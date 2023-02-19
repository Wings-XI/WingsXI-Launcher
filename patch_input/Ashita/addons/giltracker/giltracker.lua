--[[    BSD License Disclaimer
        Copyright © 2017, sylandro
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of giltracker nor the
              names of its contributors may be used to endorse or promote products
              derived from this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL sylandro BE LIABLE FOR ANY
        DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'giltracker'
_addon.author = 'sylandro'
_addon.version = '1.0.0'
_addon.language = 'English'

require('windower.shim')

config = require('config')
images = require('images')
texts = require('texts')
--packets = require('packets')

local GIL_ITEM_ID = 65535
local CUTSCENE_STATUS_ID = 4
local SCROLL_LOCK_KEY = 70
local INVENTORY_FINISH_PACKET = 0x1D
local TREASURE_FIND_ITEM_PACKET = 0xD2
local LOGIN_ZONE_PACKET = 0x0A
local ZONE_OUT_PACKET = 0x0B
local ITEM_UPDATE_PACKET = 0x20
local ITEM_MODIFY_PACKET = 0x1F

local hide_key = SCROLL_LOCK_KEY
local is_hidden_by_cutscene = false
local is_hidden_by_key = false
local is_hidden_by_zoning = false

defaults = {}
defaults.hideKey = SCROLL_LOCK_KEY
defaults.gilText = {}
defaults.gilText.bg = {}
defaults.gilText.bg.alpha = 100
defaults.gilText.bg.red = 0
defaults.gilText.bg.green = 0
defaults.gilText.bg.blue = 0
defaults.gilText.bg.visible = false
defaults.gilText.text = {}
defaults.gilText.text.font = 'Consolas'
defaults.gilText.text.fonts = {'Arial','Trebuchet MS'}
defaults.gilText.text.size = 9
defaults.gilText.flags = {}
defaults.gilText.flags.italic = true
defaults.gilText.flags.bold = false
defaults.gilText.flags.right = true
defaults.gilText.flags.bottom = true
defaults.gilText.pos = {}
defaults.gilText.pos.x = -285
defaults.gilText.pos.y = -35
defaults.gilText.text.alpha = 255
defaults.gilText.text.red = 253
defaults.gilText.text.green = 252
defaults.gilText.text.blue = 250
defaults.gilText.text.stroke = {}
defaults.gilText.text.stroke.alpha = 200
defaults.gilText.text.stroke.red = 50
defaults.gilText.text.stroke.green = 50
defaults.gilText.text.stroke.blue = 50
defaults.gilText.text.stroke.width = 2
defaults.gilText.text.visible = true
defaults.gilImage = {}
defaults.gilImage.color = {}
defaults.gilImage.color.alpha = 255
defaults.gilImage.color.red = 255
defaults.gilImage.color.green = 255
defaults.gilImage.color.blue = 255
defaults.gilImage.visible = true

local settings = config.load(defaults)
config.save(settings)

settings.gilImage.texture = {}
settings.gilImage.texture.path = windower.addon_path..'gil.png'
settings.gilImage.texture.fit = true
settings.gilImage.size = {}
settings.gilImage.size.height = 32
settings.gilImage.size.width = 32
settings.gilImage.draggable = false
settings.gilImage.repeatable = {}
settings.gilImage.repeatable.x = 1
settings.gilImage.repeatable.y = 1

local gil_image = images.new(settings.gilImage)
local gil_text = texts.new(settings.gilText)
local inventory_loaded = false
local ready = false

config.register(settings, function(settings)
    hide_key = settings.hideKey
    local windower_settings = windower.get_windower_settings()
    local xRes = windower_settings.ui_x_res
    local yRes = windower_settings.ui_y_res
    gil_image:pos(xRes + settings.gilText.pos.x - 42,
        yRes + settings.gilText.pos.y - (settings.gilImage.size.height/6))
end)

windower.register_event('load',function()
    if windower.ffxi.get_info().logged_in then
        initialize()
    end
end)

windower.register_event('login',function()
    gil_text:text('Loading...')
end)

windower.register_event('logout', function(...)
    inventory_loaded = false
    hide()
end)

windower.register_event('add item', function(_bag,_index,id,...)
    if (id == GIL_ITEM_ID) then 
        print("gil added")
        ready = true
    end
end)

windower.register_event('remove item', function(_bag,_index,id,...)
    if (id == GIL_ITEM_ID) then
        print("gil removed")
         ready = true
    end
end)

windower.register_event('incoming chunk',function(id,org,_modi,_is_injected,_is_blocked)
    -- TODO:
    if (id == LOGIN_ZONE_PACKET) then
        inventory_loaded = false
        is_hidden_by_zoning = false
        show()
    elseif (id == TREASURE_FIND_ITEM_PACKET) then
        local count = struct.unpack('I', org, 0x04 + 1)
        if (count > 0) then
            ready = true
        end
    elseif (id == ITEM_UPDATE_PACKET) then
        local count = struct.unpack('I', org, 0x04 + 1)
        local itemId = struct.unpack('H', org, 0x0C + 1)
        --print("id " .. ITEM_UPDATE_PACKET)
        --print("count " .. count)
        --print("itemId " .. itemId)
        --print("ready " .. tostring(ready))
        --print("inventory loaded " .. tostring(inventory_loaded))
        if (itemId == GIL_ITEM_ID and count >= 0) then
            update_gil()
        end
    elseif (id == INVENTORY_FINISH_PACKET) then
        refresh_gil()
    elseif (id == ITEM_MODIFY_PACKET) then
        local count = struct.unpack('I', org, 0x04 + 1)
        local itemId = struct.unpack('H', org, 0x08 + 1)
        --print("id " .. ITEM_MODIFY_PACKET)
        --print("count " .. count)
        --print("itemId " .. itemId)
        --print("ready " .. tostring(ready))
        --print("inventory loaded " .. tostring(inventory_loaded))
        if (itemId == GIL_ITEM_ID and count >= 0) then
            update_gil()
        end
    elseif (id == ZONE_OUT_PACKET) then
        is_hidden_by_zoning = true
        hide()
    elseif (id == 0x1E) then
        local quantity = struct.unpack('I', org, 0x04 + 1)
        local locationID = struct.unpack('B', org, 0x08 + 1)
        local slotID = struct.unpack('B', org, 0x09 + 1)
        if (locationID == 0 and slotID == 0 and quantity >= 0) then
            gil_text:text(comma_value(quantity))
        end
    elseif (id == 0x29) then
        local param = struct.unpack('I', org, 0x0C + 1)
        local messageID = struct.unpack('H', org, 0x18 + 1)
        if (messageID == 565) then
            update_gil(param)
        end
    else
        --print("packet id -> " .. id)
    end
end)

windower.register_event('status change', function(new_status_id)
    local is_cutscene_playing = is_cutscene(new_status_id)
    toggle_display_if_cutscene(is_cutscene_playing)
end)

windower.register_event('keyboard', function(dik, down, _flags, _blocked)
    toggle_display_if_hide_key_is_pressed(dik, down)
end)

-- function ready_if_valid_treasure_packet(packet_data)
--     local p = packets.parse('incoming',packet_data)
--     if (p.Count > 0) then ready = true end
-- end

-- function update_if_valid_item_packet(packet_data)
--     local p = packets.parse('incoming',packet_data)
--     if (p.Item == GIL_ITEM_ID and p.Count >= 0) then
--         update_gil()
--     end
-- end

function refresh_gil()
    if (ready and inventory_loaded) then
        update_gil()
        ready = false
    elseif (not inventory_loaded) then
        initialize()
    end
end

function initialize()
    inventory_loaded = true
    update_gil()
    if not is_hidden_by_key and not is_hidden_by_cutscene then show() end
end

function update_gil(plus_gil)
    local gil = AshitaCore:GetDataManager():GetInventory():GetItem(0, 0).Count + (plus_gil or 0)
    gil_text:text(comma_value(gil))
end

function show()
    gil_text:show()
    gil_image:show()
end

function hide()
    gil_text:hide()
    gil_image:hide()
end

function comma_value(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then break end
    end
    return formatted
end

function is_cutscene(status_id)
    return status_id == CUTSCENE_STATUS_ID
end

function toggle_display_if_cutscene(is_cutscene_playing)
    if not is_hidden_by_zoning then
        if (is_cutscene_playing) and (not is_hidden_by_key) then
            is_hidden_by_cutscene = true
            hide()
        elseif (not is_cutscene_playing) and (not is_hidden_by_key) then
            is_hidden_by_cutscene = false
            show()
        end
    end
end

function toggle_display_if_hide_key_is_pressed(key_pressed, key_down)
    if not is_hidden_by_zoning then
        if (key_pressed == hide_key) and (key_down) and (is_hidden_by_key) and (not is_hidden_by_cutscene) then
            is_hidden_by_key = false
            show()
        elseif (key_pressed == hide_key) and (key_down) and (not is_hidden_by_key) and (not is_hidden_by_cutscene) then
            is_hidden_by_key = true
            hide()
        end
    end
end
