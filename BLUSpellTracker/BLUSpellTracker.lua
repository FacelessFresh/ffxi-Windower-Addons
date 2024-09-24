_addon.name = 'BLUSpellTracker'
_addon.author = 'Faceless'
_addon.version = '8.675309'
_addon.commands = {'bs'}

local res = require('resources') -- Importing the resources library
local spells = require('spells') -- Table with spell data
local texts = require('texts') -- Importing the texts library for UI

local ui = {} -- To store our UI components
local known_spells = {} -- Known spells to be populated dynamically
local current_zone_id = windower.ffxi.get_info().zone
local player_zone_name = res.zones[current_zone_id].name
local player_name = windower.ffxi.get_player().name
local job = windower.ffxi.get_player().main_job

-- UI scale factors
local default_scale_factor = 1.0  -- Default scale factor
local scale_factor = default_scale_factor  -- Current scale factor

-- Default UI settings
local settings = {
    text = {font = 'Arial', size = 12 * scale_factor, color = {255, 255, 255, 255}},
    pos = {x = 100, y = 100},
    bg = {alpha = 128, red = 0, green = 0, blue = 0},
    flags = {bold = false, italic = false}
}

-- Create the UI window
ui.window = texts.new(settings)

-- Function to check if a spell is Blue Magic
local function is_blue_magic(spell_id)
    local spell = res.spells[spell_id]
    return spell and spell.type == 'BlueMagic'
end

-- Function to get the spell ID based on spell name
local function get_spell_id(spell_name)
    for id, spell in pairs(res.spells) do
        if spell.name == spell_name then
            return id
        end
    end
    return nil  -- Return nil if not found
end

-- Load the player's known Blue Magic spells
local function load_known_spells()
    known_spells = {} -- Clear previous known spells
    local player_spells = windower.ffxi.get_spells()
    for spell_id, is_known in pairs(player_spells) do
        if is_known and is_blue_magic(spell_id) then
            known_spells[spell_id] = true  -- Store by ID for easy lookup
        end
    end
end

-- Load spells user doesn't know in the zone
local function get_learnable_spells_in_zone(zone_id)
    local learnable_spells = {}

    -- Get the spells for the current zone
    local spells_in_zone = spells[zone_id] or {}
    
    -- Filter spells based on whether the player knows them
    for _, spell in ipairs(spells_in_zone) do
        local spell_id = get_spell_id(spell.name)  -- Get the ID from the helper function
        if spell_id and not known_spells[spell_id] then
            table.insert(learnable_spells, { 
                name = spell.name,
                level = spell.level,
                mob = spell.mob,
                location = spell.estimated_locations  -- Keep it for UI display
            })
        end
    end

    return learnable_spells
end

-- Function to update UI with zone info and spells
local function update_ui()
    local spells_in_zone = get_learnable_spells_in_zone(current_zone_id)
    
    if #spells_in_zone > 0 then
        -- Display UI with zone name, spell details, mobs, and locations
        local display_text = 'Zone: ' .. player_zone_name .. '\n'
        for _, spell in pairs(spells_in_zone) do
            display_text = display_text .. spell.name .. ' (Lv ' .. spell.level .. ')\n'
            display_text = display_text .. 'Mob: ' .. spell.mob .. '\n'
            display_text = display_text .. 'Location: ' .. table.concat(spell.location, ', ') .. '\n\n'  -- Convert table to string
        end

        -- Show the UI
        ui.window:text(display_text)
        ui.window:show()
    else
        ui.window:hide() -- Hide the UI if there are no spells to show
    end
end

-- Function to set the scale of the UI
local function set_scale(factor)
    scale_factor = factor
    local new_size = settings.text.size * scale_factor
    ui.window:size(new_size)
    windower.add_to_chat(207, "BLUSpellTracker: UI scale set to " .. tostring(factor))
    update_ui()  -- Refresh UI with new scale
end

-- Command to display help information
local function display_help()
    local help_text = [[
    BLUSpellTracker Commands:
    --------------------------
    //bs scale <factor>     - Set the scale of the UI (e.g., //bs scale 1.5)
    //bs scale r            - Reset the scale to the default size (1.0)
    //bs help               - Show this help message
    ]]
    windower.add_to_chat(207, help_text)  -- Display help message to the user
end

-- When the player changes zones
windower.register_event('zone change', function(new_id)
    current_zone_id = new_id
    player_zone_name = res.zones[current_zone_id].name
    update_ui()
end)

-- Listen for the incoming text (system messages) to detect when a spell is learned
windower.register_event('incoming text', function(original, modified, mode)
    -- Check if it's a system message with the correct mode
    if mode == 129 then
        -- Detect if the message indicates the player learned a spell
        local learning_message = player_name .. ' learns'
        if original:contains(learning_message) then
            -- Immediately load known spells and update UI
            load_known_spells()
            update_ui()
        end
    end
end)

-- Function to reset the UI scale to the original size (1.0)
local function reset_scale()
    scale_factor = 1.0
    settings.text.size = 12 * scale_factor  -- Reset to original font size
    ui.window:size(settings.text.size)  -- Update the window size
    windower.add_to_chat(207, "BLUSpellTracker: UI scale reset to default (1.0)")
    update_ui()  -- Refresh the UI
end

-- Command to change scale
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or ''

    if command == 'scale' then
        local scale_arg = args[1] and args[1]:lower() or ''
        if scale_arg == 'r' then
            reset_scale()  -- Call reset scale when 'r' is passed
        else
            local factor = tonumber(scale_arg)
            if factor then
                set_scale(factor)
            else
                windower.add_to_chat(167, "BLUSpellTracker: Invalid scale value. Usage: //bs scale <factor> or //bs scale r")
            end
        end
    elseif command == 'help' then
        display_help()  -- Show help information
    else
        windower.add_to_chat(167, "BLUSpellTracker: Unknown command. Type //bs help for a list of commands.")
    end
end)

-- When the addon loads
windower.register_event('load', function()
    -- Load known spells
    load_known_spells()

    -- Display initial data
    update_ui()
end)
