if type(ScriptHawk) ~= "table" then
	print("This script is not designed to run by itself");
	print("Please run ScriptHawk.lua from the parent directory instead");
	print("Thanks for using ScriptHawk :)");
	return;
end

local Game = {
	speedy_speeds = { .001, .01, .1, 1, 5, 10, 20, 50, 100 },
	speedy_invert_XZ = true,
	speedy_index = 7,
	rot_speed = 100,
	max_rot_units = 65535,
	Memory = { -- Version order: PAL 1.1, PAL 1.0, Japan, US 1.1, US 1.0
		["CSS_character"] = {0x126A18, 0x126478, 0x127F18, 0x126988, 0x1263E8}, -- Character select screen
		["CSS_vehicle"] = {0x127010, 0x126A50, 0x128508, 0x126F80, 0x1269C0}, -- Track select screen
		["game_settings"] = {0x123B20, 0x1235A0, 0x124F80, 0x123A90, 0x123510}, -- Pointer
		["is_paused"] = {0x123B25, 0x1235A5, 0x124F85, 0x123A95, 0x123515}, -- Byte
		["show_results"] = {0x123B26, 0x1235A6, 0x124F86, 0x123A96, 0x123516}, -- Byte
		["get_ready"] = {0x11B3C3, 0x11AE43, 0x11C823, 0x11B333, 0x11ADB3}, -- Byte?
		["cheats_enabled"] = {0x0E03A8, 0x0DFE28, 0x0E17F8, 0x0E0318, 0x0DFD98}, -- Bitfield u32_be
		["cheat_menu"] = {0x0E03AC, 0x0DFE2C, 0x0E17FC, 0x0E031C, 0x0DFD9C}, -- Bitfield u32_be
		["pointer_list"] = {0x11B468, 0x11AEE8, 0x11C8C8, 0x11B3D8, 0x11AE58},
		["num_objects"] = {0x11B46C, 0x11AEEC, 0x11C8CC, 0x11B3DC, 0x11AE5C},
	},
	maps = {
		"0x00 - Overworld",
		"0x01 - Bluey 1",
		"0x02 - Dragon Forest (Hub)",
		"0x03 - Fossil Canyon",
		"0x04 - Pirate Lagoon",
		"0x05 - Ancient lake",
		"0x06 - Walrus Cove",
		"0x07 - Hot Top Volcano",
		"0x08 - Whale Bay",
		"0x09 - Snowball Valley",
		"0x0A - Crescent Island",
		"0x0B - Fire Mountain",
		"0x0C - Dino Domain (Hub)",
		"0x0D - Everfrost Peak",
		"0x0E - Sherbert Island (Hub)",
		"0x0F - Spaceport Alpha",

		"0x10 - Horseshoe Gulch (Unused)",
		"0x11 - Spacedust Alley",
		"0x12 - Greenwood Village",
		"0x13 - Boulder Canyon",
		"0x14 - Windmill Plains",
		"0x15 - Intro",
		"0x16 - Character Select",
		"0x17 - Title Screen",
		"0x18 - Snowflake Mountain",
		"0x19 - Smokey Castle",
		"0x1A - Darkwater Beach",
		"0x1B - Icicle Pyramid",
		"0x1C - Frosty Village",
		"0x1D - Jungle Falls",
		"0x1E - Treasure Caves",
		"0x1F - Haunted Woods",

		"0x20 - Darkmoon Caverns",
		"0x21 - Star City",
		"0x22 - Trophy Race Results Screen",
		"0x23 - Future Fun Land (Hub)",
		"0x24 - Overworld (Opening Cutscene)",
		"0x25 - Wizpig 1",
		"0x26 - Dino 1",
		"0x27 - Menu Screen",
		"0x28 - Bubbler 1",
		"0x29 - Smokey 1",
		"0x2A - Overworld (Wizpig 1 opening cutscene)",
		"0x2B - Wizpig amulet cutscene",
		"0x2C - TT amulet cutscene",
		"0x2D - Overworld (FFL opening cutscene)",
		"0x2E - Dino 2",
		"0x2F - Dino Trophy",

		"0x30 - Snowflake Trophy",
		"0x31 - Sherbert Trophy",
		"0x32 - Dragon Trophy",
		"0x33 - FFL Trophy",
		"0x34 - Bluey 2",
		"0x35 - Bubbler 2",
		"0x36 - Smokey 2",
		"0x37 - Wizpig 2",
		"0x38 - Overworld (Fake credits)",
		"0x39 - Tricky's map (cutscene version)",
		"0x3A - Smokey's map (cutscene version)",
		"0x3B - Bluey's map (cutscene version)",
		"0x3C - Wizpig 1 cutscene",
		"0x3D - Bubbler's map (cutscene version)",
		"0x3E - Wizpig 2 cutscene",
		"0x3F - Overworld (Credits 1)",

		"0x40 - Overworld (Credits 2)",
		-- Anything higher sends the player to the overworld
	},
};

local player_object_pointer = 0x3FFFC0; -- Seems to be the same for all versions

function Game.getPlayerObject(player)
	player = player or 1;
	return dereferencePointer(player_object_pointer + (player - 1) * 4);
end

local currentPointers = {};
local object_index = 1; -- TODO: Grab script stuff up top for because of reasons, fix w/refactor please

