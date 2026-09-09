-- local requestedIpl = {
--     "h4_mph4_terrain_occ_09",
--     "h4_mph4_terrain_occ_06",
--     "h4_mph4_terrain_occ_05",
--     "h4_mph4_terrain_occ_01",
--     "h4_mph4_terrain_occ_00",
--     "h4_mph4_terrain_occ_08",
--     "h4_mph4_terrain_occ_04",
--     "h4_mph4_terrain_occ_07",
--     "h4_mph4_terrain_occ_03",
--     "h4_mph4_terrain_occ_02",
--     "h4_islandx_terrain_04",
--     "h4_islandx_terrain_05_slod",
--     "h4_islandx_terrain_props_05_d_slod",
--     "h4_islandx_terrain_02",
--     "h4_islandx_terrain_props_05_a_lod",
--     "h4_islandx_terrain_props_05_c_lod",
--     "h4_islandx_terrain_01",
--     "h4_mph4_terrain_04",
--     "h4_mph4_terrain_06",
--     "h4_islandx_terrain_04_lod",
--     "h4_islandx_terrain_03_lod",
--     "h4_islandx_terrain_props_06_a",
--     "h4_islandx_terrain_props_06_a_slod",
--     "h4_islandx_terrain_props_05_f_lod",
--     "h4_islandx_terrain_props_06_b",
--     "h4_islandx_terrain_props_05_b_lod",
--     "h4_mph4_terrain_lod",
--     "h4_islandx_terrain_props_05_e_lod",
--     "h4_islandx_terrain_05_lod",
--     "h4_mph4_terrain_02",
--     "h4_islandx_terrain_props_05_a",
--     "h4_mph4_terrain_01_long_0",
--     "h4_islandx_terrain_03",
--     "h4_islandx_terrain_props_06_b_slod",
--     "h4_islandx_terrain_01_slod",
--     "h4_islandx_terrain_04_slod",
--     "h4_islandx_terrain_props_05_d_lod",
--     "h4_islandx_terrain_props_05_f_slod",
--     "h4_islandx_terrain_props_05_c",
--     "h4_islandx_terrain_02_lod",
--     "h4_islandx_terrain_06_slod",
--     "h4_islandx_terrain_props_06_c_slod",
--     "h4_islandx_terrain_props_06_c",
--     "h4_islandx_terrain_01_lod",
--     "h4_mph4_terrain_06_strm_0",
--     "h4_islandx_terrain_05",
--     "h4_islandx_terrain_props_05_e_slod",
--     "h4_islandx_terrain_props_06_c_lod",
--     "h4_mph4_terrain_03",
--     "h4_islandx_terrain_props_05_f",
--     "h4_islandx_terrain_06_lod",
--     "h4_mph4_terrain_01",
--     "h4_islandx_terrain_06",
--     "h4_islandx_terrain_props_06_a_lod",
--     "h4_islandx_terrain_props_06_b_lod",
--     "h4_islandx_terrain_props_05_b",
--     "h4_islandx_terrain_02_slod",
--     "h4_islandx_terrain_props_05_e",
--     "h4_islandx_terrain_props_05_d",
--     "h4_mph4_terrain_05",
--     "h4_mph4_terrain_02_grass_2",
--     "h4_mph4_terrain_01_grass_1",
--     "h4_mph4_terrain_05_grass_0",
--     "h4_mph4_terrain_01_grass_0",
--     "h4_mph4_terrain_02_grass_1",
--     "h4_mph4_terrain_02_grass_0",
--     "h4_mph4_terrain_02_grass_3",
--     "h4_mph4_terrain_04_grass_0",
--     "h4_mph4_terrain_06_grass_0",
--     "h4_mph4_terrain_04_grass_1",
--     "island_distantlights",
--     "island_lodlights",
--     "h4_yacht_strm_0",
--     "h4_yacht",
--     "h4_yacht_long_0",
--     "h4_islandx_yacht_01_lod",
--     "h4_clubposter_palmstraxx",
--     "h4_islandx_yacht_02_int",
--     "h4_islandx_yacht_02",
--     "h4_clubposter_moodymann",
--     "h4_islandx_yacht_01",
--     "h4_clubposter_keinemusik",
--     "h4_islandx_yacht_03",
--     "h4_ch2_mansion_final",
--     "h4_islandx_yacht_03_int",
--     "h4_yacht_critical_0",
--     "h4_islandx_yacht_01_int",
--     "h4_mph4_island_placement",
--     "h4_islandx_mansion_vault",
--     "h4_islandx_checkpoint_props",
--     "h4_islandairstrip_hangar_props_slod",
--     "h4_se_ipl_01_lod",
--     "h4_ne_ipl_00_slod",
--     "h4_se_ipl_06_slod",
--     "h4_ne_ipl_00",
--     "h4_se_ipl_02",
--     "h4_islandx_barrack_props_lod",
--     "h4_se_ipl_09_lod",
--     "h4_ne_ipl_05",
--     "h4_mph4_island_se_placement",
--     "h4_ne_ipl_09",
--     "h4_islandx_mansion_props_slod",
--     "h4_se_ipl_09",
--     "h4_mph4_mansion_b",
--     "h4_islandairstrip_hangar_props_lod",
--     "h4_islandx_mansion_entrance_fence",
--     "h4_nw_ipl_09",
--     "h4_nw_ipl_02_lod",
--     "h4_ne_ipl_09_slod",
--     "h4_sw_ipl_02",
--     "h4_islandx_checkpoint",
--     "h4_islandxdock_water_hatch",
--     "h4_nw_ipl_04_lod",
--     "h4_islandx_maindock_props",
--     "h4_beach",
--     "h4_islandx_mansion_lockup_03_lod",
--     "h4_ne_ipl_04_slod",
--     "h4_mph4_island_nw_placement",
--     "h4_ne_ipl_08_slod",
--     "h4_nw_ipl_09_lod",
--     "h4_se_ipl_08_lod",
--     "h4_islandx_maindock_props_lod",
--     "h4_se_ipl_03",
--     "h4_sw_ipl_02_slod",
--     "h4_nw_ipl_00",
--     "h4_islandx_mansion_b_side_fence",
--     "h4_ne_ipl_01_lod",
--     "h4_se_ipl_06_lod",
--     "h4_ne_ipl_03",
--     "h4_islandx_maindock",
--     "h4_se_ipl_01",
--     "h4_sw_ipl_07",
--     "h4_islandx_maindock_props_2",
--     "h4_islandxtower_veg",
--     "h4_mph4_island_sw_placement",
--     "h4_se_ipl_01_slod",
--     "h4_mph4_wtowers",
--     "h4_se_ipl_02_lod",
--     "h4_islandx_mansion",
--     "h4_nw_ipl_04",
--     "h4_mph4_airstrip_interior_0_airstrip_hanger",
--     "h4_islandx_mansion_lockup_01",
--     "h4_islandx_barrack_props",
--     "h4_nw_ipl_07_lod",
--     "h4_nw_ipl_00_slod",
--     "h4_sw_ipl_08_lod",
--     "h4_islandxdock_props_slod",
--     "h4_islandx_mansion_lockup_02",
--     "h4_islandx_mansion_slod",
--     "h4_sw_ipl_07_lod",
--     "h4_islandairstrip_doorsclosed_lod",
--     "h4_sw_ipl_02_lod",
--     "h4_se_ipl_04_slod",
--     "h4_islandx_checkpoint_props_lod",
--     "h4_se_ipl_04",
--     "h4_se_ipl_07",
--     "h4_mph4_mansion_b_strm_0",
--     "h4_nw_ipl_09_slod",
--     "h4_se_ipl_07_lod",
--     "h4_islandx_maindock_slod",
--     "h4_islandx_mansion_lod",
--     "h4_sw_ipl_05_lod",
--     "h4_nw_ipl_08",
--     "h4_islandairstrip_slod",
--     "h4_nw_ipl_07",
--     "h4_islandairstrip_propsb_lod",
--     "h4_islandx_checkpoint_props_slod",
--     "h4_aa_guns_lod",
--     "h4_sw_ipl_06",
--     "h4_islandx_maindock_props_2_slod",
--     "h4_islandx_mansion_office",
--     "h4_islandx_maindock_lod",
--     "h4_mph4_dock",
--     "h4_islandairstrip_propsb",
--     "h4_islandx_mansion_lockup_03",
--     "h4_nw_ipl_01_lod",
--     "h4_se_ipl_05_slod",
--     "h4_sw_ipl_01_lod",
--     "h4_nw_ipl_05",
--     "h4_islandxdock_props_2_lod",
--     "h4_ne_ipl_04_lod",
--     "h4_ne_ipl_01",
--     "h4_beach_party_lod",
--     "h4_islandx_mansion_lights",
--     "h4_sw_ipl_00_lod",
--     "h4_islandx_mansion_guardfence",
--     "h4_beach_props_party",
--     "h4_ne_ipl_03_lod",
--     "h4_islandx_mansion_b",
--     "h4_beach_bar_props",
--     "h4_ne_ipl_04",
--     "h4_sw_ipl_08_slod",
--     "h4_islandxtower",
--     "h4_se_ipl_00_slod",
--     "h4_islandx_barrack_hatch",
--     "h4_ne_ipl_06_slod",
--     "h4_ne_ipl_03_slod",
--     "h4_sw_ipl_09_slod",
--     "h4_ne_ipl_02_slod",
--     "h4_nw_ipl_04_slod",
--     "h4_ne_ipl_05_lod",
--     "h4_nw_ipl_08_slod",
--     "h4_sw_ipl_05_slod",
--     "h4_islandx_mansion_b_lod",
--     "h4_ne_ipl_08",
--     "h4_islandxdock_props",
--     "h4_islandairstrip_doorsopen_lod",
--     "h4_se_ipl_05_lod",
--     "h4_islandxcanal_props_slod",
--     "h4_mansion_gate_closed",
--     "h4_se_ipl_02_slod",
--     "h4_nw_ipl_02",
--     "h4_ne_ipl_08_lod",
--     "h4_sw_ipl_08",
--     "h4_islandairstrip",
--     "h4_islandairstrip_props_lod",
--     "h4_se_ipl_05",
--     "h4_ne_ipl_02_lod",
--     "h4_islandx_maindock_props_2_lod",
--     "h4_sw_ipl_03_slod",
--     "h4_ne_ipl_01_slod",
--     "h4_beach_props_slod",
--     "h4_underwater_gate_closed",
--     "h4_ne_ipl_00_lod",
--     "h4_islandairstrip_doorsopen",
--     "h4_sw_ipl_01_slod",
--     "h4_se_ipl_00",
--     "h4_se_ipl_06",
--     "h4_islandx_mansion_lockup_02_lod",
--     "h4_islandxtower_veg_lod",
--     "h4_sw_ipl_00",
--     "h4_se_ipl_04_lod",
--     "h4_nw_ipl_07_slod",
--     "h4_islandx_mansion_props_lod",
--     "h4_islandairstrip_hangar_props",
--     "h4_nw_ipl_06_lod",
--     "h4_islandxtower_lod",
--     "h4_islandxdock_lod",
--     "h4_islandxdock_props_lod",
--     "h4_beach_party",
--     "h4_nw_ipl_06_slod",
--     "h4_islandairstrip_doorsclosed",
--     "h4_nw_ipl_00_lod",
--     "h4_ne_ipl_02",
--     "h4_islandxdock_slod",
--     "h4_se_ipl_07_slod",
--     "h4_islandxdock",
--     "h4_islandxdock_props_2_slod",
--     "h4_islandairstrip_props",
--     "h4_sw_ipl_09",
--     "h4_ne_ipl_06",
--     "h4_se_ipl_03_lod",
--     "h4_nw_ipl_03",
--     "h4_islandx_mansion_lockup_01_lod",
--     "h4_beach_lod",
--     "h4_ne_ipl_07_lod",
--     "h4_nw_ipl_01",
--     "h4_mph4_island_lod",
--     "h4_islandx_mansion_office_lod",
--     "h4_islandairstrip_lod",
--     "h4_beach_props_lod",
--     "h4_nw_ipl_05_slod",
--     "h4_islandx_checkpoint_lod",
--     "h4_nw_ipl_05_lod",
--     "h4_nw_ipl_03_slod",
--     "h4_nw_ipl_03_lod",
--     "h4_sw_ipl_05",
--     "h4_mph4_mansion",
--     "h4_sw_ipl_03",
--     "h4_se_ipl_08_slod",
--     "h4_mph4_island_ne_placement",
--     "h4_aa_guns",
--     "h4_islandairstrip_propsb_slod",
--     "h4_sw_ipl_01",
--     "h4_mansion_remains_cage",
--     "h4_nw_ipl_01_slod",
--     "h4_ne_ipl_06_lod",
--     "h4_se_ipl_08",
--     "h4_sw_ipl_04_slod",
--     "h4_sw_ipl_04_lod",
--     "h4_mph4_beach",
--     "h4_sw_ipl_06_lod",
--     "h4_sw_ipl_06_slod",
--     "h4_se_ipl_00_lod",
--     "h4_ne_ipl_07_slod",
--     "h4_mph4_mansion_strm_0",
--     "h4_nw_ipl_02_slod",
--     "h4_mph4_airstrip",
--     "h4_island_padlock_props",
--     "h4_islandairstrip_props_slod",
--     "h4_nw_ipl_06",
--     "h4_sw_ipl_09_lod",
--     "h4_islandxcanal_props_lod",
--     "h4_ne_ipl_05_slod",
--     "h4_se_ipl_09_slod",
--     "h4_islandx_mansion_vault_lod",
--     "h4_se_ipl_03_slod",
--     "h4_nw_ipl_08_lod",
--     "h4_islandx_barrack_props_slod",
--     "h4_islandxtower_veg_slod",
--     "h4_sw_ipl_04",
--     "h4_islandx_mansion_props",
--     "h4_islandxtower_slod",
--     "h4_beach_props",
--     "h4_islandx_mansion_b_slod",
--     "h4_islandx_maindock_props_slod",
--     "h4_sw_ipl_07_slod",
--     "h4_ne_ipl_07",
--     "h4_islandxdock_props_2",
--     "h4_ne_ipl_09_lod",
--     "h4_islandxcanal_props",
--     "h4_beach_slod",
--     "h4_sw_ipl_00_slod",
--     "h4_sw_ipl_03_lod",
--     "h4_islandx_disc_strandedshark",
--     "h4_islandx_disc_strandedshark_lod",
--     "h4_islandx",
--     "h4_islandx_props_lod",
--     "h4_mph4_island_strm_0",
--     "h4_islandx_sea_mines",
--     "h4_mph4_island",
--     "h4_boatblockers",
--     "h4_mph4_island_long_0",
--     "h4_islandx_disc_strandedwhale",
--     "h4_islandx_disc_strandedwhale_lod",
--     "h4_islandx_props",
--     "h4_int_placement_h4_interior_1_dlc_int_02_h4_milo_",
--     "h4_int_placement_h4_interior_0_int_sub_h4_milo_",
--     "h4_int_placement_h4",
	
-- 	"int_cayo_bung",
-- 	"int_cayo_bung_01_milo_",
-- 	"int_cayo_bung_02_milo_",
-- 	"int_cayo_bung_03_milo_",
-- 	"int_cayo_bung_04_milo_",
-- 	"int_cayo_bung_05_milo_",
-- 	"int_cayo_bung_06_milo_",
-- 	"int_cayo_bung_07_milo_",
-- 	"uj_cayo_jungle_01",
-- 	"uj_cayo_jungle_02",
-- 	"uj_cayo_water_01",
-- 	"uj_cayo_light_01",
-- 	"uj_cayo_shops",
	
-- 	"int_cayo_base2_milo_",
-- 	"int_cayo_base3_milo_",
-- 	"int_cayo_base_milo_",
	
-- 	"int_cayo_barracks_01_milo_",
-- 	"int_cayo_barracks_02_milo_",
-- 	"int_cayo_stock_01_milo_",
-- 	"int_cayo_stock_02_milo_",
-- 	"int_cayo_stock_03_milo_",
-- 	"int_cayo_stock_04_milo_",
-- 	"int_cayo_stock_05_milo_",
-- 	"uj_cayo_barracs",
	
-- 	"uj_cayo_med2_milo_",
-- 	"uj_cayo_med_milo_",
-- 	"uj_cayo_med3_milo_",
-- 	"uj_cayo_med_build",
	
-- 	"uj_ipl_cayom_pool_door"
--     }

