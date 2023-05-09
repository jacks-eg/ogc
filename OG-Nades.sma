#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <engine>
#include <fun>
#include <amxmisc>
#include <xs>

#define PLUGIN "[ZE] Granadas"
#define VERSION "1.1"
#define AUTHOR "[M]etrikcz"

#define ID_BLOOD (taskid - TASK_BLOOD)
#define TASK_BLOOD 9876
#define pev_nade_type        pev_flTimeStepSound
/***************************************************************************************************************/
new g_fire_trail, g_fireexp , g_fire_gibs
/****************************************************************************************************************/

const Float:FREEZE_DURATION = 3.0
const DROGE_DURATION = 2
const FIRE_DURATION = 15
const FIRE_DAMAGE = 5

const BREAK_GLASS = 0x01 
const FFADE_IN = 0x0000
const UNIT_SECOND = (1<<12)
const Float:NADE_EXPLOSION_RADIUS = 240.0

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
			
enum {
	NADE_HE,
	NADE_FB,
	NADE_SM,
	MAXTYPE_NADE
}
enum {
	NADE_FIRE,
	NADE_FROST,
	NADE_DROGE
}

enum caract_nades { NadeName[20], NadeRed, NadeGreen, NadeBlue, NadeVModel[50],NadePModel[50], NadeWModel[50] }
new const nadeinfo[][caract_nades] = {
	{ "Fire Nade", 255, 0, 0, "models/og_ctf1-0b/weapons/v_hegrenade.mdl", "models/og_ctf1-0b/weapons/p_hegrenade.mdl", "models/og_ctf1-0b/weapons/w_hegrenade.mdl" },
	{ "Frost Nade",  0, 0, 255, "models/v_flashbang.mdl", "models/p_flashbang.mdl", "models/w_flashbang.mdl" },
	{ "Frost Nade",  0, 255, 0, "models/v_smokegrenade.mdl", "models/p_smokegrenade.mdl", "models/w_smokegrenade.mdl" }
}

new const nadeweapon[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" }
new g_nade[33][MAXTYPE_NADE]

public plugin_precache() 
{
	new i
	for(i = 0; i < sizeof nadeinfo; i++) 
	{
		precache_model(nadeinfo[i][NadeVModel])
		precache_model(nadeinfo[i][NadePModel])
		precache_model(nadeinfo[i][NadeWModel])
	}	
	
	g_fire_trail = precache_model ("sprites/og_ctf1-0b/HE_Trail.spr")
	g_fireexp = precache_model("sprites/og_ctf1-0b/HE_Exp.spr")
	g_fire_gibs = precache_model("sprites/og_ctf1-0b/HE_Gibs.spr")
}


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_SetModel,"fw_SetModel", 1)
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGren")
	//RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++) 
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy", 1)
	/*
	g_msgDamage = get_user_msgid("Damage")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgScreenFade = get_user_msgid("ScreenFade")*/
	
	//register_concmd("say .nades", "cmd_nades")
}

public plugin_natives() 
{
	register_native("give_nade", "native_give_grenade", 1)
}
/*
public fw_takedamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(is_user_connected(attacker) && is_user_alive(victim) && g_frozen[victim]) {
		if((pev(victim, pev_health) - damage) < 1.0) {
			set_pev(victim, pev_health, 1.0)
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}*/

