#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN	"SentryGunMRO"
#define VERSION	"2.0e"
#define AUTHOR	"CsMercenarioPRO"

#define ENTITYCLASS "info_target"

stock Float:fpev(_index, _value)
{
	static Float:fl
	pev(_index, _value, fl)
	return fl
}

stock bool:is_player(ent)
{
	if(is_user_connected(ent) || is_user_connecting(ent))
		return true
	return false
}

stock bool:is_alive(ent)
{
	if(pev(ent, pev_deadflag)==DEAD_NO && fpev(ent, pev_health)>0.0)
		return true
	return false
}

stock Float:halflife_time()
{
	static Float:fl
	global_get(glb_time, fl)
	return fl
}

new const szClasses[][] =
{
	"sentrybase",
	"sentrygun",
	"sentryrocket"
}



new const Float:flSizes[][] =
{
	{-16.0, -16.0, 0.0},
	{16.0, 16.0, 16.0},
	{-16.0, -16.0, 0.0},
	{16.0, 16.0, 48.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0}
}



//new const Float:dmgGlow[3] = {241.0, 98.0, 15.0}


new const Float:dmgGlowT[3] = {255.0, 0.0, 0.0}
new const Float:dmgGlowCT[3] = {0.0, 0.0, 255.0}


new const szModels[][] =
{
	"models/og_ctf1-0b/sentrys/base.mdl",
	"models/og_ctf1-0b/sentrys/lvl1_t.mdl",
	"models/og_ctf1-0b/sentrys/lvl2_t.mdl",
	"models/og_ctf1-0b/sentrys/lvl3_t.mdl",
	"models/og_ctf1-0b/sentrys/lvl1_ct.mdl",
	"models/og_ctf1-0b/sentrys/lvl2_ct.mdl",
	"models/og_ctf1-0b/sentrys/lvl3_ct.mdl",
	"models/rpgrocket.mdl"
}

/*
new const szModels[][] =
{
	"models/sentries/base.mdl",
	"models/sentries/sentry1t.mdl",
	"models/sentries/sentry2t.mdl",
	"models/sentries/sentry3t.mdl",
	"models/sentries/sentry1ct.mdl",
	"models/sentries/sentry2ct.mdl",
	"models/sentries/sentry3ct.mdl",
	"models/rpgrocket.mdl"
}
*/

new const szSounds[][] =
{
	"og_ctf1-0b/sentrys/turridle.wav",
	"og_ctf1-0b/sentrys/turrset.wav",
	"og_ctf1-0b/sentrys/turrspot.wav",
	"og_ctf1-0b/sentrys/building.wav",
	"og_ctf1-0b/sentrys/asscan3.wav",
	"weapons/rocketfire1.wav",
	"weapons/debris1.wav",
	"weapons/debris2.wav",
	"weapons/debris3.wav",
	"og_ctf1-0b/sentrys/asscan1.wav"
}

/*
new const szSounds[][] =
{
	"sentries/turridle.wav",
	"sentries/turrset.wav",
	"sentries/turrspot.wav",
	"sentries/building.wav",
	"sentries/asscan3.wav",
	"weapons/rocket1.wav",
	"weapons/debris1.wav",
	"weapons/debris2.wav",
	"weapons/debris3.wav",
	"sentries/asscan1.wav"
}
*/

	/*
	//"weapons/m249-1.wav",
	
	"sentries/turridle.wav",
	"sentries/turrset.wav",
	"sentries/turrspot.wav",
	"sentries/building.wav",
	"sentries/shoot1.wav",
	"weapons/rocket1.wav",
	"weapons/debris1.wav",
	"weapons/debris2.wav",
	"weapons/debris3.wav"
	*/

new g_pCvars[13]
new boom
new trail

new Float:g_bulletdmg[2]
new Float:g_rocketdelay
new g_rocketamount
new g_rockettracktarget

stock getHead(ent)					{ return pev(ent, pev_euser1); }
stock getBase(ent)					{ return pev(ent, pev_euser2); }
stock getOwner(ent)					{ return pev(ent, pev_euser3); }
stock getEnemy(ent)					{ return pev(ent, pev_enemy); }
stock setHead(ent, head)				{ set_pev(ent, pev_euser1, head); }
stock setBase(ent, base)				{ set_pev(ent, pev_euser2, base); }
stock setOwner(ent, owner)				{ set_pev(ent, pev_euser3, owner); }
stock setEnemy(ent, enemy)				{ set_pev(ent, pev_enemy, enemy); }
stock Float:getLastThinkTime(ent)			{ return fpev(ent, pev_fuser1); }
stock setLastThinkTime(ent, Float:lastThinkTime)	{ set_pev(ent, pev_fuser1, lastThinkTime); }
stock Float:getTurnRate(ent)				{ return fpev(ent, pev_fuser2); }
stock setTurnRate(ent, Float:turnRate)			{ set_pev(ent, pev_fuser2, turnRate); }
stock Float:getRadarAngle(ent)				{ return fpev(ent, pev_fuser3); }
stock setRadarAngle(ent, Float:radarAngle)		{ set_pev(ent, pev_fuser3, radarAngle); }
stock Float:getTargetLostTime(ent)			{ return fpev(ent, pev_fuser4); }
stock setTargetLostTime(ent, Float:lostTime)		{ set_pev(ent, pev_fuser4, lostTime); }
stock getBits(ent)					{ return pev(ent, pev_iuser1); }
stock setBits(ent, bits)				{ set_pev(ent, pev_iuser1, bits); }
stock getLevel(ent)					{ return pev(ent, pev_iuser2); }
stock setLevel(ent, level)				{ set_pev(ent, pev_iuser2, level); }
stock getTeam(ent)					{ return is_player(ent)?get_user_team(ent):pev(ent, pev_team); }
stock setTeam(ent, team)				{ set_pev(ent, pev_team, team); }
stock getTurretAngles(ent, Float:angles[3])		{ pev(ent, pev_vuser1, angles); }
stock setTurretAngles(ent, Float:angles[3])		{ set_pev(ent, pev_vuser1, angles); }
stock getLastSight(ent, Float:last[3])			{ pev(ent, pev_vuser2, last); }
stock setLastSight(ent, Float:last[3])			{ set_pev(ent, pev_vuser2, last); }
stock getAnimFloats(ent, Float:animFloats[3])		{ pev(ent, pev_vuser3, animFloats); }
stock setAnimFloats(ent, Float:animFloats[3])		{ set_pev(ent, pev_vuser3, animFloats); }

stock kill_entity(ent)
{
	set_pev(ent, pev_flags, pev(ent, pev_flags)|FL_KILLME)
}