-- local int_barracks = GetInteriorAtCoordsWithType(4969.689, -5286.237, 6.293,"uj_cayo_barracks")
-- EnableInteriorProp(int_barracks, "box")
-- RefreshInterior(int_barracks)
	
-- local int_stock1 = GetInteriorAtCoordsWithType(5130.676, -4611.803, -4.666,"int_stock")
-- EnableInteriorProp(int_stock1, "light_stock")
-- EnableInteriorProp(int_stock1, "meth_app")
-- EnableInteriorProp(int_stock1, "meth_staff_01")
-- EnableInteriorProp(int_stock1, "meth_staff_02")
-- EnableInteriorProp(int_stock1, "meth_update_lab_01")
-- EnableInteriorProp(int_stock1, "meth_update_lab_02")
-- EnableInteriorProp(int_stock1, "meth_update_lab_01_2")
-- EnableInteriorProp(int_stock1, "meth_update_lab_02_2")
-- EnableInteriorProp(int_stock1, "meth_stock")
-- RefreshInterior(int_stock1)
	
-- local int_stock2 = GetInteriorAtCoordsWithType(5134.326, -5190.307, -4.675,"int_stock")
-- EnableInteriorProp(int_stock2, "weed_app")
-- EnableInteriorProp(int_stock2, "weed_staff_01")
-- EnableInteriorProp(int_stock2, "weed_staff_02")
-- EnableInteriorProp(int_stock2, "weed_update_lamp")
-- EnableInteriorProp(int_stock2, "weed_fan_update")
-- EnableInteriorProp(int_stock2, "weed_stock")
-- EnableInteriorProp(int_stock2, "weed_plant_v7")
-- RefreshInterior(int_stock2)
	
-- local int_stock3 = GetInteriorAtCoordsWithType(4983.767, -5133.899, -4.474,"int_stock")
-- EnableInteriorProp(int_stock3, "light_stock")
-- EnableInteriorProp(int_stock3, "coke_app")
-- EnableInteriorProp(int_stock3, "coke_staff_01")
-- EnableInteriorProp(int_stock3, "coke_staff_02")
-- EnableInteriorProp(int_stock3, "coke_stock")
-- RefreshInterior(int_stock3)
	
-- local int_stock4 = GetInteriorAtCoordsWithType(4906.630, -5279.436, -1.376,"int_stock")
-- EnableInteriorProp(int_stock4, "light_stock")
-- EnableInteriorProp(int_stock4, "money_app")
-- EnableInteriorProp(int_stock4, "money_staff_02")
-- EnableInteriorProp(int_stock4, "money_stock")
-- RefreshInterior(int_stock4)
	
-- local int_stock5 = GetInteriorAtCoordsWithType(4986.189, -5295.240, -0.818,"int_stock")
-- EnableInteriorProp(int_stock5, "light_stock")
-- EnableInteriorProp(int_stock5, "weapon_app")
-- EnableInteriorProp(int_stock5, "weapon_staff_01")
-- EnableInteriorProp(int_stock5, "weapon_stock")
-- RefreshInterior(int_stock5)

-- CreateThread(function()
-- 	for i = #requestedIpl, 1, -1 do
-- 		RequestIpl(requestedIpl[i])
-- 		requestedIpl[i] = nil
-- 	end
-- 	requestedIpl = nil
-- end)

local islandVec = vector3(4840.571, -5174.425, 2.0)
CreateThread(function()
    local inzone = false
    while true do Wait(5)
        inzone = false
        local pCoords = GetEntityCoords(PlayerPedId(-1))
        local distance1 = #(pCoords - islandVec)
            if distance1 < 2000.0 then
                inzone = true
                SetRadarAsExteriorThisFrame()
                SetRadarAsInteriorThisFrame(`h4_fake_islandx`, vec(4700.0, -5145.0), 0, 0)
            end
        if not inzone then
          Wait(1000)
        end
    end
end)


CreateThread(function()
	Wait(2500)
	local islandLoaded = false
	local islandCoords = vector3(4840.571, -5174.425, 2.0)
	SetDeepOceanScaler(0.0)
	while true do
		local pCoords = GetEntityCoords(PlayerPedId())
		if #(pCoords - islandCoords) < 2000.0 then
			if not islandLoaded then
				islandLoaded = true
				Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 1)
			end
		else
			if islandLoaded then
				islandLoaded = false
				Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 0)
			end
		end
		Wait(5000)
	end
end)

