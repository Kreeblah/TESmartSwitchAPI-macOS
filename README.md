# TESmart Switch API
A macOS utility for controlling a 16-port TESmart KVM switch.

This is a utility for controlling TESmart 16-port KVM switches.  It has been tested with a model HKS1601A1U KVM (and has been reported to work with a HSW1601A1U switch), but should also work with the HKS1601A10, as the utilities and documentation for both appear to be identical.

Building is relatively straightforward, though it does require Carthage for dependency management.  Check out the project, switch to the directory where it was checked out (the directory containing the Cartfile), and run:

``carthage update --platform Mac``

From there, you should be able to build the project in Xcode as usual.
