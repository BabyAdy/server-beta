fx_version 'cerulean'
game 'gta5'

author 'Purple Havoc'
description 'Purple Havoc Loading Screen'
version '1.0.0'

loadscreen 'index.html'

-- cursor de mouse activ pe loading screen (control player pe controalele muzicii)
loadscreen_cursor 'yes'

-- NU inchide automat loading screen-ul cand jocul termina de incarcat -> ramane
-- deasupra notificarii native "Loading x%". Se inchide cand rpg-auth apeleaza
-- ShutdownLoadingScreenNui() (la deschiderea ecranului de login).
loadscreen_manual_shutdown 'yes'

files {
    'index.html',
    'logo.svg',
    'bg.jpg',
    'song1.mp3',
    'song2.mp3',
    'song3.mp3'
}
