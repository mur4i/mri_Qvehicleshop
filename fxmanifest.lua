fx_version 'cerulean'
game 'gta5'

author 'Murai'
description 'Vehicle Shop'
version '1.0.0'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

ox_lib 'locale'

ui_page {"ui/index.html"}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

files {
    'locales/*.json',
    'ui/*'
}