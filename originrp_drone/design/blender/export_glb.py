import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy
from blib import reset
from drone_model import build_drone
from case_model import build_case
from ctrl_model import build_ctrl

def simplify_materials():
    """Matières procédurales → Principled simple (exportable en glTF)."""
    for m in bpy.data.materials:
        p = m.get('p')
        if not p or not m.use_nodes: continue
        p = p.to_dict() if hasattr(p, 'to_dict') else p
        nt = m.node_tree; nt.nodes.clear()
        out = nt.nodes.new('ShaderNodeOutputMaterial'); bs = nt.nodes.new('ShaderNodeBsdfPrincipled'); nt.links.new(bs.outputs[0], out.inputs[0])
        bs.inputs['Base Color'].default_value = (*p['c'], 1); bs.inputs['Roughness'].default_value = p['r']; bs.inputs['Metallic'].default_value = p['m']
        if p.get('e'): bs.inputs['Emission Color'].default_value = (*p['e'], 1); bs.inputs['Emission Strength'].default_value = min(p['es'], 6)

def to_mesh():
    for o in list(bpy.data.objects):
        if o.type in ('FONT', 'CURVE'):
            bpy.ops.object.select_all(action='DESELECT'); o.hide_viewport = False; o.select_set(True); bpy.context.view_layer.objects.active = o
            bpy.ops.object.convert(target='MESH')
    for o in list(bpy.data.objects):   # supprime les objets de découpe (booléens)
        if o.type == 'MESH' and o.hide_render: bpy.data.objects.remove(o)

def export(path):
    simplify_materials(); to_mesh()
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_apply=True, export_yup=True, export_image_format='JPEG', export_jpeg_quality=85)

out = sys.argv[-1]; which = sys.argv[-2]
reset()
if which == 'drone': build_drone(1.0)
if which == 'case':
    build_case(1.0); bpy.data.objects['lidHinge'].rotation_euler = (0, 0, 0)
if which == 'ctrl': build_ctrl()
if which == 'wreck':
    from drone_model import build_wreck
    r = build_wreck(); r.rotation_euler = (0, 0, 0); r.location.z = 0
export(os.path.join(out, f'orp_{which}.glb'))
