#include <amxmodx>
#include <fakemeta>
#include <cstrike>

new g_maxplayers
new tCount
new ctCount
new g_msgScreenFade;

public plugin_init()
{
	register_plugin("Addon: Win Team", "1.0", "Raheem ft Jack's")
	g_maxplayers = get_maxplayers()
	register_logevent("logevent_round_end", 2, "1=Round_End")
	g_msgScreenFade = get_user_msgid("ScreenFade");
}

public logevent_round_end()
{
	
	tCount = GetPlayersNum(CsTeams:CS_TEAM_T)
	ctCount = GetPlayersNum(CsTeams:CS_TEAM_CT)
	
	for (new id = 1; id <= g_maxplayers; id++)
	{			
		if(ctCount > tCount)
			ScreenFade(0, 0, 150);
		else if(tCount > ctCount)
			ScreenFade(150, 0, 0);
		else
			ScreenFade(150, 150, 150);
	}
}

stock GetPlayersNum(CsTeams:iTeam)
{
    new iNum;
    for( new i = 1; i <= g_maxplayers; i++ )
	{
        if( is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) == iTeam )
            iNum++;
    }
    return iNum;
}

stock ScreenFade(red, green, blue)
{
	message_begin(MSG_BROADCAST, g_msgScreenFade);
	write_short((1<<12)*4);
	write_short((1<<12)*1);
	write_short(0x0001);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(250);
	message_end();
}  

