for _,name in ipairs({"basalt_cobble", "slate_tale", "straw", "stone_brick", "ors_cobble", "gneiss_cobble", "slate_cobble"}) do
	local nodename = "darkage:"..name
	local tmp = minetest.registered_nodes[nodename]
	if not tmp then
		print("[darkage] "..nodename.." not yet defined")
		return
	end
	local desc = tmp.description
	stairs.register_stair_and_slab("darkage_"..name, nodename,
		tmp.groups,
		{"darkage_"..name..".png"},
		desc.." Stair",
		desc.." Slab",
		tmp.sounds
	)
end
--"desert_stone_cobble" "sandstone_cobble"
