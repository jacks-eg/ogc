/* ////////////////////////////////////////////////////////////////////////////////////////////////
				Guardado General del Servidor.
//////////////////////////////////////////////////////////////////////////////////////////////// */

#include <amxmodx>
#include <amxmisc>
#include <fvault>
#include <og_data>
#include <reapi>
#include <jctf>
#include <fakemeta>
#include <hamsandwich>
#include <TutorText>
#include <geoip>

new const iInfoG[][] = {
	"Guardado 1-0b", 						// 0*
	"1.0b",								// 1*
	"Spy.VE",							// 2*
	"API: Servidor iniciado correctamente",				// 3*
	"API: ERROR! Servidor falla de inicio...",			// 4*	
	"API: Realizando copia de seguridad",				// 5*
	"API: ERROR! No se pudo realizar la copia de seguridad...",	// 6*
	"API: Copia de Seguridad hecha exitosamente!"			// 7*
}

new const TAG[] = "^4[^1GLOBAL^4]^1 ";

#define kLevels 12
#define TASK_CLEAR_KILL 100
#define INFO 	"\d[\rO'G\d]\w CS-Public Oficial #1 \d[\r 1.0b\d ]^n\d[\rO'G\d]\w GRUPO:\d https://www.facebook.com/groups/community.og/"

#define ACCESS_LEVEL		ADMIN_IMMUNITY
#define ADMIN_LISTEN		ADMIN_USER
#define BIG-MASTER 		ADMIN_CFG
#define OWNER 			ADMIN_RCON
#define SUB-OWNER 		ADMIN_RESERVATION
#define QUEEN 			ADMIN_LEVEL_C
#define MANAGER 		ADMIN_LEVEL_D
#define SHERIF 			ADMIN_LEVEL_E
#define OFFICER 		ADMIN_LEVEL_F
#define STAFF 			ADMIN_LEVEL_G
#define PREMIUM 		ADMIN_LEVEL_H
#define VIP 			ADMIN_CVAR

new message[190], g_MessageColor, g_NameColor, g_AdminListen, strName[191], strText[191], alive[11]
static msgSayText, teamInfo, g_maxplayers

static const g_szTag[][] = 
{
        "",
        "^x04[^x03 OwNeR^x04 ]",
        "^x04[^x03 SUB-OwNeR^x04 ]",
        "^x04[^x03 QUEEN :3^x04 ]",
        "^x04[^x03 MANAGER^x04 ]",
        "^x04[^x03 SHERIF^x04 ]",
        "^x04[^x03 STAFF^x04 ]",
        "^x04[^x03 PREMIUM^x04 ]",
        "^x04[^x03 V.I.P^x04 ]",
        "^x04[^x03 BIG MASTER^x04 ]"
};

new name[32], playerTeamName[19], arg[1], newColor, newListen, teamName[10]
static color[10]

new KEYSMENU = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0;

enum 
{
	STEAMID, SAVE_STEAMID, IDLAN, SAVE_IDLAN, FILE_RANK, FILE_EXP, FILE_MODELS, FILE_HUD, 
	FILE_DEATHS, FILE_KILLS, MAX_DATA
};

enum
{
	HEATSHOP, KNIFE, GRENADE, ADMIN
}

enum _:MEDALLAS
{
	gNAME[32], gEXP, gPNG[100], gINFO[64]
}

enum _:Item
{
	iMODELS, iADMIN 
}

enum _:iKills
{
	MSJ[33], KILL, SOUND[33]
}

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" };
			
