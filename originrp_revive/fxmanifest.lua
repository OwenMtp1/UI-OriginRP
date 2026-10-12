fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_revive'
description 'OriginRP - Réanimation animée avec kit de soin (moins de 10 s)'
version '1.0.0'

dependencies { 'ox_lib', 'ox_inventory', 'ox_target' }

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'

server_scripts {
    'sv_config.lua',
    'server.lua',
}

-- Sac d'intervention personnalisé (orp_medbag_closed / orp_medbag_open)
data_file 'DLC_ITYP_REQUEST' 'stream/orp_medbag.ytyp'
