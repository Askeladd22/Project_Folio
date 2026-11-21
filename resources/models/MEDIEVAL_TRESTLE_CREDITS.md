# Medieval Trestle Table — visual material attribution

The optional local GLB pair in Project Folio v0.1.109 combines
separately authored material and model references supplied by the user.
**Neither file is committed to Git**. The built-in fallback is an
original procedural mesh using the project-owned `wood.png` texture.

- **KIFIR**, *Medieval Table*: base silhouette/GLB supplied by the user,
  [Sketchfab](https://sketchfab.com/3d-models/medieval-table-b72b2843827743bda281a3d28212dd4c).
  The glTF asset metadata declares **CC BY 4.0**.
- **Alex Krush**, *Old Wooden Table — Game Ready Asset*: supplied
  `Wood_albedo.jpg`, converted to 1024px for the optional renderer,
  [Sketchfab](https://sketchfab.com/3d-models/old-wooden-table-game-ready-asset-d06d49bdb23c45d5b1fe33bab4b04374).
  Its glTF metadata also declares **CC BY 4.0**.
- [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/)
  requires preserving appropriate author/source attribution and
  identifying modifications when redistributing derived material.

The game rescales, rotates and shortens the model supports to the
existing **decorative** tabletop coordinates. This never changes the
physics. PBR metal/roughness/normal maps are inspected but not supported
by the present glTF import shader; no fake PBR quality claim.

Install the optional high fidelity package by unpacking at the
repository root (next to `main.lua`):

```
resources/models/medieval_table_folio.glb
resources/models/medieval_table_folio_wood.jpg
```

The default `old_wooden` F8 style detects these locally and otherwise
loads the tracked procedural trestle. The 125MB *Medieval Market /
Tent Prop_01* was intentionally excluded, since its 111 meshes are
not a single table. Validate UV seams and mouse picking visually
before bundling a commercial release.
