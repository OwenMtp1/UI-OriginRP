# Outils de modélisation « hard surface » + matières usées façon armes GTA
import bpy, bmesh, math
from mathutils import Vector, Matrix

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def _link(o, col=None):
    (col or bpy.context.scene.collection).objects.link(o)
    return o

def mesh_obj(name, bm, mat=None, parent=None):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); _link(o)
    if mat: me.materials.append(mat)
    for p in me.polygons: p.use_smooth = True
    if parent: o.parent = parent
    return o

def finish(o, bevel=0.0, seg=3, angle=35, weighted=True, sub=0):
    if bevel > 0:
        m = o.modifiers.new('bevel', 'BEVEL'); m.width = bevel; m.segments = seg
        m.limit_method = 'ANGLE'; m.angle_limit = math.radians(angle); m.harden_normals = False
    if sub:
        s = o.modifiers.new('sub', 'SUBSURF'); s.levels = sub; s.render_levels = sub
    if weighted:
        w = o.modifiers.new('wn', 'WEIGHTED_NORMAL'); w.keep_sharp = True
    return o

def box(name, size, loc=(0, 0, 0), mat=None, bevel=0.0, seg=3, cuts=0, shape=None, rot=(0, 0, 0), parent=None, angle=35):
    """Pavé (option : subdivisé puis déformé par `shape(v)` pour effiler / galber)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    if cuts:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
        if shape: v.co = shape(v.co)
    o = mesh_obj(name, bm, mat, parent)
    o.location = loc; o.rotation_euler = rot
    return finish(o, bevel, seg, angle)

def cyl(name, r, h, loc=(0, 0, 0), mat=None, rot=(0, 0, 0), verts=32, bevel=0.0, seg=2, r2=None, parent=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=r, radius2=r2 if r2 is not None else r, depth=h)
    o = mesh_obj(name, bm, mat, parent); o.location = loc; o.rotation_euler = rot
    return finish(o, bevel, seg, 30)

def sphere(name, r, loc=(0, 0, 0), mat=None, scale=(1, 1, 1), parent=None, seg=32):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=r)
    for v in bm.verts: v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2]))
    o = mesh_obj(name, bm, mat, parent); o.location = loc
    return o

def torus(name, R, r, loc=(0, 0, 0), mat=None, rot=(0, 0, 0), parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=40, minor_segments=12, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name
    if mat: o.data.materials.append(mat)
    for p in o.data.polygons: p.use_smooth = True
    if parent: o.parent = parent
    return o

def text(name, s, size, loc, rot, mat, extrude=0.0004, parent=None, align='CENTER', font_bold=True):
    cu = bpy.data.curves.new(name, 'FONT'); cu.body = s; cu.size = size; cu.extrude = extrude; cu.align_x = align; cu.align_y = 'CENTER'
    o = bpy.data.objects.new(name, cu); _link(o); o.location = loc; o.rotation_euler = rot
    o.data.materials.append(mat)
    if parent: o.parent = parent
    return o

def boolean(target, cutter, op='DIFFERENCE'):
    m = target.modifiers.new('bool_' + cutter.name, 'BOOLEAN'); m.object = cutter; m.operation = op; m.solver = 'EXACT'
    # booléen après le biseau : les arêtes extérieures restent arrondies
    wn = target.modifiers.find('wn')
    if wn >= 0: target.modifiers.move(len(target.modifiers) - 1, wn)
    cutter.hide_render = True; cutter.hide_viewport = True; cutter.display_type = 'WIRE'
    return m

def array(o, count, offset, relative=False):
    m = o.modifiers.new('arr', 'ARRAY'); m.count = count
    m.use_relative_offset = relative; m.use_constant_offset = not relative; m.constant_offset_displace = offset
    o.modifiers.move(len(o.modifiers) - 1, 0)
    return o

# ─── Matières ───
def _nodes(mat):
    mat.use_nodes = True; nt = mat.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); bs = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(bs.outputs['BSDF'], out.inputs['Surface'])
    return nt, bs

def mat(name, color, rough=0.5, metal=0.0, wear=0.0, wear_color=None, wear_rough=None, grain=0.0, grain_scale=600.0, coat=0.0, emit=None, emit_strength=0.0, dust=0.0, alpha=1.0, transmission=0.0):
    """Principled + usure des arêtes (normale biseautée vs normale réelle) + grain + poussière."""
    m = bpy.data.materials.new(name); nt, bs = _nodes(m); L = nt.links.new
    m["p"] = {"c": list(color), "r": rough, "m": metal, "e": list(emit) if emit else None, "es": emit_strength, "coat": coat}
    base = nt.nodes.new('ShaderNodeRGB'); base.outputs[0].default_value = (*color, 1)
    col_out = base.outputs[0]
    rough_v = nt.nodes.new('ShaderNodeValue'); rough_v.outputs[0].default_value = rough; rough_out = rough_v.outputs[0]
    if wear > 0:
        bev = nt.nodes.new('ShaderNodeBevel'); bev.inputs['Radius'].default_value = 0.003; bev.samples = 8
        geo = nt.nodes.new('ShaderNodeNewGeometry')
        dot = nt.nodes.new('ShaderNodeVectorMath'); dot.operation = 'DOT_PRODUCT'
        L(bev.outputs[0], dot.inputs[0]); L(geo.outputs['Normal'], dot.inputs[1])
        inv = nt.nodes.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0; L(dot.outputs['Value'], inv.inputs[1])
        noise = nt.nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 90; noise.inputs['Detail'].default_value = 8
        mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; L(inv.outputs[0], mul.inputs[0]); L(noise.outputs['Fac'], mul.inputs[1])
        ramp = nt.nodes.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].position = 0.0; ramp.color_ramp.elements[1].position = max(0.01, 0.12 / wear)
        L(mul.outputs[0], ramp.inputs['Fac'])
        wc = nt.nodes.new('ShaderNodeRGB'); wc.outputs[0].default_value = (*(wear_color or (0.35, 0.35, 0.36)), 1)
        mix = nt.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'
        L(ramp.outputs['Color'], mix.inputs['Factor']); L(col_out, mix.inputs[6]); L(wc.outputs[0], mix.inputs[7]); col_out = mix.outputs[2]
        if wear_rough is not None:
            mr = nt.nodes.new('ShaderNodeMix'); mr.data_type = 'FLOAT'; mr.inputs[2].default_value = rough; mr.inputs[3].default_value = wear_rough
            L(ramp.outputs['Color'], mr.inputs['Factor']); rough_out = mr.outputs[0]
    if dust > 0:
        nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 25; nz.inputs['Detail'].default_value = 6
        rp = nt.nodes.new('ShaderNodeValToRGB'); rp.color_ramp.elements[0].position = .55; rp.color_ramp.elements[1].position = .8
        L(nz.outputs['Fac'], rp.inputs['Fac'])
        mm = nt.nodes.new('ShaderNodeMath'); mm.operation = 'MULTIPLY'; mm.inputs[1].default_value = dust; L(rp.outputs['Color'], mm.inputs[0])
        dc = nt.nodes.new('ShaderNodeRGB'); dc.outputs[0].default_value = (0.22, 0.2, 0.17, 1)
        mx = nt.nodes.new('ShaderNodeMix'); mx.data_type = 'RGBA'; L(mm.outputs[0], mx.inputs['Factor']); L(col_out, mx.inputs[6]); L(dc.outputs[0], mx.inputs[7]); col_out = mx.outputs[2]
    L(col_out, bs.inputs['Base Color']); L(rough_out, bs.inputs['Roughness'])
    bs.inputs['Metallic'].default_value = metal
    if coat: bs.inputs['Coat Weight'].default_value = coat; bs.inputs['Coat Roughness'].default_value = 0.08
    if grain > 0:
        gn = nt.nodes.new('ShaderNodeTexNoise'); gn.inputs['Scale'].default_value = grain_scale; gn.inputs['Detail'].default_value = 4
        bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = grain; bp.inputs['Distance'].default_value = 0.0005
        L(gn.outputs['Fac'], bp.inputs['Height']); L(bp.outputs['Normal'], bs.inputs['Normal'])
    if emit:
        bs.inputs['Emission Color'].default_value = (*emit, 1); bs.inputs['Emission Strength'].default_value = emit_strength
    if transmission: bs.inputs['Transmission Weight'].default_value = transmission
    if alpha < 1: bs.inputs['Alpha'].default_value = alpha
    return m

def carbon(name):
    m = bpy.data.materials.new(name); nt, bs = _nodes(m); L = nt.links.new
    m["p"] = {"c": [0.02, 0.02, 0.022], "r": 0.32, "m": 0.0, "e": None, "es": 0, "coat": 0.8}
    tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Rotation'].default_value[2] = math.radians(45)
    L(tc.outputs['Object'], mp.inputs['Vector'])
    ck = nt.nodes.new('ShaderNodeTexChecker'); ck.inputs['Scale'].default_value = 900
    ck.inputs['Color1'].default_value = (0.012, 0.012, 0.013, 1); ck.inputs['Color2'].default_value = (0.04, 0.04, 0.045, 1)
    L(mp.outputs['Vector'], ck.inputs['Vector']); L(ck.outputs['Color'], bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value = 0.32; bs.inputs['Coat Weight'].default_value = 0.8; bs.inputs['Coat Roughness'].default_value = 0.05
    return m

# ─── Studio « vitrine Ammu-Nation » ───
def studio(target=(0, 0, 0.1), cam_loc=(0.75, -0.75, 0.45), lens=55, res=(1600, 1000), samples=96, floor=True):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = samples; sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = res; sc.render.film_transparent = False
    sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'AgX - Medium High Contrast'
    w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.012, 0.014, 0.02, 1); bg.inputs[1].default_value = 1.0
    if floor:
        fm = mat('floor', (0.02, 0.022, 0.026), rough=0.28, grain=0.0)
        bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0)); f = bpy.context.active_object; f.data.materials.append(fm)
    def area(name, loc, energy, color, size, tgt=target):
        ld = bpy.data.lights.new(name, 'AREA'); ld.energy = energy; ld.color = color; ld.size = size
        lo = bpy.data.objects.new(name, ld); _link(lo); lo.location = loc
        d = Vector(tgt) - Vector(loc); lo.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        return lo
    area('key', (0.9, -0.9, 1.1), 90, (1.0, 0.93, 0.85), 0.9)
    area('fill', (-1.1, -0.6, 0.5), 25, (0.75, 0.85, 1.0), 1.2)
    area('rim', (-0.4, 1.1, 0.8), 140, (0.55, 0.75, 1.0), 0.5)
    area('rim2', (1.0, 0.9, 0.35), 60, (1.0, 0.55, 0.3), 0.4)
    area('top', (0, 0, 1.6), 12, (1, 1, 1), 1.5)
    cd = bpy.data.cameras.new('cam'); cd.lens = lens; cd.dof.use_dof = True; cd.dof.aperture_fstop = 5.6
    co = bpy.data.objects.new('cam', cd); _link(co); co.location = cam_loc
    d = Vector(target) - Vector(cam_loc); co.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    cd.dof.focus_distance = d.length
    sc.camera = co
    return co

def aim(cam, loc, target):
    cam.location = loc; d = Vector(target) - Vector(loc); cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler(); cam.data.dof.focus_distance = d.length

def render(path):
    bpy.context.scene.render.filepath = path; bpy.ops.render.render(write_still=True)
