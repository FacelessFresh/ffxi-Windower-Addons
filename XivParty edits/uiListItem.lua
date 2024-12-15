--[[
	Copyright © 2023, Tylas
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

		* Redistributions of source code must retain the above copyright
		  notice, this list of conditions and the following disclaimer.
		* Redistributions in binary form must reproduce the above copyright
		  notice, this list of conditions and the following disclaimer in the
		  documentation and/or other materials provided with the distribution.
		* Neither the name of XivParty nor the
		  names of its contributors may be used to endorse or promote products
		  derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- windower library imports
local res = require('resources')

-- imports
local classes = require('classes')
local uiContainer = require('uiContainer')
local uiJobIcon = require('uiJobIcon')
local uiStatusBar = require('uiStatusBar')
local uiLeader= require('uiLeader')
local uiRange = require('uiRange')
local uiBuffIcons = require('uiBuffIcons')
local uiText = require('uiText')
local uiImage = require('uiImage')
local const = require('const')
local players = require('player')
local ep = {}
config = require('config')
master_level = 0
--local saved_data = config.load('player_data.txt') or {}
-- create the class, derive from uiContainer
local uiListItem = classes.class(uiContainer)

local isDebug = false

-- Function to save the job and master level
function save_player_data()
    local data = {
        job = windower.ffxi.get_player().main_job,
        master_level = ep.master_level,
    }
    print("Saving player data: Job = " .. data.job .. ", Master Level = " .. data.master_level)
    
    -- Debugging if XML file is being saved correctly
	
    local result = config.save('player_data.txt', data)
    if result then
        print("Data saved successfully.")
    else
        print("Error: Data not saved.")
    end
end


-- Function to load the saved job and master level data
function load_player_data()
    local data = config.load('player_data.txt') or {}
    if data then
        print("Loaded saved data: Job = " .. data.job .. ", Master Level = " .. data.master_level)  -- Debugging line
    else
        print("No saved data found.")
    end
end

function uiListItem:init(layout, player, isUiLocked, itemWidth, itemHeight)
	if self.super:init(layout) then
		self.layout = layout
		self.player = player
		self.isUiLocked = isUiLocked

		self.hover = self:addChild(uiImage.new(layout.hover))
		self.hover:hide(const.visFeature)

		self.cursor = self:addChild(uiImage.new(layout.cursor))
		self.cursor:opacity(0)

		self.hpBar = self:addChild(uiStatusBar.new(layout.hp, const.barTypeHp, player))
		self.mpBar = self:addChild(uiStatusBar.new(layout.mp, const.barTypeMp, player))
		self.tpBar = self:addChild(uiStatusBar.new(layout.tp, const.barTypeTp, player))

		self.jobIcon = self:addChild(uiJobIcon.new(layout.jobIcon, player))

		self.txtName = self:addChild(uiText.new(layout.txtName))
		self.txtZone = self:addChild(uiText.new(layout.txtZone))

		self.txtJob = self:addChild(uiText.new(layout.txtJob))
		self.txtSubJob = self:addChild(uiText.new(layout.txtSubJob))

		self.leader = self:addChild(uiLeader.new(layout.leader, player))

		self.range = self:addChild(uiRange.new(layout.range, player))
		self.buffIcons = self:addChild(uiBuffIcons.new(layout.buffIcons, player))

		self.imgMouse = self:addChild(uiImage.create())
		self.imgMouse:size(math.max(0, itemWidth - 1), math.max(0, itemHeight - 1)) -- reduce size by 1 to prevent hovering over two neighboring items at the same time
		self.imgMouse:alpha(isDebug and 32 or 0)

		self.mouseHandlerId = windower.register_event('mouse', function(type, x, y, delta, blocked)
			return self:handleWindowerMouse(type, x, y, delta, blocked)
		end)
	end
end

function uiListItem:dispose()
	if not self.isEnabled then return end

	if self.mouseHandlerId then
		windower.unregister_event(self.mouseHandlerId)
		self.mouseHandlerId = nil
	end

	self.super:dispose()
end

function uiListItem:setPlayer(player)
	if not self.isEnabled then return end
	if self.player == player then return end

	self.player = player

	self.hpBar:setPlayer(player)
	self.mpBar:setPlayer(player)
	self.tpBar:setPlayer(player)

	self.jobIcon:setPlayer(player)
	self.leader:setPlayer(player)
	self.range:setPlayer(player)
	self.buffIcons:setPlayer(player)
end

function uiListItem:setUiLocked(isUiLocked)
	if not self.isEnabled then return end

	self.isUiLocked = isUiLocked

	if not isUiLocked then
		self.hover:hide(const.visFeature)
	end
end

function uiListItem:update()
	if not self.isEnabled or not self.player then return end

	if self.player.name then
		self.txtName:update(self.player.name)
	else
		self.txtName:update('???')
	end

	self:updateZone()
	self:updateJob()
	self:updateCursor()

	self.super:update()
end

function uiListItem:updateZone()
	local zoneString = ''

	if self.player.zone and self.player.isOutsideZone then
		if self.layout.txtZone.short then
			zoneString = '('..res.zones[self.player.zone]['search']..')'
		else
			zoneString = '('..res.zones[self.player.zone].name..')'
		end
	end

	self.txtZone:update(zoneString)
end
local master_level_chart = {
	[2500] = 0,          -- ML 0
	[5550] = 1,      -- ML 1
	[8721] = 2,      -- ML 2
	[11919] = 3,     -- ML 3
	[15122] = 4,     -- ML 4
	[18327] = 5,     -- ML 5
	[21532] = 6,     -- ML 6
	[24737] = 7,     -- ML 7
	[27942] = 8,     -- ML 8
	[31147] = 9,     -- ML 9
	[41205] = 10,     -- ML 10
	[48130] = 11,     -- ML 11
	[53677] = 12,     -- ML 12
	[58618] = 13,     -- ML 13
	[63292] = 14,     -- ML 14
	[67848] = 15,     -- ML 15
	[72353] = 16,     -- ML 16
	[76835] = 17,     -- ML 17
	[81307] = 18,     -- ML 18
	[85775] = 19,     -- ML 19
	[109112] = 20,     -- ML 20
	[127014] = 21,     -- ML 21
	[141329] = 22,     -- ML 22
	[153277] = 23,     -- ML 23
	[163663] = 24,     -- ML 24
	[173018] = 25,     -- ML 25
	[181692] = 26,     -- ML 26
	[189917] = 27,     -- ML 27
	[197845] = 28,     -- ML 28
	[205578] = 29,     -- ML 29
	[258409] = 30,     -- ML 30
	[307400] = 31,     -- ML 31
	[353012] = 32,     -- ML 32
	[395651] = 33,     -- ML 33
	[435673] = 34,     -- ML 34
	[473392] = 35,     -- ML 35
	[509085] = 36,     -- ML 36
	[542995] = 37,     -- ML 37
	[575336] = 38,     -- ML 38
	[606296] = 39,     -- ML 39
	[769426] = 40,     -- ML 40
	[951369] = 41,     -- ML 41
	[1154006] = 42,     -- ML 42
	[1379407] = 43,     -- ML 43
	[1629848] = 44,     -- ML 44
	[1907833] = 45,     -- ML 45
	[2216116] = 46,     -- ML 46
	[2557728] = 47,     -- ML 47
	[2936001] = 48,     -- ML 48
	[3354601] = 49,     -- ML 49
	[3817561] = 50,     -- ML 50
    --[/* TNL for max ML */] = /* Max ML */,
}
-- Sort the TNLs in ascending order
local sorted_tnls = {}
for tnl, level in pairs(master_level_chart) do
    table.insert(sorted_tnls, tnl)
end
table.sort(sorted_tnls)

-- packets
packet_handlers = {
    [0x061] = function(org)
        local p = packets.parse('incoming', org)
        ep.tnml = p['Required Exemplar Points']
		ep.master_level_rt= p['Master Level']
		ep.job = res.jobs[p['Main Job']].name
		
        --print("Required Exemplar Points:", ep.tnml)
        
        -- Find the highest master level that doesn't exceed ep.tnml
        local master_level = 0
        for _, tnl in ipairs(sorted_tnls) do
            if ep.tnml >= tnl then
                master_level = master_level_chart[tnl]  -- Update with the corresponding master level
            else
                break  -- Exit the loop when the TNL exceeds ep.tnml
            end
        end
        
        --print("Master Level:", master_level)
		ep.master_level = master_level
		--print("ep.master_level before saving:", ep.master_level)
		--save_player_data() -- Save the player data after the update
    end,
}
windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
    if is_injected or is_blocked then return end
    local handler = packet_handlers[id]
    if handler then
        handler(org,modi)
		if data then
			parse_job_data(data)
		end
    end
end)

function refresh_master_level()
	--load_player_data()
    if not ep.tnml then
        --print("Error: TNL data is missing.")
        return
    end

    local tnml = ep.tnml or 0  -- Use current TNL value, default to 0 if not set
    local master_level = 0
    for _, tnl in ipairs(sorted_tnls) do
        if tnml >= tnl then
            master_level = master_level_chart[tnl]
        else
            break
        end
    end

    --print("Updated Master Level:", master_level)
    ep.master_level = master_level
end
function parse_job_data(data)
    -- Extract exemplar points (EP) from the packet
    local exemplar_points = data:unpack('I', 0x45 + 1) -- Offset for EP in 0x061
    local master_level = calculate_master_level(exemplar_points)
    
    ep.master_level = master_level
    --print("Master Level Updated via 0x061:", ep.master_level)
end

function calculate_master_level(exemplar_points)
    -- Logic to calculate master level from exemplar points
    local master_level = 0
    for _, tnl in ipairs(sorted_tnls) do
        if exemplar_points >= tnl then
            master_level = master_level_chart[tnl]
        else
            break
        end
    end
    return master_level
end

windower.register_event('job change', function()
    ---print("Job changed, refreshing master level.")
    refresh_master_level()
end)

windower.register_event('party invite', function()
    --print("Party invite received, refreshing master level.")
    refresh_master_level()
end)
windower.register_event('load', function()
	-- settings must only be loaded when logged in, as they are separate for every character
	if windower.ffxi.get_info().logged_in then
		refresh_master_level()
	end
end)

windower.register_event('login', function()
	if not isInitialized then
		refresh_master_level()
	end
end)
local function get_job_points_spent()
    local player = windower.ffxi.get_player()
    local jobpointsspent = 0

    -- Get the player's current main job
    local main_job = player.main_job:lower()

    -- List of categories that represent job point expenditure
    local valid_categories = {
        'jp_spent'
    }

    -- Calculate job points spent for the current main job
    for k, v in pairs(player.job_points[main_job]) do
        -- Only count categories that are in valid_categories
        if v > 0 and table.contains(valid_categories, k) then
            jobpointsspent = jobpointsspent + v
        end
    end
    return jobpointsspent
end

function uiListItem:updateJob()
	local jobpointsspent = get_job_points_spent()
	local jobString = ''
	local subJobString = ''
	
	if not self.player.isOutsideZone then
		if self.player.job then
			jobString = self.player.job
			if jobpointsspent == 2100 and ep.master_level ~= nil then
				if self.player.jobLvl then
					jobString = jobString .. ' ML ' .. tostring(ep.master_level)
				end
			else
				jobString = self.player.job
				if self.player.jobLvl then
					jobString = jobString .. ' ' .. tostring(self.player.jobLvl)
				end
			end
		end

		if self.player.subJob and self.player.subJob ~= 'MON' then
			if self.player.subJob ~= "NON" then 
				subJobString = self.player.subJob
				if self.player.subJobLvl then
					subJobString = subJobString .. ' ' .. tostring(self.player.subJobLvl)
				end
			else
				subJobString = ""
			end
		end
	end

	self.txtJob:update(jobString)
	self.txtSubJob:update(subJobString)
end

function uiListItem:updateCursor()
	local opacity = 0

	if not self.player.isOutsideZone then
		if self.player.isSelected then
			opacity = 1
		elseif self.player.isSubTarget then
			opacity = 0.5
		end
	end

	self.cursor:opacity(opacity)
end

-- handle mouse interaction
function uiListItem:handleWindowerMouse(type, x, y, delta, blocked)
    if blocked then return end

    if self.isUiLocked and Settings.mouseTargeting then
		if self.imgMouse:hover(x, y) and not self.player.isOutsideZone and self.player.isInTargetingRange then
			-- mouse move
			if type == 0 then
				self.hover:show(const.visFeature)
			-- mouse left click
			elseif type == 1 then
				return true
			-- mouse left release
			elseif type == 2 then
				windower.send_command('input /ta ' .. self.player.name)
				return true
			end
		else
			self.hover:hide(const.visFeature)
		end
    else
		self.hover:hide(const.visFeature)
	end

    return false
end

return uiListItem