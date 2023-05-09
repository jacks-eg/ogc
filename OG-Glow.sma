#include <amxmodx>
#include <hamsandwich>
#include <fun>

#pragma semicolon 1

new const PluginInfo[][] = { "Glow Menu", "v1.0", "totopizza" };

#define INFO 	"\d- [\rO'G\d]\w ||\y Ozut Gamer`s \w ||\d CS-Public\r Oficial\y #1^n\d- \rGRUPO:\d www.fb.com/groups/community.og/^n\d-\r Fundador\d &\r Soporte:\w Spy.VE^n\d-\w Menu de Armas\d [\r PREMIUM\d ]"

enum _:DATA_GLOW {
	color[25],
	r,
	g,
	b
};

new const szGlowMenu[][DATA_GLOW] = {
	//Color            R    G    B
	{ "Rojo",    255,     0,     0    },
	{ "Verde",    0,    255,    0     },
	{ "Azul",    0,    0,    255    },
	{ "Celeste",    0,    255,    255    },
	{ "Amarillo",    255,     255,    0    },
	{ "Naranja",    255,    128,    0    }
};

new bool:UserGlow[33], UserGlowNumber[33];

public plugin_init() {
	register_plugin(PluginInfo[0], PluginInfo[1], PluginInfo[2]);
}

public plugin_natives()
	register_native("og_open_glowmenu", "glowmenu", 1);

public client_putinserver(id) 
{
	UserGlow[id] = false;
	UserGlowNumber[id] = -1;
}

public glowmenu(id) {
	show_menu_glow(id);
}

public show_menu_glow(id) {
	new menu = menu_create(fmt("%s^n\r***\w !BRILLO!\r ***", INFO), "opc_menu");
	new text[512];
	
	for(new i=0;i < sizeof(szGlowMenu); i++) 
	{
		if(i == UserGlowNumber[id])
		formatex(text, charsmax(text), "\d %s \d[\r***\d]", szGlowMenu[i][color]);
		else
		formatex(text, charsmax(text), "\w %s", szGlowMenu[i][color]);
		
		menu_additem(menu, text, "");
	}
	menu_additem(menu, "\yQuitar Brillo", "");
	
	menu_setprop(menu, MPROP_NEXTNAME, "\wSiguiente");
	menu_setprop(menu, MPROP_BACKNAME, "\wAnterior");
	menu_setprop(menu, MPROP_EXITNAME, "\ySalir");
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public opc_menu(id, menu, item)
 {
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return;
	}
		
	if(UserGlowNumber[id] == item) 
	{
		glowmenu(id);
		return;
	}
	
	if(item == 6) 
	{
		UserGlow[id] = false;
		UserGlowNumber[id] = -1;
		set_user_rendering(id, kRenderFxNone);
		menu_destroy(menu);
		return;
	}
	
		
	UserGlow[id] = true;
	UserGlowNumber[id] = item;
		
	set_hudmessage(random_num(15, 255), random_num(15, 255), random_num(15, 255), -1.0, 0.70, 1, 6.0, 2.0);
	show_hudmessage(id, "* !Activado! *^n*****|| Brillo: %s ||*****", szGlowMenu[item][color]);
	
	set_user_rendering(id, kRenderFxGlowShell, szGlowMenu[UserGlowNumber[id]][r], szGlowMenu[UserGlowNumber[id]][g], szGlowMenu[UserGlowNumber[id]][b], kRenderNormal, 20);
	menu_destroy(menu);
	return;
}
