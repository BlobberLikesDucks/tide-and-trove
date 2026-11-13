"""Animation library (animation skill): game-ready clips keyed on a Mixamo-style rig.

Poses are authored as per-bone Euler offsets in Godot model axes (x = side axis:
+ bends a limb back / - raises it forward; y = up; z = forward) relative to the
bind pose, so the same clips drive any rig with these bone names. Loops repeat
their first key on the last frame (invisible seam); one-shots (kick, getup) ease.
Clips are named AN_<Action> and pushed to muted NLA tracks for glTF export.
"""
import math

import bpy
from mathutils import Quaternion, Vector

FPS = 30


def godot_q(e):
    gx, gy, gz = e
    return (Quaternion((0, 0, 1), gy) @ Quaternion((1, 0, 0), gx) @ Quaternion((0, 1, 0), -gz))


MAP = {"Pelvis": "Hips", "Chest": "Spine", "Head": "Neck", "UpperArmL": "LeftArm", "UpperArmR": "RightArm",
       "LowerArmL": "LeftForeArm", "LowerArmR": "RightForeArm", "ThighL": "LeftUpLeg", "ThighR": "RightUpLeg",
       "ShinL": "LeftLeg", "ShinR": "RightLeg", "FootL": "LeftFoot", "FootR": "RightFoot", "Chest2": "Chest", "Head2": "Head",
       "HandL": "LeftHand", "HandR": "RightHand"}


class Poser:
    def __init__(self, rig):
        self.rig = rig
        self.pb = rig.pose.bones
        self.rest = {b.name: b.bone.matrix_local.to_quaternion() for b in self.pb}
        self.hips_m = rig.data.bones["Hips"].matrix_local.to_3x3().inverted()

    def apply(self, pose, dz=0.0, dy=0.0, hips_rot=None):
        for pb in self.pb:
            pb.rotation_mode = "QUATERNION"
            pb.rotation_quaternion = Quaternion()
            pb.location = Vector()
        for k, e in pose.items():
            n = MAP.get(k, k)
            if n not in self.rest:
                continue
            r = self.rest[n]
            self.pb[n].rotation_quaternion = r.inverted() @ godot_q(e) @ r
        if hips_rot is not None:
            r = self.rest["Hips"]
            self.pb["Hips"].rotation_quaternion = r.inverted() @ godot_q(hips_rot) @ r
        self.pb["Hips"].location = self.hips_m @ Vector((0, dy, dz))


def V(x=0.0, y=0.0, z=0.0):
    return [x, y, z]


def blank():
    return {k: V() for k in ("ThighL", "ThighR", "ShinL", "ShinR", "UpperArmL", "UpperArmR", "LowerArmL", "LowerArmR",
                             "Chest", "Chest2", "Head", "FootL", "FootR")}


S = math.sin
C = math.cos


def p_idle(t):
    r = blank()
    w = t * math.tau
    r["UpperArmL"] = V(S(w) * 0.05, 0, 0.09)
    r["UpperArmR"] = V(-S(w) * 0.05, 0, -0.09)
    r["LowerArmL"][0] = -0.15
    r["LowerArmR"][0] = -0.15
    r["Chest"][0] = S(w) * 0.025
    r["Head"] = V(S(w * 2) * 0.03, S(w) * 0.12, 0)
    return r, S(w) * 0.008, 0, None


def _gait(t, amp, lean, bounce):
    r = blank()
    w = t * math.tau
    a = S(w)
    r["ThighL"][0] = a * amp
    r["ThighR"][0] = -a * amp
    r["ShinL"][0] = max(0.0, -C(w)) * amp * 1.5 + 0.08
    r["ShinR"][0] = max(0.0, C(w)) * amp * 1.5 + 0.08
    r["FootL"][0] = -a * amp * 0.3
    r["FootR"][0] = a * amp * 0.3
    r["UpperArmL"] = V(-a * amp * 0.85, 0, 0.1)
    r["UpperArmR"] = V(a * amp * 0.85, 0, -0.1)
    r["LowerArmL"][0] = -0.35 - max(0.0, a) * amp * 0.6
    r["LowerArmR"][0] = -0.35 - max(0.0, -a) * amp * 0.6
    r["Chest"] = V(lean, a * 0.1, 0)
    r["Head"][0] = -lean * 0.6
    return r, abs(C(w)) * bounce - bounce * 0.5, 0, V(0, -a * 0.08, 0)


def p_walk(t):
    return _gait(t, 0.55, 0.05, 0.04)


def p_run(t):
    r, dz, dy, h = _gait(t, 0.95, 0.22, 0.09)
    r["LowerArmL"][0] = -1.3
    r["LowerArmR"][0] = -1.3
    return r, dz, dy, h


