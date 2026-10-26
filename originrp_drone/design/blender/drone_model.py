import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import bpy
from mathutils import Vector
from blib import *

def build_drone(folded=0.0):
    """Drone tactique OR-D2 : coque polymère noire, bras alu/carbone, nacelle EO/IR. Avant = +Y, haut = +Z."""
    M = {
        'poly': mat('polymer', (0.014, 0.014, 0.015), rough=0.55, wear=0.6, wear_color=(0.16, 0.16, 0.17), wear_rough=0.4, grain=0.02, grain_scale=1500, dust=0.04),
        'shell': mat('shell', (0.01, 0.01, 0.011), rough=0.38, wear=0.5, wear_color=(0.14, 0.14, 0.15), grain=0.04, coat=0.2),
        'metal': mat('anodized', (0.03, 0.03, 0.033), rough=0.32, metal=1.0, wear=0.9, wear_color=(0.55, 0.55, 0.57), wear_rough=0.2),
        'steel': mat('steel', (0.6, 0.6, 0.62), rough=0.25, metal=1.0),
        'rubber': mat('rubber', (0.02, 0.02, 0.02), rough=0.92, grain=0.2, grain_scale=300),
        'glass': mat('glass', (0.004, 0.006, 0.01), rough=0.03, coat=1.0),
        'lens': mat('lens', (0.003, 0.004, 0.008), rough=0.02, metal=0.2, coat=1.0),
        'germ': mat('germanium', (0.06, 0.04, 0.03), rough=0.05, metal=0.9, coat=1.0),
        'carbon': carbon('carbon'),
        'paint': mat('paint', (0.32, 0.32, 0.33), rough=0.6),
        'red': mat('red_led', (0.3, 0.0, 0.0), rough=0.2, emit=(1, 0.03, 0.02), emit_strength=25),
        'redpaint': mat('redpaint', (0.45, 0.02, 0.02), rough=0.5),
        'green': mat('green_led', (0.0, 0.2, 0.05), rough=0.2, emit=(0.1, 1, 0.2), emit_strength=8),
        'vent': mat('vent', (0.002, 0.002, 0.002), rough=0.9),
    }
    root = bpy.data.objects.new('OR-D2', None); bpy.context.scene.collection.objects.link(root)
    Z0 = 0.075  # hauteur du ventre

    # ── fuselage : effilé vers le nez, galbé ──
    def hull_shape(v):
        y = v.y; t = max(0.0, (y - 0.04) / 0.11)
        v.x *= 1 - 0.38 * t
        if v.z > 0: v.z *= 1 - 0.5 * t
        else: v.z *= 1 - 0.15 * t
        rear = max(0.0, (-y - 0.1) / 0.05); v.x *= 1 - 0.12 * rear
        return v
    hull = box('hull', (0.125, 0.3, 0.062), (0, 0, Z0 + 0.031), M['poly'], bevel=0.016, seg=4, cuts=6, shape=hull_shape, parent=root, angle=25)
    # capot supérieur (pièce séparée = ligne de joint)
    def top_shape(v):
        t = max(0.0, (v.y - 0.02) / 0.1); v.x *= 1 - 0.3 * t; v.z -= 0.012 * t * t
        return v
    top = box('top', (0.105, 0.22, 0.026), (0, -0.01, Z0 + 0.07), M['shell'], bevel=0.011, seg=4, cuts=5, shape=top_shape, parent=root, angle=25)
    # ouïes latérales
    for sx in (-1, 1):
        for i in range(6):
            box(f'vent{sx}{i}', (0.004, 0.012, 0.024), (sx * 0.0625, -0.07 + i * 0.016, Z0 + 0.03), M['vent'], bevel=0.0015, parent=root)
    # baie de capteurs avant (vitre fumée) + caméras stéréo + feu rouge
    box('sensorBay', (0.06, 0.012, 0.026), (0, 0.148, Z0 + 0.032), M['glass'], bevel=0.005, rot=(math.radians(-12), 0, 0), parent=root)
    for sx in (-0.018, 0.018):
        cyl(f'stereo{sx}', 0.0065, 0.006, (sx, 0.153, Z0 + 0.033), M['lens'], rot=(math.radians(90 - 12), 0, 0), parent=root)
    sphere('noseLed', 0.004, (0, 0.152, Z0 + 0.047), M['red'], parent=root)
    # capteurs latéraux / arrière
    for sx in (-1, 1):
        cyl(f'side{sx}', 0.006, 0.004, (sx * 0.064, 0.05, Z0 + 0.04), M['lens'], rot=(0, math.radians(90), 0), parent=root)
    cyl('rearCam', 0.006, 0.004, (0, -0.152, Z0 + 0.04), M['lens'], rot=(math.radians(90), 0, 0), parent=root)

    # ── nacelle EO/IR sous le nez ──
    g = bpy.data.objects.new('gimbal', None); bpy.context.scene.collection.objects.link(g); g.parent = root; g.location = (0, 0.105, Z0 - 0.004)
    cyl('gMount', 0.016, 0.012, (0, 0, 0), M['metal'], bevel=0.002, parent=g)
    box('gYoke', (0.07, 0.014, 0.008), (0, 0, -0.01), M['poly'], bevel=0.003, parent=g)
    for sx in (-1, 1): box(f'gArm{sx}', (0.008, 0.014, 0.04), (sx * 0.031, 0, -0.03), M['poly'], bevel=0.003, parent=g)
    head = box('gHead', (0.05, 0.05, 0.046), (0, 0.004, -0.04), M['shell'], bevel=0.012, seg=4, parent=g)
    cyl('zoomBarrel', 0.016, 0.014, (-0.006, 0.03, -0.04), M['metal'], rot=(math.radians(90), 0, 0), bevel=0.002, parent=g)
    cyl('zoomGlass', 0.012, 0.002, (-0.006, 0.0375, -0.04), M['lens'], rot=(math.radians(90), 0, 0), parent=g)
    cyl('irGlass', 0.007, 0.004, (0.016, 0.031, -0.032), M['germ'], rot=(math.radians(90), 0, 0), parent=g)
    cyl('wideGlass', 0.005, 0.004, (0.016, 0.031, -0.05), M['lens'], rot=(math.radians(90), 0, 0), parent=g)
    cyl('laser', 0.003, 0.004, (-0.006, 0.031, -0.059), M['red'], rot=(math.radians(90), 0, 0), parent=g)

    # ── batterie arrière enfichable ──
    bat = box('battery', (0.09, 0.1, 0.03), (0, -0.085, Z0 + 0.092), M['poly'], bevel=0.008, seg=3, parent=root)
    for i in range(7): box(f'grip{i}', (0.092, 0.004, 0.004), (0, -0.125 + i * 0.006, Z0 + 0.107), M['rubber'], bevel=0.0015, parent=root)
    for i in range(4): box(f'led{i}', (0.006, 0.003, 0.002), (-0.012 + i * 0.008, -0.04, Z0 + 0.108), M['green'] if i < 3 else M['vent'], parent=root)
    box('batBtn', (0.014, 0.008, 0.003), (0.028, -0.04, Z0 + 0.108), M['metal'], bevel=0.001, parent=root)
    text('batTxt', 'OR-D2  ·  14.8V 6Ah', 0.008, (0, -0.07, Z0 + 0.1072), (0, 0, 0), M['paint'], parent=root)
    # marquages latéraux
    for sx in (-1, 1):
        text(f'side_txt{sx}', 'ORIGIN  AIR UNIT', 0.0085, (sx * 0.0628, -0.02, Z0 + 0.012), (math.radians(90), 0, math.radians(90 * sx)), M['paint'], parent=root)
    text('warn', '⚠', 0.012, (0.03, 0.02, Z0 + 0.0905), (0, 0, 0), M['redpaint'], parent=root)
    # vis du capot
    for (x, y) in [(-0.042, 0.06), (0.042, 0.06), (-0.045, -0.09), (0.045, -0.09)]:
        cyl(f'screw{x}{y}', 0.0028, 0.002, (x, y, Z0 + 0.0835), M['steel'], verts=12, parent=root)

    # ── bras + moteurs + hélices ──
    ARMS = [(0.05, 0.085, 40), (-0.05, 0.085, -40), (0.05, -0.085, 140), (-0.05, -0.085, -140)]
    FOLD = [170, -170, 15, -15]
    props = []
    for i, (x, y, ang) in enumerate(ARMS):
        a = ang + (FOLD[i] - ang) * folded
        piv = bpy.data.objects.new(f'armPivot{i}', None); bpy.context.scene.collection.objects.link(piv); piv.parent = root
        piv.location = (x, y, Z0 + (0.03 if i < 2 else 0.018)); piv.rotation_euler = (0, 0, math.radians(-a))
        box(f'hinge{i}', (0.034, 0.03, 0.028), (0, 0, 0), M['metal'], bevel=0.004, parent=piv)
        cyl(f'hingePin{i}', 0.006, 0.032, (0, 0, 0), M['steel'], parent=piv)
        def arm_shape(v):
            t = (v.y + 0.5 * 0.2) / 0.2; v.z *= 1 - 0.3 * t; v.x *= 1 - 0.25 * t; return v
        box(f'arm{i}', (0.024, 0.2, 0.02), (0, 0.11, 0), M['carbon'], bevel=0.005, cuts=3, shape=arm_shape, parent=piv)
        box(f'armClamp{i}', (0.03, 0.022, 0.026), (0, 0.04, 0), M['poly'], bevel=0.004, parent=piv)
        # moteur à cloche avec ailettes
        mx = (0, 0.215, 0.008)
        box(f'mountPlate{i}', (0.04, 0.05, 0.008), (0, 0.208, -0.006), M['poly'], bevel=0.003, parent=piv)
        cyl(f'stator{i}', 0.024, 0.012, (0, 0.215, 0.004), M['metal'], bevel=0.0015, parent=piv)
        cyl(f'bell{i}', 0.027, 0.02, (0, 0.215, 0.02), M['metal'], bevel=0.002, verts=40, parent=piv)
        for k in range(14):
            th = k / 14 * math.tau
            box(f'fin{i}_{k}', (0.003, 0.006, 0.014), (math.cos(th) * 0.0275, 0.215 + math.sin(th) * 0.0275, 0.02), M['vent'], rot=(0, 0, th), parent=piv)
        cyl(f'cap{i}', 0.011, 0.008, (0, 0.215, 0.034), M['steel'], bevel=0.002, parent=piv)
        # pied d'atterrissage
        cyl(f'leg{i}', 0.0045, 0.06, (0, 0.215, -0.035), M['poly'], parent=piv)
        sphere(f'foot{i}', 0.009, (0, 0.215, -0.066), M['rubber'], scale=(1, 1, 0.7), parent=piv)
        # feu de bras
        sphere(f'armLed{i}', 0.004, (0, 0.235, -0.006), M['red'] if i < 2 else M['green'], parent=piv)
        # hélice bipale (pales vrillées, saumons rouges)
        hub = bpy.data.objects.new(f'hub{i}', None); bpy.context.scene.collection.objects.link(hub); hub.parent = piv; hub.location = (0, 0.215, 0.04)
        hub.rotation_euler = (0, 0, math.radians(35 + i * 50))
        for s in (1, -1):
            def blade_shape(v, s=s):
                u = (v.y + 0.5) ; # 0..1 le long de la pale
                chord = 0.022 * (1 - 0.55 * u) + 0.006 * math.sin(math.pi * min(1, u * 1.3))
                v.x = v.x * chord / 0.02
                tw = math.radians(18 * (1 - u) + 6)
                x, z = v.x, v.z
                v.x = x * math.cos(tw) - z * math.sin(tw); v.z = x * math.sin(tw) + z * math.cos(tw)
                v.y = s * (0.012 + u * 0.165)
                v.z += 0.004 * u
                return v
            bl = box(f'blade{i}{s}', (0.02, 1.0, 0.003), (0, 0, 0), M['poly'], bevel=0.0012, seg=2, cuts=8, shape=blade_shape, parent=hub)
            box(f'tip{i}{s}', (0.012, 0.014, 0.0034), (0, s * 0.17, 0.004), M['redpaint'], bevel=0.001, parent=hub)
        props.append(hub)
    # antennes sous les bras arrière
    for sx in (-1, 1):
        box(f'antenna{sx}', (0.004, 0.012, 0.055), (sx * 0.045, -0.13, Z0 - 0.02), M['poly'], bevel=0.0015, rot=(math.radians(-25), 0, 0), parent=root)
    return root, props


