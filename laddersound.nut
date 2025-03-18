::L4LADD3R <- {
	
	botsEmitSound = true,
	
	ladderMinStepWidth  = 30,
	
	ladderSounds = [
		"player/footsteps/survivor/walk/ladder1.wav",
		"player/footsteps/survivor/walk/ladder2.wav",
		"player/footsteps/survivor/walk/ladder3.wav",
		"player/footsteps/survivor/walk/ladder4.wav"
	]
	
}

// Creates the think timer which calls "Think()" every tick
// ----------------------------------------------------------------------------------------------------------------------------

function createThinkTimer(){
	local timer = null;
	while(timer = Entities.FindByName(null, "thinkTimer")){
		timer.Kill()
	}
	timer = SpawnEntityFromTable("logic_timer", { targetname = "thinkTimer", RefireTime = 0.01 })
	timer.ValidateScriptScope()
	timer.GetScriptScope()["scope"] <- this

	timer.GetScriptScope()["func"] <- function(){
		scope.Think()
	}
	timer.ConnectOutput("OnTimer", "func")
	EntFire("!self", "Enable", null, 0, timer)
}

foreach(sound in ladderSounds){
	PrecacheSound(sound)
}

::GetRandomLadderSound <- function(){
	local randomInt = RandomInt(0, ladderSounds.len() - 1)
	local randomSound = ladderSounds[randomInt]
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
			//printl("keys validated")
			continue
		}
		
		local currentPos = ent.GetOrigin()
		local travelDistance = (currentPos - scope["player_previous_ladder_pos"]).Length()
		
		printl("Distance moved between ticks: " + travelDistance)
		printl("Distance traveled on ladder:  " + scope["player_traveled_ladder_distance"])
		
		// Start-event
		if(scope["player_previous_ladder_state"] == false && playerIsUsingLadder == true){
			PlayerLadderUseStart(ent)
		}
		
		// Stop-event
		if(scope["player_previous_ladder_state"] == true && playerIsUsingLadder == false){
			PlayerLadderUseEnd(ent)
		}
		
		if(travelDistance <= 0.0){
			continue
		}
		
		if(playerIsUsingLadder){
			// Addup traveled distance
			scope["player_traveled_ladder_distance"] += travelDistance
			if(scope["player_traveled_ladder_distance"] >= L4LADD3R.ladderMinStepWidth){
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
	//printl("Player started using a ladder")
}

::PlayerLadderUseEnd <- function(ent){
	if(!IsEntityValid(ent)){
		return;
	}
	local scope = GetValidatedScriptScope(ent);
	scope["player_previous_ladder_state"] <- false
	scope["player_traveled_ladder_distance"] = 0
	//printl("Player stopped using a ladder")
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


createThinkTimer();