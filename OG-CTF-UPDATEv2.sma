/* Anti Decompiler :) */
#pragma compress 1

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <reapi>

new const MOD_TITLE[] =		"[ ReAPI ] JCTF"				/* Please don't modify. */
new const MOD_AUTHOR[] =		"Digi,yododo,jesuspunk, Spy.VE Edit"		/* If you make major changes, add " & YourName" at the end */
new const MOD_VERSION[] =		"0.3.1c"					/* If you make major changes, add "custom" at the end but do not modify the actual version number! */

#define FEATURE_BUY		true
#define FEATURE_ADRENALINE	true
#define FEATURE_TEAMBALANCE	true
#define RESPAWNMAXTIMECHECK 	5

#define HUD_HELP		random_num(0,255), random_num(0,255), random_num(0,255), -1.0, 0.25, 2, 1.0, 0.8, .fadeintime = 0.04
#define HUD_HELP2		random_num(0,255), random_num(0,255), random_num(0,255), -1.0, 0.25, 2, 1.0, 0.8, .fadeintime = 0.04
#define HUD_SPAWN		random_num(0,255), random_num(0,255), random_num(0,255), -1.0, 0.6, 1, 1.0, 0.8

#define HUD_ANNOUNCE		-1.0, 0.3, 2, 1.0, 0.8, .fadeintime = 0.04

#define INFO 			"\d[\r OzutGamer`s\d ]\w Captura la Bandera. + Rangos. \r||RAMPAGE||^n\d[\r GRUPO\d ]\w www.facebook.com/groups/community.og/"

/* --------------------------------------------------------------------------------------------	
	[REWARD FOR]				[MONEY]		[FRAGS]		[ADRENALINE]
-------------------------------------------------------------------------------------------- */
#define REWARD_RETURN				500,		0,		10
#define REWARD_RETURN_ASSIST			500,		0,		10
#define REWARD_CAPTURE				5000,		2,		20
#define REWARD_CAPTURE_ASSIST			5000,		2,		25
#define REWARD_CAPTURE_TEAM			1000,		1,		10
#define REWARD_STEAL				1000,		1,		10
#define REWARD_PICKUP				500,		1,		5
#define PENALTY_DROP				-1500,		-1,		-10
#define REWARD_KILLCARRIER			500,		1,		10

#define PENALTY_SUICIDE				0,		-1,		-20
#define PENALTY_TEAMKILL			0,		0,		-20

const ADMIN_RETURNWAIT =				15		// time the flag needs to stay dropped before it can be returned by command
const Float:SPEED_FLAG =				1.1		// speed while carying the enemy flag
new const Float:BASE_HEAL_DISTANCE =		400.0		// healing distance for flag

new const FLAG_SAVELOCATION[] =			"maps/%s.ctf" // you can change where .ctf files are saved/loaded from

#define FLAG_IGNORE_BOTS			true		// set to true if you don't want bots to pick up flags

new const INFO_TARGET[] =				"info_target"
new const ITEM_CLASSNAME[] =			"ctf_item"
new const WEAPONBOX[] =				"weaponbox"

new const BASE_CLASSNAME[] =			"ctf_flagbase"
new const Float:BASE_THINK =			0.25

new const FLAG_CLASSNAME[] =			"ctf_flag"
new const FLAG_MODEL[] =				"models/OzutServers/ctf/Banderas.mdl"

new const Float:FLAG_THINK =			0.1
const FLAG_SKIPTHINK =				20 	/* FLAG_THINK * FLAG_SKIPTHINK = 2.0 seconds ! */

new const Float:FLAG_HULL_MIN[3] =		{-2.0, -2.0, 0.0}
new const Float:FLAG_HULL_MAX[3] =		{2.0, 2.0, 16.0}

new const Float:FLAG_SPAWN_VELOCITY[3] =		{0.0, 0.0, -500.0}
new const Float:FLAG_SPAWN_ANGLES[3] =		{0.0, 0.0, 0.0}

new const Float:FLAG_DROP_VELOCITY[3] =		{0.0, 0.0, 50.0}

new const Float:FLAG_PICKUPDISTANCE =		80.0

const FLAG_LIGHT_RANGE =				12
const FLAG_LIGHT_LIFE =				5
const FLAG_LIGHT_DECAY =				1
	
const FLAG_ANI_DROPPED =				0
const FLAG_ANI_STAND =				1
const FLAG_ANI_BASE =				2

const FLAG_HOLD_BASE =				33
const FLAG_HOLD_DROPPED =				34

#if FEATURE_BUY == true