def p_dig(t):
    r = blank()
    w = t * math.tau
    a = S(w)
    r["UpperArmR"] = V(-1.25 + a * 0.75, 0, -0.15)
    r["UpperArmL"] = V(-1.1 + a * 0.6, 0, 0.2)
    r["LowerArmR"][0] = -0.45 + a * 0.2
    r["LowerArmL"][0] = -0.55
    r["Chest"][0] = 0.32 + a * 0.15
    r["Head"][0] = -0.1
    r["ThighL"][0] = -0.4
    r["ShinL"][0] = 0.55
    r["ThighR"][0] = 0.2
    r["ShinR"][0] = 0.15
    return r, -0.05 + a * 0.02, 0, None


def p_sweep(t):
    r = blank()
    a = S(t * math.tau)
    r["UpperArmR"] = V(-0.7, 0, a * 0.4)
    r["UpperArmL"] = V(-0.6, 0, a * 0.4)
    r["LowerArmR"][0] = -0.5
    r["LowerArmL"][0] = -0.3
    r["Chest"] = V(0.18, a * 0.18, 0)
    r["ThighL"][0] = -0.15
    r["ShinL"][0] = 0.2
    return r, -0.02, 0, V(0, a * 0.06, 0)


def p_tantrum(t):
    r = blank()
    a = S(t * math.tau)
    r["ThighL"][0] = -max(0.0, a) * 0.8
    r["ShinL"][0] = max(0.0, a) * 1.0
    r["ThighR"][0] = -max(0.0, -a) * 0.8
    r["ShinR"][0] = max(0.0, -a) * 1.0
    r["UpperArmL"] = V(-0.3, 0, 2.3 + a * 0.5)
    r["UpperArmR"] = V(-0.3, 0, -2.3 + a * 0.5)
    r["LowerArmL"][0] = -0.7
    r["LowerArmR"][0] = -0.7
    r["Head"] = V(-0.2, 0, a * 0.3)
    return r, abs(a) * 0.07, 0, None


def p_sit(t):
    r = blank()
    w = t * math.tau
    r["ThighL"][0] = -1.55
    r["ThighR"][0] = -1.55
    r["ShinL"][0] = 1.55
    r["ShinR"][0] = 1.55
    r["UpperArmL"] = V(-0.35, 0, 0.1)
    r["UpperArmR"] = V(-0.35, 0, -0.1)
    r["LowerArmL"][0] = -0.7
    r["LowerArmR"][0] = -0.7
    r["Chest"][0] = -0.05 + S(w) * 0.02
    r["Head"] = V(0, S(w) * 0.25, 0)
    return r, -0.44, 0, None


def p_sleep(t):
    r, dz, dy, h = p_sit(0)
    w = t * math.tau
    r["Head"] = V(0.55, 0, 0.15)
    r["Chest"][0] = -0.2 + S(w) * 0.04
    r["UpperArmL"] = V(-0.1, 0, 0.05)
    r["UpperArmR"] = V(-0.1, 0, -0.05)
    return r, dz, dy, h


def p_wave(t):
    """Friendly wave: upper arm out to the side just above shoulder height, forearm
    upright, the hand rocking side to side from the elbow (two waves per cycle)."""
    r, dz, dy, h = p_idle(t)
    a = S(t * math.tau * 2.0)
    r["UpperArmR"] = V(-0.3, 0.1, -1.75)
    r["LowerArmR"] = V(-0.15, 0, -1.05 + a * 0.32)
    r["HandR"] = V(0, 0, a * 0.18)
    r["UpperArmL"] = V(0.02, 0, 0.12)
    r["Chest"] = V(0.02, 0.06, 0.04 + a * 0.01)
    r["Head"] = V(-0.06, 0.12, 0.07)
    return r, dz, dy, h


def p_cheer(t):
    r = blank()
    a = S(t * math.tau)
    r["UpperArmL"] = V(0, 0, 2.6 + a * 0.3)
    r["UpperArmR"] = V(0, 0, -2.6 - a * 0.3)
    r["LowerArmL"] = V(0, 0, 0.3)
    r["LowerArmR"] = V(0, 0, -0.3)
    r["Head"][0] = -0.25
    r["ThighL"][0] = -abs(a) * 0.3
    r["ShinL"][0] = abs(a) * 0.5
    r["ThighR"][0] = -abs(a) * 0.3
    r["ShinR"][0] = abs(a) * 0.5
    return r, abs(a) * 0.12, 0, None


def p_climb(t):
    r = blank()
    a = S(t * math.tau)
    r["UpperArmL"] = V(-2.6 + a * 0.4, 0, 0.1)
    r["UpperArmR"] = V(-2.6 - a * 0.4, 0, -0.1)
    r["LowerArmL"][0] = -0.4 - max(0.0, a) * 0.5
    r["LowerArmR"][0] = -0.4 - max(0.0, -a) * 0.5
    r["ThighL"][0] = -0.8 + a * 0.5
    r["ThighR"][0] = -0.8 - a * 0.5
    r["ShinL"][0] = 0.9
    r["ShinR"][0] = 0.9
    r["Chest"][0] = 0.1
    return r, a * 0.03, 0, None


