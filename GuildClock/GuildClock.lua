-- Guilds Addon for Windower
-- Displays the current Vana'diel day, time, weather, and crafting guild status (Open/Closed)

_addon.name = 'GuildClock'
_addon.version = '86753.09'
_addon.author = 'Faceless'
_addon.commands = {'guildclock', 'gc'}

-- Load Windower libraries
texts = require('texts')
config = require('config')
res = require('resources') -- For weather data

-- Default settings for the UI
local defaults = {
    pos = {x = 100, y = 100},
    text = {font = 'Times New Roman', size = 12, color = {255, 255, 255, 255}},
    flags = {bold = true},
    bg = {alpha = 128, red = 0, green = 0, blue = 0},
    layout = 'vertical', -- Added layout setting
}

local settings = config.load(defaults)
local ui_text = texts.new('', settings) -- Initialize UI text

-- Guilds and their open/closed days and hours
local guild_info = {
	Alchemy = {open_hour = 480, close_hour = 1380},  -- 8:00 to 23:00
	Bone = {open_hour = 480, close_hour = 1380},    -- 8:00 to 23:00
	Cloth = {open_hour = 360, close_hour = 1260},   -- 6:00 to 21:00
	Cook = {open_hour = 300, close_hour = 1200},    -- 5:00 to 20:00
	Fish = {open_hour = 180, close_hour = 1080},     -- 3:00 to 18:00
	Gold = {open_hour = 480, close_hour = 1380},    -- 8:00 to 23:00
	Leather = {open_hour = 180, close_hour = 1080},  -- 3:00 to 18:00
	Smith = {open_hour = 480, close_hour = 1380},    -- 8:00 to 23:00
	Wood = {open_hour = 360, close_hour = 1260}      -- 6:00 to 21:00
}


-- Function to get the current game day
local function get_current_day()
    local days = {'Firesday', 'Earthsday', 'Watersday', 'Windsday', 'Iceday', 'Lightningday', 'Lightsday', 'Darksday'}
    local vana_day = windower.ffxi.get_info().day
    return days[vana_day + 1] -- Adjusting for Lua 1-based indexing
end

-- Function to get the current game time in HH:MM format
local function get_current_time()
    local vana_time = windower.ffxi.get_info().time
    local hours = math.floor(vana_time / 60) -- Get hours
    local minutes = vana_time % 60 -- Get remaining minutes
    return string.format("%02d:%02d", hours, minutes) -- Format to HH:MM
end

-- Function to get the current weather
local function get_current_weather()
    local current_weather = windower.ffxi.get_info().weather
    if current_weather and res.weather[current_weather] then
        return res.weather[current_weather].name
    else
        return "Clear" -- Default if no weather condition is found
    end
end

-- Function to determine if a guild is open based on game day and time
local function is_guild_open(guild, current_day, current_time_in_minutes)
    local info = guild_info[guild]
    
    -- Closed on Darksday
    if current_day == info.closed_day then
        return "Closed"
    end
    
    -- Check opening hours
    if current_time_in_minutes >= info.open_hour and current_time_in_minutes < info.close_hour then
        return "Open"
    else
        return "Closed"
    end
end

-- Function to update the UI with guild statuses
local function update_guild_status()
    local current_day = get_current_day()
    local current_time = get_current_time() -- Get formatted time
    local current_weather = get_current_weather()

    local status_list = {}
    for guild, _ in pairs(guild_info) do
        local time_in_minutes = windower.ffxi.get_info().time -- Get current time in minutes
        local status = is_guild_open(guild, current_day, time_in_minutes)
        
        -- Color guild status based on whether it's open or closed
        if status == "Open" then
            table.insert(status_list, guild .. ": \\cs(0,255,0)Open\\cr") -- Green if open
        else
            table.insert(status_list, guild .. ": \\cs(255,0,0)Closed\\cr") -- Red if closed
        end
    end

    -- Adjust UI text based on layout mode
    if settings.layout == 'horizontal' then
        ui_text:text("Day: \\cs(0,175,150)" .. current_day .. "\\cr | " ..
                     "Time: \\cs(0,175,150)" .. current_time .. "\\cr | " .. -- Olive green for day, time
                     "Weather: \\cs(0,175,150)" .. current_weather .. "\\cr | " ..
                     table.concat(status_list, " | ") .. "\n")
    else
        ui_text:text("\\cs(0,175,150)Day: " .. current_day .. "\\cr\n" ..
                     "\\cs(0,175,150)Time: " .. current_time .. "\\cr\n" .. -- Olive green for day, time
                     "\\cs(0,175,150)Weather: " .. current_weather .. "\\cr\n" ..
                     "-------------------\n" ..
                     table.concat(status_list, "\n") .. "\n" ..
                     "-------------------")
    end
