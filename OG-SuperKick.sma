/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Super Kick"
#define VERSION "1.0b"
#define AUTHOR "Spy.VE"

new gMaxPlayers
new const TAG[] = "^4[^1O'G^4]^1 ";

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("ipower", "cmdpower")
	gMaxPlayers = get_maxplayers()
}

public cmdpower(id)
{
	MenuPower(id)
	return PLUGIN_HANDLED;
}

public MenuPower(id) 
{
	new gMenu; gMenu = menu_create("Menu Super Kick 1.0b", "handler_power")
	new gName[32], gID[12]
    
	for(new i = 1; i <= gMaxPlayers; i++) 
	{
		if(is_user_connected(i)) 
		{
          
			get_user_name(i, gName, charsmax(gName))
			formatex(gID, charsmax(gID), "%d %d", i, get_user_userid(i))
			menu_additem(gMenu, gName, gID)
		}
    
	}
	menu_display(id, gMenu, 0)
	return PLUGIN_HANDLED;
}
public handler_power(id, menu, item) 
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}

	new lol, buffer[12], playerid, userid
	menu_item_getinfo(menu, item, lol, buffer, charsmax(buffer), _, _, lol)
    
	new szid[3], szuserid[9], logdata[100]
	parse(buffer, szid, charsmax(szid), szuserid, charsmax(szuserid))
	playerid = str_to_num(szid)
	userid = str_to_num(szuserid)
	
	if(!is_user_connected(playerid))  
	{
		player_print(id, "Usuario seleccionado con la^3 ID:^4 %d^1 se ha desconectado.", playerid)
		return PLUGIN_HANDLED;
	}	
	
	if(userid != get_user_userid(playerid)) 
	{
		player_print(id, "Usuario seleccionado no es el que usted eligio.")
		return PLUGIN_HANDLED;
	}
	
	new name[32]
	get_user_name(playerid, name, charsmax(name))
    
	player_print(id, "Has Kikeado a:^4 %s^1 su id es:^4 %d", name, playerid)
	server_cmd("kick ^"%s^"", name)
	
	formatex(logdata, charsmax(logdata), "[MRO] Has Kikeado a: %s", name)
	log_to_file("mro_superkick.log", logdata)
	
	return PLUGIN_HANDLED;
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
