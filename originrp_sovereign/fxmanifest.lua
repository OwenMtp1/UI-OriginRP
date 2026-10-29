fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_sovereign'
description 'OriginRP - Sovereign .50 : pistolet lourd canon long (stats clonées de WEAPON_PISTOL) avec camos'
version '1.0.0'

files {
    'meta/weapons.meta',
    'meta/weaponcomponents.meta',
    'meta/weaponarchetypes.meta',
    'meta/weaponanimations.meta',
}

data_file 'WEAPONCOMPONENTSINFO_FILE' 'meta/weaponcomponents.meta'
data_file 'WEAPON_METADATA_FILE'      'meta/weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE'    'meta/weaponanimations.meta'
data_file 'WEAPONINFO_FILE'           'meta/weapons.meta'

shared_script 'config.lua'
client_script 'client.lua'