public plugin_cfg()
{
	g_bulletdmg[0] = get_pcvar_float(g_pCvars[0])
	g_bulletdmg[1] = get_pcvar_float(g_pCvars[1])
	g_rocketdelay = get_pcvar_float(g_pCvars[10])
	g_rocketamount = get_pcvar_num(g_pCvars[11])
	g_rockettracktarget = get_pcvar_num(g_pCvars[12])
}



new MaxPlayers;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	MaxPlayers = get_maxplayers();
	
	g_pCvars[0] = register_cvar("sentry_bulletdmg_min", "10.0")
	g_pCvars[1] = register_cvar("sentry_bulletdmg_max", "12.0")
	g_pCvars[2] = register_cvar("sentry_searchradius", "1800.0")
	g_pCvars[3] = register_cvar("sentry_health_lv1e", "1000.0")
	g_pCvars[4] = register_cvar("sentry_health_lv2e", "2000.0")
	g_pCvars[5] = register_cvar("sentry_health_lv3e", "3000.0")
	g_pCvars[6] = register_cvar("sentry_detonation_dmg", "200.0")
	g_pCvars[7] = register_cvar("sentry_detonation_radius", "300.0")
	g_pCvars[8] = register_cvar("sentry_dmgtoken_multiplier", "0.5")
	g_pCvars[9] = register_cvar("sentry_rocketdmg", "150.0")
	g_pCvars[10] = register_cvar("sentry_rocket_lauchdelay", "0")
	g_pCvars[11] = register_cvar("sentry_rocket_lauchamount", "0")
	g_pCvars[12] = register_cvar("sentry_rocket_tracktarget", "0")
	
	register_forward(FM_Touch, "fwd_Touch", 1)
	register_forward(FM_Think, "sentryThink")
	
	RegisterHam(Ham_TakeDamage, ENTITYCLASS, "sentryTakeDamage")
}

public plugin_natives()
{
	register_native("sentry_stopbuild", "native_sentry_stopbuild")
	register_native("sentry_sethealth", "native_sentry_sethealth")
	register_native("sentry_setorigin", "native_sentry_setorigin")
	register_native("sentry_remove", "native_sentry_remove")
	register_native("sentry_detonate", "native_sentry_detonate")
	register_native("sentry_setlevel", "native_sentry_setlevel")
	register_native("sentry_build", "native_sentry_build")
}

public plugin_precache()
{
	for(new i=0;i<sizeof(szModels);i++)
		precache_model(szModels[i])
	for(new i=0;i<sizeof(szSounds);i++)
		precache_sound(szSounds[i])
	
	boom = precache_model("sprites/zerogxplode.spr")
	trail = precache_model("sprites/smoke.spr")
}

public fwd_Touch(ptd, ptr)
{
	if(!pev_valid(ptd) || !is_rocket(ptd))
		return
	new Float:origin[3], Float:dmg
	pev(ptd, pev_origin, origin)
	dmg = fpev(ptd, pev_dmg)
	create_explosion(origin, dmg, dmg*1.5, ptd, getOwner(ptd))
	switch(random_num(1,3))
	{
		case 1: emit_sound(ptd, CHAN_VOICE, szSounds[6], 0.55, ATTN_NORM, 0, PITCH_NORM)
		case 2: emit_sound(ptd, CHAN_VOICE, szSounds[7], 0.55, ATTN_NORM, 0, PITCH_NORM)
		case 3: emit_sound(ptd, CHAN_VOICE, szSounds[8], 0.55, ATTN_NORM, 0, PITCH_NORM)
	}
	kill_entity(ptd)
}

public native_sentry_stopbuild(id, num)
{
	if(num != 1)
		return
	new ent
	ent = get_param(1)
	if(!pev_valid(ent) || !is_sentrybase(ent)) return
	kill_entity(ent)
}

public native_sentry_sethealth(id, num)
{
	if(num != 2)
		return
	new ent, Float:health
	ent = get_param(1)
	health = get_param_f(2)
	if(!pev_valid(ent)) return
	if(is_sentrybase(ent)) ent = getHead(ent)
	if(!pev_valid(ent) || !is_sentrygun(ent)) return
	set_pev(ent, pev_health, health)
}

public native_sentry_setorigin(id, num)
{
	if(num != 2)
		return
	new ent, Float:origin[3]
	ent = get_param(1)
	get_array_f(2, origin, 3)
	if(!pev_valid(ent)) return
	if(is_sentrybase(ent)) ent = getHead(ent)
	if(!pev_valid(ent) || !is_sentrygun(ent)) return
	set_pev(getBase(ent), pev_origin, origin)
	origin[2] += 16.0
	set_pev(ent, pev_origin, origin)
}

public native_sentry_remove(id, num)
{
	if(num != 1)
		return
	new ent
	ent = get_param(1)
	if(!pev_valid(ent)) return
	if(is_sentrybase(ent)) ent = getHead(ent)
	if(!pev_valid(ent) || !is_sentrygun(ent)) return
	sentryKilled(ent)
	kill_entity(ent)
	kill_entity(getBase(ent))
}

public native_sentry_detonate(id, num)
{
	if(num != 1)
		return
	new ent
	ent = get_param(1)
	if(!pev_valid(ent)) return
	if(is_sentrybase(ent)) ent = getHead(ent)
	if(!pev_valid(ent) || !is_sentrygun(ent)) return
	set_pev(ent, pev_health, 0.0)
}

