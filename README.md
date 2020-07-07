# TESmartSwitchAPI
A macOS utility for controlling a 16-port TESmart KVM switch.

This is a utility for controlling TESmart 16-port KVM switches.  It has been tested with a model HKS1601A1U switch, but should also work with the HKS1601A10, as the utilities and documentation for both appear to be identical.

Current shortcomings in this application are parts of the networking, as the library used (CocoaAsyncSocket) combines multiple requests made in short succession into a single packet, which doesn't really work well with the switch.  Currently, as a workaround, there are sleep statements in areas where this could happen, but it's not ideal.

Building is relatively straightforward, though it does require Carthage for dependency management.  Check out the project, switch to the directory where it was checked out, and run:

``carthage update --platform Mac``

From there, you should be able to build the project in Xcode as usual.
