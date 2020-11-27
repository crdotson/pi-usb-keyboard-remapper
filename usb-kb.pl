#!/usr/bin/perl -w
use strict;
use Net::Pcap;
use NetPacket::USBMon;

my $debug;
if ($#ARGV > -1 and $ARGV[0] eq "-d") { $debug = 'true'; print "Debug mode enabled.\n"}

if ($debug) { 
	use Time::HiRes;
	use Data::Dumper;
	open(HIDG0, "> /tmp/usbkeyboard.txt");
	$| = 1;  # disable output buffering for debug statements
} else { 
	open(HIDG0, "> /dev/hidg0") or die "Can't open /dev/hidg0; make sure dtoverlay=dwc2 is set in /boot/config.txt!" ;
} 

# usbmon module must be loaded.
system("/sbin/modprobe usbmon");
binmode(HIDG0);

my $starttime;
my $errbuf;
my $device = "usbmon0";
my $handle = Net::Pcap::open_live($device, 2000, 1, 0, \$errbuf);
if (!defined $handle) {die "Unable to open ",$device, " - ", $errbuf;}

Net::Pcap::loop($handle, -1, \&process_packet, '') 
    || die "Unable to start sniffing";

close HIDG0;

sub process_packet
{
  my ($user, $header, $packet) = @_;
  if ($debug) { $starttime = [Time::HiRes::gettimeofday()];}

  # ignore frames with no data
  if (NetPacket::USBMon->decode($packet)->{'len_cap'}==0) {
	  return;
  }

  my $packetdata = NetPacket::USBMon->decode($packet)->{'data'};
  # HID format is 8 bytes; the first byte is the modifer keys, and the final six bytes are all other keys.
  my @moddata = split(//,unpack("B8" , $packetdata));
  my @keydata = unpack("H2" x 7 , substr($packetdata,1));

  if ($debug) { print "Received: modifiers " . (join '',@moddata) . " keys:" . (join ' ',@keydata) . "\n"; }
  
  # flip the windows and alt keys
  my $tmp = $moddata[0];
  $moddata[0] = $moddata[1];
  $moddata[1] = $tmp;
  $tmp = $moddata[4];
  $moddata[4] = $moddata[5];
  $moddata[5] = $tmp;

  # You can modify any other keys you like here by iterating through @keydata and making replacements.

  if ($debug) { print "Sent: modifiers " . (join '',@moddata) . " keys:" . (join ' ',@keydata) . "\n"; }

  syswrite HIDG0, pack( 'B8', (join '', @moddata)) . pack( 'H2' x 7, @keydata);

  if ($debug) { print "latency:  " . Time::HiRes::tv_interval($starttime) . "\n"; }
}

