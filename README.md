# Azoth
Objective-C UI library for SDL3

### About
Based on AppKit, tries to present pretty much the same interface as AppKit does, except the namespace is AZ not NS. You get things like AZCollectionView, AZTableView, AZOutlineView, AZSplitView, AZScrollView AZImageView, AZButton, AZLabel (a read-only version of AZTextField), AZPopupButton, AZSlider, AZScroller, AZTextfield as well as things like AZWindow, AZEvent and the AZView hierarchy (including AZResponder, AZControl etc.)

You also get AZViewController, which can read .zib files (which themselves can be created from .xib files in Xcode using the included tool 'xib2zib' which will convert the NS classes into the corresponding AZ ones).

There are a bunch of test-applications (I generally wrote these while creating the functionality they demonstrate, so some of the earlier ones don't take full advantage of what is available in the framework, be warned).

The simplest demo is [AZBasic](Documentation/AZBasic/README.md) which just opens a window and responds (by doing nothing) to events and can serve as a starting template. The others try to demonstrate some piece of functionality, generally they're named after what they're showing off.


### Sources:
I wouldn't have been able to put Azoth together in anywhere near the timescale I did without referring to the projects in [Sources](Documentation/Sources/). I thank the authors of these projects from the bottom of my heart.


### Caveats:
- Note that you need to create a static library for Azoth on Windows, and use the WHOLEARCHIVE linker option (e.g. /WHOLEARCHIVE:Azoth.lib), because categories will otherwise be stripped from the libraries.

