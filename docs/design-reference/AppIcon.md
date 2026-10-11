# Bearings app icon

The owner supplied `appIcon.png` and explicitly selected it as the application icon. This later selection approves the supplied rendering. Its colors and subtle texture are preserved; the earlier `#C8AB89` / `#323575` request is the original design brief, not a claim that every pixel in the accepted artwork uses only those colors.

- Source: root `appIcon.png`, 1254 × 1254, opaque PNG; unchanged by integration.
- Source SHA-256: `9a7923a68d4c3dee2196582f19af69cd6fdf263249120260b7c0a28c658b0206`.
- Application asset: `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 1024 × 1024, opaque PNG.
- Asset SHA-256: `5e6bba6a243141ebbd037cc3996e6bcf9704604a4a2398b27a78ff89e6af5eaf`.
- Processing: proportional resize using macOS image tooling; no recoloring, redrawing, cropping or corner mask.
- Asset configuration: universal iOS 1024 × 1024 icon; app Debug and Release configurations select `AppIcon`. iOS supplies its own rounded mask and generated device sizes.

Visual review confirmed that topographic contours continue beyond all four edges and the circular compass remains fully visible. Compilation, installed-app checks and remaining device limitations are recorded in `docs/Testing.md`.

## Generation provenance

The concept was generated with the built-in image generator during the Bearings rename; no fallback CLI or API-key workflow was used. The owner then supplied the selected image for integration. The generation prompt for this composition was:

```text
Generate one square 1024x1024 iOS app icon for Bearings as extremely clean flat vector-style digital artwork. This is a two-ink flat-color drawing, NOT an aged paper or printed effect. Precisely uniform SOLID background RGB(200,171,137) hex #C8AB89; every background pixel has the same color. Foreground RGB(50,53,117) hex #323575. Only these two flat colors plus edge antialiasing.
Draw a top-down circular hiking/navigation compass used to take a bearing on a simplified topographic map. Center the circular compass, diameter about 58 percent of the square, fully visible with comfortable margin. Use thin uniform strokes for the compass bezel, compass circular orientation ring, graduations, crosshair bearing guides and diagonal pointed compass needle. The needle is outlined, with a small flat navy triangular north pointer; keep it restrained. All contour and compass strokes should be comparably thin (about 2 pixels per 1024). Simplified widely spaced navy topographic contour curves form a few hills/valleys around the compass, clipped beyond all four edges; the map extends beyond the icon canvas and has no sheet outline. Background and compass interior are identical solid tan. No text, labels, humans, hands or rectangular compass baseplate.
ABSOLUTE: NO GRAIN, NO PAPER TEXTURE, NO LIGHTING, NO GRADIENT, NO SHADOW, NO COLOR VARIATION IN TAN REGIONS. Solid clean computer-drawn SVG-like visual treatment. Full bleed sharp square canvas, no corner rounding, frame, padding around an inset icon, or device mockup.
```