new const WHITESPACE[] =				" "
new const MENU_BUY[] =				"menu_buy"
new const MENU_KEYS_BUY =				(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

new const BUY_ITEM_DISABLED[] =			"r"
new const BUY_ITEM_AVAILABLE[] =			"w"

#endif // FEATURE_BUY

#if FEATURE_ADRENALINE == true
new const BUY_ITEM_AVAILABLE2[] =			"y"
#endif // FEATURE_ADRENALINE

new const TAG[] = 					"^4[^1OzutGamer`s^4]^1"
new const CONSOLE_PREFIX[] =			"[OzutGamer`s] "

const FADE_OUT =					0x0000
const FADE_IN =					0x0001
const FADE_MODULATE =				0x0002
const FADE_STAY =					0x0004
	
const m_iUserPrefs =				510
const m_flNextPrimaryAttack =			46
const m_flNextSecondaryAttack =			47

new const PLAYER[] =				"player"
#define NULL					""

#define entity_create(%1) 			create_entity(%1)
#define entity_spawn(%1)			DispatchSpawn(%1)
#define entity_think(%1)			call_think(%1)
#define entity_remove(%1)			remove_entity(%1)
#define weapon_remove(%1)			call_think(%1)

#define task_set(%1)				set_task(%1)
#define task_remove(%1)				remove_task(%1)

#define player_hasFlag(%1)			(g_iFlagHolder[TEAM_RED] == %1 || g_iFlagHolder[TEAM_BLUE] == %1)
#define player_allowChangeTeam(%1)		set_pdata_int(%1, 125, get_pdata_int(%1, 125) & ~(1<<8))
#define get_opTeam(%1)				(%1 == TEAM_BLUE ? TEAM_RED : (%1 == TEAM_RED ? TEAM_BLUE : 0))



enum
{
	x,
	y,
	z
}

enum (+= 64)
{
	TASK_RESPAWN = 64,
	TASK_PROTECTION,
	TASK_DAMAGEPROTECTION,
	TASK_EQUIPAMENT,
	TASK_PUTINSERVER,
	TASK_TEAMBALANCE,
	TASK_ADRENALINE,
	TASK_DEFUSE,
	TASK_CHECKHP
}

enum
{
	TEAM_NONE = 0,
	TEAM_RED,
	TEAM_BLUE,
	TEAM_SPEC
}

new const g_szCSTeams[][] =
{
	NULL,
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new const g_szTeamName[][] =
{
	NULL,
	"Red",
	"Blue",
	"Spectator"
}

new const g_szMLTeamName[][] =
{
	NULL,
	"TEAM_RED",
	"TEAM_BLUE",
	"TEAM_SPEC"
}

new const g_szMLFlagTeam[][] =
{
	NULL,
	"FLAG_RED",
	"FLAG_BLUE",
	NULL
}

enum
{
	FLAG_STOLEN = 0,
	FLAG_PICKED,
	FLAG_DROPPED,
	FLAG_MANUALDROP,
	FLAG_RETURNED,
	FLAG_CAPTURED,
	FLAG_AUTORETURN,
	FLAG_ADMINRETURN
}

enum
{
	EVENT_TAKEN = 0,
	EVENT_DROPPED,
	EVENT_RETURNED,
	EVENT_SCORE,
}

new const g_szSounds[][][] =
{
	{NULL, "red_flag_taken", "blue_flag_taken"},
	{NULL, "red_flag_dropped", "blue_flag_dropped"},
	{NULL, "red_flag_returned", "blue_flag_returned"},
	{NULL, "red_team_scores", "blue_team_scores"}
}

#if FEATURE_BUY == true

enum
{
	no_weapon,
	primary,
	secondary,
	he,
	flash,
	smoke,
	armor,
	nvg
}

new const g_szRebuyCommands[][] =
{
	NULL,
	"PrimaryWeapon",
	"SecondaryWeapon",
	"HEGrenade",
	"Flashbang",
	"SmokeGrenade",
	"Armor",
	"NightVision"
}

#endif // FEATURE_BUY

new const g_szRemoveEntities[][] =
{
	"func_buyzone",
	"armoury_entity",
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"info_map_parameters",
	"player_weaponstrip",
	"game_player_equip"
}

enum
{
	ZERO = 0,
	W_P228,
	W_SHIELD,
	W_SCOUT,
	W_HEGRENADE,
	W_XM1014,
	W_C4,
	W_MAC10,
	W_AUG,
	W_SMOKEGRENADE,
	W_ELITE,
	W_FIVESEVEN,
	W_UMP45,
	W_SG550,
	W_GALIL,
	W_FAMAS,
	W_USP,
	W_GLOCK18,
	W_AWP,
	W_MP5NAVY,
	W_M249,
	W_M3,
	W_M4A1,
	W_TMP,
	W_G3SG1,
	W_FLASHBANG,
	W_DEAGLE,
	W_SG552,
	W_AK47,
	W_KNIFE,
	W_P90,
	W_VEST,
	W_VESTHELM,
	W_NVG
}
/*
new const g_iBPAmmo[] =
{
	0,		// (unknown)
	52,		// P228
	0,		// SHIELD
	90,		// SCOUT
	0,		// HEGRENADE (not used)
	32,		// XM1014
	0,		// C4 (not used)
	100,		// MAC10
	90,		// AUG
	0,		// SMOKEGRENADE (not used)
	120,		// ELITE
	100,		// FIVESEVEN
	100,		// UMP45
	90,		// SG550
	90,		// GALIL
	90,		// FAMAS
	100,		// USP
	120,		// GLOCK18
	30,		// AWP
	120,		// MP5NAVY
	200,		// M249
	32,		// M3
	90,		// M4A1
	120,		// TMP
	90,		// G3SG1
	0,		// FLASHBANG (not used)
	35,		// DEAGLE
	90,		// SG552
	90,		// AK47
	0,		// KNIFE (not used)
	100,		// P90
	0,		// Kevlar (not used)
	0,		// Kevlar + Helm (not used)
	0		// NVG (not used)
}*/

#if FEATURE_BUY == true

new const g_iWeaponPrice[] =
{
	0,		// (unknown)
	600,		// P228
	10000,		// SHIELD
	6000,		// SCOUT
	300,		// HEGRENADE
	3000,		// XM1014
	12000,		// C4
	1400,		// MAC10
	3500,		// AUG
	99999,		// SMOKEGRENADE
	1000,		// ELITE
	750,		// FIVESEVEN
	1700,		// UMP45
	6000,		// SG550
	2000,		// GALIL
	2250,		// FAMAS
	500,		// USP
	400,		// GLOCK18
	10000,		// AWP
	1500,		// MP5NAVY
	5000,		// M249
	1700,		// M3
	3100,		// M4A1
	1250,		// TMP
	7000,		// G3SG1
	99999,		// FLASHBANG
	650,		// DEAGLE
	3500,		// SG552
	2500,		// AK47
	0,		// KNIFE (not used)
	2350,		// P90
	650,		// Kevlar
	1000,		// Kevlar + Helm
	1250		// NVG
}

#endif // FEATURE_BUY

#if FEATURE_BUY == true && FEATURE_ADRENALINE == true

new const g_iWeaponAdrenaline[] =
{
	0,		// (unknown)
	0,		// P228
	50,		// SHIELD
	50,		// SCOUT
	0,		// HEGRENADE
	0,		// XM1014
	80,		// C4
	0,		// MAC10
	0,		// AUG
	0,		// SMOKEGRENADE
	0,		// ELITE
	0,		// FIVESEVEN
	0,		// UMP45
	30,		// SG550
	0,		// GALIL
	0,		// FAMAS
	0,		// USP
	0,		// GLOCK18
	100,		// AWP
	0,		// MP5NAVY
	10,		// M249
	0,		// M3
	0,		// M4A1
	0,		// TMP
	30,		// G3SG1
	0,		// FLASHBANG
	0,		// DEAGLE
	0,		// SG552
	0,		// AK47
	0,		// KNIFE (not used)
	0,		// P90
	0,		// Kevlar
	0,		// Kevlar + Helm
	0		// NVG
}

#endif // FEATURE_ADRENALINE

#if FEATURE_BUY == true

new const g_iWeaponSlot[] =
{
	0,		// none
	2,		// P228
	1,		// SHIELD
	1,		// SCOUT
	4,		// HEGRENADE
	1,		// XM1014
	5,		// C4
	1,		// MAC10
	1,		// AUG
	4,		// SMOKEGRENADE
	2,		// ELITE
	2,		// FIVESEVEN
	1,		// UMP45
	1,		// SG550
	1,		// GALIL
	1,		// FAMAS
	2,		// USP
	2,		// GLOCK18
	1,		// AWP
	1,		// MP5NAVY
	1,		// M249
	1,		// M3
	1,		// M4A1
	1,		// TMP
	1,		// G3SG1
	4,		// FLASHBANG
	2,		// DEAGLE
	1,		// SG552
	1,		// AK47
	3,		// KNIFE (not used)
	1,		// P90
	0,		// Kevlar
	0,		// Kevlar + Helm
	0		// NVG
}

#endif // FEATURE_BUY

new const g_szWeaponEntity[][24] =
{
	NULL,
	"weapon_p228",
	"weapon_shield",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90",
	"item_kevlar",
	"item_assaultsuit",
	NULL
}

#if FEATURE_BUY == true

new const g_szWeaponCommands[][] =
{
	{NULL,			NULL},
	{"p228",		"228compact"},
	{"shield",		NULL},
	{"scout",		NULL},
	{"hegren",		NULL},
	{"xm1014",		"autoshotgun"},
	{NULL,			NULL},
	{"mac10",		NULL},
	{"aug",			"bullpup"},
	{"sgren",		NULL},
	{"elites",		NULL},
	{"fiveseven",		"fn57"},
	{"ump45",		"sm"},
	{"sg550",		"krieg550"},
	{"galil",		"defender"},
	{"famas",		"clarion"},
	{"usp",			"km45"},
	{"glock",		"9x19mm"},
	{"awp",			"magnum"},
	{"mp5",			"mp"},
	{"m249",		NULL},
	{"m3",			"12gauge"},
	{"m4a1",		NULL},
	{"tmp",			NULL},
	{"g3sg1",		"d3au1"},
	{"flash",		NULL},
	{"deagle",		"nighthawk"},
	{"sg552",		"krieg552"},
	{"ak47",		"cv47"},
	{NULL,			NULL},
	{"p90",			"c90"},
	{"vest",		NULL},
	{"vesthelm",		NULL},
	{"nvgs",		NULL}
}

#endif // FEATURE_BUY


new const Float:g_fWeaponRunSpeed[] = // CONFIGURABLE - weapon running speed (edit the numbers in the list)
{
	150.0,	// Zoomed speed with any weapon
	250.0,	// P228
	0.0,		// SHIELD (not used) 
	260.0,	// SCOUT
	250.0,	// HEGRENADE
	240.0,	// XM1014
	250.0,	// C4
	250.0,	// MAC10
	240.0,	// AUG
	250.0,	// SMOKEGRENADE
	250.0,	// ELITE
	250.0,	// FIVESEVEN
	250.0,	// UMP45
	210.0,	// SG550
	240.0,	// GALIL
	240.0,	// FAMAS
	250.0,	// USP
	250.0,	// GLOCK18
	210.0,	// AWP
	250.0,	// MP5NAVY
	220.0,	// M249
	230.0,	// M3
	230.0,	// M4A1
	250.0,	// TMP
	210.0,	// G3SG1
	250.0,	// FLASHBANG
	250.0,	// DEAGLE
	235.0,	// SG552
	221.0,	// AK47
	250.0,	// KNIFE
	245.0,	// P90
	0.0,		// Kevlar (not used)
	0.0,		// Kevlar + Helm (not used)
	0.0		// NVG (not used)
}

new g_iMaxPlayers
new g_szMap[32]
new g_iTeam[33]
new g_iScore[3]
new g_iSync[4]
new g_iFlagHolder[3]
new g_iFlagEntity[3]
new g_iBaseEntity[3]
new Float:g_fFlagDropped[3]

#if FEATURE_BUY == true

new g_iMenu[33]
new g_iRebuy[33][8]
new g_iAutobuy[33][64]
new g_iRebuyWeapons[33][8]

new pCvar_ctf_nospam_flash
new pCvar_ctf_nospam_he
new pCvar_ctf_nospam_smoke

new gMsg_BuyClose

#endif // FEATURE_BUY

new Float:g_iMaxArmor[33]
new Float:g_iMaxHealth[33]
new g_iAdrenaline[33]
new g_iAdrenalineUse[33]
new bool:g_bRestarting
new bool:g_bBot[33]
new bool:g_bAlive[33]
new bool:g_bDefuse[33]
new bool:g_bLights[33]
new bool:g_bBuyZone[33]
new bool:g_bSuicide[33]
new bool:g_bAssisted[33][3]
new bool:g_bProtected[33]
new bool:g_bRestarted[33]
new bool:g_bFirstSpawn[33]

new Float:g_fFlagBase[3][3]
new Float:g_fFlagLocation[3][3]
new Float:g_fWeaponSpeed[33]
new Float:g_fLastDrop[33]
new Float:g_fLastBuy[33][4]

new pCvar_ctf_flagheal
new pCvar_ctf_flagreturn
new pCvar_ctf_respawntime
new pCvar_ctf_protection
new pCvar_ctf_weaponstay
new pCvar_ctf_spawnmoney

new pCvar_ctf_sound[4]
new pCvar_mp_winlimit
new pCvar_mp_startmoney

#if FEATURE_TEAMBALANCE == true
new pCvar_mp_autoteambalance
#endif

new gMsg_RoundTime
new gMsg_HostageK
new gMsg_HostagePos
new gMsg_ScoreInfo
new gMsg_TeamScore
new gHook_EntSpawn
new gSpr_regeneration
new g_iForwardReturn
new g_iFW_flag
new pCvar_ctf_flagendround

public plugin_precache()
{
	precache_model(FLAG_MODEL)

	gSpr_regeneration = precache_model("sprites/OzutServers/HP.spr")

	for(new szSound[64], i = 0; i < sizeof g_szSounds; i++)
	{
		for(new t = 1; t <= 2; t++)
		{
			formatex(szSound, charsmax(szSound), "sound/OzutServers/ctf/%s.mp3", g_szSounds[i][t])

			precache_generic(szSound)
		}
	}

	gHook_EntSpawn = register_forward(FM_Spawn, "ent_spawn")
}

public ent_spawn(ent)
{
	if(!is_entity(ent))
		return FMRES_IGNORED

	static szClass[32]

	entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass))
	for(new i = 0; i < sizeof g_szRemoveEntities; i++)
	{
		if(equal(szClass, g_szRemoveEntities[i]))
		{
			entity_remove(ent)

			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}


enum _:CMDS
{
COMMAND[32],
VALUE[10]
}

new Pregame_Cmds[][CMDS] =
{
{"mp_auto_reload_weapons", "1"},
{"mp_auto_join_team", "0"},
{"mp_freezetime", "0"},
{"mp_timelimit", "30"},
{"mp_refill_bpammo_weapons", "3"},
{"sv_alltalk", "1"},
{"mp_buytime", "-1"},
{"mp_consistency", "1"},
{"mp_flashlight", "0"},
{"mp_forcechasecam", "0"},
{"mp_forcecamera", "0"},
{"allow_spectators", "1"},
{"sv_timeout", "10"},
{"mp_infinite_ammo","2"}
}

public plugin_init()
{
	register_plugin(MOD_TITLE, MOD_VERSION, MOD_AUTHOR)
	set_pcvar_string(register_cvar("jctf_version", MOD_VERSION, FCVAR_SERVER|FCVAR_SPONLY), MOD_VERSION)

	register_dictionary("CTF.txt")
	register_dictionary("common.txt")

	// Forwards, hooks, events, etc
	unregister_forward(FM_Spawn, gHook_EntSpawn)
	
	register_touch(FLAG_CLASSNAME, PLAYER, "flag_touch")
	
	register_think(FLAG_CLASSNAME, "flag_think")
	register_think(BASE_CLASSNAME, "base_think")

	register_logevent("event_restartGame", 2, "1&Restart_Round", "1&Game_Commencing")
	register_event("HLTV", "event_roundStart", "a", "1=0", "2=0")
	register_event("TeamInfo", "player_joinTeam", "a")
	register_event("CurWeapon", "player_currentWeapon", "be", "1=1")
	register_event("SetFOV", "player_currentWeapon", "be", "1>1")
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "player_spawn", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "player_killed", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "ham_PlayerKilledPost", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "player_damage", .post = false);
	
	RegisterHam(Ham_Spawn, WEAPONBOX, "weapon_spawn", 1)
	RegisterHam(Ham_BloodColor, "player", "Forward_BloodColor", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, g_szWeaponEntity[W_KNIFE], "player_useWeapon", 1) // not a typo
	
	g_iSync[0] = CreateHudSyncObj()
	g_iSync[1] = CreateHudSyncObj()
	g_iSync[2] = CreateHudSyncObj()
	g_iSync[3] = CreateHudSyncObj()

#if FEATURE_BUY == true

	register_menucmd(register_menuid(MENU_BUY), MENU_KEYS_BUY, "player_key_buy")

	register_event("StatusIcon", "player_inBuyZone", "be", "2=buyzone")

	register_clcmd("buy", "player_cmd_buy_main")
	register_clcmd("buyammo1", "msg_block")
	register_clcmd("buyammo2", "msg_block")
	register_clcmd("primammo", "msg_block")
	register_clcmd("secammo", "msg_block")
	register_clcmd("client_buy_open", "player_cmd_buyVGUI")

	register_clcmd("autobuy", "player_cmd_autobuy")
	register_clcmd("cl_autobuy", "player_cmd_autobuy")
	register_clcmd("cl_setautobuy", "player_cmd_setAutobuy")

	register_clcmd("rebuy", "player_cmd_rebuy")
	register_clcmd("cl_rebuy", "player_cmd_rebuy")
	register_clcmd("cl_setrebuy", "player_cmd_setRebuy")

	register_clcmd("buyequip", "player_cmd_buy_equipament")

#endif // FEATURE_BUY

	for(new w = W_P228; w <= W_NVG; w++)
	{
#if FEATURE_BUY == true
		for(new i = 0; i < 2; i++)
		{
			if(strlen(g_szWeaponCommands[w][i]))
				register_clcmd(g_szWeaponCommands[w][i], "player_cmd_buyWeapon")
		}
#endif // FEATURE_BUY

		if(w != W_SHIELD && w <= W_P90)
			RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponEntity[w], "player_useWeapon", 1)
	}

	register_clcmd("og_moveflag", "admin_cmd_moveFlag", ADMIN_LEVEL_W, "<red/blue> - Moves team's flag base to your origin (for map management)")
	register_clcmd("og_save", "admin_cmd_saveFlags",ADMIN_LEVEL_W)
	register_clcmd("og_return", "admin_cmd_returnFlag", ADMIN_LEVEL_W)
	
	/** SOLTAR BANDERA COMANDO. **/
	register_clcmd("say /soltar", "player_cmd_dropFlag")
	register_clcmd("say soltar", "player_cmd_dropFlag")
	
	register_clcmd("say dropflag", "player_cmd_dropFlag")
	register_clcmd("say /dropflag", "player_cmd_dropFlag")

	register_clcmd("SOLTAR", "player_cmd_dropFlag")
	
	register_clcmd("fullupdate", "msg_block")
	
	gMsg_HostagePos = get_user_msgid("HostagePos")
	gMsg_HostageK = get_user_msgid("HostageK")
	gMsg_RoundTime = get_user_msgid("RoundTime")
	gMsg_ScoreInfo = get_user_msgid("ScoreInfo")
	gMsg_TeamScore = get_user_msgid("TeamScore")

	register_message(get_user_msgid("BombDrop"), "msg_block")
	register_message(get_user_msgid("ClCorpse"), "msg_block")
	register_message(gMsg_HostageK, "msg_block")
	register_message(gMsg_HostagePos, "msg_block")
	register_message(gMsg_RoundTime, "msg_roundTime")
	register_message(gMsg_TeamScore, "msg_teamScore")

	// CVARS
	pCvar_ctf_flagheal = register_cvar("ctf_flagheal", "1")
	pCvar_ctf_flagreturn = register_cvar("ctf_flagreturn", "60")
	pCvar_ctf_respawntime = register_cvar("ctf_respawntime", "5")
	pCvar_ctf_protection = register_cvar("ctf_protection", "3")
	pCvar_ctf_weaponstay = register_cvar("ctf_weaponstay", "10")
	pCvar_ctf_spawnmoney = register_cvar("ctf_spawnmoney", "1000")
	pCvar_ctf_flagendround = register_cvar("ctf_flagendround", "0")

#if FEATURE_BUY == true

	pCvar_ctf_nospam_flash = register_cvar("ctf_nospam_flash", "20")
	pCvar_ctf_nospam_he = register_cvar("ctf_nospam_he", "20")
	pCvar_ctf_nospam_smoke = register_cvar("ctf_nospam_smoke", "20")

	gMsg_BuyClose = get_user_msgid("BuyClose")

#endif // FEATURE_BUY

	pCvar_ctf_sound[EVENT_TAKEN] = register_cvar("ctf_sound_taken", "1")
	pCvar_ctf_sound[EVENT_DROPPED] = register_cvar("ctf_sound_dropped", "1")
	pCvar_ctf_sound[EVENT_RETURNED] = register_cvar("ctf_sound_returned", "1")
	pCvar_ctf_sound[EVENT_SCORE] = register_cvar("ctf_sound_score", "1")

	pCvar_mp_winlimit = get_cvar_pointer("mp_winlimit")
	pCvar_mp_startmoney = get_cvar_pointer("mp_startmoney")
	
#if FEATURE_TEAMBALANCE == true
	pCvar_mp_autoteambalance = get_cvar_pointer("mp_autoteambalance")
#endif

	// Plugin's forwards
	g_iFW_flag = CreateMultiForward("jctf_flag", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	get_mapname(g_szMap, charsmax(g_szMap))
	g_iMaxPlayers = get_member_game(m_nMaxPlayers)
	
	set_member_game(m_GameDesc, "www.communityog.com");
	
	set_task(5.0, "start_pregame")
}

public start_pregame()
{
	for(new i = 0 ; i < sizeof(Pregame_Cmds) ; i++)
	{
		set_cvar_string(Pregame_Cmds[i][COMMAND], Pregame_Cmds[i][VALUE])
	}

	client_cmd(0, "stopsound;spk ^"doors/doormove1.wav^"");
	server_cmd("sv_restart 1")
}

public ham_PlayerKilledPost(victim, attacker, sg)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker) || !attacker || attacker == victim)
		return HAM_IGNORED;
		
	if(g_iAdrenaline[attacker] == 100)
	{
		client_print(attacker, print_center, "** Tienes la Adrenalina al Maxmimo!! Presiona (N) para Usarla. **")
	}
	else
	{
		client_print(attacker, print_center, "** +5 Adrenalina por matar!! **")
		g_iAdrenaline[attacker]+= 5
	}

	return PLUGIN_HANDLED;
}

