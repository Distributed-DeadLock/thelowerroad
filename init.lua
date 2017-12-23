-- lowercrossroads -- by D.Lock
-- a minetest mod that adds a long road from -Z to +Z to the world, during world-generation.
-- dependencies : default stairs farming
-- ----------------------------------------------------------------------------
-- Config Section ---

-- the distance in chunks between roads, defining the gridsize
-- default: 3
local gridchunks = tonumber(minetest.setting_get("lowercrossroads.gridchunks")) or 3
--- defining the road wobble
-- the factor x-pos is divided by, before taking the sinus
-- values larger than the chunksize will stretch out the wobble
--  values smaller than chunksize produce varying results depending on the resonance with chunksize 
-- default: 62
local sinfactor = tonumber(minetest.setting_get("lowercrossroads.sinfactor")) or 62
-- the result of sin(x-pos / sinfactor) is multiplied by this
-- the bigger the value, the bigger the wobble
--  values bigger than (chunksize/2)-roadwith will break the mod. 20 is a safe value
-- default: 30
local sinspread = tonumber(minetest.setting_get("lowercrossroads.sinspread")) or 30
-- affects the rareness of house generation
-- setting this to 0 will create houses one the ground
-- larger values create houses only if the road is underground 
-- default: 5
local house_rareness = tonumber(minetest.setting_get("lowercrossroads.house_rareness")) or 0
-- if the trees are getting cleared out if the road is underground
-- if set to 1, all trees above the road will be removed
-- even if the road is currently underground
-- if set to 0, trees are only cleared if neccesary
local excessive_clearing = tonumber(minetest.setting_get("lowercrossroads.excessive_clearing")) or 0
-- road base elevation
-- in blocks above sea-level
local elevation_offset = (minetest.setting_get("lowercrossroads.roadelevation")) or 0
-- don't place on deep water
-- 1 to place --- 0 to not place
local water_roads = (minetest.setting_get("lowercrossroads.waterroads")) or 1

-- the material the road is build of
--- main material
local t1rb1 = { name = "default:silver_sandstone_brick", force_place = true, prob = 255 }
local t2rb1 = { name = "default:stonebrick", force_place = true, prob = 255 }
local t3rb1 = { name = "default:desert_sandstone_brick", force_place = true, prob = 255 }
local t4rb1 = { name = "default:desert_stonebrick", force_place = true, prob = 255 }
--- border
local t1rb2 = { name = "default:silver_sandstone_block", force_place = true, prob = 255 }
local t2rb2 = { name = "default:stone_block", force_place = true, prob = 255 }
local t3rb2 = { name = "default:desert_sandstone_block", force_place = true, prob = 255 }
local t4rb2 = { name = "default:desert_stone_block", force_place = true, prob = 255 }
--- road decoration
local t1rb3 = { name = "default:clay", force_place = true, prob = 6 }
local t2rb3 = { name = "default:cobble", force_place = true, prob = 6 }
local t3rb3 = { name = "default:dirt_with_dry_grass", force_place = true, prob = 6 }
local t4rb3 = { name = "default:desert_cobble", force_place = true, prob = 6 }
--- stairs
local t1nst = { name = "stairs:stair_silver_sandstone_brick", param2 = 2, force_place = true, prob = 255 }
local t1pst = { name = "stairs:stair_silver_sandstone_brick", force_place = true, prob = 255 }
local t2nst = { name = "stairs:stair_stonebrick", param2 = 2, force_place = true, prob = 255 }
local t2pst = { name = "stairs:stair_stonebrick", force_place = true, prob = 255 }
local t3nst = { name = "stairs:stair_desert_sandstone_brick", param2 = 2, force_place = true, prob = 255 }
local t3pst = { name = "stairs:stair_desert_sandstone_brick", force_place = true, prob = 255 }
local t4nst = { name = "stairs:stair_desert_stonebrick", param2 = 2, force_place = true, prob = 255 }
local t4pst = { name = "stairs:stair_desert_stonebrick", force_place = true, prob = 255 }
--- general deco
local rbcob = { name = "default:cobble", force_place = false, prob = 255 }
local rbtorch = { name = "default:torch", param2 = 1, force_place = true, prob = 49 }
local rbtorch2 = { name = "default:torch", param2 = 1, force_place = false, prob = 255 }
local rbtorch3 = { name = "default:torch", param2 = 1, force_place = true, prob = 255 }
local rbfence = { name = "default:fence_wood", force_place = true, prob = 13 }
local rbfence2 = { name = "default:fence_wood", force_place = false, prob = 255 }
local rbfence3 = { name = "default:fence_wood", force_place = true, prob = 255 }
--- placeholder. chest is placed directly on map
local rbchest = { name = "default:chest", force_place = true, prob = 255, param2 = 1 }
--- water deco
local rbwt1 = { name = "default:tree", param2 = 9, force_place = true, prob = 255 }

-- ---- Don't edit below here (unless you know what you are doing) ----
-- ----------------------------------------------------------------------------
-- node roadbuilders trophy - not craftable
-- a rare loot-object - rarely found in roadside buidlings
minetest.register_node("lowercrossroads:collectible_roadbuilder_trophy", {
	description = "The Lower Road - Roadbuilders Trophy - Collectible",
	is_ground_content = false,
	sunlight_propagates = true,
    groups = {cracky = 3, oddly_breakable_by_hand = 3, dig_immediate = 3},
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 3,
	tiles = {
		"default_stone.png"
	},
	drawtype = "nodebox",	
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.5, -0.4375, 0.4375, -0.4375, 0.4375}, -- NodeBox1
			{-0.375, -0.4375, -0.375, 0.375, -0.375, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.0625, -0.25, -0.125, 0.0625, 0.5, 0}, -- NodeBox4
			{-0.1875, 0.25, -0.125, 0.1875, 0.375, 0}, -- NodeBox5
			{0.1875, 0.125, -0.125, 0.3125, 0.25, 0}, -- NodeBox6
			{-0.3125, 0.125, -0.125, -0.1875, 0.25, 0}, -- NodeBox7
			{-0.375, -0.125, 0, 0.375, 0, 0.125}, -- NodeBox8
			{0.125, -0.1875, 0, 0.3125, 0.0625, 0.125}, -- NodeBox9
		}
	}
})

-- air that replaces other blocks, for tunneling
local ab1 = { name = "air", force_place = true, prob = 255 }
-- air that replaces nothing, used as "filler" to make non-cubic volumes
local ab2 = { name = "air", prob = 0 }

-- get the size of chunks to be generated at once by mapgen, stated in nodes
local chunksizeinnodes = minetest.setting_get("chunksize") * 16
-- set the base-level of the road (y-wise)
-- road will not go below this AND be only generated in the chunk containing this y-position
-- best be left at water_level
local road_base_elevation = minetest.setting_get("water_level") + elevation_offset
local waterlevel = minetest.setting_get("water_level")
-- the width of the road
local road_width = 5
-- the height of the road
local road_height = 6
-- limit sinspread to the max possible value
if (sinspread > (math.floor(chunksizeinnodes / 2) - road_width - 1 )) then
	sinspread = (math.floor(chunksizeinnodes / 2) - road_width - 1 )
	end
-- the allowed difference between heightlevel and roadlevel for houses to appear
local house_bbh = (1 - house_rareness)
-- limit house_bbh to "sane" values
if (house_bbh > 1) then
	house_bbh = 1
elseif (house_bbh < -10) then
	house_bbh = -10
end
-- air schematic for clearing stuff	
local air_schem = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 1,
		z = 1
	},
	data = {
		ab1
	}
}	