local nrgqerbwE = {
    ["bung_01"] = {
        dfbrtrty = "int_cayo_bung_01_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4922.401, -4890.898, 2.882),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["bung_02"] = {
        dfbrtrty = "int_cayo_bung_02_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4905.901, -4895.277, 2.935),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["bung_03"] = {
        dfbrtrty = "int_cayo_bung_03_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4914.043, -4921.505, 2.883),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["bung_04"] = {
        dfbrtrty = "int_cayo_bung_04_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4928.957, -4917.173, 3.196),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["bung_05"] = {
        dfbrtrty = "int_cayo_bung_05_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4877.275, -4899.075, 2.319),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["bung_06"] = {
        dfbrtrty = "int_cayo_bung_06_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4881.355, -4956.812, 2.882),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["bung_07"] = {
        dfbrtrty = "int_cayo_bung_07_milo_",
        srnsrtnrter = "uj_cayo_bung_01",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4893.728, -4954.350, 2.882),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(3.30, -0.70, 3.30),
                    vector3(3.30, -0.70, 1.00),
                    vector3(3.30, 0.700, 1.00),
                    vector3(3.30, 0.700, 3.30)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(1.90, -2.70, 3.30),
                    vec(1.90, -2.70, 2.00),
                    vec(3.00, -1.60, 2.00),
                    vec(3.00, -1.60, 3.30)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-1.30, 2.70, 3.30),
                    vec(-1.30, 2.70, 2.00),
                    vec(-2.50, 1.50, 2.00),
                    vec(-2.50, 1.50, 3.30)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(2.90, 1.50, 3.30),
                    vec(2.90, 1.50, 2.00),
                    vec(1.80, 2.70, 2.00),
                    vec(1.80, 2.70, 3.30)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-2.40, -1.60, 3.30),
                    vec(-2.40, -1.60, 2.00),
                    vec(-1.30, -2.70, 2.00),
                    vec(-1.30, -2.70, 3.30)
                }
            },
            {
                uiou = 5,
                yut = 1285,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(0.00, 2.83, 2.02),
                    vec(0.00, 2.91, 3.00),
                    vec(0.55, 2.91, 3.00),
                    vec(0.55, 2.83, 2.02)
                }
            }
        }
    },
    ["base_01"] = {
        dfbrtrty = "int_cayo_base_milo_",
        srnsrtnrter = "int_cayo_base",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4958.787, -5101.636, 2.257),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(2.3000, -14.500, 0.000),
                    vector3(2.3000, -14.500, 2.400),
                    vector3(-4.500, -14.500, 2.400),
                    vector3(-4.500, -14.500, 0.000)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 2,
                wwev = 1,
                erwq = {
                    vec(-2.400, 2.700, 0.000),
                    vec(-2.400, 2.700, 2.300),
                    vec(-3.800, 2.700, 2.300),
                    vec(-3.800, 2.700, 0.000)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-6.900, 0.700, 0.600),
                    vec(-6.900, 0.700, 2.990),
                    vec(-6.900, 2.000, 2.990),
                    vec(-6.900, 2.000, 0.600)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-6.950, -9.970, 1.400),
                    vec(-6.950, -9.970, 2.950),
                    vec(-6.950, -3.900, 2.950),
                    vec(-6.950, -3.900, 1.400)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.800, -3.900, 1.400),
                    vec(4.800, -3.900, 2.950),
                    vec(4.800, -9.970, 2.950),
                    vec(4.800, -9.970, 1.400)
                }
            },
            {
                uiou = 5,
                yut = 64,
                werww = 2,
                wwev = 1,
                erwq = {
                    vec(2.600, -2.000, 1.400),
                    vec(2.600, -2.000, 2.900),
                    vec(0.600, -2.000, 2.900),
                    vec(0.600, -2.000, 1.400)
                }
            },
            {
                uiou = 6,
                yut = 8192,
                werww = 2,
                wwev = 0,
                erwq = {
                    vec(-6.950, 3.570, 1.400),
                    vec(-6.950, 3.570, 2.950),
                    vec(-6.950, 9.500, 2.950),
                    vec(-6.950, 9.500, 1.400)
                }
            },
            {
                uiou = 7,
                yut = 8192,
                werww = 2,
                wwev = 0,
                erwq = {
                    vec(-6.100, 11.300, 1.400),
                    vec(-6.100, 11.300, 2.950),
                    vec(3.9000, 11.300, 2.950),
                    vec(3.9000, 11.300, 1.400)
                }
            },
            {
                uiou = 8,
                yut = 8192,
                werww = 3,
                wwev = 2,
                erwq = {
                    vec(4.800, 9.400, 1.400),
                    vec(4.800, 9.400, 2.950),
                    vec(4.800, 3.500, 2.950),
                    vec(4.800, 3.500, 1.400)
                }
            },
            {
                uiou = 9,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(5.550, 10.500, 1.750),
                    vec(5.550, 10.500, 3.250),
                    vec(9.900, 10.500, 3.250),
                    vec(9.900, 10.500, 1.750)
                }
            },
            {
                uiou = 10,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(11.300, 10.500, 0.900),
                    vec(11.300, 10.500, 3.250),
                    vec(12.800, 10.500, 3.250),
                    vec(12.800, 10.500, 0.900)
                }
            },
            {
                uiou = 11,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(11.950, 2.750, 1.750),
                    vec(11.950, 2.750, 3.250),
                    vec(5.9900, 2.750, 3.250),
                    vec(5.9900, 2.750, 1.750)
                }
            },
            {
                uiou = 12,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(13.400, 9.699, 1.750),
                    vec(13.400, 9.699, 3.250),
                    vec(13.400, 3.600, 3.250),
                    vec(13.400, 3.600, 1.750)
                }
            }
        }
    },
    ["base_02"] = {
        dfbrtrty = "int_cayo_base2_milo_",
        srnsrtnrter = "int_cayo_base",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(5100.596, -4686.349, 1.696),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(2.3000, -14.500, 0.000),
                    vector3(2.3000, -14.500, 2.400),
                    vector3(-4.500, -14.500, 2.400),
                    vector3(-4.500, -14.500, 0.000)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 2,
                wwev = 1,
                erwq = {
                    vec(-2.400, 2.700, 0.000),
                    vec(-2.400, 2.700, 2.300),
                    vec(-3.800, 2.700, 2.300),
                    vec(-3.800, 2.700, 0.000)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-6.900, 0.700, 0.600),
                    vec(-6.900, 0.700, 2.990),
                    vec(-6.900, 2.000, 2.990),
                    vec(-6.900, 2.000, 0.600)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-6.950, -9.970, 1.400),
                    vec(-6.950, -9.970, 2.950),
                    vec(-6.950, -3.900, 2.950),
                    vec(-6.950, -3.900, 1.400)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.800, -3.900, 1.400),
                    vec(4.800, -3.900, 2.950),
                    vec(4.800, -9.970, 2.950),
                    vec(4.800, -9.970, 1.400)
                }
            },
            {
                uiou = 5,
                yut = 64,
                werww = 2,
                wwev = 1,
                erwq = {
                    vec(2.600, -2.000, 1.400),
                    vec(2.600, -2.000, 2.900),
                    vec(0.600, -2.000, 2.900),
                    vec(0.600, -2.000, 1.400)
                }
            },
            {
                uiou = 6,
                yut = 8192,
                werww = 2,
                wwev = 0,
                erwq = {
                    vec(-6.950, 3.570, 1.400),
                    vec(-6.950, 3.570, 2.950),
                    vec(-6.950, 9.500, 2.950),
                    vec(-6.950, 9.500, 1.400)
                }
            },
            {
                uiou = 7,
                yut = 8192,
                werww = 2,
                wwev = 0,
                erwq = {
                    vec(-6.100, 11.300, 1.400),
                    vec(-6.100, 11.300, 2.950),
                    vec(3.9000, 11.300, 2.950),
                    vec(3.9000, 11.300, 1.400)
                }
            },
            {
                uiou = 8,
                yut = 8192,
                werww = 3,
                wwev = 2,
                erwq = {
                    vec(4.800, 9.400, 1.400),
                    vec(4.800, 9.400, 2.950),
                    vec(4.800, 3.500, 2.950),
                    vec(4.800, 3.500, 1.400)
                }
            },
            {
                uiou = 9,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(5.550, 10.500, 1.750),
                    vec(5.550, 10.500, 3.250),
                    vec(9.900, 10.500, 3.250),
                    vec(9.900, 10.500, 1.750)
                }
            },
            {
                uiou = 10,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(11.300, 10.500, 0.900),
                    vec(11.300, 10.500, 3.250),
                    vec(12.800, 10.500, 3.250),
                    vec(12.800, 10.500, 0.900)
                }
            },
            {
                uiou = 11,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(11.950, 2.750, 1.750),
                    vec(11.950, 2.750, 3.250),
                    vec(5.9900, 2.750, 3.250),
                    vec(5.9900, 2.750, 1.750)
                }
            },
            {
                uiou = 12,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(13.400, 9.699, 1.750),
                    vec(13.400, 9.699, 3.250),
                    vec(13.400, 3.600, 3.250),
                    vec(13.400, 3.600, 1.750)
                }
            }
        }
    },
    ["base_03"] = {
        dfbrtrty = "int_cayo_base3_milo_",
        srnsrtnrter = "int_cayo_base",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(5145.229, -5125.005, 1.425),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(2.3000, -14.500, 0.000),
                    vector3(2.3000, -14.500, 2.400),
                    vector3(-4.500, -14.500, 2.400),
                    vector3(-4.500, -14.500, 0.000)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 2,
                wwev = 1,
                erwq = {
                    vec(-2.400, 2.700, 0.000),
                    vec(-2.400, 2.700, 2.300),
                    vec(-3.800, 2.700, 2.300),
                    vec(-3.800, 2.700, 0.000)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-6.900, 0.700, 0.600),
                    vec(-6.900, 0.700, 2.990),
                    vec(-6.900, 2.000, 2.990),
                    vec(-6.900, 2.000, 0.600)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-6.950, -9.970, 1.400),
                    vec(-6.950, -9.970, 2.950),
                    vec(-6.950, -3.900, 2.950),
                    vec(-6.950, -3.900, 1.400)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.800, -3.900, 1.400),
                    vec(4.800, -3.900, 2.950),
                    vec(4.800, -9.970, 2.950),
                    vec(4.800, -9.970, 1.400)
                }
            },
            {
                uiou = 5,
                yut = 64,
                werww = 2,
                wwev = 1,
                erwq = {
                    vec(2.600, -2.000, 1.400),
                    vec(2.600, -2.000, 2.900),
                    vec(0.600, -2.000, 2.900),
                    vec(0.600, -2.000, 1.400)
                }
            },
            {
                uiou = 6,
                yut = 8192,
                werww = 2,
                wwev = 0,
                erwq = {
                    vec(-6.950, 3.570, 1.400),
                    vec(-6.950, 3.570, 2.950),
                    vec(-6.950, 9.500, 2.950),
                    vec(-6.950, 9.500, 1.400)
                }
            },
            {
                uiou = 7,
                yut = 8192,
                werww = 2,
                wwev = 0,
                erwq = {
                    vec(-6.100, 11.300, 1.400),
                    vec(-6.100, 11.300, 2.950),
                    vec(3.9000, 11.300, 2.950),
                    vec(3.9000, 11.300, 1.400)
                }
            },
            {
                uiou = 8,
                yut = 8192,
                werww = 3,
                wwev = 2,
                erwq = {
                    vec(4.800, 9.400, 1.400),
                    vec(4.800, 9.400, 2.950),
                    vec(4.800, 3.500, 2.950),
                    vec(4.800, 3.500, 1.400)
                }
            },
            {
                uiou = 9,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(5.550, 10.500, 1.750),
                    vec(5.550, 10.500, 3.250),
                    vec(9.900, 10.500, 3.250),
                    vec(9.900, 10.500, 1.750)
                }
            },
            {
                uiou = 10,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(11.300, 10.500, 0.900),
                    vec(11.300, 10.500, 3.250),
                    vec(12.800, 10.500, 3.250),
                    vec(12.800, 10.500, 0.900)
                }
            },
            {
                uiou = 11,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(11.950, 2.750, 1.750),
                    vec(11.950, 2.750, 3.250),
                    vec(5.9900, 2.750, 3.250),
                    vec(5.9900, 2.750, 1.750)
                }
            },
            {
                uiou = 12,
                yut = 8192,
                werww = 3,
                wwev = 0,
                erwq = {
                    vec(13.400, 9.699, 1.750),
                    vec(13.400, 9.699, 3.250),
                    vec(13.400, 3.600, 3.250),
                    vec(13.400, 3.600, 1.750)
                }
            }
        }
    },
    ["barracks_01"] = {
        dfbrtrty = "int_cayo_barracks_01_milo_",
        srnsrtnrter = "uj_cayo_barracks",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4925.351, -5287.008, 7.183),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(-4.150, -4.600, 0.3000),
                    vector3(-4.150, -4.600, -1.100),
                    vector3(-4.150, -6.900, -1.130),
                    vector3(-4.150, -6.900, 0.3000)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.500, -9.699, 0.2000),
                    vec(4.500, -9.699, -2.500),
                    vec(4.500, -7.600, -2.500),
                    vec(4.500, -7.600, 0.2000)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.100, 2.550, 0.3000),
                    vec(4.100, 2.550, -1.100),
                    vec(4.100, 4.800, -1.100),
                    vec(4.100, 4.800, 0.3000)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.100, -3.900, 0.3000),
                    vec(4.100, -3.900, -1.100),
                    vec(4.100, -1.600, -1.100),
                    vec(4.100, -1.600, 0.3000)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-4.150, 1.300, 0.3000),
                    vec(-4.150, 1.300, -1.100),
                    vec(-4.150, -1.00, -1.100),
                    vec(-4.150, -1.00, 0.3000)
                }
            }
        }
    },
    ["barracks_02"] = {
        dfbrtrty = "int_cayo_barracks_02_milo_",
        srnsrtnrter = "uj_cayo_barracks",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4969.681, -5289.068, 7.737),
        jkiuy = {
            {
                uiou = 0,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(-4.150, -4.600, 0.3000),
                    vector3(-4.150, -4.600, -1.100),
                    vector3(-4.150, -6.900, -1.130),
                    vector3(-4.150, -6.900, 0.3000)
                }
            },
            {
                uiou = 1,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.500, -9.699, 0.2000),
                    vec(4.500, -9.699, -2.500),
                    vec(4.500, -7.600, -2.500),
                    vec(4.500, -7.600, 0.2000)
                }
            },
            {
                uiou = 2,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.100, 2.550, 0.3000),
                    vec(4.100, 2.550, -1.100),
                    vec(4.100, 4.800, -1.100),
                    vec(4.100, 4.800, 0.3000)
                }
            },
            {
                uiou = 3,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(4.100, -3.900, 0.3000),
                    vec(4.100, -3.900, -1.100),
                    vec(4.100, -1.600, -1.100),
                    vec(4.100, -1.600, 0.3000)
                }
            },
            {
                uiou = 4,
                yut = 8192,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-4.150, 1.300, 0.3000),
                    vec(-4.150, 1.300, -1.100),
                    vec(-4.150, -1.00, -1.100),
                    vec(-4.150, -1.00, 0.3000)
                }
            }
        }
    },
    ["med_01"] = {
        dfbrtrty = "uj_cayo_med_milo_",
        srnsrtnrter = "uj_cayo_med",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(5074.281, -4567.228, 5.472),
        jkiuy = {
            {
                uiou = 0,
                yut = 64,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(-2.900, -2.900, 1.9000),
                    vector3(-2.900, -2.900, -0.500),
                    vector3(-1.500, -2.900, -0.500),
                    vector3(-1.500, -2.900, 1.9000)
                }
            },
            {
                uiou = 1,
                yut = 9,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-5.250, -0.450, 2.400),
                    vec(-5.250, -0.450, 0.200),
                    vec(-5.250, -1.900, 0.200),
                    vec(-5.250, -1.900, 2.400)
                }
            },
            {
                uiou = 2,
                yut = 9,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(3.250, -0.400, 2.200),
                    vec(3.250, -0.400, 0.400),
                    vec(3.250, 2.4500, 0.400),
                    vec(3.250, 2.4500, 2.200)
                }
            }
        }
    },
    ["med_02"] = {
        dfbrtrty = "uj_cayo_med2_milo_",
        srnsrtnrter = "uj_cayo_med",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(4879.575, -5265.430, 8.646),
        jkiuy = {
            {
                uiou = 0,
                yut = 64,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(-2.900, -2.900, 1.9000),
                    vector3(-2.900, -2.900, -0.500),
                    vector3(-1.500, -2.900, -0.500),
                    vector3(-1.500, -2.900, 1.9000)
                }
            },
            {
                uiou = 1,
                yut = 9,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-5.250, -0.450, 2.400),
                    vec(-5.250, -0.450, 0.200),
                    vec(-5.250, -1.900, 0.200),
                    vec(-5.250, -1.900, 2.400)
                }
            },
            {
                uiou = 2,
                yut = 9,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(3.250, -0.400, 2.200),
                    vec(3.250, -0.400, 0.400),
                    vec(3.250, 2.4500, 0.400),
                    vec(3.250, 2.4500, 2.200)
                }
            }
        }
    },
    ["med_03"] = {
        dfbrtrty = "uj_cayo_med3_milo_",
        srnsrtnrter = "uj_cayo_med",
        mtneetywennf = true,
        jnmhtyuu = false,
        ghny = vector3(5532.915, -5225.564, 13.248),
        jkiuy = {
            {
                uiou = 0,
                yut = 64,
                werww = 1,
                wwev = 0,
                erwq = {
                    vector3(-2.900, -2.900, 1.9000),
                    vector3(-2.900, -2.900, -0.500),
                    vector3(-1.500, -2.900, -0.500),
                    vector3(-1.500, -2.900, 1.9000)
                }
            },
            {
                uiou = 1,
                yut = 9,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(-5.250, -0.450, 2.400),
                    vec(-5.250, -0.450, 0.200),
                    vec(-5.250, -1.900, 0.200),
                    vec(-5.250, -1.900, 2.400)
                }
            },
            {
                uiou = 2,
                yut = 9,
                werww = 1,
                wwev = 0,
                erwq = {
                    vec(3.250, -0.400, 2.200),
                    vec(3.250, -0.400, 0.400),
                    vec(3.250, 2.4500, 0.400),
                    vec(3.250, 2.4500, 2.200)
                }
            }
        }
    }
}