public plugin_cfg()
{
	new szFile[64]

	formatex(szFile, charsmax(szFile), FLAG_SAVELOCATION, g_szMap)

	new hFile = fopen(szFile, "rt")

	if(hFile)
	{
		new iFlagTeam = TEAM_RED
		new szData[24]
		new szOrigin[3][6]

		while(fgets(hFile, szData, charsmax(szData)))
		{
			if(iFlagTeam > TEAM_BLUE)
				break

			trim(szData)
			parse(szData, szOrigin[x], charsmax(szOrigin[]), szOrigin[y], charsmax(szOrigin[]), szOrigin[z], charsmax(szOrigin[]))

			g_fFlagBase[iFlagTeam][x] = str_to_float(szOrigin[x])
			g_fFlagBase[iFlagTeam][y] = str_to_float(szOrigin[y])
			g_fFlagBase[iFlagTeam][z] = str_to_float(szOrigin[z])

			iFlagTeam++
		}

		fclose(hFile)
	}

	flag_spawn(TEAM_RED)
	flag_spawn(TEAM_BLUE)
}

public plugin_natives()
{
	register_library("jctf")

	register_native("jctf_get_team", "native_get_team")
	register_native("jctf_get_flagcarrier", "native_get_flagcarrier")
	register_native("get_user_adrenaline", "native_get_adrenaline")
	register_native("set_user_adrenaline", "native_set_adrenaline")
}

public plugin_end()
{
	DestroyForward(g_iFW_flag)
}

public native_get_team(iPlugin, iParams)
{
	/* jctf_get_team(id) */

	return g_iTeam[get_param(1)]
}

public native_get_adrenaline(iPlugin, iParams)
{
	return g_iAdrenaline[get_param(1)]
}

public native_set_adrenaline(iPlugin, iParams)
{
	g_iAdrenaline[get_param(1)] = get_param(2)
}

public native_get_flagcarrier(iPlugin, iParams)
{
	/* jctf_get_flagcarrier(id) */

	new id = get_param(1)

	return g_iFlagHolder[get_opTeam(g_iTeam[id])] == id
}

public flag_spawn(iFlagTeam)
{
	if(g_fFlagBase[iFlagTeam][x] == 0.0 && g_fFlagBase[iFlagTeam][y] == 0.0 && g_fFlagBase[iFlagTeam][z] == 0.0)
	{
		new iFindSpawn = rg_find_ent_by_class(g_iMaxPlayers, iFlagTeam == TEAM_BLUE ? "info_player_start" : "info_player_deathmatch")

		if(iFindSpawn)
		{
			entity_get_vector(iFindSpawn, EV_VEC_origin, g_fFlagBase[iFlagTeam])

			server_print("[CTF] %s flag origin not defined, set on player spawn.", g_szTeamName[iFlagTeam])
			log_error(AMX_ERR_NOTFOUND, "[CTF] %s flag origin not defined, set on player spawn.", g_szTeamName[iFlagTeam])
		}
		else
		{
			server_print("[CTF] WARNING: player spawn for ^"%s^" team does not exist !", g_szTeamName[iFlagTeam])
			log_error(AMX_ERR_NOTFOUND, "[CTF] WARNING: player spawn for ^"%s^" team does not exist !", g_szTeamName[iFlagTeam])
			set_fail_state("Player spawn unexistent!")

			return PLUGIN_CONTINUE
		}
	}
	else
		server_print("[CTF] %s flag and base spawned at: %.1f %.1f %.1f", g_szTeamName[iFlagTeam], g_fFlagBase[iFlagTeam][x], g_fFlagBase[iFlagTeam][y], g_fFlagBase[iFlagTeam][z])

	new ent
	new Float:fGameTime = get_gametime()

	// the FLAG
	ent = rg_create_entity(INFO_TARGET)

	if(!ent)
		return flag_spawn(iFlagTeam)

	entity_set_model(ent, FLAG_MODEL)
	entity_set_string(ent, EV_SZ_classname, FLAG_CLASSNAME)
	entity_set_int(ent, EV_INT_body, iFlagTeam)
	entity_set_int(ent, EV_INT_sequence, FLAG_ANI_STAND)
	entity_spawn(ent)
	entity_set_origin(ent, g_fFlagBase[iFlagTeam])
	entity_set_size(ent, FLAG_HULL_MIN, FLAG_HULL_MAX)
	entity_set_vector(ent, EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
	entity_set_vector(ent, EV_VEC_angles, FLAG_SPAWN_ANGLES)
	entity_set_edict(ent, EV_ENT_aiment, 0)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
	entity_set_float(ent, EV_FL_gravity, 2.0)
	entity_set_float(ent, EV_FL_nextthink, fGameTime + FLAG_THINK)

	g_iFlagEntity[iFlagTeam] = ent
	g_iFlagHolder[iFlagTeam] = FLAG_HOLD_BASE

	// flag BASE
	ent = rg_create_entity(INFO_TARGET)

	if(!ent)
		return flag_spawn(iFlagTeam)

	entity_set_string(ent, EV_SZ_classname, BASE_CLASSNAME)
	entity_set_model(ent, FLAG_MODEL)
	entity_set_int(ent, EV_INT_body, 0)
	entity_set_int(ent, EV_INT_sequence, FLAG_ANI_BASE)
	entity_spawn(ent)
	entity_set_origin(ent, g_fFlagBase[iFlagTeam])
	entity_set_vector(ent, EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)

	entity_set_float(ent, EV_FL_renderamt, 100.0)
	entity_set_float(ent, EV_FL_nextthink, fGameTime + BASE_THINK)

	if(iFlagTeam == TEAM_RED)
		entity_set_vector(ent, EV_VEC_rendercolor, Float:{150.0, 0.0, 0.0})
	else
		entity_set_vector(ent, EV_VEC_rendercolor, Float:{0.0, 0.0, 150.0})

	g_iBaseEntity[iFlagTeam] = ent

	return PLUGIN_CONTINUE
}

public flag_think(ent)
{
	if(!is_entity(ent))
		return

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + FLAG_THINK)

	static id
	static iStatus
	static iFlagTeam
	static iSkip[3]
	static Float:fOrigin[3]
	static Float:fPlayerOrigin[3]

	iFlagTeam = (ent == g_iFlagEntity[TEAM_BLUE] ? TEAM_BLUE : TEAM_RED)

	if(g_iFlagHolder[iFlagTeam] == FLAG_HOLD_BASE)
		fOrigin = g_fFlagBase[iFlagTeam]
	else
		entity_get_vector(ent, EV_VEC_origin, fOrigin)

	g_fFlagLocation[iFlagTeam] = fOrigin

	iStatus = 0

	if(++iSkip[iFlagTeam] >= FLAG_SKIPTHINK)
	{
		iSkip[iFlagTeam] = 0

		if(1 <= g_iFlagHolder[iFlagTeam] <= g_iMaxPlayers)
		{
			id = g_iFlagHolder[iFlagTeam]

			set_hudmessage(HUD_HELP)
			ShowSyncHudMsg(id, g_iSync[3], "%L", id, "HUD_YOUHAVEFLAG")

			iStatus = 1
		}
		else if(g_iFlagHolder[iFlagTeam] == FLAG_HOLD_DROPPED)
			iStatus = 2

		message_begin(MSG_BROADCAST, gMsg_HostagePos)
		write_byte(0)
		write_byte(iFlagTeam)
		engfunc(EngFunc_WriteCoord, fOrigin[x])
		engfunc(EngFunc_WriteCoord, fOrigin[y])
		engfunc(EngFunc_WriteCoord, fOrigin[z])
		message_end()

		message_begin(MSG_BROADCAST, gMsg_HostageK)
		write_byte(iFlagTeam)
		message_end()

		static iStuck[3]

		if(g_iFlagHolder[iFlagTeam] >= FLAG_HOLD_BASE && !(entity_get_int(ent, EV_INT_flags) & FL_ONGROUND))
		{
			if(++iStuck[iFlagTeam] > 4)
			{
				flag_autoReturn(ent)

				log_message("^"%s^" flag is outside world, auto-returned.", g_szTeamName[iFlagTeam])

				return
			}
		}
		else
			iStuck[iFlagTeam] = 0
	}

	for(id = 1; id <= g_iMaxPlayers; id++)
	{
		if(g_iTeam[id] == TEAM_NONE || g_bBot[id])
			continue

		/* Check flag proximity for pickup */
		if(g_iFlagHolder[iFlagTeam] >= FLAG_HOLD_BASE)
		{
			entity_get_vector(id, EV_VEC_origin, fPlayerOrigin)

			if(get_distance_f(fOrigin, fPlayerOrigin) <= FLAG_PICKUPDISTANCE)
				flag_touch(ent, id)
		}

		/* Send dynamic lights to players that have them enabled */
		if(g_iFlagHolder[iFlagTeam] != FLAG_HOLD_BASE && g_bLights[id])
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
			write_byte(TE_DLIGHT)
			engfunc(EngFunc_WriteCoord, fOrigin[x])
			engfunc(EngFunc_WriteCoord, fOrigin[y])
			engfunc(EngFunc_WriteCoord, fOrigin[z] + (g_iFlagHolder[iFlagTeam] == FLAG_HOLD_DROPPED ? 32 : -16))
			write_byte(FLAG_LIGHT_RANGE)
			write_byte(iFlagTeam == TEAM_RED ? 100 : 0)
			write_byte(0)
			write_byte(iFlagTeam == TEAM_BLUE ? 155 : 0)
			write_byte(FLAG_LIGHT_LIFE)
			write_byte(FLAG_LIGHT_DECAY)
			message_end()
		}

		/* If iFlagTeam's flag is stolen or dropped, constantly warn team players */
		if(iStatus && g_iTeam[id] == iFlagTeam)
		{
			set_hudmessage(HUD_HELP2)
			ShowSyncHudMsg(id, g_iSync[2], "%L", id, (iStatus == 1 ? "HUD_ENEMYHASFLAG" : "HUD_RETURNYOURFLAG"))
		}
	}
}

flag_sendHome(iFlagTeam)
{
	new ent = g_iFlagEntity[iFlagTeam]

	entity_set_edict(ent, EV_ENT_aiment, 0)
	entity_set_origin(ent, g_fFlagBase[iFlagTeam])
	entity_set_int(ent, EV_INT_sequence, FLAG_ANI_STAND)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
	entity_set_vector(ent, EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
	entity_set_vector(ent, EV_VEC_angles, FLAG_SPAWN_ANGLES)

	g_iFlagHolder[iFlagTeam] = FLAG_HOLD_BASE
}

flag_take(iFlagTeam, id)
{
	if(g_bProtected[id])
		player_removeProtection(id, "PROTECTION_TOUCHFLAG")

	new ent = g_iFlagEntity[iFlagTeam]

	entity_set_edict(ent, EV_ENT_aiment, id)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW)
	entity_set_int(ent, EV_INT_solid, SOLID_NOT)

	g_iFlagHolder[iFlagTeam] = id

	player_updateSpeed(id)
}