-- the road schematic, a one node long (z-wise) slice of the road 
-- one schematic for each "temperature zone"
-- road intersection-point
local t1_intersect = {
	yslice_prob = {
		
	},
	size = {
		y = 9,
		x = 9,
		z = 9
	}
,
	data = {
t1rb2, t1rb2, ab2, ab2, ab2, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab2, ab2, ab2, ab2, t1rb2, 
t1rb2, t1rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t1rb2, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, 
t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, 
ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab2, t1rb2, t1rb2, 
t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, 
t1rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t1rb2, t1rb2, 
t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, 
t1rb2, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, 
t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t1rb2, t1rb2, ab2, ab2, ab2, ab2, ab2, t1rb2, t1rb2, t1rb2, t1rb2, ab2, ab2, ab2, ab2, 
ab2, t1rb2, t1rb2, t1rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t1rb2, rbtorch3, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, 

}
}
local t2_intersect = {
	yslice_prob = {
		
	},
	size = {
		y = 9,
		x = 9,
		z = 9
	}
,
	data = {
t2rb2, t2rb2, ab2, ab2, ab2, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab2, ab2, ab2, ab2, t2rb2, 
t2rb2, t2rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t2rb2, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, 
t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, 
ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab2, t2rb2, t2rb2, 
t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, 
t2rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t2rb2, t2rb2, 
t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, 
t2rb2, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, 
t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t2rb2, t2rb2, ab2, ab2, ab2, ab2, ab2, t2rb2, t2rb2, t2rb2, t2rb2, ab2, ab2, ab2, ab2, 
ab2, t2rb2, t2rb2, t2rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t2rb2, rbtorch3, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, 

}
}
local t3_intersect = {
	yslice_prob = {
		
	},
	size = {
		y = 9,
		x = 9,
		z = 9
	}
,
	data = {
t3rb2, t3rb2, ab2, ab2, ab2, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab2, ab2, ab2, ab2, t3rb2, 
t3rb2, t3rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t3rb2, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, 
t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, 
ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab2, t3rb2, t3rb2, 
t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, 
t3rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t3rb2, t3rb2, 
t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, 
t3rb2, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, 
t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t3rb2, t3rb2, ab2, ab2, ab2, ab2, ab2, t3rb2, t3rb2, t3rb2, t3rb2, ab2, ab2, ab2, ab2, 
ab2, t3rb2, t3rb2, t3rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t3rb2, rbtorch3, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, 

}
}
local t4_intersect = {
	yslice_prob = {
		
	},
	size = {
		y = 9,
		x = 9,
		z = 9
	}
,
	data = {
t4rb2, t4rb2, ab2, ab2, ab2, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab2, ab2, ab2, ab2, t4rb2, 
t4rb2, t4rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t4rb2, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, 
t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, 
ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab2, t4rb2, t4rb2, 
t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, 
t4rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t4rb2, t4rb2, 
t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, 
t4rb2, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, 
t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab2, t4rb2, t4rb2, ab2, ab2, ab2, ab2, ab2, t4rb2, t4rb2, t4rb2, t4rb2, ab2, ab2, ab2, ab2, 
ab2, t4rb2, t4rb2, t4rb2, ab1, ab1, ab1, ab1, ab1, ab1, ab1, t4rb2, rbtorch3, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, rbtorch3, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab1, ab2, ab1, ab1, 
ab1, ab1, ab1, ab1, ab1, ab2, ab2, ab2, ab1, ab1, ab1, ab1, ab1, ab2, ab2, 

}
}
-- main road
local t1road_main = {
	yslice_prob = {		
	},
	size = {
		y = 8,
		x = 7,
		z = 1
	},
	data = {
		ab2, ab2, rbcob, rbcob, rbcob, ab2, ab2,
		t1rb2, rbcob, rbcob, rbcob, rbcob, rbcob, t1rb2,
		t1rb2, t1rb1, t1rb1, t1rb1, t1rb1, t1rb1, t1rb2,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab2, ab1, ab1, ab1, ab1, ab1, ab2,
	}
}
local t2road_main = {
	yslice_prob = {		
	},
	size = {
		y = 8,
		x = 7,
		z = 1
	},
	data = {
		ab2, ab2, rbcob, rbcob, rbcob, ab2, ab2,
		t2rb2, rbcob, rbcob, rbcob, rbcob, rbcob, t2rb2,
		t2rb2, t2rb1, t2rb1, t2rb1, t2rb1, t2rb1, t2rb2,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab2, ab1, ab1, ab1, ab1, ab1, ab2,
	}
}
local t3road_main = {
	yslice_prob = {		
	},
	size = {
		y = 8,
		x = 7,
		z = 1
	},
	data = {
		ab2, ab2, rbcob, rbcob, rbcob, ab2, ab2,
		t3rb2, rbcob, rbcob, rbcob, rbcob, rbcob, t3rb2,
		t3rb2, t3rb1, t3rb1, t3rb1, t3rb1, t3rb1, t3rb2,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab2, ab1, ab1, ab1, ab1, ab1, ab2,
	}
}
local t4road_main = {
	yslice_prob = {		
	},
	size = {
		y = 8,
		x = 7,
		z = 1
	},
	data = {
		ab2, ab2, rbcob, rbcob, rbcob, ab2, ab2,
		t4rb2, rbcob, rbcob, rbcob, rbcob, rbcob, t4rb2,
		t4rb2, t4rb1, t4rb1, t4rb1, t4rb1, t4rb1, t4rb2,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab1, ab1, ab1, ab1, ab1, ab1, ab1,
		ab2, ab1, ab1, ab1, ab1, ab1, ab2,
	}
}
-- road decoration
local t1road_deco = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 5,
		z = 1
	}
,
	data = {
		t1rb3, t1rb3, t1rb3, t1rb3, t1rb3,
	}
}
local t2road_deco = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 5,
		z = 1
	}
,
	data = {
		t2rb3, t2rb3, t2rb3, t2rb3, t2rb3,
	}
}
local t3road_deco = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 5,
		z = 1
	}
,
	data = {
		t3rb3, t3rb3, t3rb3, t3rb3, t3rb3,
	}
}
local t4road_deco = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 5,
		z = 1
	}
,
	data = {
		t4rb3, t4rb3, t4rb3, t4rb3, t4rb3,
	}
}
local road_water = {
	yslice_prob = {		
	},
	size = {
		y = 3,
		x = 7,
		z = 1
	}
,
	data = {
		rbwt1, ab2, ab2, ab2, ab2, ab2, rbwt1,
		rbwt1, ab2, ab2, ab2, ab2, ab2, rbwt1,
		rbfence, ab2, ab2, ab2, ab2, ab2, rbfence
	}
}

local road_light = {
	yslice_prob = {		
	},
	size = {
		y = 3,
		x = 1,
		z = 1
	},
	data = {
		rbfence2,
		rbfence2,
		rbtorch2
	}
}

