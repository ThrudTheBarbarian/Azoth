# Things to do.

In (sort of) order
- NSCoder classes as foundation work for
    - initWithCoder to work, which might allow XIBs
    - NSPasteboard as foundation work for
        - Drag and drop support (then into views)
            - Not sure we'll manage to integrate with Windows D&D though
				- SDL3 has a 'drop' type event. Don't see a drag one.
				- Only copes with filename or text content

- AZCollectionView needs to be done. That's the last "big" view-type.
	- moved this below the above because an AZCollectionViewItem will
	  have to be a subclass of AZViewController, which needs to (or at
	  least can) load its view from a NIB

- SDL_GPU implementation of the renderer
	- There are no references to SDL_Texture outside of the AZRenderer class
	  any more, so we ought to be able to make a protocol id<Renderer> and 
	  have both SDL_Render and SDL_GPU style rendering available, chosen at
	  application startup.
	  