public flag_touch(ent, id)
{
#if FLAG_IGNORE_BOTS == true

	if(!g_bAlive[id] || g_bBot[id])
		return

#else // FLAG_IGNORE_BOTS

	if(!g_bAlive[id])
		return

#endif // FLAG_IGNORE_BOTS

	new iFlagTeam = (g_iFlagEntity[TEAM_BLUE] == ent ? TEAM_BLUE : TEAM_RED)

	if(1 <= g_iFlagHolder[iFlagTeam] <= g_iMaxPlayers) // if flag is carried we don't care
		return

	new Float:fGameTime = get_gametime()

	if(g_fLastDrop[id] > fGameTime)
		return

	new iTeam = g_iTeam[id]

	if(!(TEAM_RED <= g_iTeam[id] <= TEAM_BLUE))
		return

	new iFlagTeamOp = get_opTeam(iFlagTeam)
	new szName[32]

	get_entvar(id, var_netname, szName, charsmax(szName));

	if(iTeam == iFlagTeam) // If the PLAYER is on the same team as the FLAG
	{
		if(g_iFlagHolder[iFlagTeam] == FLAG_HOLD_DROPPED) // if the team's flag is dropped, return it to base
		{
			flag_sendHome(iFlagTeam)

			task_remove(ent)

			player_award(id, REWARD_RETURN, "%L", id, "REWARD_RETURN")

			ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_RETURNED, id, iFlagTeam, false)

			new iAssists = 0

			for(new i = 1; i <= g_iMaxPlayers; i++)
			{
				if(i != id && g_bAssisted[i][iFlagTeam] && g_iTeam[i] == iFlagTeam)
				{
					player_award(i, REWARD_RETURN_ASSIST, "%L", i, "REWARD_RETURN_ASSIST")

					ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_RETURNED, i, iFlagTeam, true)

					iAssists++
				}

				g_bAssisted[i][iFlagTeam] = false
			}

			if(1 <= g_iFlagHolder[iFlagTeamOp] <= g_iMaxPlayers)
				g_bAssisted[id][iFlagTeamOp] = true

			if(iAssists)
			{
				new szFormat[64]

				format(szFormat, charsmax(szFormat), "%s + %d assists", szName, iAssists)

				game_announce(EVENT_RETURNED, iFlagTeam, szFormat)
			}
			else
				game_announce(EVENT_RETURNED, iFlagTeam, szName)

			log_message("<%s>%s returned the ^"%s^" flag.", g_szTeamName[iTeam], szName, g_szTeamName[iFlagTeam])

			set_hudmessage(HUD_HELP)
			ShowSyncHudMsg(id, g_iSync[3], "%L", id, "HUD_RETURNEDFLAG")

			if(g_bProtected[id])
				player_removeProtection(id, "PROTECTION_TOUCHFLAG")
		}
		else if(g_iFlagHolder[iFlagTeam] == FLAG_HOLD_BASE && g_iFlagHolder[iFlagTeamOp] == id) // if the PLAYER has the ENEMY FLAG and the FLAG is in the BASE make SCORE
		{
			player_award(id, REWARD_CAPTURE, "%L", id, "REWARD_CAPTURE")

			ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_CAPTURED, id, iFlagTeamOp, false)

			new iAssists = 0

			for(new i = 1; i <= g_iMaxPlayers; i++)
			{
				if(i != id && g_iTeam[i] > 0 && g_iTeam[i] == iTeam)
				{
					if(g_bAssisted[i][iFlagTeamOp])
					{
						player_award(i, REWARD_CAPTURE_ASSIST, "%L", i, "REWARD_CAPTURE_ASSIST")

						ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_CAPTURED, i, iFlagTeamOp, true)

						iAssists++
					}
					else
						player_award(i, REWARD_CAPTURE_TEAM, "%L", i, "REWARD_CAPTURE_TEAM")
				}

				g_bAssisted[i][iFlagTeamOp] = false
			}

			set_hudmessage(HUD_HELP)
			ShowSyncHudMsg(id, g_iSync[3], "%L", id, "HUD_CAPTUREDFLAG")

			if(iAssists)
			{
				new szFormat[64]

				format(szFormat, charsmax(szFormat), "%s + %d assists", szName, iAssists)

				game_announce(EVENT_SCORE, iFlagTeam, szFormat)
			}
			else
				game_announce(EVENT_SCORE, iFlagTeam, szName)

			log_message("<%s>%s captured the ^"%s^" flag. (%d assists)", g_szTeamName[iTeam], szName, g_szTeamName[iFlagTeamOp], iAssists)

			emessage_begin(MSG_BROADCAST, gMsg_TeamScore)
			ewrite_string(g_szCSTeams[iFlagTeam])
			ewrite_short(++g_iScore[iFlagTeam])
			emessage_end()

			flag_sendHome(iFlagTeamOp)

			player_updateSpeed(id)

			g_fLastDrop[id] = fGameTime + 3.0

			if(g_bProtected[id])
				player_removeProtection(id, "PROTECTION_TOUCHFLAG")

			if(0 < get_pcvar_num(pCvar_mp_winlimit) <= g_iScore[iFlagTeam])
			{
				emessage_begin(MSG_ALL, SVC_INTERMISSION) // hookable mapend
				emessage_end()

				return
			}
//reapi
			new iFlagRoundEnd = get_pcvar_num(pCvar_ctf_flagendround)

			if (iFlagRoundEnd)
			{
				if (iFlagTeam == TEAM_RED) {
					rg_round_end(3.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN);
				}
				else if (iFlagTeam == TEAM_BLUE) {
					rg_round_end(3.0, WINSTATUS_CTS, ROUND_CTS_WIN);
				}
			
				rg_update_teamscores(g_iScore[TEAM_BLUE], g_iScore[TEAM_RED], false);
			}
//end reapi
		}
	}
	else
	{
		if(g_iFlagHolder[iFlagTeam] == FLAG_HOLD_BASE)
		{
			player_award(id, REWARD_STEAL, "%L", id, "REWARD_STEAL")

			ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_STOLEN, id, iFlagTeam, false)

			log_message("<%s>%s stole the ^"%s^" flag.", g_szTeamName[iTeam], szName, g_szTeamName[iFlagTeam])
		}
		else
		{
			player_award(id, REWARD_PICKUP, "%L", id, "REWARD_PICKUP")

			ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_PICKED, id, iFlagTeam, false)

			log_message("<%s>%s picked up the ^"%s^" flag.", g_szTeamName[iTeam], szName, g_szTeamName[iFlagTeam])
		}

		set_hudmessage(HUD_HELP)
		ShowSyncHudMsg(id, g_iSync[3], "%L", id, "HUD_YOUHAVEFLAG")

		flag_take(iFlagTeam, id)

		g_bAssisted[id][iFlagTeam] = true

		task_remove(ent)

		if(g_bProtected[id])
			player_removeProtection(id, "PROTECTION_TOUCHFLAG")
	
		game_announce(EVENT_TAKEN, iFlagTeam, szName)
	}
}

public flag_autoReturn(ent)
{
	task_remove(ent)

	new iFlagTeam = (g_iFlagEntity[TEAM_BLUE] == ent ? TEAM_BLUE : (g_iFlagEntity[TEAM_RED] == ent ? TEAM_RED : 0))

	if(!iFlagTeam)
		return

	flag_sendHome(iFlagTeam)

	ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_AUTORETURN, 0, iFlagTeam, false)

	game_announce(EVENT_RETURNED, iFlagTeam, NULL)

	log_message("^"%s^" flag returned automatically", g_szTeamName[iFlagTeam])
}

public base_think(ent)
{
	if(!is_entity(ent))
		return

	if(!get_pcvar_num(pCvar_ctf_flagheal))
	{
		entity_set_float(ent, EV_FL_nextthink, get_gametime() + 10.0) /* recheck each 10s seconds */

		return
	}

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + BASE_THINK)

	new iFlagTeam = (g_iBaseEntity[TEAM_BLUE] == ent ? TEAM_BLUE : TEAM_RED)

	if(g_iFlagHolder[iFlagTeam] != FLAG_HOLD_BASE)
		return

	static id
	id = -1

	while((id = find_ent_in_sphere(id, g_fFlagBase[iFlagTeam], BASE_HEAL_DISTANCE)) != 0)
	{
		if(1 <= id <= g_iMaxPlayers && g_bAlive[id] && g_iTeam[id] == iFlagTeam)
		{
			new Float:iHealth = get_entvar(id,var_health)
			if(iHealth < g_iMaxHealth[id])
			{
				set_entvar(id,var_health,iHealth+1.0)
				player_healingEffect(id)
			}
		}

		if(id >= g_iMaxPlayers)
			break
	}
}

public client_putinserver(id)
{
	g_bBot[id] = (is_user_bot(id) ? true : false)

	g_iTeam[id] = TEAM_SPEC
	g_bFirstSpawn[id] = true
	g_bRestarted[id] = false
	g_bLights[id] = false
}

public client_disconnected(id)
{
	player_dropFlag(id)
	task_remove(id)

	g_iTeam[id] = TEAM_NONE
	g_iAdrenaline[id] = 0
	g_iAdrenalineUse[id] = 0

	g_bAlive[id] = false
	g_bLights[id] = false
	g_bAssisted[id][TEAM_RED] = false
	g_bAssisted[id][TEAM_BLUE] = false
}

public player_joinTeam()
{
	new id = read_data(1)
	
	if(g_bAlive[id])
		return

	new szTeam[2]

	read_data(2, szTeam, charsmax(szTeam))

	switch(szTeam[0])
	{
		case 'T':
		{
			if(g_iTeam[id] == TEAM_RED && g_bFirstSpawn[id])
			{
				new iRespawn = get_pcvar_num(pCvar_ctf_respawntime)
				if(iRespawn > RESPAWNMAXTIMECHECK) iRespawn = RESPAWNMAXTIMECHECK
				if(iRespawn > 0) player_respawn(id - TASK_RESPAWN, iRespawn + 1)
#if FEATURE_TEAMBALANCE == true
				task_remove(id - TASK_TEAMBALANCE)
				task_set(1.0, "player_checkTeam", id - TASK_TEAMBALANCE)
#endif
			}

			g_iTeam[id] = TEAM_RED
		}

		case 'C':
		{
			if(g_iTeam[id] == TEAM_BLUE && g_bFirstSpawn[id])
			{
				new iRespawn = get_pcvar_num(pCvar_ctf_respawntime)
				if(iRespawn > RESPAWNMAXTIMECHECK) iRespawn = RESPAWNMAXTIMECHECK
				if(iRespawn > 0)
					player_respawn(id - TASK_RESPAWN, iRespawn + 1)

#if FEATURE_TEAMBALANCE == true
				task_remove(id - TASK_TEAMBALANCE)
				task_set(1.0, "player_checkTeam", id - TASK_TEAMBALANCE)
#endif
			}

			g_iTeam[id] = TEAM_BLUE
		}

		case 'U':
		{
			g_iTeam[id] = TEAM_NONE
			g_bFirstSpawn[id] = true
		}

		default:
		{
			player_allowChangeTeam(id)
			g_iTeam[id] = TEAM_SPEC
			g_bFirstSpawn[id] = true
		}
	}
}

public player_spawn(id)
{
	if(!is_user_alive(id) || (!g_bRestarted[id] && g_bAlive[id]))
		return

	/* make sure we have team right */
	switch(get_member(id, m_iTeam))
	{
		case CS_TEAM_T: g_iTeam[id] = TEAM_RED
		case CS_TEAM_CT: g_iTeam[id] = TEAM_BLUE
		default: return
	}

	g_bAlive[id] = true
	g_bDefuse[id] = false
	g_bBuyZone[id] = true
	//g_bFreeLook[id] = false
	g_fLastBuy[id] = Float:{0.0, 0.0, 0.0, 0.0}

	task_remove(id - TASK_PROTECTION)
	task_remove(id - TASK_EQUIPAMENT)
	task_remove(id - TASK_DAMAGEPROTECTION)
#if FEATURE_TEAMBALANCE == true
	task_remove(id - TASK_TEAMBALANCE)
#endif
	task_remove(id - TASK_ADRENALINE)
	task_remove(id - TASK_DEFUSE)

#if FEATURE_BUY == true

	task_set(0.1, "player_spawnEquipament", id - TASK_EQUIPAMENT)

#endif // FEATURE_BUY

	task_set(0.2, "player_checkVitals", id - TASK_CHECKHP)

	new iProtection = get_pcvar_num(pCvar_ctf_protection)

	if(iProtection > 0)
		player_protection(id - TASK_PROTECTION, iProtection)

	if(g_bFirstSpawn[id] || g_bRestarted[id])
	{
		g_bRestarted[id] = false
		g_bFirstSpawn[id] = false

		rg_add_account(id,get_pcvar_num(pCvar_mp_startmoney))
	}
	else if(g_bSuicide[id])
	{
		g_bSuicide[id] = false
		player_print(id, "%L", id, "SPAWN_NOMONEY")
	}
	else
		rg_add_account(id,get_pcvar_num(pCvar_ctf_spawnmoney))
}

public player_checkVitals(id)
{
	id += TASK_CHECKHP

	if(!g_bAlive[id])
		return

	/* in case player is VIP or whatever special class that sets armor */
	new Float:iArmor = Float:get_entvar(id,var_armorvalue)

	g_iMaxArmor[id] = (iArmor > 0.0 ? iArmor : 100.0)
	g_iMaxHealth[id] = get_entvar(id,var_health)
}

#if FEATURE_BUY == true