-- stair 
local t1road_stairs_neg = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t1rb2, t1nst, t1nst, t1nst, t1nst, t1nst, t1rb2,
	}
}
local t1road_stairs_pos = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t1rb2, t1pst, t1pst, t1pst, t1pst, t1pst, t1rb2,
	}
}
local t2road_stairs_neg = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t2rb2, t2nst, t2nst, t2nst, t2nst, t2nst, t2rb2,
	}
}
local t2road_stairs_pos = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t2rb2, t2pst, t2pst, t2pst, t2pst, t2pst, t2rb2,
	}
}
local t3road_stairs_neg = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t3rb2, t3nst, t3nst, t3nst, t3nst, t3nst, t3rb2, 
	}
}
local t3road_stairs_pos = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t3rb2, t3pst, t3pst, t3pst, t3pst, t3pst, t3rb2, 
	}
}
local t4road_stairs_neg = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t4rb2, t4nst, t4nst, t4nst, t4nst, t4nst, t4rb2, 
	}
}
local t4road_stairs_pos = {
	yslice_prob = {		
	},
	size = {
		y = 1,
		x = 7,
		z = 1
	}
,
	data = {
		t4rb2, t4pst, t4pst, t4pst, t4pst, t4pst, t4rb2, 
	}
}
-- tunneling
local t1road_tunnel = {
	yslice_prob = {		
	},
	size = {
		y = 7,
		x = 7,
		z = 1
	},
	data = {
		t1rb2, ab2, ab2, ab2, ab2, ab2, t1rb2,
		t1rb2, ab2, ab2, ab2, ab2, ab2, t1rb2,
		t1rb2, ab2, ab2, ab2, ab2, ab2, t1rb2,
		t1rb1, ab2, ab2, ab2, ab2, ab2, t1rb1,
		t1rb1, ab2, ab2, ab2, ab2, ab2, t1rb1,
		t1rb1, t1rb1, ab2, ab2, ab2, t1rb1, t1rb1,
		ab2, t1rb1, t1rb1, t1rb2, t1rb1, t1rb1, ab2,
	}
}
local t2road_tunnel = {
	yslice_prob = {		
	},
	size = {
		y = 7,
		x = 7,
		z = 1
	},
	data = {
		t2rb2, ab2, ab2, ab2, ab2, ab2, t2rb2,
		t2rb2, ab2, ab2, ab2, ab2, ab2, t2rb2,
		t2rb2, ab2, ab2, ab2, ab2, ab2, t2rb2,
		t2rb1, ab2, ab2, ab2, ab2, ab2, t2rb1,
		t2rb1, ab2, ab2, ab2, ab2, ab2, t2rb1,
		t2rb1, t2rb1, ab2, ab2, ab2, t2rb1, t2rb1,
		ab2, t2rb1, t2rb1, t2rb2, t2rb1, t2rb1, ab2,
	}
}
local t3road_tunnel = {
	yslice_prob = {		
	},
	size = {
		y = 7,
		x = 7,
		z = 1
	},
	data = {
		t3rb2, ab2, ab2, ab2, ab2, ab2, t3rb2,
		t3rb2, ab2, ab2, ab2, ab2, ab2, t3rb2,
		t3rb2, ab2, ab2, ab2, ab2, ab2, t3rb2,
		t3rb1, ab2, ab2, ab2, ab2, ab2, t3rb1,
		t3rb1, ab2, ab2, ab2, ab2, ab2, t3rb1,
		t3rb1, t3rb1, ab2, ab2, ab2, t3rb1, t3rb1,
		ab2, t3rb1, t3rb1, t3rb2, t3rb1, t3rb1, ab2,
	}
}
local t4road_tunnel = {
	yslice_prob = {		
	},
	size = {
		y = 7,
		x = 7,
		z = 1
	},
	data = {
		t4rb2, ab2, ab2, ab2, ab2, ab2, t4rb2,
		t4rb2, ab2, ab2, ab2, ab2, ab2, t4rb2,
		t4rb2, ab2, ab2, ab2, ab2, ab2, t4rb2,
		t4rb1, ab2, ab2, ab2, ab2, ab2, t4rb1,
		t4rb1, ab2, ab2, ab2, ab2, ab2, t4rb1,
		t4rb1, t4rb1, ab2, ab2, ab2, t4rb1, t4rb1,
		ab2, t4rb1, t4rb1, t4rb2, t4rb1, t4rb1, ab2,
	}
}
local light_tunnel = {
	yslice_prob = {		
	},
	size = {
		y = 3,
		x = 7,
		z = 1
	},
	data = {
	rbfence, ab2, ab2, ab2, ab2, ab2, rbfence,
	rbfence, ab2, ab2, ab2, ab2, ab2, rbfence,
	rbtorch, ab2, ab2, ab2, ab2, ab2, rbtorch,	
	}
}
local support_tunnel = {
	yslice_prob = {		
	},
	size = {
		y = 4,
		x = 7,
		z = 1
	},
	data = {
	rbfence2, ab2, ab2, ab2, ab2, ab2, rbfence2,
	rbfence2, ab2, ab2, ab2, ab2, ab2, rbfence2,
	rbfence2, ab2, ab2, ab2, ab2, ab2, rbfence2,
	rbfence2, ab2, ab2, ab2, ab2, ab2, rbfence2,	
	}
}
-- small house
local t1road_house = {
	yslice_prob = {		
	},
	size = {
		y = 5,
		x = 6,
		z = 5
	},
	data = {
	ab2, t1rb2, t1rb1, t1rb1, t1rb1, t1rb2, ab2, t1rb2, t1rb1, t1rb1, t1rb1, t1rb2, ab2, t1rb2, t1rb1, rbfence3, t1rb1, 
	t1rb2, ab2, t1rb2, t1rb1, t1rb1, t1rb1, t1rb2, ab2, ab2, t1rb2, t1rb2, t1rb2, ab2, t1rb2, t1rb1, t1rb2, t1rb2, 
	t1rb2, t1rb1, t1rb2, t1rb1, ab1, ab1, ab1, t1rb1, t1rb2, t1rb1, ab1, ab1, ab1, t1rb1, t1rb2, t1rb1, ab1, 
	ab1, ab1, t1rb1, ab2, t1rb2, rbwt1, rbwt1, rbwt1, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb2, t1rb1, ab1, ab1, 
	ab1, ab1, rbchest, t1rb1, ab1, ab1, ab1, ab1, ab1, rbfence3, t1rb2, t1rb1, ab1, ab1, ab1, t1rb1, ab2, 
	t1rb2, rbwt1, rbwt1, rbwt1, t1rb2, t1rb2, t1rb1, t1rb2, t1rb2, t1rb2, t1rb1, t1rb2, t1rb1, rbfence3, ab1, ab1, t1rb1, 
	t1rb2, t1rb1, rbtorch3, ab1, ab1, t1rb1, t1rb2, t1rb1, ab1, ab1, ab1, t1rb1, ab2, t1rb2, rbwt1, rbwt1, rbwt1, 
	t1rb2, ab2, t1rb2, t1rb1, t1rb1, t1rb1, t1rb2, ab2, t1rb2, t1rb1, t1rb1, t1rb1, t1rb2, ab2, t1rb2, t1rb1, rbfence3, 
	t1rb1, t1rb2, ab2, t1rb2, t1rb1, t1rb1, t1rb1, t1rb2, ab2, ab2, t1rb2, t1rb2, t1rb2, ab2, 
	}
}
local t2road_house = {
	yslice_prob = {		
	},
	size = {
		y = 5,
		x = 6,
		z = 5
	},
	data = {
	ab2, t2rb2, t2rb1, t2rb1, t2rb1, t2rb2, ab2, t2rb2, t2rb1, t2rb1, t2rb1, t2rb2, ab2, t2rb2, t2rb1, rbfence3, t2rb1, 
	t2rb2, ab2, t2rb2, t2rb1, t2rb1, t2rb1, t2rb2, ab2, ab2, t2rb2, t2rb2, t2rb2, ab2, t2rb2, t2rb1, t2rb2, t2rb2, 
	t2rb2, t2rb1, t2rb2, t2rb1, ab1, ab1, ab1, t2rb1, t2rb2, t2rb1, ab1, ab1, ab1, t2rb1, t2rb2, t2rb1, ab1, 
	ab1, ab1, t2rb1, ab2, t2rb2, rbwt1, rbwt1, rbwt1, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb2, t2rb1, ab1, ab1, 
	ab1, ab1, rbchest, t2rb1, ab1, ab1, ab1, ab1, ab1, rbfence3, t2rb2, t2rb1, ab1, ab1, ab1, t2rb1, ab2, 
	t2rb2, rbwt1, rbwt1, rbwt1, t2rb2, t2rb2, t2rb1, t2rb2, t2rb2, t2rb2, t2rb1, t2rb2, t2rb1, rbfence3, ab1, ab1, t2rb1, 
	t2rb2, t2rb1, rbtorch3, ab1, ab1, t2rb1, t2rb2, t2rb1, ab1, ab1, ab1, t2rb1, ab2, t2rb2, rbwt1, rbwt1, rbwt1, 
	t2rb2, ab2, t2rb2, t2rb1, t2rb1, t2rb1, t2rb2, ab2, t2rb2, t2rb1, t2rb1, t2rb1, t2rb2, ab2, t2rb2, t2rb1, rbfence3, 
	t2rb1, t2rb2, ab2, t2rb2, t2rb1, t2rb1, t2rb1, t2rb2, ab2, ab2, t2rb2, t2rb2, t2rb2, ab2, 
	}
}
local t3road_house = {
	yslice_prob = {		
	},
	size = {
		y = 5,
		x = 6,
		z = 5
	},
	data = {
	ab2, t3rb2, t3rb1, t3rb1, t3rb1, t3rb2, ab2, t3rb2, t3rb1, t3rb1, t3rb1, t3rb2, ab2, t3rb2, t3rb1, rbfence3, t3rb1, 
	t3rb2, ab2, t3rb2, t3rb1, t3rb1, t3rb1, t3rb2, ab2, ab2, t3rb2, t3rb2, t3rb2, ab2, t3rb2, t3rb1, t3rb2, t3rb2, 
	t3rb2, t3rb1, t3rb2, t3rb1, ab1, ab1, ab1, t3rb1, t3rb2, t3rb1, ab1, ab1, ab1, t3rb1, t3rb2, t3rb1, ab1, 
	ab1, ab1, t3rb1, ab2, t3rb2, rbwt1, rbwt1, rbwt1, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb2, t3rb1, ab1, ab1, 
	ab1, ab1, rbchest, t3rb1, ab1, ab1, ab1, ab1, ab1, rbfence3, t3rb2, t3rb1, ab1, ab1, ab1, t3rb1, ab2, 
	t3rb2, rbwt1, rbwt1, rbwt1, t3rb2, t3rb2, t3rb1, t3rb2, t3rb2, t3rb2, t3rb1, t3rb2, t3rb1, rbfence3, ab1, ab1, t3rb1, 
	t3rb2, t3rb1, rbtorch3, ab1, ab1, t3rb1, t3rb2, t3rb1, ab1, ab1, ab1, t3rb1, ab2, t3rb2, rbwt1, rbwt1, rbwt1, 
	t3rb2, ab2, t3rb2, t3rb1, t3rb1, t3rb1, t3rb2, ab2, t3rb2, t3rb1, t3rb1, t3rb1, t3rb2, ab2, t3rb2, t3rb1, rbfence3, 
	t3rb1, t3rb2, ab2, t3rb2, t3rb1, t3rb1, t3rb1, t3rb2, ab2, ab2, t3rb2, t3rb2, t3rb2, ab2, 
	}
}
local t4road_house = {
	yslice_prob = {		
	},
	size = {
		y = 5,
		x = 6,
		z = 5
	},
	data = {
	ab2, t4rb2, t4rb1, t4rb1, t4rb1, t4rb2, ab2, t4rb2, t4rb1, t4rb1, t4rb1, t4rb2, ab2, t4rb2, t4rb1, rbfence3, t4rb1, 
	t4rb2, ab2, t4rb2, t4rb1, t4rb1, t4rb1, t4rb2, ab2, ab2, t4rb2, t4rb2, t4rb2, ab2, t4rb2, t4rb1, t4rb2, t4rb2, 
	t4rb2, t4rb1, t4rb2, t4rb1, ab1, ab1, ab1, t4rb1, t4rb2, t4rb1, ab1, ab1, ab1, t4rb1, t4rb2, t4rb1, ab1, 
	ab1, ab1, t4rb1, ab2, t4rb2, rbwt1, rbwt1, rbwt1, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb2, t4rb1, ab1, ab1, 
	ab1, ab1, rbchest, t4rb1, ab1, ab1, ab1, ab1, ab1, rbfence3, t4rb2, t4rb1, ab1, ab1, ab1, t4rb1, ab2, 
	t4rb2, rbwt1, rbwt1, rbwt1, t4rb2, t4rb2, t4rb1, t4rb2, t4rb2, t4rb2, t4rb1, t4rb2, t4rb1, rbfence3, ab1, ab1, t4rb1, 
	t4rb2, t4rb1, rbtorch3, ab1, ab1, t4rb1, t4rb2, t4rb1, ab1, ab1, ab1, t4rb1, ab2, t4rb2, rbwt1, rbwt1, rbwt1, 
	t4rb2, ab2, t4rb2, t4rb1, t4rb1, t4rb1, t4rb2, ab2, t4rb2, t4rb1, t4rb1, t4rb1, t4rb2, ab2, t4rb2, t4rb1, rbfence3, 
	t4rb1, t4rb2, ab2, t4rb2, t4rb1, t4rb1, t4rb1, t4rb2, ab2, ab2, t4rb2, t4rb2, t4rb2, ab2, 
	}
}

-- -- road building functions


