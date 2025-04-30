-- fxmanifest.lua
fx_version 'cerulean'
game        'gta5'

name        'prp-moonshinedelivery'
author      'DTrain'
description 'Moonshine Delivery Script for FiveM (QBox + ox_inventory + ox_target + ox_lib)'
version     '1.1.0'

shared_script '@ox_lib/init.lua'

shared_script 'Config.lua'
server_script 'Server.lua'
client_script 'Client.lua'

dependencies {
  'ox_inventory',
  'ox_target',
  'ox_lib',
  'ps-dispatch'
}
