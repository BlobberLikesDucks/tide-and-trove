"""Tide & Trove Blender asset kit. In a live Blender session:

    import sys; sys.path.insert(0, r"<repo>/blender")
    import tt; tt.load(["props"]); tt.pipe.build(group="props")
"""
import importlib
import sys

CORE = ["tt.mats", "tt.geo", "tt.paint", "tt.procgen", "tt.anims", "tt.pipe"]


def load(groups=()):
    for name in CORE:
        if name in sys.modules:
            importlib.reload(sys.modules[name])
        else:
            importlib.import_module(name)
    mod = sys.modules["tt.pipe"]
    mod.REGISTRY.clear()
    for g in groups:
        name = "ttassets." + g
        if name in sys.modules:
            importlib.reload(sys.modules[name])
        else:
            importlib.import_module(name)
    globals()["pipe"] = mod
    return mod