public native_sentry_setlevel(id, num)
{
	if(num != 4)
		return
	new ent, level, playsound, sethealth
	ent = get_param(1)
	level = clamp(get_param(2), 1, 3)
	playsound = get_param(3)
	sethealth = get_param(4)
	if(!pev_valid(ent)) return
	if(is_sentrybase(ent)) ent = getHead(ent)
	if(!pev_valid(ent) || !is_sentrygun(ent)) return
	setLevel(ent, level)
	if(playsound)
		emit_sound(ent, CHAN_AUTO, szSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	if(sethealth)
		set_pev(ent, pev_health, getLevelHealth(level))
}


public native_sentry_build(id, num)
{
	if(num != 6)
		return 0
	new ent, Float:nOrigin[3], dropToGround, owner, team, level, instant
	get_array_f(1, nOrigin, 3)
	dropToGround = get_param(2)
	owner = get_param(3)
	team = get_param(4)
	level = clamp(get_param(5), 1, 3)
	instant = get_param(6)
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, ENTITYCLASS))
	if(!pev_valid(ent))
		return 0
	dllfunc(DLLFunc_Spawn, ent)
	set_pev(ent, pev_classname, szClasses[0])
	engfunc(EngFunc_SetModel, ent, szModels[0])
	engfunc(EngFunc_SetSize, ent, flSizes[0], flSizes[1])
	setOwner(ent, owner)
	setTeam(ent, team)
	setLevel(ent, level)
	set_pev(ent, pev_takedamage, 0.0)
	set_pev(ent, pev_health, 0.0)
	if(dropToGround)
		nOrigin[2] -= distFromGround(nOrigin, ent)
	set_pev(ent, pev_origin, nOrigin)
	set_pev(ent, pev_solid, SOLID_SLIDEBOX)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_nextthink, halflife_time() + ((instant!=0)?0.0:2.0))
	emit_sound(ent, CHAN_AUTO, szSounds[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
	return ent
}

//#include <cstrike>

stock createSentryHead(Float:origin[3], owner, team, level, base)
{
	new ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, ENTITYCLASS))
	if(!pev_valid(ent))
		return 0
	dllfunc(DLLFunc_Spawn, ent)
	set_pev(ent, pev_classname, szClasses[1])
	level = clamp(level, 1, 3)
	setOwner(ent, owner)
	setTeam(ent, team)
	setLevel(ent, level)
	setBase(ent, base)
	
	/*
	new maxplayers = get_maxplayers()
	
	for( new i = 1; i <= maxplayers; i++ )
	{
	
	if ( is_user_connected(i) )
	{
		if ( cs_get_user_team(i) == CS_TEAM_T )
		{
			switch(level)
			{
				case 1: engfunc(EngFunc_SetModel, ent, szModels[1])
				case 2: engfunc(EngFunc_SetModel, ent, szModels[2])
				case 3: engfunc(EngFunc_SetModel, ent, szModels[3])
			}
		}
		else if ( cs_get_user_team(i) == CS_TEAM_CT )
		{
			switch(level)
			{
				case 1: engfunc(EngFunc_SetModel, ent, szModels[4])
				case 2: engfunc(EngFunc_SetModel, ent, szModels[5])
				case 3: engfunc(EngFunc_SetModel, ent, szModels[6])
			}
		}
	}
	}
	*/
	
	client_print(owner, print_center, "Pulsa 'E' para subir de nivel.")
	
	
	if ( getTeam(team) == 1)
	{
			switch(level)
			{
				case 1: engfunc(EngFunc_SetModel, ent, szModels[1])
				case 2: engfunc(EngFunc_SetModel, ent, szModels[2])
				case 3: engfunc(EngFunc_SetModel, ent, szModels[3])
			}
	}
	else if ( getTeam(team) == 2)
	{
			switch(level)
			{
				case 1: engfunc(EngFunc_SetModel, ent, szModels[4])
				case 2: engfunc(EngFunc_SetModel, ent, szModels[5])
				case 3: engfunc(EngFunc_SetModel, ent, szModels[6])
			}
	}
	
	/*
	switch(level)
	{
		case 1: engfunc(EngFunc_SetModel, ent, szModels[1])
		case 2: engfunc(EngFunc_SetModel, ent, szModels[2])
		case 3: engfunc(EngFunc_SetModel, ent, szModels[3])
	}
	*/
	
	
	
	
	engfunc(EngFunc_SetSize, ent, flSizes[2], flSizes[3])
	switch(team)
	{
		case 1: set_pev(ent, pev_colormap, 0|(0<<8))
		case 2: set_pev(ent, pev_colormap, 150|(160<<8))
		default: set_pev(ent, pev_colormap, 150|(160<<8))
	}

	set_pev(ent, pev_controller_1, 127)
	set_pev(ent, pev_controller_2, 127)
	set_pev(ent, pev_controller_3, 127)
	set_pev(ent, pev_takedamage, 1.0)
	set_pev(ent, pev_health, getLevelHealth(level))
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_solid, SOLID_SLIDEBOX)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_nextthink, halflife_time())
	emit_sound(ent, CHAN_AUTO, szSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	return ent
}

stock createHVRrocket(Float:origin[3], Float:vecForward[3], launcher, owner, team, Float:dmg)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, ENTITYCLASS))
	if(!pev_valid(ent))
		return 0
	dllfunc(DLLFunc_Spawn, ent)
	set_pev(ent, pev_classname, szClasses[2])
	engfunc(EngFunc_SetModel, ent, szModels[7])
	engfunc(EngFunc_SetSize, ent, flSizes[4], flSizes[5])
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_solid, SOLID_BBOX)
	
	new Float:angles[3]
	vector_to_angle(vecForward, angles)
	set_pev(ent, pev_angles, angles)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_vuser4, vecForward)
	set_pev(ent, pev_owner, launcher)
	setOwner(ent, owner)
	setTeam(ent, team)
	set_pev(ent, pev_dmg, dmg)
	
	set_pev(ent, pev_nextthink, halflife_time() + 0.1)
	return ent
}

stock Float:distFromGround(Float:start[3], pSkip)
{
	static tr, Float:end[3]
	tr = create_tr2()
	end[0] = start[0]
	end[1] = start[1]
	end[2] = -8192.0
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, pSkip, tr)
	get_tr2(tr, TR_vecEndPos, end)
	free_tr2(tr)
	return vector_distance(start, end)
}

