--[[
	Checkpoint trigger functions
]]

function StartCreeps( trigger )
	print( "Starting creeps!" )
	for _, ent in pairs( Entities:FindAllByClassname( "npc_dota_creep_lane")) do
		ent:SetMoveCapability( 1 )
	end
end

function StopCreeps( trigger )
	print( "Stopping creeps!" )
	GameRules:SendCustomMessage( "#round_complete", 0, 0 )
	for _, ent in pairs( Entities:FindAllByClassname( "npc_dota_creep_lane")) do
		ent:SetMoveCapability( 0 )
	end
end