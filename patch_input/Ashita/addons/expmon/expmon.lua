--[[
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2019 InoUno
 *
 *	Permission is hereby granted, free of charge, to any person obtaining a copy
 *	of this software and associated documentation files (the "Software"), to
 *	deal in the Software without restriction, including without limitation the
 *	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *	sell copies of the Software, and to permit persons to whom the Software is
 *	furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *	DEALINGS IN THE SOFTWARE.
]]--

_addon.author   = 'InoUno'
_addon.name     = 'ExpMon'
_addon.version  = '1.0.1'

require 'common'

---------------------------------------------------------------------------------------------------
-- desc: Default timer configuration table.
---------------------------------------------------------------------------------------------------
local default_config =
{
    font =
    {
        font        = 'Consolas',
        size        = 12,
        color		= '255,255,255,255',
        position    = { 15, -16 },
        bgcolor     = '150,0,0,0',
        bgvisible   = true,
		bold		= true,
    },
    calcInterval    = 5,
}
local config = default_config
local configPath = _addon.path .. 'settings/config.json'

local function saveConfig()
    ashita.settings.save(configPath, config)
end


local data = {
    xpTotal = 0,
    xpStartTime = 0,
    chainNo = 0,
    maxChain = 0,
    nextChainTimeout = 0,
    nextCalc = 0,
    lastRenderTime = 0,
}

local jobs = {
    [1]  = 'WAR',
    [2]  = 'MNK',
    [3]  = 'WHM',
    [4]  = 'BLM',
    [5]  = 'RDM',
    [6]  = 'THF',
    [7]  = 'PLD',
    [8]  = 'DRK',
    [9]  = 'BST',
    [10] = 'BRD',
    [11] = 'RNG',
    [12] = 'SAM',
    [13] = 'NIN',
    [14] = 'DRG',
    [15] = 'SMN',
    [16] = 'BLU',
    [17] = 'COR',
    [18] = 'PUP',
    [19] = 'DNC',
    [20] = 'SCH',
    [21] = 'GEO',
    [22] = 'RUN',
}

-- Exp Message Types for Debug Message
local expMsgTypes = T{
    8, 253, 371, 372
}

-------------------------------------------------
-- Chain expiration times and calculations
-------------------------------------------------

local default_chain_timers = {
    { maxLevel = 10, timers = { 50, 40, 30, 20, 10, 6, 2 } },
    { maxLevel = 20, timers = { 100, 80, 60, 40, 20, 8, 4 } },
    { maxLevel = 30, timers = { 150, 120, 90, 60, 30, 10, 5 } },
    { maxLevel = 40, timers = { 200, 160, 120, 80, 40, 40, 30 } },
    { maxLevel = 50, timers = { 250, 200, 150, 100, 50, 50, 50 } },
    { maxLevel = 60, timers = { 300, 240, 180, 120, 90, 60, 60 } },
    { maxLevel = 100, timers = { 360, 300, 240, 165, 105, 60, 60 } },
}
local chain_timers = default_chain_timers
local chainTimersPath = _addon.path .. 'settings/chain_timers.json'

local function getMatchingLevelTimers(playerLevel)
    for _, v in ipairs(chain_timers) do
        if v.maxLevel > playerLevel then
            return v.timers
        end
    end
    return chain_timers[-1]
end

local function getNextChainTime()
    local playerLevel = AshitaCore:GetDataManager():GetPlayer():GetMainJobLevel()
    local timers = getMatchingLevelTimers(playerLevel)

    local chainTier = data.chainNo
    if chainTier > 6 then
        chainTier = 6
    end

    return timers[chainTier + 1]
end

-------------------------------------------------
-- Formatting functions
-------------------------------------------------

local function commaValue(num)
    local result = num
    local k = 1
    while k ~= 0 do
        result, k = string.gsub(result, "^(-?%d+)(%d%d%d)", '%1,%2')
    end
    return result
end