local function incrementObjectIndex()
	object_index = object_index + 1;
	if object_index > #currentPointers then
		object_index = 1;
	end
end

local function decrementObjectIndex()
	object_index = object_index - 1;
	if object_index <= 0 then
		object_index = #currentPointers;
	end
end

local object_analysis_tools_modes = {
	"Disabled",
	"List",
	"Examine",
};
local object_analysis_tools_mode_index = 1;
local object_analysis_tools_mode = object_analysis_tools_modes[object_analysis_tools_mode_index];

local function switchObjectAnalysisToolsMode()
	object_analysis_tools_mode_index = object_analysis_tools_mode_index + 1;
	if object_analysis_tools_mode_index > #object_analysis_tools_modes then
		object_analysis_tools_mode_index = 1;
	end
	object_analysis_tools_mode = object_analysis_tools_modes[object_analysis_tools_mode_index];
end

-- Relative to objects in pointer list
local object_fields = {
	["x_pos"] = 0x0C, -- Float
	["y_pos"] = 0x10, -- Float
	["z_pos"] = 0x14, -- Float
	["y_velocity"] = 0x20, -- Float
	["object_descriptor_pointer"] = 0x40, -- Pointer
	["object_descriptor"] = {
		["name"] = 0x60, -- Null terminated string
	},
	["map_color"] = 0x9B, -- Byte
	["velocity"] = 0xC4, -- Float
	["lateral_velocity"] = 0xC8, -- Float
	["wheel_array_pointer"] = 0x60, -- Pointer
	["wheel_array"] = {
		["size"] = 0x00, -- u32_be
		["array_base"] = 0x04, -- Array of wheel object pointers
		["wheel"] = {
			["size"] = 0x08, -- Float
		},
	},
	["camera_zoom"] = 0x12C, -- Float
	["throttle"] = 0x14C, -- Float 0-1
	["spin_timer"] = 0x206, -- s16_be
	["powerup_color"] = 0x20A, -- Byte, 0-4
	["powerup_colors"] = {
		[0x00] = "Blue",
		[0x01] = "Red",
		[0x02] = "Green",
		[0x03] = "Yellow",
		[0x04] = "Rainbow",
	},
	["powerup_quantity"] = 0x20B, -- Byte, Max 10
	["powerup_level"] = 0x20C, -- Byte, 0-2
	["bananas"] = 0x21D, -- s8, capped at 99
	["x_rot"] = 0x23A, -- 16_be
	["y_rot"] = 0x238, -- 16_be
	["facing_angle"] = 0x238, -- 16_be
	["z_rot"] = 0x23C, -- 16_be
	["boost_timer"] = 0x26B, -- s8
	["silver_coins"] = 0x29A,
};

-- Game settings fields, relative to dereferencePointer(Game.Memory.game_settings[version])
game_settings_fields = {
	keys_collected = 0x08, -- u16_be? bitfield
	bosses_beaten = 0x0D, -- byte? bitfield
	trophies_collected = 0x0E, -- u16_be? bitfield
	tt_amulet_pieces = 0x16, -- u8
	wizpig_amulet_pieces = 0x17, -- u8
	balloons = 0x1C, -- u8
	map = 0x49, -- Byte
	p1_character = 0x59, -- Byte
	p2_character = 0x71, -- Byte
	p3_character = 0x89, -- Byte
	p4_character = 0xA1, -- Byte
	p5_character = 0xB9, -- Byte
	p6_character = 0xD1, -- Byte
	p7_character = 0xE9, -- Byte
	p8_character = 0x101, -- Byte
};

-- Boost size: 0x90
-- Checkpoint size: 0xB0
-- exit size: 0xD0
-- Flowers size: 0xE0
-- LevelDoor size: 0x1F0
-- setuppoint size: 0x90
-- WorldGate size: 0x1E0

local cars = { -- Indexed by character
	[0] = "KremCar",
	[1] = "BadgerCar",
	[2] = "TortCar",
	[3] = "ConkaCar",
	[4] = "TigerCar",
	[5] = "BanjoCar",
	[6] = "ChickenCar",
	[7] = "MouseCar",
	[8] = "SWcar", -- TT
	[9] = "diddycar",
};

local hovers = {
	[0] = "KremlinHover",
	[1] = "BadgerHover",
	[2] = "TortHover",
	[3] = "ConkaHover",
	[4] = "TigerHover",
	[5] = "BanjoHover",
	[6] = "ChickenHover",
	[7] = "MouseHover",
	[8] = "ticktockhover",
	[9] = "diddyhover",
};

local planes = {
	[0] = "KremPlane",
	[1] = "BadgerPlane",
	[2] = "TortPlane",
	[3] = "Conka",
	[4] = "TigPlane",
	[5] = "BanjoPlane",
	[6] = "ChickenPlane",
	[7] = "MousePlane",
	[8] = "ticktockplane",
	[9] = "diddyplane",
};

local function isVehicle(objectBase)
	local name = getObjectName(objectBase);
	return table.contains(cars, name) or table.contains(hovers, name) or table.contains(planes, name); -- TODO: Faster method of detection, object size?
end

