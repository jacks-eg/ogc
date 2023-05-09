/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#define PLUGIN  "Reapi RoundMoney"
#define VERSION "1.0"
#define AUTHOR  "Jack's"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHookChain(RG_CBasePlayer_AddAccount, "OnCallMoneyEvent")

	    /* Forwards */
	register_forward( FM_SetModel, "fw_SetModel" );  

}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;
	
	// Get entity's classname
	static classname[10]
	pev(entity, pev_classname, classname, charsmax(classname))
		
	// Check if it's a weapon box
	if (equal(classname, "weaponbox"))
	{
		// They get automatically removed when thinking
		set_pev(entity, pev_nextthink, get_gametime() + 10.0)
		return;
	}
}


public OnCallMoneyEvent(id, amount, RewardType:type, bool:bTrackChange)
{
	SetHookChainArg(2, ATYPE_INTEGER, 16000)
}