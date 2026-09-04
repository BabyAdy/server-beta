fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rpg-licences'
author 'Custom RPG'
version '0.1.0'
description 'Licente (driving/weapon/flying/sailing) pe ore -- restrictii vehicule + arme, /agl staff'

-- foloseste: users.*_licence_hours (rpg-auth), resolveCharacter (rpg-characters),
-- addChatMessage / grade staff (rpg-hud + rpg-auth)
dependencies {
    'rpg-auth',
    'rpg-characters',
    'rpg-hud',
}

shared_scripts {
    '@rpg-auth/shared/staff.lua',   -- Staff.level() / Staff.BROADCAST_COLOR
    'shared/config.lua',
}

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