def build_wreck():
    """Drone abattu : bras arraché, hélices cassées, coque fissurée et noircie."""
    root, props = build_drone(0.0)
    O = bpy.data.objects
    burnt = mat('burnt', (0.006, 0.006, 0.006), rough=0.9, wear=0.8, wear_color=(0.06, 0.05, 0.045), dust=0.12, grain=0.08, grain_scale=900)
    ash = mat('ash', (0.09, 0.085, 0.08), rough=1.0, grain=0.3)
    dead = mat('dead_led', (0.05, 0.0, 0.0), rough=0.4)
    for o in list(O):
        if o.type != 'MESH': continue
        if any(o.name.startswith(n) for n in ('blade1', 'tip1', 'blade3', 'tip3', 'blade2-1', 'tip2-1', 'leg1', 'foot1', 'leg3', 'foot3')): O.remove(o); continue
        if o.name in ('hull', 'top', 'battery') or o.name.startswith('armClamp'): o.data.materials.clear(); o.data.materials.append(burnt)
        if o.name in ('noseLed', 'laser') or o.name.startswith('armLed') or o.name.startswith('led'): o.data.materials.clear(); o.data.materials.append(dead)
    # bras arrière droit arraché (pend et tordu), bras avant droit plié
    O['armPivot3'].rotation_euler = (math.radians(35), math.radians(-25), math.radians(-120))
    O['armPivot1'].rotation_euler = (math.radians(-18), 0, math.radians(30))
    O['gimbal'].rotation_euler = (math.radians(28), math.radians(12), 0)
    # fissures + traces de brûlure + éclats de carbone
    for k, (x, y, r) in enumerate([(0.01, 0.03, 25), (-0.02, -0.01, -40), (0.025, -0.06, 70), (-0.03, 0.07, 10)]):
        box(f'crack{k}', (0.002, 0.05, 0.002), (x, y, 0.075 + 0.0825), ash, rot=(0, 0, math.radians(r)), parent=root)
    for k in range(5):
        box(f'shard{k}', (0.01 + k * 0.003, 0.03, 0.002), (0.1 - k * 0.04, -0.2 + k * 0.03, 0.001), O['carbon'] if 'carbon' in O else burnt, rot=(0, 0, k), parent=root) if False else None
    root.rotation_euler = (math.radians(-6), math.radians(-24), math.radians(20))
    root.location.z = -0.01
    return root

