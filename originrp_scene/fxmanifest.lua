fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_scene'
description 'OriginRP - Kit de mise en scène (scènes partagées pour tous les joueurs)'
version '1.0.0'

dependencies { 'ox_lib', 'ox_inventory' }

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'

server_scripts {
    'sv_config.lua',
    'server.lua',
}