end

-- Create the UI and set initial position
local function createUI()
    ui_text:show() -- Show the UI
    ui_text:pos(settings.pos.x, settings.pos.y) -- Set initial position
    update_guild_status() -- Update guild status on UI creation
end

-- Register mouse events for dragging
local dragging = false
local drag_offset = {x = 0, y = 0}
local locked = false -- Variable to track lock status

windower.register_event('mouse', function(event, x, y)
    if locked then return end -- Do not allow dragging if locked

    if event == 1 then -- Left mouse button down
        local width, height = ui_text:size()
        if x >= settings.pos.x and x <= settings.pos.x + width and
           y >= settings.pos.y and y <= settings.pos.y + height then
            dragging = true
            drag_offset.x = x - settings.pos.x
            drag_offset.y = y - settings.pos.y
        end
    elseif event == 2 then -- Left mouse button up
        dragging = false
    end
end)

-- Update position while dragging
windower.register_event('mouse move', function(x, y)
    if dragging then
        settings.pos.x = x - drag_offset.x
        settings.pos.y = y - drag_offset.y
        ui_text:pos(settings.pos.x, settings.pos.y) -- Update position
    end
end)

-- Function to update the UI periodically
local function updateUI()
    if ui_text:is_visible() then
        update_guild_status()
    end
end

-- Set a timer to update the UI every minute
local update_timer
local function start_update_timer()
    update_timer = windower.call_after(60, function()
        updateUI()
        start_update_timer() -- Reschedule
    end)
end

-- Register time change event
windower.register_event('time change', function(new, old)
    -- Update current time in minutes
    update_guild_status() -- Refresh the guild status
end)

-- Command handler for '/guildclock' command
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or ''
    
    if command == 'show' then
        createUI()
        start_update_timer() -- Start the timer when showing the UI
    elseif command == 'lock' then
        locked = true
        windower.add_to_chat(207, "UI is now locked and cannot be moved.")
    elseif command == 'unlock' then
        locked = false
        windower.add_to_chat(207, "UI is now unlocked and can be moved.")
    elseif command == 'hide' then
        ui_text:hide()
        windower.add_to_chat(207, "GuildClock UI hidden.")
    elseif command == 'setsize' then
        local newSize = tonumber(...) -- Get the size from command arguments
        if newSize then
            settings.text.size = newSize
            ui_text:size(newSize) -- Update UI text size
            windower.add_to_chat(207, "Text size changed to " .. newSize)
        else
            windower.add_to_chat(207, "Usage: /guildclock setsize [size]")
        end
    elseif command == 'setfont' then
        local newFont = ... -- Get the font name from command arguments
        if newFont and newFont ~= "" then
            settings.text.font = newFont
            ui_text:font(newFont) -- Update UI font
            windower.add_to_chat(207, "Font changed to " .. newFont)
        else
            windower.add_to_chat(207, "Usage: /guildclock setfont [font name]")
        end
    elseif command == 'help' then
        windower.add_to_chat(207, "GuildClock Commands:");
        windower.add_to_chat(207, "/guildclock show - Show the GuildClock UI");
        windower.add_to_chat(207, "/guildclock hide - Hide the GuildClock UI");
        windower.add_to_chat(207, "/guildclock lock - Lock the UI position");
        windower.add_to_chat(207, "/guildclock unlock - Unlock the UI position");
        windower.add_to_chat(207, "/guildclock setsize [size] - Change text size");
        windower.add_to_chat(207, "/guildclock setfont [font name] - Change text font");
    else
        windower.add_to_chat(207, "Usage: /guildclock [show | hide | lock | unlock | setsize | setfont | help]");
    end
end)


-- Cleanup when the addon is unloaded
windower.register_event('unload', function()
    ui_text:hide()
    config.save(settings) -- Save settings upon unload
    if update_timer then
        windower.cancel(update_timer) -- Cancel the update timer
    end
end)
-- Initialize and load settings
config.register(settings, function() update_guild_status() end)
-- Automatically create UI when the addon is loaded
createUI()
