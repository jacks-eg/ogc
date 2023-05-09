#include <amxmodx>
#include <reapi>

#define PLUGIN  "ResetScore ReAPI"
#define VERSION "2.1"
#define AUTHOR  "SkY#IN"

native center_msj(pPlayer, iMsgType, const szMessage[], any:...)


new const TAG[] = "^4[^1DG^4]^1";
new cmdRS[][]={"say /rs", "say rs", "say_team rs","say_team /rs","say /resetscore","say_team /resetscore"}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	for(new i; i < sizeof cmdRS; i++){ register_clcmd(cmdRS[i], "cmdRSfunc"); }
}

public cmdRSfunc(id)
{
	if(get_member(id, m_iTeam) == TEAM_SPECTATOR)
	{
		player_print(id, "^4->^3 ERROR!^1 No puedes reiniciar tu^4 Score^1, debes estar en un^4 Equipo")
		return PLUGIN_HANDLED
	}

	if(get_entvar(id, var_frags) == 0.0 && get_member(id, m_iDeaths) == 0)
	{
		center_msj(id, print_center, ">> ERROR! Tu Score esta en '0' <<")
		return PLUGIN_HANDLED
	}
	
	static g_name[32][33]
	get_user_name(id, g_name[id], 31)
	
	set_entvar(id, var_frags, 0.0);
	set_member(id, m_iDeaths, 0);
	    
	message_begin(MSG_ALL, 85);
	write_byte(id);
	write_short(0); 
	write_short(0); 
	write_short(0); 
	write_short(0);
	message_end();

	player_print(id, "Jugador:^4 %s^1 a Reiniciado su^3 (Score)^1 a^4 (0)", g_name[id])
	return PLUGIN_HANDLED;	
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