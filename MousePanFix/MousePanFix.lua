--[[
MousePanFix: Prevents the mouse from getting stuck in camera pan mode in FFXI. Please keep as much of the code for mousepanfix.lua as possible because I want it to work the same, just be able to save UI position settings.
]]

_addon.name = 'MousePanFix'
_addon.author = 'Faceless'
_addon.version = '8.675309'
_addon.commands = {'mousepanfix', 'mpf'}

local logger = require('logger')
local chat = require('chat')
local texts = require('texts')  -- Require the texts module for UI
local ui_text = texts.new('mpf: off', ui_settings)
config = require('config')  -- Load the config module

-- Default settings for the UI
local defaults = {
    pos = {x = 100, y = 100},
    text = {font = 'Arial', size = 12, color = {255, 255, 255, 255}},
    bg = {alpha = 128, red = 0, green = 0, blue = 0}
}

-- Load the UI settings
local ui_settings = config.load(defaults)
local ui_text = texts.new('mpf: off', ui_settings)  -- Initialize UI text with "off"

-- Track left mouse state to detect if it's stuck in pan mode
local left_mouse_down = false  -- Variable to track left mouse button
local mouse_fix_enabled = false  -- Tracks whether the fix is enabled

-- Sets Default Mode Types 
local LeftClick = 1
local LeftRelease = 2 

-- Debug Mode to Determine your Mouse Setup 
local debug_mode = false
local is_focused = true
local focus_check_duration = 5 -- Time before considering focus lost
local release_delay = 0.1  -- In seconds (100ms)
-- Variables for focus tracking
local last_mouse_update = os.clock()  -- Track the last time the mouse moved
local focus_timeout = 0.5  -- Duration in seconds to consider focus lost

-- Get window settings
local settings = windower.get_windower_settings()
local window_x = settings.window_x_pos
local window_y = settings.window_y_pos
local window_width = settings.x_res
local window_height = settings.y_res

-- UI visibility variable
local ui_visible = true  -- Set to true to show the UI by default

-- Function to update the UI text based on the mouse fix state
local function update_ui_text()
    if mouse_fix_enabled then
        ui_text:text('mpf: on')  -- Update to "mpf: on"
    else
        ui_text:text('mpf: off')  -- Update to "mpf: off"
    end
end

-- Function to show/hide the UI and set its position
local function update_ui()
    if ui_visible and windower.ffxi.get_info().logged_in then
        ui_text:show()  -- Show the UI
        ui_text:pos(ui_settings.pos.x, ui_settings.pos.y)  -- Set position
        update_ui_text()  -- Update the UI text based on current state

        -- Force the text to recalculate its size
        local width = width or 56  -- Get width and height
        height = height or 20  -- Set a default height if nil
    else
		ui_text:hide()
    end
end

-- Called whenever character logs in.
windower.register_event('login', function()
	ui_visible = true
    update_ui()
end)
-- Called whenever character logs out.
windower.register_event('logout', function()
    ui_visible = false
    update_ui()  -- Hide the UI
end)

-- Function to toggle mouse fix state
local function toggle_mouse_fix()
    mouse_fix_enabled = not mouse_fix_enabled
    update_ui_text() -- Update UI text based on current state
    return true
end

-- Dragging functionality for the UI
--local dragging = false
--local drag_offset = {x = 0, y = 0}

-- Register mouse events for dragging the UI
windower.register_event('mouse', function(event, x, y)
    local width = 56  -- UI width
    local height = 20  -- UI height
    local inside_ui = x >= ui_settings.pos.x and x <= (ui_settings.pos.x + width) and
                      y >= ui_settings.pos.y and y <= (ui_settings.pos.y + height)

    if inside_ui then
        if event == 1 then -- Left mouse button down
            dragging = true
            drag_offset = {x = x - ui_settings.pos.x, y = y - ui_settings.pos.y}
            return true  -- Block the event for UI interaction
        elseif event == 2 then -- Left mouse button up
            if dragging then
                dragging = false
            end
            toggle_mouse_fix()  -- Toggle the mouse fix for UI
            return true  -- Block the event for UI interaction
        end
    else
        -- Let the game process mouse events when outside the UI
        if event == 1 or event == 2 then
            return false  -- Allow targeting NPCs and other game interactions
        end
    end
	if dragging then
        ui_settings.pos.x = x - drag_offset.x
        ui_settings.pos.y = y - drag_offset.y
        ui_text:pos(ui_settings.pos.x, ui_settings.pos.y) -- Update position
    end
end)

-- Update position while dragging
--windower.register_event('mouse move', function(x, y)
--
--end)

-- Focus check handlers
local function simulate_left_release()
    windower.send_command('/mouse ' .. LeftRelease)
    left_mouse_down = false  -- Reset the left mouse down state
end

local function on_focus_lost()
    if is_focused then
        is_focused = false
        -- Simulate left mouse button release to prevent stuck dragging
        if left_mouse_down then
            simulate_left_release()
        end
    end
end

local function on_focus_gained()
    if not is_focused then
        is_focused = true
        -- Force a left click and release after focus regained if the system thinks the left button is down
        if left_mouse_down then
            windower.send_command('/mouse ' .. LeftClick)
            windower.send_command('/mouse ' .. LeftRelease)
            left_mouse_down = false
        else
            windower.send_command('@wait ' .. release_delay .. '; input /mouse ' .. LeftRelease)
        end
    end
end

