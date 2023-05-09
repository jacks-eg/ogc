#include < amxmodx >
#include < sqlx >
#include < hamsandwich >
#include < cstrike >

#define PLUGIN "Sistema de cuentas MySQL/SQLite"
#define VERSION "1.0.9"
#define AUTHOR "Neeeeeeeeeel.- & r0ma"

/* 
	Sistema de cuentas MySQL/SQLite Version: 1.0.9
	
	Principales colaboradores del Codigo.
	
	Neeeeeeeeeel.-
	shinoda
	Kiske
	Javivi
	ILUSION
	fearAR
	rak
	r0ma
*/

new const MYSQL_HOST[] = "74.91.127.79"
new const MYSQL_USER[] = "ogservers_ze"
new const MYSQL_PASS[] = "hcp0oolpdf"
new const MYSQL_DATEBASE[] = "ze_evo"

new const TABLES[][] = { "Registro", "Eventos", "Escapes" }

new const g_info[][] = { 
	"^4[^1O'G^4]^1 ",
	"\d[\r O'G\d ]\w Zombie Escape + Niveles\r CSO\d [\y BOSS + EVO\d ]^n\d[\r O'G\d ]\y Version:\r 1.0b\y Foro:\d www.ozutservers.tk"
}
new g_szHashPass[ 33 ][ 34 ];

// comentar esta linea para desactivar la proteccion de caracteres especiales
#define CHARACTERS_PROTECTION

#define	TAG	"[Cuentas]"
new Handle:g_hTuple;
new g_maxplayers;
new g_usuario[ 33 ][ 33 ];
new g_password[ 33 ][ 35 ];
new g_estado[ 33 ];
new g_playername[ 33 ][ 33 ];
new g_id[ 33 ];
new g_experiencia[ 33 ];
new g_menu[512];

enum
{
	OFFLINE = 0,
	REGISTRAR_USUARIO,
	REGISTRAR_PASSWORD,
	LOGUEAR_USUARIO,
	LOGUEAR_PASSWORD,
	NEW_PASSWORD,
	CARGAR_DATOS,
	GUARDAR_DATOS,
	LOGUEADO
};

// esto es del team join de exolent
stock const FIRST_JOIN_MSG[ ] = "#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[ ] = "#Team_Select_Spect";
stock const INGAME_JOIN_MSG[ ] = "#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[ ] = "#IG_Team_Select_Spect";
const iMaxLen = sizeof( INGAME_JOIN_MSG_SPEC );
stock const VGUI_JOIN_TEAM_NUM = 2;

public plugin_init( ) 
{
	register_plugin( PLUGIN, VERSION, AUTHOR );

	register_clcmd( "CREAR_USUARIO", "reg_usuario" );
	register_clcmd( "CREAR_PASSWORD", "reg_password" );
	register_clcmd( "LOGUEAR_USUARIO", "log_usuario" );
	register_clcmd( "LOGUEAR_PASSWORD", "log_password" );
	register_clcmd( "CAMBIAR_PASSWORD", "cambiar_password" );
	
	register_concmd( "say .account", "my_account" );
	
	register_clcmd( "chooseteam", "clcmd_changeteam" );
	register_clcmd( "jointeam", "clcmd_changeteam" );
	
	register_message( get_user_msgid( "ShowMenu" ), "message_ShowMenu" );
	register_message( get_user_msgid( "VGUIMenu" ), "message_VGUIMenu" );
	
	register_event( "HLTV", "event_round_start", "a", "1=0", "2=0" );
	
	RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn", true );
	
	g_maxplayers = get_maxplayers( );
	
	MySQLx_Init( );
}


public my_account(id) {
	
	formatex( g_menu, charsmax(g_menu), "%s^n\d-|\y Configuracion de Cuenta\d |-", g_info[1] );
	new menu = menu_create( g_menu, "handler_account" );
	
	menu_additem( menu, "Cambiar mi\r Contrasea", "1" );
	menu_additem( menu, "Cerrar Seccion", "2" );
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_setprop( menu, MPROP_EXITNAME, "Salir" );
	menu_display( id, menu, 0 );
} 