local Inside = false
local Ipls = {['Range'] = {}}


LoadNeeded = function()
	Citizen.InvokeNative("0x9A9D1BA639675CF1", "HeistIsland", true)  -- load the map and removes the city
	RequestIpl("int_cayo_bung")
	RequestIpl("int_cayo_bung_01_milo_")
	RequestIpl("int_cayo_bung_02_milo_")
	RequestIpl("int_cayo_bung_03_milo_")
	RequestIpl("int_cayo_bung_04_milo_")
	RequestIpl("int_cayo_bung_05_milo_")
	RequestIpl("int_cayo_bung_06_milo_")
	RequestIpl("int_cayo_bung_07_milo_")
	RequestIpl("uj_cayo_jungle_01")
	RequestIpl("uj_cayo_jungle_02")
	RequestIpl("uj_cayo_water_01")
	RequestIpl("uj_cayo_light_01")
	RequestIpl("uj_cayo_shops")

	RequestIpl("int_cayo_base2_milo_")
	RequestIpl("int_cayo_base3_milo_")
	RequestIpl("int_cayo_base_milo_")

	RequestIpl("int_cayo_barracks_01_milo_")
	RequestIpl("int_cayo_barracks_02_milo_")
	RequestIpl("int_cayo_stock_01_milo_")
	RequestIpl("int_cayo_stock_02_milo_")
	RequestIpl("int_cayo_stock_03_milo_")
	RequestIpl("int_cayo_stock_04_milo_")
	RequestIpl("int_cayo_stock_05_milo_")
	RequestIpl("uj_cayo_barracs")

	RequestIpl("uj_cayo_med2_milo_")
	RequestIpl("uj_cayo_med_milo_")
	RequestIpl("uj_cayo_med3_milo_")
	RequestIpl("uj_cayo_med_build")
	RemoveIpl("hei_carrier")
	RemoveIpl("hei_carrier_int1")
	RemoveIpl("hei_carrier_int1_lod")
	RemoveIpl("hei_carrier_int2")
	RemoveIpl("hei_carrier_int2_lod")
	RemoveIpl("hei_carrier_int3")
	RemoveIpl("hei_carrier_int3_lod")
	RemoveIpl("hei_carrier_int4")
	RemoveIpl("hei_carrier_int4_lod")
	RemoveIpl("hei_carrier_int5")
	RemoveIpl("hei_carrier_int5_lod")
	RemoveIpl("hei_carrier_int6")
	RemoveIpl("hei_carrier_int6_lod")
	RemoveIpl("hei_carrier_lod")
	RemoveIpl("hei_carrier_slod")

	RequestIpl("uj_ipl_cayom_pool_door")

	local int_barracks = GetInteriorAtCoordsWithType(4969.689, -5286.237, 6.293,"uj_cayo_barracks")
	EnableInteriorProp(int_barracks, "box")
	RefreshInterior(int_barracks)
	
	local int_stock1 = GetInteriorAtCoordsWithType(5130.676, -4611.803, -4.666,"int_stock")
	EnableInteriorProp(int_stock1, "light_stock")
	EnableInteriorProp(int_stock1, "meth_app")
	EnableInteriorProp(int_stock1, "meth_staff_01")
	EnableInteriorProp(int_stock1, "meth_staff_02")
	EnableInteriorProp(int_stock1, "meth_update_lab_01")
	EnableInteriorProp(int_stock1, "meth_update_lab_02")
	EnableInteriorProp(int_stock1, "meth_update_lab_01_2")
	EnableInteriorProp(int_stock1, "meth_update_lab_02_2")
	EnableInteriorProp(int_stock1, "meth_stock")
	RefreshInterior(int_stock1)
	
	local int_stock2 = GetInteriorAtCoordsWithType(5134.326, -5190.307, -4.675,"int_stock")
	EnableInteriorProp(int_stock2, "weed_app")
	EnableInteriorProp(int_stock2, "weed_staff_01")
	EnableInteriorProp(int_stock2, "weed_staff_02")
	EnableInteriorProp(int_stock2, "weed_update_lamp")
	EnableInteriorProp(int_stock2, "weed_fan_update")
	EnableInteriorProp(int_stock2, "weed_stock")
	EnableInteriorProp(int_stock2, "weed_plant_v7")
	RefreshInterior(int_stock2)
	
	local int_stock3 = GetInteriorAtCoordsWithType(4983.767, -5133.899, -4.474,"int_stock")
	EnableInteriorProp(int_stock3, "light_stock")
	EnableInteriorProp(int_stock3, "coke_app")
	EnableInteriorProp(int_stock3, "coke_staff_01")
	EnableInteriorProp(int_stock3, "coke_staff_02")
	EnableInteriorProp(int_stock3, "coke_stock")
	RefreshInterior(int_stock3)
	
	local int_stock4 = GetInteriorAtCoordsWithType(4906.630, -5279.436, -1.376,"int_stock")
	EnableInteriorProp(int_stock4, "light_stock")
	EnableInteriorProp(int_stock4, "money_app")
	EnableInteriorProp(int_stock4, "money_staff_02")
	EnableInteriorProp(int_stock4, "money_stock")
	RefreshInterior(int_stock4)
	
	local int_stock5 = GetInteriorAtCoordsWithType(4986.189, -5295.240, -0.818,"int_stock")
	EnableInteriorProp(int_stock5, "light_stock")
	EnableInteriorProp(int_stock5, "weapon_app")
	EnableInteriorProp(int_stock5, "weapon_staff_01")
	EnableInteriorProp(int_stock5, "weapon_stock")
	RefreshInterior(int_stock5)
