-- Generated from template

require( "creep_spawner" )
require( "util" )

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache( context )
	PrecacheUnitByNameSync("npc_dota_hero_lina", context)
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CAddonTemplateGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
	print( "Addon is loaded." )

	GameRules:SetHeroSelectionTime( 10.0 )
	GameRules:SetPreGameTime( 15.0 )

	GameRules:SetGoldTickTime( 60.0 )
	GameRules:SetGoldPerTick( 0 )

	GameRules:SetHeroRespawnEnabled( false )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
	GameRules:GetGameModeEntity():SetBuybackEnabled( false ) 

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )

	ListenToGameEvent('player_connect_full', Dynamic_Wrap(CAddonTemplateGameMode, 'OnPlayerConnectFull'), self)
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CAddonTemplateGameMode, "OnEntityKilled" ), self )
	ListenToGameEvent( "dota_player_killed", Dynamic_Wrap( CAddonTemplateGameMode, "OnPlayerKilled" ), self )
	ListenToGameEvent( "game_start", Dynamic_Wrap( CAddonTemplateGameMode, "OnGameStart" ), self )
	ListenToGameEvent( "dota_item_purchased", Dynamic_Wrap(CAddonTemplateGameMode, "OnItemPurchase"), self)

	self:_ReadGameConfiguration()
	GameRules.sLastState = nil
end

function CAddonTemplateGameMode:_ReadGameConfiguration()
	local kv = LoadKeyValues( "scripts/maps/spawn_lists.txt" )
	kv = kv or {}
	self:_ReadSpawnsConfiguration( kv["Spawns"] )
end

function CAddonTemplateGameMode:_ReadSpawnsConfiguration( kvSpawns )
	self._spawners = {}
	for k, v in pairs( kvSpawns ) do
		local spawner = CreepSpawner()
		spawner:Setup( v )
		self._spawners [ k ] = spawner
	end
end

function CAddonTemplateGameMode:OnGameStart()
	GameRules:SendCustomMessage( "#game_start", 0, 0 )

	-- Count creeps and heroes to die for lose condition
	self.nTotalHeroes = self:CountAlliedHeroes()
	print ( string.format( "Waiting for %d heroes to die.", self.nTotalHeroes ))
end

function CAddonTemplateGameMode:CountAlliedCreeps()
	return table.getn( Entities:FindAllByClassname( "npc_dota_creep_lane" ) )
end

function CAddonTemplateGameMode:CountAlliedHeroes()
	local i = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero( nPlayerID ) then
				i = i + 1
			end
		end
	end
	return i
end

-- Evaluate the state of the game
function CAddonTemplateGameMode:OnThink()
	 -- Reconnect heroes
    for _,hero in pairs(Entities:FindAllByClassname("npc_dota_hero_lina")) do
        if hero:GetPlayerOwnerID() == -1 then
            local id = hero:GetPlayerOwner():GetPlayerID()
            if id ~= -1 then
                print("Reconnecting hero for player " .. id)
                hero:SetControllableByPlayer(id, true)
                hero:SetPlayerID(id)
            end
        end
    end

	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		for _, sp in pairs( self._spawners ) do
			sp:Think()
		end

		if GameRules.sLastState ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			FireGameEvent( "game_start", {} )
		end

	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	GameRules.sLastState = GameRules:State_Get()
	return 1
end

function CAddonTemplateGameMode:OnEntityKilled( event )
	self:CheckForDefeat()
end

function CAddonTemplateGameMode:OnPlayerKilled( event )
	self:CheckForDefeat()
end

function CAddonTemplateGameMode:CheckForDefeat()
	if self:CountAlliedHeroes() <= 0 or self:CountAlliedCreeps() < 0 then
		print (self:CountAlliedHeroes())
		print (self:CountAlliedCreeps())
		GameRules:MakeTeamLose( DOTA_TEAM_GOODGUYS )
	end
end

function CAddonTemplateGameMode:OnPlayerConnectFull( keys )
    local player = PlayerInstanceFromIndex( keys.index + 1 )
    print( "Creating hero." )
    local playerHero = CreateHeroForPlayer("npc_dota_hero_lina", player )
    -- Debug
    playerHero:SetGold(10000, true)
    -- Remove existing abilities
	for id = 0, 3 do
		local ab = playerHero:GetAbilityByIndex(id)
		if ab ~= nil then
			playerHero:RemoveAbility(ab:GetAbilityName())
		end
	end
end

function CAddonTemplateGameMode:OnItemPurchase(keys)
	local playerID = keys.PlayerID
	local playerInstance = PlayerInstanceFromIndex(playerID + 1)
	local playerHero = playerInstance:GetAssignedHero()

	local item = self:GetItemByName(playerHero, keys.itemname)
	local abilityToAdd = string.gsub(item:GetAbilityName(), "item_ability_", "")
	playerHero:AddAbility(abilityToAdd)
	item:RemoveSelf()
end

function CAddonTemplateGameMode:GetItemByName( hero, name )
  -- Find item by slot
  for i = 0, 11 do
    local item = hero:GetItemInSlot( i )
    if item ~= nil then
      local lname = item:GetAbilityName()
	  print(string.format("%s item in %d slot, looking for %s", lname, i, name))
      if lname == name then
        return item
      end
    end
  end

  return nil
end