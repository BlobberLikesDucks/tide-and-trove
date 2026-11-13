"""Tide & Trove material library (stylized-style + materials skills).

Palette: "cozy coastal" analogous base (sand / driftwood / sage / sea teal) with a
coral accent reserved for interactive + hero elements and a gold accent for value
(gems, brass, plaques). Backgrounds (cliffs, ground) are kept desaturated; props
the player touches are saturated.

Every material has a *kind* that drives the bake pipeline in paint.py:
  paint   - colour is baked into the asset's hand-painted atlas, then all paint
            materials of an asset collapse into one MAT_<Asset> (1 draw call).
  tint    - Godot recolours it at runtime by name (Skin, Shirt, Blade, Gem, Fossil..);
            the atlas region is baked from a white base and the colour is kept as
            the glTF baseColorFactor so Art.tint() still works.
  special - glass / water / emissive / holo: left as flat PBR, never baked.
"""
import bpy

KIND = {}
_MATS = {}


def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hexc(h):
    h = h.lstrip("#")
    return tuple(_lin(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def M(name, color, rough=0.85, metal=0.0, emit=0.0, alpha=1.0, kind=None):
    if name in _MATS and _MATS[name].name == name:
        return _MATS[name]
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if b is None:
        b = nt.nodes.new("ShaderNodeBsdfPrincipled")
        out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
        nt.links.new(b.outputs[0], out.inputs[0])
    col = hexc(color)
    b.inputs["Base Color"].default_value = (*col, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    try:
        b.inputs["Specular IOR Level"].default_value = 0.25
    except KeyError:
        pass
    if emit > 0:
        b.inputs["Emission Color"].default_value = (*col, 1.0)
        b.inputs["Emission Strength"].default_value = emit
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            try:
                setattr(m, attr, val)
                break
            except Exception:
                pass
    m.diffuse_color = (*col, alpha)
    m["tt_hex"] = color
    m["tt_name"] = name
    if kind is None:
        kind = "special" if (emit > 0 or alpha < 1.0) else "paint"
    KIND[name] = kind
    m["tt_kind"] = kind
    _MATS[name] = m
    return m


def kind_of(m):
    return m.get("tt_kind", KIND.get(m.name, "paint"))


def base_hex(m):
    return m.get("tt_hex", "#cccccc")


# ------------------------------------------------------------------ palette --
# Sand & ground (desaturated, warm)
SAND = M("Sand", "#f0d3a0"); SAND2 = M("Sand2", "#e6c48c"); SAND_WET = M("SandWet", "#cfa979"); SAND_DK = M("SandDark", "#b48d5e")
SAND_CLIFF = M("SandCliff", "#ecc792"); SAND_CAVE = M("SandCave", "#c4ae8c"); SAND_REEF = M("SandReef", "#cdc4b3")
GRASS = M("Grass", "#8cc864"); GRASS2 = M("Grass2", "#76b455"); GRASS3 = M("Grass3", "#a3d67a"); CLOVER = M("Clover", "#5fa648")
SOIL = M("Soil", "#6e4d2f"); MUD = M("Mud", "#8a6440")
# Wood family
WOOD = M("Wood", "#b57d4c"); WOOD_DK = M("WoodDark", "#7c502f"); WOOD_LT = M("WoodLight", "#dcab6f"); WOOD_RED = M("WoodRed", "#a05d3c")
DRIFT = M("Driftwood", "#b8aa98"); DRIFT_DK = M("DriftDark", "#8d7e6d")
# Architecture
PLASTER = M("Plaster", "#d8c6a6"); SIDING = M("Siding", "#4fa3a5"); SIDING2 = M("Siding2", "#5cb8b2"); SIDING3 = M("Siding3", "#438d90")
TRIM = M("Trim", "#f1e6cc"); ROOF = M("Roof", "#e0705a"); ROOF2 = M("Roof2", "#c95e49"); ROOF3 = M("Roof3", "#ea8a72")
SHUTTER = M("Shutter", "#f29e7a"); SHOP_WALL = M("ShopWall", "#f2a95c"); SHOP_WALL2 = M("ShopWall2", "#e2954a")
SHOP_ROOF = M("ShopRoof", "#3f7f6a"); SHOP_ROOF2 = M("ShopRoof2", "#356e5b")
STRIPE_R = M("StripeRed", "#e05252"); STRIPE_W = M("StripeWhite", "#fff7ec"); STRIPE_Y = M("StripeYellow", "#f7c948"); STRIPE_G = M("StripeGreen", "#5bbf6a")
STONE = M("Stone", "#d8cbb0"); STONE2 = M("Stone2", "#c2b394"); CONCRETE = M("Concrete", "#b9b2a6"); CURB = M("Curb", "#b8b2a6")
ASPHALT = M("Asphalt", "#4c515a"); ASPHALT2 = M("Asphalt2", "#42474f"); PAINT_W = M("PaintWhite", "#f2efe6")
TILE = M("Tile", "#8fc9de"); TILE2 = M("Tile2", "#79b4ca")
# Rock & strata (background: desaturated)
ROCK = M("Rock", "#a39d91"); ROCK_DK = M("RockDark", "#6d6963"); ROCK_LT = M("RockLight", "#c6bfb0"); ROCK_BLUE = M("RockBlue", "#5f6877")
STRATA = [M("StrataA", "#d9b48a"), M("StrataB", "#c48f63"), M("StrataC", "#e8d1a6"), M("StrataD", "#a8724b"), M("StrataE", "#ba825b")]
SLATE = [M("SlateA", "#707b88"), M("SlateB", "#58626f"), M("SlateC", "#8b95a2"), M("SlateD", "#4b5361"), M("SlateE", "#7e8895")]
SANDST = [M("SandstoneA", "#ecd6a8"), M("SandstoneB", "#dcc08c"), M("SandstoneC", "#f4e4c0"), M("SandstoneD", "#caa777"), M("SandstoneE", "#e2c895")]
CAVE_DK = M("CaveDark", "#1e2632")
# Vegetation (puffy stylized greens)
LEAF = M("Leaf", "#4caf50"); LEAF_DK = M("LeafDark", "#2f8a58"); LEAF_LT = M("LeafLight", "#80c65c")
TRUNK = M("Trunk", "#9d7855"); TRUNK2 = M("Trunk2", "#846241"); COCONUT = M("Coconut", "#6b4a2b")
# Metals (stepped roughness, low metallic for toon)
METAL = M("Metal", "#b8c0c8", rough=0.4, metal=0.6); METAL_DK = M("MetalDark", "#4d5762", rough=0.45, metal=0.5)
IRON = M("Iron", "#30353b", rough=0.5, metal=0.5); BRASS = M("Brass", "#d9a83f", rough=0.35, metal=0.7); RUST = M("Rust", "#a0522d")
# Specials (never baked)
GLASS = M("Glass", "#cfeff7", rough=0.05, alpha=0.28); WATER = M("Water", "#3fa7d6", rough=0.1, alpha=0.5)
SEA = M("Sea", "#3fa7d6", rough=0.1, kind="special")
GLOW_CYAN = M("GlowCyan", "#5ff2ff", emit=3.0); GLOW_WARM = M("GlowWarm", "#ffd27a", emit=3.0); GLOW_RED = M("GlowRed", "#ff4a3a", emit=2.0)
HOLO = M("Holo", "#6ff7ff", emit=2.0, alpha=0.35); LEMONADE = M("Lemonade", "#ffb43a", rough=0.1, alpha=0.6)
SCREEN = M("Screen", "#7dff9a", emit=2.0)
# Specimens & museum
BONE = M("Bone", "#efe3c4"); FBONE = M("FossilBone", "#c9a77a"); APEX = M("ApexBone", "#ddd2bd")
TOOTH = M("Tooth", "#fbf5e6"); SOCKET = M("Socket", "#3a2e28")
SHELL = M("Shell", "#d9a46f"); SHELL2 = M("ShellStripe", "#8a4f2a")
MATRIX = M("Matrix", "#a89f8a"); MATRIX2 = M("Matrix2", "#968c76")
FOSSIL = M("Fossil", "#b89a72", kind="tint")
GEM = M("Gem", "#4fd1e8", rough=0.1, kind="tint"); GEM2 = M("GemFacet", "#a8f2ff", rough=0.08)
FLECK = M("Fleck", "#e8b84a", rough=0.35, metal=0.6, kind="tint")
RED = M("Red", "#d9483b"); VELVET = M("Velvet", "#a3263a"); GREEN = M("Green", "#3fa34d"); YELLOW = M("Yellow", "#f7d24a")
ORANGE = M("Orange", "#f08a3c"); BLUE = M("Blue", "#3f7fd9"); PURPLE = M("Purple", "#8a5cc2"); PINK = M("Pink", "#f4a6b8")
CORAL = M("Coral", "#ff7a59"); TEAL = M("Teal", "#2f8f8f"); CREAM = M("Cream", "#fff3d6")
TERRACOTTA = M("Terracotta", "#c8643c"); DARK = M("Dark", "#2a2a30"); POPCORN = M("Popcorn", "#fff3b0")
PAPER = M("Paper", "#fffaf0"); PAPER2 = M("Paper2", "#efe4cc"); CLOTH = M("Cloth", "#2f8f8f"); ROPE = M("Rope", "#c9a46a")
CUSHION = M("Cushion", "#2f8f8f"); LEATHER = M("Leather", "#8a5a32"); RUBBER = M("Rubber", "#2b2d33")
# Godot-tinted (character + tool) materials: names are part of the game contract
C_SKIN = M("Skin", "#e0ac83", kind="tint"); C_SHIRT = M("Shirt", "#c8b27a", kind="tint"); C_PANTS = M("Pants", "#6b5a3e", kind="tint")
C_SHOE = M("Shoe", "#4a3626", kind="tint"); C_HAIR = M("Hair", "#5a3a22", kind="tint"); C_HAT = M("Hat", "#d9c08c", kind="tint")
C_ACC = M("Accent", "#22252b", kind="tint"); C_PACK = M("Pack", "#8a6a3a", kind="tint")
C_BLADE = M("Blade", "#b8c0c8", rough=0.4, metal=0.6, kind="tint")
C_EYE = M("Eye", "#1d1d24"); C_WHITE = M("EyeWhite", "#fbfbf6"); C_MOUTH = M("Mouth", "#8a3a3a"); C_BLUSH = M("Blush", "#f0a090")
C_SOLE = M("Sole", "#2a2420"); C_BELT = M("Belt", "#4a3020"); C_SOCK = M("Sock", "#f2efe6"); C_BUTTON = M("Button", "#f2e6c8")
C_HANDLE = M("Handle", "#8a5a32"); C_GRIP = M("Grip", "#2a2a30")
INK = M("Ink", "#3a3a48"); AMBER = M("Amber", "#f2a23a", rough=0.08, alpha=0.75); AMBER_DK = M("AmberDark", "#a8561c", rough=0.2)
LAMP_TINT = M("Lamp", "#7ddc6a", emit=1.5, kind="tint")
