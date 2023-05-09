#include < amxmodx >
#include < mysqlt >
#include < amxmisc >
#include < fakemeta >
#include < hamsandwich >

#define PLUGIN "Sistema de cuentas MySQL"
#define VERSION "1.1.15"
#define AUTHOR "r0ma"

new const g_info[][] = { 
	"^4[^1O'G^4]^1 ",
	"\d[\rO'G\d]\w ||\y Ozut Gamer`s\d ©\w CS-Oficial\d ||\y VE\d ||^n\d[\rO'G\d]\w GRUPO:\d www.fb.com/groups/ogc.cs/"
}

/* =================================================================================================
					MYSQL DATA
================================================================================================= */

new const MYSQL_HOST[] = "74.91.127.79"
new const MYSQL_USER[] = "27031"
new const MYSQL_PASS[] = "mtp9x3l7co"
new const MYSQL_DATEBASE[] = "ozutgamers"
new const MYSQL_TABLE[] =  "cuentas"
new const MYSQL_TABLE2[] =  "autologin"

new Handle:g_hTuple;
new g_maxplayers;
new g_estado;
new g_id[ 33 ];
new g_usuario[ 33 ][ 34 ];
new g_password[ 33 ][ 34 ];
new g_playername[ 33 ][ 33 ];
new g_experiencia[ 33 ];
new g_menu[512];
new g_szHashPass[ 33 ][ 34 ];
new g_szHashUser[ 33 ][ 34 ];
new g_rango[33];
new g_tokens[33];
new g_countplayers;
new g_hats[33];
new g_sync[3];
new g_steamid[ 33 ][ 33 ];

enum
{
	REGISTRAR_CUENTA,
	LOGUEAR_CUENTA,
	CARGAR_DATOS,
	GUARDAR_DATOS,
	AUTO_LOGIN_CHECKER,
	AUTO_LOGIN,
	AUTO_LOGIN_ADD
};

enum _:DATA
{
	NOMBRE[30],
	FRAGS
}

#define TASK_HUD 67521
#define ID_HUD (taskid - TASK_HUD)


new const Rangos[][DATA] = 
{
	{ "Unranked", 100 },
	{ "Silver I", 250 },
	{ "Silver II", 1000 },
	{ "Silver III", 1750 },
	{ "Silver IV", 2800 },
	{ "Silver Elite", 3600 },
	{ "Silver Elite Master", 4900 },
	{ "Gold Nova I", 6000 },
	{ "Gold Nova II", 8300 },
	{ "Gold Nova III", 10000 },
	{ "Gold Nova Master", 11400 },
	{ "Master Guardian I",13500 },
	{ "Master Guardian II", 15700 },
	{ "Master Guardian Elite", 18000 },
	{ "Distinguished Master Guardian", 21900 },
	{ "Legendary Eagle", 23000 },
	{ "Legendary Eagle Master", 25100 },
	{ "Supreme Master First Class", 27500 },
	{ "The Global Elite", 30000 },
	{ "Ozut Gamer`s", 100000 }
}

new const rangeexp[] = 
{ 
	0, 100, 250, 1000, 1750, 2800, 3600, 4900, 6000, 8300, 10000,
	11400, 13500, 15700, 18000, 21900, 23000, 25100, 27500, 30000, 100000
}


public plugin_init( )  {
	register_plugin( PLUGIN, VERSION, AUTHOR );

	register_event( "HLTV", "event_round_start", "a", "1=0", "2=0" );
	
	RegisterHam( Ham_Spawn, "player", "_PlayerSpawn", true );
	RegisterHam( Ham_Killed, "player", "_PlayerKilledPost", true);
	
	register_clcmd( "CREAR_USUARIO", "reg_usuario" );
	register_clcmd( "CREAR_PASSWORD", "reg_password" );
	register_clcmd( "LOGUEAR_USUARIO", "log_usuario" );
	register_clcmd( "LOGUEAR_PASSWORD", "log_password" );
	
	register_clcmd( "AUTOL_USUARIO", "auto_usuario" );
	register_clcmd( "AUTOL_PASSWORD", "auto_password" );
	

	register_clcmd( "chooseteam", "clcmd_changeteam" );
	register_clcmd( "jointeam", "clcmd_changeteam" );

	register_message( get_user_msgid( "ShowMenu" ), "message_ShowMenu" );
	register_message( get_user_msgid( "VGUIMenu" ), "message_VGUIMenu" );
	
	g_maxplayers = get_maxplayers( );
	MySQLx_Init( );
	
	g_sync[0] = CreateHudSyncObj()
	
	register_concmd("say .rangos", "_Show_ListRanges");
	register_concmd("say rangos", "_Show_ListRanges");
	register_concmd("say account", "_Show_account");
}

