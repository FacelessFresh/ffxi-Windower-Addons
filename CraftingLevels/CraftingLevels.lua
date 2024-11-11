_addon.name = 'CraftingLevels'
_addon.author = 'Faceless'
_addon.version = '8675.3.09'
_addon.commands = {'craftinglevels', 'cl'}

require('tables')
texts = require('texts')
config = require('config')

settings = config.load({
    skill_levels = {
        Fishing = 0.0, Woodworking = 0.0, Smithing = 0.0, Goldsmithing = 0.0,
        Clothcraft = 0.0, Leathercraft = 0.0, Bonecraft = 0.0, Alchemy = 0.0, Cooking = 0.0
    },
    font = 'Rockwell',  -- Default font
    fontsize = 10,      -- Default font size
    pos = {x = 0, y = 700}  -- Default position
})

local skill_levels = {}
local crafting_skills = {
    fishing = 'Fishing', woodworking = 'Woodworking', smithing = 'Smithing',
    goldsmithing = 'Goldsmithing', clothcraft = 'Clothcraft', leathercraft = 'Leathercraft',
    bonecraft = 'Bonecraft', alchemy = 'Alchemy', cooking = 'Cooking'
}

-- Function to update crafting levels in the display box
function update_crafting_levels()
    local skill_text = 'Crafting Levels:\n'
    for skill, level in pairs(skill_levels) do
        skill_text = skill_text .. string.format('%s: %.1f\n', skill, level)
    end
    display_box:text(skill_text)
end

-- Initialize the display box after settings have been loaded
function initialize_skill_levels()
    local player = windower.ffxi.get_player()
    if not player then 
        return 
    end

    -- Load skill levels from settings
    for skill_key, skill_name in pairs(crafting_skills) do
        local saved_level = settings.skill_levels[skill_name]
        local current_level = player.skills[skill_key] or 0

        -- Only update the settings if saved_level is 0 and current_level is greater than 0
        if saved_level == 0 and current_level > 0 then
            skill_levels[skill_name] = current_level
            settings.skill_levels[skill_name] = current_level
            settings:save()
        else
            -- Load the saved level directly if it's set in the settings file
            skill_levels[skill_name] = saved_level
        end
    end

    -- Initialize the display box after loading settings
    display_box = texts.new({
        pos = settings.pos,  -- Use saved position
        text = {font = settings.font, size = settings.fontsize, color = {alpha = 255, red = 255, green = 255, blue = 255}},
        bg = {alpha = 160, red = 0, green = 0, blue = 0},
        padding = 5,
        flags = {draggable = true},
    })
    display_box:hide()  -- Hide the box initially

    update_crafting_levels()  -- Update crafting levels after initialization
    display_box:show()  -- Show the box after loading and updating the levels
end

-- Update settings and save when a skill-up occurs
windower.register_event('incoming text', function(original, modified, mode)
	    -- Handle the case where a skill reaches a new level (e.g., "Leathercraft skill reaches level 3")
    if mode == 129 and original:contains('skill reaches level') then
        for skill_key, skill_name in pairs(crafting_skills) do
            if original:lower():contains(skill_name:lower()) then
                -- Extract the new level from the message
                local new_level = original:match('level (%d+)')
                if new_level then
                    -- Update the skill level to the new level
                    skill_levels[skill_name] = tonumber(new_level)
                    settings.skill_levels[skill_name] = skill_levels[skill_name]
                    settings:save()

                    -- Force update to the display box
                    update_crafting_levels()
                end
                break
            end
        end
    end
    if mode == 129 and original:contains('skill rises') then
        for skill_key, skill_name in pairs(crafting_skills) do
            if original:lower():contains(skill_name:lower()) then
                local amount = original:match('%.(%d+)')
                if amount then
                    local increment = tonumber('0.' .. amount)
                    skill_levels[skill_name] = skill_levels[skill_name] + increment
                    settings.skill_levels[skill_name] = skill_levels[skill_name]
                    settings:save()
                    
                    -- Force update to display box
                    update_crafting_levels()
                end
                break
            end
        end
    end
end)

-- Command to toggle the display of crafting levels
windower.register_event('addon command', function(command, ...)
    local args = {...}  -- Capture the arguments passed to the command
    if command == 'toggle' then
        if display_box:visible() then
            display_box:hide()
        else
            update_crafting_levels()
            display_box:show()
        end
    elseif command == 'setfont' then
        local newFont = ... -- Get the font name from command arguments
        if newFont and newFont ~= "" then
            settings.font = newFont
            display_box:font(newFont) -- Update UI font
            windower.add_to_chat(207, "Font changed to " .. newFont)
        else
            windower.add_to_chat(207, "Usage: /craftinglevels setfont [font name]")
        end
    elseif command == 'setfontsize' then
        local size = tonumber(args[1]) or 10  -- Default to 10 if no size is provided
        display_box:size(size)  -- Update font size dynamically
        settings.fontsize = size  -- Save the font size setting
        settings:save()  -- Save settings to file
        print(string.format("Font size set to: %d", size))
    elseif command == 'setpos' then
        local x = tonumber(args[1]) or 0  -- Default to 0 if no x-coordinate is provided
        local y = tonumber(args[2]) or 0  -- Default to 0 if no y-coordinate is provided
        display_box:pos(x, y)  -- Update position dynamically
        settings.pos = {x = x, y = y}  -- Save the position setting
        settings:save()  -- Save settings to file
        print(string.format("Position set to: (%d, %d)", x, y))
    end
end)

-- Retry initialization on load and with crafting start events
windower.register_event('load', function()
    coroutine.schedule(initialize_skill_levels, 2)
end)

-- Cleanup when the addon is unloaded
windower.register_event('unload', function()
    display_box:hide()
    config.save(settings) -- Save settings upon unload
end)

-- Ensure the display box is hidden properly when logging out
windower.register_event('logout', function()
    display_box:hide()  -- Hide the box when logging out
end)

-- Ensure the display box is hidden properly when switching characters
windower.register_event('login', function()
    display_box:hide()  -- Hide the box when logging in (could be redundant but ensures it is hidden)
    initialize_skill_levels()  -- Re-initialize skill levels on login
end)
