fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'originrp_drone'
description 'OriginRP - Unité drone OR-D2 : mallette, déploiement, radiocommande à écran, vie, batterie 2 h, brouillage'
version '1.0.0'

dependencies { 'ox_lib', 'ox_inventory', 'ox_target' }

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client.lua', 'flight.lua' }
server_scripts { 'sv_config.lua', 'server.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }

-- Props OriginRP (orp_drone, orp_drone_folded, orp_drone_wreck, orp_dronecase, orp_dronecase_open, orp_drone_rc)
data_file 'DLC_ITYP_REQUEST' 'stream/orp_drone.ytyp'
