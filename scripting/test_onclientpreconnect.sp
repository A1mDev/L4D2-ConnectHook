#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <connecthook>
#define REQUIRE_EXTENSIONS


public Plugin:myinfo = 
{
	name = "ConnectHook Test Plugin",
	author = "spumer",
	description = "",
	version = "",
	url = "http://zo-zo.org/"
};


public Action:OnClientPreConnect(const String:name[], const String:password[], const String:ip[], const String:steamID[], String:rejectReason[255])
{
	PrintToServer("Name=%s, password=%s, IP=%s, steamID=%s", name, password, ip, steamID);
	FormatEx(rejectReason, sizeof(rejectReason), "%s", "#Valve_Reject_Server_Full");
	return Plugin_Stop;
}