function getExamineData(objectBase)
	local examineData = {};
	if isRDRAM(objectBase) then
		table.insert(examineData, {getObjectName(objectBase), toHexString(objectBase, 6)});
		table.insert(examineData, {"Descriptor", toHexString(mainmemory.read_u32_be(objectBase + object_fields.object_descriptor_pointer), 8)});
		table.insert(examineData, {"isVehicle", tostring(isVehicle(objectBase))});
		table.insert(examineData, {"Separator", 1});

		table.insert(examineData, {"X Position", mainmemory.readfloat(objectBase + object_fields.x_pos, true)});
		table.insert(examineData, {"Y Position", mainmemory.readfloat(objectBase + object_fields.y_pos, true)});
		table.insert(examineData, {"Z Position", mainmemory.readfloat(objectBase + object_fields.z_pos, true)});
		table.insert(examineData, {"Separator", 1});

		if isVehicle(objectBase) then
			table.insert(examineData, {"X Rotation", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(objectBase + object_fields.x_rot))});
			table.insert(examineData, {"Y Rotation", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(objectBase + object_fields.y_rot))});
			table.insert(examineData, {"Z Rotation", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(objectBase + object_fields.z_rot))});
			table.insert(examineData, {"Separator", 1});

			table.insert(examineData, {"Velocity", mainmemory.readfloat(objectBase + object_fields.velocity, true)});
			table.insert(examineData, {"Lateral Velocity", mainmemory.readfloat(objectBase + object_fields.lateral_velocity, true)});
			table.insert(examineData, {"Y Velocity", mainmemory.readfloat(objectBase + object_fields.y_velocity, true)});
			table.insert(examineData, {"Separator", 1});

			table.insert(examineData, {"Map Color", mainmemory.readbyte(objectBase + object_fields.map_color)});
			table.insert(examineData, {"Wheel Array", toHexString(mainmemory.read_u32_be(objectBase + object_fields.wheel_array_pointer), 8)});
			table.insert(examineData, {"Separator", 1});
		end
	end
	return examineData;
end

local function get_slot_base(pointerList, index)
	return dereferencePointer(pointerList + (index * 4));
end

-- Populate and sort pointer list
function populateObjectPointerList()
	currentPointers = {};
	local pointerList = dereferencePointer(Game.Memory.pointer_list[version]);
	if not isRDRAM(pointerList) then
		return;
	end
	local num_slots = mainmemory.read_u32_be(Game.Memory.num_objects[version]);
	for i = 0, num_slots - 1 do
		local slotBase = get_slot_base(pointerList, i);
		if isRDRAM(slotBase) and slotBase ~= playerObject then
			table.insert(currentPointers, slotBase);
		end
	end
	table.sort(currentPointers);
end

local map_freeze_values = {};

--------------------
-- Region/Version --
--------------------

function Game.detectVersion(romName, romHash)
	if romHash == "B7F628073237B3D211D40406AA0884FF8FDD70D5" then -- Europe 1.1
		version = 1;
		map_freeze_values = {
			0x121777, 0x123B07 -- TODO: Double check these
		};
	elseif romHash == "DD5D64DD140CB7AA28404FA35ABDCABA33C29260" then -- Europe 1.0
		version = 2;
		map_freeze_values = {
			0x11AF3B, 0x1211F7, 0x1212E2, 0x123587, 0x206BB5, 0x206C3B -- TODO: Double check these
		};
	elseif romHash == "23BA3D302025153D111416E751027CEF11213A19" then -- Japan
		version = 3;
		map_freeze_values = {
			0x11C91B, 0x122BD7, 0x122CC2, 0x124F67, 0x1FD4A5, 0x1FD52B -- TODO: Double check these
		};
	elseif romHash == "6D96743D46F8C0CD0EDB0EC5600B003C89B93755" then -- USA 1.1
		version = 4;
		map_freeze_values = {
			0x1216E7, 0x123A77 -- TODO: Double check these
		};
	elseif romHash == "0CB115D8716DBBC2922FDA38E533B9FE63BB9670" then -- USA 1.0
		version = 5;
		map_freeze_values = {
			0x121167, 0x121252, 0x1234F7 -- TODO: Double check these
		};
	else
		return false;
	end

	return true;
end

-------------------
-- Physics/Scale --
-------------------

