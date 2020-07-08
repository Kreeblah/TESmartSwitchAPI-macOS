# Protocol Documentation

For anybody else looking for documentation on the protocol this KVM uses, hopefully this will be helpful.  For brevity, what’s listed here as “packets” is the data in the data portion of a TCP/IP packet.  Normal TCP/IP flows apply, so the rest of the packet should look as you’d expect.

**Note:** For all communications below, the KVM expects each request to be made in its own packet, one call per packet.  **You cannot combine multiple requests into a single packet.**  If you do, the KVM will ignore everything past the first one in the list.

## Connecting

Connecting to the KVM is as simple as opening a TCP connection to the IP address and port that it’s listening on.  There’s no handshake beyond this and (probably more importantly) no security.  Connections happen in the clear, and the KVM always sends data back to the same port that a request to it was made from.

Getting the Current Active Display Port

Requesting the current active display port is done by sending the following packet to the KVM:

    0xaa 0xbb 0x03 0x10 0x00 0xee

The KVM will then respond with a packet containing the following data:

    0xaa 0xbb 0x03 0x11 BYTE1 BYTE2

BYTE1 is a **zero-indexed** byte indicating the number of the active display port.  For example, if port 1 is selected, the byte will be 0x00, whereas if port 12 is selected, the byte will be 0x0b.

BYTE2 functions as a validation for BYTE1, and will always be a value 0x16 (22 in decimal) greater than BYTE1.

## Setting the Current Active Display Port

Setting the current active display port is done by sending this packet:

    0xaa 0xbb 0x03 0x01 BYTE1 0xee

BYTE1 here is a **non-zero-indexed** byte indicating the port to switch to.  So, if port 1 should be selected, BYTE1 should be 0x01, and if port 12 should be selected, then BYTE1 should be 0x0c.

The KVM will respond with two packets that look like this:

    0xaa 0xbb 0x03 0x11 BYTE1 BYTE2

The packet is in the same format as the reply to the current active display port request, meaning that BYTE1 is a **zero-indexed** byte indicating the newly-selected port, and BYTE2 is a value 0x16 (22 in decimal) greater than that.

## Enabling or Disabling the Buzzer

The internal buzzer is quite shrill, so it makes sense that they offered a way to disable it.  In order to alter the state of the buzzer, send the following packet to the KVM:

    0xaa 0xbb 0x03 0x02 BYTE1 0xee

Send BYTE1 as 0x01 to enable the buzzer, or 0x00 to silence it.  When enabled, it chirps every time the active display port is changed.

For these calls, the KVM doesn’t reply with any data.

## Enabling or Disabling Active Port Detection

By default, the KVM will change inputs to any input which is just connected, or begins sending data when it wasn’t before.  Depending on your use case, this may or may not be desirable.  So, to enable or disable this detection, send the following packet to the KVM:

    0xaa 0xbb 0x03 0x81 BYTE1 0xee

Like with the buzzer, send BYTE1 as 0x01 to enable this feature, or 0x00 to disable it.  The KVM also doesn’t reply with any data.

## Setting the Port Display Timeout

The display on the front of the KVM which indicates which port is currently being forwarded to the output can be turned off.  The amount of time it’s illuminated after a port change is configurable by the number of seconds you want it to remain lit.  To set this, send this packet to the KVM:

    0xaa 0xbb 0x03 0x03 BYTE1 0xee

BYTE1 in this packet is the number of seconds to leave the display turned on, with 0 indicating that the display should remain on indefinitely.  This call doesn’t return any data.

## Retrieving the Configured Network Settings

Retrieving the configured network settings is done by sending a three-byte packet to the KVM, depending on which setting you want to request (IP address, port, netmask, or gateway).  The packets that are used for this are:

    0x49 0x50 0x3f
    0x50 0x54 0x3f
    0x4d 0x41 0x3f
    0x47 0x57 0x3f

In order, these packets request the IP address, port, netmask, and gateway.  Note that their ASCII representations are “IP?”, “PT?”, “MA?”, and “GW?”.  The KVM will respond to each with a packet that looks like one of these:

    0x49 0x50 0x3a 0x31 0x39 0x32 0x2e 0x31 0x36 0x38 0x2e 0x30 0x30 0x31 0x2e 0x30 0x31 0x30
    0x50 0x54 0x3a 0x30 0x50 0x30 0x30 0x30 0x3b
    0x4d 0x41 0x3a 0x32 0x35 0x35 0x2e 0x32 0x35 0x35 0x2e 0x32 0x35 0x35 0x2e 0x30 0x30 0x30
    0x47 0x57 0x3a 0x31 0x39 0x32 0x2e 0x31 0x36 0x38 0x2e 0x30 0x30 0x31 0x2e 0x30 0x30 0x31

The ASCII equivalents of these are:

    IP:192.168.001.010
    PT:05000;
    MA:255.255.255.000
    GW:192.168.001.001

A couple of things to note here are that all octets for the IP address, netmask, and gateway are zero-padded to fill out three characters.  Similarly, the port number is zero-padded to fill out five characters.

**Note:** The port reply has a semi-colon at the end, which the IP address, netmask, and gateway do not.  However, each of the IP address, netmask, and gateway **also send a second packet** containing only 0x3b (a semi-colon).  Depending on your network library, you may need to account for this, including which order the pair of packets is received/processed in.

## Setting the Configured Network Settings

Configuring the network settings on the KVM is fairly straightforward, given the above.  Packets to do this look as follows:

    0x49 0x50 0x3a 0x31 0x39 0x32 0x2e 0x31 0x36 0x38 0x2e 0x31 0x2e 0x31 0x30 0x3b
    0x50 0x54 0x3a 0x50 0x30 0x30 0x30 0x3b
    0x4d 0x41 0x3a 0x32 0x35 0x35 0x2e 0x32 0x35 0x35 0x2e 0x32 0x35 0x35 0x2e 0x30 0x3b
    0x47 0x57 0x3a 0x31 0x39 0x32 0x2e 0x31 0x36 0x38 0x2e 0x31 0x2e 0x31 0x3b

Or, for the ASCII equivalents:

    IP:192.168.1.10;
    PT:5000;
    MA:255.255.255.0;
    GW:192.168.1.1;

Note that while these packets look similar to the replies from requesting the configuration information, they’re not the same.  There’s no zero-padding, and each packet has a semi-colon at the end (instead of that being sent in a separate packet, as with the IP address, netmask, and gateway when requesting configuration information).

If the call is successful, the KVM will reply with the following packet:

    0x4f 0x4b

Or, in ASCII:

    OK