-- Register mouse event
windower.register_event('mouse', function(type, x, y, delta, blocked)
    -- Debug output for mouse event types
    if debug_mode then
        windower.add_to_chat(8, "Mouse event type: " .. tostring(type))
        if type == 0 then
            windower.add_to_chat(8, "This action registers as type 0, to set this as either: for LeftClick type //mpf set leftclick 0 ; for LeftRelease type //mpf set leftrelease 0")
        elseif type == 1 then
            windower.add_to_chat(8, "This action registers as type 1, to set this as either: for LeftClick type //mpf set leftclick 1 ; for LeftRelease type //mpf set leftrelease 1")
        elseif type == 2 then  
            windower.add_to_chat(8, "This action registers as type 2, to set this as either: for LeftClick type //mpf set leftclick 2 ; for LeftRelease type //mpf set leftrelease 2")
        elseif type == 3 then  
            windower.add_to_chat(8, "This action registers as type 3, to set this as either: for LeftClick type //mpf set leftclick 3 ; for LeftRelease type //mpf set leftrelease 3")
        elseif type == 4 then  
            windower.add_to_chat(8, "This action registers as type 4, to set this as either: for LeftClick type //mpf set leftclick 4 ; for LeftRelease type //mpf set leftrelease 4")
        elseif type == 5 then  
            windower.add_to_chat(8, "This action registers as type 5, to set this as either: for LeftClick type //mpf set leftclick 5 ; for LeftRelease type //mpf set leftrelease 5")
        end
    end

    -- Only handle mouse if fix is enabled
    if not mouse_fix_enabled then
        return false  -- Let other handlers process it when disabled
    end

    -- Update last mouse movement time
    last_mouse_update = os.clock()
    
    --[[ Track mouse movement within window boundaries, If game is full screen or borderless window focus will never be lost even pulling up other windows most likely. therefore there's a
	time check in to force it to lose focus if now change in position is active after a bit, this way we can add in the ability to toggle on and off the mouse fix when the mouse is 
	being used and when it's not.]]
    if x >= window_x and x <= (window_x + window_width) and
       y >= window_y and y <= (window_y + window_height) then
        -- Check if focus is gained
        if not focus_active then
            on_focus_gained()
            focus_active = true
			--[[if mouse_fix_enabled then
				toggle_mouse_fix()
			end]]
        end
    else
		-- Check if focus is lost
		if focus_active then
			on_focus_lost()
			focus_active = false
		end
    end
    -- Handle mouse click and release based on current state
    if type == LeftClick then
        if not left_mouse_down then
            left_mouse_down = true
        end
        return mouse_fix_enabled  -- Return true when enabled, otherwise allow pass-through
    elseif type == LeftRelease then
        left_mouse_down = false
        return mouse_fix_enabled  -- Same as above
    end

    return false  -- Allow other handlers to process the event
end)

-- Set up command handling
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    if cmd == 'on' then
        if not mouse_fix_enabled then
            toggle_mouse_fix()
            chat.add_to_chat(8, 'MousePanFix enabled.')
        end
    elseif cmd == 'off' then
        if mouse_fix_enabled then
            toggle_mouse_fix()
            chat.add_to_chat(8, 'MousePanFix disabled.')
        end
    elseif cmd == 'debug' then
        debug_mode = not debug_mode
        chat.add_to_chat(8, 'Debug mode ' .. (debug_mode and 'enabled' or 'disabled') .. '.')
    elseif cmd == 'pos' then
        if args[2] and args[3] then
            ui_settings.pos.x = tonumber(args[2])
            ui_settings.pos.y = tonumber(args[3])
            update_ui()  -- Update the UI position
        end
    elseif cmd == 'set' then
        if args[2] and args[3] then
            local param = args[2]:lower()
            local value = tonumber(args[3])
            if param == 'leftclick' then
                LeftClick = value
                chat.add_to_chat(8, 'LeftClick type set to: ' .. value)
            elseif param == 'leftrelease' then
                LeftRelease = value
                chat.add_to_chat(8, 'LeftRelease type set to: ' .. value)
            end
        end
    elseif cmd == 'fontsize' then
        if args[2] then
            local size = tonumber(args[2])
            ui_text:size(size) -- Set the font size
            chat.add_to_chat(8, 'Font size set to: ' .. size)
        end
    elseif cmd == 'font' then
        if args[2] then
            local font_name = args[2]
            ui_text:font(font_name) -- Set the font
            chat.add_to_chat(8, 'Font set to: ' .. font_name)
        end
    elseif cmd == 'hide' then
        ui_visible = false
        update_ui()  -- Hide the UI
    elseif cmd == 'show' then
        ui_visible = true
        update_ui()  -- Show the UI
    elseif cmd == 'reset' then
        ui_settings.pos.x = 100
        ui_settings.pos.y = 100
        ui_text:pos(ui_settings.pos.x, ui_settings.pos.y) -- Reset UI position
        update_ui()  -- Update the UI position
        chat.add_to_chat(8, 'UI position reset.')
    else
        chat.add_to_chat(8, 'Usage: //mpf <on|off|pos|fontsize|font|hide|show|debug|set>')
    end
end)

-- Track focus lost or gained
windower.register_event('prerender', function()
    -- Check if focus has been lost
    if is_focused and os.clock() - last_mouse_update > focus_timeout then
        on_focus_lost()
    end
end)

-- Cleanup when the addon is unloaded
windower.register_event('unload', function()
    ui_text:hide()
    config.save(settings) -- Save settings upon unload
end)
-- Initialize the UI
update_ui()  -- Show the UI initially
