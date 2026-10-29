"""Pistolet lourd « Sovereign » — inspiré du Pistol .50 et du Micro SMG de GTA. Canon = +X, haut = +Z, origine = prise en main."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(__file__))
import bpy
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from blib import *

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, 'tex'); os.makedirs(TEX, exist_ok=True)
S = 1024

# ─── Camos (textures raccordables, sans texte) ─────────────────────────────
def tile_noise(cells, seed, blur=0):
    """Bruit organique raccordable : petite grille aléatoire, tuilée 3×3, agrandie, recadrée au centre."""
    rnd = random.Random(seed)
    small = Image.new('L', (cells, cells))
    small.putdata([rnd.randint(0, 255) for _ in range(cells * cells)])
    big = Image.new('L', (cells * 3, cells * 3))
    for i in range(3):
        for j in range(3): big.paste(small, (i * cells, j * cells))
    big = big.resize((S * 3, S * 3), Image.BICUBIC)
    if blur: big = big.filter(ImageFilter.GaussianBlur(blur))
    return big.crop((S, S, 2 * S, 2 * S))

def mask(noise, lo, hi=256):
    return noise.point(lambda v: 255 if lo <= v < hi else 0)

def wrap_draw(img, fn):
    """Dessine un motif sur les 9 copies pour qu'il se raccorde sur les bords."""
    d = ImageDraw.Draw(img)
    for ox in (-S, 0, S):
        for oy in (-S, 0, S): fn(d, ox, oy)

