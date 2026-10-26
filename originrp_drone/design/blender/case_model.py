import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont
from blib import *

HERE = os.path.dirname(os.path.abspath(__file__))

def font(sz, bold=True):
    for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf']:
        if os.path.exists(p): return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def sticker_images(out):
    os.makedirs(out, exist_ok=True)
    im = Image.new('RGB', (600, 300), (238, 234, 222)); d = ImageDraw.Draw(im)
    d.rectangle([12, 12, 588, 288], fill=(196, 22, 28)); d.text((300, 130), 'FRAGILE', fill=(240, 236, 226), font=font(110), anchor='mm')
    d.text((300, 235), 'MATÉRIEL AÉRIEN · NE PAS RENVERSER', fill=(240, 236, 226), font=font(28), anchor='mm')
    im.save(os.path.join(out, 'fragile.png'))
    im = Image.new('RGB', (600, 300), (244, 244, 238)); d = ImageDraw.Draw(im)
    d.text((24, 22), 'ORIGIN RP · AIR UNIT', fill=(15, 15, 15), font=font(40))
    d.text((24, 80), 'MOD. OR-D2   S/N 0472-LS', fill=(15, 15, 15), font=font(30, False))
    d.text((24, 120), 'POIDS 9,8 kg   LI-ION UN3481', fill=(15, 15, 15), font=font(30, False))
    import random; random.seed(4); x = 24
    while x < 570:
        w = random.choice([2, 2, 4, 6]); d.rectangle([x, 175, x + w, 270], fill=(10, 10, 10)); x += w + random.choice([2, 3, 4])
    im.save(os.path.join(out, 'label.png'))

def img_mat(name, path, rough=0.6):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; bs = nt.nodes['Principled BSDF']
    t = nt.nodes.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(path)
    nt.links.new(t.outputs['Color'], bs.inputs['Base Color']); bs.inputs['Roughness'].default_value = rough
    return m

def decal_plane(name, w, h, loc, rot, m, parent=None):
    bpy.ops.mesh.primitive_plane_add(size=1, location=loc, rotation=rot); o = bpy.context.active_object; o.name = name
    o.scale = (w, h, 1); o.data.materials.append(m)
    if parent: o.parent = parent
    return o

