--Makes a stratus of rocks
--name of the rock to generate
--wherein kind of node to replace, for example default:stone
--minp, maxp the corners of the map to be generated
--seed random seed
--stratus_chance inverse probability in a given radius 1:2, 1:3 etc
--radius horizontal radius of the stratus
--radius_y vertical radius of the stratus
-- [[deep how deep can be from the ground
local function generate_single_stratus(str, minp, maxp, mapseed, data, area)
	local name, wherein, ceilin, seed, stratus_chance, radius, radius_y, deep, y_min, y_max = unpack(str)
	if maxp.y < y_min
	or minp.y > y_max then
		return
	end
	seed = seed+mapseed

	name = minetest.get_content_id(name)
	wherein = minetest.get_content_id(wherein[1])
	ceilin = table.copy(ceilin)
	for n,i in pairs(ceilin) do
		ceilin[n] = minetest.get_content_id(i)
	end

	-- it will be only generate a stratus for every 100 m of area
	local stratus_per_volume=1
	local area_size = 45
	local y_min = math.max(minp.y, y_min)
	local y_max = math.min(maxp.y, y_max)
	local volume = ((maxp.x-minp.x+1)/area_size)*((y_max-y_min+1)/area_size)*((maxp.z-minp.z+1)/area_size)
	local pr = PseudoRandom(seed)
	local blocks = math.floor(stratus_per_volume*volume)
	minetest.log("info", "	<<"..dump(name)..">>");
	if blocks == 0 then
		blocks = 1
	end
	minetest.log("info", "	blocks: "..dump(blocks).." in vol: "..dump(volume).." ("..dump(maxp.x-minp.x+1)..","..dump(y_max-y_min+1)..","..dump(maxp.z-minp.z+1)..")")
	for i = 1,blocks do
		if pr:next(1,stratus_chance) == 1 then
			-- TODO deep
			local y0=y_max-radius_y+1
			if y0 < y_min then
				y0=y_min
			else
				y0=pr:next(y_min, y0)
			end
			local x0 = maxp.x-radius+1
			if x0 < minp.x then
				x0 = minp.x
			else
				x0 = pr:next(minp.x, x0)
			end
			local z0 = maxp.z-radius+1
			if z0 < minp.z then
				x0 = minp.z
			else
				z0 = pr:next(minp.z, z0)
			end
			local n = data[area:index(x0, y0, z0)]
			local i = 0
			--print("	upper node "..n)
			local x
			for _,v in ipairs(ceilin) do
				if n == v then
					x = true
					break
				end
			end
			if x then
				-- search for the node to replace
				--print("	Searching nodes to replace from "..dump(y0-1).." to "..dump(y_min))
				local vi = area:index(x0, y0-1, z0)
				for y1 = y0-1,y_min,-1 do
					if data[vi] == wherein then
						y0 = math.max(y1-deep, y_min)
						break
					end
					vi = vi - area.ystride
				end
				local rx=pr:next(radius/2,radius)+1
				local rz=pr:next(radius/2,radius)+1
				local ry=pr:next(radius_y/2,radius_y)+1
				--print("	area of generation ("..dump(rx)..","..dump(rz)..","..dump(ry)..")")
				local vi = area:index(x0, y0, z0)
				for x1=0,rx do
					local vi = vi + x1
					rz = math.max(rz + 3 - pr:next(1,6), 1)
					for z1=pr:next(1,3),rz do
						local vi = vi + z1 * area.zstride
						for y1 = pr:next(1,3), ry + pr:next(1,3) do
							local vi = vi + y1 * area.ystride
							if data[vi] == wherein then
								data[vi] = name
								i = i + 1
							end
						end
					end
				end
			end
			minetest.log("info", "	generated "..i.." blocks in ("..x0..","..y0..","..z0..")")
		end
	end
	--print("generate_ore done")
end

local strati,n = {},1
local function generate_stratus(name, wherein, ceilin, ceil, minp, maxp, seed, stratus_chance, radius, radius_y, deep, y_min, y_max)
--[[
	wherein[1] = "air"
	y_max = 30000--]]
	strati[n] = {name, wherein, ceilin, seed, stratus_chance, radius, radius_y, deep, y_min, y_max}
	n = n+1
end

local function generate_strati(minp, maxp, seed, data, area)
	for _,str in ipairs(strati) do
		generate_single_stratus(str, minp, maxp, seed, data, area)
	end
end

local function generate_claylike(name, minp, maxp, seed, chance, minh, maxh, dirt)
	if maxp.y <= maxh
	or minp.y >= minh then
		return
	end
	local pr = PseudoRandom(seed)
	local divlen = 4
	local divs = (maxp.x-minp.x)/divlen+1;
	for yy=minh,maxh do
		local x = pr:next(1,chance)
		if x == 1 then
			for divx=0+1,divs-1-1 do
				for divz=0+1,divs-1-1 do
					local cx = minp.x + math.floor((divx+0.5)*divlen)
					local cz = minp.z + math.floor((divz+0.5)*divlen)
					local up = minetest.get_node({x=cx,y=yy,z=cz}).name
					local down = minetest.get_node({x=cx,y=yy-1,z=cz}).name
					if (up == "default:water_source"
						or up == "air"
					)
					and ( down == "default:sand"
						or (
							(down == "default:dirt"
								or down == "default:dirt_with_grass"
							)
							and dirt == 1
						)
					) then
						local num_water_around = 0
						for _,pos in ipairs({
							{x=cx-divlen*2,y=yy,z=cz},
							{x=cx+divlen*2,y=yy,z=cz},
							{x=cx,y=yy,z=cz-divlen*2},
							{x=cx,y=yy,z=cz+divlen*2}
						}) do
							if minetest.get_node(pos).name == "default:water_source" then
								num_water_around = num_water_around + 1
							end
						end
						if num_water_around <= 2 then
							for x1=-divlen,divlen do
								for z1=-divlen,divlen do
									local p={x=cx+x1,y=yy-1,z=cz+z1}
									down = minetest.get_node(p).name
									if down == "default:sand"
									or (dirt == 1
										and (down == "default:dirt"
											or down == "default:dirt_with_grass"
										)
									) then
										minetest.set_node(p, {name=name})
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

--[[
local function generate_ore(name, wherein, minp, maxp, seed, chunks_per_volume, chunk_size, ore_per_chunk, y_min, y_max)
	if maxp.y < y_min or minp.y > y_max then
		return
	end
	local y_min = math.max(minp.y, y_min)
	local y_max = math.min(maxp.y, y_max)
	local volume = (maxp.x-minp.x+1)*(y_max-y_min+1)*(maxp.z-minp.z+1)
	local pr = PseudoRandom(seed)
	local num_chunks = math.floor(chunks_per_volume * volume)
	local inverse_chance = math.floor(chunk_size*chunk_size*chunk_size / ore_per_chunk)
	--print("generate_ore num_chunks: "..dump(num_chunks))
	for i=1,num_chunks do
		local y0 = pr:next(y_min, y_max-chunk_size+1)
		if y0 >= y_min and y0 <= y_max then
			local x0 = pr:next(minp.x, maxp.x-chunk_size+1)
			local z0 = pr:next(minp.z, maxp.z-chunk_size+1)
			local p0 = {x=x0, y=y0, z=z0}
			for x1=0,chunk_size-1 do
			for y1=0,chunk_size-1 do
			for z1=0,chunk_size-1 do
				if pr:next(1,inverse_chance) == 1 then
					local x2 = x0+x1
					local y2 = y0+y1
					local z2 = z0+z1
					local p2 = {x=x2, y=y2, z=z2}
					if minetest.get_node(p2).name == wherein then
						minetest.set_node(p2, {name=name})
					end
				end
			end
			end
			end
		end
	end
	--print("generate_ore done")
end]]

--[[
local function generate_stratus(name, wherein, ceilin, ceil, minp, maxp, seed, stratus_chance, radius, radius_y, deep, y_min, y_max)
	minetest.register_ore({
		ore_type	 	= "sheet",
		ore				= name,
		wherein			= "default:stone",
		noise_threshold = 1/stratus_chance,
		noise_params	= {offset=0, scale=2, spread={x=radius, y=radius_y, z=radius}, seed=seed, octaves=2, persist=0.70}
		clust_size		= 4,
		y_min		= y_min,
		y_max		= y_max,
	})
end--]]

--[[
minetest.register_ore({
	ore_type	 	= "sheet",
	ore				= "darkage:chalk",
	wherein			= "default:stone",
	clust_size		= 4,
	y_min		= -20,
	y_max		= 50,
	noise_params	= {offset=0, scale=2, spread={x=10000, y=10000, z=10000}, seed=1135, octaves=2, persist=0.70}
})

minetest.register_ore({
	ore_type	 	= "sheet",
	ore				= "darkage:gneiss",
	wherein			= "default:stone",
	clust_size		= 2,
	y_min		= -31000,
	y_max		= -250,
	noise_params	= {offset=0, scale=10, spread={x=2000, y=10000, z=2000}, seed=1139, octaves=2, persist=0.70}
})--]]

local seed = 0
local minp, maxp
-- [[ (name, wherein, ceilin, crap, crap, crap, seed, stratus_chance, radius, radius_y, deep, y_min, y_max)
generate_stratus("darkage:chalk",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+3, 4, 25, 8, 0, -20,	50)
generate_stratus("darkage:ors",
				{"default:stone"},
				{"default:stone","air","default:water_source"}, nil,
				minp, maxp, seed+4, 4, 25, 7, 50, -200,	500)
generate_stratus("darkage:shale",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+5, 4, 23, 7, 50, -50,	20)
generate_stratus("darkage:slate",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+6, 6, 23, 5, 50, -500, 0)
generate_stratus("darkage:schist",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+7, 6, 19, 6, 50, -31000, -10)
generate_stratus("darkage:basalt",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+8, 5, 20, 5, 20, -31000, -50)
generate_stratus("darkage:marble",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+9, 4, 25, 6, 50, -31000,	-75)
generate_stratus("darkage:serpentine",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+10, 4, 28, 8, 50, -31000,	-350)
generate_stratus("darkage:gneiss",
				{"default:stone"},
				{"default:stone","air"}, nil,
				minp, maxp, seed+11, 4, 15, 5, 50, -31000, -250)--]]

minetest.register_on_generated(function(minp, maxp, seed)
	-- Generate stratus
	local t1 = os.clock()
	minetest.log("info", "[darkage] Generate...")

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

--	generate_ore("darkage:desert_stone_with_iron", "default:desert_stone", minp, maxp, seed+0, 1/7/7/7, 3, 5, -15, 40)
	generate_claylike("darkage:mud", minp, maxp, seed+1, 4, 0, 2, 0)
	generate_claylike("darkage:silt", minp, maxp, seed+2, 4, -1, 1, 1)

	generate_strati(minp, maxp, seed, data, area)

	vm:set_data(data)
	vm:write_to_map()

	minetest.log("info", string.format("[darkage] finished after: %.2fs", os.clock() - t1))
end)
