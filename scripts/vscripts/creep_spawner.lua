--[[
	CreepSpawner - A single unit spawner.
]]
if CreepSpawner == nil then
	CreepSpawner = class({})
end

function CreepSpawner:Setup( kv )
	self.szSpawnerName = kv.SpawnerName or ""
	self.szNPCName = kv.NPCName or ""
	self.nSpawnTime = tonumber( kv.SpawnTime or 0 )
	self.nSpawnCount = tonumber( kv.SpawnCount or 1 )
	self.bAllied = kv.Allied or false
	self.tEntities = {}
	local entSpawner = Entities:FindByName( nil, self.szSpawnerName )
	if not entSpawner then
		print( string.format( "Failed to find spawner named %s\n", self.szSpawnerName) )
	end
	self.vSpawnLocation = entSpawner:GetAbsOrigin()
end

function CreepSpawner:Precache()
end

function CreepSpawner:Think()
	if not self.nSpawnTime then
		return
	end

	if GameRules:GetGameTime() >= self.nSpawnTime then
		self:_DoSpawn()
		self.nSpawnTime = nil
	end
end

function CreepSpawner:_DoSpawn()
	local nUnitsToSpawn = self.nSpawnCount
	local team = DOTA_TEAM_BADGUYS
	if self.bAllied then
		team = DOTA_TEAM_GOODGUYS
	end
	for iUnit = 1,nUnitsToSpawn do
		local entUnit = CreateUnitByName( self.szNPCName, self.vSpawnLocation, true, nil, nil, team )
		self.tEntities[ iUnit ] = entUnit
		-- entUnit:AddAbility( "life_stealer_feast")
		if self.bAllied then
			local entWp = Entities:FindByName( nil, "path_creeps_1" )
			entUnit:SetInitialGoalEntity( entWp )
			entUnit:SetBaseMoveSpeed( 300 )
		end
	end
	print( string.format( "Spawned %i units of type %s", nUnitsToSpawn, self.szNPCName))
end