/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <jctf>

#define MAX_ITEM 10

enum _:ITEMS
{
	ITEM_NAME[32],
	ITEM_COST,
	ITEM_FORWARD
}

new iCmd[][]={"say /adrenaline", "say adrenaline", "say_team /adrenaline","say_team adrenaline","say /adrenalina","say_team /adrenalina","say adrenalina","say_team adrenalina"}
new const TAG[] = "^4[^1O'G^4]^1 ";
new const INFO[] = "\d[\rO'G\d]\w Captura la Bandera + Rangos \d[\r 1.0b\d ]^n\d[\rO'G\d]\w GRUPO:\d https://www.facebook.com/groups/community.og/"

new g_szItem[MAX_ITEM][ITEMS], g_TotalItems

public plugin_init()
{
	register_plugin("CTF Combos", "1.2b", "Sugisaki & Spy.VE")
	for(new i; i < sizeof iCmd; i++){ register_clcmd(iCmd[i], "ShowMenu_ShopAdrenaline"); }	
}

public plugin_natives()
{
	register_native("shop_add_item", "_native_add_item")
	register_native("og_shop", "ShowMenu_ShopAdrenaline", 1)
}

public _native_add_item(pid, par)
{
	if(g_TotalItems >= MAX_ITEM)
	{
		log_amx("Maximo de Combos (%i) alcanzado, Modifica el plugin de la tienda.",  MAX_ITEM)
		return PLUGIN_HANDLED
	}
	
	if(get_param(2) > 100)
	{
		log_amx("El item #%d sobrepaso el valor de 100 de adrenalina.", g_TotalItems)
		return PLUGIN_HANDLED
	}
	new FWD[32]
	g_szItem[g_TotalItems][ITEM_COST] = get_param(2)
	get_string(1, g_szItem[g_TotalItems][ITEM_NAME], 31)
	get_string(3, FWD, charsmax(FWD))
	if(get_func_id(FWD, pid) == -1)
	{
		new pluginfilename[32]
		get_plugin(pid, pluginfilename, charsmax(pluginfilename));
		log_amx("[%s] Funcion %s Inexistente", pluginfilename, FWD);
		return PLUGIN_HANDLED
	}
	if((g_szItem[g_TotalItems][ITEM_FORWARD] = CreateOneForward(pid, FWD, FP_CELL, FP_STRING)) == -1)
	{
		log_amx("Ocurrio un error al crear la funcion %s", FWD)
		return PLUGIN_HANDLED
	}
	g_TotalItems++
	return PLUGIN_CONTINUE
}

public ShowMenu_ShopAdrenaline(id)
{
	new temp[512], menu, len[512];
	formatex(len, charsmax(len), "%s^n\r*\w Menu de Combos\d (\r CTF\d )", INFO);
	menu = menu_create(len, "buymenu_handled");
	
	for(new i = 0; i < g_TotalItems; i++)
	{
		num_to_str(i, temp, charsmax(temp))
		menu_additem(menu, fmt("%s\d Costo:\y%d \r(ADR)", g_szItem[i][ITEM_NAME], g_szItem[i][ITEM_COST]))
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atras.")
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente.")
	menu_setprop(menu, MPROP_EXITNAME, "Salir.")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED
}

public buymenu_handled(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new cost = get_user_adrenaline(id)
	if(g_szItem[item][ITEM_COST] > cost)
	{
		player_print(id, "^1 No tienes suficiente^4 Adrenalina^1 para comprar este^4 Combo")
		return PLUGIN_HANDLED
	}
	
	new ret
	ExecuteForward(g_szItem[item][ITEM_FORWARD], ret, id, g_szItem[item][ITEM_NAME]);
	if(ret == PLUGIN_HANDLED)
	{
		return PLUGIN_HANDLED
	}
	set_user_adrenaline(id, cost - g_szItem[item][ITEM_COST])
	return PLUGIN_CONTINUE
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