public client_authorized(id)
	get_user_authid(id, g_steamid[id], charsmax(g_steamid[]));

public client_putinserver( id ) {
	
	get_user_name( id, g_playername[ id ], charsmax( g_playername[ ] ) );
	set_task(2.0, "autologin_test", id);
	g_countplayers = 0
}

public client_disconnected(id) {
	
	g_countplayers--
	remove_task(id+TASK_HUD)
	if( g_estado & (1<<id) ) {
		guardar_datos( id );
		
		g_estado &= ~(1<<id);
	}
	
	g_usuario[ id ][ 0 ] = '^0';
	g_password[ id ][ 0 ] = '^0';
}

public event_round_start( ) {
	for( new i = 1; i <= g_maxplayers; i++ ) {
		if( g_estado & (1<<i) && is_user_connected( i ) )
			guardar_datos( i );
	}
}

public message_VGUIMenu( iMsgid, iDest, id ) {
	if( g_estado & (1<<id) ||  get_msg_arg_int( 1 ) != 2 ) 
	return PLUGIN_CONTINUE;
	
	show_login_menu( id );
	return PLUGIN_HANDLED;
}

public message_ShowMenu( iMsgid, iDest, id ) {
	if( g_estado & (1<<id) )
		return PLUGIN_CONTINUE;
	
	static sMenuCode[ 33 ];
	get_msg_arg_string( 4, sMenuCode, charsmax( sMenuCode ) );
	
	if( containi( sMenuCode, "Team_Select" ) != -1 ) {
		show_login_menu( id );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public clcmd_changeteam( id ) {
	
	if( ~g_estado & (1<<id) ) {
		show_login_menu( id );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public show_login_menu( id ) {
	
	formatex(g_menu, charsmax(g_menu), "%s^n\d-||\w Sistema de\r Registro\d ||-^n\wcrear una cuenta o ingresa los datos de una existente para unirte a la partida^n", g_info[1]);
	new menu = menu_create( g_menu, "login_menu" );
	
	menu_additem( menu, "Crear una\y cuenta", "1" );
	menu_additem( menu, "Ingresar a una\y cuenta^n", "2" );
	menu_additem( menu, "Nuestros\r Servidores", "3" );
	menu_additem( menu, "Lista de\r Baneados", "4" );
	menu_additem( menu, "Grupos\y Oficiales", "5" );
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_setprop( menu, MPROP_EXITNAME, "Salir");
	menu_display( id, menu, 0 );
	
	return PLUGIN_HANDLED;
}

public login_menu( id, menu, item ) {
	
	switch( item ) {
		case 0: client_cmd( id, "messagemode CREAR_USUARIO" );
		case 1: client_cmd( id, "messagemode LOGUEAR_USUARIO" );
	}
	
	return PLUGIN_HANDLED;
}

public reg_usuario( id ) {
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
	
	hash_string( g_usuario[ id ], Hash_Md5, g_szHashUser[ id ], charsmax( g_szHashUser[] ) );	
	client_cmd( id, "messagemode CREAR_PASSWORD" );
	
	return PLUGIN_HANDLED;
}

public reg_password( id ) {
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
	
	hash_string( g_password[ id ], Hash_Md5, g_szHashPass[ id ], charsmax( g_szHashPass[] ) );
	
	new szQuery[ 256 ], iData[ 2 ];
	
	iData[ 0 ] = id;
	iData[ 1 ] = REGISTRAR_CUENTA;
	
	get_user_name( id, g_playername[ id ], charsmax( g_playername[ ] ) );
	
	formatex( szQuery, charsmax( szQuery ), "INSERT INTO %s (Usuario, Password, Pj) VALUES (^"%s^", ^"%s^", ^"%s^")", MYSQL_TABLE, g_szHashUser[ id ], g_szHashPass[ id ], g_playername[ id ] );
	mysql_query(g_hTuple, "DataHandler", szQuery, iData, 2);
	
	return PLUGIN_HANDLED;
}

public log_usuario( id ) {
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
	
	hash_string( g_usuario[ id ], Hash_Md5, g_szHashUser[ id ], charsmax( g_szHashUser[] ) );	
	client_cmd( id, "messagemode LOGUEAR_PASSWORD" );
	
	return PLUGIN_HANDLED;
}

public log_password( id ) {
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
	
	hash_string( g_password[ id ], Hash_Md5, g_szHashPass[ id ], charsmax( g_szHashPass[] ) );
	
	new szQuery[ 128 ], iData[ 2 ];
	
	iData[ 0 ] = id;
	iData[ 1 ] = LOGUEAR_CUENTA;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Usuario=^"%s^" AND Password=^"%s^"", MYSQL_TABLE, g_szHashUser[ id ], g_szHashPass[ id ] );
	mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
	
	return PLUGIN_HANDLED;
}

public guardar_datos( id ) {
	new szQuery[ 128 ], iData[ 2 ];
	
	iData[ 0 ] = id;
	iData[ 1 ] = GUARDAR_DATOS;
	
	formatex( szQuery, charsmax( szQuery ), "UPDATE %s SET Experiencia='%d', Rangos='%d', Tokens='%d' WHERE id='%d'", MYSQL_TABLE, g_experiencia[ id ], g_rango[ id ], g_tokens[ id ], g_id[ id ] );
	mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
}

public actualizar_personaje( id )
{
	if( !is_user_connected( id ) ) return;
	
	get_user_name( id, g_playername[ id ], charsmax( g_playername[ ] ) );

	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = GUARDAR_DATOS;
	
	formatex( szQuery, charsmax( szQuery ), "UPDATE %s SET Pj=^"%s^" WHERE id='%d'", MYSQL_TABLE, g_playername[ id ], g_id[ id ] );
	mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
}

public autologin_test(id) {

	if( !is_user_connected( id ) ) return;
	
	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = AUTO_LOGIN_CHECKER;
	
	formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE steamid=^"%s^"", MYSQL_TABLE2, g_steamid[id] );
	mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
	
}

public DataHandler(failstate, error[], error2, data[], size, Float:queuetime){
	static id; id = data[ 0 ];
	
	if( !is_user_connected( id ) ) return;
	
	switch( failstate ) {
		case TQUERY_CONNECT_FAILED: {
			log_to_file( "SQL_LOG_TQ.txt", "Error en la conexion al MySQL [%i]: %s", error2, error );
			return;
		}
		case TQUERY_QUERY_FAILED:
			log_to_file( "SQL_LOG_TQ.txt", "Error en la consulta al MySQL [%i]: %s", error2, error );
	}
	
	switch( data[ 1 ] ) {
		case REGISTRAR_CUENTA: {
			
			if( failstate < TQUERY_SUCCESS ) {
				if( containi( error, "Usuario" ) != -1 )
					client_printc( id,"El usuario ya existe." );
				
				else if( containi( error, "Pj" ) != -1 )
					client_printc( id,"El nombre de personaje esta en uso." );
				else
					client_printc( id,"Error al crear la cuenta. Intente nuevamente." );
				
				client_cmd( id, "spk buttons/button10.wav" );
				show_login_menu( id );
			}
			else {
				client_printc( id, "Tu cuenta ha sido creada correctamente." );
				client_printc( id, "Datos:^3 Usuario^1 -^4 %s^1 ||^3 Contraseña:^4 %s", g_usuario[ id ], g_password[ id ] );

				new szQuery[ 128 ], iData[ 2 ];
				
				iData[ 0 ] = id;
				iData[ 1 ] = CARGAR_DATOS;
				
				formatex( szQuery, charsmax( szQuery ), "SELECT id FROM %s WHERE Usuario=^"%s^"", MYSQL_TABLE, g_szHashUser[ id ] );
				mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
			}
			
		}
		case LOGUEAR_CUENTA: {
		ttt	if( mysql_num_results() ) {
				
				g_id[ id ] = mysql_read_result(0)
				
				/* DATOS */
				g_experiencia[ id ] = mysql_read_result(4)
				g_rango[ id ] = mysql_read_result(5)
				g_tokens[ id ] = mysql_read_result(6)
				g_hats[ id ] = mysql_read_result(7)
				
				func_login_success( id );
				
			}
			else {
				client_printc( id, "Usuario o Contraseñ incorrecta." );
				client_cmd( id, "spk buttons/button10.wav" );
				
				show_login_menu( id );
			}
		}
		case CARGAR_DATOS: {
			if( mysql_num_results() ) {
				g_id[ id ] = mysql_read_result(0)
				
				g_experiencia[ id ] = g_rango[ id ] = g_tokens[ id ] = g_hats[ id ] = 0;
				func_login_success( id );
			}
			else {
				client_printc( id, "Error al cargar los datos, intente nuevamente." );
				show_login_menu( id );
			}
		}
		case GUARDAR_DATOS: {
			if( failstate < TQUERY_SUCCESS )
				client_printc(id, "Error en el guardado de datos." );
			
			else
				client_printc(id, "Datos Actualizados..." )
		}
	}
}

public DataHandler_Autologin(failstate, error[], errnum, data[], size, Float:queuetime) 
{
	if(failstate != TQUERY_SUCCESS) {
		log_to_file("Autologin.log",  "%s: [num: %d] [err: %s]", data, errnum, error);
		return PLUGIN_HANDLED;
	}
	
	static id; 
	id = data[0];
	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if(mysql_num_results()){
		/*new nombre[33], frags, muertes, headshots, faka, Opcion[256];
		new menu = menu_create("\r[BREAKING GAMING] \wTus Estadisticas", "menu_estadisticas");
		
		mysql_read_result(0, nombre, charsmax(nombre));
		
		frags = mysql_read_result(2);
		muertes = mysql_read_result(3);
		headshots = mysql_read_result(4);
		faka = mysql_read_result(5);
		
		formatex(Opcion, charsmax(Opcion), "Tu nombre: \d[%s]", nombre);
		menu_additem(menu, Opcion, "1");
	
		formatex(Opcion, charsmax(Opcion), "Tu SteamID: \d[%s]", g_steamid[id]);
		menu_additem(menu, Opcion, "2");
		
		formatex(Opcion, charsmax(Opcion), "Tus Frags: \d[%d]",frags);
		menu_additem(menu, Opcion, "3");
		
		formatex(Opcion, charsmax(Opcion), "Tus muertes: \d[%d]", muertes);
		menu_additem(menu, Opcion, "4");

		formatex(Opcion, charsmax(Opcion), "Tus headshots: \d[%d]", headshots);
		menu_additem(menu, Opcion, "5");
		
		formatex(Opcion, charsmax(Opcion), "Tus Kills con faka: \d[%d]^n^n", faka);
		menu_additem(menu, Opcion, "6");
		
		menu_additem(menu, "Actualizar Datos", "7");
		
		menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");
		menu_setprop(menu, MPROP_EXITNAME, "Salir");
		
		menu_display(id, menu, 0);*/
		
	}else{
		ColorChat(id, GREEN, "%s No tienes estadisticas", PREFIX);
	}
	return PLUGIN_CONTINUE;
}


/*
		case AUTO_LOGIN_CHECKER: {
			if( mysql_num_results() ) {
			
				static t_user[64], t_pw[64];
				
				t_user[ id ] = mysql_read_result(2)
				t_pw[ id ] = mysql_read_result(3)
				
				new szQuery[ 128 ], iData[ 2 ];
	
				iData[ 0 ] = id;
				iData[ 1 ] = LOGUEAR_CUENTA;
	
				formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE Usuario=^"%s^" AND Password=^"%s^"", MYSQL_TABLE, t_user[ id ], t_pw[ id ] );
				mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
			}
			else {
				client_printc(id, "Auto-login:^4 OFF" )
				show_login_menu( id );
			}
		}
		case AUTO_LOGIN: {
			if( mysql_num_results() ) {
				
				new status[64], menu;
				status[id] = mysql_read_result(1)
				formatex(g_menu, charsmax(g_menu), "%s^n\d----->\w Auto login:\r %s\d (\yActivado\d)", g_info[1], status);
				menu = menu_create(g_menu, "autologin_handler");
				
				menu_additem(menu, "Eliminar\r Autologin");
				
				menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
				menu_setprop( menu, MPROP_EXITNAME, "Salir");
				menu_display( id, menu, 0 );
	
				return;
			}
			else {
				
				new menu;
				
				formatex(g_menu, charsmax(g_menu), "%s^n\d----->\w Auto login:\r %s\d (\yDesactivado\d)", g_info[1], g_steamid[id]);
				menu = menu_create(g_menu, "autologin_handler_add");
				
				menu_additem(menu, "Activar\y Autologin");
				
				menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
				menu_setprop( menu, MPROP_EXITNAME, "Salir");
				menu_display( id, menu, 0 );
	
				return;
			}
		}
		case AUTO_LOGIN_ADD: {
		
			if( failstate < TQUERY_SUCCESS ) {
				if( containi( error, "steamid" ) != -1 )
					client_printc( id,"steamid ya se encuentra agregado." );
				
				else if( containi( error, "user" ) != -1 && containi( error, "password" ) != -1 )
					client_printc( id,"Esta cuenta se tiene auto login" );
				else
					client_printc( id,"Error al agregar steamid. Intente nuevamente." );
				
				client_cmd( id, "spk buttons/button10.wav" );
				//show_login_menu( id );
			}
			else {
				client_printc( id, "Existo!^4 SteamID^1 agregada...." );
				client_printc( id, "Cuenta:^4 %d^1 SteamID:^4 %s", g_id[id], g_steamid[id] );

				new szQuery[ 128 ], iData[ 2 ];
				
				iData[ 0 ] = id;
				iData[ 1 ] = CARGAR_DATOS;
				
				formatex( szQuery, charsmax( szQuery ), "SELECT id FROM %s WHERE Usuario=^"%s^"", MYSQL_TABLE, g_szHashUser[ id ] );
				mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
			}
		}*/

public autologin_handler(id, menu, item) {

	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public autologin_handler_add(id, menu, item) {

	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	switch(item) {
		case 0: client_cmd(id,"messagemode AUTOL_USUARIO");
	}
	
	return PLUGIN_HANDLED;
}

public auto_usuario( id ) {
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
	
	hash_string( g_usuario[ id ], Hash_Md5, g_szHashUser[ id ], charsmax( g_szHashUser[] ) );	
	client_cmd( id, "messagemode AUTOL_PASSWORD" );
	
	return PLUGIN_HANDLED;
}

public auto_password( id ) {
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
	
	hash_string( g_password[ id ], Hash_Md5, g_szHashPass[ id ], charsmax( g_szHashPass[] ) );
	
	
	static szQuery[ 128 ], iData[ 2 ];
	iData[ 0 ] = id;
	iData[ 1 ] = AUTO_LOGIN_ADD;
		
	formatex( szQuery, charsmax( szQuery ), "INSERT INTO %s (steamid, user, password) VALUES (^"%s^", ^"%s^", ^"%s^")", MYSQL_TABLE2, g_steamid[id], g_szHashUser[ id ], g_szHashPass[ id ] );
	mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
	/*
	new szQuery[ 256 ], iData[ 2 ];
	
	iData[ 0 ] = id;
	iData[ 1 ] = REGISTRAR_CUENTA;
	
	get_user_name( id, g_playername[ id ], charsmax( g_playername[ ] ) );
	
	formatex( szQuery, charsmax( szQuery ), "INSERT INTO %s (Usuario, Password, Pj) VALUES (^"%s^", ^"%s^", ^"%s^")", MYSQL_TABLE, g_szHashUser[ id ], g_szHashPass[ id ], g_playername[ id ] );
	mysql_query(g_hTuple, "DataHandler", szQuery, iData, 2);*/
	
	return PLUGIN_HANDLED;
}




public func_login_success( id ) {
	engclient_cmd( id, "jointeam", "5" );
	engclient_cmd( id, "joinclass", "5" );
	
	g_estado |= (1<<id);	
	g_countplayers+=1;

	actualizar_personaje( id );
	client_cmd( id, "name ^"%s^"", g_playername[ id ] );
}

public client_infochanged( id )
{
	if( !is_user_connected( id ) ) 
		return PLUGIN_HANDLED;
	
	static szNewname[ 33 ], szNewname2[ 33 ];
	get_user_info( id, "name", szNewname, charsmax( szNewname ) );
	get_user_name( id, szNewname2, charsmax(szNewname2 ) );
	
	if( ( !equal( g_playername[ id ], szNewname[ id ] ) || 
	!equal( g_playername[ id ], szNewname2[ id ] ) )  && g_estado == (1<<id))
	{
		set_user_info( id, "name", g_playername[ id ] );
		client_cmd( id, "name ^"%s^"", g_playername[ id ] );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public _Show_account(id) {

	formatex(g_menu, charsmax(g_menu), "%s", g_info[1]);
	new menu = menu_create(g_menu, "funct_account");
	
	menu_additem(menu, "\wCambiar contrasena")
	menu_additem(menu, "\wAuto Login\d (\y STEAM\d )")
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_setprop( menu, MPROP_EXITNAME, "Salir");
	menu_display( id, menu, 0 );
	
	return PLUGIN_HANDLED;
}

public funct_account(id, menu, item) {
	
	if(item == MENU_EXIT) {
	
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if(item == 1)
	{
		if( !is_user_connected( id ) ) return PLUGIN_HANDLED;
	
		static szQuery[ 128 ], iData[ 2 ];
		iData[ 0 ] = id;
		iData[ 1 ] = AUTO_LOGIN;
				
		formatex( szQuery, charsmax( szQuery ), "SELECT * FROM %s WHERE steamid=^"%s^"", MYSQL_TABLE2, g_steamid[id] );
		mysql_query( g_hTuple, "DataHandler", szQuery, iData, 2 );
	}

	return PLUGIN_HANDLED;
}



public MySQLx_Init( )
{
	g_hTuple = mysql_makehost(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATEBASE)
	
	if( !g_hTuple ) 
	{
		log_to_file( "SQL_ERROR.txt", "No se pudo conectar con la base de datos." );
		return pause( "a" );
	}
	
	new szTabla[ 4000 ];
	new len = 0;
	
	len += formatex(szTabla[len], charsmax(szTabla) - len, "CREATE TABLE IF NOT EXISTS %s", MYSQL_TABLE);
	len += formatex(szTabla[len], charsmax(szTabla) - len, "( id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Usuario varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Password varchar(35) NOT NULL, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Pj varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Experiencia int(10) NOT NULL DEFAULT '0', ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Rangos int(10) NOT NULL DEFAULT '0', ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Tokens int(10) NOT NULL DEFAULT '0', ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "Hats int(10) NOT NULL DEFAULT '0' )");
		
	mysql_query(g_hTuple, "QueryCreateTable", szTabla);
	
	arrayset(szTabla, EOS, sizeof( szTabla ) ); len = 0;
	
	len += formatex(szTabla[len], charsmax(szTabla) - len, "CREATE TABLE IF NOT EXISTS %s", MYSQL_TABLE2);
	len += formatex(szTabla[len], charsmax(szTabla) - len, "( id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "steamid varchar(32) NOT NULL UNIQUE KEY, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "user varchar(32) NOT NULL, ");
	len += formatex(szTabla[len], charsmax(szTabla) - len, "password varchar(32) NOT NULL )");
	
	mysql_query(g_hTuple, "QueryCreateTable", szTabla);
	
	arrayset(szTabla, EOS, sizeof( szTabla ) ); len = 0;
	
	return PLUGIN_CONTINUE;
}

public QueryCreateTable(failstate, error[], error2, data[], size, Float:queuetime)
{
	switch ( failstate )
	{
		case TQUERY_CONNECT_FAILED: log_to_file("SQL_LOG_TQ.txt", "Failed to connect to database [%i]: %s", error2, error)
		case TQUERY_QUERY_FAILED: log_to_file("SQL_LOG_TQ.txt", "Error on query for creating table [%i]: %s", error2, error)
	}
			
	return PLUGIN_HANDLED;
}

/* =================================================================================================
					SISTEMA DE RANGOS
================================================================================================= */

public show_hudstats(taskid) {
	
	new id = ID_HUD;
	new nextexp = rangeexp[(g_rango[id]+1)]

	if (!is_user_alive(id))	
		id = pev(id, pev_iuser2);

	set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), 0.16, 0.05, 1, 1.0, 1.0);

	/*if( g_countplayers < 2) {
		
		ShowSyncHudMsg(ID_HUD, g_sync[0], "\
			|•| Ozut Gamer`s Community^n\
			|•| Requiere más de 3 Jugadores...^n\
			|•| Rango: OFF^n\
			|•| Token(s): OFF")
	}
	else */
	if(id != ID_HUD) {
		
		ShowSyncHudMsg(ID_HUD, g_sync[0], "\
			|•| Ozut Gamer`s Community^n\
			|•| Espectando a: %s ( %s )^n\
			|•| Frag(s): %d / %d (%d%%)^n\
			|•| Rango: %s^n\
			|•| Pais: xxx",
			g_playername[id],
			get_user_flags(id) & ADMIN_IMMUNITY ? "ADMIN":"USUARIO",
			g_experiencia[id],
			Rangos[g_rango[id]][FRAGS],
			get_porcentaje(id, nextexp),
			Rangos[g_rango[id]][NOMBRE])
	} else {
		
		ShowSyncHudMsg(ID_HUD, g_sync[0],
			"|•| Ozut Gamer`s Community^n\
			|•| Frag(s): %d / %d (%d%%)^n\
			|•| Rango: %s^n\
			|•| Token(s): %d",
			g_experiencia[id], 
			Rangos[g_rango[id]][FRAGS], 
			get_porcentaje(id, nextexp),
			Rangos[g_rango[id]][NOMBRE],
			g_tokens[id])
	}	
}

public _PlayerKilledPost(v, a)
{
	/*if(g_countplayers < 2)
		return HAM_IGNORED;*/
		
	if(!is_user_connected(v) || !is_user_connected(a) || !a || a == v)
		return HAM_IGNORED;
		
	static iMulti;
	iMulti = 0;

	if(access(a, ADMIN_RCON)) iMulti = 6
	else if(access(a, ADMIN_LEVEL_D)) iMulti = 5
	else if(access(a, ADMIN_VOTE)) iMulti = 5
	else if(access(a, ADMIN_CHAT)) iMulti = 5
	else if(access(a, ADMIN_LEVEL_F)) iMulti = 4
	else if(access(a, ADMIN_LEVEL_C)) iMulti = 4
	else if(access(a, ADMIN_LEVEL_G)) iMulti = 3
	else if(access(a, ADMIN_LEVEL_H)) iMulti = 2
	else iMulti = 1
	
	//remove_task(v+TASK_HUD)

	if(get_pdata_int(v, 75, 5) == HIT_HEAD || get_user_weapon(a) == CSW_KNIFE || get_user_weapon(a) == CSW_HEGRENADE) {
		
		SetFrags(a, 2);
		g_tokens[a] += 2 * iMulti
		
	} else {
		if(get_user_flags(v) & ADMIN_IMMUNITY) {
			
			SetFrags(a, 2);
			g_tokens[a] += 2 * iMulti
			client_printc(a, "Ganancia^4 (x2)^1 por matar a un^4 Administrador.")
			
		} else {
			SetFrags(a, 1);
			g_tokens[a] += 1 * iMulti
		}
	}
	return HAM_IGNORED;
}

public _PlayerSpawn( id )
{	
	if(is_user_alive( id ))
		set_task(1.0, "show_hudstats", id+TASK_HUD, _, _, "b")
}


SetFrags(id, frags) {
	
	static iRank;
	iRank = g_rango[id];
	g_experiencia[id] += frags;
	
	while( g_experiencia[id] >= Rangos[g_rango[id]][FRAGS] && g_rango[id] < charsmax(Rangos))
		++g_rango[id];

	if(iRank < g_rango[id]) {
		client_printc(id, "Felicidades subiste al rango:^4 %s", Rangos[g_rango[id]][NOMBRE]);
		client_printc(id, "Comandos:^4 .stats^1 |^4 .rangos^1 |^4 .items")
	}
}

public _Show_ListRanges(id) {

	formatex(g_menu, charsmax(g_menu), "%s^n\d----->\w Lista de Rangos:\R\y", g_info[1]);
	new menu = menu_create(g_menu, "funct_listranges");
	
	for(new i = 0; i < sizeof Rangos; i++) {
		formatex(g_menu, charsmax(g_menu), "\y %s\r\R EXP\w %d", Rangos[i][NOMBRE], Rangos[i][FRAGS])
		menu_additem(menu, g_menu);
	}
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_setprop( menu, MPROP_EXITNAME, "Salir");
	menu_display( id, menu, 0 );
	
	return PLUGIN_HANDLED;
}

public funct_listranges(id, item, menu) {

	if(item == MENU_EXIT) {
	
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

	
/* =================================================================================================
					STOCKS
================================================================================================= */
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

// Porcentaje Frags //
stock get_porcentaje(id, nextexp) {
	if(g_rango[id] == 19) return 19;
	static diference, diference_exp
	diference = (nextexp - rangeexp[g_rango[id]])
	diference_exp = (g_experiencia[id] - rangeexp[g_rango[id]])
	return floatround(((diference_exp * 100.0) / diference))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/
