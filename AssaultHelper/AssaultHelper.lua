_addon.name = 'AssaultHelper'
_addon.author = 'Faceless'
_addon.version = '867530.1'
_addon.commands = {'assault', 'ah', 'assaulthelper', 'ass'}

-- Required Libraries

local res = require('resources') -- Importing the resources library
local assaulttable = require('AssaultTable')
local packets = require('packets')               -- Importing Packets
require('tables')                                -- Importing tables library for UI
local texts = require('texts') -- Importing the texts library for UI
config = require('config') -- Importing the config library for settings management

-- Global variables for current mission and zone
_G.current_mission_id = nil
_G.current_zone_id = nil
_G.wrap_limit = 50 -- Default wrap limit

-- Load saved settings
local settings = config.load(ui_settings)
local ui_settings = settings.pos and settings or defaults
local ui_settings = {
    text = {
        font = settings.text and settings.text.font or 'Arial', 
        size = settings.text and settings.text.size or 12, 
        color = settings.text and settings.text.color or { 255, 255, 255, 255 }
    },
    pos = settings.pos or { x = 200, y = 200 },
    bg = {
        alpha = settings.bg and settings.bg.alpha or 200,
        red = settings.bg and settings.bg.red or 0,
        green = settings.bg and settings.bg.green or 0,
        blue = settings.bg and settings.bg.blue or 0
    },
    width = settings.width or 300,
    height = settings.height or 150
}



-- Create the UI window with defined width
local ui_window = texts.new(ui_settings)

-- Utility function to write to a log file
local function write_log(content)
    local log_file_path = windower.addon_path .. 'parse_log.txt'  -- Change to your log file path
    local file = io.open(log_file_path, 'a')  -- Append mode
    if file then
        file:write(content)
        file:close()
    else
        print("Failed to open log file.")
    end
end

-- Utility function to log table data
local function log_table(t, indent)
    local log_content = ""
    indent = indent or 0
    for k, v in pairs(t) do
        local prefix = string.rep("  ", indent)
        if type(v) == "table" then
            log_content = log_content .. prefix .. k .. ":\n"
            log_content = log_content .. log_table(v, indent + 1)
        else
            log_content = log_content .. prefix .. k .. ": " .. tostring(v) .. "\n"
        end
    end
    return log_content
end

-- Function to display the UI
function display_assault_guide()
    local mission_id = _G.assault_mission_id  -- Only retrieve mission I
    local mission_info = assaulttable[mission_id]

	if mission_info then
		local header = mission_info.name  -- Only include the mission name
		local guide = mission_info.guide

		display_ui(header, guide)
	end
end

function justify_line(line, limit)
    local words = {}
    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end

    if #words == 0 then
        return line
    end

    local total_chars = 0
    for _, word in ipairs(words) do
        total_chars = total_chars + #word
    end

    local spaces_needed = limit - total_chars
    local gaps = #words - 1

    if gaps > 0 then
        local even_space = math.floor(spaces_needed / gaps)
        local extra_space = spaces_needed % gaps

        local justified_line = ""
        for i, word in ipairs(words) do
            justified_line = justified_line .. word
            if i < #words then
                justified_line = justified_line .. string.rep(" ", even_space + (i <= extra_space and 1 or 0))
            end
        end
        return justified_line
    else
        return line -- Return the line as is if there's no need for justification
    end
end

function justify_text(text, limit)
    if not text or type(text) ~= "string" then
        return "" -- Return an empty string if text is nil or not a string
    end

    local justified_text = ""
    local lines = {}

    -- Split the text into lines
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    for _, line in ipairs(lines) do
        local words = {}
        for word in line:gmatch("%S+") do
            table.insert(words, word)
        end

        local current_line = ""
        for _, word in ipairs(words) do
            if #current_line + #word + 1 > limit then
                justified_text = justified_text .. justify_line(current_line, limit) .. "\n"
                current_line = word
            else
                current_line = current_line .. (current_line ~= '' and ' ' or '') .. word
            end
        end

        if current_line ~= '' then
            justified_text = justified_text .. justify_line(current_line, limit) .. "\n"
        end
    end

    return justified_text