def smoke(loc, size=0.5, strength=6.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); c = bpy.context.active_object; c.scale = (size, size, size * 1.8)
    m = bpy.data.materials.new('smoke'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); vol = nt.nodes.new('ShaderNodeVolumePrincipled')
    vol.inputs['Color'].default_value = (0.02, 0.02, 0.02, 1); nt.links.new(vol.outputs[0], out.inputs['Volume'])
    tc = nt.nodes.new('ShaderNodeTexCoord'); nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 5.5; nz.inputs['Detail'].default_value = 6
    nt.links.new(tc.outputs['Object'], nz.inputs['Vector'])
    grad = nt.nodes.new('ShaderNodeTexGradient'); grad.gradient_type = 'SPHERICAL'; nt.links.new(tc.outputs['Object'], grad.inputs['Vector'])
    g2 = nt.nodes.new('ShaderNodeMath'); g2.operation = 'MULTIPLY_ADD'; g2.inputs[1].default_value = 2.2; g2.inputs[2].default_value = -0.9; nt.links.new(grad.outputs['Fac'], g2.inputs[0])
    mx = nt.nodes.new('ShaderNodeMath'); mx.operation = 'MAXIMUM'; mx.inputs[1].default_value = 0; nt.links.new(g2.outputs[0], mx.inputs[0])
    n2 = nt.nodes.new('ShaderNodeMath'); n2.operation = 'MULTIPLY_ADD'; n2.inputs[1].default_value = 1.6; n2.inputs[2].default_value = -0.45; nt.links.new(nz.outputs['Fac'], n2.inputs[0])
    n3 = nt.nodes.new('ShaderNodeMath'); n3.operation = 'MAXIMUM'; n3.inputs[1].default_value = 0; nt.links.new(n2.outputs[0], n3.inputs[0])
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; nt.links.new(mx.outputs[0], mul.inputs[0]); nt.links.new(n3.outputs[0], mul.inputs[1])
    k = nt.nodes.new('ShaderNodeMath'); k.operation = 'MULTIPLY'; k.inputs[1].default_value = strength * 12; nt.links.new(mul.outputs[0], k.inputs[0])
    mx = k
    nt.links.new(mx.outputs[0], vol.inputs['Density'])
    c.data.materials.append(m)
    return c

if __name__ == '__main__':
    out = sys.argv[-1]
    reset()
    root, props = build_drone(0.0)
    cam = studio(target=(0, 0, 0.09), cam_loc=(0.6, 0.66, 0.38), lens=50, samples=int(os.environ.get('SPP', '64')))
    render(os.path.join(out, 'drone_34.png'))
    aim(cam, (0.0, 0.62, 0.16), (0, 0.05, 0.08)); render(os.path.join(out, 'drone_front.png'))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'orp_drone.blend'))
