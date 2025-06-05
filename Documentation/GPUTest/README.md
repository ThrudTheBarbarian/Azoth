# GPUTest

Trivial demo to render one of the icons in the icon font using a 9-way blit via the GPU renderer and then render the sane icon at normal size in the centre.

Note that selection of the GPU (rather than 2D-renderer) back-end is made in `main.m` vis:

```
	AZApp.rendererType	= AZRendererType3d;
```


<img src=GPUTest.png width=642>