end

LoadTemp = function()
	Citizen.Wait(0)
    RequestIpl("h4_mph4_terrain_occ_09")
    RequestIpl("h4_mph4_terrain_occ_06")
    RequestIpl("h4_mph4_terrain_occ_05")
    RequestIpl("h4_mph4_terrain_occ_01")
    RequestIpl("h4_mph4_terrain_occ_00")
    RequestIpl("h4_mph4_terrain_occ_08")
    RequestIpl("h4_mph4_terrain_occ_04")
    RequestIpl("h4_mph4_terrain_occ_07")
    RequestIpl("h4_mph4_terrain_occ_03")
    RequestIpl("h4_mph4_terrain_occ_02")
    RequestIpl("h4_islandx_terrain_04")
    RequestIpl("h4_islandx_terrain_05_slod")
    RequestIpl("h4_islandx_terrain_props_05_d_slod")
    RequestIpl("h4_islandx_terrain_02")
    RequestIpl("h4_islandx_terrain_props_05_a_lod")
    RequestIpl("h4_islandx_terrain_props_05_c_lod")
    RequestIpl("h4_islandx_terrain_01")
    RequestIpl("h4_mph4_terrain_04")
    RequestIpl("h4_mph4_terrain_06")
    RequestIpl("h4_islandx_terrain_04_lod")
    RequestIpl("h4_islandx_terrain_03_lod")
    RequestIpl("h4_islandx_terrain_props_06_a")
    RequestIpl("h4_islandx_terrain_props_06_a_slod")
    RequestIpl("h4_islandx_terrain_props_05_f_lod")
    RequestIpl("h4_islandx_terrain_props_06_b")
    RequestIpl("h4_islandx_terrain_props_05_b_lod")
    RequestIpl("h4_mph4_terrain_lod")
    RequestIpl("h4_islandx_terrain_props_05_e_lod")
    RequestIpl("h4_islandx_terrain_05_lod")
    RequestIpl("h4_mph4_terrain_02")
    RequestIpl("h4_islandx_terrain_props_05_a")
    RequestIpl("h4_mph4_terrain_01_long_0")
    RequestIpl("h4_islandx_terrain_03")
    RequestIpl("h4_islandx_terrain_props_06_b_slod")
    RequestIpl("h4_islandx_terrain_01_slod")
    RequestIpl("h4_islandx_terrain_04_slod")
    RequestIpl("h4_islandx_terrain_props_05_d_lod")
    RequestIpl("h4_islandx_terrain_props_05_f_slod")
    RequestIpl("h4_islandx_terrain_props_05_c")
    RequestIpl("h4_islandx_terrain_02_lod")
    RequestIpl("h4_islandx_terrain_06_slod")
    RequestIpl("h4_islandx_terrain_props_06_c_slod")
    RequestIpl("h4_islandx_terrain_props_06_c")
    RequestIpl("h4_islandx_terrain_01_lod")
    RequestIpl("h4_mph4_terrain_06_strm_0")
    RequestIpl("h4_islandx_terrain_05")
    RequestIpl("h4_islandx_terrain_props_05_e_slod")
    RequestIpl("h4_islandx_terrain_props_06_c_lod")
    RequestIpl("h4_mph4_terrain_03")
    RequestIpl("h4_islandx_terrain_props_05_f")
    RequestIpl("h4_islandx_terrain_06_lod")
    RequestIpl("h4_mph4_terrain_01")
    RequestIpl("h4_islandx_terrain_06")
    RequestIpl("h4_islandx_terrain_props_06_a_lod")
    RequestIpl("h4_islandx_terrain_props_06_b_lod")
    RequestIpl("h4_islandx_terrain_props_05_b")
    RequestIpl("h4_islandx_terrain_02_slod")
    RequestIpl("h4_islandx_terrain_props_05_e")
    RequestIpl("h4_islandx_terrain_props_05_d")
    RequestIpl("h4_mph4_terrain_05")
    RequestIpl("h4_mph4_terrain_02_grass_2")
    RequestIpl("h4_mph4_terrain_01_grass_1")
    RequestIpl("h4_mph4_terrain_05_grass_0")
    RequestIpl("h4_mph4_terrain_01_grass_0")
    RequestIpl("h4_mph4_terrain_02_grass_1")
    RequestIpl("h4_mph4_terrain_02_grass_0")
    RequestIpl("h4_mph4_terrain_02_grass_3")
    RequestIpl("h4_mph4_terrain_04_grass_0")
    RequestIpl("h4_mph4_terrain_06_grass_0")
    RequestIpl("h4_mph4_terrain_04_grass_1")
    RequestIpl("island_distantlights")
    RequestIpl("island_lodlights")
    RequestIpl("h4_yacht_strm_0")
    RequestIpl("h4_yacht")
    RequestIpl("h4_yacht_long_0")
    RequestIpl("h4_islandx_yacht_01_lod")
    RequestIpl("h4_clubposter_palmstraxx")
    RequestIpl("h4_islandx_yacht_02_int")
    RequestIpl("h4_islandx_yacht_02")
    RequestIpl("h4_clubposter_moodymann")
    RequestIpl("h4_islandx_yacht_01")
    RequestIpl("h4_clubposter_keinemusik")
    RequestIpl("h4_islandx_yacht_03")
    RequestIpl("h4_ch2_mansion_final")
    RequestIpl("h4_islandx_yacht_03_int")
    RequestIpl("h4_yacht_critical_0")
    RequestIpl("h4_islandx_yacht_01_int")
    RequestIpl("h4_mph4_island_placement")
    RequestIpl("h4_islandx_mansion_vault")
    RequestIpl("h4_islandx_checkpoint_props")
    RequestIpl("h4_islandairstrip_hangar_props_slod")
    RequestIpl("h4_se_ipl_01_lod")
    RequestIpl("h4_ne_ipl_00_slod")
    RequestIpl("h4_se_ipl_06_slod")
    RequestIpl("h4_ne_ipl_00")
    RequestIpl("h4_se_ipl_02")
    RequestIpl("h4_islandx_barrack_props_lod")
    RequestIpl("h4_se_ipl_09_lod")
    RequestIpl("h4_ne_ipl_05")
    RequestIpl("h4_mph4_island_se_placement")
    RequestIpl("h4_ne_ipl_09")
    RequestIpl("h4_islandx_mansion_props_slod")
    RequestIpl("h4_se_ipl_09")
    RequestIpl("h4_mph4_mansion_b")
    RequestIpl("h4_islandairstrip_hangar_props_lod")
    RequestIpl("h4_islandx_mansion_entrance_fence")
    RequestIpl("h4_nw_ipl_09")
    RequestIpl("h4_nw_ipl_02_lod")
    RequestIpl("h4_ne_ipl_09_slod")
    RequestIpl("h4_sw_ipl_02")
    RequestIpl("h4_islandx_checkpoint")
    RequestIpl("h4_islandxdock_water_hatch")
    RequestIpl("h4_nw_ipl_04_lod")
    RequestIpl("h4_islandx_maindock_props")
    RequestIpl("h4_beach")
    RequestIpl("h4_islandx_mansion_lockup_03_lod")
    RequestIpl("h4_ne_ipl_04_slod")
    RequestIpl("h4_mph4_island_nw_placement")
    RequestIpl("h4_ne_ipl_08_slod")
    RequestIpl("h4_nw_ipl_09_lod")
    RequestIpl("h4_se_ipl_08_lod")
    RequestIpl("h4_islandx_maindock_props_lod")
    RequestIpl("h4_se_ipl_03")
    RequestIpl("h4_sw_ipl_02_slod")
    RequestIpl("h4_nw_ipl_00")
    RequestIpl("h4_islandx_mansion_b_side_fence")
    RequestIpl("h4_ne_ipl_01_lod")
    RequestIpl("h4_se_ipl_06_lod")
    RequestIpl("h4_ne_ipl_03")
    RequestIpl("h4_islandx_maindock")
    RequestIpl("h4_se_ipl_01")
    RequestIpl("h4_sw_ipl_07")
    RequestIpl("h4_islandx_maindock_props_2")
    RequestIpl("h4_islandxtower_veg")
    RequestIpl("h4_mph4_island_sw_placement")
    RequestIpl("h4_se_ipl_01_slod")
    RequestIpl("h4_mph4_wtowers")
    RequestIpl("h4_se_ipl_02_lod")
    RequestIpl("h4_islandx_mansion")
    RequestIpl("h4_nw_ipl_04")
    RequestIpl("h4_mph4_airstrip_interior_0_airstrip_hanger")
    RequestIpl("h4_islandx_mansion_lockup_01")
    RequestIpl("h4_islandx_barrack_props")
    RequestIpl("h4_nw_ipl_07_lod")
    RequestIpl("h4_nw_ipl_00_slod")
    RequestIpl("h4_sw_ipl_08_lod")
    RequestIpl("h4_islandxdock_props_slod")
    RequestIpl("h4_islandx_mansion_lockup_02")
    RequestIpl("h4_islandx_mansion_slod")
    RequestIpl("h4_sw_ipl_07_lod")
    RequestIpl("h4_islandairstrip_doorsclosed_lod")
    RequestIpl("h4_sw_ipl_02_lod")
    RequestIpl("h4_se_ipl_04_slod")
    RequestIpl("h4_islandx_checkpoint_props_lod")
    RequestIpl("h4_se_ipl_04")
    RequestIpl("h4_se_ipl_07")
    RequestIpl("h4_mph4_mansion_b_strm_0")
    RequestIpl("h4_nw_ipl_09_slod")
    RequestIpl("h4_se_ipl_07_lod")
    RequestIpl("h4_islandx_maindock_slod")
    RequestIpl("h4_islandx_mansion_lod")
    RequestIpl("h4_sw_ipl_05_lod")
    RequestIpl("h4_nw_ipl_08")
    RequestIpl("h4_islandairstrip_slod")
    RequestIpl("h4_nw_ipl_07")
    RequestIpl("h4_islandairstrip_propsb_lod")
    RequestIpl("h4_islandx_checkpoint_props_slod")
    RequestIpl("h4_aa_guns_lod")
    RequestIpl("h4_sw_ipl_06")
    RequestIpl("h4_islandx_maindock_props_2_slod")
    RequestIpl("h4_islandx_mansion_office")
    RequestIpl("h4_islandx_maindock_lod")
    RequestIpl("h4_mph4_dock")
    RequestIpl("h4_islandairstrip_propsb")
    RequestIpl("h4_islandx_mansion_lockup_03")
    RequestIpl("h4_nw_ipl_01_lod")
    RequestIpl("h4_se_ipl_05_slod")
    RequestIpl("h4_sw_ipl_01_lod")
    RequestIpl("h4_nw_ipl_05")
    RequestIpl("h4_islandxdock_props_2_lod")
    RequestIpl("h4_ne_ipl_04_lod")
    RequestIpl("h4_ne_ipl_01")
    RequestIpl("h4_beach_party_lod")
    RequestIpl("h4_islandx_mansion_lights")
    RequestIpl("h4_sw_ipl_00_lod")
    RequestIpl("h4_islandx_mansion_guardfence")
    RequestIpl("h4_beach_props_party")
    RequestIpl("h4_ne_ipl_03_lod")
    RequestIpl("h4_islandx_mansion_b")
    RequestIpl("h4_beach_bar_props")
    RequestIpl("h4_ne_ipl_04")
    RequestIpl("h4_sw_ipl_08_slod")
    RequestIpl("h4_islandxtower")
    RequestIpl("h4_se_ipl_00_slod")
    RequestIpl("h4_islandx_barrack_hatch")
    RequestIpl("h4_ne_ipl_06_slod")
    RequestIpl("h4_ne_ipl_03_slod")
    RequestIpl("h4_sw_ipl_09_slod")
    RequestIpl("h4_ne_ipl_02_slod")
    RequestIpl("h4_nw_ipl_04_slod")
    RequestIpl("h4_ne_ipl_05_lod")
    RequestIpl("h4_nw_ipl_08_slod")
    RequestIpl("h4_sw_ipl_05_slod")
    RequestIpl("h4_islandx_mansion_b_lod")
    RequestIpl("h4_ne_ipl_08")
    RequestIpl("h4_islandxdock_props")
    RequestIpl("h4_islandairstrip_doorsopen_lod")
    RequestIpl("h4_se_ipl_05_lod")
    RequestIpl("h4_islandxcanal_props_slod")
    RequestIpl("h4_mansion_gate_closed")
    RequestIpl("h4_se_ipl_02_slod")
    RequestIpl("h4_nw_ipl_02")
    RequestIpl("h4_ne_ipl_08_lod")
    RequestIpl("h4_sw_ipl_08")
    RequestIpl("h4_islandairstrip")
    RequestIpl("h4_islandairstrip_props_lod")
    RequestIpl("h4_se_ipl_05")
    RequestIpl("h4_ne_ipl_02_lod")
    RequestIpl("h4_islandx_maindock_props_2_lod")
    RequestIpl("h4_sw_ipl_03_slod")
    RequestIpl("h4_ne_ipl_01_slod")
    RequestIpl("h4_beach_props_slod")
    RequestIpl("h4_underwater_gate_closed")
    RequestIpl("h4_ne_ipl_00_lod")
    RequestIpl("h4_islandairstrip_doorsopen")
    RequestIpl("h4_sw_ipl_01_slod")
    RequestIpl("h4_se_ipl_00")
    RequestIpl("h4_se_ipl_06")
    RequestIpl("h4_islandx_mansion_lockup_02_lod")
    RequestIpl("h4_islandxtower_veg_lod")
    RequestIpl("h4_sw_ipl_00")
    RequestIpl("h4_se_ipl_04_lod")
    RequestIpl("h4_nw_ipl_07_slod")
    RequestIpl("h4_islandx_mansion_props_lod")
    RequestIpl("h4_islandairstrip_hangar_props")
    RequestIpl("h4_nw_ipl_06_lod")
    RequestIpl("h4_islandxtower_lod")
    RequestIpl("h4_islandxdock_lod")
    RequestIpl("h4_islandxdock_props_lod")
    RequestIpl("h4_beach_party")
    RequestIpl("h4_nw_ipl_06_slod")
    RequestIpl("h4_islandairstrip_doorsclosed")
    RequestIpl("h4_nw_ipl_00_lod")
    RequestIpl("h4_ne_ipl_02")
    RequestIpl("h4_islandxdock_slod")
    RequestIpl("h4_se_ipl_07_slod")
    RequestIpl("h4_islandxdock")
    RequestIpl("h4_islandxdock_props_2_slod")
    RequestIpl("h4_islandairstrip_props")
    RequestIpl("h4_sw_ipl_09")
    RequestIpl("h4_ne_ipl_06")
    RequestIpl("h4_se_ipl_03_lod")
    RequestIpl("h4_nw_ipl_03")
    RequestIpl("h4_islandx_mansion_lockup_01_lod")
    RequestIpl("h4_beach_lod")
    RequestIpl("h4_ne_ipl_07_lod")
    RequestIpl("h4_nw_ipl_01")
    RequestIpl("h4_mph4_island_lod")
    RequestIpl("h4_islandx_mansion_office_lod")
    RequestIpl("h4_islandairstrip_lod")
    RequestIpl("h4_beach_props_lod")
    RequestIpl("h4_nw_ipl_05_slod")
    RequestIpl("h4_islandx_checkpoint_lod")
    RequestIpl("h4_nw_ipl_05_lod")
    RequestIpl("h4_nw_ipl_03_slod")
    RequestIpl("h4_nw_ipl_03_lod")
    RequestIpl("h4_sw_ipl_05")
    RequestIpl("h4_mph4_mansion")
    RequestIpl("h4_sw_ipl_03")
    RequestIpl("h4_se_ipl_08_slod")
    RequestIpl("h4_mph4_island_ne_placement")
    RequestIpl("h4_aa_guns")
    RequestIpl("h4_islandairstrip_propsb_slod")
    RequestIpl("h4_sw_ipl_01")
    RequestIpl("h4_mansion_remains_cage")
    RequestIpl("h4_nw_ipl_01_slod")
    RequestIpl("h4_ne_ipl_06_lod")
    RequestIpl("h4_se_ipl_08")
    RequestIpl("h4_sw_ipl_04_slod")
    RequestIpl("h4_sw_ipl_04_lod")
    RequestIpl("h4_mph4_beach")
    RequestIpl("h4_sw_ipl_06_lod")
    RequestIpl("h4_sw_ipl_06_slod")
    RequestIpl("h4_se_ipl_00_lod")
    RequestIpl("h4_ne_ipl_07_slod")
    RequestIpl("h4_mph4_mansion_strm_0")
    RequestIpl("h4_nw_ipl_02_slod")
    RequestIpl("h4_mph4_airstrip")
    --RequestIpl("h4_mansion_gate_broken")
    RequestIpl("h4_island_padlock_props")
    RequestIpl("h4_islandairstrip_props_slod")
    RequestIpl("h4_nw_ipl_06")
    RequestIpl("h4_sw_ipl_09_lod")
    RequestIpl("h4_islandxcanal_props_lod")
    RequestIpl("h4_ne_ipl_05_slod")
    RequestIpl("h4_se_ipl_09_slod")
    RequestIpl("h4_islandx_mansion_vault_lod")
    RequestIpl("h4_se_ipl_03_slod")
    RequestIpl("h4_nw_ipl_08_lod")
    RequestIpl("h4_islandx_barrack_props_slod")
    RequestIpl("h4_islandxtower_veg_slod")
    RequestIpl("h4_sw_ipl_04")
    RequestIpl("h4_islandx_mansion_props")
    RequestIpl("h4_islandxtower_slod")
    RequestIpl("h4_beach_props")
    RequestIpl("h4_islandx_mansion_b_slod")
    RequestIpl("h4_islandx_maindock_props_slod")
    RequestIpl("h4_sw_ipl_07_slod")
    RequestIpl("h4_ne_ipl_07")
    RequestIpl("h4_islandxdock_props_2")
    RequestIpl("h4_ne_ipl_09_lod")
    RequestIpl("h4_islandxcanal_props")
    RequestIpl("h4_beach_slod")
    RequestIpl("h4_sw_ipl_00_slod")
    RequestIpl("h4_sw_ipl_03_lod")
    RequestIpl("h4_islandx_disc_strandedshark")
    RequestIpl("h4_islandx_disc_strandedshark_lod")
    RequestIpl("h4_islandx")
    RequestIpl("h4_islandx_props_lod")
    RequestIpl("h4_mph4_island_strm_0")
    RequestIpl("h4_islandx_sea_mines")
    RequestIpl("h4_mph4_island")
    RequestIpl("h4_boatblockers")
    RequestIpl("h4_mph4_island_long_0")
    RequestIpl("h4_islandx_disc_strandedwhale")
    RequestIpl("h4_islandx_disc_strandedwhale_lod")
    RequestIpl("h4_islandx_props")
    RequestIpl("h4_int_placement_h4_interior_1_dlc_int_02_h4_milo_")
    RequestIpl("h4_int_placement_h4_interior_0_int_sub_h4_milo_")
    RequestIpl("h4_int_placement_h4")
