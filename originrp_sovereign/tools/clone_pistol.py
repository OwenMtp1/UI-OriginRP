#!/usr/bin/env python3
"""
Crée les .meta du Sovereign en CLONANT le pistolet de GTA (WEAPON_PISTOL) depuis TES fichiers du jeu.
Résultat : recul, dégâts, cadence, précision, portée, sons et animations strictement identiques au pistolet de base.

1. Avec OpenIV ou CodeWalker, extrais depuis GTA V (dossier update.rpf → common → data → ai, en général) :
     weapons.meta, weaponcomponents.meta, weaponanimations.meta
2. Lance :
     python3 clone_pistol.py chemin/weapons.meta chemin/weaponcomponents.meta chemin/weaponanimations.meta
3. Les fichiers sont écrits dans ../meta/ (weapons.meta, weaponcomponents.meta, weaponanimations.meta).

Pour cloner une autre arme (ex. WEAPON_COMBATPISTOL), change BASE ci-dessous.
"""
import copy, os, sys
import xml.etree.ElementTree as ET

BASE = 'WEAPON_PISTOL'
BASE_CLIP = 'COMPONENT_PISTOL_CLIP_01'
BASE_SKIN = 'COMPONENT_PISTOL_VARMOD_LUXE'      # composant « finition luxe » de GTA : sert de modèle aux skins
NEW = 'WEAPON_ORPSOVEREIGN'
MODEL = 'w_pi_orpsovereign'
LABEL = 'WT_ORPSOV'
CLIP = ('COMPONENT_ORPSOVEREIGN_CLIP_01', 'w_pi_orpsovereign_mag1')
# finitions (skins) : ajoute ici tes futurs camos (nom du composant, modèle .ydr)
SKINS = [
    ('COMPONENT_ORPSOVEREIGN_SKIN_HW', 'w_pi_orpsovereign_hw'),
]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'meta')


def text(el, tag):
    c = el.find(tag)
    return c.text if c is not None else None


def set_text(el, tag, value):
    c = el.find(tag)
    if c is None:
        c = ET.SubElement(el, tag)
    c.text = value


def find_item(root, type_, name):
    for it in root.iter('Item'):
        if it.get('type') == type_ and text(it, 'Name') == name:
            return it
    sys.exit(f'Introuvable : {type_} « {name} ». Vérifie que tu as extrait le bon fichier.')


def write(tree_root, name):
    os.makedirs(OUT, exist_ok=True)
    ET.indent(tree_root, '  ')
    path = os.path.join(OUT, name)
    ET.ElementTree(tree_root).write(path, encoding='UTF-8', xml_declaration=True)
    print('écrit :', os.path.normpath(path))


def weapons(path):
    src = ET.parse(path).getroot()
    w = copy.deepcopy(find_item(src, 'CWeaponInfo', BASE))
    set_text(w, 'Name', NEW)
    set_text(w, 'Model', MODEL)
    set_text(w, 'HumanNameHash', LABEL)
    # points d'attache : chargeur sur le même os que l'original, skins sur gun_root
    aps = w.find('AttachPoints')
    clip_bone = 'WAPClip'
    if aps is not None:
        for ap in aps.findall('Item'):
            comps = ap.find('Components')
            names = [text(c, 'Name') for c in comps.findall('Item')] if comps is not None else []
            if BASE_CLIP in names:
                clip_bone = text(ap, 'AttachBone') or clip_bone
        w.remove(aps)
    aps = ET.SubElement(w, 'AttachPoints')
    for bone, comps in [(clip_bone, [(CLIP[0], 'true')]), ('gun_root', [(s[0], 'false') for s in SKINS])]:
        ap = ET.SubElement(aps, 'Item')
        ET.SubElement(ap, 'AttachBone').text = bone
        cl = ET.SubElement(ap, 'Components')
        for name, default in comps:
            c = ET.SubElement(cl, 'Item')
            ET.SubElement(c, 'Name').text = name
            ET.SubElement(c, 'Default', value=default)
    blob = ET.Element('CWeaponInfoBlob')
    infos = ET.SubElement(ET.SubElement(ET.SubElement(blob, 'Infos'), 'Item'), 'Infos')
    infos.append(w)
    write(blob, 'weapons.meta')


def components(path):
    src = ET.parse(path).getroot()
    out = ET.Element('CWeaponComponentInfoBlob')
    infos = ET.SubElement(out, 'Infos')
    clip = copy.deepcopy(find_item(src, 'CWeaponComponentClipInfo', BASE_CLIP))
    set_text(clip, 'Name', CLIP[0]); set_text(clip, 'Model', CLIP[1])
    infos.append(clip)
    base_skin = find_item(src, 'CWeaponComponentVariantModelInfo', BASE_SKIN)
    for name, model in SKINS:
        s = copy.deepcopy(base_skin)
        set_text(s, 'Name', name); set_text(s, 'Model', model)
        infos.append(s)
    write(out, 'weaponcomponents.meta')


def animations(path):
    src = ET.parse(path).getroot()
    out = ET.Element('CWeaponAnimationsSets')
    sets_out = ET.SubElement(out, 'WeaponAnimationsSets')
    found = 0
    sets_in = src.find('WeaponAnimationsSets')
    for st in (sets_in.findall('Item') if sets_in is not None else []):
        anims = st.find('WeaponAnimations')
        if anims is None:
            continue
        for it in anims.findall('Item'):
            if it.get('key') == BASE:
                new_set = ET.SubElement(sets_out, 'Item', key=st.get('key'))
                fb = st.find('Fallback')
                if fb is not None:
                    new_set.append(copy.deepcopy(fb))
                wa = ET.SubElement(new_set, 'WeaponAnimations')
                clone = copy.deepcopy(it); clone.set('key', NEW)
                wa.append(clone)
                found += 1
    if not found:
        sys.exit(f'Aucune animation trouvée pour {BASE}.')
    write(out, 'weaponanimations.meta')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(__doc__); sys.exit(1)
    weapons(sys.argv[1]); components(sys.argv[2]); animations(sys.argv[3])
    print('Terminé : stats et animations identiques à', BASE)