public player_spawnEquipament(id)
{
	id += TASK_EQUIPAMENT

	if(!g_bAlive[id])
		return

	rg_remove_all_items(id, false);
	rg_give_item(id, g_szWeaponEntity[W_KNIFE], GT_REPLACE);
		
	new RandomNum;RandomNum = random_num(1,2)
	
	if(RandomNum == 1)
	{
		rg_give_item(id, "weapon_ak47", GT_REPLACE)
		rg_set_user_bpammo(id, WEAPON_AK47, 90)
	}
	else if(RandomNum == 2)
	{
		rg_give_item(id, "weapon_m4a1", GT_REPLACE)
		rg_set_user_bpammo(id, WEAPON_M4A1, 90)
	}
	
	rg_give_item(id, "weapon_deagle", GT_REPLACE)
	rg_set_user_bpammo(id, WEAPON_DEAGLE, 35)
}

#endif // FEATURE_BUY

public player_protection(id, iStart)
{
	id += TASK_PROTECTION

	if(!(TEAM_RED <= g_iTeam[id] <= TEAM_BLUE))
		return

	static iCount[33]

	if(iStart)
	{
		iCount[id] = iStart + 1
		g_bProtected[id] = true
	}

	if(--iCount[id] > 0)
	{
		set_hudmessage(HUD_SPAWN)
		ShowSyncHudMsg(id, g_iSync[0], "%L", id, "PROTECTION_LEFT", iCount[id])

		task_set(1.0, "player_protection", id - TASK_PROTECTION)
	}
	else
		player_removeProtection(id, "PROTECTION_EXPIRED")
}

public player_removeProtection(id, szLang[])
{
	if(!(TEAM_RED <= g_iTeam[id] <= TEAM_BLUE))
		return

	g_bProtected[id] = false

	task_remove(id - TASK_PROTECTION)
	task_remove(id - TASK_DAMAGEPROTECTION)

	set_hudmessage(HUD_SPAWN)
	ShowSyncHudMsg(id, g_iSync[0], "%L", id, szLang)
}

public player_currentWeapon(id)
{
	if(!g_bAlive[id])
		return

	static bool:bZoom[33]

	new iZoom = read_data(1)

	if(1 < iZoom <= 90)  /* setFOV event */
		bZoom[id] = bool:(iZoom <= 40)

	else  /* CurWeapon event */
	{
		if(!bZoom[id]) /*if not zooming, get weapon speed */
			g_fWeaponSpeed[id] = g_fWeaponRunSpeed[read_data(2)]

		else  /*if zooming, set zoom speed */
			g_fWeaponSpeed[id] = g_fWeaponRunSpeed[0]

		player_updateSpeed(id)
	}
}

public client_PostThink(id)
{
	if(!g_bAlive[id])
		return

	if(get_member(id,m_bOwnsShield))
	{
		if(get_member(id,m_bShieldDrawn))
		{
			g_fWeaponSpeed[id] = 180.0
			player_updateSpeed(id)
		}
		else
		{
			g_fWeaponSpeed[id] = 250.0
			player_updateSpeed(id)
		}
	}
}

public player_useWeapon(ent)
{
	if(!is_entity(ent))
		return

	static id

	id = entity_get_edict(ent, EV_ENT_owner)

	if(1 <= id <= g_iMaxPlayers && g_bAlive[id])
	{
		if(g_bProtected[id])
			player_removeProtection(id, "PROTECTION_WEAPONUSE")
	}
}

//reapi
public player_damage(id, iWeapon, iAttacker, Float:fDamage, iType)
{
	if(g_bProtected[id])
	{
		//task_remove(id - TASK_DAMAGEPROTECTION)
		//task_set(0.1, "player_damageProtection", id - TASK_DAMAGEPROTECTION)

		entity_set_vector(id, EV_VEC_punchangle, FLAG_SPAWN_ANGLES)
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE
	}

	return HC_CONTINUE
}

public player_damageProtection(id)
{
	id += TASK_DAMAGEPROTECTION
}

public player_killed(id, killer)
{
	g_bAlive[id] = false
	g_bBuyZone[id] = false

	task_remove(id - TASK_RESPAWN)
	task_remove(id - TASK_PROTECTION)
	task_remove(id - TASK_EQUIPAMENT)
	task_remove(id - TASK_DAMAGEPROTECTION)
#if FEATURE_TEAMBALANCE == true
	task_remove(id - TASK_TEAMBALANCE)
#endif
	task_remove(id - TASK_ADRENALINE)
	task_remove(id - TASK_DEFUSE)

	if(id == killer || !(1 <= killer <= g_iMaxPlayers))
	{
		g_bSuicide[id] = true

		player_award(id, PENALTY_SUICIDE, "%L", id, "PENALTY_SUICIDE")
	}
	else if(1 <= killer <= g_iMaxPlayers)
	{
		if(g_iTeam[id] == g_iTeam[killer])
		{
			player_award(killer, PENALTY_TEAMKILL, "%L", killer, "PENALTY_TEAMKILL")
		}
		else
		{
			if(id == g_iFlagHolder[g_iTeam[killer]])
			{
				g_bAssisted[killer][g_iTeam[killer]] = true

				player_award(killer, REWARD_KILLCARRIER, "%L", killer, "REWARD_KILLCARRIER")

			}
		}
	}

	new iRespawn = get_pcvar_num(pCvar_ctf_respawntime)
	if(iRespawn > RESPAWNMAXTIMECHECK) iRespawn = RESPAWNMAXTIMECHECK
	if(iRespawn > 0)
		player_respawn(id - TASK_RESPAWN, iRespawn)

	player_dropFlag(id)
	player_allowChangeTeam(id)
#if FEATURE_TEAMBALANCE == true
	task_set(1.0, "player_checkTeam", id - TASK_TEAMBALANCE)
#endif
}

#if FEATURE_TEAMBALANCE == true
public player_checkTeam(id)
{
	id += TASK_TEAMBALANCE

	if(!(TEAM_RED <= g_iTeam[id] <= TEAM_BLUE) || g_bAlive[id] || !get_pcvar_num(pCvar_mp_autoteambalance))
		return

	new iPlayers[3]
	new iTeam = g_iTeam[id]
	new iOpTeam = get_opTeam(iTeam)

	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(TEAM_RED <= g_iTeam[i] <= TEAM_BLUE)
			iPlayers[g_iTeam[i]]++
	}

	if((iPlayers[iTeam] > 1 && !iPlayers[iOpTeam]) || iPlayers[iTeam] > (iPlayers[iOpTeam] + 1))
	{
		player_allowChangeTeam(id)

		engclient_cmd(id, "jointeam", (iOpTeam == TEAM_BLUE ? "2" : "1"))

		set_task(1.0, "player_forceJoinClass", id)
		player_print(id, "Fuiste transferiodo al Equipo:^4 %L^1, debido a un Auto Balance de Equipos.", id, g_szMLTeamName[iOpTeam])
	}
}

public player_forceJoinClass(id)
{
	engclient_cmd(id, "joinclass", "5")
}

#endif

public player_respawn(id, iStart)
{
	id += TASK_RESPAWN

	if(!(TEAM_RED <= g_iTeam[id] <= TEAM_BLUE) || g_bAlive[id])
		return

	static iCount[33]
	/*, iUserFlags;
	iUserFlags = get_user_flags( id );*/

	if(iStart)
		iCount[id] = iStart + 1
	if(iCount[id] > RESPAWNMAXTIMECHECK) iCount[id] = RESPAWNMAXTIMECHECK

	set_hudmessage(HUD_SPAWN)

	if(--iCount[id] > 0)
	{
		ShowSyncHudMsg(id, g_iSync[0], "%L", id, "RESPAWNING_IN", iCount[id])
		task_set(1.0, "player_respawn", id - TASK_RESPAWN)
	}
	else
	{
		ShowSyncHudMsg(id, g_iSync[0], "%L", id, "RESPAWNING")
		
		entity_set_int(id, EV_INT_deadflag, DEAD_RESPAWNABLE)
		entity_set_int(id, EV_INT_iuser1, 0)
		entity_think(id)
		entity_spawn(id)
		set_entvar(id,var_health,100.0)
		set_pev(id, pev_armorvalue, 100.0) 
		
		/*
		if( iUserFlags & ADMIN_RCON ) 	 	 // PROPIETARIO.
		{
			set_entvar(id,var_health,350.0)
			set_pev(id, pev_armorvalue, 350.0) 
		}
		else
		{
			
		}
		
		else if( iUserFlags & ADMIN_LEVEL_X ) 	 // ADMIN: DUEÑO.
		{
			set_entvar(id,var_health,320.0)
		}
		
		else if( iUserFlags & ADMIN_LEVEL_W ) 	 // ADMIN: SOCIO GLOBAL
		{
			set_entvar(id,var_health,300.0)
		}
		else if( iUserFlags & ADMIN_RESERVATION ) // ADMIN: SUB-DUEÑO
		{
			set_entvar(id,var_health,280.0)
		}
		else if( iUserFlags & ADMIN_LEVEL_H ) 	// ADMIN: SOCIO
		{
			set_entvar(id,var_health,250.0)
		}
		else if( iUserFlags & ADMIN_LEVEL_H ) 	// ADMIN: QUEEN
		{
			set_entvar(id,var_health,200.0)
		}
		else if( iUserFlags & ADMIN_LEVEL_H ) 	// ADMIN: STAFF
		{
			set_entvar(id,var_health,200.0)
		}
		else if( iUserFlags & ADMIN_LEVEL_H ) 	// ADMIN: SEXY GIRL
		{
			set_entvar(id,var_health,200.0)
		}
		else if( iUserFlags & ADMIN_VOTE ) 	// PREMIUM
		{
			set_entvar(id,var_health,200.0)
		}
		else if( iUserFlags & ADMIN_PASSWORD ) 	// MEMBER
		{
			set_entvar(id,var_health,200.0)
			
		}
		else
		{}*/
		
	}
}

public player_cmd_dropFlag(id)
{
	if(!g_bAlive[id] || id != g_iFlagHolder[get_opTeam(g_iTeam[id])])
		player_print(id, "%L", id, "DROPFLAG_NOFLAG")

	else
	{
		new iOpTeam = get_opTeam(g_iTeam[id])

		player_dropFlag(id)
		player_award(id, PENALTY_DROP, "%L", id, "PENALTY_MANUALDROP")

		ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_MANUALDROP, id, iOpTeam, false)

		g_bAssisted[id][iOpTeam] = false
	}

	return PLUGIN_HANDLED
}

public player_dropFlag(id)
{
	new iOpTeam = get_opTeam(g_iTeam[id])

	if(id != g_iFlagHolder[iOpTeam])
		return

	new ent = g_iFlagEntity[iOpTeam]

	if(!is_entity(ent))
		return

	g_fLastDrop[id] = get_gametime() + 2.0
	g_iFlagHolder[iOpTeam] = FLAG_HOLD_DROPPED

	entity_set_edict(ent, EV_ENT_aiment, 0)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
	entity_set_int(ent, EV_INT_sequence, FLAG_ANI_DROPPED)
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
	entity_set_origin(ent, g_fFlagLocation[iOpTeam])

	new Float:fReturn = get_pcvar_float(pCvar_ctf_flagreturn)

	if(fReturn > 0)
		task_set(fReturn, "flag_autoReturn", ent)

	if(g_bAlive[id])
	{
		new Float:fVelocity[3]

		velocity_by_aim(id, 200, fVelocity)

		fVelocity[z] = 0.0

		entity_set_vector(ent, EV_VEC_velocity, fVelocity)

		player_updateSpeed(id)
	}
	else
		entity_set_vector(ent, EV_VEC_velocity, FLAG_DROP_VELOCITY)

	new szName[32]

	get_entvar(id, var_netname, szName, charsmax(szName));

	game_announce(EVENT_DROPPED, iOpTeam, szName)

	ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_DROPPED, id, iOpTeam, false)

	g_fFlagDropped[iOpTeam] = get_gametime()

	log_message("<%s>%s dropped the ^"%s^" flag.", g_szTeamName[g_iTeam[id]], szName, g_szTeamName[iOpTeam])
}

public admin_cmd_moveFlag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new szTeam[2]

	read_argv(1, szTeam, charsmax(szTeam))

	new iTeam = str_to_num(szTeam)

	if(!(TEAM_RED <= iTeam <= TEAM_BLUE))
	{
		switch(szTeam[0])
		{
			case 'r', 'R': iTeam = 1
			case 'b', 'B': iTeam = 2
		}
	}

	if(!(TEAM_RED <= iTeam <= TEAM_BLUE))
		return PLUGIN_HANDLED

	entity_get_vector(id, EV_VEC_origin, g_fFlagBase[iTeam])

	entity_set_origin(g_iBaseEntity[iTeam], g_fFlagBase[iTeam])
	entity_set_vector(g_iBaseEntity[iTeam], EV_VEC_velocity, FLAG_SPAWN_VELOCITY)

	if(g_iFlagHolder[iTeam] == FLAG_HOLD_BASE)
	{
		entity_set_origin(g_iFlagEntity[iTeam], g_fFlagBase[iTeam])
		entity_set_vector(g_iFlagEntity[iTeam], EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
	}

	new szName[32]
	new szSteam[48]

	get_entvar(id, var_netname, szName, charsmax(szName));
	get_user_authid(id, szSteam, charsmax(szSteam))

	log_amx("Admin %s<%s><%s> moved %s flag to %.2f %.2f %.2f", szName, szSteam, g_szTeamName[g_iTeam[id]], g_szTeamName[iTeam], g_fFlagBase[iTeam][0], g_fFlagBase[iTeam][1], g_fFlagBase[iTeam][2])

	show_activity_key("ADMIN_MOVEBASE_1", "ADMIN_MOVEBASE_2", szName, LANG_PLAYER, g_szMLFlagTeam[iTeam])

	client_print(id, print_console, "%s%L", CONSOLE_PREFIX, id, "ADMIN_MOVEBASE_MOVED", id, g_szMLFlagTeam[iTeam])

	return PLUGIN_HANDLED
}

