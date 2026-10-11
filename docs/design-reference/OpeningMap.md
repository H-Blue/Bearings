# Opening map provenance

The owner requested a new portrait topographic-map image derived from `appIcon.png`, removing the compass and showing two parallel mountain ridges with a central river. The subsequent explicit correction bends the river and nearby ridges to the right near the bottom. The owner then selected that image for a minimum two-second app opening screen.

The built-in image generator created the artwork using the previous map as its reference. The returned bitmap was exported with macOS `sips` to 1206 × 2622 pixels, without cropping, recoloring or redrawing. The final owner-selected source `bearings-ridges-iphone-16-pro-right.png` remains untouched at the repository root; the application bundles an identical copy at `Bearings/Resources/Assets.xcassets/OpeningMap.imageset/OpeningMap.png`.

Source and bundled-image SHA-256: `809925cf983bcfa6b7cd68c467fcb4816718b030df25fab12088642fe47830d3`.

## Final generation prompt

Use case: precise-object-edit. Edit the provided portrait topographic map. Change the river's final bend from LEFT to RIGHT. The river must continue down the central valley through the upper and middle image, then sweep clearly rightward in the bottom quarter and exit through the lower RIGHT edge. Adjust the adjacent ridge contour lines around this bend so the two mountain ridges naturally follow the river toward the right. Keep the upper terrain composition, two elongated parallel ridges, fine navy contour strokes, tan background and subtle paper texture unchanged as much as possible. Preserve the existing simplified top-down cartographic style and palette, #C8AB89 tan and #323575 navy targets. No compass, labels, text, added objects, border or device frame. Preserve tall portrait framing for an iPhone 16 Pro; requested final size 1206 x 2622 pixels. Produce one opaque portrait image.