end
RemoveNeeded = function()
	Citizen.InvokeNative("0x9A9D1BA639675CF1", "HeistIsland", false)
	RemoveIpl("int_cayo_bung")
	RemoveIpl("int_cayo_bung_01_milo_")
	RemoveIpl("int_cayo_bung_02_milo_")
	RemoveIpl("int_cayo_bung_03_milo_")
	RemoveIpl("int_cayo_bung_04_milo_")
	RemoveIpl("int_cayo_bung_05_milo_")
	RemoveIpl("int_cayo_bung_06_milo_")
	RemoveIpl("int_cayo_bung_07_milo_")
	RemoveIpl("uj_cayo_jungle_01")
	RemoveIpl("uj_cayo_jungle_02")
	RemoveIpl("uj_cayo_water_01")
	RemoveIpl("uj_cayo_light_01")
	RemoveIpl("uj_cayo_shops")

	RemoveIpl("int_cayo_base2_milo_")
	RemoveIpl("int_cayo_base3_milo_")
	RemoveIpl("int_cayo_base_milo_")

	RemoveIpl("int_cayo_barracks_01_milo_")
	RemoveIpl("int_cayo_barracks_02_milo_")
	RemoveIpl("int_cayo_stock_01_milo_")
	RemoveIpl("int_cayo_stock_02_milo_")
	RemoveIpl("int_cayo_stock_03_milo_")
	RemoveIpl("int_cayo_stock_04_milo_")
	RemoveIpl("int_cayo_stock_05_milo_")
	RemoveIpl("uj_cayo_barracs")

	RemoveIpl("uj_cayo_med2_milo_")
	RemoveIpl("uj_cayo_med_milo_")
	RemoveIpl("uj_cayo_med3_milo_")
	RemoveIpl("uj_cayo_med_build")
	
	LoadTemp()
end