function makeroadZ(minp, maxp, seed)
	-- set the base x-position of the road to be in the center of the chunk
	-- the road will "wiggle" around this value 
	local centerx = minp.x + math.floor(chunksizeinnodes / 2)
	-- set the start- and end-point (x-wise) of the road for this chunk
	local startx = centerx + (math.floor(sinspread * math.sin(minp.z/sinfactor)))
	local endx = centerx + (math.floor(sinspread * math.sin(maxp.z/sinfactor)))
	-- preferred direction of the road-shifting : 1(to neg x) or -1(to pos x)
	local pref_dir_x = (math.max(startx - endx, 1)) / (math.abs(math.max(startx - endx, 1)))
	-- set the maximum elevation for the road
	local maxy = maxp.y - road_height

	-- get the voxel manipulation object for the chunk
	local voxman_o = minetest.get_mapgen_object("voxelmanip")
	-- get the heightmap object for the chunk
	local hmap = minetest.get_mapgen_object("heightmap")
	-- get the heatmap object for the chunk
	local heatmap = minetest.get_mapgen_object("heatmap")
	-- if no heatmap is provided use the heightmap as heatmap ;-)
	if (heatmap == nil) then
		heatmap = minetest.get_mapgen_object("heightmap")
	end
	
	-- reseed the random function
	math.randomseed(seed)
	-- init some vars for position calculation
	local x, hm_i, y , prev_x, prev_y, preprev_y, test_x, test_y, slices_left, match_i, match_o, match_s, d_i, d_o, d_s, rtype
	-- will hold list of blocks to be cleared after road construction during tree/plant removal
	local clearlist
	-- related to house placement
	local hashouse = 0 
	local isstairs = 0
	local housex, housey, housez, schem_house
	-- repeat for ever z-value stating with the lowest
	for z = minp.z, maxp.z do
		match_i = false
		match_o = false
		match_s = false
		d_i = chunksizeinnodes
		d_o = chunksizeinnodes
		d_s = chunksizeinnodes
		slices_left = maxp.z - z
		-- set first slices pos to be at base elevation and startx
		if (z == minp.z) then
			x = startx
			y = road_base_elevation
			prev_x = x
			prev_y = y
			preprev_y = y
			rtype = 3
		else
		
		-- check for valid placement position
		
			-- test straight foreward
			test_x = prev_x
			-- get height at current test position
			hm_i = (test_x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
			-- don't go lower than waterlevel
			test_y = math.max(hmap[hm_i], waterlevel)
				
			-- if straight foreward is a x-pos that can reach endx and 
			--  can reach road_base_elevation and
			--  height is flat or only 1 node difference and
			--  height does not exceed the height-limit
			if (math.abs(test_x - endx) < (slices_left / road_width)) and
				(math.abs(test_y - road_base_elevation) < slices_left) and
				(math.abs(test_y - prev_y) < 2) and
				(test_y < maxy) then
				match_s = true
				-- get distance to ideal sin-line
				d_s = math.abs((centerx + math.floor(sinspread * math.sin(z/sinfactor))) - test_x)
			end
			
			-- test "outward" position
			test_x = prev_x + pref_dir_x
			-- get height at current test position
			hm_i = (test_x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
			-- don't go lower than waterlevel
			test_y = math.max(hmap[hm_i], waterlevel)
			-- test again for x-pos one node "outward"
			if (math.abs(test_x - endx) < (slices_left / road_width)) and
				(math.abs(test_y - road_base_elevation) < slices_left) and
				(math.abs(test_y - prev_y) < 2) and
				(test_y < maxy) then
				match_o = true
				-- get distance to ideal sin-line
				d_o = math.abs((centerx + math.floor(sinspread * math.sin(z/sinfactor))) - test_x)
			end
			
			-- test "inward" position
			test_x = prev_x - pref_dir_x
			-- get height at current test position
			hm_i = (test_x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
			-- don't go lower than waterlevel
			test_y = math.max(hmap[hm_i], waterlevel)
			-- test again for x-pos one node "inward"
			if (math.abs(test_x - endx) < (slices_left / road_width)) and
				(math.abs(test_y - road_base_elevation) < slices_left) and
				(math.abs(test_y - prev_y) < 2) and
				(test_y < maxy) then
				match_i = true
				-- get distance to ideal sin-line
				d_i = math.abs((centerx + math.floor(sinspread * math.sin(z/sinfactor))) - test_x)
			end
			
			-- if at least on valid position was found
			if match_s or match_i or match_o then
			
				-- if straight forward is closest to ideal sin-line
				if match_s and (d_s < d_o) and (d_s < d_i) then
					x = prev_x
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					y = math.max(hmap[hm_i], waterlevel)
				end
				
				-- if "outwards" is closest to ideal sin-line
				if match_o and (d_o < d_s) and (d_o < d_i) then
					x = prev_x + pref_dir_x
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					y = math.max(hmap[hm_i], waterlevel)
				end
				
					-- if "inwards" is closest to ideal sin-line
				if match_i and (d_i < d_s) and (d_i < d_s) then
					x = prev_x - pref_dir_x
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					y = math.max(hmap[hm_i], waterlevel)
				end
				rtype = 1
			else
			-- no valid pos on surface found, tunneling/bridging instead
			
				-- set x-pos as close as possible to ideal sin-line
				if ( prev_x == (centerx + math.floor(sinspread * math.sin(z/sinfactor))) ) then	
					x = prev_x
				elseif ( prev_x > (centerx + math.floor(sinspread * math.sin(z/sinfactor))) ) then
					x = prev_x - 1
				else
					x = prev_x + 1
				end
				
				-- set y-pos
				-- if road is above ground, lower it
				hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				if (((prev_y > hmap[hm_i]) or 
				( minetest.get_node({x=x,y=prev_y,z=z}).name == "air" )) and
				 (math.abs(prev_y - road_base_elevation) < (slices_left + 1))) then 
					y = prev_y - 1
				else 
				
					-- else set to closest to elevation-sin-line
					test_y = math.floor(math.sin(math.pi * ( (z - minp.z) / chunksizeinnodes ) ) * ((maxy - road_base_elevation) / 2)) + road_base_elevation
					if ( prev_y == test_y) then
						y = prev_y
					elseif (prev_y > test_y) then
						y = prev_y - 1
					else
						y = prev_y + 1
					end
				end
				-- make shure y is not below waterlevel
				y = math.max(y, waterlevel)	
				rtype = 2
			end
			
		end	

		-- don't build on water, if not allowed
		if ((water_roads == 1) or 
			((minetest.get_node({x=x,y=(waterlevel),z=z}).name ~= "default:water_source") or
			(minetest.get_node({x=x,y=(waterlevel),z=math.min((z+1),maxp.z)}).name ~= ("default:water_source" or "ignore")))) then
			-- get heat at current pos
			hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
			local lheat = heatmap[hm_i]
			local schem_main, schem_stair_neg, schem_stair_pos, schem_tunnel, schem_road_deco
			-- assign matrials depending on temperature
			if (lheat < 20 ) then
				schem_main = t1road_main
				schem_stair_neg = t1road_stairs_neg
				schem_stair_pos = t1road_stairs_pos
				schem_tunnel = t1road_tunnel
				schem_road_deco = t1road_deco
				schem_house = t1road_house
			elseif (lheat < 50 ) then
				schem_main = t2road_main
				schem_stair_neg = t2road_stairs_neg
				schem_stair_pos = t2road_stairs_pos
				schem_tunnel = t2road_tunnel
				schem_road_deco = t2road_deco
				schem_house = t2road_house
			elseif (lheat < 80 ) then
				schem_main = t3road_main
				schem_stair_neg = t3road_stairs_neg
				schem_stair_pos = t3road_stairs_pos
				schem_tunnel = t3road_tunnel
				schem_road_deco = t3road_deco
				schem_house = t3road_house
			else
				schem_main = t4road_main
				schem_stair_neg = t4road_stairs_neg
				schem_stair_pos = t4road_stairs_pos
				schem_tunnel = t4road_tunnel
				schem_road_deco = t4road_deco
				schem_house = t4road_house
			end

			-- place main road segment

			minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y - 2), z = z }, schem_main, 0, nil, true)
			minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2)) , y = y, z = z }, schem_road_deco, 0, nil, true)

			
			-- straighten out small height-wobble 
			-- if roadheight of this is the same as two slices before, but not the same as previous slice
			if (y == preprev_y) and
			  (y ~= prev_y) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y - 2), z = (z - 1) }, schem_main, 0, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1), z = (z - 1) }, support_tunnel, 0, nil, true)
				prev_y = y
			end
			
			
			-- Replace trees/plants and snow with air
			-- if road is not below surface or excessive_clearing is turned on
			if ( ((y - hmap[hm_i]) > -8) or (excessive_clearing == 1) ) then
				clearlist = minetest.find_nodes_in_area({x = (x - math.floor(road_width/2) - 1), y = (y + 1), z = z },
				{x = (x + math.floor(road_width/2) + 1) , y = maxp.y, z = z },
				{"group:tree", "group:leaves", "group:leafdecay", "group:leafdecay_drop", "group:plant", "group:flora", 
				 "group:sapling", "default:snow", "default:snowblock", "default:cactus"})
				for _ , clnode in pairs(clearlist) do
					minetest.place_schematic_on_vmanip(voxman_o, clnode, air_schem, 0, nil, true)
				end
			end

			-- place stairs if road is uneven
			isstairs = 0
			if (prev_y < y) then
				isstairs = 1
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = y, z = z }, schem_stair_pos, 0, nil, true)
			end
			if (prev_y > y) then
				isstairs = 1
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1), z = z }, schem_stair_neg, 0, nil, true)
			end
			
			-- place tunnel if is underground
			if ( (y - hmap[hm_i]) < -5) and
			  ( minetest.get_node({x = x, y = (y + 6), z = z}).name ~= "air" ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = y , z = z }, schem_tunnel, 0, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1) , z = z }, light_tunnel, 0, nil, true)
			end

			-- place deco if on water
			if ( minetest.get_node({x = x, y = y, z = z}).name == "default:water_source" ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y - 1), z = z }, road_water, 0, nil, true)
			end
			
			-- place street light
			if ( math.random(1, 80) > 78 ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1), z = z }, road_light, 0, nil, true)
			end
			
			-- place roadside house
			if ( (slices_left == 3) and ((y - hmap[hm_i]) < house_bbh) and 
			  (prev_x <= x) and ( isstairs == 0) and
			  (hmap[((x - minp.x + 5) + (((z - minp.z)) * chunksizeinnodes))] - y) > -1)then
				hashouse = 1
				housex = (x + math.floor(road_width/2) + 1)
				housey = (y)
				housez = (z - 2)
				minetest.place_schematic_on_vmanip(voxman_o, { x = housex , y = housey , z = housez }, schem_house, 0, nil, true)
			end
		end
		prev_x = x
		preprev_y = prev_y
		prev_y = y
	end
	-- put voxel manipulator object on map
	voxman_o:calc_lighting()
	voxman_o:write_to_map()
	-- check for house and update/fill chest
	if (hashouse == 1) then
		minetest.place_schematic({ x = housex , y = housey , z = housez }, schem_house, 0, nil, true)
		minetest.set_node({x = (housex + 4), y = ( housey + 1), z = (housez + 2)}, rbchest)
		local chestinv = minetest.get_inventory({type="node", pos={x = (housex + 4), y = ( housey + 1), z = (housez + 2)}})
		-- put in some loot
		local stack = ItemStack("farming:bread " .. math.random(1, 11))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:torch " .. math.random(1, 7))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:wood " .. math.random(0, 9))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:pick_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:iron_lump " .. math.random(0, 4))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:axe_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:shovel_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:sword_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		if (math.random(0,50) == 1) then
			stack = ItemStack("lowercrossroads:collectible_roadbuilder_trophy 1")
			chestinv:add_item("main", stack)
			print(os.date() .. " : [theloweroad]: collectible placed at: x:" .. (housex + 4) .. " y:" .. (housey + 1) .. " z:" .. (housez + 2) )
		end
		
	end