local function formatTime(timeInSeconds)
    if (timeInSeconds == nil or timeInSeconds == 0) then
        return "N/A"
    end
    local seconds = timeInSeconds % 60
    local minutes = math.floor(timeInSeconds / 60) % 60
    local hours = math.floor(timeInSeconds / 60 / 60)
    local result = ""
    if hours > 0 then
        result = result .. string.format("%dh", hours)
    end
    if minutes > 0 then
        result = result .. string.format("%dm", minutes)
    end
    if seconds > 0 then
        result = result .. string.format("%ds", seconds)
    end
    return result
end

local function getJob(jobId)
    local job = jobs[jobId]
    if job == nil then
        return "N/A"
    end
    return job
end

-------------------------------------------------
-- Misc. functionality
-------------------------------------------------

local function addonPrint(text)
    print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. text)
end

local function displayStats()
    if data.xpStartTime == 0 then
        addonPrint("No active session")
    else
        addonPrint("EXP gained: " .. commaValue(data.xpTotal))
        addonPrint("Started at: " .. os.date("%c", data.xpStartTime))
        addonPrint("Duration: " .. formatTime(os.time() - data.xpStartTime))
        addonPrint("Max chain: #" .. data.maxChain)
    end
end

-------------------------------------------------
-- Exp calculations
-------------------------------------------------

local function calculatePerSecond(amount, startTime)
    local diff = os.time() - startTime
    if diff == 0 then
        return 0
    end
    return amount / diff
end

local function expCalculations()
    local player = AshitaCore:GetDataManager():GetPlayer()

    local current = player:GetExpCurrent()
    local needed = player:GetExpNeeded()
    local playerLevel = player:GetMainJobLevel()
    local isPotentiallyMaxLevel = player:GetMainJobLevel()

    local expTypeSuffix = "L"
    local meritPoints = ""
    local expTypeFull = "XP"

    if player:GetLimitMode() == 224 or (needed-current == 1 and isPotentiallyMaxLevel) then
        current = player:GetLimitPoints()
        needed = 10000
        expTypeSuffix = "M"
        expTypeFull = "LP"
        meritPoints = " [" .. player:GetMeritPoints() .. "]"
    end
    local missing = needed - current

    local perSecond = calculatePerSecond(data.xpTotal, data.xpStartTime)
    local etlSeconds = 0
    if (perSecond > 0) then
        etlSeconds = missing / perSecond
    end

    local level = player:GetMainJobLevel()
    local job = getJob(player:GetMainJob())
    if player:GetSubJobLevel() > 0 then
        job = job .. "/" .. getJob(player:GetSubJob())
    end

    data.status = string.format(" Lv. %d %s  |  %s: %s/%s%s  |  TN%s: %s  |  %s/hr: %.1fk  |  ET%s: %s ",
        level, job,
        expTypeFull, commaValue(current), commaValue(needed), meritPoints,
        expTypeSuffix, commaValue(missing),
        expTypeFull, perSecond * 3.6,
        expTypeSuffix, formatTime(etlSeconds)
    )

    data.nextCalc = os.time() + config.calcInterval
end

-------------------------------------------------
-- Display functionality
-------------------------------------------------

local function updateFontManager()
    config = ashita.settings.load_merged(configPath, config)

	local a,r,g,b = config.font.color:match("([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)")
	local fcolor = math.d3dcolor(a,r,g,b)
	      a,r,g,b = config.font.bgcolor:match("([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)")
	local bcolor = math.d3dcolor(a,r,g,b)

    local f = AshitaCore:GetFontManager():Get( '__inoexp_addon' )
    f:SetBold( config.font.bold )
    f:SetColor( fcolor )
    f:SetFontFamily( config.font.font )
	f:SetFontHeight( config.font.size )
    f:SetPositionX( config.font.position[1] )
	f:SetPositionY( config.font.position[2] )
	f:GetBackground():SetColor( bcolor )
    f:GetBackground():SetVisibility( config.font.bgvisible )
end

local function updateDisplay()
    local time = os.time()
    local f = AshitaCore:GetFontManager():Get( '__inoexp_addon' )
    f:SetVisibility(true)

    config = ashita.settings.load_merged(configPath, config)

    local chainTimer = data.nextChainTimeout - time

    local chainStatus = ""
    if chainTimer > 0 then
        chainStatus = string.format("  [Next chain #%d:  %s left] ", data.chainNo + 1, formatTime(chainTimer))
    end

    f:SetText(data.status .. chainStatus)
    data.lastRenderTime = time
