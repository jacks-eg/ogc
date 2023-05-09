#include <amxmodx>
#include <fakemeta_util>
#include <api_shop>
#include <reapi>

#define VERSION "2.2"

native og_avalanche(id)

// CS Offsets
#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }
			
new qItemp, g_has_unlimited_clip[33], g_tryder[33]

public plugin_init()
{
	register_plugin("[CTF] StronTryder", VERSION, "ILUSION")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	register_clcmd("drop", "clcmd_drop")
	RegisterHookChain(RG_CBasePlayer_Killed, "fw_PlayerKilled", true);
	qItemp = ctf_item_register("Mode: StronTyper", 50, 5000);
}

// Item Selected forward
public ctf_item_selected(player, item_id)
{
	if (item_id != qItemp)
		return PLUGIN_CONTINUE;
		
	if (!is_user_alive(player))
	{
		client_print(player, print_center, "|| No puedes usar el StronTyper sino estas vivo! ||");
		return PLUGIN_HANDLED;
	}
	
	if(g_tryder[player])
	{
		client_print(player, print_center, "|| Ya tienes el StronTyper! ||");
		return PLUGIN_HANDLED;
	}
	
	static red, green, blue
	red = 0
	green = 250
	blue = 0
	
	// Glow
	fm_set_rendering(player, kRenderFxGlowShell, red, green, blue, kRenderNormal, 20)
	
	rg_remove_all_items(player, false);
	rg_give_item(player, "weapon_knife", GT_REPLACE);
	rg_give_item(player, "weapon_deagle", GT_REPLACE);
	og_avalanche(player)
	
	// Clip
	g_has_unlimited_clip[player] = true
	
	// Dont Drop
	g_tryder[player] = true
	
	// HP
	fm_set_user_health(player, 1000)
		
	// Armor
	fm_set_user_armor(player, 500)
	
	new name[32]
	get_user_name(player, name, 31)
		
	set_hudmessage(0, 255, 0, 0.05, 0.45, 1, 0.0, 5.0, 1.0, 1.0, -1)
	show_hudmessage(0, "%s Tiene un StronTryder!!", name)
	
	return PLUGIN_CONTINUE;
}

public clcmd_drop(player)
{
	if (g_tryder[player])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public event_round_start()
{
	for (new id; id <= 32; id++) g_has_unlimited_clip[id] = false;
	for (new player; player <= 32; player++) g_tryder[player] = false;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (g_tryder[victim])
	{
		fm_set_rendering(victim)
		g_has_unlimited_clip[victim] = false;
		g_tryder[victim] = false;
		set_hudmessage(0, 255, 0, 0.05, 0.45, 1, 0.0, 5.0, 1.0, 1.0, -1)
		show_hudmessage(victim, "!!!Perdiste el StronTyper!!!")
	}
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Player doesn't have the unlimited clip upgrade
	if (!g_has_unlimited_clip[msg_entity])
		return;
	
	// Player not alive or not an active weapon
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static weapon, clip
	weapon = get_msg_arg_int(2) // get weapon ID
	clip = get_msg_arg_int(3) // get weapon clip
	
	// Unlimited Clip Ammo
	if (MAXCLIP[weapon] > 2) // skip grenades
	{
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon]) // HUD should show full clip all the time
		
		if (clip < 2) // refill when clip is nearly empty
		{
			// Get the weapon entity
			static wname[32], weapon_ent
			get_weaponname(weapon, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, msg_entity)
			
			// Set max clip on weapon
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}

// Set Weapon Clip Ammo
stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}
