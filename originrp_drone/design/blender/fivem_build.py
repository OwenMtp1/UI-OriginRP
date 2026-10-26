"""Construit les 6 props OriginRP, les convertit en drawables Sollumz et exporte en XML CodeWalker (.ydr.xml + .ytyp.xml)."""
import sys, os, math, struct
sys.path.insert(0, os.path.dirname(__file__))
import bpy, addon_utils
from PIL import Image
from blib import reset
from drone_model import build_drone, build_wreck
from case_model import build_case
from ctrl_model import build_ctrl

OUT = sys.argv[-1]; EXPORT = os.path.join(OUT, 'export'); TEX = os.path.join(OUT, 'tex')
os.makedirs(EXPORT, exist_ok=True); os.makedirs(TEX, exist_ok=True)
reset()
addon_utils.enable('Sollumz', default_set=True)

def lin2srgb(c): return int(255 * (12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055))

def flat_textures():
    """Matières procédurales → Principled + petite texture unie (format attendu par Sollumz)."""
    done = {}
    for m in bpy.data.materials:
        p = m.get('p')
        if not p or not m.use_nodes: continue
        p = p.to_dict() if hasattr(p, 'to_dict') else p
        key = tuple(round(x, 4) for x in p['c'])
        if key not in done:
            path = os.path.join(TEX, 'orp_drone_c%02d.png' % len(done))
            Image.new('RGB', (16, 16), tuple(lin2srgb(x) for x in p['c'])).save(path); done[key] = path
        nt = m.node_tree; nt.nodes.clear()
        out = nt.nodes.new('ShaderNodeOutputMaterial'); bs = nt.nodes.new('ShaderNodeBsdfPrincipled'); nt.links.new(bs.outputs[0], out.inputs[0])
        tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = bpy.data.images.load(done[key]); nt.links.new(tx.outputs['Color'], bs.inputs['Base Color'])
        bs.inputs['Roughness'].default_value = p['r']; bs.inputs['Metallic'].default_value = p['m']

def bake_variant(name, root, x_offset):
    objs = [o for o in bpy.data.objects if o == root or root in o.children_recursive and True]
    objs = [root] + list(root.children_recursive)
    for o in list(objs):
        if o.type in ('FONT', 'CURVE') and not o.hide_render:
            bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
            bpy.ops.object.convert(target='MESH')
    objs = [root] + list(root.children_recursive)
    meshes = []
    for o in objs:
        if o.type != 'MESH': continue
        if o.hide_render: bpy.data.objects.remove(o); continue
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.convert(target='MESH')            # applique biseaux / booléens
        if not o.data.uv_layers: o.data.uv_layers.new(name='UVMap')
        meshes.append(o)
    empties = [o.name for o in [root] + list(root.children_recursive) if o.type == 'EMPTY']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw; o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    j = bpy.context.active_object; j.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for n in empties:
        if n in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[n])
    for uv in list(j.data.uv_layers)[1:]: j.data.uv_layers.remove(uv)
    j.location.x = x_offset
    print('TRIS', name, sum(len(p.vertices) - 2 for p in j.data.polygons))
    return j

VARIANTS = [
    ('orp_drone', lambda: build_drone(0.0)[0]),
    ('orp_drone_folded', lambda: build_drone(1.0)[0]),
    ('orp_drone_wreck', build_wreck),
    ('orp_dronecase', lambda: build_case(0.0)),
    ('orp_dronecase_open', lambda: build_case(1.0)),
    ('orp_drone_rc', build_ctrl),
]
joined = []
for i, (name, fn) in enumerate(VARIANTS):
    joined.append(bake_variant(name, fn(), i * 1.5))
flat_textures()
for j in joined:   # emplacements de matière vides → première matière de l'objet
    first = next((sl.material for sl in j.material_slots if sl.material), None)
    for sl in j.material_slots:
        if sl.material is None: sl.material = first

# ─── Sollumz : shaders, drawables, collisions, ytyp, export ───
bpy.ops.object.select_all(action='SELECT'); bpy.context.view_layer.objects.active = joined[0]
print('autoconvert', bpy.ops.sollumz.autoconvertmaterials())
drawables = []
for o in joined:
    name = o.name
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.sollumz.converttodrawable()
    dr = o.parent if o.parent else o
    dr.name = name; drawables.append(dr)

