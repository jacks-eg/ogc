#include <amxmodx>
#include <amxmisc>
#include <astro>

native jctf_dropflag(id)
native jctf_adrenaline(id)

#define PLUGIN "Menu N"
#define VERSION "1.0"
#define AUTHOR "Jack's"

new const INFO[] = "\r• \wASTRO STRIKE COMMUNITY\d |\y CAPTURE THE FLAG + RANGOS^n\r•\w Grupo:\r www\w.\rfacebook\w.\rcom\w/\rgroups\w/\rastrostrike"
new KEYSMENU = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("nightvision", "cmdMenuN")
	register_menu("Menu N", KEYSMENU, "HandMenuN")
} 

public cmdMenuN(qIndex)
{
	new menu[512], len;len = 0;

	len += formatex(menu[len], sizeof menu - 1 - len, "%s^n\r•\w Menú Principal^n^n", INFO)

	len += formatex(menu[len], sizeof menu - 1 - len, "\r1. \ySoltar \rBandera.^n")

	if(jctf_adrenaline(qIndex) >= 100)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \yUsar:\w Combos de Adrenalina.^n")
	else 
		len += formatex(menu[len], sizeof menu - 1 - len, "\r2. \dNecesitas tener\r 100\d de\y Adrenalina^n")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r3. \wTop10\d (\r Ranking \d)^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4. \wVer:\y Ganadores\w actuales del\r Evento^n")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r5. \wLista de\y Rangos\d (\rCSGO\d)^n")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r0. \wSalir.")

	show_menu(qIndex, KEYSMENU, menu, -1, "Menu N")
}

public HandMenuN(qIndex, qKeys, qMenu)	
{
	switch(qKeys)
	{
		case 0: jctf_dropflag(qIndex)
		case 1: 
		{
			if(jctf_adrenaline(qIndex) >= 100)
				jctf_adrenaline(qIndex)
			else
				cmdMenuN(qIndex)
		}
		case 2: client_cmd(qIndex, "say top1")
		case 3: client_cmd(qIndex, "say evento")
		case 4: client_cmd(qIndex, "say rangos")
	}

	return PLUGIN_HANDLED
}