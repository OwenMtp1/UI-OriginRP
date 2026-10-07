fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_radar'
description 'OriginRP - Radars de vitesse automatiques (amendes 100 à 1500 $)'
version '1.0.0'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'

server_scripts {
    'sv_config.lua',
    'server.lua',
}
