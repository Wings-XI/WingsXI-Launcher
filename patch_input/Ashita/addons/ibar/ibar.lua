--[[
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2014 Vicrelant
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

_addon.author   = 'Tokey (modified original works by Vicrelant)';
_addon.name     = 'ibar';
_addon.version  = '3.0.6.7';

require 'common'

	  mb_data = {};
	arraySize = 0;

	jobs = {
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
		[22] = 'RUN'
	};
	
---------------------------------------------------------------------------------------------------
-- desc: Default ibar configuration table.
---------------------------------------------------------------------------------------------------
local default_config =
{
    font =
    {
        nameNew     = 'Calibri',
        sizeNew     = 10,
        color		= '255,255,255,255',
        position    = { 130, 0 },
        bgcolor     = '100,0,0,0',
        bgvisible   = true,
		bold		= false
    },
	layout =
	{
		player = ' $zone ($z_id) $name  [$level]  [$position] - $ecompass ',
		targetNew = ' $target [$job / $level / $aggro] [ID: $id] $position  $weak  $strong  $respawn  $steal  $items ',
		npc = ' $target [$position] [ID: $id / Index: $m_index] '
	},
	lootpools =
	{
		drops = true,
		steal = true
	},
	options =
	{
		targetPosition = false
	}
};
local ibar_config = default_config;
local f = AshitaCore:GetFontManager():Create( '__ibar_wings_addon' );

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	ibar_config = ashita.settings.load_merged(_addon.path .. 'settings/ibar.json', ibar_config);

	local a,r,g,b = ibar_config.font.color:match("([^,]+),([^,]+),([^,]+),([^,]+)");
	local fcolor = math.d3dcolor(a,r,g,b);
	local a,r,g,b = ibar_config.font.bgcolor:match("([^,]+),([^,]+),([^,]+),([^,]+)");
	local bcolor = math.d3dcolor(a,r,g,b);
	
    f:SetBold( ibar_config.font.bold );
    f:SetColor( fcolor );
    f:SetFontFamily( ibar_config.font.nameNew );
	f:SetFontHeight( ibar_config.font.sizeNew );
    f:SetPositionX( ibar_config.font.position[1] );
	f:SetPositionY( ibar_config.font.position[2] );
	f:SetText( '' );
    f:SetVisibility( false );
	f:GetBackground():SetColor( bcolor );
    f:GetBackground():SetVisibility( ibar_config.font.bgvisible );
	
	local ZoneID	= AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	
	local _, mb_data = pcall(require, 'data.' .. tostring(ZoneID));
    if (mb_data == nil or type(mb_data) ~= 'table') then
        mb_data = { };
    end
	
	arraySize = table.getn(mb_data);
end );

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
	local f = AshitaCore:GetFontManager():Get( '__ibar_wings_addon' );
	ibar_config.font.position = { f:GetPositionX(), f:GetPositionY() };
	
	ashita.settings.save(_addon.path .. 'settings/ibar.json', ibar_config);
	
	AshitaCore:GetFontManager():Delete( '__ibar_wings_addon' );
end );