def scratches(img, n, col, seed):
    rnd = random.Random(seed); d = ImageDraw.Draw(img)
    for _ in range(n):
        x, y = rnd.random() * S, rnd.random() * S; L = 10 + rnd.random() * 70; a = rnd.random() * math.tau
        d.line([(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], fill=col, width=1)

def camo_noir(path):
    """Noir « Obsidienne » : carbone forgé (paillettes noires / graphite) + écailles hexagonales en relief, micro-usure."""
    rnd = random.Random(31)
    img = Image.new('RGB', (S, S), (9, 9, 10))
    def flakes(d, ox, oy):
        r2 = random.Random(31)
        for _ in range(2600):
            x, y = r2.random() * S + ox, r2.random() * S + oy; L = 6 + r2.random() * 26; a = r2.random() * math.tau; w = 3 + r2.random() * 10
            v = r2.choice([7, 10, 13, 17, 22, 30, 38])
            pts = [(x + math.cos(a) * L - math.sin(a) * w, y + math.sin(a) * L + math.cos(a) * w), (x + math.cos(a) * L + math.sin(a) * w, y + math.sin(a) * L - math.cos(a) * w),
                   (x - math.cos(a) * L + math.sin(a) * w, y - math.sin(a) * L - math.cos(a) * w), (x - math.cos(a) * L - math.sin(a) * w, y - math.sin(a) * L + math.cos(a) * w)]
            d.polygon(pts, fill=(v, v, v + 2))
    wrap_draw(img, flakes)
    img = img.filter(ImageFilter.GaussianBlur(.7))
    R_ = 32; h = R_ * math.sqrt(3)
    hx = Image.new('L', (S, S), 0)
    def hexes(d, ox, oy):
        for row in range(int(S / h) + 3):
            for col in range(int(S / (1.5 * R_)) + 3):
                cx = col * 1.5 * R_ + ox; cy = row * h + (h / 2 if col % 2 else 0) + oy
                pts = [(cx + R_ * .96 * math.cos(math.radians(60 * k)), cy + R_ * .96 * math.sin(math.radians(60 * k))) for k in range(6)]
                d.line(pts + [pts[0]], fill=255, width=3)
    wrap_draw(hx, hexes)
    region = mask(tile_noise(7, 33, 8), 105).filter(ImageFilter.GaussianBlur(10))     # les écailles par grandes plaques
    hxm = ImageChops.multiply(hx.filter(ImageFilter.GaussianBlur(.6)), region)
    img = Image.composite(Image.new('RGB', (S, S), (58, 60, 66)), img, hxm.point(lambda v: v * 0.75).point(int))
    inner = ImageChops.multiply(ImageChops.invert(hx.filter(ImageFilter.MaxFilter(5))), region).point(lambda v: v * 0.25).point(int)
    img = Image.composite(Image.new('RGB', (S, S), (4, 4, 5)), img, inner)
    scratches(img, 90, (40, 40, 44), 3)
    img.save(path); return path

def camo_halloween(path):
    """Halloween cartoon : nuit violette, citrouilles souriantes, fantômes, chauves-souris, bonbons, étoiles — contours noirs épais."""
    img = Image.new('RGB', (S, S), (58, 30, 92))
    # léger dégradé de nuages violets (raccordable)
    clouds = tile_noise(5, 41, 14)
    img = Image.composite(Image.new('RGB', (S, S), (74, 40, 116)), img, clouds.point(lambda v: max(0, v - 110) * 2).point(int).filter(ImageFilter.GaussianBlur(8)))
    OUT = (16, 10, 22); W = 7
    rnd = random.Random(77)
    # placement en quinconce régulier (aspect « motif imprimé »), avec un peu d'aléatoire
    items = []
    kinds = ['pumpkin', 'ghost', 'bat', 'candy', 'pumpkin', 'moon', 'ghost', 'bat', 'candy', 'pumpkin', 'star', 'bat']
    n = 4; step = S / n; k = 0
    for row in range(n):
        for col in range(n):
            x = col * step + (step / 2 if row % 2 else 0) + rnd.uniform(-18, 18) + step / 2
            y = row * step + rnd.uniform(-18, 18) + step / 2
            items.append((kinds[k % len(kinds)], x, y, rnd.uniform(-.35, .35), rnd.uniform(.85, 1.1))); k += 1
    small = [(rnd.random() * S, rnd.random() * S) for _ in range(70)]
    def rot(pts, cx, cy, a): return [(cx + (px - cx) * math.cos(a) - (py - cy) * math.sin(a), cy + (px - cx) * math.sin(a) + (py - cy) * math.cos(a)) for px, py in pts]
    def star(d, x, y, r, col):
        pts = [(x + math.cos(math.radians(-90 + 36 * i)) * (r if i % 2 == 0 else r * .45), y + math.sin(math.radians(-90 + 36 * i)) * (r if i % 2 == 0 else r * .45)) for i in range(10)]
        d.polygon(pts, fill=col, outline=OUT, width=4)
    def draw(d, ox, oy):
        for x, y in small:   # petites étoiles et points scintillants
            x += ox; y += oy
            d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 236, 160))
        for kind, x, y, a, sc in items:
            x += ox; y += oy; r = 62 * sc
            if kind == 'pumpkin':
                for dx, c in ((-.45, (226, 102, 18)), (.45, (226, 102, 18)), (0, (250, 132, 30))):
                    d.ellipse([x + dx * r - r * .62, y - r * .78, x + dx * r + r * .62, y + r * .78], fill=c, outline=OUT, width=W)
                d.rounded_rectangle([x - 7, y - r * .78 - 20, x + 7, y - r * .78 + 6], 4, fill=(70, 140, 50), outline=OUT, width=4)
                d.ellipse([x + 4, y - r * .78 - 16, x + 34, y - r * .78 - 2], fill=(90, 175, 60), outline=OUT, width=4)
                for sx in (-1, 1): d.polygon(rot([(x + sx * r * .42, y - r * .32), (x + sx * r * .16, y - r * .08), (x + sx * r * .58, y - r * .04)], x, y, 0), fill=(40, 20, 10))
                d.chord([x - r * .55, y - r * .25, x + r * .55, y + r * .55], 10, 170, fill=(40, 20, 10))
                d.rectangle([x - r * .12, y + r * .15, x + r * .02, y + r * .3], fill=(250, 132, 30))
                d.ellipse([x - r * .7, y + r * .05, x - r * .45, y + r * .25], fill=(255, 150, 120))
                d.ellipse([x + r * .45, y + r * .05, x + r * .7, y + r * .25], fill=(255, 150, 120))
            elif kind == 'ghost':
                body = [(x - r * .55, y + r * .7)]
                for i in range(19):
                    t = math.pi + i / 18 * math.pi; body.append((x + math.cos(t) * r * .55, y - r * .15 + math.sin(t) * r * .6))
                for i, wx in enumerate([.55, .27, 0, -.27, -.55]):
                    body.append((x + wx * r, y + r * (.7 if i % 2 == 0 else .52)))
                d.polygon(rot(body, x, y, a), fill=(246, 244, 255), outline=OUT, width=W)
                for sx in (-1, 1): d.ellipse([x + sx * r * .2 - 8, y - r * .25 - 11, x + sx * r * .2 + 8, y - r * .25 + 11], fill=OUT)
                d.ellipse([x - 10, y + r * .02, x + 10, y + r * .2], fill=OUT)
                for sx in (-1, 1): d.ellipse([x + sx * r * .38 - 9, y - r * .02 - 5, x + sx * r * .38 + 9, y - r * .02 + 5], fill=(255, 170, 200))
            elif kind == 'bat':
                w = r * 1.05
                pts = [(x, y - w * .1), (x - w * .3, y - w * .42), (x - w * .5, y - w * .18), (x - w, y - w * .38), (x - w * .78, y + w * .1), (x - w * .55, y), (x - w * .35, y + w * .2), (x, y + w * .1),
                       (x + w * .35, y + w * .2), (x + w * .55, y), (x + w * .78, y + w * .1), (x + w, y - w * .38), (x + w * .5, y - w * .18), (x + w * .3, y - w * .42)]
                d.polygon(rot(pts, x, y, a), fill=(28, 18, 38), outline=(150, 100, 210), width=4)
                for sx in (-1, 1): d.ellipse([x + sx * 12 - 6, y - 12, x + sx * 12 + 6, y], fill=(255, 220, 90))
            elif kind == 'candy':
                pts = [(x, y + r * .75), (x - r * .48, y - r * .55), (x + r * .48, y - r * .55)]
                tri = rot(pts, x, y, a)
                d.polygon(tri, fill=(255, 250, 235), outline=OUT, width=W)
                band = [(x - r * .3, y - r * .05), (x + r * .3, y - r * .05), (x + r * .16, y + r * .33), (x - r * .16, y + r * .33)]
                d.polygon(rot(band, x, y, a), fill=(255, 140, 20))
                top = [(x - r * .48, y - r * .55), (x + r * .48, y - r * .55), (x + r * .3, y - r * .05), (x - r * .3, y - r * .05)]
                d.polygon(rot(top, x, y, a), fill=(255, 205, 40), outline=OUT, width=4)
            elif kind == 'moon':
                d.ellipse([x - r * .6, y - r * .6, x + r * .6, y + r * .6], fill=(255, 226, 120), outline=OUT, width=W)
                d.ellipse([x - r * .25, y - r * .75, x + r * .85, y + r * .35], fill=(58, 30, 92))
            elif kind == 'star':
                star(d, x, y, r * .6, (255, 226, 120))
    wrap_draw(img, draw)
    img.save(path); return path