function Game.getCharacter(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readbyte(playerObject + object_fields.map_color);
	end
	return 8; -- Default is TT, of course
end

local charToCSS = { -- Table to convert character selection screen index to in game character index
	[0] = 0, -- Krunch
	[9] = 1, -- Diddy
	[1] = 2, -- Bumper
	[5] = 3, -- Banjo
	[3] = 4, -- Conker
	[2] = 5, -- Tiptup
	[7] = 6, -- Pipsy
	[4] = 7, -- Timber
	[6] = 8, -- Drumstick
	[8] = 9, -- T. T.
};

function Game.setCharacter(index, player)
	player = player or 1;
	mainmemory.writebyte(Game.Memory.CSS_character[version] + player - 1, charToCSS[index] or 9);
	local gameSettings = dereferencePointer(Game.Memory.game_settings[version]);
	if isRDRAM(gameSettings) then
		mainmemory.writebyte(gameSettings + game_settings_fields.p1_character + ((player - 1) * 0x18), index);
	end
end

function Game.getVelocity(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.velocity, true);
	end
	return 0;
end

function Game.setVelocity(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + object_fields.velocity, value, true);
	end
end

local previous_velocity = 0;
local current_velocity = 0;
function Game.getAcceleration(player)
	return current_velocity - previous_velocity;
end

function Game.getLateralVelocity(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.lateral_velocity, true);
	end
	return 0;
end

function Game.setLateralVelocity(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + object_fields.lateral_velocity, value, true);
	end
end

function Game.getSpinTimer(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.read_s16_be(playerObject + object_fields.spin_timer);
	end
	return 0;
end

function Game.colorSpinTimer()
	local spinTimer = Game.getSpinTimer();
	spinTimer = math.abs(spinTimer);
	spinTimer = math.min(spinTimer, 80);
	spinTimer = spinTimer / 80;
	if spinTimer == 0 then
		return 0xFFFFFFFF; -- White
	end
	return getColor(spinTimer);
end

function Game.getYVelocity(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.y_velocity, true);
	end
	return 0;
end

function Game.setYVelocity(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + object_fields.y_velocity, value, true);
	end
end

function Game.getBoost(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.read_s8(playerObject + object_fields.boost_timer);
	end
	return 0;
end

function Game.getThrottle(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.throttle, true);
	end
	return 0;
end

function Game.getBananas(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.read_s8(playerObject + object_fields.bananas);
	end
	return 0;
end

function Game.setBananas(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writebyte(playerObject + object_fields.bananas, value);
	end
end

--------------
-- Position --
--------------

function Game.getXPosition(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.x_pos, true);
	end
	return 0;
end

function Game.getYPosition(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.y_pos, true);
	end
	return 0;
end

function Game.getZPosition(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + object_fields.z_pos, true);
	end
	return 0;
end

function Game.setXPosition(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + object_fields.x_pos, value, true);
		local wheelArray = dereferencePointer(playerObject + object_fields.wheel_array_pointer);
		if isRDRAM(wheelArray) then
			local wheelArraySize = mainmemory.read_u32_be(wheelArray + object_fields.wheel_array.size);
			for i = 0, wheelArraySize do
				local wheel = dereferencePointer(wheelArray + object_fields.wheel_array.array_base + i * 4);
				if isRDRAM(wheel) then
					--print("Wheel "..i..": "..toHexString(wheel));
				end
			end
		end
	end
end

function Game.setYPosition(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + object_fields.y_pos, value, true);
		Game.setYVelocity(0);
	end
end

function Game.setZPosition(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + object_fields.z_pos, value, true);
	end
end

--------------
-- Rotation --
--------------

function Game.getXRotation(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.read_u16_be(playerObject + object_fields.x_rot);
	end
	return 0;
end

function Game.getYRotation(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.read_u16_be(playerObject + object_fields.facing_angle);
	end
	return 0;
end

function Game.getZRotation(player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		return mainmemory.read_u16_be(playerObject + object_fields.z_rot);
	end
	return 0;
end

function Game.setXRotation(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.write_u16_be(playerObject + object_fields.x_rot, value);
	end
end

function Game.setYRotation(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.write_u16_be(playerObject + object_fields.facing_angle, value);
	end
end

function Game.setZRotation(value, player)
	local playerObject = Game.getPlayerObject(player);
	if isRDRAM(playerObject) then
		mainmemory.write_u16_be(playerObject + object_fields.z_rot, value);
	end
end

----------------------------------------
-- Optimal tapping script             --
-- Written by Faschz, 2015            --
-- Enhancements by Isotarge 2015-2017 --
----------------------------------------

-- Boost Thresholds
local get_ready_yellow_max = 36;
local get_ready_yellow_min = 20;
local get_ready_blue_max = 18;
local get_ready_blue_min = 6;

-- Blue
local function increase_get_ready_blue_max()
	get_ready_blue_max = math.min(80, get_ready_blue_max + 1);
end

local function decrease_get_ready_blue_max()
	get_ready_blue_max = math.max(0, get_ready_blue_max - 1);
end

local function increase_get_ready_blue_min()
	get_ready_blue_min = math.min(80, get_ready_blue_min + 1);
end

local function decrease_get_ready_blue_min()
	get_ready_blue_min = math.max(0, get_ready_blue_min - 1);
end

-- Yellow
local function increase_get_ready_yellow_max()
	get_ready_yellow_max = math.min(80, get_ready_yellow_max + 1);
end

local function decrease_get_ready_yellow_max()
	get_ready_yellow_max = math.max(0, get_ready_yellow_max - 1);
end

local function increase_get_ready_yellow_min()
	get_ready_yellow_min = math.min(80, get_ready_yellow_min + 1);
end

local function decrease_get_ready_yellow_min()
	get_ready_yellow_min = math.max(0, get_ready_yellow_min - 1);
end

local otap_enabled = false;
local otap_startFrame;
local otap_startLag;

-- Velocity writes
-- 0x800519B4 - Scale velocity down to character specific top speed
-- 0x80051EC0 - Main velocity write (forward)
-- 0x80051F30
-- 0x800520D4

-- Threshold for switching between A press modulo
--velocity_min = -9.212730408;
--velocity_med = -12.34942532;
--velocity_max = -14.22209072;

velocity_min = {[0] = -9.39,  [1] = -9.44,  [2] = -9.44,  [3] = -9.44,  [4] = -9.44,  [5] = -9.44,  [6] = -9.44,  [7] = -9.44,  [8] = -9.44,  [9] = -9.44,  [10] = -9.44};
velocity_med = {[0] = -13.16, [1] = -13.17, [2] = -13.17, [3] = -13.17, [4] = -13.17, [5] = -13.17, [6] = -13.17, [7] = -13.17, [8] = -13.17, [9] = -13.17, [10] = -13.17};
velocity_max = {[0] = -13.29, [1] = -13.28, [2] = -13.28, [3] = -13.28, [4] = -13.28, [5] = -13.28, [6] = -13.28, [7] = -13.28, [8] = -13.28, [9] = -13.28, [10] = -13.28};

function adjustVelMin(value, bananas)
	velocity_min[bananas] = velocity_min[bananas] + value;
	velocity_min[bananas] = math.min(0, velocity_min[bananas]); -- Clamp to 0
	velocity_min[bananas] = math.max(velocity_med[bananas], velocity_min[bananas]); -- Clamp to velocity_med
end

function adjustVelMed(value, bananas)
	velocity_med[bananas] = velocity_med[bananas] + value;
	velocity_med[bananas] = math.min(velocity_min[bananas], velocity_med[bananas]); -- Clamp to velocity_min
	velocity_med[bananas] = math.max(velocity_max[bananas], velocity_med[bananas]); -- Clamp to velocity_max
end

function adjustVelMax(value, bananas)
	velocity_max[bananas] = velocity_max[bananas] + value;
	velocity_max[bananas] = math.min(velocity_max[bananas], velocity_med[bananas]); -- Clamp to velocity_med
end

function dumpVelocityValues()
	return "min: "..round(velocity_min[bananas], 3).." med: "..round(velocity_med[bananas], 3).." max: "..round(velocity_max[bananas], 3);
end

local function enableOptimalTap()
	otap_startFrame = emu.framecount();
	otap_startLag = emu.lagcount();
	otap_enabled = true;
	print("Auto tapper (by Faschz) enabled.");
end

local function disableOptimalTap()
	otap_enabled = false;
	print("Auto tapper (by Faschz) disabled.");
end

local function optimalTap()
	local velocity = Game.getVelocity();
	local character = Game.getCharacter();
	local bananas = math.max(math.min(Game.getBananas(), 10), 0);
	local boost = Game.getBoost();
	local getReady = mainmemory.readbyte(Game.Memory.get_ready[version]);
	local isPaused = mainmemory.readbyte(Game.Memory.is_paused[version]);
	local showResults = mainmemory.readbyte(Game.Memory.show_results[version]);

	local boostType = forms.getproperty(ScriptHawk.UI.form_controls.otap_boost_dropdown, "SelectedItem");

	-- Don't press A if we're paused
	if isPaused ~= 0 then -- TODO: This check isn't perfect, it's still possible that it'll tap A and close the menu, I think we need a menu object pointer or something
		--print("Don't press A, we're paused.");
		return;
	end

	-- Don't press A if the race is finished
	if showResults ~= 0 then
		return;
	end

	-- Don't press A if we're boosting
	if boost > 0 then
		return;
	end

	-- Get a zipper at the start of the race
	if getReady ~= 0 and boostType ~= "None" then
		local boostMin = 0;
		local boostMax = 0;

		if boostType == "Blue" then
			boostMin = get_ready_blue_min;
			boostMax = get_ready_blue_max;
		elseif boostType == "Yellow" then
			boostMin = get_ready_yellow_min;
			boostMax = get_ready_yellow_max;
		end

		local shouldWeTap = getReady >= boostMin and getReady <= boostMax and boost == 0;
		joypad.set({["A"] = shouldWeTap}, 1);
		return;
	end

	-- Bot taps A once every modulo frames
	local modulo = 1;
	if velocity >= velocity_min[bananas] then
		modulo = 1;
	elseif velocity >= velocity_med[bananas] and velocity < velocity_min[bananas] then
		modulo = 2;
	elseif velocity >= velocity_max[bananas] and velocity < velocity_med[bananas] then
		modulo = 3;
	elseif velocity < velocity_max[bananas] then
		modulo = 4;
	end

	local shouldWeTap = (emu.framecount() - (otap_startFrame + (emu.lagcount() - otap_startLag))) % modulo == 0;
	joypad.set({["A"] = shouldWeTap}, 1);
end

--------------------
-- Boost analysis --
--------------------

local boostFrames = 0;

local function outputBoostStats()
	if Game.isPhysicsFrame() and forms.ischecked(ScriptHawk.UI.form_controls.boost_info_checkbox) then
		local boost = Game.getBoost();
		local getReady = mainmemory.readbyte(Game.Memory.get_ready[version]);
		if boost > 0 and getReady == 0 then
			local aPressed = joypad.getimmediate()["P1 A"];
			if aPressed then
				print("Frame: "..boostFrames.." Boost: "..boost.." (A Pressed)");
			else
				print("Frame: "..boostFrames.." Boost: "..boost);
			end
			boostFrames = boostFrames + 1;
		else
			if boostFrames > 0 then
				print("Boost ended");
			end
			boostFrames = 0;
		end
	end
end

--------------
-- Encircle --
--------------

local radius = 1000;

local function encircle_player(player)
	local playerObject = Game.getPlayerObject(player);
	if not isRDRAM(playerObject) then
		return;
	end

	local playerX = Game.getXPosition();
	local playerY = Game.getYPosition();
	local playerZ = Game.getZPosition();
	local x, z;

	-- Iterate and set position
	for i = 1, #currentPointers do
		x = playerX + math.cos(math.pi * 2 * i / #currentPointers) * radius;
		z = playerZ + math.sin(math.pi * 2 * i / #currentPointers) * radius;

		mainmemory.writefloat(currentPointers[i] + object_fields.x_pos, x, true);
		mainmemory.writefloat(currentPointers[i] + object_fields.y_pos, playerY, true);
		mainmemory.writefloat(currentPointers[i] + object_fields.z_pos, z, true);
	end
end

function getObjectName(objectBase) -- TODO: Cache descriptor
	if isRDRAM(objectBase) then
		local objectDescriptor = dereferencePointer(objectBase + object_fields.object_descriptor_pointer);
		if isRDRAM(objectDescriptor) then
			return readNullTerminatedString(objectDescriptor + object_fields.object_descriptor.name);
		end
	end
	return "Unknown";
end

function checkFor(objectName)
	for i = 1, #currentPointers do
		if getObjectName(currentPointers[i]) == objectName then
			print("Found "..objectName.." at "..toHexString(currentPointers[i], 6));
		end
	end
end

local function drawAnalysisToolsOSD()
	if object_analysis_tools_mode == "Disabled" then
		return;
	end
	local row = 0;
	local playerObject = Game.getPlayerObject();

	gui.text(Game.OSDPosition[1], 0 + Game.OSDRowHeight * row, "Index: "..object_index.."/"..#currentPointers, nil, 'bottomright');
	row = row + 1;

	if object_analysis_tools_mode == "List" then
		row = row + 1;

		for i = #currentPointers, 1, -1 do
			local color = nil;
			if object_index == i then
				color = yellow_highlight;
			end
			if currentPointers[i] == playerObject then
				color = green_highlight;
			end
			gui.text(Game.OSDPosition[1], 0 + Game.OSDRowHeight * row, i..": "..getObjectName(currentPointers[i]).." "..toHexString(currentPointers[i] or 0, 6), color, 'bottomright');
			row = row + 1;
		end
	end

	if object_analysis_tools_mode == "Examine" then
		local examine_data = getExamineData(currentPointers[object_index]);
		for i = #examine_data, 1, -1 do
			if examine_data[i][1] ~= "Separator" then
				if type(examine_data[i][2]) == "number" then
					examine_data[i][2] = round(examine_data[i][2], precision);
				end
				gui.text(Game.OSDPosition[1], 0 + Game.OSDRowHeight * row, examine_data[i][2].." - "..examine_data[i][1], nil, 'bottomright');
				row = row + 1;
			else
				row = row + examine_data[i][2];
			end
		end
	end
end

function zipToSelectedObject()
	if isRDRAM(currentPointers[object_index]) then
		-- Read the selected object's position
		local objectX = mainmemory.readfloat(currentPointers[object_index] + object_fields.x_pos, true);
		local objectY = mainmemory.readfloat(currentPointers[object_index] + object_fields.y_pos, true);
		local objectZ = mainmemory.readfloat(currentPointers[object_index] + object_fields.z_pos, true);

		-- Set the player position to the object
		Game.setXPosition(objectX);
		Game.setYPosition(objectY);
		Game.setZPosition(objectZ);
	end
end

ScriptHawk.bindMouse("mousewheelup", decrementObjectIndex);
ScriptHawk.bindMouse("mousewheeldown", incrementObjectIndex);
ScriptHawk.bindKeyRealtime("N", decrementObjectIndex, true);
ScriptHawk.bindKeyRealtime("M", incrementObjectIndex, true);
ScriptHawk.bindKeyRealtime("Z", zipToSelectedObject, true);
ScriptHawk.bindKeyRealtime("C", switchObjectAnalysisToolsMode, true);

------------
-- Events --
------------

function Game.setMap(value)
	value = value - 1;

	-- Legacy method of doing this, I hope to obsolete this one day
	for i = 1, #map_freeze_values do
		mainmemory.writebyte(map_freeze_values[i], value);
	end

	-- This write sets the menu options, much closer to what the game actually does
	local gameSettings = dereferencePointer(Game.Memory.game_settings[version]);
	if isRDRAM(gameSettings) then
		mainmemory.writebyte(gameSettings + game_settings_fields.map, value);
	end
end

function Game.applyInfinites()
	-- Unlock all magic code toggles
	mainmemory.write_u32_be(Game.Memory.cheat_menu[version], 0xFFFFFFFF);

	-- Turn on TT & Drumstick magic codes
	local cheatsEnabled = mainmemory.read_u32_be(Game.Memory.cheats_enabled[version]);
	cheatsEnabled = setBit(cheatsEnabled, 0); -- TT
	cheatsEnabled = setBit(cheatsEnabled, 1); -- Drumstick
	mainmemory.write_u32_be(Game.Memory.cheats_enabled[version], cheatsEnabled);

	-- Player object bizzo
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		mainmemory.writebyte(playerObject + object_fields.bananas, 10);
		mainmemory.writebyte(playerObject + object_fields.powerup_quantity, 1);
		--mainmemory.write_s8(playerObject + object_fields.boost_timer, 1);
		mainmemory.writebyte(playerObject + object_fields.silver_coins, 8);
	end
end

function Game.initUI()
	ScriptHawk.UI.form_controls.boost_info_checkbox = forms.checkbox(ScriptHawk.UI.options_form, "Boost info", ScriptHawk.UI.col(5) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(4) + ScriptHawk.UI.dropdown_offset);
	ScriptHawk.UI.form_controls.encircle_checkbox = forms.checkbox(ScriptHawk.UI.options_form, "Encircle (beta)", ScriptHawk.UI.col(5) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(5) + ScriptHawk.UI.dropdown_offset);

	ScriptHawk.UI.form_controls.otap_checkbox = forms.checkbox(ScriptHawk.UI.options_form, "Auto tapper", ScriptHawk.UI.col(0) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(6) + ScriptHawk.UI.dropdown_offset);
	ScriptHawk.UI.form_controls.otap_boost_dropdown = forms.dropdown(ScriptHawk.UI.options_form, {"Yellow", "Blue", "None"}, ScriptHawk.UI.col(0) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(7) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.col(4), ScriptHawk.UI.button_height);

	local blue_col_base = 5;
	local yellow_col_base = 11;

	-- Boost Threshold, blue min
	ScriptHawk.UI.form_controls.get_ready_blue_min_label = forms.label(ScriptHawk.UI.options_form, "BMin:", ScriptHawk.UI.col(blue_col_base), ScriptHawk.UI.row(6) + ScriptHawk.UI.label_offset, 40, 14);
	ScriptHawk.UI.form_controls.decrease_get_ready_blue_min_button = forms.button(ScriptHawk.UI.options_form, "-", decrease_get_ready_blue_min, ScriptHawk.UI.col(blue_col_base + 3) - 28, ScriptHawk.UI.row(6), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.increase_get_ready_blue_min_button = forms.button(ScriptHawk.UI.options_form, "+", increase_get_ready_blue_min, ScriptHawk.UI.col(blue_col_base + 4) - 28, ScriptHawk.UI.row(6), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.get_ready_blue_min_value_label = forms.label(ScriptHawk.UI.options_form, get_ready_blue_min, ScriptHawk.UI.col(blue_col_base + 4), ScriptHawk.UI.row(6) + ScriptHawk.UI.label_offset, 32, 14);

	-- Boost Threshold, blue max
	ScriptHawk.UI.form_controls.get_ready_blue_max_label = forms.label(ScriptHawk.UI.options_form, "BMax:", ScriptHawk.UI.col(blue_col_base), ScriptHawk.UI.row(7) + ScriptHawk.UI.label_offset, 40, 14);
	ScriptHawk.UI.form_controls.decrease_get_ready_blue_max_button = forms.button(ScriptHawk.UI.options_form, "-", decrease_get_ready_blue_max, ScriptHawk.UI.col(blue_col_base + 3) - 28, ScriptHawk.UI.row(7), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.increase_get_ready_blue_max_button = forms.button(ScriptHawk.UI.options_form, "+", increase_get_ready_blue_max, ScriptHawk.UI.col(blue_col_base + 4) - 28, ScriptHawk.UI.row(7), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.get_ready_blue_max_value_label = forms.label(ScriptHawk.UI.options_form, get_ready_blue_max, ScriptHawk.UI.col(blue_col_base + 4), ScriptHawk.UI.row(7) + ScriptHawk.UI.label_offset, 32, 14);

	-- Boost Threshold, yellow min
	ScriptHawk.UI.form_controls.get_ready_yellow_min_label = forms.label(ScriptHawk.UI.options_form, "YMin:", ScriptHawk.UI.col(yellow_col_base), ScriptHawk.UI.row(6) + ScriptHawk.UI.label_offset, 40, 14);
	ScriptHawk.UI.form_controls.decrease_get_ready_yellow_min_button = forms.button(ScriptHawk.UI.options_form, "-", decrease_get_ready_yellow_min, ScriptHawk.UI.col(yellow_col_base + 3) - 28, ScriptHawk.UI.row(6), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.increase_get_ready_yellow_min_button = forms.button(ScriptHawk.UI.options_form, "+", increase_get_ready_yellow_min, ScriptHawk.UI.col(yellow_col_base + 4) - 28, ScriptHawk.UI.row(6), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.get_ready_yellow_min_value_label = forms.label(ScriptHawk.UI.options_form, get_ready_yellow_min, ScriptHawk.UI.col(yellow_col_base + 4), ScriptHawk.UI.row(6) + ScriptHawk.UI.label_offset, 32, 14);

	-- Boost Threshold, yellow max
	ScriptHawk.UI.form_controls.get_ready_yellow_max_label = forms.label(ScriptHawk.UI.options_form, "YMax:", ScriptHawk.UI.col(yellow_col_base), ScriptHawk.UI.row(7) + ScriptHawk.UI.label_offset, 40, 14);
	ScriptHawk.UI.form_controls.decrease_get_ready_yellow_max_button = forms.button(ScriptHawk.UI.options_form, "-", decrease_get_ready_yellow_max, ScriptHawk.UI.col(yellow_col_base + 3) - 28, ScriptHawk.UI.row(7), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.increase_get_ready_yellow_max_button = forms.button(ScriptHawk.UI.options_form, "+", increase_get_ready_yellow_max, ScriptHawk.UI.col(yellow_col_base + 4) - 28, ScriptHawk.UI.row(7), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls.get_ready_yellow_max_value_label = forms.label(ScriptHawk.UI.options_form, get_ready_yellow_max, ScriptHawk.UI.col(yellow_col_base + 4), ScriptHawk.UI.row(7) + ScriptHawk.UI.label_offset, 32, 14);
end

--[[
--Game.setPosition(-1740.12133789063, 28.9976959228516, -7824.4384765625);
--Game.setYRotation(32768);
testState = 0;
testSpace = {
	min = 0,
	med = 0,
	max = 0,
};
--]]

function Game.eachFrame()
	if Game.isPhysicsFrame() then
		previous_velocity = current_velocity;
		current_velocity = Game.getVelocity();
	end

	--Game.setCharacter(8, 1);
	--Game.setCharacter(8, 2);
	--Game.setCharacter(8, 3);
	--Game.setCharacter(8, 4);
	--Game.setCharacter(8, 5);
	--Game.setCharacter(8, 6);
	--Game.setCharacter(8, 7);
	--Game.setCharacter(8, 8);

	populateObjectPointerList();

	if not otap_enabled and forms.ischecked(ScriptHawk.UI.form_controls.otap_checkbox) then
		enableOptimalTap();
	end

	if otap_enabled and not forms.ischecked(ScriptHawk.UI.form_controls.otap_checkbox) then
		disableOptimalTap();
	end

	if otap_enabled then
		optimalTap();
	end

	if forms.ischecked(ScriptHawk.UI.form_controls.encircle_checkbox) then
		encircle_player();
	end

	outputBoostStats();

	--[[
	local velocity = Game.getVelocity();
	if velocity >= -12 then
		Game.setXPosition(-1740.12133789063);
		Game.setZPosition(-7824.4384765625);
	end

	local zPos = Game.getZPosition();
	if zPos >= -3800 then
		local character = Game.getCharacter();
		local bananas = math.max(math.min(Game.getBananas(), 10), 0);
		print("frame "..emu.framecount().." pos "..round(zPos, 3).." vel "..round(velocity, 3).." || "..dumpVelocityValues());
		adjustVelMin(testSpace.min, bananas);
		adjustVelMed(testSpace.med, bananas);
		adjustVelMax(testSpace.max, bananas);

		if velocity_min[bananas] >= 0 then
			print("Warning: Min "..velocity_min[bananas].." >= 0");
		end
		if velocity_med[bananas] >= 0 then
			print("Warning: Med "..velocity_med[bananas].." >= 0");
		end
		if velocity_max[bananas] >= 0 then
			print("Warning: Max "..velocity_max[bananas].." >= 0");
		end
		if velocity_min[bananas] <= velocity_med[bananas] then
			print("Warning: Min "..velocity_min[bananas].." <= Med "..velocity_med[bananas]);
		end
		if velocity_med[bananas] <= velocity_max[bananas] then
			print("Warning: Med "..velocity_med[bananas].." <= Max "..velocity_max[bananas]);
		end

		savestate.loadslot(testState);
	end
	--]]
end

function Game.drawUI()
	forms.settext(ScriptHawk.UI.form_controls.get_ready_blue_min_value_label, get_ready_blue_min);
	forms.settext(ScriptHawk.UI.form_controls.get_ready_blue_max_value_label, get_ready_blue_max);
	forms.settext(ScriptHawk.UI.form_controls.get_ready_yellow_min_value_label, get_ready_yellow_min);
	forms.settext(ScriptHawk.UI.form_controls.get_ready_yellow_max_value_label, get_ready_yellow_max);
	drawAnalysisToolsOSD();
end

Game.OSDPosition = {2, 70}
Game.OSD = {
	{"X", Game.getXPosition},
	{"Y", Game.getYPosition},
	{"Z", Game.getZPosition},
	{"Separator", 1},
	{"dY"},
	{"dXZ"},
	{"Separator", 1},
	{"Spin Timer", Game.getSpinTimer, Game.colorSpinTimer},
	{"Boost", Game.getBoost},
	{"Velocity", Game.getVelocity},
	{"Acceleration", Game.getAcceleration},
	{"Y Velocity", Game.getYVelocity},
	{"Lateral Velocity", Game.getLateralVelocity},
	--{"Lateral Acceleration", Game.getLateralAcceleration},
	{"Throttle", Game.getThrottle},
	{"Separator", 1},
	{"Max dY"},
	{"Max dXZ"},
	{"Odometer"},
	{"Separator", 1},
	{"Rot. X", Game.getXRotation},
	{"Facing", Game.getYRotation},
	--{"Moving", Game.getMovingRotation},
	{"Rot. Z", Game.getZRotation},
};

return Game;