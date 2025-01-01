# Things to do.

In (sort of) order

- AZCollectionView needs to be done. That's the last "big" view-type.

- NSCoder classes as foundation work for
    - initWithCoder to work, which might allow XIBs
    - NSPasteboard as foundation work for
        - Drag and drop support (then into views)
            - Not sure we'll manage to integrate with Windows D&D though
				- SDL3 has a 'drop' type event. Don't see a drag one.
				- Only copes with filename or text content

- SDL_GPU implementation of the renderer