def stipple(path):
    """Grip caoutchouc piqueté (texture de couleur + relief)."""
    rnd = random.Random(2); img = Image.new('RGB', (512, 512), (30, 30, 32)); d = ImageDraw.Draw(img)
    for _ in range(14000):
        x, y = rnd.random() * 512, rnd.random() * 512; r = 1 + rnd.random() * 2.2; v = 14 + rnd.randint(0, 22)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(v, v, v + 1))
    img.save(path); return path

# ─── Matières ──────────────────────────────────────────────────────────────
def camo_mat(name, img, rough=0.45, metal=0.35, wear_col=(0.42, 0.42, 0.44)):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; L = nt.links.new
    bs = nt.nodes['Principled BSDF']
    t = nt.nodes.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(img)
    # usure des arêtes : le métal apparaît sous la peinture
    bev = nt.nodes.new('ShaderNodeBevel'); bev.inputs['Radius'].default_value = 0.0012; bev.samples = 8
    geo = nt.nodes.new('ShaderNodeNewGeometry'); dot = nt.nodes.new('ShaderNodeVectorMath'); dot.operation = 'DOT_PRODUCT'
    L(bev.outputs[0], dot.inputs[0]); L(geo.outputs['Normal'], dot.inputs[1])
    inv = nt.nodes.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1; L(dot.outputs['Value'], inv.inputs[1])
    nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 140; nz.inputs['Detail'].default_value = 10
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; L(inv.outputs[0], mul.inputs[0]); L(nz.outputs['Fac'], mul.inputs[1])
    rp = nt.nodes.new('ShaderNodeValToRGB'); rp.color_ramp.elements[0].position = .02; rp.color_ramp.elements[1].position = .09; L(mul.outputs[0], rp.inputs['Fac'])
    wc = nt.nodes.new('ShaderNodeRGB'); wc.outputs[0].default_value = (*wear_col, 1)
    mix = nt.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; L(rp.outputs['Color'], mix.inputs['Factor']); L(t.outputs['Color'], mix.inputs[6]); L(wc.outputs[0], mix.inputs[7])
    # occlusion des creux : relief 3D (cavités plus sombres)
    ao = nt.nodes.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value = 0.012; ao.samples = 16
    aor = nt.nodes.new('ShaderNodeMapRange'); aor.inputs['To Min'].default_value = .25; L(ao.outputs['AO'], aor.inputs['Value'])
    aom = nt.nodes.new('ShaderNodeMix'); aom.data_type = 'RGBA'; aom.blend_type = 'MULTIPLY'; aom.inputs['Factor'].default_value = 1
    L(mix.outputs[2], aom.inputs[6]); L(aor.outputs['Result'], aom.inputs[7])
    L(aom.outputs[2], bs.inputs['Base Color'])
    mm = nt.nodes.new('ShaderNodeMix'); mm.data_type = 'FLOAT'; mm.inputs[2].default_value = metal; mm.inputs[3].default_value = 1.0; L(rp.outputs['Color'], mm.inputs['Factor']); L(mm.outputs[0], bs.inputs['Metallic'])
    # rugosité variable selon le motif (zones plus brillantes / plus mates)
    bw = nt.nodes.new('ShaderNodeRGBToBW'); L(t.outputs['Color'], bw.inputs[0])
    mr = nt.nodes.new('ShaderNodeMapRange'); mr.inputs['To Min'].default_value = rough + .15; mr.inputs['To Max'].default_value = rough - .12; mr.inputs['From Max'].default_value = .25
    L(bw.outputs[0], mr.inputs['Value']); L(mr.outputs['Result'], bs.inputs['Roughness'])
    gn = nt.nodes.new('ShaderNodeTexNoise'); gn.inputs['Scale'].default_value = 2200; bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = .04
    L(gn.outputs['Fac'], bp.inputs['Height'])
    # relief de la peinture suivant le motif du camo
    bp2 = nt.nodes.new('ShaderNodeBump'); bp2.inputs['Strength'].default_value = .35; bp2.inputs['Distance'].default_value = .0006
    L(bw.outputs[0], bp2.inputs['Height']); L(bp.outputs['Normal'], bp2.inputs['Normal']); L(bp2.outputs['Normal'], bs.inputs['Normal'])
    bs.inputs['Specular IOR Level'].default_value = .35
    m['p_img'] = img
    return m