end
function display_ui(header, guide)
    local wrapped_text = ""

    -- Split the guide into separate lines based on the newlines
    local lines = {}
    for line in guide:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        local wrapped_line = word_wrap(line, _G.wrap_limit) -- Use the dynamic wrap limit
        wrapped_text = wrapped_text .. wrapped_line

        -- Only add a newline if the line is not empty
        if i < #lines or line ~= "" then
            wrapped_text = wrapped_text .. "\n"
        end
    end

    ui_window:text(header .. "\n\n" .. wrapped_text)
    ui_window:pos(ui_settings.pos.x, ui_settings.pos.y)
    ui_window:show()
end


function word_wrap(text, limit)
    limit = limit or 70  -- Default wrap length
    local wrapped_text = ''
    local words = {}

    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    local line = ''
    for _, word in ipairs(words) do
        if #line + #word + 1 > limit then
            wrapped_text = wrapped_text .. line .. "\n"
            line = word
        else
            line = line .. (line ~= '' and ' ' or '') .. word
        end
    end

    if line ~= '' then
        wrapped_text = wrapped_text .. line
    end

    return wrapped_text
end

-- Function to log packet data
local function log_packet_data(id, p)
    write_log('Packet ID: ' .. id .. '\n')
    write_log('Packet Data: ' .. log_table(p) .. '\n')  -- Use log_table for structured output
end

-- Function to handle packet parsing and trigger the UI
function on_packet_parsed(mission_id)
    _G.assault_mission_id = mission_id
    display_assault_guide() 
end

-- Register event to handle incoming packets
windower.register_event('incoming chunk', function(id, data)
    -- Packet ID 0x056 contains the assault mission data for when you accept and cancel Assault Missions
    if id == 0x056 then
        local p = packets.parse('incoming', data)
        _G.assault_mission_id = p['Current Assault Mission'] -- Store the mission ID globally
        local mission_id = _G.assault_mission_id

        -- Call the function to handle UI display
        on_packet_parsed(mission_id)
    end
end)

-- Variable to track setup mode
local setup_mode = false

-- Register mouse events for dragging
local dragging = false
local drag_offset = { x = 0, y = 0 }

windower.register_event('mouse', function(event, x, y)
    if event == 1 then -- Left mouse button down
        local width, height = ui_window:size()
        if x >= ui_settings.pos.x and x <= ui_settings.pos.x + width and
           y >= ui_settings.pos.y and y <= ui_settings.pos.y + height then
            dragging = true
            drag_offset.x = x - ui_settings.pos.x
            drag_offset.y = y - ui_settings.pos.y
        end
    elseif event == 2 then -- Left mouse button up
        dragging = false
    end
end)

-- Update position while dragging
windower.register_event('mouse', function(x, y)
    if dragging then
        ui_settings.pos.x = x - drag_offset.x
        ui_settings.pos.y = y - drag_offset.y
        ui_window:pos(ui_settings.pos.x, ui_settings.pos.y) -- Update position
    end
end)
local function display_help(special)
    if special then
		windower.add_to_chat(207, "AssaultHelper Special Help:\n" ..
                       "This version of the help provides additional context.\n" ..
                       "Use this add-on to assist with Assault Missions.\n\n" ..
                       "Commands:\n" ..
                       "//assault setwraplimit <number> - Set the word wrap limit.\n" ..
                       "//assault setfont <font name> - Set the font for the UI.\n" ..
                       "//assault setfontsize <size> - Set the font size.\n" ..
                       "//assault setopacity <value> - Set the background opacity (0-255).\n" ..
                       "//assault setup - Enter setup mode to adjust the UI.\n")
    else
        windower.add_to_chat(207, "AssaultHelper Help:\n" ..
                       "Use these commands to interact with the add-on:\n\n" ..
                       "//assault or //ah - Open the UI.\n" ..
                       "//assault help - Display this help information.\n" ..
                       "//assault setwraplimit <number> - Set the word wrap limit.\n" ..
                       "//assault setfont <font name> - Set the font for the UI.\n" ..
                       "//assault setfontsize <size> - Set the font size.\n" ..
                       "//assault setopacity <value> - Set the background opacity (0-255).\n" ..
                       "//assault setup - Enter setup mode to adjust the UI.\n")
    end
