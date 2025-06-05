# Azoth
## Objective-C UI library for SDL3

### About
Based on AppKit, tries to present pretty much the same interface as AppKit does, except the namespace is AZ not NS. You get things like AZCollectionView, AZTableView, AZOutlineView, AZSplitView, AZScrollView AZImageView, AZButton, AZLabel (a read-only version of AZTextField), AZPopupButton, AZSlider, AZScroller, AZTextfield as well as things like AZWindow, AZEvent and the AZView hierarchy (including AZResponder, AZControl etc.)

You also get AZViewController, which can read .zib files (which themselves can be created from .xib files in Xcode using the included tool 'xib2zib' which will convert the NS classes into the corresponding AZ ones).

There are a bunch of test-applications (I generally wrote these while creating the functionality they demonstrate, so some of the earlier ones don't take full advantage of what is available in the framework, be warned).

If there is a file named 'main.zib' in the Resources/ folder of the application, it will be loaded and used as the main window/UI definition for the app. This file can be generated using the 'xibtozib' tool (included) on a .zib file created from within XCode.

### Platforms

The code is only (currently) set up to run on the Mac, but with the [windows MSVC toolchain](https://github.com/gnustep/tools-windows-msvc) I have had SDL3 up and running using Objective C. There still needs to be some porting done to make sure things compile, but I see no reason that this wouldn't work on Windows

Linux has clang and the GNUstep runtime available from distribution repos, so again I can't see any reason why this wouldn't work on any Linux that supports ObjC. 

Together, that covers pretty much everyone with an ObjC / AppKit-style UI, providing GPU acceleration and shader coding. 


### Helper Tools

- [genRsrc](Documentation/genRsrc) for taking a directory full of images and converting them into a single texture map with identified rectangles. Used to create the symbols font from Google's iconography amongst other things
 
- xib2zib is a tool for converting the XIB file worked on in Xcode to design UIs, and a (similar but different and simpler) ZIB file that Azoth understands. Simply run `xib2zib <file.xib> <file.zib>` to convert from the XIB to the ZIB, and place the resulting file into Resources/ for your app. If you put a `main.zib` file in there, the AZApplicationDelegate will load it at startup, defining your main window UI.
 

### Demonstration apps

- [AZBasic](Documentation/AZBasic/README.md) is the simplest demo app, which just opens a window and responds (by doing nothing) to events and can serve as a starting template. The others try to demonstrate some piece of functionality, generally they're named after what they're showing off.

- [AZBezier](Documentation/AZBezier/README.md) is an app I wrote while trying to get offset beziers (and bezier paths in general) working in Azoth. 

- [AZCollectionView](Documentation/AZCollectionView/README.md) is an app designed to show off the collection view support, complete with delegate and datasource similar to (if not identical to) AppKit's version

- [AZCompute](Documentation/AZCompute/README.md) is not entirely complete but it still shows how GPU compute shaders can be applied to textures and drawn using the SDL3 GPU engine

- [AZDemo](Documentation/AZDemo/README.md) shows off some of the UI components available in the framework. This was actually one of the earliest demo apps written, so it's a bit raw in places in the source code.

- [AZDragAndDrop](Documentation/AZDragAndDrop/README.md) is a simple app to show drag-and-drop using Azoth

- AZFullScreen just shows how you can open a window to fullscreen dimensions via SDL3

- [AZImageView](Documentation/AZImageView/README.md) shows the various scaling, alignment and framing options available for the AZImageView class

- [AZOutline](Documentation/AZOutline/README.md) is a simple demo of the AZOutlineView using the datasource and delegate to provide data to the view

- [AZTable](Documentation/AZTable/README.md) is a simple demo of the AZAZTableView using the datasource and delegate to provide data to the view

- [GPUTest](Documentation/GPUTest/README.md) is a demo that uses the GPU renderer to do a 9-way blit of an image to a larger form

### Sources:
I wouldn't have been able to put Azoth together in anywhere near the timescale I did without referring to the projects in [Sources](Documentation/Sources/). I thank the authors of these projects from the bottom of my heart.


### Caveats:
- Note that you need to create a static library for Azoth on Windows, and use the WHOLEARCHIVE linker option (e.g. /WHOLEARCHIVE:Azoth.lib), because categories will otherwise be stripped from the libraries.

- The conversion from XIB to ZIB can sometimes go slightly awry, ZIBs are complex beasts, and there are occasional boundary cases not catered for until they're found. It's not as though this is a documented format...

- There are almost certainly bugs :) 