---------------------------------------------------------------------------------------------------
-- func: Render
-- desc: Called when our addon is rendered.
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    local f         = AshitaCore:GetFontManager():Get( '__ibar_wings_addon' );
	local Entity	= AshitaCore:GetDataManager():GetEntity();
    local party     = AshitaCore:GetDataManager():GetParty();
	local player	= AshitaCore:GetDataManager():GetPlayer();
	local target    = AshitaCore:GetDataManager():GetTarget();
	local ZoneName	= AshitaCore:GetResourceManager():GetString('areas', party:GetMemberZone(0));
	
	-- disable view if no player
	if (player:GetMainJobLevel() == 0) then
		f:SetVisibility(false);
		return;
	end
	
	f:SetVisibility(true);
	
	ibar_config = ashita.settings.load_merged(_addon.path .. 'settings/ibar.json', ibar_config);
	
	-- obtain values from json configuration.
	
	local s_target = ibar_config.layout.player;
	
	local name = string.find(s_target,'$name');
	local zone = string.find(s_target,'$zone');
	local z_id = string.find(s_target,'$z_id');
	local mlvl = string.find(s_target,'$level');
	local gpos = string.find(s_target,'$position');
	local ecom = string.find(s_target,'$ecompass');
	local scom = string.find(s_target,'$scompass');
	local p_hp = string.find(s_target,'$hpp');
	local m_id = string.find(s_target,'$id');
	local m_ix = string.find(s_target,'$m_index');
	
	-- obtain player position.
	local pX = string.format('%2.3f',Entity:GetLocalX(party:GetMemberTargetIndex(0)));
	local pY = string.format('%2.3f',Entity:GetLocalY(party:GetMemberTargetIndex(0)));
	local pZ = string.format('%2.3f',Entity:GetLocalZ(party:GetMemberTargetIndex(0)));
	local pH = string.format('%2.3f',Entity:GetLocalYaw(party:GetMemberTargetIndex(0)));
	
	local sResult = '';
	local eResult = '';
	
	if (ecom ~= nil or scom ~= nil) then
		local degrees = pH * (180 / math.pi) + 90;
		
		if (degrees > 360) then
			degrees = degrees - 360;
		elseif (degrees < 0) then
			degrees = degrees + 360;
		end
		
		sResult = math.floor(degrees);
		
		if (337 < degrees or 23 >= degrees) then
            eResult = string.format('|cff787878|N|r');
            sResult = 'N';
        elseif (23 < degrees and 68 >= degrees) then
            eResult = string.format('|cFFFFFFFF|NE|r');
            sResult = 'NE';
        elseif (68 < degrees and 113 >= degrees) then
            eResult = string.format('|cff2cf0e8|E|r');
            sResult = 'E';
        elseif (113 < degrees and 158 >= degrees) then
            eResult = string.format('|cff49ff49|SE|r');
            sResult = 'SE';
        elseif (158 < degrees and 203 >= degrees) then
            eResult = string.format('|cffffc900|S|r');
            sResult = 'S';
        elseif (203 < degrees and 248 >= degrees) then
            eResult = string.format('|cffcd18cd|SW|r');
            sResult = 'SW';
        elseif (248 < degrees and 293 >= degrees) then
            eResult = string.format('|cff4949ff|W|r');
            sResult = 'W';
        elseif (293 < degrees and 337 >= degrees) then
            eResult = string.format('|cffff1900|NW|r');
            sResult = 'NW';
        end
	end
	
	-- attempt to display player information.
	-- check if player selected and or nothing selected.
	
	if (target:GetTargetEntityPointer() == nil or target:GetTargetName() == '' or target:GetTargetServerId() == 0 or
		target:GetTargetServerId() == party:GetMemberServerId(0)) then
		
		-- player does not have a sub-job unlocked.
		if (player:GetSubJobLevel() == 0) then
			
			if (name ~= nil) then s_target = string.gsub(s_target,'$name',party:GetMemberName(0)); end
			if (z_id ~= nil) then s_target = string.gsub(s_target,'$z_id',party:GetMemberZone(0)); end
			if (zone ~= nil) then s_target = string.gsub(s_target,'$zone',ZoneName); end
			if (p_hp ~= nil) then s_target = string.gsub(s_target,'$hpp',party:GetMemberHPP(0)); end
			if (m_id ~= nil) then s_target = string.gsub(s_target,'$id',target:GetTargetServerId()); end
			if (m_ix ~= nil) then s_target = string.gsub(s_target,'$m_index',target:GetTargetIndex()); end
			
			if (mlvl ~= nil) then
				s_target = string.gsub(s_target,'$level',
				jobs[player:GetMainJob()] ..
				player:GetMainJobLevel());
			end
			
			if (gpos ~= nil) then s_target = string.gsub(s_target,'$position',pX .. ', ' .. pY .. ', ' .. pZ); end
			if (ecom ~= nil) then s_target = string.gsub(s_target,'$ecompass',eResult); end
			if (scom ~= nil) then s_target = string.gsub(s_target,'$scompass',sResult); end
			
			f:SetText(string.format(s_target));
			return;
		
		--	player has sub-job unlocked.
		elseif (player:GetSubJobLevel() > 0) then
			
			if (name ~= nil) then s_target = string.gsub(s_target,'$name',party:GetMemberName(0)); end
			if (z_id ~= nil) then s_target = string.gsub(s_target,'$z_id',party:GetMemberZone(0)); end
			if (zone ~= nil) then s_target = string.gsub(s_target,'$zone',ZoneName); end
			if (p_hp ~= nil) then s_target = string.gsub(s_target,'$hpp',party:GetMemberHPP(0)); end
			if (m_id ~= nil) then s_target = string.gsub(s_target,'$id',target:GetTargetServerId()); end
			if (m_ix ~= nil) then s_target = string.gsub(s_target,'$m_index',target:GetTargetIndex()); end
			
			if (party:GetMemberZone(0) ~= 285) then
				if (mlvl ~= nil) then
					s_target = string.gsub(s_target,'$level',
					jobs[player:GetMainJob()] ..
					player:GetMainJobLevel() .. '/' ..
					jobs[player:GetSubJob()] ..
					player:GetSubJobLevel());
				end
			elseif (party:GetMemberZone(0) == 285) then
				if (mlvl ~= nil) then
					s_target = string.gsub(s_target,'$level',
					tostring(jobs[player:GetMainJob()]));
				end
			end
			
			if (gpos ~= nil) then s_target = string.gsub(s_target,'$position',pX .. ', ' .. pY .. ', ' .. pZ); end
			if (ecom ~= nil) then s_target = string.gsub(s_target,'$ecompass',eResult); end
			if (scom ~= nil) then s_target = string.gsub(s_target,'$scompass',sResult); end
			
			f:SetText(string.format(s_target));
			return;
		end
	end
	
	local m_target = ibar_config.layout.targetNew;
	
		  name = string.find(m_target,'$target');
		  zone = string.find(m_target,'$zone');
		  mlvl = string.find(m_target,'$level');
		  gpos = string.find(m_target,'$position');
		  m_id = string.find(m_target,'$id');
		  m_ix = string.find(m_target,'$m_index');
	local flag = string.find(m_target,'$aggro');
	local mjob = string.find(m_target,'$job');
	local weak = string.find(m_target,'$weak');
	local strong = string.find(m_target,'$strong');
	local m_hp = string.find(m_target,'$hpp');
	local respawn = string.find(m_target, '$respawn');
	local items = string.find(m_target, '$items');
	local steal = string.find(m_target, '$steal');

	



	-- attempt to obtain target information.
	if (target:GetTargetServerId() ~= nil) then
		for i = 1, arraySize do
			if (tonumber(mb_data[i].id) == target:GetTargetServerId()) then

				local tentity = GetEntity(target:GetTargetIndex());
				pX = string.format('%2.3f',tentity.Movement.LocalPosition.X);
				pY = string.format('%2.3f',tentity.Movement.LocalPosition.Y);
				pZ = string.format('%2.3f',tentity.Movement.LocalPosition.Z);

				if (name ~= nil) then m_target = string.gsub(m_target,'$target',tentity.Name); end
				if (zone ~= nil) then m_target = string.gsub(m_target,'$zone',ZoneName); end
				if (m_id ~= nil) then m_target = string.gsub(m_target,'$id',target:GetTargetServerId()); end
				if (m_ix ~= nil) then m_target = string.gsub(m_target,'$m_index',target:GetTargetIndex()); end

				if (mlvl ~= nil) then m_target = string.gsub(m_target,'$level',mb_data[i].mlvl); end

				if (mb_data[i].weak ~= "") then
					if (weak ~= nil) then m_target = string.gsub(m_target,'$weak','[Weak: ' .. mb_data[i].weak ..']'); end
				else
					if (weak ~= nil) then m_target = string.gsub(m_target,'$weak','[Weak: N/A]'); end
				end

				if (mb_data[i].strong ~= "") then
					if (strong ~= nil) then m_target = string.gsub(m_target,'$strong', '[Strong: ' .. mb_data[i].strong .. ']'); end
				else
					if (strong ~= nil) then m_target = string.gsub(m_target,'$strong', '[Strong: N/A]'); end
				end

				if (m_hp ~= nil) then m_target = string.gsub(m_target,'$hpp',tentity.HealthPercent); end

				if (mb_data[i].sj == mb_data[i].mj) then
					if (mjob ~= nil) then m_target = string.gsub(m_target,'$job',jobs[tonumber(mb_data[i].mj)]); end
				else
					if (mjob ~= nil) then
						m_target = string.gsub(m_target,'$job',
						jobs[tonumber(mb_data[i].mj)] .. '/' ..
						jobs[tonumber(mb_data[i].sj)]);
					end
				end

				if (ibar_config.options.targetPosition) then
					if (gpos ~= nil) then m_target = string.gsub(m_target,'$position', '[' .. pX .. ',' .. pY .. ',' .. pZ ..']'); end
				else
					m_target = string.gsub(m_target,' $position ', '')
				end


				if (respawn ~= nil) then
					if (tonumber(mb_data[i].respawntime) > 0) then
						if (tonumber(mb_data[i].respawntime) < 60) then
							m_target = string.gsub(m_target,'$respawn','[Respawn: ' .. mb_data[i].respawntime .. 'sec]');
						elseif (tonumber(mb_data[i].respawntime) > 7200) then
							local n = (mb_data[i].respawntime / 3600)
							n = tonumber(string.format("%." .. (1 or 0) .. "f", n))

								m_target = string.gsub(m_target,'$respawn', '[Respawn: ' .. n .. 'hr]');
						else
							m_target = string.gsub(m_target,'$respawn','[Respawn: ' .. string.format('%.2f', (mb_data[i].respawntime / 60)) .. 'min]');
						end
					else
						m_target = string.gsub(m_target,'$respawn','[Respawn: N/A]');
					end
				end

				-- remove extra space before adding in the new line character
				-- m_target = m_target:gsub("%s+", " ");

				if (ibar_config.lootpools.drops == true and items ~= nil and mb_data[i].items ~= "") then
					m_target = string.gsub(m_target, '$items', '[Drops: ' .. mb_data[i].items .. ']')
				else
					m_target = string.gsub(m_target, '$items', "[Drops: N/A]")
				end

				if (ibar_config.lootpools.steal == true and steal ~= nil and mb_data[i].steal ~= "") then
					m_target = string.gsub(m_target, '$steal', '[Steal: ' .. mb_data[i].steal .. ']')
				else
					m_target = string.gsub(m_target, '$steal', "[Steal: N/A]")
				end

				if (flag ~= nil) then
					if (mb_data[i].links == 'Y') then
						m_target = string.gsub(m_target,'$aggro',mb_data[i].aggro .. ',L');
					else
						m_target = string.gsub(m_target,'$aggro',mb_data[i].aggro);
					end
				end
				
				-- m_target = m_target:gsub("[^%S\n]+", " ");
				f:SetText(string.format(m_target));

				return;

			end
		end
		
		m_target = ibar_config.layout.npc;
		
		m_id = string.find(m_target,'$id');
		m_ix = string.find(m_target,'$m_index');
		gpos = string.find(m_target,'$position');
		n_hp = string.find(m_target,'$hpp');
		
		local tentity = GetEntity(target:GetTargetIndex());


		if (tentity ~= nil) then

			-- for k, v in pairs(getmetatable(tentity)) do			print(k .. ': ' .. type(v))			end

			pX = string.format('%2.3f',tentity.Movement.LocalPosition.X);
			pY = string.format('%2.3f',tentity.Movement.LocalPosition.Y);
			pZ = string.format('%2.3f',tentity.Movement.LocalPosition.Z);
			
			if (name ~= nil) then m_target = string.gsub(m_target,'$target',tentity.Name); end
			if (m_id ~= nil) then m_target = string.gsub(m_target,'$id',target:GetTargetServerId()); end
			if (m_ix ~= nil) then m_target = string.gsub(m_target,'$m_index',target:GetTargetIndex()); end
			if (gpos ~= nil) then m_target = string.gsub(m_target,'$position', pX .. ',' .. pY .. ',' .. pZ); end
			if (n_hp ~= nil) then m_target = string.gsub(m_target,'$hpp',tentity.HealthPercent); end
			
			f:SetText(string.format(m_target));
			return;
		else
			f:SetText('');
		end
	end
