# AZBezier

Bezier paths are tricky things, and this app was written while I was trying to port the [cubic-bezier-offsetter](https://github.com/aurimasg/cubic-bezier-offsetter) code to Azoth to provide generic Bezier support. Offsetting a Bezier curve doesn't necessarily create another Bezier curve, depending on the specific curvature of the original. Instead you might have to analyse and approximate parts of the curve. This is now supported inside Azoth.

The goal of this was to be able to draw a Bezier curve on a game map, stretch it out width-ways, and texture it as a roadway, or river, or whatever. As such, I wanted things to be editable after the stretch, so the designer (me!) could alter the map later.

This is the prototype app used while getting the basics working in the framework...

<img src=AZBezier.gif width=720>
