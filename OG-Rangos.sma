/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <fvault>
#include <jctf>

new const TAG[] = "^4[^1O'G^4]^1"
#define INFO 	"\d[\rO'G\d]\w Ozut Gamer`s || CS-Public Oficial #1^n\d[\rO'G\d]\w GRUPO:\d https://www.facebook.com/groups/community.og/"

enum { LOAD, SAVE }

new const iInfoG[][] = {
	"RT-System", 					// 0*
	"1.0",						// 1*
	"Spy.VE"					// 2*
}

enum _:DATA
{
	RNAME[32],
	REXP,
	MAX_DATA
}

new const Rangos[][DATA] =
{
	{"Recluta", 50},
	{"Novato I", 100},
	{"Novato II", 500},
	{"Novato III", 1100},
	{"Novato IV", 1560},
	{"Novato V", 2230},
	{"Privado", 2770},
	{"Gefreiter", 3250},
	{"Corporal", 3700},
	{"Corporal Maestro", 4250},
	{"Sargento", 4900},
	{"Sargento Maestro", 5500},
	{"Sargento de Primera", 6000},
	{"Sargento Mayor", 6550},
	{"Teniente Tercero", 7150},
	{"Primer Teniente", 7650},
	{"Capitan", 8300},
	{"Mayor", 9000},
	{"Teniente Coronel", 10000}, 
	{"Coronel", 10500},
	{"Brigadier", 15550},
	{"Veterano I", 20155},
	{"Veterano II", 25650},
	{"Veterano III", 30000},
	{"Veterano IV", 36000},
	{"Veterano V", 41550},
	{"Teniente General", 47000},
	{"General", 54550},
	{"Mayor General", 61250},
	{"Elite I", 70000},
	{"Elite II", 77550},
	{"Elite III", 85000},
	{"Elite IV", 93550},
	{"Elite V", 100000},
	{"Mariscal", 110550},
	{"Mariscal de campo", 155550},
	{"Comandante", 200000},
	{"Generalisimo", 300000},
	{"Maestro I", 395550},
	{"Maestro II", 480500},
	{"Maestro III", 595000},
	{"Maestro IV", 685555},
	{"Maestro V", 791520},
	{"Legendario", 890000},
	{"Spartan!", 1000000}
}

new SyncHUD[2]
new iAccount[32][33], iexp[33], irangos[33]

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- PLUGIN INIT --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public plugin_init() 
{
	/* Info */
	register_plugin(iInfoG[0], iInfoG[1], iInfoG[2])
	RegisterHookChain(RG_CBasePlayer_Killed, "player_killed", true)

	/* AUTO GUARDADO */
	set_task(300.0, "check_autosave", _, _, _, "b")	/* AUTO GUARDADO */
	
	SyncHUD[0] = CreateHudSyncObj()
	register_clcmd("say rangos", "Show_ListRango")

	new ent = create_entity("info_target")
	entity_set_string(ent,EV_SZ_classname,"env_hud")
	entity_set_float(ent,EV_FL_nextthink,get_gametime() + 1.0)
 
	register_think("env_hud","ShowHUD")
}

public plugin_natives()
{
	register_native("ctf_rangos", "native_rangos", 1)
}

public native_rangos(id)
 return irangos[id]

// Show HUD
public ShowHUD(ent)
{
	entity_set_float(ent,EV_FL_nextthink,get_gametime() + 1.0)
 
	static i_players[32], i_num, i, id
	get_players(i_players, i_num, "ach")
 
	for(i=0; i < i_num; i++)
	{
		id = i_players[i]


		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.86, 1, 6.0, 1.0);
		ShowSyncHudMsg(
			id,
			SyncHUD[0],
			"==|| Exp: %d/%d ||==^n==|| Rango: %s ||==^n==|| Adrenalina: %d ||==",
			iexp[id],
			Rangos[irangos[id]][REXP],
			Rangos[irangos[id]][RNAME],
			get_user_adrenaline(id))
 	}
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- CLIENT PUTINSERVER --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public client_putinserver(id)
{	
	iexp[id] = 0
	irangos[id] = 0

	if(is_user_steam(id))
		get_user_authid(id, iAccount[id],  charsmax(iAccount[]))
	else 
		get_user_name(id, iAccount[id], 31)

	_data(id, LOAD)
}

public client_disconnected(id) 
{
	if(iexp[id] <= 0)
		return
	
	_data(id, SAVE)
}

public Show_ListRango( qIndex ) 
{
	static len[512], menu 
	formatex( len, charsmax( len ), "%s^n\r*\w Lista de Rango(s)\r\R", INFO) 
	menu = menu_create(len, "menu_listrangos") 

	for(new i = 0; i < sizeof Rangos; i++)
	{

		formatex(len, charsmax(len), "\w %s\R\y EXP\r %d", Rangos[i][RNAME], Rangos[i][REXP])
		menu_additem( menu, len )
	}

	menu_setprop(menu, MPROP_EXITNAME, "Salir.")
	menu_setprop(menu, MPROP_BACKNAME, "Anterior.")
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente.")
	menu_display(qIndex, menu, 0)
	return PLUGIN_HANDLED
}

public menu_listrangos( qIndex, qKey, qMenu )
{
	if (qKey == MENU_EXIT)
	{
		menu_destroy(qMenu)
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public player_killed(victim, attacker)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker) || !attacker || attacker == victim)
		return;

	if(get_user_weapon(attacker) == CSW_KNIFE && get_pdata_int(victim, 75, 5) == HIT_HEAD)
		SetFrags(attacker, 2)
	else
		SetFrags(attacker, 1)
}


SetFrags(id, frags)
{
	iexp[id] += frags

	static iRank; iRank = irangos[id];
	while(iexp[id] >= Rangos[irangos[id]][REXP] && irangos[id] < charsmax(Rangos))
		++irangos[id];

	if(iRank < irangos[id])
	{
		player_print(id, "^4*^1 Felicidades subiste al Rango:^4 %s", Rangos[irangos[id]][RNAME])
		player_print(id, "^4*^1 Para ver todos los Rangos Disponibles.^4 rangos^1 en say.")
		//client_cmd(id, "spk ^"%s^"", Sonido)
	}
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- STOCK --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

stock _data(id, type)
{
	static DataCenter[64], db1[25], db2[25]
	
	switch(type)
	{
		case LOAD:
		{

			if(fvault_get_data("nfvault_rangos", iAccount[id], DataCenter, charsmax(DataCenter)))
			{
				parse(DataCenter, db1, charsmax(db1), db2, charsmax(db2))
				iexp[id] = 	str_to_num(db1)
				irangos[id] = 	str_to_num(db2)
			}
		}
		case SAVE:
		{
			formatex(DataCenter, charsmax(DataCenter), "%d %d", iexp[id], irangos[id])
			fvault_set_data("nfvault_rangos", iAccount[id], DataCenter)
		}

	}
}

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