CreateThread(function()
	Wait(2500)
	local islandLoaded = false
	local islandCoords = vector3(4840.571, -5174.425, 2.0)
	SetDeepOceanScaler(0.0)
	while true do
		local pCoords = GetEntityCoords(PlayerPedId())
		if #(pCoords - islandCoords) < 2000.0 then
			if not islandLoaded then
				islandLoaded = true
                LoadNeeded()
				Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 1)
			end
		else
			if islandLoaded then
				islandLoaded = false
                RemoveNeeded()
				Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 0)
			end
		end
		Wait(5000)
	end
end)

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(1)
-- 		if GetInteriorFromEntity(GetPlayerPed(-1)) == 0 then
-- 			SetRadarAsExteriorThisFrame()
-- 			SetRadarAsInteriorThisFrame(GetHashKey("h4_fake_islandx"), 4700.0, -5145.0, 0, 0)
-- 		end
--     end
-- end)


  
  Citizen.CreateThread(function()
    while true do Wait(5)
      Citizen.Wait(2000)
      if true then
        local ukioo = Citizen.InvokeNative(0xD80958FC74E988A6)
        local rtyyt = GetEntityCoords(ukioo)
        -- print('test')
        for _,asde in pairs(nrgqerbwE) do
          local yyyrb = #(rtyyt - asde.ghny)
          if yyyrb < 150 then
            if asde.mtneetywennf then
              RequestIpl(asde.dfbrtrty)
              Citizen.InvokeNative(0x41B4893843BBDB74,asde.dfbrtrty)
              Ipls['Range'][asde.dfbrtrty] = true
              local ujymm = Citizen.InvokeNative(0x05B7A89BD78797FC,asde.ghny,asde.srnsrtnrter)
              for _,tyur in pairs(asde.jkiuy) do
                Citizen.InvokeNative(0x88B2355E,ujymm,tyur.uiou,tyur.yut)
                for i,ghny in pairs(tyur.erwq) do
                  Citizen.InvokeNative(0x87F43553,ujymm,tyur.uiou,i-1,ghny)
                end
              end
              if not asde.jnmhtyuu then
                asde.jnmhtyuu = true
                Citizen.InvokeNative(0x41F37C3427C75AE0,ujymm)
              end
            else
              Citizen.InvokeNative(0xEE6C5AD3ECE0A82D,asde.dfbrtrty)
              RemoveIpl(asde.dfbrtrty)
              Ipls['Range'][asde.dfbrtrty] = nil
            end
          elseif yyyrb > 150 and asde.jnmhtyuu then
            asde.jnmhtyuu = false
          end
        Wait(0)
        end
      end
    end
  end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
		for k, v in pairs(Ipls) do
			for k2,v2 in pairs(v) do
				RemoveIpl(k2)
				Ipls[k][k2] = nil
			end
		end
		Citizen.InvokeNative("0x9A9D1BA639675CF1", "HeistIsland", false)
	end
end)