new const iHeatShop[][MEDALLAS] =
{
	/*	TITULO	    || PUNTOS	|| 		IMAGEN						|| 				INFO		*/
	{"Sin Gemas",		10, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/Not.png",			"Requiere 10 Kill (HeatShop) para Subir de Nivel"},
	{"50 HeatShop",		50, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEATSHOP/1like.png",		"Requiere 50 Kill (HeatShop) para Subir de Nivel"},
	{"250 HeatShop",	250, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEATSHOP/2like.png",		"Requiere 250 Kill (HeatShop) para Subir de Nivel"},
	{"500 HeatShop",	500, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEATSHOP/3like.png",		"Requiere 500 Kill (HeatShop) para Subir de Nivel"},
	{"1000 HeatShop",	1000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEATSHOP/4like.png",		"Requiere 1000 Kill (HeatShop) para Subir de Nivel"},
	{"!!Hunter!!",		5000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEATSHOP/heatshop.png",		"Requiere 5000 Kill (HeatShop) Nivel Maximo!!"}
};

new const iKnife[][MEDALLAS] =
{
	/*	TITULO	    || PUNTOS	|| 		IMAGEN						|| 				INFO		*/
	{"Sin Gemas",		10, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/Not.png",			"Requiere 10 Kill (Knife) para Subir de Nivel"},
	{"50 Knife",		50, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/KNIFE/1mes.png",		"Requiere 50 Kill (Knife) para Subir de Nivel"},
	{"250 Knife",		250, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/KNIFE/2mes.png",		"Requiere 250 Kill (Knife) para Subir de Nivel"},
	{"500 Knife",		500, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/KNIFE/3mes.png",		"Requiere 500 Kill (Knife) para Subir de Nivel"},
	{"1000 Knife",		1000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/KNIFE/4mes.png",		"Requiere 1000 Kill (Knife) para Subir de Nivel"},
	{"!!Samurai!!",		2000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/KNIFE/knife.png",		"Requiere 2000 Kill (Knife) Nivel Maximo!!"}
};

new const iHegrenade[][MEDALLAS] =
{
	/*	TITULO	    || PUNTOS	|| 		IMAGEN						|| 				INFO		*/
	{"Sin Gemas",		10, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/Not.png",			"Requiere 10 Kill (Grenade) para Subir de Nivel"},
	{"50 Grenade",		50, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEGRENADE/1qa.png",		"Requiere 50 Kill (Grenade) para Subir de Nivel"},
	{"250 Grenade",		250, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEGRENADE/2qa.png",		"Requiere 250 Kill (Grenade) para Subir de Nivel"},
	{"500 Grenade",		500, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEGRENADE/3qa.png",		"Requiere 500 Kill (Grenade) para Subir de Nivel"},
	{"1000 Grenade",	1000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEGRENADE/4qa.png",		"Requiere 1000 Kill (Grenade) para Subir de Nivel"},
	{"!!Bomb!!",		2000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/HEGRENADE/hegrenade.png",	"Requiere 2000 Kill (Grenade) Nivel Maximo!!"}
};

new const iAdmins[][MEDALLAS] =
{
	/*	TITULO	    || PUNTOS	|| 		IMAGEN						|| 				INFO		*/
	{"Sin Gemas",		10, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/Not.png",			"Requiere 10 Kill (Admins) para Subir de Nivel"},
	{"50 kill Admins",	50, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/ADMIN/1res.png",		"Requiere 50 Kill (Admins) para Subir de Nivel"},
	{"250 kill Admins",	250, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/ADMIN/2res.png",		"Requiere 250 Kill (Admins) para Subir de Nivel"},
	{"500 kill Admins",	500, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/ADMIN/3res.png",		"Requiere 500 Kill (Admins) para Subir de Nivel"},
	{"1000 kill Admins",	1000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/ADMIN/4res.png",		"Requiere 1000 Kill (Admins) para Subir de Nivel"},
	{"!!Master Admin!!",	5000, 	  "http://74.91.127.79:8088/ozutservers/images/medallas/ADMIN/admin.png",		"Requiere 5000 Kill (Admins) Nivel Maximo!!"}
};

new iOptions[33][Item], SyncHUD[5],  gType[33][6], gExp[33][6];
new iName[33][32], iSteamID[32][33];
new i, kills[33] = {0,...}, deaths[33] = {0,...}, kill[33][24];
new firstblood
new g_playercountry[33][64]
new g_playerip[33][32]
new rounds_elapsed, chat_message
new play_sound;
new g_map[32]

/* MODEL DE ARMAS */

new V_AK47[]	= "models/v_ak47.mdl" 
new V_M4A1[]	= "models/v_m4a1.mdl" 
new V_DEAGLE[]	= "models/v_deagle.mdl" 
new V_KNIFE[]    = "models/v_knife.mdl" 

new const iMessagesEvents[][] = {
	"*> !BoOM! !!HeAdShOp!!! <*", 
	"*> !!VeRgAcIoN PANA!! <*", 
	"*> !!LE PARTI EL COCO CAUSA!! <*", 
	"*> !!!OMG!!! <*", 
	"*> !!TOMA EN LA GETA!! <*", 
	"*> !!NaWboNA VlAdImIRR!! <*",
	">> !!!AgARRa LOCA!!! <<",
	">> !!AY VALEE!! ESTAS PASADO DE MARICO <<",
	">> !!AYYY MARIQUITO, TE TRAICIONO EL CULO!! <<",
	">> !!MMMM YEAH!! <<",
	">> !!!!TURN DOWN FOR WHAT!!!!<<",
	"!! A VOLAR MARIPOSA HAAHAHA!!",
	"!! SEEEE MORIOOOO!!",
	"!! AY PERO QUE IDIOTA!!!",
	"!! PRIMERA SANGRE !!"
};

new const iMessagesEvents_Sounds[][] = {
	"OzutServers/ht1.wav", 
	"OzutServers/vergacion.wav", 
	"OzutServers/ht3.wav", 
	"OzutServers/ht4.wav", 
	"OzutServers/Tomaenlageta.wav", 
	"OzutServers/vladimil.wav",
	"OzutServers/knife1.wav",
	"OzutServers/knife2.wav",
	"OzutServers/knife3.wav",
	"OzutServers/yeah.wav",
	"OzutServers/td_for_what.wav",
	"OzutServers/hegrenade1.wav",
	"OzutServers/Suicide1.wav",
	"OzutServers/Suicide2.wav",
	"OzutServers/firstblood.wav"
};

new iSoundsKill[][iKills] = 
{
	{ "%s: MULTI KILL!!!", 4, "OzutServers/SoundKills/2k.wav" },
	{ "%s: RAMPAGE!!!", 6, "OzutServers/SoundKills/3k.wav" },
	{ "%s: KILLING SPREE!!!", 9, "OzutServers/SoundKills/4k.wav" },
	{ "%s: DOMINATING!!!", 12, "OzutServers/SoundKills/5k.wav" },
	{ "%s: UNSTOPPABLE!!!", 15, "OzutServers/SoundKills/6k.wav" },
	{ "%s: MEGA KILL!!!", 18, "OzutServers/SoundKills/7k.wav" },
	{ "%s: ULTRA KILL!!!", 21, "OzutServers/SoundKills/8k.wav" },
	{ "%s: IS JHON CENA!!!", 24, "OzutServers/isjhoncena.wav" },
	{ "%s: OUTSTANDING!!!", 27, "OzutServers/SoundKills/10k.wav" },
	{ "%s: LUDICROUS KILL!", 30, "OzutServers/SoundKills/11k.wav" },
	{ "%s: MONSTER KILL!!!", 33, "OzutServers/SoundKills/13k.wav" },
	{ "%s: G O D L I K E !!!", 36, "OzutServers/SoundKills/15k.wav" }
	/*,	{ "%s:}*/
	
};

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- PLUGIN INIT --------
//////////////////////////////////////////////////////////////////////////////////////////////// */


new const GameName[][] = {
	"|| CS Dev: !RAMPAGE 1.0b! ||",
	"|| www.ozutservers.com/forum ||",
	"fb.com/groups/community.og",
	"!Servidor Venezolano!"
}

public plugin_init() {
	
	/* Info */
	register_plugin(iInfoG[0], iInfoG[1], iInfoG[2])
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_itemdeploy", 1)
		
	SyncHUD[0] = CreateHudSyncObj()
	SyncHUD[1] = CreateHudSyncObj()
	SyncHUD[2] = CreateHudSyncObj()
	SyncHUD[3] = CreateHudSyncObj()
	
	register_menu("Menu Account", KEYSMENU, "HandMenuAccount");
	
	/* SOUNDS KILLS */
	register_event("DeathMsg", "events_death", "a");
	register_event("ResetHUD", "reset_hud", "b");
	register_event("HLTV","rnstart","a", "1=0", "2=0");
	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "restart_round", "a", "2=#Game_will_restart_in");
	
	register_concmd("say /medallas", "Show_MenuMedallas");
	register_concmd("say_team /medallas", "Show_MenuMedallas");
	
	register_concmd("radio1", "Show_MenuPrincipal");
	
	g_MessageColor = register_cvar("og_color", "3") // Message colors: [1] Default Yellow, [2] Green, [3] White, [4] Blue, [5] Red
	g_NameColor = register_cvar("og_namecolor", "2") // Name colors: [1] Default Yellow, [2] Green, [3] White, [4] Blue, [5] Red, [6] Team-color
	g_AdminListen = register_cvar("og_listen", "1") // Set whether admins see or not all messages(Alive, dead and team-only)

	msgSayText = get_user_msgid("SayText")
	teamInfo = get_user_msgid("TeamInfo")
	g_maxplayers = get_maxplayers()

	register_srvcmd("og_color", "set_color")
	register_srvcmd("og_namecolor", "set_name_color")
	register_srvcmd("og_listen", "set_listen")
	
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_teamsay")
	
	// Forwards
	register_forward(FM_SetModel, "fw_SetModel", 1)
	
	play_sound = register_cvar("og_playsound","1");
	chat_message = register_cvar("mro_chatmessage","1");
	get_mapname(g_map, 31)
	
	set_member_game(m_GameDesc, GameName[random(sizeof GameName -1)]);
}



// Forwards
public fw_SetModel(entity, model[])
{
	if( !pev_valid(entity) )
		return FMRES_IGNORED
	
	static Classname[64]; pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if( !equal(Classname, "weaponbox") )
		return FMRES_IGNORED
		
	if(contain(model, "_awp") != -1)
		engfunc(EngFunc_RemoveEntity, entity)
	
	return FMRES_IGNORED
}

public new_round()
{
	rounds_elapsed += 1;
	
	new p_playernum;
	p_playernum = get_playersnum(1);
	
	if(get_pcvar_num(chat_message) == 1)
	{	
		player_print(0, "Ronda:^4 %d^1 || Mapa:^4 %s^1 || Jugadores:^4 %d / %d^1 ||", rounds_elapsed, g_map, p_playernum, g_maxplayers); 
	}
	
	if(get_pcvar_num(play_sound) == 1)
	{
		new rndctstr[21]
		num_to_word(rounds_elapsed, rndctstr, 20);
		client_cmd(0, "spk ^"vox/round %s^"",rndctstr)
	}	
	return PLUGIN_CONTINUE;
}
public restart_round()
{
	rounds_elapsed = 0;	
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- PLUGIN PRECACHE --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public plugin_precache() 
{    
	precache_model(V_AK47) 
	precache_model(V_DEAGLE)
	precache_model(V_M4A1) 
	precache_model(V_KNIFE)
	
	for (i = 0; i < sizeof iMessagesEvents_Sounds; i++)
		engfunc(EngFunc_PrecacheSound, iMessagesEvents_Sounds[i])
		
	for (i = 0; i < sizeof (iSoundsKill); i++)
	{
		engfunc(EngFunc_PrecacheSound, iSoundsKill[i][SOUND])
	}
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- PLUGIN AUTHRIZED --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public client_authorized(id)
    get_user_authid(id, iSteamID[id],  charsmax(iSteamID[]));

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- CLIENT PUTINSERVER --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public client_putinserver(id) {	
	get_user_name(id, iName[id], 31);
	UTIL_ResetPlayerDB(id);

	if(containi(iSteamID[id], "STEAM_0:") != -1)
	{
		_loading(id, STEAMID);
	} 
	else 
	{
		_loading(id, IDLAN);
	}
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- CLIENT DISCONNECTED --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public client_disconnected(id) {
	
	if(gExp[id][HEATSHOP] <= 0)
		return;
	
	if(containi(iSteamID[id], "STEAM_0:") != -1)
	{
		_loading(id, SAVE_STEAMID);
	} 
	else 
	{
		_loading(id, SAVE_IDLAN);
	}
}

/* ////////////////////////////////////////////////////////////////////////////////////////////////
				-------- CLIENT DISCONNECTED --------
//////////////////////////////////////////////////////////////////////////////////////////////// */

public ShowMenu_Account(qIndex)
{
	new menu[512], len;len = 0;

	len += formatex(menu[len], sizeof menu - 1 - len, "%s^n^n", INFO);
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\y Personalizar:\w Jugador.^n");
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\y Usar:\w Brillo\d (\r ADMIN\d )^n");
	len += formatex(menu[len], sizeof menu - 1 - len, "\r3.\w Quitar Modelos de Admins y Armas: %s^n^n", iOptions[qIndex][iMODELS] ? "\ySi":"\rNo")
	
	if(containi(iSteamID[qIndex], "STEAM_0:") != -1)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r**\w Tipo de Guardado:\y SteamID^n");
	else
		len += formatex(menu[len], sizeof menu - 1 - len, "\r**\w Tipo de Guardado:\y IDLAN^n");
		
	len += formatex(menu[len], sizeof menu - 1 - len, "\r0. \wSalir.");

	show_menu(qIndex, KEYSMENU, menu, -1, "Menu Account");
}
public HandMenuAccount(qIndex, qKeys, qMenu)
{
	switch(qKeys)
	{
		case 1:
		{
			if(!is_user_admin(qIndex))
				player_print(qIndex, "No Eres Administrador");
			else
				og_glow(qIndex);
			
		}
		case 2:
		{
			if(!iOptions[qIndex][iMODELS])
				iOptions[qIndex][iMODELS] = 1, client_cmd(qIndex, "spk fvox/activated.wav"), client_cmd(qIndex, "cl_minmodels 1");
			else
				iOptions[qIndex][iMODELS] = 0, client_cmd(qIndex, "spk fvox/deactivated.wav"), client_cmd(qIndex, "cl_minmodels 0");
				
			ShowMenu_Account(qIndex)
		}
	}
	return PLUGIN_HANDLED;
}

public Show_MenuPrincipal(id)
{
	static len[512], menu
	formatex( len, charsmax( len ), "%s^n\d---||\w Menu Principal\d ||---", INFO) 
	menu = menu_create(len, "menu_principal") 

	menu_additem( menu, "\d||\w Menu de Armas. \d(\r PREMIUM\d )");
	menu_additem( menu, "\d||\w Personalizar tu Jugador.");
	menu_additem( menu, "\d||\w Estadisticas \d(\y MEDALLAS\d )");
	menu_additem( menu, "\d||\w Ventas\d /\y Servicios.");
	menu_additem( menu, "\d||\w Reglas del Servidor.");
	menu_additem( menu, "\d||\w Informacion de la Comunidad");
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir.");
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public menu_principal(id, menu, item )
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch( item )
	{
		case 1: ShowMenu_Account(id)
		case 2: Show_MenuMedallas(id)
	}
	return PLUGIN_HANDLED;
}
public fw_itemdeploy(ent) 
{
	new iWpnId = get_member(ent, m_iId)
	if(iWpnId<1)
	{
		return;
	}
	
	new id = get_member(ent, m_pPlayer)
	
	if((id>0) && is_user_connected(id))
	{
		if(iOptions[id][iMODELS])
			return;
			
		switch(iWpnId)
		{
			case WEAPON_KNIFE:
			{
				set_pev(id, pev_viewmodel2, V_KNIFE)
				set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
			}	
			case WEAPON_M4A1:
			{
				set_pev(id, pev_viewmodel2, V_M4A1)
				set_pev(id, pev_weaponmodel2, "models/p_m4a1.mdl")
			}	
			case WEAPON_AK47:
			{
				set_pev(id, pev_viewmodel2, V_AK47)
				set_pev(id, pev_weaponmodel2, "models/p_ak47.mdl")
			}	
			case WEAPON_DEAGLE:
			{
				set_pev(id, pev_viewmodel2, V_DEAGLE)
				set_pev(id, pev_weaponmodel2, "models/p_deagle.mdl")
			}
		}
	}
}

public events_death(id) {
	new killer = read_data(1);
	new victim = read_data(2);
	new headshot = read_data(3);
	new weapon[24], vicname[32], killname[32]
	new red = random_num(0, 255), green = random_num(0, 255), blue = random_num(0, 255)
	
	read_data(4,weapon,23)
	get_user_name(victim,vicname,31)
	get_user_name(killer,killname,31)


	/* *********** HEADSHOT *********** */
	if(headshot == 1) 
	{
		static RandomMsj;RandomMsj = random_num(0, 5)
		
		if(RandomMsj == 0)
		{
			set_dhudmessage(red, green, blue, -1.0, 0.07, _, _, 5.0);
			show_dhudmessage(0, iMessagesEvents[0]);
			PlaySound(iMessagesEvents_Sounds[0])
		}
		else if(RandomMsj == 1)
		{
			set_dhudmessage(red, green, blue, -1.0, 0.11, _, _, 5.0);
			show_dhudmessage(0, iMessagesEvents[1]);
			PlaySound(iMessagesEvents_Sounds[1])
		}
		else if(RandomMsj == 2)
		{
			set_dhudmessage(red, green, blue, -1.0, 0.14, _, _, 5.0);
			show_dhudmessage(0, iMessagesEvents[2]);
			PlaySound(iMessagesEvents_Sounds[2])
		}
		else if(RandomMsj == 3)
		{
			set_dhudmessage(red, green, blue, -1.0, 0.18, _, _, 5.0);
			show_dhudmessage(0, iMessagesEvents[3]);
			PlaySound(iMessagesEvents_Sounds[3])
		}
		else if(RandomMsj == 4)
		{
			set_dhudmessage(red, green, blue, -1.0, 0.22, _, _, 5.0);
			show_dhudmessage(0, iMessagesEvents[4]);
			PlaySound(iMessagesEvents_Sounds[4])
		}
		else if(RandomMsj == 5)
		{
			set_dhudmessage(red, green, blue, -1.0, 0.25, _, _, 5.0);
			show_dhudmessage(0, iMessagesEvents[5]);
			PlaySound(iMessagesEvents_Sounds[5])
		}
		
		GiveMedallas(killer, HEATSHOP, 1);
	}
	
	/* *********** KNIFE *********** */
	if(weapon[0] == 'k')
	{
		static RandomMsj;RandomMsj = random_num(0, 4)
		set_hudmessage(255,green, blue, -1.0, 0.27, _, _, 5.0);
		
		if(RandomMsj == 0)
		{
			ShowSyncHudMsg(0, SyncHUD[1], iMessagesEvents[6]);
			PlaySound(iMessagesEvents_Sounds[6])
		}
		else if(RandomMsj == 1)
		{
			ShowSyncHudMsg(0, SyncHUD[1], iMessagesEvents[7]);
			PlaySound(iMessagesEvents_Sounds[7])
		}
		else if(RandomMsj == 2)
		{
			ShowSyncHudMsg(0, SyncHUD[1], iMessagesEvents[8]);
			PlaySound(iMessagesEvents_Sounds[8])
		}
		else if(RandomMsj == 3)
		{
			ShowSyncHudMsg(0, SyncHUD[1], iMessagesEvents[9]);
			PlaySound(iMessagesEvents_Sounds[9])
		}
		else if(RandomMsj == 4)
		{
			ShowSyncHudMsg(0, SyncHUD[1], iMessagesEvents[10]);
			PlaySound(iMessagesEvents_Sounds[10])
		}
		GiveMedallas(killer, KNIFE, 1);
	}
	
	/* *********** NADE *********** */
	if(weapon[1] == 'r')
	{
		set_dhudmessage(0, green, 0, -1.0, 0.25, _, _, 0.85);
		show_dhudmessage(0, iMessagesEvents[11]);
		PlaySound(iMessagesEvents_Sounds[11])
		
		GiveMedallas(killer, GRENADE, 1);
	}
	
	/* *********** SUICIDE *********** */
	if(killer == victim) 
	{
		static RandomMsj;RandomMsj = random_num(0, 1)
		set_dhudmessage(red, green, blue, -1.0, 0.30, _, _, 0.85);
		
		if(RandomMsj == 0)
		{
			show_dhudmessage(0, iMessagesEvents[12]);
			PlaySound(iMessagesEvents_Sounds[12])
		}
		else if(RandomMsj == 1)
		{
			show_dhudmessage(0, iMessagesEvents[13]);
			PlaySound(iMessagesEvents_Sounds[13])
		}
	}
	
	/* *********** COMBOS *********** */
	else
	{
		kill[killer] = weapon;
		set_task(0.1,"clear_kill",TASK_CLEAR_KILL+killer);
	}
	
	/* *********** ADMIN *********** */
	if(is_user_admin(victim))
	{
		GiveMedallas(killer, ADMIN, 1);
	}
	
	kills[killer] += 1;
	kills[victim] = 0;
	deaths[killer] = 0;
	deaths[victim] += 1;

	for (new i = 0; i < kLevels; i++) 
	{
		if (kills[killer] == iSoundsKill[i][KILL]) 
		{
			announce(killer, i);
			return PLUGIN_CONTINUE;
		}
	}
/*
	if(firstblood && killer!=victim && killer>0)
	{
		set_dhudmessage(red, green, blue, -1.0, 0.30, _, _, 0.85);
		show_dhudmessage(0, iMessagesEvents[14]);
		
		PlaySound(iMessagesEvents_Sounds[14])
		
		firstblood = 0
	}*/

	return PLUGIN_CONTINUE;
}

public clear_kill(taskid)
{
	new id = taskid-TASK_CLEAR_KILL;
	kill[id][0] = 0;
}

announce(killer, level) 
{
	new name[33], r = random(256), g = random(256), b = random(256)

	get_user_name(killer, name, 32);
	
	set_hudmessage(r,g,b, 0.06, 0.6, _, _, 5.0);
	ShowSyncHudMsg(0, SyncHUD[2],iSoundsKill[level][MSJ], name);
	PlaySound(iSoundsKill[level][SOUND])
	
	return PLUGIN_CONTINUE;
}

public reset_hud(id) 
{
	firstblood = 1
	set_member(id, m_iAccount, 16000)
}

public rnstart(id)
{
	set_dhudmessage(random(256), random(256), random(256), -1.0, 0.08, _, _, 0.85);
	show_dhudmessage(0, "|| !!Inicia la Partida: %d!! ||", rounds_elapsed);
}

new const gThemeOG[][] = 
{
	{"<meta charset=UTF-8>\
	<style>\
	body{background:url('http://74.91.127.79:8088/ozutservers/images/Bg.jpg');background-size: 100%%;font-family:Arial}\
	table{color:#FFF;font-size:12px;}\
	th{background:#e8c021 url('http://74.91.127.79:8088/ozutservers/images/bg-userlinks.png');padding: 10px;border-bottom: solid 1px #ffbf00;font-size:14px;color:black;text-align: center}\
	td{background-color:rgba(0,0,0,0.5);padding: 5px}\
	.eff{color:#e8c021;text-shadow: 0 0 0.9em #ffbf00;font-weight: bold;}\
	p{text-align: center}\
	</style>"},
	
	{"<meta charset=UTF-8>\
	<style>\
	body{background:url('http://74.91.127.79:8088/ozutservers/images/Bg.jpg');background-size: 100%%;font-family:Arial}\
	table{color:#FFF;font-size:12px;}\
	th{background:#008aff url('http://74.91.127.79:8088/ozutservers/images/bg-userlinks.png');padding: 10px;border-bottom: solid 1px #008aff;font-size:14px;text-align: center}\
	td{background-color:rgba(0,0,0,0.5);padding: 5px}\
	.eff{color:#008aff;text-shadow: 0 0 0.9em #008aff;font-weight: bold;}\
	p{text-align: center}\
	</style>"},
	
	{"<meta charset=UTF-8>\
	<style>\
	body{background:url('http://74.91.127.79:8088/ozutservers/images/Bg.jpg');background-size: 100%%;font-family:Arial}\
	table{color:#FFF;font-size:12px;}\
	th{background:#bb0c11 url('http://74.91.127.79:8088/ozutservers/images/bg-userlinks.png');padding: 10px;border-bottom: solid 1px #bb0c11;font-size:14px;text-align: center}\
	td{background-color:rgba(0,0,0,0.5);padding: 5px}\
	.eff{color:#bb0c11;text-shadow: 0 0 0.9em #bb0c11;font-weight: bold;}\
	p{text-align: center}\
	</style>"},
	
	{"<meta charset=UTF-8>\
	<style>\
	body{background:url('http://74.91.127.79:8088/ozutservers/images/Bg.jpg');background-size: 100%%;font-family:Arial}\
	table{color:#FFF;font-size:12px;}\
	th{background:#08d708 url('http://74.91.127.79:8088/ozutservers/images/bg-userlinks.png');padding: 10px;border-bottom: solid 1px #08d708;font-size:14px;text-align: center;color:black}\
	td{background-color:rgba(0,0,0,0.5);padding: 5px}\
	.eff{color:#08d708;text-shadow: 0 0 0.9em #08d708;font-weight: bold;}\
	p{text-align: center}\
	</style>"}
}

public Show_MotdMedallas(id, type)
{
	new iMotd[ MAX_MOTD_LENGTH ];
	new iLen; iLen = 0;
		
		
	switch (type)
	{
		case HEATSHOP:
		{
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, gThemeOG[0] );
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<body><p><img src='http://74.91.127.79:8088/ozutservers/images/medallas/MedallaYellow.png' width=70%%></p><table width=100%%>")
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><th width=100%%>Mis Estadisticas - Medalla (HeatShop)</table><table width=100%%>")
			
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff' width=10>JUGADOR:</b>   %s<td><b class='eff' width=10>EXPERIENCIA:</b>   %d / %d", iName[id], gExp[id][HEATSHOP], iHeatShop[gType[id][HEATSHOP]][gEXP])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>INFORMACION:<td>  %s", iHeatShop[gType[id][HEATSHOP]][gINFO])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>SIGUIENTE NIVEL:</b>   %s<td><b class='eff'>NIVEL DE ACTUAL:</b>   %s", iHeatShop[gType[id][HEATSHOP]+1][gNAME], iHeatShop[gType[id][HEATSHOP]][gNAME])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><p><img src='%s' width=30%%></p><td><p><img src='%s' width=30%%></p>", iHeatShop[gType[id][HEATSHOP]+1][gPNG], iHeatShop[gType[id][HEATSHOP]][gPNG])
	
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "</table></body>" );
	
			show_motd( id, iMotd, "|| Medallas || - !HeatShop!" );
		}
		case KNIFE:
		{
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, gThemeOG[1] );
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<body><p><img src='http://74.91.127.79:8088/ozutservers/images/medallas/MedallaBlue.png' width=70%%></p><table width=100%%>")
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><th width=100%%>Mis Estadisticas - Medalla (Knife)</table><table width=100%%>")
			
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff' width=10>JUGADOR:</b>   %s<td><b class='eff' width=10>EXPERIENCIA:</b>   %d / %d", iName[id], gExp[id][KNIFE], iKnife[gType[id][KNIFE]][gEXP])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>INFORMACION:<td>  %s", iKnife[gType[id][KNIFE]][gINFO])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>SIGUIENTE NIVEL:</b>   %s<td><b class='eff'>NIVEL DE ACTUAL:</b>   %s", iKnife[gType[id][KNIFE]+1][gNAME], iKnife[gType[id][KNIFE]][gNAME])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><p><img src='%s' width=30%%></p><td><p><img src='%s' width=30%%></p>", iKnife[gType[id][KNIFE]+1][gPNG], iKnife[gType[id][KNIFE]][gPNG])
	
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "</table></body>" );
	
			show_motd( id, iMotd, "|| Medallas || - !Knife!" );
		}
		case GRENADE:
		{
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, gThemeOG[2] );
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<body><p><img src='http://74.91.127.79:8088/ozutservers/images/medallas/MedallaRed.png' width=70%%></p><table width=100%%>")
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><th width=100%%>Mis Estadisticas - Medalla (Grenade)</table><table width=100%%>")
			
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff' width=10>JUGADOR:</b>   %s<td><b class='eff' width=10>EXPERIENCIA:</b>   %d / %d", iName[id], gExp[id][GRENADE], iHegrenade[gType[id][GRENADE]][gEXP])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>INFORMACION:<td>  %s", iHegrenade[gType[id][GRENADE]][gINFO])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>SIGUIENTE NIVEL:</b>   %s<td><b class='eff'>NIVEL DE ACTUAL:</b>   %s", iHegrenade[gType[id][GRENADE]+1][gNAME], iHegrenade[gType[id][GRENADE]][gNAME])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><p><img src='%s' width=30%%></p><td><p><img src='%s' width=30%%></p>", iHegrenade[gType[id][GRENADE]+1][gPNG], iHegrenade[gType[id][GRENADE]][gPNG])
	
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "</table></body>" );
	
			show_motd( id, iMotd, "|| Medallas || - !Grenade!" );
		}
		case ADMIN:
		{
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, gThemeOG[3] );
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<body><p><img src='http://74.91.127.79:8088/ozutservers/images/medallas/MedallaGreen.png' width=70%%></p><table width=100%%>")
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><th width=100%%>Mis Estadisticas - Medalla (Admins)</table><table width=100%%>")
			
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff' width=10>JUGADOR:</b>   %s<td><b class='eff' width=10>EXPERIENCIA:</b>   %d / %d", iName[id], gExp[id][ADMIN], iAdmins[gType[id][ADMIN]][gEXP])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>INFORMACION:<td>  %s", iAdmins[gType[id][ADMIN]][gINFO])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><b class='eff'>SIGUIENTE NIVEL:</b>   %s<td><b class='eff'>NIVEL DE ACTUAL:</b>   %s", iAdmins[gType[id][ADMIN]+1][gNAME], iAdmins[gType[id][ADMIN]][gNAME])
			iLen += formatex( iMotd[ iLen ], sizeof iMotd-iLen, "<tr><td><p><img src='%s' width=30%%></p><td><p><img src='%s' width=30%%></p>", iAdmins[gType[id][ADMIN]+1][gPNG], iAdmins[gType[id][ADMIN]][gPNG])
	
			iLen += format( iMotd[ iLen ], sizeof iMotd-iLen, "</table></body>" );
	
			show_motd( id, iMotd, "|| Medallas || - !Admin!" );
		}
	
	}
	

}

public Show_MenuMedallas(id)
{
	static len[512], menu
	formatex( len, charsmax( len ), "%s^n\d---||\w Mis Estadisticas \y(\r Medallas\y )\d ||---", INFO) 
	menu = menu_create(len, "menu_medallas") 

	menu_additem( menu, "\d||\w Medalla:\r HeatShop.");
	menu_additem( menu, "\d||\w Medalla:\r Knife.");
	menu_additem( menu, "\d||\w Medalla:\r Grenade.");
	menu_additem( menu, "\d||\w Medalla:\r Admin.");
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir.");
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public menu_medallas(id, menu, item )
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch( item )
	{
		case 0: Show_MotdMedallas(id, HEATSHOP), Show_MenuMedallas(id)
		case 1: Show_MotdMedallas(id, KNIFE), Show_MenuMedallas(id)
		case 2: Show_MotdMedallas(id, GRENADE), Show_MenuMedallas(id)
		case 3: Show_MotdMedallas(id, ADMIN), Show_MenuMedallas(id)
	}
	return PLUGIN_HANDLED;
}

stock _loading(id, type)
{
	static DataCenter[64], db1[25], db2[25], db3[25], db4[25], db5[25], db6[25], db7[25], db8[25], db9[25];
	
	switch(type)
	{
		case STEAMID:{
			
			if(fvault_get_data("db_steamid", iSteamID[id], DataCenter, charsmax(DataCenter)))
			{
				parse(DataCenter, 
				db1, charsmax(db1), 
				db2, charsmax(db2), 
				db3, charsmax(db3), 
				db4, charsmax(db4), 
				db5, charsmax(db5), 
				db6, charsmax(db6), 
				db7, charsmax(db7), 
				db8, charsmax(db8), 
				db9, charsmax(db9))

				gExp[id][HEATSHOP] = 	str_to_num(db1)
				gType[id][HEATSHOP] = 	str_to_num(db2)
				gExp[id][KNIFE] = 	str_to_num(db3)
				gType[id][KNIFE] = 	str_to_num(db4)
				gExp[id][GRENADE] = 	str_to_num(db5)
				gType[id][GRENADE] = 	str_to_num(db6)
				gExp[id][ADMIN] = 	str_to_num(db7)
				gType[id][ADMIN] = 	str_to_num(db8)
				iOptions[id][iMODELS] =	str_to_num(db9)
			}

		}
		case IDLAN:{

			if(fvault_get_data("db_idlan", iName[id], DataCenter, charsmax(DataCenter)))
			{
				parse(DataCenter, 
				db1, charsmax(db1), 
				db2, charsmax(db2), 
				db3, charsmax(db3), 
				db4, charsmax(db4), 
				db5, charsmax(db5), 
				db6, charsmax(db6), 
				db7, charsmax(db7), 
				db8, charsmax(db8), 
				db9, charsmax(db9))

				gExp[id][HEATSHOP] = 	str_to_num(db1)
				gType[id][HEATSHOP] = 	str_to_num(db2)
				gExp[id][KNIFE] = 	str_to_num(db3)
				gType[id][KNIFE] = 	str_to_num(db4)
				gExp[id][GRENADE] = 	str_to_num(db5)
				gType[id][GRENADE] = 	str_to_num(db6)
				gExp[id][ADMIN] = 	str_to_num(db7)
				gType[id][ADMIN] = 	str_to_num(db8)
				iOptions[id][iMODELS] =	str_to_num(db9)
			}
		}
		case SAVE_STEAMID:{
			
			formatex(DataCenter, charsmax(DataCenter), "%d %d %d %d %d %d %d %d %d", 
			gExp[id][HEATSHOP], gType[id][HEATSHOP], 
			gExp[id][KNIFE], gType[id][KNIFE], 
			gExp[id][GRENADE], gType[id][GRENADE], 
			gExp[id][ADMIN], gType[id][ADMIN], iOptions[id][iMODELS])
			
			fvault_set_data("db_steamid", iSteamID[id], DataCenter)
			
		}
		case SAVE_IDLAN:{
			formatex(DataCenter, charsmax(DataCenter), "%d %d %d %d %d %d %d %d %d", 
			gExp[id][HEATSHOP], gType[id][HEATSHOP], 
			gExp[id][KNIFE], gType[id][KNIFE], 
			gExp[id][GRENADE], gType[id][GRENADE], 
			gExp[id][ADMIN], gType[id][ADMIN], iOptions[id][iMODELS])
			
			fvault_set_data("db_idlan", iName[id], DataCenter)
		}
	}
}

stock UTIL_ResetPlayerDB(id)
{
	gExp[id][HEATSHOP] = gType[id][HEATSHOP] = 0;
	gExp[id][KNIFE] = gType[id][KNIFE] = 0;
	gExp[id][GRENADE] = gType[id][GRENADE] = 0;
	gExp[id][ADMIN] = gType[id][ADMIN] = 0;
	iOptions[id][iMODELS] = 0;
	kills[id] = 0;
	deaths[id] = 0;
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

stock PlaySound(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

stock GiveMedallas(const Index, const Type, const Count)
{
	static Temp[100];
	
	switch(Type)
	{
		case HEATSHOP:
		{
			if(gExp[Index][Type] >= 5000)
				return;
			
			gExp[Index][Type] += Count;
			
			static iStatus; iStatus = gType[Index][HEATSHOP];
			
			while(gExp[Index][Type] >= iHeatShop[gType[Index][HEATSHOP]][gEXP] && gType[Index][HEATSHOP] < charsmax(iHeatShop))
			++gType[Index][HEATSHOP];
			
			if(iStatus < gType[Index][HEATSHOP])
			{
				format(Temp, charsmax(Temp), "Subiste de Nivel de tu Medalla (HeatShop) a: %s", iHeatShop[gType[Index][HEATSHOP]][gNAME]);
				player_print(Index, "Felicidades!! Subiste de Nivel de tu^3 Medalla (HeatShop)^1 a:^4 %s", iHeatShop[gType[Index][HEATSHOP]][gNAME]);
				player_print(Index, "Informacion de tu^4 Medalla^1 en^4 Estadisticas...");
				player_print(Index, "Para ver todas los Medalla Disponibles.^4 /medallas^1 en say.");
				enviarHint(Index, Temp, 7, 8.0);
			}
				
		}
		case KNIFE:
		{
			gExp[Index][Type] += Count;
			
			static iStatus; iStatus = gType[Index][KNIFE];
			
			while(gExp[Index][Type] >= iKnife[gType[Index][KNIFE]][gEXP] && gType[Index][KNIFE] < charsmax(iKnife))
			++gType[Index][KNIFE];
			
			if(iStatus < gType[Index][KNIFE])
			{
				format(Temp, charsmax(Temp), "Subiste de Nivel de tu Medalla (Knife) a: %s", iKnife[gType[Index][KNIFE]][gNAME]);
				player_print(Index, "Felicidades!! Subiste de Nivel de tu^3 Medalla (Knife)^1 a:^4 %s", iKnife[gType[Index][KNIFE]][gNAME]);
				player_print(Index, "Informacion de tu^4 Medalla^1 en^4 Estadisticas...");
				player_print(Index, "Para ver todas los Medalla Disponibles.^4 /medallas^1 en say.");
				enviarHint(Index, Temp, 6, 8.0);
			}
		}
		case GRENADE:
		{
			gExp[Index][Type] += Count;
			
			static iStatus; iStatus = gType[Index][GRENADE];
			
			while(gExp[Index][Type] >= iHegrenade[gType[Index][GRENADE]][gEXP] && gType[Index][GRENADE] < charsmax(iHegrenade))
			++gType[Index][GRENADE];
			
			if(iStatus < gType[Index][GRENADE])
			{
				format(Temp, charsmax(Temp), "Subiste de Nivel de tu Medalla (Grenade) a: %s", iHegrenade[gType[Index][GRENADE]][gNAME]);
				player_print(Index, "Felicidades!! Subiste de Nivel de tu^3 Medalla (Grenade)^1 a:^4 %s", iHegrenade[gType[Index][GRENADE]][gNAME]);
				player_print(Index, "Informacion de tu^4 Medalla^1 en^4 Estadisticas...");
				player_print(Index, "Para ver todas los Medalla Disponibles.^4 /medallas^1 en say.");
				enviarHint(Index, Temp, 5, 8.0);
			}
		}
		case ADMIN:
		{
			gExp[Index][Type] += Count;
			
			static iStatus; iStatus = gType[Index][ADMIN];
			
			while(gExp[Index][Type] >= iAdmins[gType[Index][ADMIN]][gEXP] && gType[Index][ADMIN] < charsmax(iAdmins))
			++gType[Index][ADMIN];
			
			if(iStatus < gType[Index][ADMIN])
			{
				format(Temp, charsmax(Temp), "Subiste de Nivel de tu Medalla (Admin) a: %s", iAdmins[gType[Index][ADMIN]][gNAME]);
				player_print(Index, "Felicidades!! Subiste de Nivel de tu^3 Medalla (Admin)^1 a:^4 %s", iAdmins[gType[Index][ADMIN]][gNAME]);
				player_print(Index, "Informacion de tu^4 Medalla^1 en^4 Estadisticas...");
				player_print(Index, "Para ver todas los Medalla Disponibles.^4 /medallas^1 en say.");
				enviarHint(Index, Temp, 4, 8.0);
			}
		}
	}
}

stock ValidMessage(text[], maxcount) {
    static len, i, count
    len = strlen(text)
    count = 0
    
    if (!len)
        return false;
    
    for (i = 0; i < len; i++) {
        if (text[i] != ' ') {
            count++
            if (count >= maxcount)
                return true;
        }
    }
    
    return false;
}

stock fixbug(msg[], smax)
{
	static const chars[][]= 
	{
		"^0", "^1", "^2", "^3", "^4", "#", "%"
	}
	
	for(new i = 0; i < sizeof chars; i++)
	{
		if(contain(msg, chars[i]) != -1)
		{
			replace_all(msg, smax, chars[i], "*")
		}
	}
}

public check_country(id)
{
	get_user_ip(id, g_playerip[id], charsmax(g_playerip[]), 1)
	geoip_country_ex(g_playerip[id], g_playercountry[id], charsmax(g_playercountry[]), -1)
	
	if(equal(g_playercountry[id], "ERROR"))
	{
		if(contain(g_playerip[id],"192.168.") == 0 || equal(g_playerip[id],"127.0.0.1") || contain(g_playerip[id],"10.") == 0 ||  contain(g_playerip[id],"172.") == 0)
		{
			g_playercountry[id] = "LAN"
		}
		if(equal(g_playerip[id],"loopback"))
		{
			g_playercountry[id] = "ListenServer User"
		}
		else
		{
			g_playercountry[id] = "PaÃs desconocido"
		}
	}
}


/**************************************************************************************************/
/**************************************************************************************************/

public hook_say(id)
{
	if( !is_user_connected(id) )
		return PLUGIN_HANDLED_MAIN
		
	read_args(message, charsmax(message)) //191
	remove_quotes(message)

	// Gungame commands and empty messages
	if(message[0] == '@' || message[0] == '/' || message[0] == '!' || message[0] == '#' || message[0] == '$' || equal(message, "")) // Ignores Admin Hud Messages, Admin Slash commands
		//fix
		return PLUGIN_HANDLED_MAIN
		//return PLUGIN_CONTINUE
		
	fixbug(message, charsmax(message))
	
	if( !ValidMessage(message, 1) )
		return PLUGIN_CONTINUE
	
	new admin = 0, iFlags = get_user_flags(id)
	
	if(iFlags & OWNER) admin = 1
	else if(iFlags & SUB-OWNER) admin = 2
	else if(iFlags & QUEEN) admin = 3
	else if(iFlags & MANAGER) admin = 4
	else if(iFlags & SHERIF) admin = 5
	else if(iFlags & OFFICER) admin = 6
	else if(iFlags & STAFF) admin = 7
	else if(iFlags & PREMIUM) admin = 8
	else if(iFlags & VIP) admin = 9
	else if(iFlags & BIG-MASTER) admin = 10
	
	new isAlive
	
	if(is_user_alive(id))
	{
		isAlive = 1, alive = "^x03"
	}
	else {
		isAlive = 0, alive = "^x01*Muerto* "
	}
	
	get_user_name(id, name, charsmax(name))
	check_country(id)
	
	if(admin)
	{
		// Name
		switch(get_pcvar_num(g_NameColor))
		{
			case 3: color = "SPECTATOR"
			case 4: color = "CT"
			case 5: color = "TERRORIST"
			case 6: get_user_team(id, color, charsmax(color))
		}
		
		formatex(strName, charsmax(strName), "%s^x01 ||^x04 %s^x01 || %s^x04 %s", alive, g_playercountry[id], g_szTag[admin], name)
		
		// Message
		switch(get_pcvar_num(g_MessageColor))
		{
			case 1:    // Yellow
			{
				formatex(strText, charsmax(strText), "%s", message)
			}
			case 2:    // Green
			{
				formatex(strText, charsmax(strText), "^x04%s", message)
			}
			case 3:    // White
			{
				copy(color, 9, "SPECTATOR")
				formatex(strText, charsmax(strText), "^x03%s", message)
			}
			case 4:    // Blue
			{
				copy(color, 9, "CT")
				formatex(strText, charsmax(strText), "^x03%s", message)
			}
			case 5:    // Red
			{
				copy(color, 9, "TERRORIST")
				formatex(strText, charsmax(strText), "^x03%s", message)
			}
		}
	}
	else     // Player is not admin. Team-color name : Yellow message
	{
		get_user_team(id, color, charsmax(color))
		formatex(strName, charsmax(strName), "%s^x01 ||^x04 %s^x01 ||^x03 %s", alive, g_playercountry[id], name)
		formatex(strText, charsmax(strText), "%s", message)
	}
	
	formatex(message, charsmax(message), "%s ^x01: %s", strName, strText)
	
	sendMessage(color, isAlive)    // Sends the colored message
	
	//fix
	return PLUGIN_HANDLED_MAIN
	
	//return PLUGIN_CONTINUE
}

public hook_teamsay(id)
{
	if( !is_user_connected(id) )
		return PLUGIN_HANDLED_MAIN
		
	new playerTeam = get_user_team(id)
	
	switch(playerTeam) // Team names which appear on team-only messages
	{
		case 1: copy(playerTeamName, 11, "TT")
		case 2: copy(playerTeamName, 18, "CT")
		default: copy(playerTeamName, 9, "SPEC")
	}
	
	read_args(message, charsmax(message))
	remove_quotes(message)

	
	// Gungame commands and empty messages
	if(message[0] == '@' || message[0] == '/' || message[0] == '!' || message[0] == '#' || message[0] == '$' || equal(message, "")) // Ignores Admin Hud Messages, Admin Slash commands
		//fix
		return PLUGIN_HANDLED_MAIN
		//return PLUGIN_CONTINUE
		
	fixbug(message, charsmax(message))
	
	if( !ValidMessage(message, 1) )
		return PLUGIN_CONTINUE
	
	new admin = 0, iFlags = get_user_flags(id)
	
	if(iFlags & OWNER) admin = 1
	else if(iFlags & SUB-OWNER) admin = 2
	else if(iFlags & QUEEN) admin = 3
	else if(iFlags & MANAGER) admin = 4
	else if(iFlags & SHERIF) admin = 5
	else if(iFlags & OFFICER) admin = 6
	else if(iFlags & STAFF) admin = 7
	else if(iFlags & PREMIUM) admin = 8
	else if(iFlags & VIP) admin = 9
	else if(iFlags & BIG-MASTER) admin = 10
	
	new isAlive
	
	if(is_user_alive(id))
	{
		isAlive = 1, alive = "^x03"
	}
	else {
		isAlive = 0, alive = "^x01*Muerto* "
	}
	
	get_user_name(id, name, charsmax(name))
	
	if(admin)
	{
		// Name
		switch(get_pcvar_num(g_NameColor))
		{
			case 3: color = "SPECTATOR"
			case 4: color = "CT"
			case 5: color = "TERRORIST"
			case 6: get_user_team(id, color, charsmax(color))
		}
		
		formatex(strName, charsmax(strName), "%s^x01(^x03%s^x01) %s^x04 %s", alive, playerTeamName, g_szTag[admin], name)

		// Message
		switch(get_pcvar_num(g_MessageColor))
		{
			case 1:    // Yellow
			{
				formatex(strText, charsmax(strText), "%s", message)
			}
			case 2:    // Green
			{
				formatex(strText, charsmax(strText), "^x04%s", message)
			}
			case 3:    // White
			{
				copy(color, 9, "SPECTATOR")
				formatex(strText, charsmax(strText), "^x03%s", message)
			}
			case 4:    // Blue
			{
				copy(color, 9, "CT")
				formatex(strText, charsmax(strText), "^x03%s", message)
			}
			case 5:    // Red
			{
				copy(color, 9, "TERRORIST")
				formatex(strText, charsmax(strText), "^x03%s", message)
			}
		}
	}
	else     // Player is not admin. Team-color name : Yellow message
	{
		get_user_team(id, color, charsmax(color))
		formatex(strName, charsmax(strName), "%s^x01(^x03%s^x01)^x03 %s", alive, playerTeamName, name)
		formatex(strText, charsmax(strText), "%s", message)
	}
	
	formatex(message, charsmax(message), "%s ^x01: %s", strName, strText)
	sendTeamMessage(color, isAlive, playerTeam)    // Sends the colored message
	
	//fix
	return PLUGIN_HANDLED_MAIN
	
	//return PLUGIN_CONTINUE
}

/**************************************************************************************************/

public set_color(id, level, cid)
{
	if( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
		
	read_argv(1, arg, 1)
	
	newColor = str_to_num(arg)
	
	if(newColor >= 1 && newColor <= 5)
	{
		set_pcvar_num(g_MessageColor, newColor)
		
		if(get_pcvar_num(g_NameColor) != 1 &&
		((newColor == 3 &&  get_pcvar_num(g_NameColor) != 3)
		||(newColor == 4 &&  get_pcvar_num(g_NameColor) != 4)
		||(newColor == 5 &&  get_pcvar_num(g_NameColor) != 5)))
		{
			set_pcvar_num(g_NameColor, 2)
		}
	}
	
	return PLUGIN_HANDLED
}

public set_name_color(id, level, cid)
{
	if( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
		
	read_argv(1, arg, 1)
	
	newColor = str_to_num(arg)
	
	if(newColor >= 1 && newColor <= 6)
	{
		set_pcvar_num(g_NameColor, newColor)
		
		if((get_pcvar_num(g_MessageColor) != 1
		&&((newColor == 3 &&  get_pcvar_num(g_MessageColor) != 3)
		||(newColor == 4 &&  get_pcvar_num(g_MessageColor) != 4)
		||(newColor == 5 &&  get_pcvar_num(g_MessageColor) != 5)))
		|| get_pcvar_num(g_NameColor) == 6)
		{
			set_pcvar_num(g_MessageColor, 2)
		}
	}
	return PLUGIN_HANDLED
}

public set_listen(id, level, cid)
{
	if( !cmd_access(id, level, cid, 2) )
		return PLUGIN_HANDLED
		
	read_argv(1, arg, 1)
	
	newListen = str_to_num(arg)
	
	set_pcvar_num(g_AdminListen, newListen)
	
	return PLUGIN_HANDLED
}

public sendMessage(color[], alive)
{
	for(new player = 1; player < g_maxplayers; player++)
	{
		if( !is_user_connected(player) )
			continue
			
		if(alive && is_user_alive(player) || !alive && !is_user_alive(player) 
		|| get_pcvar_num(g_AdminListen))
		{
			get_user_team(player, teamName, charsmax(teamName))    // Stores user's team name to change back after sending the message
			changeTeamInfo(player, color)        // Changes user's team according to color choosen
			writeMessage(player, message)        // Writes the message on player's chat
			changeTeamInfo(player, teamName)    // Changes user's team back to original
		}
	}
}

public sendTeamMessage(color[], alive, playerTeam)
{
	for(new player = 1; player < g_maxplayers; player++)
	{
		if( !is_user_connected(player) )
			continue
			
		if(get_user_team(player) == playerTeam)
		{
			if(alive && is_user_alive(player) || !alive && !is_user_alive(player))
			{
				get_user_team(player, teamName, charsmax(teamName))    // Stores user's team name to change back after sending the message
				changeTeamInfo(player, color)        // Changes user's team according to color choosen
				writeMessage(player, message)        // Writes the message on player's chat
				changeTeamInfo(player, teamName)    // Changes user's team back to original
			}
		}
	}
}

public changeTeamInfo(player, team[])
{
        message_begin(MSG_ONE, teamInfo, _, player)    // Tells to to modify teamInfo(Which is responsable for which time player is)
        write_byte(player)                // Write byte needed
        write_string(team)                // Changes player's team
        message_end()                    // Also Needed
}


public writeMessage(player, message[])
{
        message_begin(MSG_ONE, msgSayText, {0, 0, 0}, player)    // Tells to modify sayText(Which is responsable for writing colored messages)
        write_byte(player)                    // Write byte needed
        write_string(message)                    // Effectively write the message, finally, afterall
        message_end()                        // Needed as always
}