def rubber_mat(name, img):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; bs = nt.nodes['Principled BSDF']; m['p_img'] = img
    t = nt.nodes.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(img); nt.links.new(t.outputs['Color'], bs.inputs['Base Color'])
    bw = nt.nodes.new('ShaderNodeRGBToBW'); nt.links.new(t.outputs['Color'], bw.inputs[0])
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 1.0; bp.inputs['Distance'].default_value = .0012
    nt.links.new(bw.outputs[0], bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], bs.inputs['Normal'])
    bs.inputs['Roughness'].default_value = .85
    return m

def cube_uv(o, size):
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=size, scale_to_bounds=False, correct_aspect=True)
    bpy.ops.object.mode_set(mode='OBJECT')

# ─── Modèle (profils dessinés d'après la référence, extrudés) ──────────────
PX = 0.0008                       # 1 px de la référence ≈ 0,8 mm
def P(px, py): return ((px - 70) * PX, (100 - py) * PX)

def profile(name, outer, holes, width, mat_, bevel=0.0012, parent=None, y=0.0):
    """Profil latéral (points en px de la référence) extrudé sur la largeur, arêtes arrondies."""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '2D'; cu.fill_mode = 'BOTH'
    cu.extrude = max(0.0005, width / 2 - bevel); cu.bevel_depth = bevel; cu.bevel_resolution = 3; cu.offset = 0
    for loop in [outer] + holes:
        sp = cu.splines.new('POLY'); sp.points.add(len(loop) - 1)
        for p, (px, py) in zip(sp.points, loop):
            x, z = P(px, py); p.co = (x, z, 0, 1)
        sp.use_cyclic_u = True
    o = bpy.data.objects.new(name, cu); bpy.context.scene.collection.objects.link(o)
    o.rotation_euler = (math.radians(90), 0, 0); o.location = (0, y, 0)
    cu.materials.append(mat_)
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.convert(target='MESH')
    o = bpy.context.active_object; o.name = name
    for p_ in o.data.polygons: p_.use_smooth = True
    w = o.modifiers.new('wn', 'WEIGHTED_NORMAL'); w.keep_sharp = True
    if parent: mw = o.matrix_world.copy(); o.parent = parent; o.matrix_world = mw
    return o