public admin_cmd_saveFlags(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new iOrigin[3][3]
	new szFile[96]
	new szBuffer[1024]

	FVecIVec(g_fFlagBase[TEAM_RED], iOrigin[TEAM_RED])
	FVecIVec(g_fFlagBase[TEAM_BLUE], iOrigin[TEAM_BLUE])

	formatex(szBuffer, charsmax(szBuffer), "%d %d %d^n%d %d %d", iOrigin[TEAM_RED][x], iOrigin[TEAM_RED][y], iOrigin[TEAM_RED][z], iOrigin[TEAM_BLUE][x], iOrigin[TEAM_BLUE][y], iOrigin[TEAM_BLUE][z])
	formatex(szFile, charsmax(szFile), FLAG_SAVELOCATION, g_szMap)

	if(file_exists(szFile))
		delete_file(szFile)

	write_file(szFile, szBuffer)

	new szName[32]
	new szSteam[48]

	get_entvar(id, var_netname, szName, charsmax(szName));
	get_user_authid(id, szSteam, charsmax(szSteam))

	log_amx("Admin %s<%s><%s> saved flag positions.", szName, szSteam, g_szTeamName[g_iTeam[id]])

	client_print(id, print_console, "%s%L %s", CONSOLE_PREFIX, id, "ADMIN_MOVEBASE_SAVED", szFile)

	return PLUGIN_HANDLED
}

public admin_cmd_returnFlag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new szTeam[2]

	read_argv(1, szTeam, charsmax(szTeam))

	new iTeam = str_to_num(szTeam)

	if(!(TEAM_RED <= iTeam <= TEAM_BLUE))
	{
		switch(szTeam[0])
		{
			case 'r', 'R': iTeam = 1
			case 'b', 'B': iTeam = 2
		}
	}

	if(!(TEAM_RED <= iTeam <= TEAM_BLUE))
		return PLUGIN_HANDLED

	if(g_iFlagHolder[iTeam] == FLAG_HOLD_DROPPED)
	{
		if(g_fFlagDropped[iTeam] < (get_gametime() - ADMIN_RETURNWAIT))
		{
			new szName[32]
			new szSteam[48]

			new Float:fFlagOrigin[3]

			entity_get_vector(g_iFlagEntity[iTeam], EV_VEC_origin, fFlagOrigin)

			flag_sendHome(iTeam)

			ExecuteForward(g_iFW_flag, g_iForwardReturn, FLAG_ADMINRETURN, id, iTeam, false)

			game_announce(EVENT_RETURNED, iTeam, NULL)

			get_entvar(id, var_netname, szName, charsmax(szName));
			get_user_authid(id, szSteam, charsmax(szSteam))

			log_message("^"%s^" flag returned by admin %s<%s><%s>", g_szTeamName[iTeam], szName, szSteam, g_szTeamName[g_iTeam[id]])
			log_amx("Admin %s<%s><%s> returned %s flag from %.2f %.2f %.2f", szName, szSteam, g_szTeamName[g_iTeam[id]], g_szTeamName[iTeam], fFlagOrigin[0], fFlagOrigin[1], fFlagOrigin[2])

			show_activity_key("ADMIN_RETURN_1", "ADMIN_RETURN_2", szName, LANG_PLAYER, g_szMLFlagTeam[iTeam])

			client_print(id, print_console, "%s%L", CONSOLE_PREFIX, id, "ADMIN_RETURN_DONE", id, g_szMLFlagTeam[iTeam])
		}
		else
			client_print(id, print_console, "%s%L", CONSOLE_PREFIX, id, "ADMIN_RETURN_WAIT", id, g_szMLFlagTeam[iTeam], ADMIN_RETURNWAIT)
	}
	else
		client_print(id, print_console, "%s%L", CONSOLE_PREFIX, id, "ADMIN_RETURN_NOTDROPPED", id, g_szMLFlagTeam[iTeam])

	return PLUGIN_HANDLED
}


#if FEATURE_BUY == true

public player_inBuyZone(id)
{
	if(!g_bAlive[id])
		return

	g_bBuyZone[id] = (read_data(1) ? true : false)

	if(!g_bBuyZone[id])
		set_pdata_int(id, 205, 0) // no "close menu upon exit buyzone" thing
}

public player_cmd_setAutobuy(id)
{
	new iIndex
	new szWeapon[24]
	new szArgs[1024]

	read_args(szArgs, charsmax(szArgs))
	remove_quotes(szArgs)
	trim(szArgs)

	while(contain(szArgs, WHITESPACE) != -1)
	{
		argbreak(szArgs, szWeapon, charsmax(szWeapon), szArgs, charsmax(szArgs))

		for(new bool:bFound, w = W_P228; w <= W_NVG; w++)
		{
			if(!bFound)
			{
				for(new i = 0; i < 2; i++)
				{
					if(!bFound && equali(g_szWeaponCommands[w][i], szWeapon))
					{
						bFound = true

						g_iAutobuy[id][iIndex++] = w
					}
				}
			}
		}
	}

	player_cmd_autobuy(id)

	return PLUGIN_HANDLED
}

public player_cmd_autobuy(id)
{
	if(!g_bAlive[id])
		return PLUGIN_HANDLED

	if(!g_bBuyZone[id])
	{
		client_print(id, print_center, "%L", id, "BUY_NOTINZONE")
		return PLUGIN_HANDLED
	}

	new iMoney = get_member(id,m_iAccount)

	for(new bool:bBought[6], iWeapon, i = 0; i < sizeof g_iAutobuy[]; i++)
	{
		if(!g_iAutobuy[id][i])
			return PLUGIN_HANDLED

		iWeapon = g_iAutobuy[id][i]

		if(bBought[g_iWeaponSlot[iWeapon]])
			continue

#if FEATURE_ADRENALINE == true

		if((g_iWeaponPrice[iWeapon] > 0 && g_iWeaponPrice[iWeapon] > iMoney) || (g_iWeaponAdrenaline[iWeapon] > 0 && g_iWeaponAdrenaline[iWeapon] > g_iAdrenaline[id]))
			continue

#else // FEATURE_ADRENALINE

		if(g_iWeaponPrice[iWeapon] > 0 && g_iWeaponPrice[iWeapon] > iMoney)
			continue

#endif // FEATURE_ADRENALINE

		player_buyWeapon(id, iWeapon)
		bBought[g_iWeaponSlot[iWeapon]] = true
	}

	return PLUGIN_HANDLED
}

public player_cmd_setRebuy(id)
{
	new iIndex
	new szType[18]
	new szArgs[256]

	read_args(szArgs, charsmax(szArgs))
	replace_all(szArgs, charsmax(szArgs), "^"", NULL)
	trim(szArgs)

	while(contain(szArgs, WHITESPACE) != -1)
	{
		split(szArgs, szType, charsmax(szType), szArgs, charsmax(szArgs), WHITESPACE)

		for(new i = 1; i < sizeof g_szRebuyCommands; i++)
		{
			if(equali(szType, g_szRebuyCommands[i]))
				g_iRebuy[id][++iIndex] = i
		}
	}

	player_cmd_rebuy(id)

	return PLUGIN_HANDLED
}

public player_cmd_rebuy(id)
{
	if(!g_bAlive[id])
		return PLUGIN_HANDLED

	if(!g_bBuyZone[id])
	{
		client_print(id, print_center, "%L", id, "BUY_NOTINZONE")
		return PLUGIN_HANDLED
	}

	new iBought

	for(new iType, iBuy, i = 1; i < sizeof g_iRebuy[]; i++)
	{
		iType = g_iRebuy[id][i]

		if(!iType)
			continue

		iBuy = g_iRebuyWeapons[id][iType]

		if(!iBuy)
			continue

		switch(iType)
		{
			case primary, secondary: player_buyWeapon(id, iBuy)

			case armor: player_buyWeapon(id, (iBuy == 2 ? W_VESTHELM : W_VEST))

			case he: player_buyWeapon(id, W_HEGRENADE)

			case flash:
			{
				player_buyWeapon(id, W_FLASHBANG)

				if(iBuy == 2)
					player_buyWeapon(id, W_FLASHBANG)
			}

			case smoke: player_buyWeapon(id, W_SMOKEGRENADE)

			case nvg: player_buyWeapon(id, W_NVG)
		}

		iBought++

		if(iType == flash && iBuy == 2)
			iBought++
	}

	if(iBought)
		client_print(id, print_center, "%L", id, "BUY_REBOUGHT", iBought)

	return PLUGIN_HANDLED
}

public player_addRebuy(id, iWeapon)
{
	if(!g_bAlive[id])
		return

	switch(g_iWeaponSlot[iWeapon])
	{
		case 1: g_iRebuyWeapons[id][primary] = iWeapon
		case 2: g_iRebuyWeapons[id][secondary] = iWeapon

		default:
		{
			switch(iWeapon)
			{
				case W_VEST: g_iRebuyWeapons[id][armor] = (g_iRebuyWeapons[id][armor] == 2 ? 2 : 1)
				case W_VESTHELM: g_iRebuyWeapons[id][armor] = 2
				case W_FLASHBANG: g_iRebuyWeapons[id][flash] = clamp(g_iRebuyWeapons[id][flash] + 1, 0, 2)
				case W_HEGRENADE: g_iRebuyWeapons[id][he] = 1
				case W_SMOKEGRENADE: g_iRebuyWeapons[id][smoke] = 1
				case W_NVG: g_iRebuyWeapons[id][nvg] = 1
			}
		}
	}
}

public player_cmd_buy_main(id)
	return player_menu_buy(id, 0)

public player_cmd_buy_equipament(id)
	return player_menu_buy(id, 8)

public player_cmd_buyVGUI(id)
{
	message_begin(MSG_ONE, gMsg_BuyClose, _, id)
	message_end()

	return player_menu_buy(id, 0)
}

public player_menu_buy(id, iMenu)
{
	if(!g_bAlive[id])
		return PLUGIN_HANDLED

	if(!g_bBuyZone[id])
	{
		client_print(id, print_center, "%L", id, "BUY_NOTINZONE")
		return PLUGIN_HANDLED
	}

	static szMenu[1024]
	new iMoney = get_member(id,m_iAccount)

	switch(iMenu)
	{
		case 1:
		{
			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\r Categoria:\w Pistolas. \d]**^n^n\d1. \%sGlock 18\R$%d^n\d2. \%sUSP\R$%d^n\d3. \%sP228\R$%d^n\d4. \%sDesert Eagle\R$%d^n\d5. \%sFiveseven\R$%d^n\d6. \%sDual Elites\R$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_GLOCK18] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_GLOCK18],
				(iMoney >= g_iWeaponPrice[W_USP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_USP],
				(iMoney >= g_iWeaponPrice[W_P228] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_P228],
				(iMoney >= g_iWeaponPrice[W_DEAGLE] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_DEAGLE],
				(iMoney >= g_iWeaponPrice[W_FIVESEVEN] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_FIVESEVEN],
				(iMoney >= g_iWeaponPrice[W_ELITE] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_ELITE],
				id, "EXIT")
		}

		case 2:
		{
			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\r Categoria:\w Escopetas. \d]**^n^n\d1. \%sM3 Super90\R$%d^n\d2. \%sXM1014\R$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_M3] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_M3],
				(iMoney >= g_iWeaponPrice[W_XM1014] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_XM1014],
				id, "EXIT")
		}

		case 3:
		{
			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\r Categoria:\w Semi-Automaticas. \d]**^n^n\d1. \%sTMP\R$%d^n\d2. \%sMac-10\R$%d^n\d3. \%sMP5 Navy\R$%d^n\d4. \%sUMP-45\R$%d^n\d5. \%sP90\R$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_TMP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_TMP],
				(iMoney >= g_iWeaponPrice[W_MAC10] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_MAC10],
				(iMoney >= g_iWeaponPrice[W_MP5NAVY] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_MP5NAVY],
				(iMoney >= g_iWeaponPrice[W_UMP45] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_UMP45],
				(iMoney >= g_iWeaponPrice[W_P90] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_P90],
				id, "EXIT")
		}

		case 4:
		{
			formatex(szMenu, charsmax(szMenu),"%s^n\d**[\r Categoria:\w Rifles. \d]**^n^n\d1. \%sGalil\R$%d^n\d2. \%sFamas\R$%d^n\d3. \%sAK-47\R$%d^n\d4. \%sM4A1\R$%d^n\d5. \%sAUG\R$%d^n\d6. \%sSG552\R$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_GALIL] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_GALIL],
				(iMoney >= g_iWeaponPrice[W_FAMAS] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_FAMAS],
				(iMoney >= g_iWeaponPrice[W_AK47] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_AK47],
				(iMoney >= g_iWeaponPrice[W_M4A1] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_M4A1],
				(iMoney >= g_iWeaponPrice[W_AUG] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_AUG],
				(iMoney >= g_iWeaponPrice[W_SG552] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_SG552],
				id, "EXIT")
		}

		case 5:
		{

#if FEATURE_ADRENALINE == true

			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\r Categoria:\w Armas por Adrenalina. \d]**^n^n\d1. \%sM249 \w(\%s%d %L\w)\R\%s$%d^n\d3. \%sSG550 \w(\%s%d %L\w)\R\%s$%d^n\d3. \%sG3SG1 \w(\%s%d %L\w)\R\%s$%d^n\d4. \%sScout \w(\%s%d %L\w)\R\%s$%d^n\d5. \%sAWP \d(\rBLOOD\d) \w(\%s%d %L\w)\R\%s$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_M249] && g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_M249] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_M249] ? BUY_ITEM_AVAILABLE2 : BUY_ITEM_DISABLED), g_iWeaponAdrenaline[W_M249], id, "ADRENALINE", (iMoney >= g_iWeaponPrice[W_M249] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_M249],
				(iMoney >= g_iWeaponPrice[W_SG550] && g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_SG550] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_SG550] ? BUY_ITEM_AVAILABLE2 : BUY_ITEM_DISABLED), g_iWeaponAdrenaline[W_SG550], id, "ADRENALINE", (iMoney >= g_iWeaponPrice[W_SG550] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_SG550],
				(iMoney >= g_iWeaponPrice[W_G3SG1] && g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_G3SG1] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_G3SG1] ? BUY_ITEM_AVAILABLE2 : BUY_ITEM_DISABLED), g_iWeaponAdrenaline[W_G3SG1], id, "ADRENALINE", (iMoney >= g_iWeaponPrice[W_G3SG1] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_G3SG1],
				(iMoney >= g_iWeaponPrice[W_SCOUT] && g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_SCOUT] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_SCOUT] ? BUY_ITEM_AVAILABLE2 : BUY_ITEM_DISABLED), g_iWeaponAdrenaline[W_SCOUT], id, "ADRENALINE", (iMoney >= g_iWeaponPrice[W_SCOUT] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_SCOUT],
				(iMoney >= g_iWeaponPrice[W_AWP] && g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_AWP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_AWP] ? BUY_ITEM_AVAILABLE2 : BUY_ITEM_DISABLED), g_iWeaponAdrenaline[W_AWP], id, "ADRENALINE", (iMoney >= g_iWeaponPrice[W_AWP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_AWP],
				id, "EXIT")

