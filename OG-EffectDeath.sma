#include <amxmodx>
#include <reapi>

#define PLUGIN "Deathtype Effects"
#define VERSION "1.0"
#define AUTHOR "anakin_cstrike"

#define TEMP_MSG	16
#define TEMP_MSG2	1936

#define is_valid_player_alive(%0) (1 <= %0 <= MAX_PLAYERS && is_user_alive(%0))

new toggle_plugin,toggle_hs,toggle_kn,toggle_he,g_Smoke,g_Lightning,g_Explode;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	//register_event("DeathMsg","hook_death","a");
	RegisterHookChain(RG_CBasePlayer_Killed, "sounds_killer", false)

	toggle_plugin = register_cvar("death_effects","1");
	toggle_hs = register_cvar("hs_effect","1");
	toggle_kn = register_cvar("kn_effect","1");
	toggle_he = register_cvar("he_effect","1");
}

public plugin_precache()
{
	precache_sound("ambience/thunder_clap.wav");
	precache_sound("weapons/explode3.wav");
	g_Smoke = precache_model("sprites/steam1.spr");
	g_Lightning = precache_model("sprites/lgtning.spr");
	g_Explode = precache_model("sprites/white.spr");
	return PLUGIN_CONTINUE
}

public sounds_killer(victim, attacker, shouldgib)
{
	if(get_pcvar_num(toggle_plugin) != 1) return PLUGIN_HANDLED;

	if(!is_valid_player_alive(attacker) || victim == attacker || get_member(attacker, m_iTeam) == get_member(victim, m_iTeam))
		return PLUGIN_HANDLED;

 	new vOrigin[3],coord[3];

	get_user_origin(victim,vOrigin);
	vOrigin[2] -= 26
	coord[0] = vOrigin[0] + 150;
	coord[1] = vOrigin[1] + 150;
	coord[2] = vOrigin[2] + 800;

	if(get_member(victim, m_LastHitGroup) == HITGROUP_HEAD && GetCurrentWeapon(attacker) != WEAPON_KNIFE && get_pcvar_num(toggle_hs) == 1) 
	{
		//PlaySound(ListSounds[random_num(0, sizeof ListSounds -1)][HEADSHOT])
		create_explode(vOrigin);
		emit_sound(victim,CHAN_ITEM, "weapons/explode3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else
    {
		if( GetCurrentWeapon(attacker) == WEAPON_DEAGLE && get_pcvar_num(toggle_he) == 1)
		{
			//PlaySound(ListSounds[random_num(0, sizeof ListSounds -1)][GRENADE])
			//PlaySound(ListSounds[4][GRENADE])
			create_blood(vOrigin);
        }
		else if( GetCurrentWeapon(attacker) == WEAPON_KNIFE && get_pcvar_num(toggle_kn) == 1)
        {
			create_thunder(coord,vOrigin);
			emit_sound(victim,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
        }
    }
	return PLUGIN_CONTINUE
}

WeaponIdType:GetCurrentWeapon(iId)
{
    new iItem = get_member(iId, m_pActiveItem)
        
    if(!is_entity(iItem))
    {
        return WEAPON_NONE;
    }
    
    new WeaponIdType:iWeapon = get_member(iItem, m_iId)
    
    if (!(WEAPON_P228 <= iWeapon <= WEAPON_P90))
    {
        return WEAPON_NONE
    }
    
    return iWeapon
}


create_explode(vec1[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1);
	write_byte(TE_BEAMCYLINDER);
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2] + TEMP_MSG); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2] + TEMP_MSG2); 
	write_short(g_Explode); 
	write_byte(0);
	write_byte(0); 
	write_byte(2); 
	write_byte(16);
	write_byte(0);
	write_byte(188); 
	write_byte(220);
	write_byte(255); 
	write_byte(255); 
	write_byte(0); 
	message_end();

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION2); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_byte(185); 
	write_byte(10); 
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
	write_byte(TE_SMOKE); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_short(g_Smoke); 
	write_byte(2);  
	write_byte(10);  
	message_end();
}
create_thunder(vec1[3],vec2[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(0); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(g_Lightning); 
	write_byte(1);
	write_byte(5);
	write_byte(2);
	write_byte(20);
	write_byte(30);
	write_byte(200); 
	write_byte(200);
	write_byte(200);
	write_byte(200);
	write_byte(200);
	message_end();

	message_begin( MSG_PVS, SVC_TEMPENTITY,vec2); 
	write_byte(TE_SPARKS); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec2); 
	write_byte(TE_SMOKE); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(g_Smoke); 
	write_byte(10);  
	write_byte(10)  
	message_end();
}
create_blood(vec1[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_LAVASPLASH); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	message_end(); 
}