public sentryThink(ent)
{
	if(!pev_valid(ent))
		return FMRES_IGNORED
	static classname[32]
	pev(ent, pev_classname, classname, 31)
	if(equal(classname, szClasses[0]))
	{
		new head
		head = getHead(ent)
		if(head == 0)
		{
			new Float:origin[3]
			pev(ent, pev_origin, origin)
			origin[2] += 16.0// + 1.0
			head = createSentryHead(origin, getOwner(ent), getTeam(ent), getLevel(ent), ent)
			if(head != 0)
			{
				setOwner(ent, 0)
				setTeam(ent, 0)
				setLevel(ent, 0)
				setHead(ent, head)
				
				static i, num, ret
				num = get_pluginsnum()
				for(i=0;i<num;i++)
				{
					ret = get_func_id("sentry_buildingDone", i)
					if(ret == -1)
						continue
					if(callfunc_begin_i(ret, i) !=1)
						continue
					callfunc_push_int(head)
					ret = callfunc_end()
				}
			}
		}
		if(head == 0)
			kill_entity(ent)
		return FMRES_SUPERCEDE
	}
	else if(equal(classname, szClasses[1]))
	{
		static Float:gameTime, Float:deltaTime, enemy
		gameTime = halflife_time()
		deltaTime = gameTime - getLastThinkTime(ent)
		enemy = getEnemy(ent)
		setLastThinkTime(ent, gameTime)
		set_pev(ent, pev_nextthink, gameTime)
		
		/*
		new maxplayers = get_maxplayers()
	
		for( new i = 1; i <= maxplayers; i++ )
		{
		
		if ( is_user_connected(i)  )
		{
			if ( cs_get_user_team(i) == CS_TEAM_T )
			{
				switch(getLevel(ent))
				{
					case 1: changeModel(ent, szModels[1])
					case 2: changeModel(ent, szModels[2])
					case 3: changeModel(ent, szModels[3])
				}
			}
			else if ( cs_get_user_team(i) == CS_TEAM_CT )
			{
				switch(getLevel(ent))
				{
					case 1: changeModel(ent, szModels[4])
					case 2: changeModel(ent, szModels[5])
					case 3: changeModel(ent, szModels[6])
				}
			}
		}
		}
		*/

		if ( getTeam(ent) == 1)
		{
				switch(getLevel(ent))
				{
					case 1: changeModel(ent, szModels[1])
					case 2: changeModel(ent, szModels[2])
					case 3: changeModel(ent, szModels[3])
				}
		}
		else if ( getTeam(ent) == 2 )
		{
				switch(getLevel(ent))
				{
					case 1: changeModel(ent, szModels[4])
					case 2: changeModel(ent, szModels[5])
					case 3: changeModel(ent, szModels[6])
				}
		}
		
		
		/*
		switch(getLevel(ent))
		{
			case 1: changeModel(ent, szModels[1])
			case 2: changeModel(ent, szModels[2])
			case 3: changeModel(ent, szModels[3])
		}
		*/
		
		static Float:rc[3]
		pev(ent, pev_rendercolor, rc)
		
		if ( getTeam(ent) == 1)
		{
			rc[0] -= dmgGlowT[0] * deltaTime
			rc[1] -= dmgGlowT[1] * deltaTime
			rc[2] -= dmgGlowT[2] * deltaTime
		}
		else if ( getTeam(ent) == 2 )
		{
			rc[0] -= dmgGlowCT[0] * deltaTime
			rc[1] -= dmgGlowCT[1] * deltaTime
			rc[2] -= dmgGlowCT[2] * deltaTime
		}
		
		
		/*
		
		
		rc[0] -= dmgGlow[0] * deltaTime
		rc[1] -= dmgGlow[1] * deltaTime
		rc[2] -= dmgGlow[2] * deltaTime
		*/
		
		rc[0] = floatclamp(rc[0], 0.0, 255.0)
		rc[1] = floatclamp(rc[1], 0.0, 255.0)
		rc[2] = floatclamp(rc[2], 0.0, 255.0)
		set_pev(ent, pev_renderfx, ((rc[0]+rc[1]+rc[2])==0.0)?kRenderFxNone:kRenderFxGlowShell)
		set_pev(ent, pev_rendercolor, rc)
		set_pev(ent, pev_rendermode, kRenderNormal )
		set_pev(ent, pev_renderamt, 255.0)
		
		
		AnimEvents(ent, deltaTime)
		
		
		static Float:sentryOrigin[3], Float:targetOrigin[3]
		pev(ent, pev_origin, sentryOrigin)
		sentryOrigin[2] += 20.0
		
		static base
		base = getBase(ent)
		
		if(fpev(ent, pev_health) <= 0.0 || !pev_valid(base))
		{
			client_print(getOwner(ent), print_center, "Maquina destruida.")
			
			create_explosion(sentryOrigin, get_pcvar_float(g_pCvars[6]), get_pcvar_float(g_pCvars[7]), ent, getOwner(ent))
			
			sentryKilled(ent)
			kill_entity(ent)
			if(pev_valid(base))
				kill_entity(base)
			
			return FMRES_SUPERCEDE
		}
		
		set_pev(base, pev_renderfx, ((rc[0]+rc[1]+rc[2])==0.0)?kRenderFxNone:kRenderFxGlowShell)
		set_pev(base, pev_rendercolor, rc)
		set_pev(base, pev_rendermode, kRenderNormal )
		set_pev(base, pev_renderamt, 255.0)
		
		if(enemy != 0)
		{
			if(!pev_valid(enemy))
				enemy = 0
			if(!is_alive(enemy))
				enemy = 0
		}
		if(enemy != 0)
		{
			if(FBoxVisible(sentryOrigin, enemy, ent, 0.0, targetOrigin))
			{
				setLastSight(ent, targetOrigin)
				static Float:track[3]
				track[0] = targetOrigin[0] - sentryOrigin[0]
				track[1] = targetOrigin[1] - sentryOrigin[1]
				track[2] = targetOrigin[2] - sentryOrigin[2]
				vector_to_angle(track, track)
				
				if(MoveTurret(ent, track, deltaTime, true))
					setSequence(ent, 1)
				
				setTargetLostTime(ent, gameTime + 3.0)
			}
			else if(gameTime >= getTargetLostTime(ent)) // target lost
				enemy = 0
			else // target isnt in sight
			{
				setSequence(ent, 0)
				static tmp
				tmp = BestVisibleEnemy(ent, get_pcvar_float(g_pCvars[2]))
				if(tmp != 0 && tmp != enemy) // but we got another target in sight
				{
					enemy = tmp
				}
				else
				{
					getLastSight(ent, targetOrigin)
					static Float:track[3]
					track[0] = targetOrigin[0] - sentryOrigin[0]
					track[1] = targetOrigin[1] - sentryOrigin[1]
					track[2] = targetOrigin[2] - sentryOrigin[2]
					vector_to_angle(track, track)
					
					MoveTurret(ent, track, deltaTime, true)
				}
			}
		}
		if(enemy == 0)
		{
			setSequence(ent, 0)
			enemy = BestVisibleEnemy(ent, get_pcvar_float(g_pCvars[2]))
			if(enemy != 0)
			{
				if(gameTime >= getTargetLostTime(ent))
				{
					emit_sound(ent, CHAN_AUTO, szSounds[9], 0.8, ATTN_NORM, 0, PITCH_NORM)
					
					emit_sound(ent, CHAN_AUTO, szSounds[2], 0.8, ATTN_NORM, 0, PITCH_NORM)
					setTargetLostTime(ent, gameTime + 3.0)
				}
			}
			else
			{
				if (random_num(0, 99999) < 120)
					emit_sound(ent, CHAN_AUTO, szSounds[0], 0.5, ATTN_NORM, 0, PITCH_NORM)
				static Float:targetAngles[3]
				getTurretAngles(ent, targetAngles)
				targetAngles[0] = 0.0
				targetAngles[1] -= 45.0
				MoveTurret(ent, targetAngles, deltaTime, false)
			}
		}
		setEnemy(ent, enemy)
		
		if(getLevel(ent) == 3)
		{
			static Float:radarAngle, bits
			radarAngle = getRadarAngle(ent)
			bits = getBits(ent)
			if(bits & (1<<0))
			{
				radarAngle -= 255.0 * deltaTime
				if(radarAngle < 0.0)
				{
					radarAngle = 0.0
					bits &= ~(1<<0)
				}
			}
			else
			{
				radarAngle += 255.0 * deltaTime
				if(radarAngle > 255.0)
				{
					radarAngle = 255.0
					bits |= (1<<0)
				}
			}
			set_pev(ent, pev_controller_3, floatround(radarAngle))
			setRadarAngle(ent, radarAngle)
			setBits(ent, bits)
		}
		
		
		return FMRES_SUPERCEDE
	}
	else if(equal(classname, szClasses[2]))
	{
		switch(pev(ent, pev_iuser4))
		{
			case 0:
			{
				set_pev(ent, pev_effects, pev(ent, pev_effects)|EF_LIGHT)
				
				emit_sound(ent, CHAN_AUTO, szSounds[5], 0.5, ATTN_NORM, 0, PITCH_NORM)
				
				//emit_sound(ent, CHAN_VOICE, szSounds[5], 1.0, 0.5, 0, PITCH_NORM)
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMFOLLOW)
				write_short(ent)
				write_short(trail)
				write_byte(15)
				write_byte(5)
				write_byte(224)
				write_byte(224)
				write_byte(255)
				write_byte(255)
				message_end()
				
				set_pev(ent, pev_iuser4, 1)
			}
			case 1:
			{
				static Float:origin[3], Float:angles[3], Float:velocity[3], Float:vecForward[3], Float:len
				pev(ent, pev_origin, origin)
				pev(ent, pev_velocity, velocity)
				pev(ent, pev_vuser4, vecForward)
				
				if(origin[0] < -4096.0 || origin[0] > 4096.0 || origin[1] < -4096.0 || origin[1] > 4096.0 || origin[2] < - 4096.0 || origin[2] > 4096.0)
				{
					kill_entity(ent)
					return FMRES_IGNORED
				}
				
				if(g_rockettracktarget)
				{
					static target
					target = BestVisibleEnemy(ent, 1800.0, true)
					if(target && distToEnt(origin, target) >= 200.0)
					{
						BodyTarget(target, angles)
						vecForward[0] = angles[0] - origin[0]
						vecForward[1] = angles[1] - origin[1]
						vecForward[2] = angles[2] - origin[2]
						len = vector_length(vecForward)
						vecForward[0] = vecForward[0] / len
						vecForward[1] = vecForward[1] / len
						vecForward[2] = vecForward[2] / len
					}
				}
				
				len = vector_length(velocity)
				if(len < 2400.0)
				{
					velocity[0] = vecForward[0]*(500.0+len)
					velocity[1] = vecForward[1]*(500.0+len)
					velocity[2] = vecForward[2]*(500.0+len)
				}
				
				vector_to_angle(velocity, angles)
				
				set_pev(ent, pev_angles, angles)
				set_pev(ent, pev_velocity, velocity)
				set_pev(ent, pev_vuser4, vecForward)
			}
		}
		set_pev(ent, pev_nextthink, halflife_time() + 0.1)
		return FMRES_SUPERCEDE
	}
	
	
	return FMRES_IGNORED
}