#else // FEATURE_ADRENALINE

			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\r Categoria:\w Armas por Adrenalina. \d]**^n^n\d1. \%sM249\R\%s$%d^n\d3. \%sSG550\R\%s$%d^n\d3. \%sG3SG1\R\%s$%d^n\d4. \%sScout\R\%s$%d^n\d5. \%sAWP \d(\rBLOOD\d)\R\%s$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_M249] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),(iMoney >= g_iWeaponPrice[W_M249] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_M249],
				(iMoney >= g_iWeaponPrice[W_SG550] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (iMoney >= g_iWeaponPrice[W_SG550] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_SG550],
				(iMoney >= g_iWeaponPrice[W_G3SG1] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (iMoney >= g_iWeaponPrice[W_G3SG1] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_G3SG1],
				(iMoney >= g_iWeaponPrice[W_SCOUT] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (iMoney >= g_iWeaponPrice[W_SCOUT] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_SCOUT],
				(iMoney >= g_iWeaponPrice[W_AWP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), (iMoney >= g_iWeaponPrice[W_AWP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), g_iWeaponPrice[W_AWP],
				id, "EXIT")

#endif // FEATURE_ADRENALINE

		}

		case 8:
		{
			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\r Categoria:\w Equipamentos. \d]**^n^n\d1. \%s%L\R$%d^n\d2. \%s%L\R$%d^n^n\d3. \%s%L\R$%d^n^n\d0. \w%L",
				INFO,
				(iMoney >= g_iWeaponPrice[W_VEST] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), id, "BUYMENU_ITEM_VEST", g_iWeaponPrice[W_VEST],
				(iMoney >= g_iWeaponPrice[W_VESTHELM] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), id, "BUYMENU_ITEM_VESTHELM", g_iWeaponPrice[W_VESTHELM],
				(iMoney >= g_iWeaponPrice[W_HEGRENADE] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), id, "BUYMENU_ITEM_HE", g_iWeaponPrice[W_HEGRENADE],
				//(iMoney >= g_iWeaponPrice[W_FLASHBANG] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED), id, "BUYMENU_ITEM_FLASHBANG", g_iWeaponPrice[W_FLASHBANG],
				id, "EXIT")
		}

		default:
		{
#if FEATURE_ADRENALINE == true

			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\y Menu de compras. \d]**^n^n\d1. \%sPistolas.^n\d2. \%sEscopetas.^n\d3. \%sSemi-automaticas.^n\d4. \%sRifles.^n\d5. \%sArmas por Adrenalina.^n^n^n\d8. \%sEquipamentos.^n^n\d0.\w Salir.",
				INFO,
				(iMoney >= g_iWeaponPrice[W_GLOCK18] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_M3] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_TMP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_GALIL] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_M249] && g_iAdrenaline[id] >= g_iWeaponAdrenaline[W_M249] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_FLASHBANG] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED))

#else // FEATURE_ADRENALINE

			formatex(szMenu, charsmax(szMenu), "%s^n\d**[\y Menu de compras. \d]**^n^n\d1. \%sPistolas.^n\d2. \%sEscopetas.^n\d3. \%sSemi-automaticas.^n\d4. \%sRifles.^n\d5. \%sArmas por Adrenalina.^n^n^n\d8. \%sEquipamentos.^n^n\d0.\w Salir.",
				INFO,
				(iMoney >= g_iWeaponPrice[W_GLOCK18] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_M3] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_TMP] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_GALIL] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_M249] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED),
				(iMoney >= g_iWeaponPrice[W_FLASHBANG] ? BUY_ITEM_AVAILABLE : BUY_ITEM_DISABLED))

#endif // FEATURE_ADRENALINE
		}
	}

	g_iMenu[id] = iMenu

	show_menu(id, MENU_KEYS_BUY, szMenu, -1, MENU_BUY)

	return PLUGIN_HANDLED
}

public player_key_buy(id, iKey)
{
	iKey += 1

	if(!g_bAlive[id] || iKey == 10)
		return PLUGIN_HANDLED

	if(!g_bBuyZone[id])
	{
		client_print(id, print_center, "%L", id, "BUY_NOTINZONE")
		return PLUGIN_HANDLED
	}

	switch(g_iMenu[id])
	{
		case 1:
		{
			switch(iKey)
			{
				case 1: player_buyWeapon(id, W_GLOCK18)
				case 2: player_buyWeapon(id, W_USP)
				case 3: player_buyWeapon(id, W_P228)
				case 4: player_buyWeapon(id, W_DEAGLE)
				case 5: player_buyWeapon(id, W_FIVESEVEN)
				case 6: player_buyWeapon(id, W_ELITE)
			}
		}

		case 2:
		{
			switch(iKey)
			{
				case 1: player_buyWeapon(id, W_M3)
				case 2: player_buyWeapon(id, W_XM1014)
			}
		}

		case 3:
		{
			switch(iKey)
			{
				case 1: player_buyWeapon(id, W_TMP)
				case 2: player_buyWeapon(id, W_MAC10)
				case 3: player_buyWeapon(id, W_MP5NAVY)
				case 4: player_buyWeapon(id, W_UMP45)
				case 5: player_buyWeapon(id, W_P90)
			}
		}

		case 4:
		{
			switch(iKey)
			{
				case 1: player_buyWeapon(id, W_GALIL)
				case 2: player_buyWeapon(id, W_FAMAS)
				case 3: player_buyWeapon(id, W_AK47)
				case 4: player_buyWeapon(id, W_M4A1)
				case 5: player_buyWeapon(id, W_AUG)
				case 6: player_buyWeapon(id, W_SG552)
			}
		}

		case 5:
		{
			switch(iKey)
			{
				case 1: player_buyWeapon(id, W_M249)
				case 2: player_buyWeapon(id, W_SG550)
				case 3: player_buyWeapon(id, W_G3SG1)
				case 4: player_buyWeapon(id, W_SCOUT)
				case 5: player_buyWeapon(id, W_AWP)
			}
		}

		case 8:
		{
			switch(iKey)
			{
				case 1: player_buyWeapon(id, W_VEST)
				case 2: player_buyWeapon(id, W_VESTHELM)
				case 3: player_buyWeapon(id, W_HEGRENADE)
				//case 4: player_buyWeapon(id, W_FLASHBANG)
			}
		}

		default:
		{
			switch(iKey)
			{
				case 1,2,3,4,5,8: player_menu_buy(id, iKey)
			}
		}
	}

	return PLUGIN_HANDLED
}

public player_cmd_buyWeapon(id)
{
	if(!g_bBuyZone[id])
	{
		client_print(id, print_center, "%L", id, "BUY_NOTINZONE")
		return PLUGIN_HANDLED
	}

	new szCmd[12]

	read_argv(0, szCmd, charsmax(szCmd))

	for(new w = W_P228; w <= W_NVG; w++)
	{
		for(new i = 0; i < 2; i++)
		{
			if(equali(g_szWeaponCommands[w][i], szCmd))
			{
				player_buyWeapon(id, w)
				return PLUGIN_HANDLED
			}
		}
	}

	return PLUGIN_HANDLED
}

public player_buyWeapon(id, iWeapon)
{
	if(!g_bAlive[id])
		return

	new iArmortype = get_member(id,m_iKevlar)
	new Float:iArmor = Float:get_entvar(id,var_armorvalue)
	new iMoney = get_member(id,m_iAccount)

	/* apply discount if you already have a kevlar and buying a kevlar+helmet */
	new iCost = g_iWeaponPrice[iWeapon] - (iArmortype == 1 && iWeapon == W_VESTHELM ? 650 : 0)

#if FEATURE_ADRENALINE == true

	new iCostAdrenaline = g_iWeaponAdrenaline[iWeapon]

#endif // FEATURE_ADRENALINE

	if(iCost > iMoney)
	{
		client_print(id, print_center, "%L", id, "BUY_NEEDMONEY", iCost)
		return
	}

#if FEATURE_ADRENALINE == true

	else if(!(iCostAdrenaline <= g_iAdrenaline[id]))
	{
		client_print(id, print_center, "%L", id, "BUY_NEEDADRENALINE", iCostAdrenaline)
		return
	}

#endif // FEATURE_ADRENALINE

	switch(iWeapon)
	{
		case W_NVG:
		{
			if(get_member(id,m_bHasNightVision))
			{
				client_print(id, print_center, "%L", id, "BUY_HAVE_NVG")
				return
			}
			set_member(id,m_bHasNightVision,1)
		}

		case W_VEST:
		{
			if(iArmor >= 100.0)
			{
				client_print(id, print_center, "%L", id, "BUY_HAVE_KEVLAR")
				return
			}
		}

		case W_VESTHELM:
		{
			if(iArmor >= 100.0 && iArmortype == 2)
			{
				client_print(id, print_center, "%L", id, "BUY_HAVE_KEVLARHELM")
				return
			}
		}

		case W_FLASHBANG:
		{
			new iGrenades = rg_get_user_bpammo(id, WEAPON_FLASHBANG)

			if(iGrenades >= 2)
			{
				client_print(id, print_center, "%L", id, "BUY_NOMORE_FLASH")
				return
			}

			new iCvar = get_pcvar_num(pCvar_ctf_nospam_flash)
			new Float:fGameTime = get_gametime()

			if(g_fLastBuy[id][iGrenades] > fGameTime)
			{
				client_print(id, print_center, "%L", id, "BUY_DELAY_FLASH", iCvar)
				return
			}

			g_fLastBuy[id][iGrenades] = fGameTime + iCvar

			if(iGrenades == 1)
				g_fLastBuy[id][0] = g_fLastBuy[id][iGrenades]
		}

		case W_HEGRENADE:
		{
			if(rg_get_user_bpammo(id, WEAPON_HEGRENADE) >= 1)
			{
				client_print(id, print_center, "%L", id, "BUY_NOMORE_HE")
				return
			}

			new iCvar = get_pcvar_num(pCvar_ctf_nospam_he)
			new Float:fGameTime = get_gametime()

			if(g_fLastBuy[id][2] > fGameTime)
			{
				client_print(id, print_center, "%L", id, "BUY_DELAY_HE", iCvar)
				return
			}

			g_fLastBuy[id][2] = fGameTime + iCvar
		}

		case W_SMOKEGRENADE:
		{
			if(rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE) >= 1)
			{
				client_print(id, print_center, "%L", id, "BUY_NOMORE_SMOKE")
				return
			}

			new iCvar = get_pcvar_num(pCvar_ctf_nospam_smoke)
			new Float:fGameTime = get_gametime()

			if(g_fLastBuy[id][3] > fGameTime)
			{
				client_print(id, print_center, "%L", id, "BUY_DELAY_SMOKE", iCvar)
				return
			}

			g_fLastBuy[id][3] = fGameTime + iCvar
		}
	}

	if(1 <= g_iWeaponSlot[iWeapon] <= 2)
	{
		new iWeapons
		new iWeaponList[32]

		get_user_weapons(id, iWeaponList, iWeapons)

		if(get_member(id,m_bOwnsShield))
			iWeaponList[iWeapons++] = W_SHIELD

		for(new w, i = 0; i < iWeapons; i++)
		{
			w = iWeaponList[i]

			if(1 <= g_iWeaponSlot[w] <= 2)
			{
				if(w == iWeapon)
				{
					client_print(id, print_center, "%L", id, "BUY_HAVE_WEAPON")
					return
				}

				if(iWeapon == W_SHIELD && w == W_ELITE)
					engclient_cmd(id, "drop", g_szWeaponEntity[W_ELITE]) // drop the dual elites too if buying a shield

				if(iWeapon == W_ELITE && w == W_SHIELD)
					engclient_cmd(id, "drop", g_szWeaponEntity[W_SHIELD]) // drop the too shield if buying dual elites

				if(g_iWeaponSlot[w] == g_iWeaponSlot[iWeapon])
				{
					if(g_iWeaponSlot[w] == 2 && iWeaponList[iWeapons-1] == W_SHIELD)
					{
						engclient_cmd(id, "drop", g_szWeaponEntity[W_SHIELD]) // drop the shield

						new ent = find_ent_by_owner(g_iMaxPlayers, g_szWeaponEntity[W_SHIELD], id)
				
						if(ent)
						{
							entity_set_int(ent, EV_INT_flags, FL_KILLME) // kill the shield
							call_think(ent)
						}

						engclient_cmd(id, "drop", g_szWeaponEntity[w]) // drop the secondary

						rg_give_item(id, g_szWeaponEntity[W_SHIELD], GT_REPLACE);
					}
					else
						engclient_cmd(id, "drop", g_szWeaponEntity[w]) // drop weapon if it's of the same slot
				}
			}
		}
	}

	if(iWeapon != W_NVG && iWeapon != W_C4)
	{
		if(iWeapon == W_HEGRENADE)
		{
			rg_give_item(id, "weapon_hegrenade", GT_APPEND);
		}
		else if(iWeapon == W_SMOKEGRENADE)
		{
			rg_give_item(id, "weapon_smokegrenade", GT_APPEND);
		}
		else if(iWeapon == W_FLASHBANG)
		{
			rg_give_item(id, "weapon_flashbang", GT_APPEND);
		}
		else
		{
			rg_give_item(id, g_szWeaponEntity[iWeapon], GT_REPLACE);
		}
	}
	player_addRebuy(id, iWeapon)

	if(g_iWeaponPrice[iWeapon])
		rg_add_account(id,-iCost)

