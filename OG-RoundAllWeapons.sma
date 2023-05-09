/* Anti Decompiler :) */
#pragma compress 1

#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <reapi>
#include <TutorText>

#define RKID 987047
#define is_valid_user(%1)    (1 <= %1 <= g_maxplayers)

new bool:g_IsKnifeRound, cvar_rk, p_Timer, g_SyncMsgObj, rkon[33], bool:gModeRound[10], g_maxplayers;
new const g_Timer = 51, rkmusic[] = "sound/og_ctf1-0b/halloween/Halloween3.mp3"
const TASKR = 2707

public plugin_init() {
	
	register_plugin("Round All Mode","1.0b","Spy.VE")
	
	register_event("TextMsg", "evGameCommencing", "a", "2=#Game_Commencing")
	register_event("ResetHUD", "event_resethud", "be")	
	register_event("CurWeapon", "evCurWeapon", "be", "1=1", "2!29")
	
	g_SyncMsgObj = CreateHudSyncObj()
	g_maxplayers = get_maxplayers()
	
	cvar_rk = 1
	
	register_clcmd("drop", "cmd_drop");

	RegisterHookChain(RG_CBasePlayer_Spawn, "player_spawn", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)	
	get_cvar_pointer("mp_buytime")
}

public plugin_natives()
{
	register_native("og_round_allmode", "_IsKnifeRound", 1);
	register_native("og_run_allmode", "rk", 1);
}

public _IsKnifeRound()
	return g_IsKnifeRound;
	
public evCurWeapon(id) 
{
	if( !g_IsKnifeRound )
		return

	static weapon; weapon = get_user_weapon(id)
	
	
	
	if(gModeRound[0] == true)
	{
		if( !(weapon == CSW_AK47) ) engclient_cmd(id, "weapon_ak47")	
	}
	else if(gModeRound[1] == true)
	{
		if( !(weapon == CSW_M4A1) ) engclient_cmd(id, "weapon_m4a1")
	}
	else if(gModeRound[2] == true)
	{
		if( !(weapon == CSW_M3) ) engclient_cmd(id, "weapon_m3")
	}
	else if(gModeRound[3] == true)
	{
		if( !(weapon == CSW_KNIFE) ) engclient_cmd(id, "weapon_knife")
	}
	else if(gModeRound[4] == true)
	{
		if( !(weapon == CSW_MP5NAVY) ) engclient_cmd(id, "weapon_mp5navy")
	}
	else if(gModeRound[5] == true)
	{
		if( !(weapon == CSW_FAMAS) ) engclient_cmd(id, "weapon_famas")
	}
	else if(gModeRound[6] == true)
	{
		if( !(weapon == CSW_GALIL) ) engclient_cmd(id, "weapon_galil")
	}
	else if(gModeRound[7] == true)
	{
		if( !(weapon == CSW_P90) ) engclient_cmd(id, "weapon_p90")
	}
	else if(gModeRound[8] == true)
	{
		if( !(weapon == CSW_XM1014) ) engclient_cmd(id, "weapon_xm1014")
	}
	else if(gModeRound[9] == true)
	{
		if( !(weapon == CSW_AUG) ) engclient_cmd(id, "weapon_aug")
	}
	
	
	
}

public plugin_precache() precache_generic(rkmusic)

public client_connect(id) rkon[id] = 0

public plugin_cfg() p_Timer = g_Timer

public client_disconnected(id) rkon[id] = 0

