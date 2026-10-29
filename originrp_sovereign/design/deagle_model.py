"""Cal .50 canon long « Sovereign » — inspiré du Desert Eagle. Canon = +X, haut = +Z, origine = prise en main."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy, bmesh
from mathutils import Vector
from blib import *
from gun_model import camo_noir, camo_halloween, camo_yusuf, solid, stipple, camo_mat, rubber_mat, cube_uv, TEX

def section_prism(name, yz, x0, x1, mat_=None):
    """Prisme : section (y, z) extrudée le long de X."""
    bm = bmesh.new()
    vs = [bm.verts.new((x0, y, z)) for y, z in yz]
    f = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[f])
    nv = [e for e in r['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=nv, vec=(x1 - x0, 0, 0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    o = mesh_obj(name, bm, mat_)
    return o

def side_prism(name, xz, width):
    """Prisme : profil latéral (x, z) extrudé sur Y."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, -width / 2, z)) for x, z in xz]
    f = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[f])
    nv = [e for e in r['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=nv, vec=(0, width, 0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return mesh_obj(name, bm, None)

def apply_bool(target, cutter, op):
    m = target.modifiers.new('b', 'BOOLEAN'); m.object = cutter; m.operation = op; m.solver = 'EXACT'
    bpy.ops.object.select_all(action='DESELECT'); target.select_set(True); bpy.context.view_layer.objects.active = target
    bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.data.objects.remove(cutter)

def cutter_box(size, loc, rot=(0, 0, 0)):
    return box('cut', size, loc, None, rot=rot)

def cutter_cyl(r, h, loc, rot=(0, 0, 0)):
    return cyl('cutc', r, h, loc, None, rot=rot, verts=32)

def finish_part(o, mat_, bevel=0.0009, uv=None, parent=None):
    o.data.materials.clear(); o.data.materials.append(mat_)
    for p in o.data.polygons: p.use_smooth = True
    if uv: cube_uv(o, uv)
    b = o.modifiers.new('bevel', 'BEVEL'); b.width = bevel; b.segments = 2; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(30); b.use_clamp_overlap = True
    w = o.modifiers.new('wn', 'WEIGHTED_NORMAL'); w.keep_sharp = True
    if parent: o.parent = parent
    return o

# finitions unies : (couleur peinture sRGB, teinte linéaire des pièces métal, rugosité, métal)
SOLID = {'bleu': ((22, 62, 160), None, 0.34, 0.65),
         'rose': ((214, 78, 142), None, 0.34, 0.6),
         'noirmat': ((24, 24, 26), None, 0.62, 0.35)}

def build_deagle(finish='noir'):
    if finish in SOLID: return build_solid(finish)
    return _build(finish, None)

def build_solid(finish):
    return _build(finish, SOLID[finish])

def _build(finish, sol):
    if sol:
        col, tint, rgh, mtl = sol
        camo = solid(os.path.join(TEX, f'solid_{finish}.png'), col)
    else: camo = {'noir': lambda: camo_noir(os.path.join(TEX, 'camo_noir.png')), 'halloween': lambda: camo_halloween(os.path.join(TEX, 'camo_halloween.png')),
            'yusuf': lambda: camo_yusuf(os.path.join(TEX, 'camo_yusuf.png'))}[finish]()
    stip = stipple(os.path.join(TEX, 'stipple.png'))
    if sol:
        # tout de la même couleur : peinture unie + pièces métal teintées
        # peinture couleur sur la carcasse ; acier bronzé, caoutchouc et rail restent noirs (contraste façon GTA)
        M = {
            'camo': camo_mat(f'camo_{finish}', camo, rough=rgh, metal=mtl, wear_col=(0.3, 0.3, 0.32)),
            'steel': mat(f'steel_{finish}', (0.02, 0.02, 0.022), rough=0.3, metal=1.0, wear=0.6, wear_color=(0.14, 0.14, 0.15), wear_rough=0.25),
            'polish': mat(f'polish_{finish}', (0.06, 0.06, 0.065), rough=0.3, metal=1.0),
            'rubber': mat(f'rubber_{finish}', (0.008, 0.008, 0.009), rough=0.85, grain=1.6, grain_scale=380),
            'dark': mat(f'bore_{finish}', (0.002, 0.002, 0.002), rough=0.5),
            'fiber': mat(f'fiber_{finish}', (0.6, 0.02, 0.01), rough=0.15, emit=(1.0, 0.05, 0.02), emit_strength=12),
            'panel': rubber_mat(f'panel_{finish}', stip),
            'dot': mat(f'dot_{finish}', (0.03, 0.03, 0.03), rough=0.5),
        }
        UVS = 0.11
        return _model(finish, M, UVS)
    accent = {'noir': (0.75, 0.76, 0.78), 'halloween': (0.95, 0.38, 0.03), 'yusuf': (1.0, 0.72, 0.28)}[finish]
    UVS = {'noir': 0.11, 'halloween': 0.2, 'yusuf': 0.07}[finish]
    wear = {'noir': (0.11, 0.11, 0.12), 'halloween': (0.2, 0.12, 0.26), 'yusuf': (0.42, 0.28, 0.08)}[finish]
    M = {
        'camo': camo_mat(f'camo_{finish}', camo, rough=0.24 if finish == 'yusuf' else 0.38, metal=1.0 if finish == 'yusuf' else 0.5, wear_col=wear),
        'steel': mat(f'steel_{finish}', (0.02, 0.02, 0.022), rough=0.28, metal=1.0, wear=0.6, wear_color=(0.1, 0.1, 0.105), wear_rough=0.3),
        'polish': mat(f'polish_{finish}', {'noir': (0.07, 0.07, 0.075), 'halloween': tuple(c * 0.35 for c in accent), 'yusuf': (0.62, 0.42, 0.14)}[finish], rough=0.3, metal=1.0),
        'rubber': mat(f'rubber_{finish}', (0.008, 0.008, 0.009), rough=0.82, grain=1.6, grain_scale=380),
        'dark': mat(f'bore_{finish}', (0.002, 0.002, 0.002), rough=0.5),
        'fiber': mat(f'fiber_{finish}', (0.6, 0.02, 0.01), rough=0.15, emit=(1.0, 0.05, 0.02), emit_strength=12),
        'panel': rubber_mat(f'panel_{finish}', stip),
        'dot': mat(f'dot_{finish}', (0.03, 0.03, 0.03), rough=0.5),
    }
    return _model(finish, M, UVS)

def _model(finish, M, UVS):
    root = bpy.data.objects.new(f'Sovereign50_{finish}', None); bpy.context.scene.collection.objects.link(root)
    def E(n, parent=None):
        e = bpy.data.objects.new(n, None); bpy.context.scene.collection.objects.link(e); e.parent = parent or root; return e

    # ── canon long à section triangulaire (fixe) ──
    BX0, BX1 = 0.05, 0.37
    barrel_sec = [(-0.0122, 0.031), (0.0122, 0.031), (0.0122, 0.054), (0.0048, 0.0695), (-0.0048, 0.0695), (-0.0122, 0.054)]
    brl = section_prism('barrel', barrel_sec, BX0, BX1)
    side = side_prism('bside', [(BX0 - .01, 0.02), (BX1 - 0.004, 0.02), (BX1, 0.034), (BX1, 0.08), (BX0 - .01, 0.08)], 0.05)
    apply_bool(brl, side, 'INTERSECT')
    apply_bool(brl, cutter_cyl(0.0058, 0.06, (BX1, 0, 0.045), (0, math.radians(90), 0)), 'DIFFERENCE')          # âme
    for sy in (-1, 1):   # cannelures longues sur les flancs
        apply_bool(brl, cutter_box((0.24, 0.006, 0.0036), (0.2, sy * 0.0135, 0.043)), 'DIFFERENCE')
    for k in range(3):   # frein de bouche : évents supérieurs
        apply_bool(brl, cutter_box((0.007, 0.013, 0.03), (BX1 - 0.03 + k * 0.0105, 0, 0.067)), 'DIFFERENCE')
    for k in range(10):   # stries anti-reflet transversales devant le guidon
        apply_bool(brl, cutter_box((0.0016, 0.012, 0.004), (BX1 - 0.03 - 0.022 - k * 0.0042, 0, 0.0705)), 'DIFFERENCE')
    for sy in (-1, 1):    # goupille de verrou du canon
        apply_bool(brl, cutter_cyl(0.0022, 0.004, (0.07, sy * 0.0122, 0.038), (math.radians(90), 0, 0)), 'DIFFERENCE')
    finish_part(brl, M['camo'], uv=UVS, parent=root)
    for k in range(6):    # rayures (polygonales) visibles dans l'âme
        a = k / 6 * math.tau
        box(f'rifling{k}', (0.02, 0.0012, 0.0012), (BX1 - 0.008, math.cos(a) * 0.0055, 0.045 + math.sin(a) * 0.0055), M['steel'], rot=(a, 0, 0), parent=root)
    for sy in (-1, 1):
        cyl(f'barrelPin{sy}', 0.0018, 0.003, (0.07, sy * 0.0118, 0.038), M['polish'], rot=(math.radians(90), 0, 0), verts=14, parent=root)
    box('barrelLug', (0.03, 0.016, 0.006), (0.08, 0, 0.0285), M['steel'], bevel=0.001, parent=root)
    # rail sur le canon
    box('railBase', (0.2, 0.0085, 0.004), (0.17, 0, 0.0715), M['steel'], bevel=0.0008, parent=root)
    for k in range(17): box(f'rail{k}', (0.0046, 0.014, 0.0036), (0.077 + k * 0.0118, 0, 0.0745), M['steel'], bevel=0.0007, parent=root)
    # guidon fibre optique rouge
    box('frontSight', (0.012, 0.0065, 0.011), (BX1 - 0.042, 0, 0.0735), M['steel'], bevel=0.0012, parent=root)
    cyl('fiber', 0.0016, 0.012, (BX1 - 0.042, 0, 0.077), M['fiber'], rot=(0, math.radians(90), 0), parent=root)
    cyl('crown', 0.0068, 0.0015, (BX1 + 0.0002, 0, 0.045), M['polish'], rot=(0, math.radians(90), 0), parent=root)

    # ── culasse (mobile) : chanfreins, stries, fenêtre d'éjection ──
    slide = E('slideGroup')
    SX0, SX1 = -0.082, 0.052
    sl = section_prism('slide', [(-0.0158, 0.03), (0.0158, 0.03), (0.0158, 0.062), (0.0095, 0.077), (-0.0095, 0.077), (-0.0158, 0.062)], SX0, SX1)
    sside = side_prism('sside', [(SX0, 0.025), (SX1, 0.025), (SX1, 0.085), (SX0 + 0.006, 0.085), (SX0, 0.07)], 0.05)
    apply_bool(sl, sside, 'INTERSECT')
    for k in range(9):   # stries inclinées de chaque côté
        for sy in (-1, 1):
            apply_bool(sl, cutter_box((0.0022, 0.004, 0.034), (SX0 + 0.012 + k * 0.0048, sy * 0.016, 0.052), (0, math.radians(-14), 0)), 'DIFFERENCE')
    apply_bool(sl, cutter_box((0.04, 0.012, 0.018), (0.01, -0.012, 0.07), (math.radians(-28), 0, 0)), 'DIFFERENCE')   # fenêtre d'éjection
    for yy in (-0.004, 0.0, 0.004):   # rainures anti-reflet longitudinales sur le dessus
        apply_bool(sl, cutter_box((0.1, 0.0014, 0.0016), (SX0 + 0.07, yy, 0.077)), 'DIFFERENCE')
    finish_part(sl, M['camo'], uv=UVS, parent=slide)
    box('firingPinPlate', (0.002, 0.014, 0.022), (SX0 - 0.0005, 0, 0.052), M['polish'], bevel=0.0008, parent=slide)
    cyl('firingPin', 0.0016, 0.002, (SX0 - 0.0015, 0, 0.05), M['dark'], rot=(0, math.radians(90), 0), verts=12, parent=slide)
    cyl('chamberIndicator', 0.0022, 0.002, (0.03, 0, 0.0772), M['polish'], verts=14, parent=slide)
    box('barrelHood', (0.03, 0.02, 0.006), (0.014, 0, 0.058), M['steel'], bevel=0.001, parent=slide)
    box('extractor', (0.016, 0.0022, 0.004), (-0.017, -0.0158, 0.064), M['steel'], bevel=0.0006, parent=slide)
    # hausse à deux points + sûretés ambidextres
    rs = box('rearSight', (0.012, 0.024, 0.009), (SX0 + 0.012, 0, 0.0815), M['steel'], bevel=0.0013, parent=slide)
    apply_bool(rs, cutter_box((0.02, 0.0045, 0.008), (SX0 + 0.012, 0, 0.086)), 'DIFFERENCE')
    cyl('windageScrew', 0.0018, 0.003, (SX0 + 0.012, 0.0125, 0.0815), M['polish'], rot=(math.radians(90), 0, 0), verts=12, parent=slide)
    for sy in (-0.0068, 0.0068): sphere(f'rdot{sy}', 0.0014, (SX0 + 0.0063, sy, 0.0825), M['dot'], parent=slide)
    for sy in (-1, 1):
        cyl(f'safetyHub{sy}', 0.0048, 0.004, (SX0 + 0.012, sy * 0.0175, 0.05), M['polish'], rot=(math.radians(90), 0, 0), verts=24, parent=slide)
        box(f'safetyPaddle{sy}', (0.016, 0.003, 0.006), (SX0 + 0.02, sy * 0.0185, 0.054), M['polish'], bevel=0.0012, rot=(0, math.radians(-18), 0), parent=slide)

    # ── carcasse : sous le canon jusqu'à la crosse, pontet à crochet ──
    fr = side_prism('frame', [(-0.085, 0.031), (0.2, 0.031), (0.2, 0.012), (0.185, 0.0), (0.112, -0.002), (0.108, -0.016), (0.112, -0.03), (0.104, -0.044),
                              (0.044, -0.048), (0.028, -0.04), (0.022, -0.002), (-0.03, -0.003), (-0.074, 0.006), (-0.09, 0.022)], 0.0265)
    apply_bool(fr, side_prism('guardHole', [(0.034, -0.007), (0.1, -0.006), (0.1, -0.033), (0.094, -0.038), (0.042, -0.04), (0.034, -0.033)], 0.06), 'DIFFERENCE')
    for sy in (-1, 1):
        apply_bool(fr, cutter_box((0.07, 0.004, 0.0035), (0.15, sy * 0.0135, 0.019)), 'DIFFERENCE')    # rainure de rail
    for k in range(6):   # quadrillage à l'avant du pontet
        apply_bool(fr, cutter_box((0.004, 0.03, 0.0012), (0.11, 0, -0.012 - k * 0.0042)), 'DIFFERENCE')
    for sy in (-1, 1):   # joint carcasse / culasse
        apply_bool(fr, cutter_box((0.13, 0.002, 0.0012), (-0.02, sy * 0.0133, 0.0305)), 'DIFFERENCE')
    finish_part(fr, M['camo'], bevel=0.0012, uv=UVS, parent=root)
    cyl('guideRodCap', 0.0042, 0.003, (0.2015, 0, 0.018), M['polish'], rot=(0, math.radians(90), 0), verts=20, parent=root)
    cyl('guideRodHole', 0.0018, 0.004, (0.2025, 0, 0.018), M['dark'], rot=(0, math.radians(90), 0), verts=12, parent=root)
    box('serialPlate', (0.022, 0.0008, 0.006), (0.155, 0.0136, 0.011), M['polish'], bevel=0.0003, parent=root)
    for k in range(4): box(f'lrail{k}', (0.005, 0.021, 0.003), (0.13 + k * 0.016, 0, 0.0005), M['steel'], bevel=0.0006, parent=root)

    # ── crosse caoutchouc enveloppante (section ovale, rainures des doigts) ──
    gpts = [(-0.06, 0.0), (0.02, 0.0), (0.021, -0.01), (0.024, -0.02), (0.018, -0.03), (0.022, -0.04), (0.016, -0.05), (0.02, -0.06), (0.013, -0.07),
            (0.006, -0.12), (0.004, -0.128), (-0.05, -0.128), (-0.055, -0.1), (-0.058, -0.06), (-0.058, -0.03), (-0.064, -0.012), (-0.076, -0.004), (-0.07, 0.004)]
    rake = math.radians(-14)
    gpts = [(x * math.cos(rake) - z * math.sin(rake), x * math.sin(rake) + z * math.cos(rake)) for x, z in gpts]
    gr = side_prism('grip', gpts, 0.03)
    def along(p0, p1, n):
        for i in range(n):
            t = (i + .5) / n; yield (p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t)
    # arrondi d'abord (appliqué), puis stries peu profondes dans la surface arrondie
    bv = gr.modifiers.new('bevel0', 'BEVEL'); bv.width = 0.0055; bv.segments = 4; bv.limit_method = 'ANGLE'; bv.angle_limit = math.radians(30)
    bpy.ops.object.select_all(action='DESELECT'); gr.select_set(True); bpy.context.view_layer.objects.active = gr
    bpy.ops.object.modifier_apply(modifier='bevel0')
    front = (gpts[7], gpts[9]); back = (gpts[13], gpts[11])
    for x, z in along(*front, 9):
        apply_bool(gr, cutter_box((0.003, 0.022, 0.0013), (x + 0.0007, 0, z), (0, -rake, 0)), 'DIFFERENCE')
    for x, z in along(*back, 11):
        apply_bool(gr, cutter_box((0.003, 0.022, 0.0013), (x - 0.0007, 0, z), (0, -rake, 0)), 'DIFFERENCE')
    finish_part(gr, M['camo'], bevel=0.0004, uv=UVS, parent=root)
    lx, lz = gpts[11]

    gr.modifiers['bevel'].segments = 4
    # plaques caoutchouc piquetées, incrustées sur les flancs
    ppts = [(-0.048, -0.012), (0.008, -0.012), (0.01, -0.03), (0.006, -0.06), (0.0, -0.105), (-0.04, -0.11), (-0.046, -0.08), (-0.05, -0.04)]
    ppts = [(x * math.cos(rake) - z * math.sin(rake), x * math.sin(rake) + z * math.cos(rake)) for x, z in ppts]
    for sy in (-1, 1):
        pl = side_prism(f'gripPanel{sy}', ppts, 0.004)
        pl.location.y = sy * 0.0145
        pl.data.materials.clear(); pl.data.materials.append(M['panel']); cube_uv(pl, 0.05)
        for p in pl.data.polygons: p.use_smooth = True
        bv = pl.modifiers.new('bevel', 'BEVEL'); bv.width = 0.0016; bv.segments = 3; bv.limit_method = 'ANGLE'; bv.use_clamp_overlap = True
        pl.parent = root
        for (x, z) in ((-0.016, -0.03), (-0.04, -0.095)):
            cyl(f'panelScrew{sy}{x}', 0.0024, 0.0016, (x, sy * 0.0167, z), M['polish'], rot=(math.radians(90), 0, 0), verts=14, parent=root)
    # chargeur + talon
    gp = E('gripPivot'); gp.location = (-0.0365, 0, -0.061); gp.rotation_euler = (0, -rake, 0)
    mag = E('magGroup', gp)
    box('magBase', (0.052, 0.03, 0.011), (0.006, 0, -0.0705), M['steel'], bevel=0.003, parent=mag)
    box('magBumper', (0.044, 0.024, 0.004), (0.006, 0, -0.0775), M['rubber'], bevel=0.0015, parent=mag)
    box('magBody', (0.03, 0.02, 0.1), (0.002, 0, -0.016), M['steel'], bevel=0.002, parent=mag)

    # ── chien à anneau, détente, commandes ──
    hp = E('hammerPivot'); hp.location = (-0.086, 0, 0.04)
    box('hammerBase', (0.008, 0.009, 0.016), (0.0, 0, 0.002), M['steel'], bevel=0.002, parent=hp)
    box('hammerSpur', (0.012, 0.009, 0.006), (-0.006, 0, 0.011), M['steel'], bevel=0.002, rot=(0, math.radians(-20), 0), parent=hp)
    for k in range(3): box(f'spurSerr{k}', (0.0012, 0.0095, 0.0008), (-0.004 - k * 0.003, 0, 0.0142 + k * 0.0011), M['dark'], rot=(0, math.radians(-20), 0), parent=hp)
    tp = E('triggerPivot'); tp.location = (0.06, 0, -0.004)
    bpy.ops.curve.primitive_bezier_curve_add(); tg = bpy.context.active_object; tg.name = 'trigger'
    sp = tg.data.splines[0]
    sp.bezier_points[0].co = (0, 0, 0); sp.bezier_points[0].handle_left = (-0.004, 0, 0.004); sp.bezier_points[0].handle_right = (0.006, 0, -0.008)
    sp.bezier_points[1].co = (0.004, 0, -0.026); sp.bezier_points[1].handle_left = (0.008, 0, -0.016); sp.bezier_points[1].handle_right = (0.002, 0, -0.03)
    tg.data.bevel_depth = 0.0034; tg.data.bevel_resolution = 4; tg.data.materials.append(M['polish']); tg.parent = tp
    for k in range(5): box(f'trigSerr{k}', (0.0014, 0.0072, 0.0008), (0.0062, 0, -0.008 - k * 0.0035), M['dark'], parent=tp)
    cyl('trigScrew', 0.0012, 0.003, (-0.002, 0, -0.004), M['steel'], rot=(0, math.radians(90), 0), verts=10, parent=tp)
    box('slideStop', (0.045, 0.004, 0.006), (0.0, 0.0145, 0.026), M['steel'], bevel=0.0015, parent=root)
    cyl('slideStopKnob', 0.0045, 0.004, (-0.024, 0.016, 0.026), M['steel'], rot=(math.radians(90), 0, 0), verts=20, parent=root)
    cyl('takedown', 0.006, 0.004, (0.12, 0.0145, 0.016), M['polish'], rot=(math.radians(90), 0, 0), verts=24, parent=root)
    box('magRelease', (0.007, 0.004, 0.01), (0.03, -0.0145, -0.008), M['steel'], bevel=0.002, parent=root)
    for sy in (-1, 1):
        for x in (-0.06, 0.18): cyl(f'pin{sy}{x}', 0.0021, 0.0016, (x, sy * 0.0136, 0.015), M['polish'], rot=(math.radians(90), 0, 0), verts=14, parent=root)
    return root

if __name__ == '__main__':
    out = sys.argv[-1]; spp = int(os.environ.get('SPP', '64'))
    for finish in sys.argv[-2].split(','):
        reset()
        r = build_deagle(finish)
        r.rotation_euler = (0, 0, math.radians(-90)); r.location = (0, 0, 0.17)
        cam = studio(target=(0.0, -0.12, 0.15), cam_loc=(0.78, -1.0, 0.42), lens=55, samples=spp, res=(1600, 1000))
        L = bpy.data.lights; L['rim2'].energy = 1.2; L['key'].color = (0.96, 0.97, 1.0); L['key'].energy *= 1.3; L['fill'].energy = 9
        L['rim'].energy *= 0.6; L['top'].energy *= 0.3
        for n in ('rim', 'rim2', 'top'): L[n].size *= 3
        render(os.path.join(out, f'de_{finish}_34.png'))
        aim(cam, (-0.95, -0.13, 0.15), (0.0, -0.13, 0.15)); render(os.path.join(out, f'de_{finish}_side.png'))
        aim(cam, (0.6, 0.5, 0.4), (0, -0.1, 0.15)); render(os.path.join(out, f'de_{finish}_rear.png'))