public sentryTakeDamage(this, pevInflictor, pevAttacker, Float:flDamage, iDamageBits)
{
	if(!pev_valid(this))
		return HAM_IGNORED
	static classname[32], Float:health
	pev(this, pev_classname, classname, 31)
	pev(this, pev_health, health)
	if(equal(classname, szClasses[0]))
	{
		return HAM_SUPERCEDE
	}
	else if(equal(classname, szClasses[1]))
	{
		if(iDamageBits & (DMG_FALL|DMG_DROWN|DMG_FREEZE|DMG_NERVEGAS|DMG_POISON|DMG_RADIATION))
			return HAM_SUPERCEDE
			
		new Float:tmp = floatclamp(flDamage/50.0, 0.3, 1.0)
		new Float:tmp2[3]
		
		
		if ( getTeam(this) == 1)
		{
			tmp2[0] = dmgGlowT[0] * tmp
			tmp2[1] = dmgGlowT[1] * tmp
			tmp2[2] = dmgGlowT[2] * tmp
		}
		else if ( getTeam(this) == 2 )
		{
			tmp2[0] = dmgGlowCT[0] * tmp
			tmp2[1] = dmgGlowCT[1] * tmp
			tmp2[2] = dmgGlowCT[2] * tmp
		}
		

		/*
		tmp2[0] = dmgGlow[0] * tmp
		tmp2[1] = dmgGlow[1] * tmp
		tmp2[2] = dmgGlow[2] * tmp
		*/
		
		set_pev(this, pev_renderfx, kRenderFxGlowShell)
		set_pev(this, pev_rendercolor, tmp2)
		set_pev(this, pev_rendermode, kRenderNormal)
		set_pev(this, pev_renderamt, 255.0)
		
		if(fpev(this, pev_takedamage) == 0.0)
			return HAM_SUPERCEDE
		
		health -= flDamage*get_pcvar_float(g_pCvars[8])
		
		//damage no team
		if(pevAttacker != this && 1 <= pevAttacker <= MaxPlayers && getTeam(this) == getTeam(pevAttacker))
		//block damage maquina team
		SetHamParamEntity(1, pevAttacker),
		//incremente damage attacker team
		ExecuteHamB( Ham_TakeDamage, pevAttacker, pevInflictor, pevAttacker, flDamage / 3.0, DMG_GENERIC );
		else
		
		
		set_pev(this, pev_health, health)
		set_pev(this, pev_nextthink, halflife_time())
		
		return HAM_SUPERCEDE	
		
	}
	return HAM_IGNORED
	
	
}