public fw_Item_Deploy(weapon_ent) {
	if(!pev_valid(weapon_ent)) 
		return HAM_IGNORED;
		
	static id, weaponid
	
	id = get_pdata_cbase(weapon_ent, 41, 4)
	weaponid = cs_get_weapon_id(weapon_ent)
	
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	switch(weaponid) {
		case CSW_HEGRENADE: {
			set_pev(id, pev_viewmodel2, nadeinfo[g_nade[id][NADE_HE]][NadeVModel])
			set_pev(id, pev_weaponmodel2, nadeinfo[g_nade[id][NADE_HE]][NadePModel])
		}
		case CSW_FLASHBANG: {
			set_pev(id, pev_viewmodel2, nadeinfo[g_nade[id][NADE_FB]][NadeVModel])
			set_pev(id, pev_weaponmodel2, nadeinfo[g_nade[id][NADE_FB]][NadePModel])
		}
		case CSW_SMOKEGRENADE: {
			set_pev(id, pev_viewmodel2, nadeinfo[g_nade[id][NADE_SM]][NadeVModel])
			set_pev(id, pev_weaponmodel2, nadeinfo[g_nade[id][NADE_SM]][NadePModel])
		}
	}
	return HAM_IGNORED;
}
public fw_SetModel(entity, const model[])  {
	static Float:dmgtime, owner
	pev(entity, pev_dmgtime, dmgtime);
	owner = pev(entity, pev_owner);
	
	if(!is_user_connected(owner)) 
		return FMRES_IGNORED;
		
	/*if(ZB_GetUserZombie(owner))
		return FMRES_IGNORED;*/
	
	if(!pev_valid(entity) || dmgtime == 0.0)
		return FMRES_IGNORED;

	if (model[9] == 'h' && model[10] == 'e') {
		entity_set_model(entity, nadeinfo[g_nade[owner][NADE_HE]][NadeWModel])
		set_pev(entity, pev_flTimeStepSound, g_nade[owner][NADE_HE])
		set_rendering(entity, kRenderFxGlowShell, nadeinfo[g_nade[owner][NADE_HE]][NadeRed], nadeinfo[g_nade[owner][NADE_HE]][NadeGreen], nadeinfo[g_nade[owner][NADE_HE]][NadeBlue])
	
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_fire_trail) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(200) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(200) // brightness
		message_end()
		
	}/*
	else if (model[9] == 'f' && model[10] == 'l') 
	{ 
		entity_set_model(entity, nadeinfo[g_nade[owner][NADE_FB]][NadeWModel])
		set_pev(entity, pev_flTimeStepSound, g_nade[owner][NADE_FB])
		set_rendering(entity, kRenderFxGlowShell, nadeinfo[g_nade[owner][NADE_FB]][NadeRed], nadeinfo[g_nade[owner][NADE_FB]][NadeGreen], nadeinfo[g_nade[owner][NADE_FB]][NadeBlue])
	
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_frost_trail) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(0) // r
		write_byte(100) // g
		write_byte(200) // b
		write_byte(200) // brightness
		message_end()
	}
	else if (model[9] == 's' && model[10] == 'm') 
	{
		entity_set_model(entity, nadeinfo[g_nade[owner][NADE_SM]][NadeWModel])
		set_pev(entity, pev_flTimeStepSound, g_nade[owner][NADE_SM])
		set_rendering(entity, kRenderFxGlowShell, nadeinfo[g_nade[owner][NADE_SM]][NadeRed], nadeinfo[g_nade[owner][NADE_SM]][NadeGreen], nadeinfo[g_nade[owner][NADE_SM]][NadeBlue])
		grenade_trail(entity, nadeinfo[g_nade[owner][NADE_SM]][NadeRed], nadeinfo[g_nade[owner][NADE_SM]][NadeGreen], nadeinfo[g_nade[owner][NADE_SM]][NadeBlue])
	}*/
	else 
		return FMRES_IGNORED;

	return FMRES_SUPERCEDE;
}