def write_dds(png, dds):
    img = Image.open(png).convert('RGBA'); w, h = img.size; levels = []; lw, lh = w, h
    while True:
        levels.append(img.resize((lw, lh), Image.LANCZOS) if (lw, lh) != (w, h) else img)
        if lw == 1 and lh == 1: break
        lw, lh = max(1, lw // 2), max(1, lh // 2)
    header = struct.pack('<4sIIIIIII44x', b'DDS ', 124, 0x1 | 0x2 | 0x4 | 0x8 | 0x1000 | 0x20000, h, w, w * 4, 0, len(levels))
    pf = struct.pack('<II4sIIIII', 32, 0x41, b'\0\0\0\0', 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000)
    caps = struct.pack('<IIII4x', 0x1000 | 0x8 | 0x400000, 0, 0, 0)
    with open(dds, 'wb') as f:
        f.write(header + pf + caps)
        for lv in levels:
            r, g, b_, a = lv.split(); f.write(Image.merge('RGBA', (b_, g, r, a)).tobytes())

for m in bpy.data.materials:
    if not m.node_tree: continue
    for n in m.node_tree.nodes:
        if n.bl_idname == 'ShaderNodeTexImage' and n.image and hasattr(n, 'texture_properties'):
            src = bpy.path.abspath(n.image.filepath)
            if src.lower().endswith(('.png', '.jpg')):
                dds = os.path.splitext(src)[0] + '.dds'
                if not os.path.exists(dds): write_dds(src, dds)
                n.image.filepath = dds; n.image.name = os.path.basename(dds)
            n.texture_properties.embedded = True

for o in bpy.data.objects:
    if getattr(o, 'sollum_type', '') != 'sollumz_drawable_model': continue
    me = o.data
    if not me.uv_layers: me.uv_layers.new(name='UVMap 0')
    me.uv_layers[0].name = 'UVMap 0'
    if 'Color 1' not in me.color_attributes:
        ca = me.color_attributes.new('Color 1', 'BYTE_COLOR', 'CORNER')
        for v in ca.data: v.color = (1, 1, 1, 1)

sc = bpy.context.scene
for d in drawables:
    model = [c for c in d.children_recursive if getattr(c, 'sollum_type', '') == 'sollumz_drawable_model'][0]
    bb = [model.matrix_world @ __import__('mathutils').Vector(c) for c in model.bound_box]
    mn = [min(v[i] for v in bb) for i in range(3)]; mx = [max(v[i] for v in bb) for i in range(3)]
    bpy.ops.object.select_all(action='DESELECT'); d.select_set(True); bpy.context.view_layer.objects.active = d
    sc.create_bound_type = 'sollumz_bound_composite'; bpy.ops.sollumz.createbound()
    comp = [o for o in d.children_recursive if getattr(o, 'sollum_type', '') == 'sollumz_bound_composite'][0]
    bpy.ops.object.select_all(action='DESELECT'); comp.select_set(True); bpy.context.view_layer.objects.active = comp
    sc.create_bound_type = 'sollumz_bound_box'; bpy.ops.sollumz.createbound()
    bx = [o for o in bpy.data.objects if getattr(o, 'sollum_type', '') == 'sollumz_bound_box' and o.parent in (d, comp, None) and not o.get('done')][-1]
    bx['done'] = True; bx.parent = comp
    bx.location = ((mn[0] + mx[0]) / 2 - d.location.x, (mn[1] + mx[1]) / 2 - d.location.y, (mn[2] + mx[2]) / 2 - d.location.z)
    bx.scale = (max(.02, mx[0] - mn[0]), max(.02, mx[1] - mn[1]), max(.02, mx[2] - mn[2]))
    bpy.ops.object.select_all(action='DESELECT'); bx.select_set(True); bpy.context.view_layer.objects.active = bx
    bpy.ops.sollumz.createcollisionmaterial()

bpy.ops.sollumz.createytyp()
ytyp = sc.ytyps[sc.ytyp_index]; ytyp.name = 'orp_drone'
for d in drawables:
    bpy.ops.object.select_all(action='DESELECT'); d.select_set(True); bpy.context.view_layer.objects.active = d
    bpy.ops.sollumz.createarchetypefromselected()
for a in ytyp.archetypes: a.lod_dist = 120.0

bpy.ops.object.select_all(action='SELECT')
print('export', bpy.ops.sollumz.export_assets(directory=EXPORT, direct_export=True, use_custom_settings=True, target_formats={'CWXML'}, target_versions={'GEN8'},
      limit_to_selected=False, export_ytyps=True, export_ytyps_include='ALL', apply_transforms=False))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'orp_drone_props.blend'))
for r_, ds, fs in os.walk(EXPORT):
    for f in fs: print('FILE', os.path.relpath(os.path.join(r_, f), EXPORT), os.path.getsize(os.path.join(r_, f)))