public event_resethud(id) {
	if(p_Timer < g_Timer)
	{
		if( !rkon[id] ) client_cmd(id, "mp3 play ^"%s^"", rkmusic), rkon[id] = 1
	}
	else {
		rkon[id] = 0
	}
}
public evGameCommencing() {
	if( !cvar_rk || g_IsKnifeRound )
		return
		
	g_IsKnifeRound = true, set_task(1.0, "rk", RKID, _, _, "b")
}
public rk() {
	if( !g_IsKnifeRound )
		return
	
	if(p_Timer == g_Timer/*60*/) 
	{
		for (new id; id <= g_maxplayers; id++)
		{
			enviarHint(id, "** Ronda de calentamiento va a comenzar! **", 8, 4.0);
		}
		
		set_cvar_num("mp_buytime", 0)
		set_cvar_num("mp_round_infinite", 1)
		
		static RandomMode;RandomMode = random_num(0, 9)
		
		if(RandomMode == 0)
			gModeRound[0] = true;
		else if(RandomMode == 1)
			gModeRound[1] = true;
		else if(RandomMode == 2)
			gModeRound[2] = true;
		else if(RandomMode == 3)
			gModeRound[3] = true;
		else if(RandomMode == 4)
			gModeRound[4] = true;
		else if(RandomMode == 5)
			gModeRound[5] = true;
		else if(RandomMode == 6)
			gModeRound[6] = true;
		else if(RandomMode == 7)
			gModeRound[7] = true;
		else if(RandomMode == 8)
			gModeRound[8] = true;
		else if(RandomMode == 9)
			gModeRound[9] = true;
	}
	
	set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.8, 1, 6.0, 1.0, 0.1, 0.2)
	ShowSyncHudMsg(0, g_SyncMsgObj, "Ronda de calentamiento termina en %i segs...", p_Timer)
	
	new tep[32], ctp[32], tenum, ctnum
	
	/*
	lista opcional de banderas de filtrado:
	  "A" - no incluyen los clientes muertas
	  "B" - no incluyen los clientes vivos
	  "C" - no incluyen los robots
	  "D" - no incluyen los clientes humanos
	  "E" - partido con el equipo
	  "F" - partido con parte del nombre
	  "G" - Coincidencia sin importar mayúsculas
	  "H" - no incluyen proxies HLTV
	  "I" - incluyo clientes que se conectan
	*/
	
	get_players(tep, tenum, "ehi", "TERRORIST"); get_players(ctp, ctnum, "ehi", "CT") 
	
	if(tenum < 1 || ctnum < 1 || p_Timer <= 0)
	{
		for (new id; id <= g_maxplayers; id++)
		{
			enviarHint(0, "** Ronda de calentamiento ha finalizado! **", 8, 4.0);
			client_cmd(id, "mp3 stop");
		}
		set_task(2.0, "RST"), remove_task(RKID)
	}
	
	p_Timer--
}
public RST() {
	g_IsKnifeRound = false, p_Timer = g_Timer, server_cmd("sv_restart 1"), set_cvar_num("mp_buytime", 2), set_cvar_num("mp_round_infinite", 0)
}
public player_spawn(id)	{
	
	if( !g_IsKnifeRound )
		return
	
	rg_remove_all_items(id, false);
	rg_give_item(id, "weapon_knife", GT_REPLACE);
	
	if(gModeRound[0] == true)
	{
		rg_give_item(id, "weapon_ak47", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_AK47, 90)
	}
	else if(gModeRound[1] == true)
	{
		rg_give_item(id, "weapon_m4a1", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_M4A1, 90)
	}
	else if(gModeRound[2] == true)
	{
		rg_give_item(id, "weapon_m3", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_M3, 32)
	}
	else if(gModeRound[3] == true)
	{
		rg_give_item(id, "weapon_knife", GT_REPLACE);
	}
	else if(gModeRound[4] == true)
	{
		rg_give_item(id, "weapon_mp5navy", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_MP5N, 120)
	}
	else if(gModeRound[5] == true)
	{
		rg_give_item(id, "weapon_famas", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_FAMAS, 90)
	}
	else if(gModeRound[6] == true)
	{
		rg_give_item(id, "weapon_galil", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_GALIL, 90)
	}
	else if(gModeRound[7] == true)
	{
		rg_give_item(id, "weapon_p90", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_P90, 100)
	}
	else if(gModeRound[8] == true)
	{
		rg_give_item(id, "weapon_xm1014", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_XM1014, 32)
	}
	else if(gModeRound[9] == true)
	{
		rg_give_item(id, "weapon_aug", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_AUG, 90)
	}
}

public fw_PlayerKilled_Post(victim, attacker)
{
	if( !g_IsKnifeRound )
		return
		
	if(is_valid_user(victim)) set_task(1.0,"respawn",victim+TASKR)
}
public respawn(id) {
	id -= TASKR

	if(is_user_alive(id) || !is_user_connected(id))
		return
	
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public cmd_drop(id)
{
	if( g_IsKnifeRound )
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}