end );

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
    -- Check for zone-in packets..
    if (id == 0x0A) then
        -- Are we zoning into a mog house..
        if (struct.unpack('b', packet, 0x80 + 1) == 1) then
            return false;
        end
    
        -- Pull the zone id from the packet..
        local zoneId = struct.unpack('H', packet, 0x30 + 1);
        if (zoneId == 0) then
            zoneId = struct.unpack('H', packet, 0x42 + 1);
        end
		
        -- Update our mob list..
		--mb_data = require('data.' .. tostring(zoneId));
		_, mb_data = pcall(require, 'data.' .. tostring(zoneId));
        if (mb_data == nil or type(mb_data) ~= 'table') then
            mb_data = { };
        end
		
		arraySize = table.getn(mb_data);
    end
	
    return false;
end );

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the command arguments..
    local args = command:args();
    if (args[1] ~= '/ibar') then
        return false;
    end

	if (args[2] == nil or args[2] == "help") then
		print('  \30\02 /ibar pos x y\30\71 - Manually set the position of the bar. Note: you can still use shift+click to drag');
		print('  \30\02 /ibar fontsize number\30\71 - Adjust the font size of the ibar. Only allows values between 8 and 20');
	end

	if (args[2] == "fontsize") then
		local fontsize = tonumber(args[3])
		if (fontsize < 8 or fontsize > 20) then
			return false;
		end
		local f = AshitaCore:GetFontManager():Get( '__ibar_wings_addon' );
		ibar_config.font.size = fontsize
		f:SetFontHeight( ibar_config.font.size );
		ashita.settings.save(_addon.path .. 'settings/ibar.json', ibar_config);
	end

	if (args[2] == "pos") then
		local f = AshitaCore:GetFontManager():Get( '__ibar_wings_addon' );
		local x = tonumber(args[3])
		local y = tonumber(args[4])
		print(string.format('move ibar to %d %d', x, y))
		ibar_config.font.position = {x, y}
		f:SetPositionX( ibar_config.font.position[1] );
		f:SetPositionY( ibar_config.font.position[2] );
		ashita.settings.save(_addon.path .. 'settings/ibar.json', ibar_config);
	end

	return true;
end);