def grip_mat(name, camo_img, stip_img):
    """Polymère de la crosse : couleur du camo + relief piqueté."""
    m = camo_mat(name, camo_img, rough=0.75, metal=0.0)
    nt = m.node_tree; bs = nt.nodes['Principled BSDF']
    # crosse plus foncée que la carcasse
    src = bs.inputs['Base Color'].links[0].from_socket
    dk = nt.nodes.new('ShaderNodeMix'); dk.data_type = 'RGBA'; dk.blend_type = 'MULTIPLY'; dk.inputs['Factor'].default_value = 1.0
    dk.inputs[7].default_value = (0.55, 0.55, 0.58, 1); nt.links.new(src, dk.inputs[6]); nt.links.new(dk.outputs[2], bs.inputs['Base Color'])
    t = nt.nodes.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(stip_img)
    tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (5, 5, 5)
    nt.links.new(tc.outputs['UV'], mp.inputs['Vector']); nt.links.new(mp.outputs['Vector'], t.inputs['Vector'])
    bw = nt.nodes.new('ShaderNodeRGBToBW'); nt.links.new(t.outputs['Color'], bw.inputs[0])
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 1.0; bp.inputs['Distance'].default_value = .0018
    nt.links.new(bw.outputs[0], bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], bs.inputs['Normal'])
    return m