public handler_account( id, menu, item ) {

	if(item == MENU_EXIT) {
	
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	switch(item) {
	
		case 0: client_cmd( id, "messagemode CAMBIAR_PASSWORD" );
	}
	return PLUGIN_HANDLED;
}


public fw_PlayerSpawn( id )
{
	if( is_user_alive( id ) && g_estado[ id ] != LOGUEADO )
		set_task( 2.0, "go_login", id );
}

public go_login( id )
{
	user_silentkill( id );
	cs_set_user_team( id, CS_TEAM_SPECTATOR );
	show_login_menu( id );
}

public message_VGUIMenu( iMsgid, iDest, id )
{
	if( get_msg_arg_int( 1 ) != VGUI_JOIN_TEAM_NUM ) 
		return PLUGIN_CONTINUE;
	
	if( is_user_connected( id ) && g_estado[ id ] != LOGUEADO )
	{
		show_login_menu( id );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public message_ShowMenu( iMsgid, iDest, id )
{
	static sMenuCode[ iMaxLen ];
	get_msg_arg_string( 4, sMenuCode, sizeof( sMenuCode ) - 1 )
	
	if( equal( sMenuCode, FIRST_JOIN_MSG ) || equal( sMenuCode, FIRST_JOIN_MSG_SPEC ) || 
	equal( sMenuCode, INGAME_JOIN_MSG ) || equal( sMenuCode, INGAME_JOIN_MSG_SPEC ) )
	{
		if( is_user_connected( id )  && g_estado[ id ] != LOGUEADO )
		{
			show_login_menu( id );
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_changeteam( id )
{
	if( g_estado[ id ] != LOGUEADO )
	{
		show_login_menu( id );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public show_login_menu( id )
{
	formatex(g_menu, charsmax(g_menu), "%s^n\d-||\y Sistema de\r Registro\d ||-^nCrear una cuenta o ingresa los datos de una existente para unirte a la partida.^n", g_info[1]);
	new menu = menu_create( g_menu, "login_menu" );
	
	menu_additem( menu, "Crear una\r cuenta", "1" );
	menu_additem( menu, "Ingresar a una\r cuenta", "2" );
	menu_additem( menu, "Nuestros\r Servidores", "3" );
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_setprop( menu, MPROP_EXITNAME, "Salir");
	menu_display( id, menu, 0 );
}

public login_menu( id, menu, item ) {
	
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	switch(item) {
		case 0: client_cmd( id, "messagemode CREAR_USUARIO" );
		case 1: client_cmd( id, "messagemode LOGUEAR_USUARIO" );
	}
	return PLUGIN_HANDLED;
}

public reg_usuario( id )
{
	read_args( g_usuario[ id ], charsmax( g_usuario[ ] ) );
	remove_quotes( g_usuario[ id ] );
	trim( g_usuario[ id ] );
	
	if(strlen(g_usuario[ id ]) < 4) {
		client_cmd( id, "spk buttons/button10.wav" );
		show_login_menu( id );
		
		return PLUGIN_HANDLED;	
	}
				
	if(contain(g_usuario[ id ], " ") != -1) {
		client_cmd( id, "spk buttons/button10.wav" );
		show_login_menu( id );
		
		return PLUGIN_HANDLED;
		
	}
	
	static szQuery[ 64 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = REGISTRAR_USUARIO;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Usuario=^"%s^"", TABLES[0], g_usuario[ id ] );
	
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
	
	return PLUGIN_HANDLED;
}

public reg_password( id )
{
	read_args( g_password[ id ], charsmax( g_password[ ] ) );
	remove_quotes( g_password[ id ] );
	trim( g_password[ id ] );
	
	
	if(strlen(g_password[ id ]) < 4) {
		client_cmd( id, "spk buttons/button10.wav" );
		show_login_menu( id );
		
		return PLUGIN_HANDLED;	
	}
				
	if(contain(g_password[ id ], " ") != -1) {
		client_cmd( id, "spk buttons/button10.wav" );
		show_login_menu( id );
		
		return PLUGIN_HANDLED;
		
	}
	
	#if defined CHARACTERS_PROTECTION
	if( contain_special_characters( id, g_password[ id ], "la password" ) )
	{
		client_cmd( id, "spk buttons/button10.wav" );
		show_login_menu( id );
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = REGISTRAR_PASSWORD;
	
	hash_string( g_password[ id ], Hash_Md5, g_szHashPass[ id ], charsmax( g_szHashPass[] ) );
	formatex( szQuery, charsmax( szQuery ), "INSERT INTO %s (Usuario, Password, Personaje) VALUES (^"%s^", ^"%s^", ^"%s^")", TABLES[0], g_usuario[ id ], g_szHashPass[ id ], g_playername[ id ] );
	
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
	return PLUGIN_HANDLED;
}

public log_usuario( id )
{
	read_args( g_usuario[ id ], charsmax( g_usuario[ ] ) );
	remove_quotes( g_usuario[ id ] );
	trim( g_usuario[ id ] );

	static szQuery[ 64 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = LOGUEAR_USUARIO;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Usuario=^"%s^"", TABLES[0], g_usuario[ id ] );
	
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
	return PLUGIN_HANDLED;
}

public log_password( id )
{
	read_args( g_password[ id ], charsmax( g_password[ ] ) );
	remove_quotes( g_password[ id ] );
	trim( g_password[ id ] );
	
	#if defined CHARACTERS_PROTECTION
	if( contain_special_characters( id, g_password[ id ], "la password" ) )
	{
		client_cmd( id, "spk buttons/button10.wav" );
		show_login_menu( id );
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	static szQuery[ 64 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = LOGUEAR_PASSWORD;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Usuario=^"%s^"", TABLES[0], g_usuario[ id ] );
	
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
	return PLUGIN_HANDLED;
}

public guardar_datos( id )
{
	if( g_estado[ id ] != LOGUEADO )
		return;
	
	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = GUARDAR_DATOS;
	
	formatex( szQuery, charsmax( szQuery ), "UPDATE %s SET Experiencia='%d' WHERE id='%d'", TABLES[0], g_experiencia[ id ], g_id[ id ] );
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
}

public actualizar_personaje( id )
{
	if( g_estado[ id ] != LOGUEADO )
		return;
	
	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = GUARDAR_DATOS;
	
	formatex( szQuery, charsmax( szQuery ), "UPDATE %s SET Personaje='%s' WHERE id='%d'", TABLES[0], g_playername[ id ], g_id[ id ] );
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
}

public cargar_datos( id )
{
	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = CARGAR_DATOS;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT id, Experiencia FROM %s WHERE Usuario=^"%s^"", TABLES[0], g_usuario[ id ] );
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
}


public cambiar_password(id)
{
	read_args( g_password[ id ], charsmax( g_password[ ] ) );
	remove_quotes( g_password[ id ] );
	trim( g_password[ id ] );
	
	#if defined CHARACTERS_PROTECTION
	if( contain_special_characters( id, g_password[ id ], "la password" ) )
	{
		client_cmd( id, "spk buttons/button10.wav" );
		//show_login_menu( id );
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	static szQuery[ 64 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = NEW_PASSWORD;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Usuario=^"%s^"", TABLES[0], g_usuario[ id ] );
	
	SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
	return PLUGIN_HANDLED;
} 

// Javivi code:D
public DataHandler( failstate, Handle:Query, error[ ], error2, data[ ], datasize, Float:time )
{
	static id;
	id = data[ 0 ];
	
	if( !is_user_connected( id ) )
		return PLUGIN_HANDLED

	switch( failstate )
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_to_file( "SQL_LOG_TQ.txt", "Error en la conexion al MySQL [%i]: %s", error2, error );
			return PLUGIN_CONTINUE;
		}
		case TQUERY_QUERY_FAILED:
			log_to_file( "SQL_LOG_TQ.txt", "Error en la consulta al MySQL [%i]: %s", error2, error );
	}
	
	switch( data[ 1 ] )
	{
		case REGISTRAR_USUARIO:
		{
			if( !SQL_NumResults( Query ) )
				client_cmd( id, "messagemode CREAR_PASSWORD" );
			else
			{
				client_printc(id, "El usuario ya existe.");
				client_cmd( id, "spk buttons/button10.wav" );
				show_login_menu( id );
			}
		}
		
		case REGISTRAR_PASSWORD:
		{
			if( failstate < TQUERY_SUCCESS )
			{
				if( strfind( error, "Duplicate" ) != -1 )
				{
					if( strfind( error, "Usuario" ) != -1 )
						client_printc(id, "El usuario ya existe." );

					else if( strfind( error, "Personaje" ) != -1 )
						client_printc(id, "El nombre de personaje esta en uso." );
				}
				else
					client_printc(id, "Error al crear la cuenta. Intente nuevamente." );
				
				client_cmd( id, "spk buttons/button10.wav" );
				show_login_menu( id );
			}
			
			else
			{
				client_printc(id, "Tu^4 cuenta^1 ha sido creada correctamente." );
				client_printc(id, "Datos:^3 Usuario^1 -^4 %s^1 ||^3 Contrasea:^4 *****", g_usuario[ id ] );
				cargar_datos( id );
			}
			
		}
		
		case LOGUEAR_USUARIO:
		{
			if( SQL_NumResults( Query ) )
				client_cmd( id, "messagemode LOGUEAR_PASSWORD" );
			
			else
			{
				client_printc(id, "El usuario no existe." );
				client_cmd( id, "spk buttons/button10.wav" );
				show_login_menu( id );
			}
		}
		
		case LOGUEAR_PASSWORD:
		{
			if( SQL_NumResults( Query ) )
			{
				static szPass[ 33 ];
				SQL_ReadResult( Query, 2, szPass, charsmax( szPass ) );
				hash_string( g_password[ id ], Hash_Md5, g_szHashPass[ id ], charsmax( g_szHashPass[] ) );
				
				if( equal( g_szHashPass[ id ], szPass ) )
					cargar_datos( id );
				
				else
				{
					
					client_printc(id, "Contraseña incorrecta." );
					client_cmd( id, "spk buttons/button10.wav" );
					show_login_menu( id );
				}
			}
		}
		case NEW_PASSWORD:
		{
			if( SQL_NumResults( Query ) )
			{
				static szPass[ 33 ];
				SQL_ReadResult( Query, 2, szPass, charsmax( szPass ) );
				hash_string( g_password[ id ], Hash_Md5, g_szHashPass[ id ], charsmax( g_szHashPass[] ) );
				
				if( equal( g_szHashPass[ id ], szPass ) ) {
					client_printc(id, "Tu^4 contraseña nueva^1 es igual a la actual, vuelve a intentarlo con una distinta..." );
					client_cmd( id, "spk buttons/button10.wav" );
					client_cmd(id, "messagemode CAMBIAR_PASSWORD")
				}
				else
				{
					g_szHashPass[id] = szPass;
					
					read_args(szPass, charsmax(szPass));
					remove_quotes(szPass);
					trim(szPass);
					
					static szQuery[128], iData[2];
					iData[0] = id; 
					iData[1] = GUARDAR_DATOS;
		
					formatex(szQuery, charsmax(szQuery), "UPDATE %s SET Password=^"%s^" WHERE Usuario=^"%s^"", TABLES[0], g_szHashPass[id], g_usuario[id]);
					SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
				}
			}
		}
		case CARGAR_DATOS:
		{
			if( SQL_NumResults( Query ) )
			{
				g_id[ id ] = SQL_ReadResult( Query, 0 );
				
				g_experiencia[ id ] = SQL_ReadResult( Query, 1 );
				func_login_success( id );
			}
			
			else
			{
				client_printc(id, "Error al cargar los datos, intente nuevamente." );
				g_estado[id] = OFFLINE;
				show_login_menu( id );
			}
		}
		
		case GUARDAR_DATOS:
		{
			if( failstate < TQUERY_SUCCESS )
				client_printc(id, "Error en el guardado de datos." );
			
			else
				client_printc(id, "Datos Actualizados:^4 x Nivel^1 |^4 x Reset^1 |^4 x Crytal^1 |^4 x Hrs^1 |^4 x Mins", TAG );
		}
	}
	
	return PLUGIN_CONTINUE;
}


public func_login_success( id )
{
	// esto lo manda a un team random (con 1 a TT, con 2 a CT y creo que con 6 a SPEC.)
	static msg_block;
	msg_block = get_msg_block( id );
	set_msg_block( id, BLOCK_SET );
	engclient_cmd( id, "jointeam", "5" );
	engclient_cmd( id, "joinclass", "5" );
	set_msg_block( id, msg_block );
	
	g_estado[id] = LOGUEADO;
	actualizar_personaje( id );
	client_cmd( id, "name ^"%s^"", g_playername[ id ] );
}	

public event_round_start()
{
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(is_user_connected(i))
			guardar_datos(i)
	}
}		

public client_infochanged( id )
{
	if( !is_user_connected( id ) ) 
		return PLUGIN_HANDLED;
	
	static szNewname[ 33 ], szNewname2[ 33 ];
	get_user_info( id, "name", szNewname, charsmax( szNewname ) );
	get_user_name( id, szNewname2, charsmax(szNewname2 ) );
	
	if( ( !equal( g_playername[ id ], szNewname[ id ] ) || 
	!equal( g_playername[ id ], szNewname2[ id ] ) )  && g_estado[ id ] == LOGUEADO)
	{
		set_user_info( id, "name", g_playername[ id ] );
		client_cmd( id, "name ^"%s^"", g_playername[ id ] );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public client_putinserver( id )
{
	g_estado[ id ] = OFFLINE;
	
	get_user_name( id, g_playername[ id ], charsmax( g_playername[ ] ) );
	show_login_menu( id );
	
	set_task(1.5, "welcome_server", id);
}

public welcome_server(id) {
	client_printc(id, "Bienvenid@^4 %s^1 a^3 Zombie Escape^4 CSO^1 [^4 BOSS^1 +^4 EVO^1 ]", g_playername[id]);
	client_printc(id, "Foro:^4 www.ozutservers.tk^3 ||^1 Facebook:^4 www.facebook.com/groups/community.og/");
	client_printc(id, "Si necesitas ayuda o aclarar dudas escribe en say:^4 .help^1 o^4 /help");

}

public client_disconnected(id) guardar_datos(id);

public MySQLx_Init( )
{
	g_hTuple = SQL_MakeDbTuple( MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATEBASE );
	
	if( !g_hTuple ) 
	{
		log_to_file( "SQL_ERROR.txt", "No se pudo conectar con la base de datos." );
		return pause( "a" );
	}
	
	new szTabla[ 4000 ];
	new len = 0;
	
	len += formatex(szTabla[len], charsmax(szTabla) - len, "CREATE TABLE IF NOT EXISTS %s", TABLES[0]);
	len += formatex(szTabla[len], charsmax(szTabla) - len, "( id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Usuario varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Password varchar(35) NOT NULL, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Personaje varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Experiencia int(10) NOT NULL DEFAULT '0' )");
		
	SQL_ThreadQuery(g_hTuple, "QueryCreateTable", szTabla);
		
	arrayset(szTabla, EOS, sizeof( szTabla ) ); len = 0;
	
	len += formatex(szTabla[len], charsmax(szTabla) - len, "CREATE TABLE IF NOT EXISTS %s", TABLES[1]);
	len += formatex(szTabla[len], charsmax(szTabla) - len, "( idE INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "idDatos1 INT(50) NOT NULL,");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Personaje varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Experiencia int(10) NOT NULL DEFAULT '0' )");
		
	SQL_ThreadQuery(g_hTuple, "QueryCreateTable", szTabla);
		
	arrayset(szTabla, EOS, sizeof( szTabla ) ); len = 0;
	
	len += formatex(szTabla[len], charsmax(szTabla) - len, "CREATE TABLE IF NOT EXISTS %s", TABLES[2]);
	len += formatex(szTabla[len], charsmax(szTabla) - len, "( idEVO INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, ")
	len += formatex(szTabla[len], charsmax(szTabla) - len, "idDatos2 INT(50) NOT NULL,");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Personaje varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Experiencia int(10) NOT NULL DEFAULT '0' )");
		
	SQL_ThreadQuery(g_hTuple, "QueryCreateTable", szTabla);
		
	arrayset(szTabla, EOS, sizeof( szTabla ) ); len = 0;
		
	return PLUGIN_CONTINUE;
}

public QueryCreateTable(failstate, Handle:Query, error[], error2, data[], DataSize)
{
	switch ( failstate )
	{
		case TQUERY_CONNECT_FAILED: log_to_file("SQL_ERROR.txt", "No se pudo conectar con la base de datos [%i]: %s", error2, error)
		case TQUERY_QUERY_FAILED: log_to_file("SQL_ERROR.txt", "Error en Query de creacion de tablas [%i]: %s", error2, error)
	}
			
	return PLUGIN_HANDLED;
}

public plugin_end( )
	SQL_FreeHandle( g_hTuple );

/*================================================================================
 [Stocks]
=================================================================================*/

// Color Print //
stock client_printc(id, input[], any:...)
{	
	new count = 1, players[32]
	static msg[191]

	vformat(msg, charsmax(msg), input, 3)
	format(msg, charsmax(msg), "%s %s", g_info[0], msg)

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

// Special Characters //
stock contain_special_characters( id, const str[ ], const type[ ] )
{
	static iLen;
	
	iLen = strlen( str )
	
	for( new i = 0; i < iLen; i++ )
	{
		if( !isalpha( str[ i ] ) && !isdigit( str[ i ] ) )
		{
			client_printc(id, "Caracter especial invalido en %s: ^"%c^"", type, str[ i ] );
			console_print(id, "[O'G] Caracter especial invalido en %s: ^"%c^"", type, str[ i ] );
			
			return 1;
		}
	}
	
	return 0;
}