Citizen.CreateThread(function()
    RequestIpl("h4_mph4_terrain_occ_09")
    RequestIpl("h4_mph4_terrain_occ_06")
    RequestIpl("h4_mph4_terrain_occ_05")
    RequestIpl("h4_mph4_terrain_occ_01")
    RequestIpl("h4_mph4_terrain_occ_00")
    RequestIpl("h4_mph4_terrain_occ_08")
    RequestIpl("h4_mph4_terrain_occ_04")
    RequestIpl("h4_mph4_terrain_occ_07")
    RequestIpl("h4_mph4_terrain_occ_03")
    RequestIpl("h4_mph4_terrain_occ_02")
    RequestIpl("h4_islandx_terrain_04")
    RequestIpl("h4_islandx_terrain_05_slod")
    RequestIpl("h4_islandx_terrain_props_05_d_slod")
    RequestIpl("h4_islandx_terrain_02")
    RequestIpl("h4_islandx_terrain_props_05_a_lod")
    RequestIpl("h4_islandx_terrain_props_05_c_lod")
    RequestIpl("h4_islandx_terrain_01")
    RequestIpl("h4_mph4_terrain_04")
    RequestIpl("h4_mph4_terrain_06")
    RequestIpl("h4_islandx_terrain_04_lod")
    RequestIpl("h4_islandx_terrain_03_lod")
    RequestIpl("h4_islandx_terrain_props_06_a")
    RequestIpl("h4_islandx_terrain_props_06_a_slod")
    RequestIpl("h4_islandx_terrain_props_05_f_lod")
    RequestIpl("h4_islandx_terrain_props_06_b")
    RequestIpl("h4_islandx_terrain_props_05_b_lod")
    RequestIpl("h4_mph4_terrain_lod")
    RequestIpl("h4_islandx_terrain_props_05_e_lod")
    RequestIpl("h4_islandx_terrain_05_lod")
    RequestIpl("h4_mph4_terrain_02")
    RequestIpl("h4_islandx_terrain_props_05_a")
    RequestIpl("h4_mph4_terrain_01_long_0")
    RequestIpl("h4_islandx_terrain_03")
    RequestIpl("h4_islandx_terrain_props_06_b_slod")
    RequestIpl("h4_islandx_terrain_01_slod")
    RequestIpl("h4_islandx_terrain_04_slod")
    RequestIpl("h4_islandx_terrain_props_05_d_lod")
    RequestIpl("h4_islandx_terrain_props_05_f_slod")
    RequestIpl("h4_islandx_terrain_props_05_c")
    RequestIpl("h4_islandx_terrain_02_lod")
    RequestIpl("h4_islandx_terrain_06_slod")
    RequestIpl("h4_islandx_terrain_props_06_c_slod")
    RequestIpl("h4_islandx_terrain_props_06_c")
    RequestIpl("h4_islandx_terrain_01_lod")
    RequestIpl("h4_mph4_terrain_06_strm_0")
    RequestIpl("h4_islandx_terrain_05")
    RequestIpl("h4_islandx_terrain_props_05_e_slod")
    RequestIpl("h4_islandx_terrain_props_06_c_lod")
    RequestIpl("h4_mph4_terrain_03")
    RequestIpl("h4_islandx_terrain_props_05_f")
    RequestIpl("h4_islandx_terrain_06_lod")
    RequestIpl("h4_mph4_terrain_01")
    RequestIpl("h4_islandx_terrain_06")
    RequestIpl("h4_islandx_terrain_props_06_a_lod")
    RequestIpl("h4_islandx_terrain_props_06_b_lod")
    RequestIpl("h4_islandx_terrain_props_05_b")
    RequestIpl("h4_islandx_terrain_02_slod")
    RequestIpl("h4_islandx_terrain_props_05_e")
    RequestIpl("h4_islandx_terrain_props_05_d")
    RequestIpl("h4_mph4_terrain_05")
    RequestIpl("h4_mph4_terrain_02_grass_2")
    RequestIpl("h4_mph4_terrain_01_grass_1")
    RequestIpl("h4_mph4_terrain_05_grass_0")
    RequestIpl("h4_mph4_terrain_01_grass_0")
    RequestIpl("h4_mph4_terrain_02_grass_1")
    RequestIpl("h4_mph4_terrain_02_grass_0")
    RequestIpl("h4_mph4_terrain_02_grass_3")
    RequestIpl("h4_mph4_terrain_04_grass_0")
    RequestIpl("h4_mph4_terrain_06_grass_0")
    RequestIpl("h4_mph4_terrain_04_grass_1")
    RequestIpl("island_distantlights")
    RequestIpl("island_lodlights")
    RequestIpl("h4_yacht_strm_0")
    RequestIpl("h4_yacht")
    RequestIpl("h4_yacht_long_0")
    RequestIpl("h4_islandx_yacht_01_lod")
    RequestIpl("h4_clubposter_palmstraxx")
    RequestIpl("h4_islandx_yacht_02_int")
    RequestIpl("h4_islandx_yacht_02")
    RequestIpl("h4_clubposter_moodymann")
    RequestIpl("h4_islandx_yacht_01")
    RequestIpl("h4_clubposter_keinemusik")
    RequestIpl("h4_islandx_yacht_03")
    RequestIpl("h4_ch2_mansion_final")
    RequestIpl("h4_islandx_yacht_03_int")
    RequestIpl("h4_yacht_critical_0")
    RequestIpl("h4_islandx_yacht_01_int")
    RequestIpl("h4_mph4_island_placement")
    RequestIpl("h4_islandx_mansion_vault")
    RequestIpl("h4_islandx_checkpoint_props")
    RequestIpl("h4_islandairstrip_hangar_props_slod")
    RequestIpl("h4_se_ipl_01_lod")
    RequestIpl("h4_ne_ipl_00_slod")
    RequestIpl("h4_se_ipl_06_slod")
    RequestIpl("h4_ne_ipl_00")
    RequestIpl("h4_se_ipl_02")
    RequestIpl("h4_islandx_barrack_props_lod")
    RequestIpl("h4_se_ipl_09_lod")
    RequestIpl("h4_ne_ipl_05")
    RequestIpl("h4_mph4_island_se_placement")
    RequestIpl("h4_ne_ipl_09")
    RequestIpl("h4_islandx_mansion_props_slod")
    RequestIpl("h4_se_ipl_09")
    RequestIpl("h4_mph4_mansion_b")
    RequestIpl("h4_islandairstrip_hangar_props_lod")
    RequestIpl("h4_islandx_mansion_entrance_fence")
    RequestIpl("h4_nw_ipl_09")
    RequestIpl("h4_nw_ipl_02_lod")
    RequestIpl("h4_ne_ipl_09_slod")
    RequestIpl("h4_sw_ipl_02")
    RequestIpl("h4_islandx_checkpoint")
    RequestIpl("h4_islandxdock_water_hatch")
    RequestIpl("h4_nw_ipl_04_lod")
    RequestIpl("h4_islandx_maindock_props")
    RequestIpl("h4_beach")
    RequestIpl("h4_islandx_mansion_lockup_03_lod")
    RequestIpl("h4_ne_ipl_04_slod")
    RequestIpl("h4_mph4_island_nw_placement")
    RequestIpl("h4_ne_ipl_08_slod")
    RequestIpl("h4_nw_ipl_09_lod")
    RequestIpl("h4_se_ipl_08_lod")
    RequestIpl("h4_islandx_maindock_props_lod")
    RequestIpl("h4_se_ipl_03")
    RequestIpl("h4_sw_ipl_02_slod")
    RequestIpl("h4_nw_ipl_00")
    RequestIpl("h4_islandx_mansion_b_side_fence")
    RequestIpl("h4_ne_ipl_01_lod")
    RequestIpl("h4_se_ipl_06_lod")
    RequestIpl("h4_ne_ipl_03")
    RequestIpl("h4_islandx_maindock")
    RequestIpl("h4_se_ipl_01")
    RequestIpl("h4_sw_ipl_07")
    RequestIpl("h4_islandx_maindock_props_2")
    RequestIpl("h4_islandxtower_veg")
    RequestIpl("h4_mph4_island_sw_placement")
    RequestIpl("h4_se_ipl_01_slod")
    RequestIpl("h4_mph4_wtowers")
    RequestIpl("h4_se_ipl_02_lod")
    RequestIpl("h4_islandx_mansion")
    RequestIpl("h4_nw_ipl_04")
    RequestIpl("h4_mph4_airstrip_interior_0_airstrip_hanger")
    RequestIpl("h4_islandx_mansion_lockup_01")
    RequestIpl("h4_islandx_barrack_props")
    RequestIpl("h4_nw_ipl_07_lod")
    RequestIpl("h4_nw_ipl_00_slod")
    RequestIpl("h4_sw_ipl_08_lod")
    RequestIpl("h4_islandxdock_props_slod")
    RequestIpl("h4_islandx_mansion_lockup_02")
    RequestIpl("h4_islandx_mansion_slod")
    RequestIpl("h4_sw_ipl_07_lod")
    RequestIpl("h4_islandairstrip_doorsclosed_lod")
    RequestIpl("h4_sw_ipl_02_lod")
    RequestIpl("h4_se_ipl_04_slod")
    RequestIpl("h4_islandx_checkpoint_props_lod")
    RequestIpl("h4_se_ipl_04")
    RequestIpl("h4_se_ipl_07")
    RequestIpl("h4_mph4_mansion_b_strm_0")
    RequestIpl("h4_nw_ipl_09_slod")
    RequestIpl("h4_se_ipl_07_lod")
    RequestIpl("h4_islandx_maindock_slod")
    RequestIpl("h4_islandx_mansion_lod")
    RequestIpl("h4_sw_ipl_05_lod")
    RequestIpl("h4_nw_ipl_08")
    RequestIpl("h4_islandairstrip_slod")
    RequestIpl("h4_nw_ipl_07")
    RequestIpl("h4_islandairstrip_propsb_lod")
    RequestIpl("h4_islandx_checkpoint_props_slod")
    RequestIpl("h4_aa_guns_lod")
    RequestIpl("h4_sw_ipl_06")
    RequestIpl("h4_islandx_maindock_props_2_slod")
    RequestIpl("h4_islandx_mansion_office")
    RequestIpl("h4_islandx_maindock_lod")
    RequestIpl("h4_mph4_dock")
    RequestIpl("h4_islandairstrip_propsb")
    RequestIpl("h4_islandx_mansion_lockup_03")
    RequestIpl("h4_nw_ipl_01_lod")
    RequestIpl("h4_se_ipl_05_slod")
    RequestIpl("h4_sw_ipl_01_lod")
    RequestIpl("h4_nw_ipl_05")
    RequestIpl("h4_islandxdock_props_2_lod")
    RequestIpl("h4_ne_ipl_04_lod")
    RequestIpl("h4_ne_ipl_01")
    RequestIpl("h4_beach_party_lod")
    RequestIpl("h4_islandx_mansion_lights")
    RequestIpl("h4_sw_ipl_00_lod")
    RequestIpl("h4_islandx_mansion_guardfence")
    RequestIpl("h4_beach_props_party")
    RequestIpl("h4_ne_ipl_03_lod")
    RequestIpl("h4_islandx_mansion_b")
    RequestIpl("h4_beach_bar_props")
    RequestIpl("h4_ne_ipl_04")
    RequestIpl("h4_sw_ipl_08_slod")
    RequestIpl("h4_islandxtower")
    RequestIpl("h4_se_ipl_00_slod")
    RequestIpl("h4_islandx_barrack_hatch")
    RequestIpl("h4_ne_ipl_06_slod")
    RequestIpl("h4_ne_ipl_03_slod")
    RequestIpl("h4_sw_ipl_09_slod")
    RequestIpl("h4_ne_ipl_02_slod")
    RequestIpl("h4_nw_ipl_04_slod")
    RequestIpl("h4_ne_ipl_05_lod")
    RequestIpl("h4_nw_ipl_08_slod")
    RequestIpl("h4_sw_ipl_05_slod")
    RequestIpl("h4_islandx_mansion_b_lod")
    RequestIpl("h4_ne_ipl_08")
    RequestIpl("h4_islandxdock_props")
    RequestIpl("h4_islandairstrip_doorsopen_lod")
    RequestIpl("h4_se_ipl_05_lod")
    RequestIpl("h4_islandxcanal_props_slod")
    RequestIpl("h4_mansion_gate_closed")
    RequestIpl("h4_se_ipl_02_slod")
    RequestIpl("h4_nw_ipl_02")
    RequestIpl("h4_ne_ipl_08_lod")
    RequestIpl("h4_sw_ipl_08")
    RequestIpl("h4_islandairstrip")
    RequestIpl("h4_islandairstrip_props_lod")
    RequestIpl("h4_se_ipl_05")
    RequestIpl("h4_ne_ipl_02_lod")
    RequestIpl("h4_islandx_maindock_props_2_lod")
    RequestIpl("h4_sw_ipl_03_slod")
    RequestIpl("h4_ne_ipl_01_slod")
    RequestIpl("h4_beach_props_slod")
    RequestIpl("h4_underwater_gate_closed")
    RequestIpl("h4_ne_ipl_00_lod")
    RequestIpl("h4_islandairstrip_doorsopen")
    RequestIpl("h4_sw_ipl_01_slod")
    RequestIpl("h4_se_ipl_00")
    RequestIpl("h4_se_ipl_06")
    RequestIpl("h4_islandx_mansion_lockup_02_lod")
    RequestIpl("h4_islandxtower_veg_lod")
    RequestIpl("h4_sw_ipl_00")
    RequestIpl("h4_se_ipl_04_lod")
    RequestIpl("h4_nw_ipl_07_slod")
    RequestIpl("h4_islandx_mansion_props_lod")
    RequestIpl("h4_islandairstrip_hangar_props")
    RequestIpl("h4_nw_ipl_06_lod")
    RequestIpl("h4_islandxtower_lod")
    RequestIpl("h4_islandxdock_lod")
    RequestIpl("h4_islandxdock_props_lod")
    RequestIpl("h4_beach_party")
    RequestIpl("h4_nw_ipl_06_slod")
    RequestIpl("h4_islandairstrip_doorsclosed")
    RequestIpl("h4_nw_ipl_00_lod")
    RequestIpl("h4_ne_ipl_02")
    RequestIpl("h4_islandxdock_slod")
    RequestIpl("h4_se_ipl_07_slod")
    RequestIpl("h4_islandxdock")
    RequestIpl("h4_islandxdock_props_2_slod")
    RequestIpl("h4_islandairstrip_props")
    RequestIpl("h4_sw_ipl_09")
    RequestIpl("h4_ne_ipl_06")
    RequestIpl("h4_se_ipl_03_lod")
    RequestIpl("h4_nw_ipl_03")
    RequestIpl("h4_islandx_mansion_lockup_01_lod")
    RequestIpl("h4_beach_lod")
    RequestIpl("h4_ne_ipl_07_lod")
    RequestIpl("h4_nw_ipl_01")
    RequestIpl("h4_mph4_island_lod")
    RequestIpl("h4_islandx_mansion_office_lod")
    RequestIpl("h4_islandairstrip_lod")
    RequestIpl("h4_beach_props_lod")
    RequestIpl("h4_nw_ipl_05_slod")
    RequestIpl("h4_islandx_checkpoint_lod")
    RequestIpl("h4_nw_ipl_05_lod")
    RequestIpl("h4_nw_ipl_03_slod")
    RequestIpl("h4_nw_ipl_03_lod")
    RequestIpl("h4_sw_ipl_05")
    RequestIpl("h4_mph4_mansion")
    RequestIpl("h4_sw_ipl_03")
    RequestIpl("h4_se_ipl_08_slod")
    RequestIpl("h4_mph4_island_ne_placement")
    RequestIpl("h4_aa_guns")
    RequestIpl("h4_islandairstrip_propsb_slod")
    RequestIpl("h4_sw_ipl_01")
    RequestIpl("h4_mansion_remains_cage")
    RequestIpl("h4_nw_ipl_01_slod")
    RequestIpl("h4_ne_ipl_06_lod")
    RequestIpl("h4_se_ipl_08")
    RequestIpl("h4_sw_ipl_04_slod")
    RequestIpl("h4_sw_ipl_04_lod")
    RequestIpl("h4_mph4_beach")
    RequestIpl("h4_sw_ipl_06_lod")
    RequestIpl("h4_sw_ipl_06_slod")
    RequestIpl("h4_se_ipl_00_lod")
    RequestIpl("h4_ne_ipl_07_slod")
    RequestIpl("h4_mph4_mansion_strm_0")
    RequestIpl("h4_nw_ipl_02_slod")
    RequestIpl("h4_mph4_airstrip")
    --RequestIpl("h4_mansion_gate_broken")
    RequestIpl("h4_island_padlock_props")
    RequestIpl("h4_islandairstrip_props_slod")
    RequestIpl("h4_nw_ipl_06")
    RequestIpl("h4_sw_ipl_09_lod")
    RequestIpl("h4_islandxcanal_props_lod")
    RequestIpl("h4_ne_ipl_05_slod")
    RequestIpl("h4_se_ipl_09_slod")
    RequestIpl("h4_islandx_mansion_vault_lod")
    RequestIpl("h4_se_ipl_03_slod")
    RequestIpl("h4_nw_ipl_08_lod")
    RequestIpl("h4_islandx_barrack_props_slod")
    RequestIpl("h4_islandxtower_veg_slod")
    RequestIpl("h4_sw_ipl_04")
    RequestIpl("h4_islandx_mansion_props")
    RequestIpl("h4_islandxtower_slod")
    RequestIpl("h4_beach_props")
    RequestIpl("h4_islandx_mansion_b_slod")
    RequestIpl("h4_islandx_maindock_props_slod")
    RequestIpl("h4_sw_ipl_07_slod")
    RequestIpl("h4_ne_ipl_07")
    RequestIpl("h4_islandxdock_props_2")
    RequestIpl("h4_ne_ipl_09_lod")
    RequestIpl("h4_islandxcanal_props")
    RequestIpl("h4_beach_slod")
    RequestIpl("h4_sw_ipl_00_slod")
    RequestIpl("h4_sw_ipl_03_lod")
    RequestIpl("h4_islandx_disc_strandedshark")
    RequestIpl("h4_islandx_disc_strandedshark_lod")
    RequestIpl("h4_islandx")
    RequestIpl("h4_islandx_props_lod")
    RequestIpl("h4_mph4_island_strm_0")
    RequestIpl("h4_islandx_sea_mines")
    RequestIpl("h4_mph4_island")
    RequestIpl("h4_boatblockers")
    RequestIpl("h4_mph4_island_long_0")
    RequestIpl("h4_islandx_disc_strandedwhale")
    RequestIpl("h4_islandx_disc_strandedwhale_lod")
    RequestIpl("h4_islandx_props")
    RequestIpl("h4_int_placement_h4_interior_1_dlc_int_02_h4_milo_")
    RequestIpl("h4_int_placement_h4_interior_0_int_sub_h4_milo_")
    RequestIpl("h4_int_placement_h4")
end)