
::L4LADD3R <- {
	
	botsEmitSound = true,
	
	ladderSounds = [
		"player/footsteps/survivor/walk/ladder1.wav",
		"player/footsteps/survivor/walk/ladder2.wav",
		"player/footsteps/survivor/walk/ladder3.wav",
		"player/footsteps/survivor/walk/ladder4.wav"
	],

	thinkTimerName = "ladder_think_timer",

	// Returns the stepwidth of a player
	// Access with player class enum
	// Dont access index 0
	
	playerStepWidth = [
		null,
		32, // Smoker
		40, // Boomer
		32, // Hunter
		32, // Spitter
		25, // Jockey
		40, // Charger
		null, // Witch
		40, // Tank
		32	// Survivor
	]
}



// Creates the think timer which calls "Think()" every tick
// ----------------------------------------------------------------------------------------------------------------------------

function createThinkTimer(){
	local timer = null;
	while(timer = Entities.FindByName(null, L4LADD3R.thinkTimerName)){
		timer.Kill()
	}
	timer = SpawnEntityFromTable("logic_timer", { targetname = "thinkTimer", RefireTime = 0 })
	timer.ValidateScriptScope()
	timer.GetScriptScope()["scope"] <- this

	timer.GetScriptScope()["func"] <- function(){
		scope.Think()
	}
	timer.ConnectOutput("OnTimer", "func")
	EntFire("!self", "Enable", null, 0, timer)
}

foreach(sound in L4LADD3R.ladderSounds){
	PrecacheSound(sound)
}

::GetRandomLadderSound <- function(){
	local randomInt = RandomInt(0, L4LADD3R.ladderSounds.len() - 1)
	local randomSound = L4LADD3R.ladderSounds[randomInt]
	return randomSound
}




function Think(){
	
	local ent = null;
	
	while(ent = Entities.FindByClassname(ent, "player")){
		
		if(!IsEntityValid(ent)){
			continue;
		}
		

		if(L4LADD3R.botsEmitSound == false && IsPlayerABot(ent)){
			continue;
		}

		local playerIsUsingLadder = (NetProps.GetPropInt(ent, "movetype") == 9)
		
		local scope = GetValidatedScriptScope(ent);
		
		// One time validation
		if(!("player_previous_ladder_pos" in scope)){
			scope["player_previous_ladder_pos"] <- ent.GetOrigin()
			scope["player_previous_ladder_state"] <- false
			scope["player_traveled_ladder_distance"] <- 0.0
			// printl("keys validated")
			continue
		}
		
		local currentPos = ent.GetOrigin()
		local travelDistance = (currentPos - scope["player_previous_ladder_pos"]).Length()
		
		// printl("Distance moved between ticks: " + travelDistance)
		// printl("Distance traveled on ladder:  " + scope["player_traveled_ladder_distance"])
		
		// Start-event
		if(scope["player_previous_ladder_state"] == false && playerIsUsingLadder == true){
			PlayerLadderUseStart(ent)
		}
		
		// Stop-event
		if(scope["player_previous_ladder_state"] == true && playerIsUsingLadder == false){
			PlayerLadderUseEnd(ent)
		}
		
		// Dont play sounds for ghosts
		if(ent.IsGhost()){
			continue
		}

		if(travelDistance <= 0.0){
			continue
		}
		
		local playerClass = ent.GetZombieType()
		local playerStepWidth = L4LADD3R.playerStepWidth[playerClass];

		if(playerIsUsingLadder){
			// Addup traveled distance
			scope["player_traveled_ladder_distance"] += travelDistance
			if(scope["player_traveled_ladder_distance"] >= playerStepWidth){
				local randomSound = GetRandomLadderSound()
				EmitAmbientSoundOn(randomSound, 1, 110, 100, ent)
				scope["player_traveled_ladder_distance"] = 0.0
			}
		}
		
		scope["player_previous_ladder_pos"] <- ent.GetOrigin()
	}
}

::PlayerLadderUseStart <- function(ent){
	if(!IsEntityValid(ent)){
		return;
	}
	local scope = GetValidatedScriptScope(ent);
	scope["player_previous_ladder_state"] <- true
	scope["player_traveled_ladder_distance"] = 0
	// printl("Player started using a ladder")
}

::PlayerLadderUseEnd <- function(ent){
	if(!IsEntityValid(ent)){
		return;
	}
	local scope = GetValidatedScriptScope(ent);
	scope["player_previous_ladder_state"] <- false
	scope["player_traveled_ladder_distance"] = 0
	// printl("Player stopped using a ladder")
}


// Makes sure entity got a script scope and returns it
// ----------------------------------------------------------------------------------------------------------------------------

::GetValidatedScriptScope <- function(ent){
	ent.ValidateScriptScope()
	return ent.GetScriptScope()
}


// Check if the entity is a valid one
// ----------------------------------------------------------------------------------------------------------------------------

::IsEntityValid <- function(ent){
	return (ent && ent.IsValid())
}


// Check if volumes intersect
::volumesAreIntersecting <- function(entity1, entity2) {
	
	local entity1Min = NetProps.GetPropVector(entity1, "m_Collision.m_vecMins")
	local entity1Max = NetProps.GetPropVector(entity1, "m_Collision.m_vecMaxs")
	local entity2Min = NetProps.GetPropVector(entity2, "m_Collision.m_vecMins")
	local entity3Max = NetProps.GetPropVector(entity2, "m_Collision.m_vecMaxs")
	
	return (
	entity1Min.x <= entity2Max.x &&
	entity1Max.x >= entity1Min.x &&
	entity1Min.y <= entity2Max.y &&
	entity1Max.y >= entity1Min.y &&
	entity1Min.z <= entity2Max.z &&
	entity1Max.z >= entity2Min.z);
}


::getAllLadders <- function(){
	local ladders = [];
	local ent = null;
	while(ent = Entities.FindByClassname(ent, "func_simpleladder")){
		ladders.push(ent);
	}
	return ladders;
}

::getCurrentLadderOfPlayer <- function(player){
	local playerIsUsingLadder = (NetProps.GetPropInt(player, "movetype") == 9)
	if(playerIsUsingLadder == false) return;
	local ladders = getAllLadders();
	foreach(ent in ladders){
		if(volumesAreIntersecting(player, ent)){
			return ent;
		}
	}
}

createThinkTimer();


printl("-------------------------------------------------")
printl("-                                               -")
printl("-                                               -")
printl("-       LADDER CLIMBING SOUNDS BY RENETM        -")
printl("-                     LOADED                    -")
printl("-                                               -")
printl("-------------------------------------------------")