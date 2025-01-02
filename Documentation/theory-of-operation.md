∫# Overview

Generally aiming to be a "Cocoa-Lite" paradigm. There's no way we can implement Cocoa in a one-man-band operation, but being able to quickly put together UI using components that interoperate well with SDL is a goal.

# Theory of operation

The basic interface is AZView, which is analogous to NSView. It accepts events from SDL and propagates them to the views based on the view co-ordinate hierarchy. 

Views added as subviews to a view will have precedence over the original view. This goes for events as well as rendering - subviews render *on top of* their hosting view.

## Drawing in a view

The AZPainter class is provided, which allows the use of primitives to draw with. A lot of this was shamelessly taken from SDL2_gfx. The provided primitives include points, lines, triangles, circles, ellipses and polygons. All of these can be filled or just outline-drawn (where relevant). The polygons can also be textured using an SDL_Surface.

## Drawing Text

We depend on the SDL_ttf library for text rendering. As glyph-based rendering cannot produce accurately-kerned characters using this library, we have an AZFontCache object which can be created to cache words rendered using a given font at a given size/weight/etc. The cache is probably not necessary for things that do not change regularly (eg: labels in dialogues) but for the (forthcoming) AZTextView which allows layout and editing of free-flowing text, the cache should speed things up. The AZPainter provides a 'drawText:at:options' method for graphically drawing text without caching. 

Worth noting is that we distribute the Noto-Sans-Medium font as the "system font" (ie: the fallback). The license is available here - https://fonts.google.com/noto/specimen/Noto+Sans/license but basically says redistribution for pretty much any purpose is fine as long as you don't charge just for the font.