end

-- Command to set the font and size dynamically
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or ''
    
	if command == 'help' then
        display_help(false)  -- Regular help
    elseif command == 'wrap' then
        local limit = tonumber(args[1])
        if limit and limit > 0 then
            _G.wrap_limit = limit
            windower.add_to_chat(207, "AssaultHelper: Word wrap limit set to " .. limit)
        else
            windower.add_to_chat(167, "AssaultHelper: Please specify a valid positive number for the wrap limit.")
        end
        display_assault_guide() -- Update the UI with the new wrap limit
    elseif command == 'setfont' then
        local font = args[1]
        if font then
            ui_settings.text.font = font
            ui_window:text(ui_settings.text) -- Update UI settings
            windower.add_to_chat(207, "AssaultHelper: Font set to " .. font)
        else
            windower.add_to_chat(167, "AssaultHelper: Please specify a font name.")
        end
		display_assault_guide()

    elseif command == 'setfontsize' then
        local size = tonumber(args[1])
        if size then
            ui_settings.text.size = size
            ui_window:size(size)
            windower.add_to_chat(207, "AssaultHelper: Font size set to " .. size)
        else
            windower.add_to_chat(167, "AssaultHelper: Please specify a valid size.")
        end
		display_assault_guide()
	
	elseif command == 'setopacity' then
		local alpha = tonumber(args[1])
		if alpha and alpha >= 0 and alpha <= 255 then
			ui_settings.bg.alpha = alpha
			ui_window:bg_alpha(alpha) -- Update UI background alpha
			settings.bg.alpha = alpha  -- Update the settings
			config.save(settings, 'AssaultHelper.json') -- Save settings
			windower.add_to_chat(207, "AssaultHelper: Background opacity set to " .. alpha)
		else
			windower.add_to_chat(167, "AssaultHelper: Please specify a valid opacity value (0-255).")
		end
		display_assault_guide()	
    
	elseif command == 'setup' then
    -- Toggle setup mode
    setup_mode = not setup_mode
    
		if setup_mode then
			-- Enter setup mode, display a sample header and guide
			local sample_header = "Sample Header: Assault Mission"
			local sample_guide = "This is a sample guide text that provides information about the assault mission. " ..
								 "It will demonstrate how the text is wrapped in the UI. " ..
								 "Please ensure that the entire message is visible after adjustments."

			local wrap_limit = ui_settings.width / 10 -- Adjust based on your font size
			local wrapped_text = word_wrap(sample_guide, wrap_limit) -- Use sample_guide instead of guide
			local justified_text = justify_text(wrapped_text, wrap_limit)

			-- Combine header and guide, and apply word wrapping
			ui_window:text(sample_header .. "\n\n" .. justified_text) -- Use sample_header instead of header
			ui_window:pos(ui_settings.pos.x, ui_settings.pos.y)
			ui_window:show()
			windower.add_to_chat(207, "AssaultHelper: Setup mode activated. Adjust the window position as needed.")
			config.save(settings, 'AssaultHelper.json')
		else
			ui_window:text("")
			ui_window:pos(ui_settings.pos.x, ui_settings.pos.y)
			ui_window:show()
			-- Exit setup mode
			windower.add_to_chat(207, "AssaultHelper: Setup mode deactivated. Your settings will be saved.")
			
			-- Save the current position
			settings.pos = ui_settings.pos
			config.save(settings, 'AssaultHelper.json')
		end
    end
end)
-- Show the UI when loaded
windower.register_event('load', function()
    ui_window:pos(ui_settings.pos.x, ui_settings.pos.y)
    ui_window:show()
end)
-- Save settings on exit
windower.register_event('unload', function()
    if log_file then
        log_file:close()
    end
    settings.pos = ui_settings.pos
    settings.bg = ui_settings.bg
	config.save(settings, 'AssaultHelper.json')
	
end)

print("AssaultHelper loaded. Use //assault or //ah to open the UI.")
