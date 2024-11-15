_addon.name = 'ItemTracker'
_addon.author = 'Faceless'
_addon.version = '8.6.7.5.3.0.9'
_addon.commands = {'it', 'itemtracker'}

require('chat')
require('tables')
res = require('resources')
texts = require('texts')
config = require('config')

-- Default settings with all UI-related properties
local default_settings = {
    tracked_items = {},
    ui = {
        font = 'Arial',              -- Font type
        fontsize = 12,               -- Font size
        position = {x = 0, y = 800}, -- Position on screen
        text_color = {red = 255, green = 255, blue = 255, alpha = 255}, -- Text color
        stroke = {width = 2, alpha = 255}, -- Stroke settings for text
        bg_color = {red = 0, green = 0, blue = 0, alpha = 160}, -- Background color
        --bg_visible = true,           -- Background visibility
    }
}

-- Load settings from file (including UI settings)
local settings = config.load(default_settings)

-- Tracked items table (loaded from settings)
local tracked_items = settings.tracked_items

-- UI setup using loaded settings
local tracked_items_ui = texts.new({
    pos = settings.ui.position,
    text = {
        size = settings.ui.fontsize,
        font = settings.ui.font,
        color = settings.ui.text_color,
        stroke = settings.ui.stroke,
    },
    bg = {
        visible = settings.ui.bg_visible,
        color = settings.ui.bg_color,
    }
})

-- Fetch item quantities
function get_item_quantity(item_name)
    local total = 0
    for _, container in pairs({'inventory', 'safe', 'storage', 'locker', 'satchel', 'sack', 'case', 'wardrobe'}) do
        local items = windower.ffxi.get_items(container)
        if items then
            for _, item in ipairs(items) do
                if item.id ~= 0 then
                    local res_item = res.items[item.id]
                    if res_item and res_item.en:lower() == item_name:lower() then
                        total = total + item.count
                    end
                end
            end
        end
    end
    return total
end

-- Show UI
function show_ui()
    tracked_items_ui:visible(true)
    update_ui()
end

-- Hide UI
function hide_ui()
    tracked_items_ui:visible(false)
end

-- Helper function to sanitize item names (replace spaces with underscores)
local function sanitize_item_name(item_name)
    return item_name:gsub(" ", "_") -- Replace spaces with underscores
end

-- Helper function to unsanitize item names for display (replace underscores with spaces)
local function unsanitize_item_name(item_name)
    return item_name:gsub("_", " ") -- Replace underscores with spaces
end

-- Update UI
function update_ui()
    if not tracked_items_ui:visible() then
        return
    end

    local text = 'Tracked Items:\n'
    for sanitized_name, _ in pairs(tracked_items) do
        local item_name = unsanitize_item_name(sanitized_name)
        local quantity = get_item_quantity(item_name)
        text = text .. item_name .. ': ' .. quantity .. '\n'
    end
    tracked_items_ui:text(text)
end

-- Command handler
windower.register_event('addon command', function(...)
    local args = {...}

    if #args == 0 then
        print('No command received.')
        return
    end

    local command = args[1]:lower()
    local item_name = table.concat(args, ' ', 2)
    local sanitized_name = sanitize_item_name(item_name)

    if command == 'trackitem' then
        if item_name == '' then
            print('Please provide an item name to track.')
            return
        end
        tracked_items[sanitized_name] = true
        print('Tracking item:', item_name)
        update_ui()
        settings.tracked_items = tracked_items
        config.save(settings)
    elseif command == 'untrackitem' then
        if item_name == '' then
            print('Please provide an item name to untrack.')
            return
        end
        tracked_items[sanitized_name] = nil
        print('Untracking item:', item_name)
        update_ui()
        settings.tracked_items = tracked_items
        config.save(settings)
    elseif command == 'clearitems' then
        tracked_items = {}
        print('Cleared all tracked items.')
        update_ui()
        settings.tracked_items = tracked_items
        config.save(settings)
    elseif command == 'setfont' then
        if item_name == '' then
            print('Please provide a font name.')
            return
        end
        print('Setting font to:', item_name)
        settings.ui.font = item_name
        tracked_items_ui:font(item_name)
        config.save(settings)
    elseif command == 'setfontsize' then
        local size = tonumber(item_name)
        if not size or size < 8 or size > 72 then
            print('Please provide a valid font size (8-72).')
            return
        end
        print('Setting font size to:', size)
        settings.ui.fontsize = size
        tracked_items_ui:size(size)
        config.save(settings)
    elseif command == 'setpos' then
        local x = tonumber(args[2]) or 0  -- Default to 0 if no x-coordinate is provided
        local y = tonumber(args[3]) or 0  -- Default to 0 if no y-coordinate is provided
        tracked_items_ui:pos(x, y)  -- Update position dynamically
        settings.ui.position = {x = x, y = y}  -- Save the position setting to the correct path in settings
        config.save(settings)  -- Save settings to file
        print(string.format("Position set to: (%d, %d)", x, y))
    else
        print('Unknown command:', command)
    end
end)

-- Update initialization with sanitized item names
local sanitized_tracked_items = {}
for item_name, value in pairs(tracked_items) do
    sanitized_tracked_items[sanitize_item_name(item_name)] = value
end
tracked_items = sanitized_tracked_items
settings.tracked_items = tracked_items
config.save(settings)

-- Hook inventory changes
windower.register_event('incoming chunk', function(id, data)
    if id == 0x1F or id == 0x20 then
        update_ui()
    end
end)

-- Hook zoning and login/logout
windower.register_event('zone change', function()
    config.save(settings)
	hide_ui()
end)

windower.register_event('logout', function()
	config.save(settings)
    hide_ui()
end)

windower.register_event('login', function()
    show_ui()
end)

-- Initialize UI with loaded settings
show_ui()
