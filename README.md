# Azoth
Objective-C UI library for SDL3




### Caveats:
- Note that you need to create a static library for Azoth on Windows, and use the WHOLEARCHIVE linker option (e.g. /WHOLEARCHIVE:Azoth.lib), because categories will otherwise be stripped from the libraries.

