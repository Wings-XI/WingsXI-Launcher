--[[
 * noname - Copyright (c) 2020 atom0s [atom0s@live.com]
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
 * Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
 *
 * By using noname, you agree to the above license and its terms.
 *
 *      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
 *                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
 *                    endorses you or your use.
 *
 *   Non-Commercial - You may not use the material (noname) for commercial purposes.
 *
 *   No-Derivatives - If you remix, transform, or build upon the material (noname), you may not distribute the
 *                    modified material. You are, however, allowed to submit the modified works back to the original
 *                    noname project in attempt to have it added to the original project.
 *
 * You may not apply legal terms or technological measures that legally restrict others
 * from doing anything the license permits.
 *
 * No warranties are given.
]]--


_addon.author   = 'heals, original by atom0s';
_addon.name     = 'noplayername';
_addon.version  = '1.0.0';

require 'common'

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local noname = {};
noname.pointer1 = 0;

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Locate the needed patterns..
    local pointer1 = ashita.memory.findpattern('FFXiMain.dll', 0, '83E1F789882801000033C0668B4608', 0, 0);
    if (pointer1 == 0) then
        error('[noname] Failed to find required pattern; cannot continue!');
        return;
    end

    -- Store the pointer..
    noname.pointer1 = pointer1;

    -- Patch the player entity update function to prevent removing the invis name mask on updates..
    ashita.memory.write_uint8(noname.pointer1 + 0x02, 0xF8);
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unload.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Restore original entity update patch..
    if (noname.pointer1 ~= 0) then
        ashita.memory.write_uint8(noname.pointer1 + 0x02, 0xF7);
    end
end);

---------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is being rendered.
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    local e = GetPlayerEntity();
    if (e ~= nil and e.WarpPointer ~= 0 and e.EntityType == 0) then
        local f = e.Render.Flags2;
        if (bit.band(f, 0x08) ~= 0x08) then
            e.Render.Flags2 = bit.bor(e.Render.Flags2, 0x08);
        end
    end
end);