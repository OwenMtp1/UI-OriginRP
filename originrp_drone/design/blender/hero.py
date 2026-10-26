import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy
from blib import *
from drone_model import build_drone
from case_model import build_case
from ctrl_model import build_ctrl
out = sys.argv[-1]; spp = int(os.environ.get('SPP', '96'))
def scene_single(fn, name, target, cam_loc, lens=50, setup=None):
    reset(); o = fn()
    if setup: setup(o)
    studio(target=target, cam_loc=cam_loc, lens=lens, samples=spp, res=(1600, 1000))
    render(os.path.join(out, name))
which = sys.argv[-2]
if which == 'drone': scene_single(lambda: build_drone(0.0)[0], 'final_drone.png', (0, 0.02, 0.09), (0.6, 0.66, 0.36))
if which == 'case': scene_single(lambda: build_case(0.0), 'final_case.png', (0, 0, 0.15), (0.95, -1.15, 0.75))
if which == 'ctrl': scene_single(build_ctrl, 'final_ctrl.png', (0, 0.0, 0.06), (0.24, -0.42, 0.32), 50, lambda o: (setattr(o, 'location', (0, 0, 0.05)), setattr(o, 'rotation_euler', (math.radians(35), 0, 0))))
if which == 'hero':
    reset()
    c = build_case(0.0)
    d, _ = build_drone(0.0); d.location = (-0.05, 0.02, 0.32); d.rotation_euler = (0, 0, math.radians(-25))
    r = build_ctrl(); r.location = (0.32, -0.42, 0.075); r.rotation_euler = (math.radians(62), 0, math.radians(-12))
    studio(target=(0, -0.1, 0.25), cam_loc=(1.15, -1.55, 0.85), lens=45, samples=spp, res=(1920, 1080))
    render(os.path.join(out, 'final_hero.png'))

if which == 'wreck':
    from drone_model import build_wreck, smoke
    reset(); build_wreck()
    smoke((0.03, 0.02, 0.32), 0.3, 7.0); smoke((0.08, 0.1, 0.75), 0.45, 4.0)
    studio(target=(0, 0, 0.2), cam_loc=(0.85, -1.0, 0.55), lens=45, samples=spp, res=(1600, 1000))
    bpy.context.scene.cycles.volume_step_rate = 4
    render(os.path.join(out, 'final_wreck.png'))
