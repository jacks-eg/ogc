#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <reapi>
#include <fun>
#include <jctf>
#include <og_data>

new const TAG[] = "^4[^1O'G^4]";
new const MODEL_TANKER[][] = {"OG-TankerTT", "OG-TankerCT"}

#define TASK 6321
#define ID_TANKER (taskid - TASK)
	
new g_tryder[33]
new name[32]
new g_iCount[MAX_PLAYERS]

public plugin_init()
{
	register_plugin("CTF: Tankers", "1.0",  "Spy.VE")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event( "DeathMsg", "death_event", "a");
	register_logevent("event_round_end", 2, "1=Round_End")
	
	shop_add_item("Tanker Mode", 100, "BuyItem")
}

public death_event()
{
	new id = read_data(2);
	remove_task(id+TASK)
	g_tryder[id] = false
	set_user_rendering(id, kRenderFxNone);
	rg_reset_user_model(id, true)
}

public plugin_precache()
{
	static iTanker[64];
	
	formatex(iTanker, charsmax(iTanker), "models/player/%s/%s.mdl", MODEL_TANKER[0], MODEL_TANKER[0])
	precache_model(iTanker)
	
	formatex(iTanker, charsmax(iTanker), "models/player/%s/%s.mdl", MODEL_TANKER[1], MODEL_TANKER[1])
	precache_model(iTanker)
}


public plugin_natives()
{
	register_native("og_tankers", "_get_user_tankers", 1);
}

public _get_user_tankers(id)
	return g_tryder[id];

	
public client_putinserver(id)
{	
	get_user_name(id, name, 31);
	g_tryder[id] = false;
}

public client_disconnected(id)
{
	g_tryder[id] = false;
}
	
	
// Item Selected forward
public BuyItem(id)
{
	
	if(g_tryder[id])
	{
		player_print(id, "^1 No puedes comprar este combo nuevamente mientras esta en uso")
		return PLUGIN_HANDLED
	}
	
	rg_remove_all_items(id, false);
	rg_give_item(id, "weapon_knife", GT_REPLACE);
	
	rg_give_item(id, "weapon_m249", GT_REPLACE)
	rg_set_user_bpammo(id, WEAPON_AK47, 90)
	
	rg_give_item(id, "weapon_deagle", GT_REPLACE)
	rg_set_user_bpammo(id, WEAPON_DEAGLE, 35)
		
	g_tryder[id] = true
	if (get_member(id, m_iTeam) == CS_TEAM_CT)
	{
		rg_set_user_model(id, MODEL_TANKER[1], true)
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 20)
	}
	else if (get_member(id, m_iTeam) == CS_TEAM_T)
	{
		rg_set_user_model(id, MODEL_TANKER[0], true)
		set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 20)
	}
	
	player_print(id, "^1 Has comprado^4 Tanker Mode^1 por^4 2:00 minutos")
	
	set_entvar(id, var_health, 550.0)
	set_entvar(id, var_armorvalue, 300.0)
		
	if(task_exists(id+TASK))
		remove_task(id+TASK)
	
	g_iCount[id] = 120
	set_task(1.0, "CountDown", id+TASK, .flags="b", .repeat=g_iCount[id])
	
	return PLUGIN_CONTINUE;
}

public CountDown(taskid)
{
	new id = ID_TANKER
	client_print(id, print_center, "|| Tanker Mode: %02i:%02i ||", g_iCount[id] / 60, g_iCount[id] % 60)
	
	if(!g_iCount[id])
	{
		remove_task(id+TASK)
		g_tryder[id] = false
		set_user_rendering(id, kRenderFxNone);
		
		if(is_user_admin(id))
			og_refresh_modeladmin(id)
		else
			rg_reset_user_model(id, true)
			
		set_entvar(id, var_health, 100.0)
		set_entvar(id, var_armorvalue, 100.0)
		player_print(id, "^1 Se te han acabado los^4 2:00 minutos^1 de^4 Tanker Mode.")
	}
	g_iCount[id]--
}


public event_round_start() for (new id; id <= 32; id++) g_tryder[id] = false;
public event_round_end() for (new id; id <= 32; id++) g_tryder[id] = false;

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	g_tryder[victim] = false
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- STOCK --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

stock player_print(id, input[], any:...)
{	
	new count = 1, players[32]
	static msg[191]

	vformat(msg, charsmax(msg), input, 3)
	format(msg, charsmax(msg), "%s %s", TAG, msg)

	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}

	return PLUGIN_HANDLED
}