end

----------------------------------------------------------------------------------------------------
-- func: usage
-- desc: Displays a help block for proper command usage.
----------------------------------------------------------------------------------------------------
local function printUsage(cmd, help)
    -- Loop and print the help commands..
    for _, v in pairs(help) do
        addonPrint('\30\68Syntax:\30\02 ' .. v[1] .. '\30\71 ' .. v[2])
    end
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- make it possible to configure chain timers via a file
    chain_timers = ashita.settings.load(chainTimersPath, chain_timers)
    if chain_timers == nil then
        chain_timers = default_chain_timers
    end

    AshitaCore:GetFontManager():Create( '__inoexp_addon' )
    updateFontManager()
    expCalculations()
end)

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
	local f = AshitaCore:GetFontManager():Get( '__inoexp_addon' )
	config.font.position = { f:GetPositionX(), f:GetPositionY() }
    saveConfig()

	AshitaCore:GetFontManager():Delete( '__inoexp_addon' )
end)

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args()
    if (args[1] ~= '/xp') then
        return false
    end

    if args[2] == 'reset' or args[2] == 'r' then
        data.xpStartTime = 0
        data.xpTotal = 0
        expCalculations()
        updateDisplay()
        return true
    end

    if args[2] == 'stats' or args[2] == 's' then
        displayStats()
        return true
    end

    if args[2] == 'color' or args[2] == 'bgcolor' or args[2] == 'font' then
        config.font[args[2]] = args[3]
        saveConfig()
        updateFontManager()
        return true
    end

    if args[2] == 'default' then
        config = default_config
        saveConfig()
        updateFontManager()
        return true
    end


    -- Prints the addon help..
    printUsage('/xp', {
        { '/xp reset|r',
            '- Resets the accumulated exp.' },

        { '/xp stats|s',
            '- Shows stats about your current exp session.' },

        { '/xp color [color]',
            '- Sets the color of the display.' },

        { '/xp bgcolor [color]',
            '- Sets the background color of the display.' },

        { '/xp font [font-family]',
            '- Sets the font family to use for the display.' },

        { '/xp default',
            '- Reset the configuration to the default one.' },
    })
    return true
end)

---------------------------------------------------------------------------------------------------
-- func: Render
-- desc: Called when our addon is rendered.
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()

    -- only process changes at most every second
    local time = os.time()
    if time <= data.lastRenderTime then
        return
    end

    if time >= data.nextCalc then
        expCalculations()
    end

    updateDisplay()
end)

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
    -- trigger on character sync packets
    if id == 0x61 then
        data.nextCalc = os.time() + 1
        return false
    end

    -- handle merit mode change
    if id == 0x63 then
        local flag = struct.unpack('B', packet, 0x0B + 1)
        if flag == 96 or flag == 224 then -- merit mode change
            data.nextCalc = os.time() + 1
            return false
        end
    end

    -- Ensure it's a debug message packet
    if id ~= 0x2D then
        return false
    end

    -- Check that it's an exp message type
    local messageType = struct.unpack('H', packet, 0x18 + 1)
    if not expMsgTypes:hasvalue(messageType) then
        return false
    end

    local exp = struct.unpack('I', packet, 0x10 + 1)
    local chain = struct.unpack('I', packet, 0x14 + 1)

    local time = os.time()
    if data.xpTotal == 0 then
        data.xpStartTime = time
    end

    data.xpTotal = data.xpTotal + exp

    if chain > 0 or data.nextChainTimeout < time then
        data.chainNo = chain
        data.nextChainTimeout = time + getNextChainTime()
        if data.chainNo > data.maxChain then
            data.maxChain = data.chainNo
        end
    end

    expCalculations()
    updateDisplay()

    return false
end)

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    -- listen for incoming exp text, since character sync sometimes happens before exp is updated in the client
    -- Mode: 131 normal exp, 121 with exp chain
    if (mode == 121 or mode == 131) then
        expCalculations()
        updateDisplay()
    end
    return false;
end)
