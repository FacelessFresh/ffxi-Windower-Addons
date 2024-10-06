local sets = require("sets")
local texts = require("texts")
local burden = require("burden")

local pet_actions = 
{
    [136] = "activate",
    [139] = "deactivate",
    [141] = "fire",
    [142] = "ice",
    [143] = "wind",
    [144] = "earth",
    [145] = "thunder",
    [146] = "water",
    [147] = "light",
    [148] = "dark",
    [309] = "cooldown",
    [310] = "deus_ex_automata",
}

local maneuvers = 
S{
    141,
    142,
    143,
    144,
    145,
    146,
    147,
    148,
}

str =          'Fire:     \\cs(${color_fire|255,255,255})${fire|0}\\cr - ${time_fire|0}s - ${risk_fire|0}%'
str = str .. '\nIce:      \\cs(${color_ice|255,255,255})${ice|0}\\cr - ${time_ice|0}s - ${risk_ice|0}%'
str = str .. '\nWind:     \\cs(${color_wind|255,255,255})${wind|0}\\cr - ${time_wind|0}s - ${risk_wind|0}%'
str = str .. '\nEarth:    \\cs(${color_earth|255,255,255})${earth|0}\\cr - ${time_earth|0}s - ${risk_earth|0}%'
str = str .. '\nThunder:  \\cs(${color_thunder|255,255,255})${thunder|0}\\cr - ${time_thunder|0}s - ${risk_thunder|0}%'
str = str .. '\nWater:    \\cs(${color_water|255,255,255})${water|0}\\cr - ${time_water|0}s - ${risk_water|0}%'
str = str .. '\nLight:    \\cs(${color_light|255,255,255})${light|0}\\cr - ${time_light|0}s - ${risk_light|0}%'
str = str .. '\nDark:     \\cs(${color_dark|255,255,255})${dark|0}\\cr - ${time_dark|0}s - ${risk_dark|0}%'

local hud = texts.new(str, settings)

-- Function to update HUD for each element and show/hide based on conditions
function update_hud()
    local should_show = false  -- Start with the assumption that the HUD should be hidden
    local display_str = ""  -- Initialize an empty string for the display

    -- Check all elements for burden
    for element in pairs(burden) do
        if burden[element] and burden[element] > 0 then
            should_show = true  -- At least one element has burden > 0, so the HUD should be shown
            -- Construct the display string for the active element
            local risk = burden[element] - burden.threshold
            local color = "255," .. (risk > 33 and 0 or 255) .. "," .. (risk > 0 and 0 or 255)
            local time = (burden[element] / burden.decay_rate) * 3

            display_str = display_str .. string.format('%s: \\cs(${color_%s|255,255,255})${%s|0}\\cr - %ds - ${risk_%s|0}%%\n',
                element:sub(1, 1):upper() .. element:sub(2), -- Capitalize the first letter of the element name
                element, 
                element, 
                time,
                element
            )

            -- Update HUD data for the specific element
            hud[element] = burden[element]
            hud["risk_" .. element] = risk > 0 and risk or 0
            hud["color_" .. element] = color
            hud["time_" .. element] = time
        else
            -- Clear the HUD data for elements with 0% burden
            hud[element] = ""
            hud["risk_" .. element] = ""
            hud["color_" .. element] = ""
            hud["time_" .. element] = ""
        end
    end

    -- Update the HUD with the constructed display string
    if should_show then
        hud:text(display_str)  -- Set the HUD text to the constructed display string
        hud:show()  -- Show the HUD
    else
        hud:hide()  -- Hide the HUD if no elements have burden > 0
    end
end

windower.register_event("action", function(act)
    local abil_id = act['param']
    local actor_id = act['actor_id']
    local player = windower.ffxi.get_player()

    if player.main_job_id ~= 18 then
        return
    end

    if act["category"] == 6 and actor_id == player.id and pet_actions[abil_id] then
        burden:update(pet_actions[abil_id]) -- Always assumes good burden (+15).
        if maneuvers:contains(abil_id) then
            if act.targets[1].actions[1].param > 0 then
                burden[pet_actions[abil_id]] = burden.threshold + act.targets[1].actions[1].param -- Corrects for bad burden when over threshold.
            end
            update_hud(pet_actions[abil_id])
        end
    end
end)

local function decay_event()
    for element in pairs(burden) do
        update_hud(element)
    end
end
burden.set_decay_event(decay_event)

windower.register_event("zone change", function()
    burden:zone()
end)

local function update_decay_rate(buff_id)
    if buff_id == 305 then
        burden:update_decay_rate()
    end
end

windower.register_event("gain buff", update_decay_rate)
windower.register_event("lose buff", update_decay_rate)

decay_event()

return hud