public bool:MoveTurret(sentry, Float:targetAngles[3], Float:deltaTime, bool:Boost)
{
	if(targetAngles[0] > 180.0)
		targetAngles[0] -= 360.0
	if(targetAngles[1] < 0)
		targetAngles[1] += 360.0
	else if(targetAngles[1] > 360.0)
		targetAngles[1] -= 360.0
	static Float:curAngles[3], Float:TurnRate, Float:dir[2]
	getTurretAngles(sentry, curAngles)
	TurnRate = getTurnRate(sentry)
	dir[0] = targetAngles[0] > curAngles[0] ? 1.0 : -1.0
	dir[1] = targetAngles[1] > curAngles[1] ? 1.0 : -1.0
	if(curAngles[0] != targetAngles[0])
	{
		curAngles[0] += deltaTime * 80.0 * dir[0]
		if(dir[0] == 1.0)
		{
			if(curAngles[0] > targetAngles[0])
				curAngles[0] = targetAngles[0]
		}
		else
		{
			if(curAngles[0] < targetAngles[0])
				curAngles[0] = targetAngles[0]
		}
	}
	if(curAngles[1] != targetAngles[1])
	{
		static Float:flDist
		flDist = fabs(targetAngles[1] - curAngles[1])
		if(flDist > 180.0)
		{
			flDist = 360 - flDist
			dir[1] = -dir[1]
		}
		if(Boost)
		{
			if(flDist > 30.0)
			{
				if(TurnRate < 120.0)
				{
					TurnRate += 25.0
				}
			}
			else if(TurnRate > 80.0)
			{
				TurnRate -= 25.0
			}
			else
			{
				TurnRate += 25.0
			}
		}
		else
			TurnRate = 25.0
		curAngles[1] += deltaTime * TurnRate * dir[1]
		if(curAngles[1] < 0.0)
			curAngles[1] += 360.0
		else if(curAngles[1] >= 360.0)
			curAngles[1] -= 360.0
		if(flDist < 1.5)
			curAngles[1] = targetAngles[1]
	}
	setTurretAngles(sentry, curAngles)
	setTurnRate(sentry, TurnRate)
	
	new Float:tmpAngle[3]
	tmpAngle[0] = 0.0
	tmpAngle[1] = curAngles[1]
	set_pev(sentry, pev_angles, tmpAngle)
	
	new Float:tmp
	tmp = curAngles[0]
	tmp = -floatclamp(tmp, -45.0, 45.0) + 45.0
	tmp = 255.0 * (tmp/90.0)
	tmp = floatclamp(tmp, 0.0, 255.0)
	set_pev(sentry, pev_controller_1, floatround(tmp))
	
	return (((curAngles[0] == targetAngles[0]) && (curAngles[1] == targetAngles[1])) || TrackSentryAim(sentry)==getEnemy(sentry))?true:false
}

TrackSentryAim(sentry)
{
	static Float:vecSrc[3], Float:vecAngles[3], Float:vecDirShooting[3]
	pev(sentry, pev_origin, vecSrc)
	vecSrc[2] += 20.0
	getTurretAngles(sentry, vecAngles)
	vecAngles[0] *= -1.0
	angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecDirShooting)
	static tr, Float:vecEnd[3], pHit, Float:vecEndPos[3]
	tr = create_tr2()
	vecEnd[0] = vecSrc[0] + vecDirShooting[0] * 8192.0
	vecEnd[1] = vecSrc[1] + vecDirShooting[1] * 8192.0
	vecEnd[2] = vecSrc[2] + vecDirShooting[2] * 8192.0
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, sentry, tr)
	pHit = get_tr2(tr, TR_pHit)
	get_tr2(tr, TR_vecEndPos, vecEndPos)
	while(pHit != -1)
	{
		if(is_sentrygun(sentry) && ((pHit == sentry) || (pHit == getBase(sentry))))
		{
			vecEndPos[0] += vecDirShooting[0] * 5.0
			vecEndPos[1] += vecDirShooting[1] * 5.0
			vecEndPos[2] += vecDirShooting[2] * 5.0
			engfunc(EngFunc_TraceLine, vecEndPos, vecEnd, 0, pHit, tr)
			pHit = get_tr2(tr, TR_pHit)
			get_tr2(tr, TR_vecEndPos, vecEndPos)
			continue
		}
		break
	}
	free_tr2(tr)
	return (pHit!=-1)?pHit:0
}

