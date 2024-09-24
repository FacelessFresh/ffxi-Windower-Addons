--[[
    Copyright © 2024
    All rights reserved.

    MousePanFix: Prevents the mouse from getting stuck in camera pan mode in FFXI.
--]]

_addon.name = 'MousePanFix'
_addon.author = 'Faceless if this works, otherwise blame it on ChatGPT'
_addon.version = '8.675309'
_addon.commands = {'mousepanfix', 'mpf'}

-- Track left mouse state to detect if it's stuck in pan mode
local left_mouse_down = false  -- Variable to track left mouse button
--Sets Default Mode Types 
local LeftClick = 1
local LeftRelease = 2 
--Debug Mode to Determine your Mouse Setup 
local debug_mode = false
-- Mouse event handler to detect clicks use the command //mpf set LeftClick # for left mouse button clicked or //mpf set LeftRelease # for left mouse button released.
--[[For My Logitech G520 Gaming Mouse
		Type == 1 is Left Mouse Button is clicked
		Type == 2 is Left Mouse Button is released
		Type == 4 is Right Mouse Button is clicked
		Type == 5 is Right Mouse Button is released
		Type == 0 is Mouse is moved
	]]

windower.register_event('mouse', function(type, x, y, delta, blocked)
    if debug_mode then
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
	if type == LeftClick then  -- Mouse button pressed
        if left_mouse_down then
            left_mouse_down = false  -- Reset the state
            return true  -- Block further processing
        else
            left_mouse_down = true  -- Set the flag when button is pressed
        end

    elseif type == LeftRelease then  											
        left_mouse_down = false  -- Reset the flag on release
    end
end)

-- Check periodically to force reset if mouse is stuck
windower.register_event('prerender', function()
    if left_mouse_down then
        left_mouse_down = false
    end
end)

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
		
    elseif command == 'help' or command == 'h' then
        windower.add_to_chat(8, _addon.name .. ' v.' .. _addon.version)
        windower.add_to_chat(8, 'This addon prevents the mouse from getting stuck in pan mode.')
         windower.add_to_chat(8, 'Use //mpf debug to toggle debug mode. Use This to determine your Mouse Mode')
        windower.add_to_chat(8, 'Use //mpf set leftclick <#> to change the left click type. Default Type is Set to 1')
        windower.add_to_chat(8, 'Use //mpf set leftrelease <#> to change the left release type. Default Type is Set to 2')
    else
        windower.add_to_chat(8, 'Unknown command. Use //mousepanfix help for more information.')
    end
end)