import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy
from PIL import Image, ImageDraw, ImageFilter
from blib import *
from case_model import font, img_mat, decal_plane, HERE

def screen_image(path):
    """Écran 7" : image caméra du drone + interface de vol."""
    W, H = 1280, 760
    im = Image.new('RGB', (W, H)); d = ImageDraw.Draw(im)
    for y in range(H):  # vue aérienne stylisée : ciel → rue
        t = y / H
        c = (int(150 - 90 * t), int(160 - 90 * t), int(175 - 100 * t)) if t < .38 else (int(70 + 20 * t), int(68 + 18 * t), int(66 + 15 * t))
        d.line([(0, y), (W, y)], fill=c)
    d.polygon([(380, H), (590, 300), (690, 300), (900, H)], fill=(52, 52, 55))
    for k in range(6): d.rectangle([636, 330 + k * 75, 644, 360 + k * 75], fill=(210, 180, 60))
    for x, w, h in [(40, 220, 260), (260, 150, 180), (930, 240, 240), (1130, 160, 300)]: d.rectangle([x, 290 - h + 40, x + w, 300], fill=(95, 85, 78))
    d.rectangle([700, 460, 760, 520], fill=(120, 20, 25))
    im = im.filter(ImageFilter.GaussianBlur(1.2)); d = ImageDraw.Draw(im)
    cyan = (90, 230, 255); f = font(28); fs = font(22, False)
    d.text((24, 18), '● REC 01:42', fill=(255, 70, 70), font=f); d.text((W // 2, 18), 'OPTIQUE  ·  ZOOM 2.0×', fill=cyan, font=f, anchor='ma')
    d.text((W - 24, 18), 'GPS 18   ▂▄▆█   87%', fill=(235, 250, 255), font=f, anchor='ra')
    cx, cy = W // 2, H // 2
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], outline=(235, 250, 255), width=2); d.line([cx - 90, cy, cx - 50, cy], fill=(235, 250, 255), width=2); d.line([cx + 50, cy, cx + 90, cy], fill=(235, 250, 255), width=2)
    d.line([cx, cy - 90, cx, cy - 50], fill=(235, 250, 255), width=2); d.line([cx, cy + 50, cx, cy + 90], fill=(235, 250, 255), width=2)
    for i, (k, v) in enumerate([('ALT', '42.6 m'), ('VIT', '18 km/h'), ('DIST', '126 m'), ('CAP', '274°')]):
        d.text((24, 250 + i * 50), k, fill=cyan, font=fs); d.text((100, 246 + i * 50), v, fill=(240, 250, 255), font=f)
    d.rectangle([W // 2 - 140, H - 60, W // 2 + 140, H - 20], fill=(0, 0, 0)); d.text((W // 2, H - 52), 'EN VOL · SUIVI CIBLE', fill=(255, 200, 60), font=fs, anchor='ma')
    d.rectangle([690, 450, 770, 530], outline=(255, 60, 60), width=3)
    im.save(path)

def build_ctrl():
    """Radiocommande durcie ORIGIN RC-7 : écran 7" + manches. Haut de l'écran = +Y, face = +Z."""
    M = {
        'poly': mat('rc_poly', (0.016, 0.016, 0.018), rough=0.5, wear=0.6, wear_color=(0.13, 0.13, 0.14), wear_rough=0.35, grain=0.05, grain_scale=1500),
        'rubber': mat('rc_rubber', (0.012, 0.012, 0.012), rough=0.93, grain=0.5, grain_scale=700),
        'steel': mat('rc_steel', (0.5, 0.5, 0.52), rough=0.3, metal=1.0),
        'glass': mat('rc_glass', (0.0, 0.0, 0.0), rough=0.02, coat=1.0),
        'paint': mat('rc_paint', (0.55, 0.55, 0.56), rough=0.6),
        'red': mat('rc_red', (0.5, 0.02, 0.02), rough=0.4, emit=(1, 0.05, 0.03), emit_strength=6),
    }
    sp = os.path.join(HERE, 'tex', 'screen.png'); screen_image(sp)
    scr = bpy.data.materials.new('rc_screen'); scr.use_nodes = True; nt = scr.node_tree; bs = nt.nodes['Principled BSDF']
    tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = bpy.data.images.load(sp)
    nt.links.new(tx.outputs['Color'], bs.inputs['Base Color']); nt.links.new(tx.outputs['Color'], bs.inputs['Emission Color'])
    bs.inputs['Emission Strength'].default_value = 0.9; bs.inputs['Roughness'].default_value = 0.05; bs.inputs['Coat Weight'].default_value = 1.0
    root = bpy.data.objects.new('ORIGIN_RC7', None); bpy.context.scene.collection.objects.link(root)
    # corps + poignées ergonomiques
    def body_shape(v):
        if abs(v.x) > 0.1: v.z -= 0.006 * (abs(v.x) - 0.1) / 0.035
        return v
    body = box('rcBody', (0.27, 0.165, 0.032), (0, 0, 0), M['poly'], bevel=0.012, seg=4, cuts=4, shape=body_shape, parent=root, angle=25)
    for sx in (-1, 1):
        def grip_shape(v, sx=sx):
            v.z -= 0.012 * max(0, -v.y / 0.06); return v
        box(f'grip{sx}', (0.06, 0.13, 0.05), (sx * 0.12, -0.03, -0.024), M['rubber'], bevel=0.022, seg=5, cuts=3, shape=grip_shape, parent=root, angle=20)
    # cadre + écran
    box('bezel', (0.172, 0.108, 0.004), (0, 0.012, 0.0158), M['poly'], bevel=0.004, parent=root)
    decal_plane('screen', 0.158, 0.094, (0, 0.012, 0.0181), (0, 0, 0), scr, parent=root)
    # manches (cardan + capuchon caoutchouc strié)
    for sx in (-1, 1):
        cyl(f'stickRing{sx}', 0.019, 0.004, (sx * 0.108, -0.032, 0.017), M['poly'], bevel=0.0015, verts=40, parent=root)
        cyl(f'stickBoot{sx}', 0.014, 0.006, (sx * 0.108, -0.032, 0.021), M['rubber'], r2=0.008, parent=root)
        cyl(f'stickShaft{sx}', 0.003, 0.016, (sx * 0.108, -0.032, 0.028), M['steel'], parent=root)
        cyl(f'stickCap{sx}', 0.0105, 0.007, (sx * 0.108, -0.032, 0.0375), M['rubber'], bevel=0.002, verts=24, parent=root)
        for k in range(12):
            th = k / 12 * math.tau
            box(f'capRib{sx}{k}', (0.0016, 0.003, 0.006), (sx * 0.108 + math.cos(th) * 0.0105, -0.032 + math.sin(th) * 0.0105, 0.0375), M['rubber'], rot=(0, 0, th), parent=root)
    # boutons (gauche : retour / photo ; droite : 4 boutons)
    for sx, sy, lab in [(-0.12, 0.04, 'RTH'), (-0.098, 0.04, 'FN')]:
        cyl(f'btn{lab}', 0.006, 0.004, (sx, sy, 0.017), M['poly'], bevel=0.0012, parent=root)
        text(f'lab{lab}', lab, 0.004, (sx, sy - 0.011, 0.0161), (0, 0, 0), M['paint'], parent=root)
    for (dx, dy) in [(0, 0.009), (0, -0.009), (0.009, 0), (-0.009, 0)]:
        cyl(f'abxy{dx}{dy}', 0.0045, 0.004, (0.11 + dx, 0.045 + dy, 0.017), M['poly'], bevel=0.0012, parent=root)
    cyl('power', 0.005, 0.004, (0.05, -0.058, 0.017), M['poly'], bevel=0.001, parent=root)
    box('powerLed', (0.012, 0.002, 0.001), (0.05, -0.0665, 0.0162), M['red'], parent=root)
    # molettes + gâchettes sur la tranche supérieure
    for sx in (-1, 1):
        cyl(f'wheel{sx}', 0.009, 0.006, (sx * 0.11, 0.083, 0.004), M['rubber'], rot=(0, math.radians(90), 0), verts=24, parent=root)
        box(f'trigger{sx}', (0.04, 0.012, 0.01), (sx * 0.075, 0.085, -0.004), M['poly'], bevel=0.003, parent=root)
    # antennes rabattables
    for sx in (-1, 1):
        piv = bpy.data.objects.new(f'antPiv{sx}', None); bpy.context.scene.collection.objects.link(piv); piv.parent = root
        piv.location = (sx * 0.075, 0.084, 0.008); piv.rotation_euler = (math.radians(-70), 0, 0)
        cyl(f'antHinge{sx}', 0.006, 0.03, (0, 0, 0), M['poly'], rot=(0, math.radians(90), 0), parent=piv)
        box(f'ant{sx}', (0.03, 0.008, 0.07), (0, 0, 0.038), M['poly'], bevel=0.004, parent=piv)
    # marquages
    text('rcLogo', 'ORIGIN  RC-7', 0.0075, (-0.03, -0.062, 0.0161), (0, 0, 0), M['paint'], parent=root)
    torus('lanyard', 0.007, 0.0022, (0.135, -0.07, -0.01), M['steel'], rot=(0, math.radians(90), 0), parent=root)
    return root

if __name__ == '__main__':
    out = sys.argv[-1]
    reset()
    rc = build_ctrl(); rc.location = (0, 0, 0.05); rc.rotation_euler = (math.radians(35), 0, 0)
    cam = studio(target=(0, 0.0, 0.06), cam_loc=(0.22, -0.36, 0.3), lens=55, samples=int(os.environ.get('SPP', '64')))
    render(os.path.join(out, 'ctrl_34.png'))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'orp_ctrl.blend'))