public AnimEvents(ent, Float:deltaTime)
{
	static Float:AnimFloats[3], seq, level
	getAnimFloats(ent, AnimFloats)
	seq = pev(ent, pev_sequence)
	level = getLevel(ent)
	
	if(seq == 1)
	{
		AnimFloats[1] = AnimFloats[0]
		AnimFloats[0] += 33.0 * deltaTime
		if(AnimFloats[0] > 11.0)
			AnimFloats[0] -= 11.0
		
		if(level == 3)
			AnimFloats[2] += deltaTime
		
		switch(level)
		{
			case 1:
			{
				if(AnimFloats[1] > AnimFloats[0])
					sentryShoot(ent)
			}
			case 2:
			{
				if(AnimFloats[1] > AnimFloats[0])
					sentryShoot(ent)
				else if(AnimFloats[1] < 8.0 && AnimFloats[0] >= 8.0)
					sentryShoot(ent)
			}
			case 3:
			{
				if(AnimFloats[1] > AnimFloats[0])
					sentryShoot(ent)
				else if(AnimFloats[1] < 4.0 && AnimFloats[0] >= 4.0)
					sentryShoot(ent)
				else if(AnimFloats[1] < 5.0 && AnimFloats[0] >= 5.0)
					sentryShoot(ent)
				else if(AnimFloats[1] < 8.0 && AnimFloats[0] >= 8.0)
					sentryShoot(ent)
				else if(AnimFloats[2] > g_rocketdelay)
				{
					static rockets
					rockets = pev(ent, pev_iuser4) -1
					if(rockets > 0)
					{
						AnimFloats[2] -= 0.4
					}
					else
					{
						rockets = g_rocketamount
						AnimFloats[2] -= g_rocketdelay
					}
					set_pev(ent, pev_iuser4, rockets)
					sentryLaunch(ent)
				}
			}
		}
		emit_sound(ent, CHAN_AUTO, szSounds[4], 0.8, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		AnimFloats[0] = 0.0
		AnimFloats[1] = 0.0
		AnimFloats[2] = 0.0
		
		set_pev(ent, pev_iuser4, g_rocketamount)
	}
	
	setAnimFloats(ent, AnimFloats)
}

stock bool:is_breakable(ent)
{
	if((fpev(ent, pev_health)>0.0) && (fpev(ent, pev_takedamage)>0.0) && !(pev(ent, pev_spawnflags)&SF_BREAK_TRIGGER_ONLY))
		return true
	return false
}

stock bool:is_rocket(ent)
{
	static classname[32]
	pev(ent, pev_classname, classname, 31)
	if(equal(classname, szClasses[2]))
		return true
	return false
}


stock bool:is_sentrygun(ent)
{
	static classname[32]
	pev(ent, pev_classname, classname, 31)
	if(equal(classname, szClasses[1]))
		return true
	return false
}

stock bool:is_sentrybase(ent)
{
	static classname[32]
	pev(ent, pev_classname, classname, 31)
	if(equal(classname, szClasses[0]))
		return true
	return false
}

stock Float:getLevelHealth(level)
{
	switch(level)
	{
		case 1: return get_pcvar_float(g_pCvars[3])
		case 2: return get_pcvar_float(g_pCvars[4])
		case 3: return get_pcvar_float(g_pCvars[5])
	}
	return 1.0
}

stock changeModel(ent, model[])
{
	static s[256]
	pev(ent, pev_model, s, 255)
	if(!equal(s, model))
	{
		engfunc(EngFunc_SetModel, ent, model)
		engfunc(EngFunc_SetSize, ent, flSizes[2], flSizes[3])
	}
}

stock setSequence(ent, sequence)
{
	if(pev(ent, pev_sequence) != sequence)
	{
		set_pev(ent, pev_framerate, 1.0)
		set_pev(ent, pev_sequence, sequence)
	}
}

stock Float:fabs(Float:a) { return a>0.0?a:-a; }

stock Float:distToEnt(Float:src[3], ent)
{
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	return vector_distance(origin, src)
}

stock BodyTarget(ent, Float:vecTarget[3])
{
	static Float:absmin[3], Float:absmax[3]
	pev(ent, pev_absmin, absmin)
	pev(ent, pev_absmax, absmax)
	vecTarget[0] = (absmin[0] + absmax[0]) * 0.5
	vecTarget[1] = (absmin[1] + absmax[1]) * 0.5
	vecTarget[2] = (absmin[2] + absmax[2]) * 0.5
}

stock bool:FVisible(Float:vecSrc[3], pTarget, pSkip)
{
	static tr, Float:vecTarget[3], Float:flFraction
	tr = create_tr2()
	BodyTarget(pTarget, vecTarget)
	engfunc(EngFunc_TraceLine, vecSrc, vecTarget, (1 | 0x100), pSkip, tr)
	get_tr2(tr, TR_flFraction, flFraction)
	free_tr2(tr)
	return (flFraction == 1.0)
}

stock bool:FBoxVisible(Float:vecSrc[3], pTarget, pSkip, Float:flSize, Float:vecTargetOrigin[3])
{
	static tr, Float:vecTarget[3], Float:mins[3], Float:maxs[3], Float:flFraction
	tr = create_tr2()
	for (new i = 0; i < 5; i++)
	{
		pev(pTarget, pev_origin, vecTarget)
		pev(pTarget, pev_mins, mins)
		pev(pTarget, pev_maxs, maxs)
		vecTarget[0] += random_float( mins[0] + flSize, maxs[0] - flSize )
		vecTarget[1] += random_float( mins[1] + flSize, maxs[1] - flSize )
		vecTarget[2] += random_float( mins[2] + flSize, maxs[2] - flSize )
		
		engfunc(EngFunc_TraceLine, vecSrc, vecTarget, (1 | 0x100), pSkip, tr)
		
		get_tr2(tr, TR_flFraction, flFraction)

		if (flFraction == 1.0)
		{
			vecTargetOrigin[0] = vecTarget[0]
			vecTargetOrigin[1] = vecTarget[1]
			vecTargetOrigin[2] = vecTarget[2]
			free_tr2(tr)
			return true // line of sight is valid.
		}
	}
	free_tr2(tr)
	return false
}

stock bool:FInViewCone(this, Float:vecTarget[3])
{
	static Float:angles[3], Float:v_forward[3], Float:vec2LOS[2], Float:flDot, Float:flLen
	pev(this, pev_angles, angles)
	
	pev(this, pev_origin, v_forward)
	vec2LOS[0] = vecTarget[0] - v_forward[0]
	vec2LOS[1] = vecTarget[1] - v_forward[1]
	
	flLen = floatsqroot((vec2LOS[0]*vec2LOS[0])+(vec2LOS[1]*vec2LOS[1]))
	if(flLen == 0)
	{
		vec2LOS[0] = 0.0
		vec2LOS[1] = 0.0
	}
	else
	{
		flLen = 1/flLen
		vec2LOS[0] = vec2LOS[0]*flLen
		vec2LOS[1] = vec2LOS[1]*flLen
	}
	
	angle_vector(angles, ANGLEVECTOR_FORWARD, v_forward)
	
	flDot = vec2LOS[0]*v_forward[0] + vec2LOS[1]*v_forward[1]
	
	if(flDot > 0.5)
		return true
	return false
}

stock BestVisibleEnemy(this, Float:range, bool:CheckViewCone=false)
{
	static Float:vecSrc[3], Float:vecTarget[3]
	pev(this, pev_origin, vecSrc)
	pev(this, pev_view_ofs, vecTarget)
	vecSrc[0] += vecTarget[0]
	vecSrc[1] += vecTarget[1]
	vecSrc[2] += vecTarget[2]
	
	static Best, Float:bestDist
	Best = 0
	bestDist = range
	new ent = -1
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, range)) != 0)
	{
		if(!pev_valid(ent))
			continue
		if(!is_alive(ent))
			continue
		if(!couldBeTarget(ent, this))
			continue
		BodyTarget(ent, vecTarget)
		if(CheckViewCone && !FInViewCone(this, vecTarget))
			continue
		if(!FVisible(vecSrc, ent, this))
			continue
		static Float:dist
		dist = distToEnt(vecSrc, ent)
		if(dist <= bestDist)
		{
			Best = ent
			bestDist = dist
		}
	}
	return Best
}

stock create_explosion(Float:origin[3], Float:dmg, Float:range, inflictor, attacker)
{
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(boom)
	write_byte(30)
	write_byte(30)
	write_byte(10)
	message_end()
	
	/*
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(boom)
	write_byte(floatround((dmg - 50.0)*0.6))
	write_byte(15)
	write_byte(TE_EXPLFLAG_NONE)
	message_end()
	*/
	
	damageRadius(origin, dmg, DMG_BLAST, range, 1, inflictor, attacker)
}

stock damageRadius(Float:origin[3], Float:dmg, damagebits, Float:radius, mode, inflictor, attacker)
{
	if(attacker == 0)
		attacker = inflictor
	new ent = -1, Float:vecTarget[3], Float:ndmg
	
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, origin, radius)) != 0)
	{
		if(!pev_valid(ent))
			continue
		if(ent == inflictor)
			continue
		if(!is_breakable(ent))
			continue
		if(!FBoxVisible(origin, ent, inflictor, 0.0, vecTarget))
			continue
		ndmg = (mode==1)?(((radius-distToEnt(origin, ent))/radius)*dmg):dmg
		if(ndmg < 0.1)
			ndmg = 0.1
			
		set_pev(ent, pev_dmg_inflictor, inflictor)
		
		ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, ndmg, damagebits)
	}	
	
}