def build_case(lid_open=0.0):
    """Mallette étanche OR-D2 (type flight case 82 × 56 × 32 cm). Avant = -Y, haut = +Z."""
    W, D, HB, HL = 0.82, 0.56, 0.205, 0.11
    sticker_images(os.path.join(HERE, 'tex'))
    M = {
        'shell': mat('pp_shell', (0.006, 0.006, 0.007), rough=0.58, wear=0.5, wear_color=(0.07, 0.07, 0.075), wear_rough=0.45, grain=0.6, grain_scale=1800, dust=0.05),
        'dark': mat('pp_dark', (0.008, 0.008, 0.009), rough=0.5, wear=0.6, wear_color=(0.09, 0.09, 0.1)),
        'rubber': mat('c_rubber', (0.015, 0.015, 0.015), rough=0.95, grain=0.4, grain_scale=500),
        'steel': mat('c_steel', (0.55, 0.55, 0.57), rough=0.3, metal=1.0, wear=0.5, wear_color=(0.3, 0.3, 0.3)),
        'paint': mat('stencil', (0.75, 0.75, 0.74), rough=0.7, dust=0.3),
        'yellow': mat('latch', (0.03, 0.031, 0.034), rough=0.4, wear=0.8, wear_color=(0.2, 0.2, 0.21)),
        'foam': mat('foam', (0.03, 0.03, 0.033), rough=1.0, grain=0.6, grain_scale=400),
    }
    root = bpy.data.objects.new('OR-D2_case', None); bpy.context.scene.collection.objects.link(root)
    # ── coque inférieure ──
    base = box('base', (W, D, HB), (0, 0, HB / 2), M['shell'], bevel=0.028, seg=4, parent=root, angle=30)
    # canaux de renfort façon double paroi (avant / arrière / côtés)
    cutters = []
    for x in (-0.3, -0.18, 0.18, 0.3):
        for sy in (-1, 1):
            c = box(f'ribcut{x}{sy}', (0.045, 0.03, 0.12), (x, sy * (D / 2 + 0.006), 0.1), None); cutters.append(c)
    for sx in (-1, 1):
        for y in (-0.14, 0.14):
            c = box(f'ribcutS{sx}{y}', (0.03, 0.045, 0.12), (sx * (W / 2 + 0.006), y, 0.1), None); cutters.append(c)
    for c in cutters: boolean(base, c)
    # pieds + roulettes + logement de poignée télescopique
    for x in (-0.33, 0.33): cyl(f'foot{x}', 0.022, 0.012, (x, -0.2, 0.004), M['rubber'], parent=root)
    for x in (-0.37, 0.37):
        cyl(f'wheel{x}', 0.046, 0.032, (x, D / 2 - 0.02, 0.046), M['rubber'], rot=(0, math.radians(90), 0), bevel=0.006, verts=40, parent=root)
        cyl(f'hub{x}', 0.02, 0.034, (x, D / 2 - 0.02, 0.046), M['steel'], rot=(0, math.radians(90), 0), parent=root)
    box('teleHousing', (0.36, 0.035, 0.06), (0, D / 2 + 0.012, 0.15), M['dark'], bevel=0.008, parent=root)
    # joint d'étanchéité (ligne entre base et couvercle)
    box('gasket', (W - 0.012, D - 0.012, 0.006), (0, 0, HB + 0.001), M['rubber'], bevel=0.004, parent=root)
    # ── couvercle ──
    hinge = bpy.data.objects.new('lidHinge', None); bpy.context.scene.collection.objects.link(hinge); hinge.parent = root
    hinge.location = (0, D / 2, HB + 0.004); hinge.rotation_euler = (math.radians(-104 * lid_open), 0, 0)
    lid = box('lid', (W, D, HL), (0, -D / 2, HL / 2), M['shell'], bevel=0.028, seg=4, parent=hinge, angle=30)
    recess = box('lidRecess', (W - 0.16, D - 0.16, 0.02), (0, -D / 2, HL + 0.004), None, parent=hinge); boolean(lid, recess)
    for x in (-0.3, -0.18, 0.18, 0.3):
        c = box(f'lidRib{x}', (0.045, 0.03, 0.07), (x, -D - 0.006, 0.045), None, parent=hinge); boolean(lid, c)
    # plaque logo en relief + marquages
    box('logoPlate', (0.26, 0.07, 0.006), (-0.12, -D / 2 - 0.08, HL - 0.003), M['dark'], bevel=0.004, parent=hinge)
    text('logo', 'ORIGIN', 0.045, (-0.12, -D / 2 - 0.083, HL + 0.0004), (0, 0, 0), M['paint'], extrude=0.0008, parent=hinge)
    text('stencil', 'AIR UNIT 07  ·  DRONE OR-D2', 0.026, (0, -D + 0.05, HL - 0.0055), (0, 0, 0), M['paint'], parent=hinge)
    decal_plane('fragile', 0.15, 0.075, (0.2, -D / 2 + 0.07, HL - 0.0055), (0, 0, math.radians(4)), img_mat('fragile', os.path.join(HERE, 'tex', 'fragile.png')), parent=hinge)
    decal_plane('label', 0.12, 0.06, (0.24, -D / 2 - 0.1, HL - 0.0055), (0, 0, math.radians(-3)), img_mat('label', os.path.join(HERE, 'tex', 'label.png')), parent=hinge)
    # valve de purge (molette crantée)
    cyl('valve', 0.022, 0.012, (-0.33, -D + 0.07, HL + 0.002), M['dark'], bevel=0.002, verts=40, parent=hinge)
    for k in range(20):
        th = k / 20 * math.tau
        box(f'knurl{k}', (0.003, 0.004, 0.01), (-0.33 + math.cos(th) * 0.022, -D + 0.07 + math.sin(th) * 0.022, HL + 0.002), M['dark'], rot=(0, 0, th), parent=hinge)
    # charnière à articulations
    for i in range(7):
        cyl(f'knuckle{i}', 0.012, 0.07, (-0.33 + i * 0.11, D / 2 + 0.008, HB + 0.004), M['dark'], rot=(0, math.radians(90), 0), bevel=0.002, parent=root)
    cyl('hingePin', 0.004, W - 0.08, (0, D / 2 + 0.008, HB + 0.004), M['steel'], rot=(0, math.radians(90), 0), parent=root)
    # ── loquets à double action (jaune de sécurité, comme sur les caisses pro) ──
    for x in (-0.25, 0.25):
        lp = bpy.data.objects.new(f'latch{x}', None); bpy.context.scene.collection.objects.link(lp); lp.parent = root; lp.location = (x, -D / 2 - 0.016, HB - 0.02)
        box(f'latchBody{x}', (0.085, 0.018, 0.085), (0, 0, 0.01), M['yellow'], bevel=0.007, seg=3, parent=lp)
        box(f'latchGrip{x}', (0.06, 0.008, 0.012), (0, -0.01, -0.022), M['yellow'], bevel=0.003, parent=lp)
        box(f'latchRecess{x}', (0.05, 0.004, 0.04), (0, -0.0095, 0.02), M['dark'], bevel=0.002, parent=lp)
        for sx in (-0.03, 0.03): cyl(f'latchPin{x}{sx}', 0.004, 0.006, (sx, -0.01, 0.045), M['steel'], rot=(math.radians(90), 0, 0), verts=12, parent=lp)
    # pattes de cadenas
    for x in (-0.37, 0.37):
        box(f'padTab{x}', (0.03, 0.02, 0.04), (x, -D / 2 - 0.008, HB), M['dark'], bevel=0.004, parent=root)
        torus(f'padHole{x}', 0.008, 0.0028, (x, -D / 2 - 0.019, HB), M['steel'], rot=(math.radians(90), 0, 0), parent=root)
    # ── poignée surmoulée caoutchouc ──
    box('handleBase', (0.2, 0.02, 0.03), (0, -D / 2 - 0.01, HB - 0.045), M['dark'], bevel=0.006, parent=root)
    bpy.ops.curve.primitive_bezier_curve_add(); cv = bpy.context.active_object; cv.name = 'handleCurve'
    sp = cv.data.splines[0]; sp.bezier_points[0].co = (-0.075, 0, 0); sp.bezier_points[1].co = (0.075, 0, 0)
    sp.bezier_points[0].handle_right = (-0.06, -0.05, 0); sp.bezier_points[1].handle_left = (0.06, -0.05, 0)
    sp.bezier_points[0].handle_left = (-0.09, 0.02, 0); sp.bezier_points[1].handle_right = (0.09, 0.02, 0)
    cv.data.bevel_depth = 0.013; cv.data.bevel_resolution = 6; cv.data.materials.append(M['rubber'])
    cv.location = (0, -D / 2 - 0.02, HB - 0.045); cv.rotation_euler = (math.radians(-80), 0, 0); cv.parent = root
    # ── intérieur : mousse prédécoupée ──
    if lid_open > 0:
        box('foamTop', (W - 0.04, D - 0.04, 0.02), (0, 0, HB - 0.012), M['foam'], bevel=0.004, parent=root)
        box('eggFoam', (W - 0.04, D - 0.04, 0.03), (0, -D / 2, 0.02), M['foam'], bevel=0.004, parent=hinge)
    return root

if __name__ == '__main__':
    out = sys.argv[-1]
    reset()
    build_case(0.0)
    cam = studio(target=(0, 0, 0.15), cam_loc=(0.95, -1.15, 0.75), lens=50, samples=int(os.environ.get('SPP', '64')))
    render(os.path.join(out, 'case_34.png'))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'orp_case.blend'))
