# mios-pioneer-receiver
Pioneer receiver plugin with status and events

I'd like to acknowledge the work originally done by @Richard Wifall, which got me kick started on creating an enchanted p enhanced version of it.

The plugin is bidirectional, allowing scenes and triggers to be executed when actions are performed on the receiver. For example, I have my home theater lights turn on whenever the amp is muted and off on mute off.

Some features

* Status display (the info which shows up on the front of the amp) is decoded
* volume is decoded to dB as well as percent
* mute on and off actions which avoids blind "mute toggle".
* Direct volume set action by percent
* Decoding of audio parameters (bit rate, depth, channels, etc. for input as well output
* Decoding of video parameters (in format, resolution, color space, etc, and their output
* Modular command set which should make it easy to expand supported variables/models
* Custom icon set for "default", "on"/"on & muted"/"off"
* Command queuing
* AltUi devices view status lines
*** tested on AltUi/OpenLuup only at this point since the plugin was developed on them using Eclipse Lua Development Tools

I encourage everyone to fork and and to it; I will implement the missing actions/status variables from the Pioneer RS232 specs (which are the same as the TELNET protocol), but I don't plan on maintaining it to much afterwards.

If anyone can figure out the code page used by Pioneer for their status display, let me know. I managed to have text displayed, but special characters just aren't mapped correctly.

Additional known compatible models:
* VSX-1326
* SC-71


# Original Source Details
Forked from http://code.mios.com/trac/mios_pioneer-receiver/changeset/2/trunk?old_path=%2F&format=zip
Ogiginal page http://code.mios.com/trac/mios_pioneer-receiver/wiki/WikiStart

This is a luup plugin to support the Pioneer VSX-1021 receiver.
Since many Pioneer receivers use the same protocol it likely will work with other Pioneer receivers but I don't have any others to test it with.  If you find a receiver that it works with (or doesn't work with), please post to the MiCasaVerde forums and I will update this file.
http://forum.micasaverde.com/

Install:
To install this plugin, you need to upload the two files to your vera device.
D_PioneerReceiver1.xml
I_PioneerReceiver1.xml
Directions on how to do this can be found on the MiCasaVerde wiki:
http://wiki.micasaverde.com/index.php/Install_LUUP_Plugins

The implementation contains a table that provides the mapping between the Micasa upnp actions and the Pioneer command.  This allows for easy customization if needed.

Good luck,
Richard Wifall

KNOWN COMPATIBLE LIST:
VSX-1021

SUSPECTED COMPATIBLE LIST:
VSX-1026
VSX-926
VSX-921