def p_inspect(t):
    r = blank()
    w = t * math.tau
    r["Chest"] = V(0.25, S(w) * 0.12, 0)
    r["Head"] = V(0.2, S(w) * 0.25, 0)
    r["UpperArmR"] = V(-0.7, 0, -0.1)
    r["LowerArmR"] = V(-1.3, 0, 0)
    r["UpperArmL"] = V(-0.25, 0, 0.15)
    r["LowerArmL"] = V(-1.6, 0, 0)
    r["HandR"] = V(0, 0, 0.3)
    return r, S(w * 2) * 0.006, 0, None


def p_kick(t):
    r, dz, dy, h = p_idle(0)
    k = S(min(1.0, t * 1.4) * math.pi)  # wind-up -> kick -> recover
    r["ThighR"][0] = 0.4 * (1 - k) - 1.5 * k if t > 0.15 else 0.4 * (t / 0.15)
    r["ShinR"][0] = 0.9 * (1 - k) + 0.1 * k
    r["ThighL"][0] = 0.1
    r["UpperArmR"] = V(0.6 * k, 0, -0.3)
    r["UpperArmL"] = V(-0.5 * k, 0, 0.4)
    r["Chest"][0] = -0.25 * k
    return r, -0.03 * k, 0, None


def _lerp_pose(a, b, k):
    out = {}
    for key in set(a) | set(b):
        va, vb = a.get(key, V()), b.get(key, V())
        out[key] = [va[i] + (vb[i] - va[i]) * k for i in range(3)]
    return out


def p_getup(t):
    """Lying on the back (head toward +Z) -> sit up -> knees -> stand."""
    lie = blank()
    lie["UpperArmL"] = V(0, 0, 0.6)
    lie["UpperArmR"] = V(0, 0, -0.6)
    sit = blank()
    sit["ThighL"][0] = -1.4
    sit["ThighR"][0] = -1.4
    sit["ShinL"][0] = 2.1
    sit["ShinR"][0] = 2.1
    sit["Chest"][0] = 0.5
    sit["UpperArmL"] = V(0.4, 0, 0.3)
    sit["UpperArmR"] = V(0.4, 0, -0.3)
    crouch = blank()
    crouch["ThighL"][0] = -1.6
    crouch["ThighR"][0] = -1.2
    crouch["ShinL"][0] = 1.9
    crouch["ShinR"][0] = 2.2
    crouch["Chest"][0] = 0.6
    crouch["UpperArmL"] = V(-0.6, 0, 0.2)
    crouch["UpperArmR"] = V(-0.6, 0, -0.2)
    stand, _, _, _ = p_idle(0)
    e = lambda x: x * x * (3 - 2 * x)
    if t < 0.35:
        k = e(t / 0.35)
        return _lerp_pose(lie, sit, k), -0.82 + 0.4 * k, 0.15 * (1 - k), V(-1.5 * (1 - k))
    if t < 0.65:
        k = e((t - 0.35) / 0.3)
        return _lerp_pose(sit, crouch, k), -0.42 + 0.0 * k, 0.0, V(0)
    k = e((t - 0.65) / 0.35)
    return _lerp_pose(crouch, stand, k), -0.42 * (1 - k), 0.0, V(0)


ANIMS = [  # name, fn, seconds, keys, loop
    ("idle", p_idle, 3.0, 12, True), ("walk", p_walk, 1.0, 12, True), ("run", p_run, 0.7, 12, True),
    ("dig", p_dig, 0.75, 10, True), ("sweep", p_sweep, 1.0, 10, True), ("tantrum", p_tantrum, 0.45, 8, True),
    ("sit", p_sit, 4.0, 8, True), ("sleep", p_sleep, 3.0, 8, True), ("wave", p_wave, 1.4, 16, True),
    ("cheer", p_cheer, 0.7, 8, True), ("climb", p_climb, 1.1, 10, True), ("inspect", p_inspect, 5.0, 12, True),
    ("kick", p_kick, 0.6, 12, False), ("getup", p_getup, 1.3, 20, False),
]


def bake_clips(rig, scale_h=1.0):
    """Key every clip as its own action (AN_*) and push each to a muted NLA track."""
    poser = Poser(rig)
    ad = rig.animation_data_create()
    made = []
    for name, fn, secs, keys, loop in ANIMS:
        ad.action = None
        frames = max(2, int(round(secs * FPS)))
        for i in range(keys + 1):
            t = i / keys
            f = 1 + t * frames
            pose, dz, dy, hr = fn(0.0 if (loop and i == keys) else t)
            poser.apply(pose, dz * scale_h, dy * scale_h, hr)
            for pb in poser.pb:
                pb.keyframe_insert("rotation_quaternion", frame=f)
            poser.pb["Hips"].keyframe_insert("location", frame=f)
        act = ad.action
        act.name = "AN_" + name.capitalize()
        act.use_fake_user = True
        made.append(act)
    ad.action = None
    for act in made:
        tr = ad.nla_tracks.new()
        tr.name = act.name
        tr.strips.new(act.name, 1, act)
        tr.mute = True
    poser.apply({})
    return made