def build_gun(finish='noir'):
    camo = camo_noir(os.path.join(TEX, 'camo_noir.png')) if finish == 'noir' else camo_halloween(os.path.join(TEX, 'camo_halloween.png'))
    stip = stipple(os.path.join(TEX, 'stipple.png'))
    M = {
        'camo': camo_mat(f'camo_{finish}', camo, wear_col=(0.42, 0.42, 0.44) if finish == 'noir' else (0.55, 0.5, 0.6)),
        'grip': grip_mat(f'gripcamo_{finish}', camo, stip),
        'steel': mat(f'gunmetal_{finish}', (0.025, 0.025, 0.027), rough=0.3, metal=1.0, wear=0.9, wear_color=(0.5, 0.5, 0.52), wear_rough=0.18),
        'poly': mat(f'polymer_{finish}', (0.018, 0.018, 0.019), rough=0.55, wear=0.5, wear_color=(0.12, 0.12, 0.13), grain=0.2, grain_scale=900),
        'dark': mat(f'bore_{finish}', (0.003, 0.003, 0.003), rough=0.6),
        'brass': mat(f'brass_{finish}', (0.75, 0.55, 0.22), rough=0.25, metal=1.0),
        'sight': mat(f'tritium_{finish}', (0.1, 0.5, 0.12) if finish == 'noir' else (0.6, 0.2, 0.0), rough=0.3,
                     emit=(0.3, 1.0, 0.35) if finish == 'noir' else (1.0, 0.45, 0.05), emit_strength=8),
    }
    camo_parts = []
    root = bpy.data.objects.new(f'Sovereign_{finish}', None); bpy.context.scene.collection.objects.link(root)
    def E(name, parent=None):
        e = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(e); e.parent = parent or root; return e
    # ── culasse : chanfreins, nez incliné, stries inclinées ──
    slide = E('slideGroup')
    sl = profile('slide', [(27, 100), (29, 66), (34, 60), (250, 60), (266, 69), (268, 100)], [], 0.0256, M['camo'], bevel=0.0026, parent=slide)
    camo_parts.append(sl)
    tw = profile('slideTop', [(40, 61), (244, 61), (244, 56), (40, 56)], [], 0.0145, M['camo'], bevel=0.0018, parent=slide)   # bande supérieure chanfreinée
    camo_parts.append(tw)
    def serr(x0, n, step, lean):
        for k in range(n):
            for sy in (-1, 1):
                x, _ = P(x0 + k * step, 0)
                box(f'serr{x0}_{k}{sy}', (0.0026, 0.0042, 0.024), (x, sy * 0.0127, 0.0125), M['dark'], bevel=0.0009, rot=(0, math.radians(lean), 0), parent=slide)
    serr(40, 7, 6.2, -18)       # arrière, inclinées comme la référence
    serr(206, 4, 7.0, 18)       # avant
    ex, ez = P(105, 72); box('ejection', (0.034, 0.004, 0.011), (ex, -0.0127, ez), M['dark'], bevel=0.0012, parent=slide)
    ex, ez = P(90, 70); box('extractor', (0.016, 0.003, 0.004), (ex, -0.0132, ez), M['steel'], bevel=0.0007, parent=slide)
    rx, rz = P(42, 56); box('rearSight', (0.011, 0.02, 0.008), (rx, 0, rz + 0.003), M['steel'], bevel=0.0015, parent=slide)
    for sy in (-0.0062, 0.0062): sphere(f'rDot{sy}', 0.0015, (rx + 0.0055, sy, rz + 0.0045), M['sight'], parent=slide)
    fx, fz = P(244, 56); box('frontSight', (0.007, 0.0045, 0.008), (fx, 0, fz + 0.003), M['steel'], bevel=0.0012, parent=slide)
    sphere('fDot', 0.0017, (fx - 0.0035, 0, fz + 0.005), M['sight'], parent=slide)
    cx, cz = P(150, 58); cyl('optic', 0.004, 0.0015, (cx, 0, cz + 0.002), M['steel'], verts=6, parent=slide)   # petit emblème usiné (sans texte)
    # ── canon fileté qui dépasse ──
    bx, bz = P(268, 77)
    cyl('barrel', 0.0072, 0.024, (bx + 0.006, 0, bz), M['steel'], rot=(0, math.radians(90), 0), parent=root)
    for k in range(9): torus(f'thread{k}', 0.0072, 0.0009, (bx + 0.006 + k * 0.0019, 0, bz), M['steel'], rot=(0, math.radians(90), 0), parent=root)
    cyl('bore', 0.0049, 0.026, (bx + 0.0065, 0, bz), M['dark'], rot=(0, math.radians(90), 0), parent=root)
    # ── carcasse polymère : cache-poussière + pontet arrondi (avec ouverture) ──
    fr = profile('frame', [(98, 100), (266, 100), (266, 120), (262, 127), (214, 128), (208, 138), (206, 150), (199, 159), (186, 162), (140, 163), (124, 160), (114, 152), (110, 128), (98, 124)],
                 [[(196, 131), (194, 147), (187, 154), (138, 155), (126, 150), (122, 131)]], 0.0226, M['camo'], bevel=0.0022, parent=root)
    camo_parts.append(fr)
    for k in range(3):
        rx_, rz_ = P(190 + k * 22, 127); box(f'railSlot{k}', (0.004, 0.0232, 0.0035), (rx_, 0, rz_ + 0.0012), M['dark'], parent=root)
    # ── crosse inclinée naturellement, piquetée ──
    gr = profile('grip', [(24, 104), (112, 104), (113, 130), (115, 150), (110, 160), (106, 170), (103, 180), (105, 190), (101, 200), (99, 212), (101, 222), (96, 232), (94, 244), (92, 256), (88, 268), (44, 273), (39, 262), (32, 236), (27, 205), (25, 170), (24, 145), (20, 128), (13, 116), (8, 112), (12, 108), (18, 106)],
                 [], 0.03, M['grip'], bevel=0.0105, parent=root)
    camo_parts.append(gr)
    # ── chargeur (talon rallongé) ──
    gp = E('gripPivot'); x0, z0 = P(60, 120); gp.location = (x0, 0, z0); gp.rotation_euler = (0, math.radians(-9), 0)
    mag = E('magGroup', gp)
    bx_, bz_ = P(58, 276)
    mb = box('magBase', (0.05, 0.03, 0.012), (bx_ - x0 + 0.002, 0, bz_ - z0), M['poly'], bevel=0.003, parent=mag)
    box('magBody', (0.03, 0.02, 0.12), (bx_ - x0 + 0.004, 0, bz_ - z0 + 0.065), M['steel'], bevel=0.002, parent=mag)
    # ── commandes ──
    tp = E('triggerPivot'); tx, tz = P(150, 128); tp.location = (tx, 0, tz)
    bpy.ops.curve.primitive_bezier_curve_add(); tg = bpy.context.active_object; tg.name = 'trigger'
    sp = tg.data.splines[0]
    sp.bezier_points[0].co = (0, 0, 0); sp.bezier_points[0].handle_left = (-0.003, 0, 0.003); sp.bezier_points[0].handle_right = (0.004, 0, -0.006)
    sp.bezier_points[1].co = (0.006, 0, -0.02); sp.bezier_points[1].handle_left = (0.006, 0, -0.012); sp.bezier_points[1].handle_right = (0.006, 0, -0.024)
    tg.data.bevel_depth = 0.0026; tg.data.bevel_resolution = 3; tg.data.materials.append(M['steel']); tg.parent = tp
    box('triggerSafety', (0.002, 0.003, 0.008), (0.005, 0, -0.012), M['dark'], parent=tp)
    sx_, sz_ = P(140, 104); box('slideStop', (0.032, 0.0035, 0.005), (sx_, 0.0123, sz_), M['steel'], bevel=0.0012, parent=root)
    box('slideStopTab', (0.008, 0.005, 0.007), (sx_ - 0.014, 0.0135, sz_ + 0.001), M['steel'], bevel=0.0015, parent=root)
    tx2, tz2 = P(172, 110); cyl('takedown', 0.0035, 0.004, (tx2, 0.0122, tz2), M['steel'], rot=(math.radians(90), 0, 0), verts=16, parent=root)
    mx_, mz_ = P(117, 132); box('magRelease', (0.007, 0.004, 0.009), (mx_, -0.013, mz_), M['steel'], bevel=0.0018, parent=root)
    for sy in (-1, 1):
        for px in (80, 196):
            x, z = P(px, 116); cyl(f'pin{sy}{px}', 0.0018, 0.0015, (x, sy * 0.0115, z), M['steel'], rot=(math.radians(90), 0, 0), verts=12, parent=root)
    E('hammerPivot')    # pistolet à percuteur : pivot vide (conservé pour l'aperçu)
    sphere('round', 0.0045, (P(82, 96)[0], 0, 0.002), M['brass'], scale=(1.6, 1, 1), parent=mag)
    for o in camo_parts: cube_uv(o, 0.1 if finish == 'noir' else 0.19)
    return root