end	

function makeroadX(minp, maxp, seed)
	-- set the base z-position of the road to be in the center of the chunk
	-- the road will "wiggle" around this value 
	local centerz = minp.z + math.floor(chunksizeinnodes / 2)
	-- set the start- and end-point (z-wise) of the road for this chunk
	local startz = centerz + (math.floor(sinspread * math.sin(minp.x/sinfactor)))
	local endz = centerz + (math.floor(sinspread * math.sin(maxp.x/sinfactor)))
	-- preferred direction of the road-shifting : 1(to neg z) or -1(to pos z)
	local pref_dir_z = (math.max(startz - endz, 1)) / (math.abs(math.max(startz - endz, 1)))
	-- set the maximum elevation for the road
	local maxy = maxp.y - road_height

	-- get the voxel manipulation object for the chunk
	local voxman_o = minetest.get_mapgen_object("voxelmanip")
	-- get the heightmap object for the chunk
	local hmap = minetest.get_mapgen_object("heightmap")
	-- get the heatmap object for the chunk
	local heatmap = minetest.get_mapgen_object("heatmap")
	-- if no heatmap is provided use the heightmap as heatmap ;-)
	if (heatmap == nil) then
		heatmap = minetest.get_mapgen_object("heightmap")
	end
	
	-- reseed the random function
	math.randomseed(seed)
	-- init some vars for position calculation
	local z, hm_i, y , prev_z, prev_y, preprev_y, test_z, test_y, slices_left, match_i, match_o, match_s, d_i, d_o, d_s, rtype
	-- will hold list of blocks to be cleared after road construction during tree/plant removal
	local clearlist
	-- related to house placement
	local hashouse = 0 
	local isstairs = 0
	local housez, housey, housex, schem_house
	-- repeat for every x-value stating with the lowest
	for x = minp.x, maxp.x do
		match_i = false
		match_o = false
		match_s = false
		d_i = chunksizeinnodes
		d_o = chunksizeinnodes
		d_s = chunksizeinnodes
		slices_left = maxp.x - x
		-- set first slices pos to be at base elevation and startz
		if (x == minp.x) then
			z = startz
			y = road_base_elevation
			prev_z = z
			prev_y = y
			preprev_y = y
			rtype = 3
		else
		
		-- check for valid placement position
		
			-- test straight foreward
			test_z = prev_z
			-- get height at current test position
			hm_i = (x - minp.x + 1) + (((test_z - minp.z)) * chunksizeinnodes)
			-- don't go lower than waterlevel
			test_y = math.max(hmap[hm_i], waterlevel)
				
			-- if straight foreward is a z-pos that can reach endz and 
			--  can reach road_base_elevation and
			--  height is flat or only 1 node difference and
			--  height does not exceed the height-limit
			if (math.abs(test_z - endz) < (slices_left / road_width)) and
				(math.abs(test_y - road_base_elevation) < slices_left) and
				(math.abs(test_y - prev_y) < 2) and
				(test_y < maxy) then
				match_s = true
				-- get distance to ideal sin-line
				d_s = math.abs((centerz + math.floor(sinspread * math.sin(x/sinfactor))) - test_z)
			end
			
			-- test "outward" position
			test_z = prev_z + pref_dir_z
			-- get height at current test position
			hm_i = (x - minp.x + 1) + (((test_z - minp.z)) * chunksizeinnodes)
			-- don't go lower than waterlevel
			test_y = math.max(hmap[hm_i], waterlevel)
			-- test again for z-pos one node "outward"
			if (math.abs(test_z - endz) < (slices_left / road_width)) and
				(math.abs(test_y - road_base_elevation) < slices_left) and
				(math.abs(test_y - prev_y) < 2) and
				(test_y < maxy) then
				match_o = true
				-- get distance to ideal sin-line
				d_o = math.abs((centerz + math.floor(sinspread * math.sin(x/sinfactor))) - test_z)
			end
			
			-- test "inward" position
			test_z = prev_z - pref_dir_z
			-- get height at current test position
			hm_i = (x - minp.x + 1) + (((test_z - minp.z)) * chunksizeinnodes)
			-- don't go lower than waterlevel
			test_y = math.max(hmap[hm_i], waterlevel)
			-- test again for z-pos one node "inward"
			if (math.abs(test_z - endz) < (slices_left / road_width)) and
				(math.abs(test_y - road_base_elevation) < slices_left) and
				(math.abs(test_y - prev_y) < 2) and
				(test_y < maxy) then
				match_i = true
				-- get distance to ideal sin-line
				d_i = math.abs((centerz + math.floor(sinspread * math.sin(x/sinfactor))) - test_z)
			end
			
			-- if at least on valid position was found
			if match_s or match_i or match_o then
			
				-- if straight forward is closest to ideal sin-line
				if match_s and (d_s < d_o) and (d_s < d_i) then
					z = prev_z
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					y = math.max(hmap[hm_i], waterlevel)
				end
				
				-- if "outwards" is closest to ideal sin-line
				if match_o and (d_o < d_s) and (d_o < d_i) then
					z = prev_z + pref_dir_z
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					y = math.max(hmap[hm_i], waterlevel)
				end
				
					-- if "inwards" is closest to ideal sin-line
				if match_i and (d_i < d_s) and (d_i < d_s) then
					z = prev_z - pref_dir_z
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					y = math.max(hmap[hm_i], waterlevel)
				end
				rtype = 1
			else
			-- no valid pos on surface found, tunneling/bridging instead
			
				-- set z-pos as close as possible to ideal sin-line
				if ( prev_z == (centerz + math.floor(sinspread * math.sin(x/sinfactor))) ) then	
					z = prev_z
				elseif ( prev_z > (centerz + math.floor(sinspread * math.sin(x/sinfactor))) ) then
					z = prev_z - 1
				else
					z = prev_z + 1
				end
				
				-- set y-pos
				-- if road is above ground, lower it
				hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				if (((prev_y > hmap[hm_i]) or 
				( minetest.get_node({x=x,y=prev_y,z=z}).name == "air" )) and
				 (math.abs(prev_y - road_base_elevation) < (slices_left + 1))) then 
					y = prev_y - 1
				else 
				
					-- else set to closest to elevation-sin-line
					test_y = math.floor(math.sin(math.pi * ( (x - minp.x) / chunksizeinnodes ) ) * ((maxy - road_base_elevation) / 2)) + road_base_elevation
					if ( prev_y == test_y) then
						y = prev_y
					elseif (prev_y > test_y) then
						y = prev_y - 1
					else
						y = prev_y + 1
					end
				end
				-- make shure y is not below waterlevel
				y = math.max(y, waterlevel)	
				rtype = 2
			end
			
		end	

		-- don't build on water, if not allowed
		if ((water_roads == 1) or 
			((minetest.get_node({x=x,y=(waterlevel),z=z}).name ~= "default:water_source") or
			(minetest.get_node({x=math.min((x+1),maxp.x),y=(waterlevel),z=z}).name ~= ("default:water_source" or "ignore")))) then
			-- get heat at current pos
			hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
			local lheat = heatmap[hm_i]
			local schem_main, schem_stair_neg, schem_stair_pos, schem_tunnel, schem_road_deco
			-- assign matrials depending on temperature
			if (lheat < 20 ) then
				schem_main = t1road_main
				schem_stair_neg = t1road_stairs_neg
				schem_stair_pos = t1road_stairs_pos
				schem_tunnel = t1road_tunnel
				schem_road_deco = t1road_deco
				schem_house = t1road_house
			elseif (lheat < 50 ) then
				schem_main = t2road_main
				schem_stair_neg = t2road_stairs_neg
				schem_stair_pos = t2road_stairs_pos
				schem_tunnel = t2road_tunnel
				schem_road_deco = t2road_deco
				schem_house = t2road_house
			elseif (lheat < 80 ) then
				schem_main = t3road_main
				schem_stair_neg = t3road_stairs_neg
				schem_stair_pos = t3road_stairs_pos
				schem_tunnel = t3road_tunnel
				schem_road_deco = t3road_deco
				schem_house = t3road_house
			else
				schem_main = t4road_main
				schem_stair_neg = t4road_stairs_neg
				schem_stair_pos = t4road_stairs_pos
				schem_tunnel = t4road_tunnel
				schem_road_deco = t4road_deco
				schem_house = t4road_house
			end

			-- place main road segment

			minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y - 2), z = (z - math.floor(road_width/2) - 1) }, schem_main, 90, nil, true)
			minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = y, z = (z - math.floor(road_width/2)) }, schem_road_deco, 90, nil, true)

			
			-- straighten out small height-wobble 
			-- if roadheight of this is the same as two slices before, but not the same as previous slice
			if (y == preprev_y) and
			  (y ~= prev_y) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - 1) , y = (y - 2), z = (z - math.floor(road_width/2) - 1) }, schem_main, 90, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - 1) , y = (y + 1), z = (z - math.floor(road_width/2) - 1) }, support_tunnel, 90, nil, true)
				prev_y = y
			end
			
			
			-- Replace trees/plants and snow with air
			-- if road is not below surface or excessive_clearing is turned on
			if ( ((y - hmap[hm_i]) > -8) or (excessive_clearing == 1) ) then
				clearlist = minetest.find_nodes_in_area({x = x, y = (y + 1), z = (z - math.floor(road_width/2) - 1) },
				{x = x , y = maxp.y, z = (z + math.floor(road_width/2) + 1) },
				{"group:tree", "group:leaves", "group:leafdecay", "group:leafdecay_drop", "group:plant", "group:flora", 
				 "group:sapling", "default:snow", "default:snowblock", "default:cactus"})
				for _ , clnode in pairs(clearlist) do
					minetest.place_schematic_on_vmanip(voxman_o, clnode, air_schem, 90, nil, true)
				end
			end

			-- place stairs if road is uneven
			isstairs = 0
			if (prev_y < y) then
				isstairs = 1
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = y, z = (z - math.floor(road_width/2) - 1) }, schem_stair_pos, 90, nil, true)
			end
			if (prev_y > y) then
				isstairs = 1
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y + 1), z = (z - math.floor(road_width/2) - 1) }, schem_stair_neg, 90, nil, true)
			end
			
			-- place tunnel if is underground
			if ( (y - hmap[hm_i]) < -5) and
			  ( minetest.get_node({x = x, y = (y + 6), z = z}).name ~= "air" ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = y , z = (z - math.floor(road_width/2) - 1) }, schem_tunnel, 90, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y + 1) , z = (z - math.floor(road_width/2) - 1) }, light_tunnel, 90, nil, true)
			end

			-- place deco if on water
			if ( minetest.get_node({x = x, y = y, z = z}).name == "default:water_source" ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y - 1), z = (z - math.floor(road_width/2) - 1) }, road_water, 90, nil, true)
			end
			
			-- place street light
			if ( math.random(1, 80) > 78 ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y + 1), z = (z - math.floor(road_width/2) - 1) }, road_light, 90, nil, true)
			end
			
			-- place roadside house
			if ( (slices_left == 3) and ((y - hmap[hm_i]) < house_bbh) and 
			  (prev_z <= z) and ( isstairs == 0) and
			  (hmap[((x - minp.x) + (((z - minp.z + 5)) * chunksizeinnodes))] - y) > -1)then
				hashouse = 1
				housex = (x - 2)
				housey = (y)
				housez = (z + math.floor(road_width/2) + 1)
				minetest.place_schematic_on_vmanip(voxman_o, { x = housex , y = housey , z = housez }, schem_house, 270, nil, true)
			end
		end
		
		prev_z = z
		preprev_y = prev_y
		prev_y = y
	end
	-- put voxel manipulator object on map
	voxman_o:calc_lighting()
	voxman_o:write_to_map()
	-- check for house and update/fill chest
	if (hashouse == 1) then
		minetest.place_schematic({ x = housex , y = housey , z = housez }, schem_house, 270, nil, true)
		minetest.set_node({x = (housex + 2), y = ( housey + 1), z = (housez + 4)}, rbchest)
		local chestinv = minetest.get_inventory({type="node", pos={x = (housex + 2), y = ( housey + 1), z = (housez + 4)}})
		-- put in some loot
		local stack = ItemStack("farming:bread " .. math.random(1, 11))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:torch " .. math.random(1, 7))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:wood " .. math.random(0, 9))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:pick_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:iron_lump " .. math.random(0, 4))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:axe_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:shovel_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		stack = ItemStack("default:sword_stone " .. math.random(0, 1))
		chestinv:add_item("main", stack)
		if (math.random(0,50) == 1) then
			stack = ItemStack("lowercrossroads:collectible_roadbuilder_trophy 1")
			chestinv:add_item("main", stack)
			print(os.date() .. " : [theloweroad]: collectible placed at: x:" .. (housex + 2) .. " y:" .. (housey + 1) .. " z:" .. (housez + 4) )
		end
		
	end
