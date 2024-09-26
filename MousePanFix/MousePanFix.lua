--[[
    Copyright © 2024
    All rights reserved.

    MousePanFix: Prevents the mouse from getting stuck in camera pan mode in FFXI.
--]]

_addon.name = 'MousePanFix'
_addon.author = 'Faceless'
_addon.version = '8.675309'
_addon.commands = {'mousepanfix', 'mpf'}

-- Load necessary libraries at the top
local logger = require('logger')
local chat = require('chat')

-- Track left mouse state to detect if it's stuck in pan mode
local left_mouse_down = false  -- Variable to track left mouse button
-- Sets Default Mode Types 
local LeftClick = 1
local LeftRelease = 2 
-- Debug Mode to Determine your Mouse Setup 
local debug_mode = false
local is_focused = true
local mouse_update_timer = 0
local focus_check_duration = 5 -- Time before considering focus lost

-- Delay time before issuing LeftRelease on focus regain
local release_delay = 0.1  -- In seconds (100ms)

-- Get window settings
local settings = windower.get_windower_settings()
local window_x = settings.window_x_pos
local window_y = settings.window_y_pos
local window_width = settings.x_res
local window_height = settings.y_res

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

    -- Track mouse movement within window boundaries
    mouse_update_timer = 0  -- Reset the focus timer on mouse movement

    -- Check mouse position and handle focus
    if x >= window_x and x <= (window_x + window_width) and
       y >= window_y and y <= (window_y + window_height) then
        on_focus_gained()
    else
        on_focus_lost()
    end

    -- Handle mouse click and release
    if type == LeftClick then
        if not left_mouse_down then
            left_mouse_down = true
        end
        return true
    elseif type == LeftRelease then
        left_mouse_down = false
        return true
    end

    return false  -- Allow other handlers to process the event
end)

-- Coroutine to check if focus is lost due to mouse inactivity
windower.register_event('prerender', function()
    mouse_update_timer = mouse_update_timer + 1

    -- If the mouse has not moved for focus_check_duration, consider focus lost
    if mouse_update_timer > focus_check_duration then
        on_focus_lost()
    end
end)

-- Testing function
local function test_mouse_click()
    local success, err = pcall(function() 
        logger.info('Testing mouse click...') 
    end)

    if not success then
        -- Fallback to print if logger fails
        print('Logger not initialized, using print: Testing mouse click...')
        print('Error: ' .. err)
    else
        windower.send_command('/mouse ' .. LeftClick)  -- Simulate left click
        windower.send_command('/mouse ' .. LeftRelease)  -- Simulate left release
    end
end

-- Command handler for the addon
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or 'help'

    if command == 'debug' then
        debug_mode = not debug_mode
        windower.add_to_chat(8, "Debug mode is now " .. (debug_mode and "enabled" or "disabled"))

    elseif command == 'set' and args[1] then
        if args[1] == 'leftclick' and args[2] then
            LeftClick = tonumber(args[2]) or LeftClick
            windower.add_to_chat(8, "LeftClick type set to " .. tostring(LeftClick))

        elseif args[1] == 'leftrelease' and args[2] then
            LeftRelease = tonumber(args[2]) or LeftRelease
            windower.add_to_chat(8, "LeftRelease type set to " .. tostring(LeftRelease))
        else
            windower.add_to_chat(8, "Unknown set command. Use //mpf set leftclick <type> or //mpf set leftrelease <type>")
        end

    elseif command == 'test' then
        test_mouse_click()  -- Call the test function

    elseif command == 'help' or command == 'h' then
        windower.add_to_chat(8, _addon.name .. ' v.' .. _addon.version)
        windower.add_to_chat(8, 'This addon prevents the mouse from getting stuck in pan mode.')
        windower.add_to_chat(8, 'Use //mpf debug to toggle debug mode.')
        windower.add_to_chat(8, 'Use //mpf set leftclick <#> to change the left click type. Default is 1.')
        windower.add_to_chat(8, 'Use //mpf set leftrelease <#> to change the left release type. Default is 2.')
        windower.add_to_chat(8, 'Use //mpf test to simulate a mouse click for testing.')
    else
        windower.add_to_chat(8, 'Unknown command. Use //mpf help for more information.')
    end
end)

print('MousePanFix addon loaded. Monitoring focus and mouse input.')