public fw_ThinkGren(entity)  {
	if (!pev_valid(entity) || !is_valid_ent(entity))
		return HAM_IGNORED;

	static Float:dmgtime, Float: current_time, id, Float:originF[3]
	pev(entity, pev_dmgtime, dmgtime)
	current_time = get_gametime()
	id = pev(entity, pev_owner)
		
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	if(dmgtime > current_time)
		return HAM_IGNORED;
		
	new num = pev(entity, pev_flTimeStepSound)
	pev(entity, pev_origin, originF)	
	
	//if(pev(entity, pev_nade_type) == NADE_FROST)create_blast(originF);
	if(pev(entity, pev_nade_type) == NADE_FIRE)create_blast2(originF);
	//if(pev(entity, pev_nade_type) == NADE_DROGE)create_blast3(originF);
	
	switch(num)
	{
		case NADE_FIRE: fire_explote(entity)
		//case NADE_FROST: frost_explote(entity)
		//case NADE_DROGE: droge_explote(entity)
		default: return HAM_IGNORED;
	}
	return HAM_SUPERCEDE;
}
/*
droge_explote(ent) 
{
	static attacker 
	attacker = pev(ent, pev_owner)
	
	if(!is_user_connected(attacker)) {
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	static Float:originF[3]  
	pev(ent, pev_origin, originF)

	static victim, args[1]
	victim = -1
	args[0] = DROGE_DURATION
		
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if (!is_user_alive(victim) || !ZB_GetUserZombie(victim))
			continue;
				
		set_rendering(victim, kRenderFxGlowShell, 0, 255, 0)		
		set_task(0.1, "drogar", victim, args, sizeof args)	
	}
	engfunc(EngFunc_RemoveEntity, ent)
}
	
public drogar(tiempo[1], id)
{
	if(tiempo[0] < 1 || !is_user_alive(id)) {
		set_rendering(id)
		return;
	}
		
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short((1<<12)) 
	write_short(0) 
	write_short(0x0000) 
	write_byte(0) 
	write_byte(255) 
	write_byte(0) 
	write_byte(200) 
	message_end()
	
	new Float:fVec[3]
	fVec[0] = random_float(50.0, 150.0)
	fVec[1] = random_float(50.0, 150.0)
	fVec[2] = random_float(50.0, 150.0)
	set_pev(id, pev_punchangle, fVec)
	
	tiempo[0]--
	set_task(1.0, "drogar", id, tiempo, sizeof tiempo)
}*/
fire_explote(ent) 
{
	
	new attacker; attacker = pev(ent, pev_owner)
	if(!is_user_connected(attacker)) 
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	static Float:originF[3]//,  attacker, owner
	pev(ent, pev_origin, originF)

	//
	//owner = pev(ent, pev_owner)

	message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SPRITETRAIL ) // Throws a shower of sprites or models
	engfunc(EngFunc_WriteCoord, originF[ 0 ]) // start pos
	engfunc(EngFunc_WriteCoord, originF[ 1 ])
	engfunc(EngFunc_WriteCoord, originF[ 2 ] + 200.0)
	engfunc(EngFunc_WriteCoord, originF[ 0 ]) // velocity
	engfunc(EngFunc_WriteCoord, originF[ 1 ])
	engfunc(EngFunc_WriteCoord, originF[ 2 ] + 30.0)
	write_short(g_fire_gibs) // spr
	write_byte(60) // (count)
	write_byte(random_num(27,30)) // (life in 0.1's)
	write_byte(2) // byte (scale in 0.1's)
	write_byte(50) // (velocity along vector in 10's)
	write_byte(10) // (randomness of velocity in 10's)
	message_end()
	
	/*
	static victim
	victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if (!is_user_alive(victim) || !ZB_GetUserZombie(victim) )
			continue;
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, victim)
		write_byte(0) 
		write_byte(0) 
		write_long(DMG_BURN) 
		write_coord(0) 
		write_coord(0) 
		write_coord(0) 
		message_end()

		message_begin(MSG_ONE, g_msgScreenShake, {0, 0, 0}, victim)
		write_short(UNIT_SECOND*75)
		write_short(UNIT_SECOND*3)
		write_short(UNIT_SECOND*75)
		message_end()

		static params[2]
		params[0] = FIRE_DURATION
		params[1] = owner

		set_task(0.1, "burning_flame", victim+TASK_BLOOD, params, sizeof params)
	}*/
	engfunc(EngFunc_RemoveEntity, ent)
}
/*
frost_explote(ent) 
{
	static attacker 
	attacker = pev(ent, pev_owner)
	
	if(!is_user_connected(attacker)) {
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	static Float:originF[3], Float:originx[3], ent2
	pev(ent, pev_origin, originF)

	static victim
	victim = -1
	
	message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SPRITETRAIL ) // Throws a shower of sprites or models
	engfunc(EngFunc_WriteCoord, originF[ 0 ]) // start pos
	engfunc(EngFunc_WriteCoord, originF[ 1 ])
	engfunc(EngFunc_WriteCoord, originF[ 2 ] + 200.0)
	engfunc(EngFunc_WriteCoord, originF[ 0 ]) // velocity
	engfunc(EngFunc_WriteCoord, originF[ 1 ])
	engfunc(EngFunc_WriteCoord, originF[ 2 ] + 30.0)
	write_short(g_frost_gibs) // spr
	write_byte(60) // (count)
	write_byte(random_num(27,30)) // (life in 0.1's)
	write_byte(2) // byte (scale in 0.1's)
	write_byte(50) // (velocity along vector in 10's)
	write_byte(10) // (randomness of velocity in 10's)
	message_end() 
	
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if (!is_user_alive(victim) || !ZB_GetUserZombie(victim) || g_frozen[victim])
			continue;

		freeze_player(victim)	

		ent2 = create_entity("info_target")
		pev(victim, pev_origin, originx)
		originx[2] -= 35.0
		set_pev(ent2, pev_body, 1)
		entity_set_model(ent2, "models/mro_zev2/iceblock.mdl")
		set_pev(ent2, pev_origin, originx)
		set_pev(ent2, pev_owner, victim)
		set_rendering(ent2, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255)
		set_pev(ent2, pev_classname, "zpss_icebue")
		set_pev(ent2, pev_solid, 2) 
		set_task(FREEZE_DURATION, "remove_icecube", ent2)
	}
	
	emit_sound(ent, CHAN_WEAPON, sound_frostplayer, 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_RemoveEntity, ent)
}

freeze_player(victim, fw=0) {
	new Float:duration
	if(fw) {
		duration = (g_last_fw[fw]-get_gametime())
		if(duration <= 0) 
			return;
	}
	
	else duration = FREEZE_DURATION
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, victim)
	write_byte(0) 
	write_byte(0) 
	write_long(DMG_DROWN) 
	write_coord(0) 
	write_coord(0)
	write_coord(0) 
	message_end()
	
	message_begin(MSG_ONE, g_msgScreenShake, {0, 0, 0}, victim)
	write_short(UNIT_SECOND*75)
	write_short(UNIT_SECOND*3)
	write_short(UNIT_SECOND*75)
	message_end()
	
	set_rendering(victim, kRenderFxGlowShell, 0, 100, 200)
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, victim)
	write_short(floatround(UNIT_SECOND*duration)) 
	write_short(floatround(UNIT_SECOND*duration)) 
	write_short(FFADE_IN) 
	write_byte(0) 
	write_byte(50) 
	write_byte(200) 
	write_byte(100) 
	message_end()
	
	g_frozen[victim] = true;
	
	set_pev(victim, pev_velocity , { 0.0 , 0.0 , 0.0 } )
	set_pev(victim, pev_flags, pev(victim, pev_flags) | FL_FROZEN) 
	set_task(duration, "remove_freeze", victim)
}
public remove_icecube(ent) {
	if(pev_valid(ent)) 
		remove_entity(ent)
}
public remove_freeze(id) {
	g_frozen[id] = false;
	
	if (!is_user_alive(id))
		return;

	set_pev(id, pev_flags , pev(id , pev_flags) & ~FL_FROZEN)	
	set_rendering(id)

	static Float:origin2F[3]
	pev(id, pev_origin, origin2F)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin2F, 0)
	write_byte(TE_BREAKMODEL) 
	engfunc(EngFunc_WriteCoord, origin2F[0])
	engfunc(EngFunc_WriteCoord, origin2F[1]) 
	engfunc(EngFunc_WriteCoord, origin2F[2]+24.0) 
	write_coord(16) 
	write_coord(16) 
	write_coord(16) 
	write_coord(random_num(-50, 50)) 
	write_coord(random_num(-50, 50)) 
	write_coord(25) 
	write_byte(10) 
	write_short(g_glass) 
	write_byte(10) 
	write_byte(25) 
	write_byte(BREAK_GLASS) 
	message_end()
}

public burning_flame(args[2], taskid)
{
	if(!is_user_alive(ID_BLOOD))
		return;

	static Float:originF[3], flags
	pev(ID_BLOOD, pev_origin, originF)
	flags = pev(ID_BLOOD, pev_flags)
	
	if (flags & FL_INWATER || args[0] < 1)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE) 
		engfunc(EngFunc_WriteCoord, originF[0]) 
		engfunc(EngFunc_WriteCoord, originF[1]) 
		engfunc(EngFunc_WriteCoord, originF[2]-50.0) 
		write_short(g_smoke) 
		write_byte(random_num(15, 20)) 
		write_byte(random_num(10, 20)) 
		message_end()
		return;
	}
	
	static health
	health = get_user_health(ID_BLOOD)

	if (health > FIRE_DAMAGE) set_user_health(ID_BLOOD, health - FIRE_DAMAGE)
	else ExecuteHamB(Ham_Killed, ID_BLOOD, args[1], 0)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITE) 
	engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0)) 
	engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0)) 
	engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0)) 
	write_short(g_fire) 
	write_byte(random_num(5, 10)) 
	write_byte(200) 
	message_end()
	
	args[0] -= 1;
	set_task(0.3, "burning_flame", taskid, args, sizeof args)
}

grenade_trail(ent, r, g, b) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)
	write_short(g_trail)
	write_byte(10)
	write_byte(5)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(192)
	message_end()
}*/
	
