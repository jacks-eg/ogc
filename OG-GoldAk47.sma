#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <api_shop>

#define is_valid_player(%1) (1 <= %1 <= 32)
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define WEAPONKEY 756144798
#define ENG_NULLENT		-1

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<
CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<
CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

new AK_V_MODEL[64] = "models/OzutServers/v_GoldAk.mdl"
new AK_P_MODEL[64] = "models/OzutServers/p_GoldAk.mdl"

new g_itemid, g_MaxPlayers
new bool:g_HasA[33]
new g_hasZoom[ 33 ]
const W_AK47 = ((1<<CSW_AK47))

public plugin_init()
{
	register_plugin("[CTF] Gold AK-47", "1.1", "Alejandro")
	
	g_itemid = ctf_item_register("Golden AK-47", 9999, 99999)
	
	register_clcmd("drop", "clcmd_drop")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "event_DeathMsg", "a", "1>0")
	register_logevent("logevent_round_end", 2, "1=Round_End") 
	
	register_event("CurWeapon", "checkWeapon", "be", "1=1")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	//register_forward(FM_CmdStart, "fw_CmdStart" )
	register_forward(FM_SetModel, "fw_SetModel");
	
	g_MaxPlayers = get_maxplayers()
}

public ctf_item_selected(id, item_id)
{
	if (item_id != g_itemid)
		return PLUGIN_CONTINUE;

	
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if ( item_id == g_itemid )
	{
		drop_weapons(id, 1)
		give_item(id, "weapon_ak47")
		g_HasA[id] = true;
	}
	
	return PLUGIN_CONTINUE;
} 

public clcmd_drop(player)
{
	if (g_HasA[player])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public event_round_start()
{
	for (new id = 1; id <= g_MaxPlayers; id++)
	{
		g_HasA[id] = false
	}
}

public logevent_round_end()
{
	for (new id = 1; id <= g_MaxPlayers; id++)
	{
		g_HasA[id] = false
	}
}

public client_disconnected(id)
{
	g_HasA[id] = false
}

public event_DeathMsg()
{
	g_HasA[read_data(2)] = false
}

public plugin_precache()
{
	precache_model(AK_V_MODEL)
	precache_model(AK_P_MODEL)
	//precache_sound("weapons/zoom.wav")
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeapId
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if(g_HasA[id])
	{
		if (plrWeapId == CSW_AK47)
		{
			set_pev(id, pev_viewmodel2, AK_V_MODEL)
			set_pev(id, pev_weaponmodel2, AK_P_MODEL)
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AK47 && g_HasA[attacker] )
	{
		SetHamParamFloat(4, damage * 6 )
	}
}
/*
public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_AK47 && g_HasA[id] && !g_hasZoom[id])
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_AK47 && g_HasA[id] && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}*/

public fw_SetModel(entity, model[])
{

	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_ak47", entity)
		
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
		
		entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, WEAPONKEY)
		entity_set_model(entity, "models/w_ak47.mdl")
		g_HasA[iOwner] = false
		
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}
