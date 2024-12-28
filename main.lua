mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)

-- check that a console instance doesn't exist already
if GM.instance_number(gm.constants.oConsole) == 0 then
	GM.instance_create_depth(0, 0, -100000001, gm.constants.oConsole)
end

local ConsoleColours = {
    -- BBGGRR
    white	= 0x9B938C, -- Most text
    red		= 0x3D33CC, -- Error
    green	= 0x54AD48, -- Success
    blue	= 0xCC9B5F,
    pink	= 0xB563AF,
    purple	= 0xB55174,
    black	= 0x564E4B,
}
local ConsoleColors = ConsoleColours

local commands = {}

local function add_command(signature, func)
	GM._mod_console_registerCommandSignature(signature)

	local whitespace = string.find(signature, "%s") or math.maxinteger
	local name = string.sub(signature, 1, whitespace - 1)
	commands[name] = func

	--log.info("added command "..name..", signature: "..signature)
end
local function add_message(msg, col)
	GM.console_add_message(tostring(msg), col or ConsoleColours.white, 0)
end

local function util_namespace_unpack(pair)
	local namespace
	local identifier = pair
	local hyphen = string.find(pair, "-")
	if hyphen then
		namespace = string.sub(pair, 1, hyphen-1)
		identifier = string.sub(pair, hyphen+1)
	end
	return namespace, identifier
end

local function init()
	Callback.add(Callback.TYPE.console_onCommand, "EnableConsoleCommand", function(input)
		local cmd = {}
		for split in string.gmatch(input, "[^%s]+") do
			table.insert(cmd, split)
		end
		cmd[1] = string.lower(cmd[1])

		local fn = commands[cmd[1]]
		if fn then
			table.remove(cmd, 1)
			fn(cmd)
		end
	end)
end

Initialize(init)

if hotload then
	init()
end
hotload = true

add_command("game_speed [fps]", function(args)
	local fps = math.max(1, tonumber(args[1]) or 60)
	GM.game_set_speed(fps, 0)
	add_message("Game speed set to "..tostring(fps), ConsoleColours.green)
end)

add_command("gostage (name) [variant]", function(args)
	if not GM._mod_game_ingame() then
		add_message("You must be in-game to use this command", ConsoleColours.blue)
		return
	end

	if #args < 1 then
		add_message("Enter a stage name", ConsoleColours.blue)
		return
	end

	local stage = Stage.find(args[1])
	local index = tonumber(args[2])
	if not stage then
		add_message("Invalid stage name", ConsoleColours.red)
		return
	end
	if index then
		-- force valid range
		index = math.max(0, index)
		index = math.min(GM.ds_list_size(stage.room_list)-1, index)
		index = math.floor(index)
	end

	GM.stage_goto(stage.value, index)
	if index then
		add_message("Going to "..stage.identifier.." variant #"..tostring(index+1), ConsoleColours.green)
	else
		add_message("Going to "..stage.identifier, ConsoleColours.green)
	end
end)

add_command("summon (card) [count] [elite]", function(args)
	local director = GM._mod_game_getDirector()

	if director == -4 then
		add_message("You must be in-game to use this command", ConsoleColours.blue)
		return
	end

	if #args < 1 then
		add_message("Enter a spawn card name", ConsoleColours.blue)
		return
	end

	local card = Monster_Card.find(args[1])
	if not card then
		add_message("Invalid spawn card name", ConsoleColours.red)
		return
	end

	local count = tonumber(args[2]) or 1

	local elite = nil
	if #args > 2 then
		elite = GM.elite_type_find(args[3])
		if not elite then
			add_message("Invalid elite name", ConsoleColours.red)
			return
		end
	end

	local preserve_peace = director.peace
	director.peace = false
	for i=1, count do
		director.card_choice = card.value
		if elite then
			director.spawn_elite = elite
		end
		director.points = card.spawn_cost * 1.2
		director:event_perform(2, 1) -- ev_alarm
	end
	director.peace = preserve_peace

	if elite then
		add_message("Summoned "..tostring(count).." "..args[3].." "..card.identifier, ConsoleColours.green)
	else
		add_message("Summoned "..tostring(count).." "..card.identifier, ConsoleColours.green)
	end
end)