stock ham_ent_radiusdamage(ent, Float:damage, Float:radius, dmgtype = DMG_GENERIC)
{
	new Float:xOrigin[3]
	pev(ent, pev_origin, xOrigin);
	
	new id = -1, Float:vOrigin[3], Float:AdjustedDamage, owner;
	owner = pev(ent, pev_owner);

	while((id = engfunc(EngFunc_FindEntityInSphere, id, xOrigin, radius)) != 0)
	{
		if(id == ent)
			continue;
		
		if(!is_user_alive(id))
			continue;
		
		if(ZB_GetUserZombie(id) == ZB_GetUserZombie(owner))
			continue;

		pev(id, pev_origin, vOrigin);
		AdjustedDamage = damage - get_distance_f(xOrigin, vOrigin) * damage / radius

		if(AdjustedDamage > pev(id, pev_health))
		{
			ExecuteHamB(Ham_Killed, id, owner, 0)
			continue;
		}
		
		ExecuteHamB(Ham_TakeDamage, id, 0, 0, AdjustedDamage, dmgtype)

		message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, id)
		write_short(floatround(UNIT_SECOND*AdjustedDamage))
		write_short(UNIT_SECOND*3)
		write_short(floatround(UNIT_SECOND*AdjustedDamage))
		message_end()
	}
}
/*
stock create_blast(const Float:originF[3]) 
{
	// Frost Sprite
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (TE_SPRITE) // TE ID
	engfunc(EngFunc_WriteCoord, originF[0]) // Position X
	engfunc(EngFunc_WriteCoord, originF[1]) // Y
	engfunc(EngFunc_WriteCoord, originF[2] + 50.0) // Z
	write_short(g_frostexp) // Sprite index
	write_byte(20) // Size of sprite
	write_byte(200) // Low For Light | More For Dark !
	message_end()
}*/

stock create_blast2(const Float:originF[3]) 
{
	// Frost Sprite
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (TE_SPRITE) // TE ID
	engfunc(EngFunc_WriteCoord, originF[0]) // Position X
	engfunc(EngFunc_WriteCoord, originF[1]) // Y
	engfunc(EngFunc_WriteCoord, originF[2] + 50.0) // Z
	write_short(g_fireexp) // Sprite index
	write_byte(20) // Size of sprite
	write_byte(200) // Low For Light | More For Dark !
	message_end()
}
/*
stock create_blast3(const Float:originF[3]) 
{
	// Frost Sprite
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (TE_SPRITE) // TE ID
	engfunc(EngFunc_WriteCoord, originF[0]) // Position X
	engfunc(EngFunc_WriteCoord, originF[1]) // Y
	engfunc(EngFunc_WriteCoord, originF[2] + 50.0) // Z
	write_short(g_drogeexp) // Sprite index
	write_byte(20) // Size of sprite
	write_byte(200) // Low For Light | More For Dark !
	message_end()
}
*/
public native_give_grenade(id, nade_type, nade) 
{
	g_nade[id][nade_type] = nade
	give_item(id, nadeweapon[nade_type])
}
