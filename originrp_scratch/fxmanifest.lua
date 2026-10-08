fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_scratch'
description 'OriginRP - Borne et tickets à gratter (SA Lottery)'
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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