#if FEATURE_ADRENALINE == true

	if(iCostAdrenaline)
	{
		g_iAdrenaline[id] -= iCostAdrenaline
	}

#endif // FEATURE_ADRENALINE

//	if(g_iBPAmmo[iWeapon])
	//	rg_set_user_bpammo(id, iWeapon, g_iBPAmmo[iWeapon]);
}
#endif // FEATURE_BUY

public weapon_spawn(ent)
{
	if(!is_entity(ent))
		return

	new Float:fWeaponStay = get_pcvar_float(pCvar_ctf_weaponstay)
	
	if(fWeaponStay > 0)
	{
		task_remove(ent)
		task_set(fWeaponStay, "weapon_startFade", ent)
	}
}

public weapon_startFade(ent)
{
	if(!is_entity(ent))
		return

	new szClass[32]

	entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass))

	if(!equal(szClass, WEAPONBOX) && !equal(szClass, ITEM_CLASSNAME))
		return

	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_int(ent, EV_INT_rendermode, kRenderTransAlpha)

	entity_set_float(ent, EV_FL_renderamt, 255.0)
	entity_set_vector(ent, EV_VEC_rendercolor, Float:{255.0, 255.0, 0.0})
	entity_set_vector(ent, EV_VEC_velocity, Float:{0.0, 0.0, 20.0})

	weapon_fadeOut(ent, 255.0)
}

public weapon_fadeOut(ent, Float:fStart)
{
	if(!is_entity(ent))
	{
		task_remove(ent)
		return
	}

	static Float:fFadeAmount[4096]

	if(fStart)
	{
		task_remove(ent)
		fFadeAmount[ent] = fStart
	}

	fFadeAmount[ent] -= 25.5

	if(fFadeAmount[ent] > 0.0)
	{
		entity_set_float(ent, EV_FL_renderamt, fFadeAmount[ent])

		task_set(0.1, "weapon_fadeOut", ent)
	}
	else
	{
		new szClass[32]

		entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass))

		if(equal(szClass, WEAPONBOX))
			weapon_remove(ent)
		else
			entity_remove(ent)
	}
}

public event_restartGame()
	g_bRestarting = true

public event_roundStart()
{
	new ent = -1

	while((ent = rg_find_ent_by_class(ent,WEAPONBOX)) > 0)
	{
		task_remove(ent)
		weapon_remove(ent)
	}

	ent = -1

	while((ent = rg_find_ent_by_class(ent,ITEM_CLASSNAME)) > 0)
	{
		task_remove(ent)
		entity_remove(ent)
	}

	for(new id = 1; id < g_iMaxPlayers; id++)
	{
		if(!g_bAlive[id])
			continue

		g_bDefuse[id] = false
		g_fLastBuy[id] = Float:{0.0, 0.0, 0.0, 0.0}

		task_remove(id - TASK_EQUIPAMENT)
#if FEATURE_TEAMBALANCE == true
		task_remove(id - TASK_TEAMBALANCE)
#endif
		task_remove(id - TASK_DEFUSE)

		if(g_bRestarting)
		{
			task_remove(id)
			task_remove(id - TASK_ADRENALINE)

			g_bRestarted[id] = true
			g_iAdrenaline[id] = 0
			g_iAdrenalineUse[id] = 0
		}

		player_updateSpeed(id)
	}

	for(new iFlagTeam = TEAM_RED; iFlagTeam <= TEAM_BLUE; iFlagTeam++)
	{
		flag_sendHome(iFlagTeam)

		task_remove(g_iFlagEntity[iFlagTeam])

		log_message("%s, %s flag returned back to base.", (g_bRestarting ? "Game restarted" : "New round started"), g_szTeamName[iFlagTeam])
	}

	if(g_bRestarting)
	{
		g_iScore = {0,0,0}
		g_bRestarting = false
	}
}

public msg_block()
	return PLUGIN_HANDLED

public msg_teamScore()
{
	new szTeam[2]

	get_msg_arg_string(1, szTeam, 1)

	switch(szTeam[0])
	{
		case 'T': set_msg_arg_int(2, ARG_SHORT, g_iScore[TEAM_RED])
		case 'C': set_msg_arg_int(2, ARG_SHORT, g_iScore[TEAM_BLUE])
	}
}

public msg_roundTime()
	set_msg_arg_int(1, ARG_SHORT, get_timeleft())


player_award(id, iMoney, iFrags, iAdrenaline, szText[], any:...)
{
#if FEATURE_ADRENALINE == false

	iAdrenaline = 0

#endif // FEATURE_ADRENALINE

	if(!g_iTeam[id] || (!iMoney && !iFrags && !iAdrenaline))
		return

	new szMsg[48]
	new szMoney[24]
	new szFrags[48]
	new szFormat[192]
	new szAdrenaline[48]

	if(iMoney != 0)
	{
		rg_add_account(id,iMoney)
		formatex(szMoney, charsmax(szMoney), "^4%s%d$^1", iMoney > 0 ? "+" : NULL, iMoney)
	}

	if(iFrags != 0)
	{
		player_setScore(id, iFrags, 0)
		formatex(szFrags, charsmax(szFrags), "^4%s%d^1 %L", iFrags > 0 ? "+" : NULL, iFrags, id, (iFrags > 1 ? "FRAGS" : "FRAG"))
	}

#if FEATURE_ADRENALINE == true

	if(iAdrenaline != 0)
	{
		g_iAdrenaline[id] = clamp(g_iAdrenaline[id] + iAdrenaline, 0, 100)
		//player_hudAdrenaline(id)
		formatex(szAdrenaline, charsmax(szAdrenaline), "^4%s%d^1 %L", iAdrenaline > 0 ? "+" : NULL, iAdrenaline, id, "ADRENALINE")
	}

#endif // FEATURE_ADRENALINE == true

	vformat(szMsg, charsmax(szMsg), szText, 6)
	formatex(szFormat, charsmax(szFormat), "%s%s%s%s%s ^4Motivo:^1 %s", szMoney, (szMoney[0] && (szFrags[0] || szAdrenaline[0]) ? " || " : NULL), szFrags, (szFrags[0] && szAdrenaline[0] ? " || " : NULL), szAdrenaline, szMsg)
	player_print(id, szFormat)
}

player_setScore(id, iAddFrags, iAddDeaths)
{
	new iFrags = floatround(get_entvar(id,var_frags),floatround_round)
	new iDeaths = get_member(id,m_iDeaths)

	if(iAddFrags != 0)
	{
		iFrags += iAddFrags
		set_entvar(id,var_frags,Float:get_entvar(id,var_frags)+float(iAddFrags))
	}

	if(iAddDeaths != 0)
	{
		iDeaths += iAddDeaths
		set_member(id, m_iDeaths, iDeaths)
	}

	message_begin(MSG_BROADCAST, gMsg_ScoreInfo)
	write_byte(id)
	write_short(iFrags)
	write_short(iDeaths)
	write_short(0)
	write_short(g_iTeam[id])
	message_end()
}

player_healingEffect(id)
{
	new iOrigin[3] 

	get_user_origin(id, iOrigin)

	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
	write_byte(TE_PROJECTILE)
	write_coord(iOrigin[x] + random_num(-10, 10))
	write_coord(iOrigin[y] + random_num(-10, 10))
	write_coord(iOrigin[z] + random_num(0, 30))
	write_coord(0)
	write_coord(0)
	write_coord(15)
	write_short(gSpr_regeneration)
	write_byte(1)
	write_byte(id)
	message_end()
}

player_updateSpeed(id)
{
	new Float:fSpeed = 1.0

	if(player_hasFlag(id))
		fSpeed *= SPEED_FLAG

	set_entvar(id,var_maxspeed,g_fWeaponSpeed[id] * fSpeed)
}

game_announce(iEvent, iFlagTeam, szName[])
{
	new iColor = iFlagTeam
	new szText[64]

	switch(iEvent)
	{
		case EVENT_TAKEN:
		{
			iColor = get_opTeam(iFlagTeam)
			formatex(szText, charsmax(szText), "%L", LANG_PLAYER, "ANNOUNCE_FLAGTAKEN", szName, LANG_PLAYER, g_szMLFlagTeam[iFlagTeam])
		}

		case EVENT_DROPPED: formatex(szText, charsmax(szText), "%L", LANG_PLAYER, "ANNOUNCE_FLAGDROPPED", szName, LANG_PLAYER, g_szMLFlagTeam[iFlagTeam])

		case EVENT_RETURNED:
		{
			if(strlen(szName) != 0)
				formatex(szText, charsmax(szText), "%L", LANG_PLAYER, "ANNOUNCE_FLAGRETURNED", szName, LANG_PLAYER, g_szMLFlagTeam[iFlagTeam])
			else
				formatex(szText, charsmax(szText), "%L", LANG_PLAYER, "ANNOUNCE_FLAGAUTORETURNED", LANG_PLAYER, g_szMLFlagTeam[iFlagTeam])
		}

		case EVENT_SCORE: formatex(szText, charsmax(szText), "%L", LANG_PLAYER, "ANNOUNCE_FLAGCAPTURED", szName, LANG_PLAYER, g_szMLFlagTeam[get_opTeam(iFlagTeam)])
	}

	set_hudmessage(iColor == TEAM_RED ? 255 : 0, 0, iColor == TEAM_BLUE ? 255 : 0, HUD_ANNOUNCE)
	ShowSyncHudMsg(0, g_iSync[1], szText)

	if(get_pcvar_num(pCvar_ctf_sound[iEvent]))
		client_cmd(0, "mp3 play ^"sound/OzutServers/ctf/%s.mp3^"", g_szSounds[iEvent][iFlagTeam])
}

/*********************************************************************************************************************/
stock player_print(id, input[], any:...)
{
	if(g_bBot[id] || (id && !g_iTeam[id]))
		return PLUGIN_HANDLED
		
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


public Forward_BloodColor(Client)
{
	SetHamReturnInteger(-1);
	return HAM_SUPERCEDE;
}