tracer(Float:start[3], Float:end[3]) {
	//new start_[3]
	new start_[3], end_[3]
	FVecIVec(start, start_)
	FVecIVec(end, end_)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
	write_byte(TE_TRACER)
	write_coord(start_[0])
	write_coord(start_[1])
	write_coord(start_[2])
	write_coord(end_[0])
	write_coord(end_[1])
	write_coord(end_[2])
	message_end()
}

gunshot(Float:origin[3], hit) {
	if(!pev_valid(hit))
		hit = 0
	if(!ExecuteHam(Ham_IsBSPModel, hit))
		return
	new origin_[3]
	FVecIVec(origin,origin_)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOT)
	write_coord(origin_[0])
	write_coord(origin_[1])
	write_coord(origin_[2])
	message_end()
}


public FireBullets(iShots, Float:vecSrc[3], Float:vecDirShooting[3], Float:flDamage, pevAttacker, pevInflictor)
{
	if(pevInflictor == 0)
		pevInflictor = pevAttacker
	static tr, Float:vecEnd[3], pHit, Float:vecEndPos[3]
	tr = create_tr2()
	vecEnd[0] = vecSrc[0] + vecDirShooting[0] * 8192.0
	vecEnd[1] = vecSrc[1] + vecDirShooting[1] * 8192.0
	vecEnd[2] = vecSrc[2] + vecDirShooting[2] * 8192.0
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, pevInflictor, tr)
	pHit = get_tr2(tr, TR_pHit)
	get_tr2(tr, TR_vecEndPos, vecEndPos)
	
	
	while(pHit != -1)
	{
		if(is_sentrygun(pevInflictor) && ((pHit == pevInflictor) || (pHit == getBase(pevInflictor))))
		{
			vecEndPos[0] += vecDirShooting[0] * 5.0
			vecEndPos[1] += vecDirShooting[1] * 5.0
			vecEndPos[2] += vecDirShooting[2] * 5.0
			engfunc(EngFunc_TraceLine, vecEndPos, vecEnd, 0, pHit, tr)
			pHit = get_tr2(tr, TR_pHit)
			get_tr2(tr, TR_vecEndPos, vecEndPos)
			continue
		}
		
		if(is_breakable(pHit))
		{
			set_pev(pHit, pev_dmg_inflictor, pevInflictor)
			//ExecuteHamB(Ham_TraceAttack, pHit, pevAttacker, flDamage, vecDirShooting, tr, DMG_BULLET)
			
			ExecuteHamB(Ham_TakeDamage, pHit, pevInflictor, pevAttacker, flDamage, DMG_BULLET)
			ExecuteHamB(Ham_TraceBleed, pHit, flDamage, vecDirShooting, tr, DMG_BULLET)
			
		}
		
		
		if(--iShots)
		{
			flDamage *= 0.7
			vecEndPos[0] += vecDirShooting[0] * 5.0
			vecEndPos[1] += vecDirShooting[1] * 5.0
			vecEndPos[2] += vecDirShooting[2] * 5.0
			engfunc(EngFunc_TraceLine, vecEndPos, vecEnd, 0, pHit, tr)
			pHit = get_tr2(tr, TR_pHit)
			get_tr2(tr, TR_vecEndPos, vecEndPos)
			continue
		}
		break
	}
	
	tracer(vecSrc, vecEndPos)
	gunshot(vecEndPos, pHit)
	free_tr2(tr)
}

stock sentryShoot(ent)
{
	static Float:sentryOrigin[3],Float:sentryAngle[3],Float:v_forward[3]
	pev(ent, pev_origin, sentryOrigin)
	sentryOrigin[2] += 20.0
	getTurretAngles(ent, sentryAngle)
	sentryAngle[0] *= -1.0
	angle_vector(sentryAngle, ANGLEVECTOR_FORWARD, v_forward)
	
	FireBullets(1, sentryOrigin, v_forward, random_float(g_bulletdmg[0], g_bulletdmg[1]), getOwner(ent), ent)
	
	emit_sound(ent, CHAN_WEAPON, szSounds[4], 0.3, ATTN_NORM, 0, PITCH_NORM)
	
	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_MUZZLEFLASH)
}

stock sentryLaunch(ent)
{
	static Float:sentryOrigin[3],Float:sentryAngle[3],Float:v_forward[3]
	pev(ent, pev_origin, sentryOrigin)
	sentryOrigin[2] += 25.0
	getTurretAngles(ent, sentryAngle)
	sentryAngle[0] *= -1.0
	angle_vector(sentryAngle, ANGLEVECTOR_FORWARD, v_forward)
	
	static i, num, ret
	num = get_pluginsnum()
	for(i=0;i<num;i++)
	{
		ret = get_func_id("sentry_launch", i)
		if(ret == -1)
			continue
		if(callfunc_begin_i(ret, i) !=1 )
			continue
		callfunc_push_int(ent)
		ret = callfunc_end()
		if(ret != PLUGIN_CONTINUE) return
	}
	
	createHVRrocket(sentryOrigin, v_forward, ent, getOwner(ent), getTeam(ent), get_pcvar_float(g_pCvars[9]))
}

stock couldBeTarget(ent, sentry)
{
	if(!pev_valid(ent))
		return false
	static i, num, ret
	num = get_pluginsnum()
	for(i=0;i<num;i++)
	{
		ret = get_func_id("sentry_couldBeTarget", i)
		if(ret == -1)
			continue
		if(callfunc_begin_i(ret, i) !=1 )
			continue
		callfunc_push_int(ent)
		callfunc_push_int(sentry)
		ret = callfunc_end()
		if(ret != -1) return (ret!=0)
	}
	return is_breakable(ent) && (ent != sentry) && (ent != getOwner(sentry)) && ((getTeam(sentry) == 0) || getTeam(sentry) != getTeam(ent))
}

stock sentryKilled(ent)
{
	static i, num, ret
	num = get_pluginsnum()
	for(i=0;i<num;i++)
	{
		ret = get_func_id("sentry_killed", i)
		if(ret == -1)
			continue
		if(callfunc_begin_i(ret, i) !=1 )
			continue
		callfunc_push_int(ent)
		ret = callfunc_end()
	}
}