end	

function makeroadcross(minp, maxp, seed)
	-- set the base x-position of the road to be in the center of the chunk
	-- the road will "wiggle" around this value 
	local centerx = minp.x + math.floor(chunksizeinnodes / 2)
	-- set the start- and end-point (x-wise) of the road for this chunk
	local cstartx = centerx + (math.floor(sinspread * math.sin(minp.z/sinfactor)))
	local cendx = centerx + (math.floor(sinspread * math.sin(maxp.z/sinfactor)))
	-- preferred direction of the road-shifting : 1(to neg x) or -1(to pos x)
	local pref_dir_x = (math.max(cstartx - cendx, 1)) / (math.abs(math.max(cstartx - cendx, 1)))
	
	-- set the base z-position of the road to be in the center of the chunk
	-- the road will "wiggle" around this value 
	local centerz = minp.z + math.floor(chunksizeinnodes / 2)
	-- set the start- and end-point (z-wise) of the road for this chunk
	local cstartz = centerz + (math.floor(sinspread * math.sin(minp.x/sinfactor)))
	local cendz = centerz + (math.floor(sinspread * math.sin(maxp.x/sinfactor)))
	-- preferred direction of the road-shifting : 1(to neg z) or -1(to pos z)
	local pref_dir_z = (math.max(cstartz - cendz, 1)) / (math.abs(math.max(cstartz - cendz, 1)))
	
	-- set the maximum elevation for the road
	local maxy = maxp.y - road_height
	
	-- calc intersection-point x an z for the two roads
	--local intersectx = math.floor(cstartx -((cstartx - cendx) / 2))
	--local intersectz = math.floor(cstartz -((cstartz - cendz) / 2))
	--local intersectx = centerx
	--local intersectz = centerz
	local intersectx = math.floor((centerx + cstartx + cendx) / 3)
	local intersectz = math.floor((centerz + cstartz + cendz) / 3)
	
	-- get the voxel manipulation object for the chunk
	local voxman_o = minetest.get_mapgen_object("voxelmanip")
	-- get the heightmap object for the chunk
	local hmap = minetest.get_mapgen_object("heightmap")
	-- get the heatmap object for the chunk
	local heatmap = minetest.get_mapgen_object("heatmap")
	-- if no heatmap is provided use the heightmap as heatmap ;-)
	if (heatmap == nil) then
		heatmap = minetest.get_mapgen_object("heightmap")
	end
	
	
	-- reseed the random function
	math.randomseed(seed)
	-- init some vars for position calculation
	local x, hm_i, y , prev_x, prev_y, preprev_y, test_x, test_y, slices_left, match_i, match_o, match_s, d_i, d_o, d_s, rtype
	local z, prev_z, test_z
	
	-- will hold list of blocks to be cleared after road construction during tree/plant removal
	local clearlist
	
	local hashouse = 0 
	local isstairs = 0
	
	-- calc intersection-point y for the two roads
	-- get height at intersect position
	hm_i = (intersectx - minp.x + 1) + (((intersectz - minp.z)) * chunksizeinnodes)
	test_y = math.max(hmap[hm_i], waterlevel)
	local intersecty
	local heightoffset = math.min((intersectx - minp.x),(maxp.x - intersectx),(intersectz - minp.z),(maxp.z - intersectz))
	if ((test_y <= maxy) and (test_y < (heightoffset + road_base_elevation - 3))) then
		intersecty = test_y
	else
		intersecty = road_base_elevation + math.floor(heightoffset / 2)
	end
	
		-- get heat at intersect pos
		hm_i = (intersectx - minp.x + 1) + (((intersectz - minp.z)) * chunksizeinnodes)
		local lheat = heatmap[hm_i]
		local schem_intersect
		-- assign matrials depending on temperature
		if (lheat < 20 ) then
			schem_intersect = t1_intersect
		elseif (lheat < 50 ) then
			schem_intersect = t2_intersect
		elseif (lheat < 80 ) then
			schem_intersect = t3_intersect
		else
			schem_intersect = t4_intersect
		end
	--place intersection
	-- don't build on water, if not allowed
	if ((water_roads == 1) or
		((minetest.get_node({x=(intersectx - 3),y=(waterlevel),z=intersectz}).name ~= "default:water_source") or
		(minetest.get_node({x=(intersectx + 3),y=(waterlevel),z=intersectz}).name ~= "default:water_source") or
		(minetest.get_node({x=intersectx,y=(waterlevel),z=(intersectz - 3)}).name ~= "default:water_source") or
		(minetest.get_node({x=intersectx,y=(waterlevel),z=(intersectz + 3)}).name ~= "default:water_source"))) then
		minetest.place_schematic_on_vmanip(voxman_o,{ x = (intersectx - math.floor(road_width/2) - 2) , y = (intersecty - 1) , z = (intersectz - math.floor(road_width/2) - 2) }, schem_intersect, 0, nil, true)
	end
	
	
	-- do the z-road
	for a = 1, 2 do
		local startx, endx, startz, endz, starty, endy
		if (a == 1) then
			startz = minp.z
			endz = ( intersectz - math.floor(road_width/2) - 2 )
			startx = cstartx
			endx = intersectx
			starty = road_base_elevation
			endy = intersecty
		else
			startz = ( intersectz + math.floor(road_width/2) + 2 )
			endz = maxp.z
			startx = intersectx
			endx = cendx
			starty = intersecty
			endy = road_base_elevation
		end
		-- repeat for every z-value stating with the lowest
		for z = startz, endz do
			match_i = false
			match_o = false
			match_s = false
			d_i = chunksizeinnodes
			d_o = chunksizeinnodes
			d_s = chunksizeinnodes
			slices_left = endz - z
			-- set first slices pos to be at start elevation and startx
			if (z == startz) then
				x = startx
				y = starty
				prev_x = x
				prev_y = y
				preprev_y = y
				rtype = 3
			else
			
			-- check for valid placement position
			
				-- test straight foreward
				test_x = prev_x
				-- get height at current test position
				hm_i = (test_x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				-- don't go lower than waterlevel
				test_y = math.max(hmap[hm_i], waterlevel)
					
				-- if straight foreward is a x-pos that can reach endx and 
				--  can reach endy and
				--  height is flat or only 1 node difference and
				--  height does not exceed the height-limit
				if (math.abs(test_x - endx) < (slices_left / road_width)) and
					(math.abs(test_y - endy) < slices_left) and
					(math.abs(test_y - prev_y) < 2) and
					(test_y < maxy) then
					match_s = true
					-- get distance to endx
					d_s = math.abs(math.abs( math.floor(math.sin((math.pi / 2) * ((endz - z)/(endz - startz))) * (endx - startx)) ) - math.abs(endx - test_x))
				end
				
				-- test "outward" position
				test_x = prev_x + pref_dir_x
				-- get height at current test position
				hm_i = (test_x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				-- don't go lower than waterlevel
				test_y = math.max(hmap[hm_i], waterlevel)
				-- test again for x-pos one node "outward"
				if (math.abs(test_x - endx) < (slices_left / road_width)) and
					(math.abs(test_y - endy) < slices_left) and
					(math.abs(test_y - prev_y) < 2) and
					(test_y < maxy) then
					match_o = true
					-- get distance to endx
					d_o = math.abs(math.abs( math.floor(math.sin((math.pi / 2) * ((endz - z)/(endz - startz))) * (endx - startx)) ) - math.abs(endx - test_x))
				end
				
				-- test "inward" position
				test_x = prev_x - pref_dir_x
				-- get height at current test position
				hm_i = (test_x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				-- don't go lower than waterlevel
				test_y = math.max(hmap[hm_i], waterlevel)
				-- test again for x-pos one node "inward"
				if (math.abs(test_x - endx) < (slices_left / road_width)) and
					(math.abs(test_y - endy) < slices_left) and
					(math.abs(test_y - prev_y) < 2) and
					(test_y < maxy) then
					match_i = true
					-- get distance to endx
					d_i = math.abs(math.abs( math.floor(math.sin((math.pi / 2) * ((endz - z)/(endz - startz))) * (endx - startx)) ) - math.abs(endx - test_x))
				end
				
				-- if at least on valid position was found
				if match_s or match_i or match_o then
				
					-- if straight forward is closest to endx
					if match_s and (d_s <= d_o) and (d_s <= d_i) then
						x = prev_x
						hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
						y = math.max(hmap[hm_i], waterlevel)
					end
					
					-- if "outwards" is closest to endx
					if match_o and (d_o < d_s) and (d_o < d_i) then
						x = prev_x + pref_dir_x
						hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
						y = math.max(hmap[hm_i], waterlevel)
					end
					
						-- if "inwards" is closest to endx
					if match_i and (d_i < d_s) and (d_i < d_s) then
						x = prev_x - pref_dir_x
						hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
						y = math.max(hmap[hm_i], waterlevel)
					end
					rtype = 1
				else
				-- no valid pos on surface found, tunneling/bridging instead

				
					-- set x-pos as close as possible to endx
					if ( prev_x < (endx - math.floor(((endx - startx) / (endz - startz)) * slices_left)) ) then	
						x = prev_x + 1
					elseif ( prev_x > (endx - math.floor(((endx - startx) / (endz - startz)) * slices_left)) ) then
						x = prev_x - 1
					else
						x = prev_x
					end
					
					-- set y-pos
					-- if road is above ground, lower it
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					if ( (prev_y > hmap[hm_i]) or 
					( minetest.get_node({x=x,y=prev_y,z=z}).name == "air" ) ) and
					( (math.abs(prev_y - endy) + 1) < slices_left ) and
					(math.abs(prev_y - road_base_elevation) < (slices_left + 1)) then
						y = prev_y - 1
					else 
					
						-- else set to closest to target elevation
						test_y = endy
						if ( prev_y < test_y) then
							y = prev_y + 1
						elseif (prev_y > (test_y + slices_left)) then
							y = prev_y - 1
						else
							y = prev_y
						end

					end
					-- make shure y is not below waterlevel
					y = math.max(y, waterlevel)	
					rtype = 2
				end
				
			end	

			-- don't build on water, if not allowed
			if ((water_roads == 1) or 
				((minetest.get_node({x=x,y=(waterlevel),z=z}).name ~= "default:water_source") or
				(minetest.get_node({x=x,y=(waterlevel),z=math.min((z+1),maxp.z)}).name ~= ("default:water_source" or "ignore")))) then
				-- get heat at current pos
				hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				local lheat = heatmap[hm_i]
				local schem_main, schem_stair_neg, schem_stair_pos, schem_tunnel, schem_road_deco
				-- assign matrials depending on temperature
				if (lheat < 20 ) then
					schem_main = t1road_main
					schem_stair_neg = t1road_stairs_neg
					schem_stair_pos = t1road_stairs_pos
					schem_tunnel = t1road_tunnel
					schem_road_deco = t1road_deco
					
				elseif (lheat < 50 ) then
					schem_main = t2road_main
					schem_stair_neg = t2road_stairs_neg
					schem_stair_pos = t2road_stairs_pos
					schem_tunnel = t2road_tunnel
					schem_road_deco = t2road_deco
					
				elseif (lheat < 80 ) then
					schem_main = t3road_main
					schem_stair_neg = t3road_stairs_neg
					schem_stair_pos = t3road_stairs_pos
					schem_tunnel = t3road_tunnel
					schem_road_deco = t3road_deco
					
				else
					schem_main = t4road_main
					schem_stair_neg = t4road_stairs_neg
					schem_stair_pos = t4road_stairs_pos
					schem_tunnel = t4road_tunnel
					schem_road_deco = t4road_deco
					
				end

				-- place main road segment

				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y - 2), z = z }, schem_main, 0, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2)) , y = y, z = z }, schem_road_deco, 0, nil, true)

				
				-- straighten out small height-wobble 
				-- if roadheight of this is the same as two slices before, but not the same as previous slice
				if (y == preprev_y) and
				  (y ~= prev_y) then
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y - 2), z = (z - 1) }, schem_main, 0, nil, true)
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1), z = (z - 1) }, support_tunnel, 0, nil, true)
					prev_y = y
				end
				
				
				-- Replace trees/plants and snow with air
				-- if road is not below surface or excessive_clearing is turned on
				if ( ((y - hmap[hm_i]) > -8) or (excessive_clearing == 1) ) then
					clearlist = minetest.find_nodes_in_area({x = (x - math.floor(road_width/2) - 1), y = (y + 1), z = z },
					{x = (x + math.floor(road_width/2) + 1) , y = maxp.y, z = z },
					{"group:tree", "group:leaves", "group:leafdecay", "group:leafdecay_drop", "group:plant", "group:flora", 
					 "group:sapling", "default:snow", "default:snowblock", "default:cactus"})
					for _ , clnode in pairs(clearlist) do
						minetest.place_schematic_on_vmanip(voxman_o, clnode, air_schem, 0, nil, true)
					end
				end

				-- place stairs if road is uneven
				isstairs = 0
				if (prev_y < y) then
					isstairs = 1
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = y, z = z }, schem_stair_pos, 0, nil, true)
				end
				if (prev_y > y) then
					isstairs = 1
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1), z = z }, schem_stair_neg, 0, nil, true)
				end
				
				-- place tunnel if is underground
				if ( (y - hmap[hm_i]) < -5) and
				  ( minetest.get_node({x = x, y = (y + 6), z = z}).name ~= "air" ) then
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = y , z = z }, schem_tunnel, 0, nil, true)
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1) , z = z }, light_tunnel, 0, nil, true)
				end

				-- place deco if on water
				if ( minetest.get_node({x = x, y = y, z = z}).name == "default:water_source" ) then
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y - 1), z = z }, road_water, 0, nil, true)
				end
				
				-- place street light
				if ( math.random(1, 80) > 78 ) then
					minetest.place_schematic_on_vmanip(voxman_o, { x = (x - math.floor(road_width/2) - 1) , y = (y + 1), z = z }, road_light, 0, nil, true)
				end
			end
			
			prev_x = x
			preprev_y = prev_y
			prev_y = y
		end
	
	end
	
	-- do the x-road
	
		for a = 1, 2 do
		local startx, endx, startz, endz, starty, endy
		if (a == 1) then
			startx = minp.x
			endx = ( intersectx - math.floor(road_width/2) - 2 )
			startz = cstartz
			endz = intersectz
			starty = road_base_elevation
			endy = intersecty
		else
			startx = ( intersectx + math.floor(road_width/2) + 2 )
			endx = maxp.x
			startz = intersectz
			endz = cendz
			starty = intersecty
			endy = road_base_elevation
		end
		-- repeat for every x-value stating with the lowest
		for x = startx, endx do
			match_i = false
			match_o = false
			match_s = false
			d_i = chunksizeinnodes
			d_o = chunksizeinnodes
			d_s = chunksizeinnodes
			slices_left = endx - x
			-- set first slices pos to be at start elevation and startx
			if (x == startx) then
				z = startz
				y = starty
				prev_z = z
				prev_y = y
				preprev_y = y
				rtype = 3
			else
			
			-- check for valid placement position
			
				-- test straight foreward
				test_z = prev_z
				-- get height at current test position
				hm_i = (x - minp.x + 1) + (((test_z - minp.z)) * chunksizeinnodes)
				-- don't go lower than waterlevel
				test_y = math.max(hmap[hm_i], waterlevel)
					
				-- if straight foreward is a x-pos that can reach endx and 
				--  can reach endy and
				--  height is flat or only 1 node difference and
				--  height does not exceed the height-limit
				if (math.abs(test_z - endz) < (slices_left / road_width)) and
					(math.abs(test_y - endy) < slices_left) and
					(math.abs(test_y - prev_y) < 2) and
					(test_y < maxy) then
					match_s = true
					-- get distance to endz
					d_s = math.abs(math.abs( math.floor(math.sin((math.pi / 2) * ((endx - x)/(endx - startx))) * (endz - startz)) ) - math.abs(endz - test_z))
				end
				
				-- test "outward" position
				test_z = prev_z + pref_dir_z
				-- get height at current test position
				hm_i = (x - minp.x + 1) + (((test_z - minp.z)) * chunksizeinnodes)
				-- don't go lower than waterlevel
				test_y = math.max(hmap[hm_i], waterlevel)
				-- test again for x-pos one node "outward"
				if (math.abs(test_z - endz) < (slices_left / road_width)) and
					(math.abs(test_y - endy) < slices_left) and
					(math.abs(test_y - prev_y) < 2) and
					(test_y < maxy) then
					match_o = true
					-- get distance to endz
					d_o = math.abs(math.abs( math.floor(math.sin((math.pi / 2) * ((endx - x)/(endx - startx))) * (endz - startz)) ) - math.abs(endz - test_z))
				end
				
				-- test "inward" position
				test_z = prev_z - pref_dir_z
				-- get height at current test position
				hm_i = (x - minp.x + 1) + (((test_z - minp.z)) * chunksizeinnodes)
				-- don't go lower than waterlevel
				test_y = math.max(hmap[hm_i], waterlevel)
				-- test again for x-pos one node "inward"
				if (math.abs(test_z - endz) < (slices_left / road_width)) and
					(math.abs(test_y - endy) < slices_left) and
					(math.abs(test_y - prev_y) < 2) and
					(test_y < maxy) then
					match_i = true
					-- get distance to endz
					d_i = math.abs(math.abs( math.floor(math.sin((math.pi / 2) * ((endx - x)/(endx - startx))) * (endz - startz)) ) - math.abs(endz - test_z))
				end
				
				-- if at least on valid position was found
				if match_s or match_i or match_o then
				
					-- if straight forward is closest to endx
					if match_s and (d_s <= d_o) and (d_s <= d_i) then
						z = prev_z
						hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
						y = math.max(hmap[hm_i], waterlevel)
					end
					
					-- if "outwards" is closest to endx
					if match_o and (d_o < d_s) and (d_o < d_i) then
						z = prev_z + pref_dir_z
						hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
						y = math.max(hmap[hm_i], waterlevel)
					end
					
						-- if "inwards" is closest to endx
					if match_i and (d_i < d_s) and (d_i < d_s) then
						z = prev_z - pref_dir_z
						hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
						y = math.max(hmap[hm_i], waterlevel)
					end
					rtype = 1
				else
				-- no valid pos on surface found, tunneling/bridging instead

				
					-- set z-pos as close as possible to endz
					if ( prev_z < (endz - math.floor(((endz - startz) / (endx - startx)) * slices_left)) ) then	
						z = prev_z + 1
					elseif ( prev_z > (endz - math.floor(((endz - startz) / (endx - startx)) * slices_left)) ) then
						z = prev_z - 1
					else
						z = prev_z
					end
					
					-- set y-pos
					-- if road is above ground, lower it
					hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
					if ( (prev_y > hmap[hm_i]) or 
					( minetest.get_node({x=x,y=prev_y,z=z}).name == "air" ) ) and
					( (math.abs(prev_y - endy) + 1) < slices_left ) and
					(math.abs(prev_y - road_base_elevation) < (slices_left + 1)) then 
						y = prev_y - 1
					else 
					
						-- else set to closest to base-level
						test_y = endy
						if ( prev_y < test_y) then
							y = prev_y + 1
						elseif (prev_y > (test_y + slices_left)) then
							y = prev_y - 1
						else
							y = prev_y
						end
					end
					-- make shure y is not below waterlevel
					y = math.max(y, waterlevel)	
					rtype = 2
				end
				
			end	

		-- don't build on water, if not allowed	
		if ((water_roads == 1) or 
			((minetest.get_node({x=x,y=(waterlevel),z=z}).name ~= "default:water_source") or
			(minetest.get_node({x=math.min((x+1),maxp.x),y=(waterlevel),z=z}).name ~= ("default:water_source" or "ignore")))) then
				-- get heat at current pos
				hm_i = (x - minp.x + 1) + (((z - minp.z)) * chunksizeinnodes)
				local lheat = heatmap[hm_i]
				local schem_main, schem_stair_neg, schem_stair_pos, schem_tunnel, schem_road_deco
				-- assign matrials depending on temperature
				if (lheat < 20 ) then
					schem_main = t1road_main
					schem_stair_neg = t1road_stairs_neg
					schem_stair_pos = t1road_stairs_pos
					schem_tunnel = t1road_tunnel
					schem_road_deco = t1road_deco
					
				elseif (lheat < 50 ) then
					schem_main = t2road_main
					schem_stair_neg = t2road_stairs_neg
					schem_stair_pos = t2road_stairs_pos
					schem_tunnel = t2road_tunnel
					schem_road_deco = t2road_deco
					
				elseif (lheat < 80 ) then
					schem_main = t3road_main
					schem_stair_neg = t3road_stairs_neg
					schem_stair_pos = t3road_stairs_pos
					schem_tunnel = t3road_tunnel
					schem_road_deco = t3road_deco
					
				else
					schem_main = t4road_main
					schem_stair_neg = t4road_stairs_neg
					schem_stair_pos = t4road_stairs_pos
					schem_tunnel = t4road_tunnel
					schem_road_deco = t4road_deco
					
				end

			-- place main road segment

			minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y - 2), z = (z - math.floor(road_width/2) - 1) }, schem_main, 90, nil, true)
			minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = y, z = (z - math.floor(road_width/2)) }, schem_road_deco, 90, nil, true)

			
			-- straighten out small height-wobble 
			-- if roadheight of this is the same as two slices before, but not the same as previous slice
			if (y == preprev_y) and
			  (y ~= prev_y) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - 1) , y = (y - 2), z = (z - math.floor(road_width/2) - 1) }, schem_main, 90, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = (x - 1) , y = (y + 1), z = (z - math.floor(road_width/2) - 1) }, support_tunnel, 90, nil, true)
				prev_y = y
			end
			
			
			-- Replace trees/plants and snow with air
			-- if road is not below surface or excessive_clearing is turned on
			if ( ((y - hmap[hm_i]) > -8) or (excessive_clearing == 1) ) then
				clearlist = minetest.find_nodes_in_area({x = x, y = (y + 1), z = (z - math.floor(road_width/2) - 1) },
				{x = x , y = maxp.y, z = (z + math.floor(road_width/2) + 1) },
				{"group:tree", "group:leaves", "group:leafdecay", "group:leafdecay_drop", "group:plant", "group:flora", 
				 "group:sapling", "default:snow", "default:snowblock", "default:cactus"})
				for _ , clnode in pairs(clearlist) do
					minetest.place_schematic_on_vmanip(voxman_o, clnode, air_schem, 90, nil, true)
				end
			end

			-- place stairs if road is uneven
			isstairs = 0
			if (prev_y < y) then
				isstairs = 1
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = y, z = (z - math.floor(road_width/2) - 1) }, schem_stair_pos, 90, nil, true)
			end
			if (prev_y > y) then
				isstairs = 1
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y + 1), z = (z - math.floor(road_width/2) - 1) }, schem_stair_neg, 90, nil, true)
			end
			
			-- place tunnel if is underground
			if ( (y - hmap[hm_i]) < -5) and
			  ( minetest.get_node({x = x, y = (y + 6), z = z}).name ~= "air" ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = y , z = (z - math.floor(road_width/2) - 1) }, schem_tunnel, 90, nil, true)
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y + 1) , z = (z - math.floor(road_width/2) - 1) }, light_tunnel, 90, nil, true)
			end

			-- place deco if on water
			if ( minetest.get_node({x = x, y = y, z = z}).name == "default:water_source" ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y - 1), z = (z - math.floor(road_width/2) - 1) }, road_water, 90, nil, true)
			end
			
			-- place street light
			if ( math.random(1, 80) > 78 ) then
				minetest.place_schematic_on_vmanip(voxman_o, { x = x , y = (y + 1), z = (z - math.floor(road_width/2) - 1) }, road_light, 90, nil, true)
			end
		end
		
			prev_z = z
			preprev_y = prev_y
			prev_y = y
		end
	
	end
	
	-- clear intersection area
	clearlist = minetest.find_nodes_in_area({x = (intersectx - math.floor(road_width/2) - 2), y = (intersecty + 3), z = (intersectz - math.floor(road_width/2) - 2) },
			{x = (intersectx + math.floor(road_width/2) + 2) , y = maxp.y, z = (intersectz + math.floor(road_width/2) + 2) },
			{"group:tree", "group:leaves", "group:leafdecay", "group:leafdecay_drop", "group:plant", "group:flora", 
			 "group:sapling", "default:snow", "default:snowblock", "default:cactus"})
	for _ , clnode in pairs(clearlist) do
		minetest.place_schematic_on_vmanip(voxman_o, clnode, air_schem, 90, nil, true)
	end
	
	-- put voxel manipulator object on map
	voxman_o:calc_lighting()
	voxman_o:write_to_map()
	

		
end	


-- -- the road building callback-function -- called upon world generation once per chunk

minetest.register_on_generated(function(minp, maxp, seed)
	-- if the chunk does not contain the y-position the road should be at, exit and do nothing.
	if not ( (minp.y < road_base_elevation) and (maxp.y > road_base_elevation) ) then
		return
	end
	
	if ( ( ((math.floor(minp.x/chunksizeinnodes)) % gridchunks) == 0 ) and
		( ((math.floor(minp.z/chunksizeinnodes)) % gridchunks) == 0 ) ) then
		makeroadcross(minp, maxp, seed)
		return
	end
	
	if ( ((math.floor(minp.x/chunksizeinnodes)) % gridchunks) == 0 ) then 	
		makeroadZ(minp, maxp, seed)
		return
	end
	
		if ( ((math.floor(minp.z/chunksizeinnodes)) % gridchunks) == 0 ) then 	
		makeroadX(minp, maxp, seed)
		return
	end
end	
)
