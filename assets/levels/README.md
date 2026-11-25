# Level JSON and Tiled export

Runtime level files are named `level_<id>.json` and are loaded by `LevelLoader`.
The canonical format follows `sdd` §23.1: metadata, grid size, required element
names, player start, checkpoints, goal rectangle, solid terrain rectangles, and
hazard rectangles. Coordinates and sizes are pixels from the map's top-left.

`woodAnchor` interactables normally create a horizontal temporary bridge. A
tall, narrow anchor (`height > width`) instead grows a climbable vine. In that
form, the Wood player can hold either movement direction while overlapping the
vine to climb upward, then jump or move away to leave it.

A Tiled finite orthogonal map can be exported with **File → Export As → JSON**
without a custom script. Add map properties `levelId`, `world`, `index`, and
`requiredElements` (comma-separated element names). Add object groups containing
rectangle objects with class/type `solid`, `fireHazard`, `waterHazard`,
`electricHazard`, `checkpoint`, or `goal`; use `playerStart` for the spawn
point. A tile layer named `terrain`, `collision`, or `solid` is treated as
collision terrain; alternatively set its boolean `collision` property to true.
Only finite orthogonal maps with square tiles are supported. Tile layers may be
exported as JSON arrays or base64 with no compression, zlib, or gzip. Decorative
layers are ignored. Tile-layer collision is built from horizontal runs of
non-empty tiles; object layers preserve exact rectangles.

`LevelSchemaValidator` normalizes either this Tiled export or a canonical level
file, then rejects malformed IDs, dimensions, elements, bounds, hazard types,
and missing required spawn/goal data with a JSON path in the error message.
