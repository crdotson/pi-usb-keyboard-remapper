# pi-usb-keyboard-remapper
A proof-of-concept USB to USB keyboard remapper on a Raspberry Pi

I got a great deal on a keyboard that I really liked (Matias Quiet Pro), but it was for Mac, and I'm using Windows.  It worked fine, except that the position of the Alt and Windows keys were reversed.  I tried remapping the keys in Windows using Windows PowerToys, but Windows would get confused occasionally about these modifier keys.  I then looked at building a USB to USB converter at https://github.com/tmk/tmk_keyboard/tree/master/converter/usb_usb, but I didn't have a USB shield to build it.  I also looked at replacing the controller in the keyboard with a Teensy and QMK, and I might still do that.  

What I did have, however, was a Raspberry Pi 4 which can do USB OTG and also has USB ports to plug in a keyboard.  

I couldn't find anyone else who had already used a Pi as a hardware keyboard remapper, so I wrote up this quick proof of concept that watches the USB bus using the usbmon facility.  When a packet is received, it pulls it apart and looks at the modifier codes and key codes in the HID packet.  It then swaps the Alt and Windows modifier bits and then sends a HID packet out to the host.  I plugged it into my laptop using a USB-C to USB-C cable, and it works great!  I'm using it to type this now.

If you invoke it with -d, it will show you what was received and what was sent, and also how long the processing time was from when the packet was received to after it was sent.  Latency is on the order of a few hundred microseconds in general and is not noticeable.  

I would really like to make something like QMK work on the Pi so that I can use the keymaps, but that looks like considerably more work!  

Note that I don't even bother filtering for a specific USB device, so if you plug in any other USB devices to your Pi, your "keyboard" will probably go absolutely crazy.  Also, if you kill the process while a key is being held down, your computer will never receive the "no keys being pressed" packet, which is a lot of fun, and you'll have to unplug the Pi unless you can somehow navigate while those keys are being pressed to disable the keyboard device.

Thanks to https://mtlynch.io/key-mime-pi/ and https://medium.com/swlh/make-your-raspberry-pi-file-system-read-only-raspbian-buster-c558694de79 for doing some of the hard work for creating the HID device and figuring out how to make Raspbian readonly.

I also created a clean image with just this autostarting and with a readonly filesystem, so that it can be plugged and unplugged without filesystem/SD card corruption.  It's available under releases, just gunzip and dd to any SD card >= 8GB.  

If you want to create your own image, then:

1. apt-get install libnet-pcap-perl
1. cpan install Net::Pcap NetPacket::USBMon 
1. follow instructions at https://mtlynch.io/key-mime-pi/ to set up HID device.
1. edit /etc/rc.local to start the remapper on boot.
1. Follow the instructions at https://medium.com/swlh/make-your-raspberry-pi-file-system-read-only-raspbian-buster-c558694de79 to make the filesystem readonly.  
