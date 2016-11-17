# mios-pioneer-receiver
Pioneer receiver plugin with status and events


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

