fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_bracelet'
description 'OriginRP - Bracelet électronique (pose via ALT, visible selon le pantalon)'
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
