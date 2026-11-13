"""Tide & Trove - build every 3D asset (blender-director pipeline).

Headless:
    blender -b --factory-startup --python blender/build.py -- [groups] [--only id,id] [--qa]
      groups: env nature props specimens characters fxdress   (default: all)

Live Blender (MCP / Python console):
    import sys; sys.path.insert(0, r"<repo>/blender")
    import tt; pipe = tt.load(["props"]); pipe.build(group="props")

Each asset: model -> UV -> (sculpt normal bake) -> hand-painted atlas bake ->
material collapse -> collision proxies -> validation (blender/qa/report_*.json)
-> GLB export to game/assets/models -> optional QA contact sheet (blender/qa/*.png).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import tt  # noqa: E402

MODULES = ["env", "nature", "props", "specimens", "characters", "fxdress"]

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
groups = [a for a in argv if not a.startswith("--") and a in MODULES] or MODULES
only = None
if "--only" in argv:
    only = set(argv[argv.index("--only") + 1].split(","))
qa = "--qa" in argv

for mod in groups:
    pipe = tt.load([mod])
    reps = pipe.build(ids=only)
    bad = [r for r in reps if r.get("verdict") != "SHIP"]
    print("== %s: %d built, %d need attention" % (mod, len(reps), len(bad)))
    for r in bad:
        print("   ", r["id"], r.get("verdict"), r.get("issues"))
    if qa and mod != "characters":
        import tt.qa as Q
        print("   sheet:", Q.sheet(mod))