add_command("locate (object) [index]", function(args)
	if #args < 1 then
		add_message("Enter a valid object name", ConsoleColours.blue)
		return
	end
	local namespace, identifier = util_namespace_unpack(args[1])
	local obj = GM._mod_object_find(identifier, namespace)
	if obj == -1 then
		add_message("Invalid object: \""..identifier.."\"", ConsoleColours.red)
		return
	end

	local index = tonumber(args[2]) or 1
	local locate = GM._mod_instance_find(obj, index)

	if locate == -4 then
		add_message("Failed to locate instance", ConsoleColours.red)
		if GM._mod_instance_number(obj) > 0 then
			if index < 1 or index > GM._mod_instance_number(obj) then
				add_message("Index out of range", ConsoleColours.red)
			end
		else
			add_message("No instances of given object exist", ConsoleColours.red)
		end
		return
	end
	local p = Player.get_client()
	if p:exists() then
		p.x = locate.x
		p.y = locate.y - 16
	end
end)

add_command("camera_lock", function(args)
	local oHUD = GM._mod_game_getHUD()
	if oHUD ~= -4 then
		oHUD.camera_locked = true
		add_message("Camera LOCKED", ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)

add_command("camera_track (object) [index]", function(args)
	local oHUD = GM._mod_game_getHUD()
	if oHUD == -4 then
		add_message("You must be in-game to use this command", ConsoleColours.blue)
		return
	end
	if #args < 1 then
		add_message("Enter a valid object name", ConsoleColours.blue)
		return
	end

	local namespace, identifier = util_namespace_unpack(args[1])
	local obj = GM._mod_object_find(identifier, namespace)
	if obj == -1 then
		add_message("Invalid object: \""..identifier.."\"", ConsoleColours.red)
		return
	end

	local index = tonumber(args[2]) or 1
	local locate = GM._mod_instance_find(obj, index)

	if locate == -4 then
		add_message("Failed to locate instance", ConsoleColours.red)
		if GM._mod_instance_number(obj) > 0 then
			if index < 1 or index > GM._mod_instance_number(obj) then
				add_message("Index out of range", ConsoleColours.red)
			end
		else
			add_message("No instances of given object exist", ConsoleColours.red)
		end
		return
	end

	oHUD.camera_track = locate
end)
add_command("camera_reset", function(args)
	local oHUD = GM._mod_game_getHUD()
	if oHUD ~= -4 then
		oHUD.camera_locked = false
		oHUD.camera_track = -4
		add_message("Camera RESET", ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)

add_command("zoom", function(args)
	local p = Player.get_client()
	if p:exists() then
		p:item_give(Item.find("paulsGoatHoof"), 60)
		p:item_give(Item.find("hopooFeather"), 60)
		add_message("zoomies :3", ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)
add_command("unzoom", function(args)
	local p = Player.get_client()
	if p:exists() then
		p:item_remove(Item.find("paulsGoatHoof"), 60)
		p:item_remove(Item.find("hopooFeather"), 60)
		add_message("no zoomies :(", ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)

add_command("firepower", function(args)
	local p = Player.get_client()
	if p:exists() then
		p:item_give(Item.find("lensMakersGlasses"), 20)
		p:item_give(Item.find("soldiersSyringe"), 20)
		p:item_give(Item.find("brilliantBehemoth"), 100)
		add_message("firepowered !!", ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)
add_command("unfirepower", function(args)
	local p = Player.get_client()
	if p:exists() then
		p:item_remove(Item.find("lensMakersGlasses"), 20)
		p:item_remove(Item.find("soldiersSyringe"), 20)
		p:item_remove(Item.find("brilliantBehemoth"), 100)
		add_message("unfirepowered .", ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)

local preserve_director_alarm_1
add_command("peace", function(args)
	local director = GM._mod_game_getDirector()
	if director ~= -4 then
		director.peace = true
		add_message("Peace ON", ConsoleColours.green)
		preserve_director_alarm_1 = director:alarm_get(1)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)
add_command("unpeace", function(args)
	local director = GM._mod_game_getDirector()
	if director ~= -4 then
		director.peace = false
		add_message("Peace OFF", ConsoleColours.green)
		if preserve_director_alarm_1 then
			director:alarm_set(1, preserve_director_alarm_1)
			preserve_director_alarm_1 = nil
		end
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)
add_command("god", function(args)
	local p = Player.get_client()
	p.invincible = math.huge
	add_message("Godmode ON", ConsoleColours.green)
end)
add_command("ungod", function(args)
	local p = Player.get_client()
	p.invincible = 0
	add_message("Godmode OFF", ConsoleColours.green)
end)

add_command("skip_tp", function(args)
	local tps = Instance.find_all(gm.constants.pTeleporter)
	if #tps > 0 then
		for _, tp in ipairs(tps) do
			tp.time = 0
			tp.maxtime = 1
		end
		add_message("Teleporter skipped", ConsoleColours.green)
	else
		add_message("Teleporter not found", ConsoleColours.red)
	end
end)

add_command("kill_all", function(args)
	local actors = Instance.find_all(gm.constants.pActor)
	if #actors > 0 then
		local kills = 0
		for _, actor in ipairs(actors) do
			if actor.team ~= 1.0 then
				actor.hp = -10000
				kills = kills + 1
			end
		end
		add_message("Killed "..tostring(kills).." actor(s).", ConsoleColours.green)
	else
		add_message("No actors?", ConsoleColours.red)
	end
end)

add_command("give_item (item) [count] [temporary]", function(args)
	if #args < 1 then
		add_message("Enter a valid item name", ConsoleColours.blue)
		return
	end
	local p = Player.get_client()
	if p:exists() then
		local item = Item.find(args[1])
		if not item then
			add_message("Invalid item name: \""..args[1].."\"", ConsoleColours.red)
			return
		end
		local count = tonumber(args[2]) or 1
		local kind = tonumber(args[3]) or 0

		p:item_give(item, count, kind)
		add_message("Given "..tostring(count).." "..item.identifier, ConsoleColours.green)
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)

add_command("remove_item (item) [count]", function(args)
	if #args < 1 then
		add_message("Enter a valid item name", ConsoleColours.blue)
		return
	end
	local p = Player.get_client()
	if p:exists() then
		local item = Item.find(args[1])
		if not item then
			add_message("Invalid item: \""..args[1].."\"", ConsoleColours.red)
			return
		end
		local count = tonumber(args[2]) or 1

		p:item_remove(item, count)
		if #args > 2 and tonumber(args[3]) ~= 0 then
			add_message("Temp items cannot be removed, sorry;;", ConsoleColours.red)
		else
			add_message("Removed "..tostring(count).." "..item.identifier, ConsoleColours.green)
		end
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)
add_command("logs", function(args)
	if args[1] == "confirm" then
		for i=0, GM.variable_global_get("count_monster_log")-1 do
			GM.save_flag_set(GM.monster_log_get_save_key_got(i), true)
		end
		for i=0, GM.variable_global_get("count_item_log")-1 do
			GM.save_flag_set(GM.item_log_get_save_key_got(i), true)
		end
		for i=0, GM.variable_global_get("count_survivor_log")-1 do
			GM.save_flag_set(GM.survivor_log_get_save_key_got(i), true)
		end
		for i=0, GM.variable_global_get("count_environment_log")-1 do
			GM.save_flag_set(GM.environment_log_get_save_key_got(i), true)

			local log = Environment_Log.wrap(i)
			for j=0, #log.display_room_ids-1 do
				GM.save_flag_set(GM.environment_log_get_save_key_variant_unlocked(i, j), true)
			end
		end
		add_message("All logs unlocked", ConsoleColours.green)
	else
		add_message("Are you sure? This will permanently alter your save data! Enter `logs confirm` to confirm.")
	end
end)
add_command("gimme (object) [count]", function(args)
	if #args < 1 then
		add_message("Enter a valid object name", ConsoleColours.blue)
		return
	end

	local namespace, identifier = util_namespace_unpack(args[1])
	local obj = GM._mod_object_find(identifier, namespace)
	if obj == -1 then
		add_message("Invalid object: \""..identifier.."\"", ConsoleColours.red)
		return
	end

	local count = tonumber(args[2]) or 1
	local x, y = GM.input_mouse_x(), GM.input_mouse_y()

	for i=1, count do
		GM.instance_create(x, y, obj)
	end

	add_message(string.format("Spawning %s %s at mouse location", count, identifier), ConsoleColours.green)
end)
add_command("spawn_boss [kind] [mountain]", function(args)
	local director = GM._mod_game_getDirector()

	if director == -4 then
		add_message("You must be in-game to use this command", ConsoleColours.blue)
		return
	end

	local kind = args[1]
	local mountain = tonumber(args[2]) or 0

	local p = Instance.find(gm.constants.oP)
	director:director_do_teleporter_boss_spawn(p.x, p.y,
										math.max(700, 450 * GM.power(director.enemy_buff, 0.4)),
										director.monster_spawn_array, mountain, kind == "horde", kind == "blight")

	add_message("Spawning boss", ConsoleColours.green)
end)

add_command("test_lategame [minutes] [items] [levels]", function(args)
	if not GM._mod_game_ingame() or GM._mod_net_isClient() then
		add_message("You must be in-game and not a client to use this command.", ConsoleColours.blue)
		return
	end
	local director = GM._mod_game_getDirector()

	local minutes = tonumber(args[1]) or 60
	local items = tonumber(args[2]) or 90
	local levels = tonumber(args[3]) or 12

	for i=1, minutes*60 do
		director:event_perform(2, 0)
	end
	director.loops = director.loops + 3
	director.points = 0

	local players = Instance.find_all(gm.constants.oP)
	for _, actor in ipairs(players) do
		for i=1, items do
			local p
			if math.random() < 0.2 then
				p = GM.treasure_weights_roll_pickup(0) -- TREASURE_WEIGHT_INDEX.small_chest
			else
				p = GM.treasure_weights_roll_pickup(1) -- TREASURE_WEIGHT_INDEX.large_chest
			end
			if p ~= -1 and GM.object_to_item(p) ~= -1 and p ~= gm.constants.oDuplicator and p ~= gm.constants.oUmbrella then
				actor:item_give(GM.object_to_item(p))
			end
		end
	end

	for i=1, levels do
		director:player_level_up_gml_Object_oDirectorControl_Create_0()
	end

	add_message(string.format("Advanced time by %d minutes, %d items given, %d level ups.", minutes, items, levels), ConsoleColours.green)
end)
add_command("unlockall", function(args)
	if args[1] == "confirm" then
		for i=0, GM.variable_global_get("count_achievement")-1 do
			GM.achievement_force_set_unlocked(i, true)
		end
		add_message("All achievements unlocked", ConsoleColours.green)
	else
		add_message("Are you sure? This will permanently alter your save data! Enter `unlockall confirm` to confirm.")
	end
end)
add_command("lockall", function(args)
	if args[1] == "confirm" then
		for i=0, GM.variable_global_get("count_achievement")-1 do
			GM.achievement_force_set_unlocked(i, false)
		end
		add_message("All achievements locked", ConsoleColours.green)
	else
		add_message("Are you sure? This will permanently alter your save data! Enter `lockall confirm` to confirm.")
	end
end)
add_command("unlock (achievement)", function(args)
	local ach = Achievement.find(args[1])
	if ach then
		GM.achievement_force_set_unlocked(ach.value, true)
	else
		add_message("Enter a valid unlock name", ConsoleColours.blue)
	end
end)
add_command("lock (achievement)", function(args)
	local ach = Achievement.find(args[1])
	if ach then
		GM.achievement_force_set_unlocked(ach.value, false)
	else
		add_message("Enter a valid unlock name", ConsoleColours.blue)
	end
end)

add_command("test_eclipse", function(args)
	if GM._mod_room_get_current() ~= gm.constants.rStart then
		add_message("Use command from start menu", ConsoleColours.blue)
	else
		GM.variable_global_set("__gamemode_current", 1)
		GM.game_lobby_start()
		GM.room_goto(gm.constants.rSelect)
		add_message("Going into Eclipse gamemode", ConsoleColours.green)
	end
end)
add_command("log_environment_cam_get", function(args)
	local oLogMenu = Instance.find(gm.constants.oLogMenu)
	if oLogMenu:exists() then
		local s = tostring(math.floor(oLogMenu.environment_cam_x))..", "..tostring(math.floor(oLogMenu.environment_cam_y))
		add_message("Copied "..s, ConsoleColours.blue.." to clipboard")
		GM.clipboard_set_text(s)
	else
		add_message("Only usable from log menu.", ConsoleColours.red)
	end
end)

local classes = {
	achievement			= "class_achievement",
	actor_skin			= "class_actor_skin",
	actor_state			= "class_actor_state",
	artifact			= "class_artifact",
	buff				= "class_buff",
	difficulty			= "class_difficulty",
	elite				= "class_elite",
	ending				= "class_ending_type",
	environment_log		= "class_environment_log",
	equipment			= "class_equipment",
	gamemode			= "class_game_mode",
	interactable_card	= "class_interactable_card",
	item				= "class_item",
	item_log			= "class_item_log",
	monster_card		= "class_monster_card",
	monster_log			= "class_monster_log",
	skill				= "class_skill",
	stage				= "class_stage",
	survivor			= "class_survivor",
	survivor_log		= "class_survivor_log",
}

add_command("find (class) (pattern)", function(args)
	local class_name = args[1]
	local pattern = args[2]
	if #args < 1 or (not classes[class_name] and class_name ~= "*") then
		add_message("(class) must be one of the following:", ConsoleColours.blue)
		for k, v in pairs(classes) do
			add_message("    "..k, ConsoleColours.blue)
		end
		return
	end
	if #args < 2 then
		add_message("Enter a pattern", ConsoleColours.blue)
		return
	end
	local string = ""
	local results = 0
	local linecount = 1
	for k, v in pairs(classes) do
		if k == class_name or class_name == "*" then
			local arr = GM.variable_global_get(classes[k])

			local count = GM.variable_global_get("count_"..k)
			if not count then count = #arr end

			local substring = ""
			for i=1, count do
				local class = arr[i]
				if type(class) == "table" then
					local namespace = string.lower(class[1])
					local identifier = string.lower(class[2])
					if pattern == "*" or namespace:match(pattern) or identifier:match(pattern) then
						substring = substring.."    ["..tostring(i-1).."]"
						substring = substring.." : "
						substring = substring..class[1].."-"..class[2]
						substring = substring.."\n"
						results = results + 1
						linecount = linecount + 1
					end
				elseif pattern == "*" then
					substring = substring.."["..tostring(i-1).."] : -empty-\n"
					linecount = linecount + 1
				end
			end
			if substring ~= "" then
				string = string..""..string.upper(k)..":\n"
				string = string..substring
			end
		end
	end
	string = "> found "..tostring(results).." results\n"..string

	add_message(string, ConsoleColours.blue)
	log.info(string)
	if linecount > 40 then
		add_message("note: if the info displayed is too long, the results are also logged to LogOutput.txt", ConsoleColours.blue)
	end
end)

add_command("set_gold (amount)", function(args)
	local oHUD = GM._mod_game_getHUD()
	if oHUD ~= -4 then
		local g = tonumber(args[1])
		if g then
			oHUD.gold = g
			add_message("Set gold to "..args[1], ConsoleColours.green)
		else
			add_message("Invalid input.", ConsoleColours.red)
		end
	else
		add_message("You must be in-game to use this command", ConsoleColours.blue)
	end
end)