if __name__ == '__main__':
    out = sys.argv[-1]; spp = int(os.environ.get('SPP', '64'))
    for finish in sys.argv[-2].split(','):
        reset()
        r = build_gun(finish)
        r.rotation_euler = (0, 0, math.radians(-90)); r.location = (0, 0, 0.16)
        cam = studio(target=(0.0, -0.05, 0.12), cam_loc=(0.5, -0.62, 0.3), lens=55, samples=spp, res=(1600, 1000))
        bpy.data.lights['rim2'].energy = 3; bpy.data.lights['key'].color = (0.96, 0.97, 1.0); bpy.data.lights['fill'].energy = 35
        render(os.path.join(out, f'gun_{finish}_34.png'))
        aim(cam, (-0.62, -0.06, 0.12), (0.0, -0.06, 0.12)); render(os.path.join(out, f'gun_{finish}_side.png'))
        aim(cam, (0.45, 0.4, 0.32), (0, -0.04, 0.12)); render(os.path.join(out, f'gun_{finish}_rear.png'))

def camo_yusuf(path):
    """Finition luxe « Yusuf Amir » : or brossé gravé de rinceaux baroques (volutes + feuilles), traits sombres en creux."""
    rnd = random.Random(9)
    base = Image.new('RGB', (S, S), (168, 118, 38))
    br = tile_noise(48, 3, 0).resize((S, S)).filter(ImageFilter.BoxBlur(0))
    streak = Image.effect_noise((S, 8), 40).resize((S, S)).convert('L')  # brossage horizontal
    base = Image.composite(Image.new('RGB', (S, S), (200, 150, 62)), base, ImageChops.multiply(streak, br).point(lambda v: min(255, v * 2)))
    eng = Image.new('L', (S, S), 0)   # masque de gravure
    hi = Image.new('L', (S, S), 0)    # reflet du bord de gravure
    def spiral(cx, cy, r0, turns, sgn, a0):
        pts = []
        for i in range(int(turns * 40)):
            t = i / 40; a = a0 + sgn * t * math.tau; r = r0 * (1 - t / (turns + .3))
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        return pts
    def leaf(cx, cy, a, L):
        p = []
        for i in range(13):
            t = i / 12; w = math.sin(t * math.pi) * L * .28
            p.append((cx + math.cos(a) * t * L - math.sin(a) * w, cy + math.sin(a) * t * L + math.cos(a) * w))
        for i in range(12, -1, -1):
            t = i / 12; w = math.sin(t * math.pi) * L * .28
            p.append((cx + math.cos(a) * t * L + math.sin(a) * w, cy + math.sin(a) * t * L - math.cos(a) * w))
        return p
    motifs = []
    N = 4; step = S / N
    for gx in range(N):
        for gy in range(N):
            cx = gx * step + step / 2 + (step / 2 if gy % 2 else 0); cy = gy * step + step / 2
            sgn = 1 if (gx + gy) % 2 else -1; a0 = rnd.random() * math.tau
            sp = spiral(cx, cy, step * .42, 1.6, sgn, a0)
            lv = [leaf(*sp[k], a0 + sgn * k / 40 * math.tau + sgn * 1.2, step * (.16 + rnd.random() * .06)) for k in range(6, len(sp) - 20, 9)]
            motifs.append((sp, lv))
    for gx in range(N):
        for gy in range(N):
            cx = gx * step + (step / 2 if gy % 2 else 0); cy = gy * step; sgn = -1 if (gx + gy) % 2 else 1; a0 = rnd.random() * math.tau
            sp = spiral(cx, cy, step * .2, 1.3, sgn, a0)
            motifs.append((sp, [leaf(*sp[k], a0 + sgn * k / 40 * math.tau + sgn * 1.2, step * .1) for k in range(4, len(sp) - 14, 10)]))
    def draw(d, ox, oy, col, off):
        for sp, lv in motifs:
            d.line([(x + ox + off, y + oy + off) for x, y in sp], fill=col, width=5, joint='curve')
            for l in lv:
                d.polygon([(x + ox + off, y + oy + off) for x, y in l], outline=col, width=3)
                d.line([(x + ox + off, y + oy + off) for x, y in l[:7]], fill=col, width=2)
    wrap_draw(eng, lambda d, ox, oy: draw(d, ox, oy, 255, 0))
    wrap_draw(hi, lambda d, ox, oy: draw(d, ox, oy, 255, 2))
    hi = ImageChops.subtract(hi, eng)
    img = Image.composite(Image.new('RGB', (S, S), (58, 36, 10)), base, eng.filter(ImageFilter.GaussianBlur(.8)))
    img = Image.composite(Image.new('RGB', (S, S), (250, 214, 130)), img, hi.point(lambda v: v * .6).point(int))
    scratches(img, 120, (170, 124, 42), 5)
    img.save(path); return path

def solid(path, col):
    """Finition unie (cerakote) : couleur pleine avec un très léger grain."""
    n = tile_noise(64, 5, 0).resize((S, S))
    img = Image.new('RGB', (S, S), col)
    dk = Image.new('RGB', (S, S), tuple(int(c * .88) for c in col))
    img = Image.composite(dk, img, n.point(lambda v: int(v * .5)))
    # crasse dans les zones peu manipulées + micro-rayures : aspect peinture cerakote usée
    g = tile_noise(6, 17, 10).resize((S, S)).point(lambda v: max(0, v - 120) * 1.4).point(int)
    img = Image.composite(Image.new('RGB', (S, S), tuple(int(c * .55) for c in col)), img, g)
    scratches(img, 260, tuple(min(255, int(c * 1.25 + 25)) for c in col), 11)
    scratches(img, 140, tuple(int(c * .6) for c in col), 12)
    img.save(path); return path
