#include <amxmodx>
#include <engine>

const HUD_CHANNEL = 3
const TASK_BOMB_TIMER = 1546813

new g_iC4Timer, g_iDefaultC4Timer, mp_c4timer

//sprite
new g_c4timer, cvar_showteam, cvar_flash, cvar_sprite, g_C4, g_msg_showtimer, 
g_msg_roundtime, g_msg_scenario

#define MAX_SPRITES	2
#define task_sound 69696969

static const g_timersprite[MAX_SPRITES][] = 
{ 
	"bombticking", "bombticking1" 
}

public plugin_init()
{
	register_plugin("C4 Time HUD", "1.0", "Spy.VE")
	
	//C4TIMER
	if(find_ent_by_class(-1, "func_bomb_target") 
	|| find_ent_by_class(-1, "info_bomb_target"))
	{
		register_event("SendAudio", "Broadcast_BOMBPL", "a", "1=0", "2=%!MRAD_BOMBPL" /* , "3=100" */)
		register_event("HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0")
		register_logevent("Logevent_Round_End", 2, "1=Round_End")
	
		mp_c4timer = get_cvar_pointer("mp_c4timer")
		g_iDefaultC4Timer = get_pcvar_num(mp_c4timer)
	}
		
	//sprite
	cvar_showteam	= register_cvar("og_showc4timer", "3")
	cvar_flash	= register_cvar("og_showc4flash", "0")
	cvar_sprite	= register_cvar("og_showc4sprite", "1")
	//cvar_msg	= register_cvar("og_showc4msg", "1")
	
	g_msg_showtimer	= get_user_msgid("ShowTimer")
	g_msg_roundtime	= get_user_msgid("RoundTime")
	g_msg_scenario	= get_user_msgid("Scenario")
		
	register_logevent("logevent_plantedthebomb", 3, "2=Planted_The_Bomb")
		
	g_C4	= get_cvar_pointer("mp_c4timer")
}

public Event_HLTV_New_Round()
{
	if(g_iC4Timer)
	{
		remove_task(TASK_BOMB_TIMER)
		g_iC4Timer = 0
		g_iDefaultC4Timer = get_pcvar_num(mp_c4timer)
		
		//sprite
		g_c4timer = get_pcvar_num(g_C4)
	}
}
public Logevent_Round_End()
{
	if(g_iC4Timer)
	{
		remove_task(TASK_BOMB_TIMER)
		g_iC4Timer = 0
	}
}
public Broadcast_BOMBPL()
{
	g_iC4Timer = g_iDefaultC4Timer
	set_task(1.0, "Task_BombTimer", TASK_BOMB_TIMER, .flags="a", .repeat=g_iC4Timer)
	Task_BombTimer()
}
public Task_BombTimer()
{
    if(g_iC4Timer > 10)
    {
        if(g_iC4Timer != g_iDefaultC4Timer && (g_iC4Timer == 30 || g_iC4Timer == 20))
        {
            new temp[64]
            num_to_word(g_iC4Timer, temp, charsmax(temp))
            sound_all("spk ^"vox/%s seconds until explosion^"", temp)
        }
    }
    else if(g_iC4Timer > 0)
    {
        new temp[64]; num_to_word(g_iC4Timer, temp, charsmax(temp))
        sound_all("spk ^"vox/%s^"", temp)
    }

    --g_iC4Timer


}
sound_all(const fmt[], any:...)
{
    new cmd[64]
    vformat(cmd, charsmax(cmd), fmt, 2)
    new players[32], num, id
    get_players(players, num, "c")

    for(--num; num>=0; num--)
    {
        id = players[ num ]
        if( !is_user_connecting( id ) )
        {
            client_cmd(id, cmd)
        }
    }
}  

//sprite
public logevent_plantedthebomb()
{
	if(task_exists(TASK_BOMB_TIMER))
	{
		new showtteam = get_pcvar_num(cvar_showteam)
		
		static players[32], num, i
		
		switch(showtteam)
		{
			case 1: get_players(players, num, "ace", "TERRORIST")
			case 2: get_players(players, num, "ace", "CT")
			case 3: get_players(players, num, "ac")
			default: return
		}
		
		for(i = 0; i < num; ++i) set_task(1.0, "update_timer", players[i])
	}
}
public update_timer(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msg_showtimer, _, id)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msg_roundtime, _, id)
	write_short(g_c4timer)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msg_scenario, _, id)
	write_byte(1)
	write_string(g_timersprite[clamp(get_pcvar_num(cvar_sprite), 0, (MAX_SPRITES - 1))])
	write_byte(150)
	write_short(get_pcvar_num(cvar_flash) ? 20 : 0)
	message_end()
	/*
	if(get_pcvar_num(cvar_msg))
	{
		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.87, 1, 6.0, 10.0)
		show_hudmessage(id, g_message)
	}*/
}

