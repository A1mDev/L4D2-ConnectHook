#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <connecthook>

public Plugin myinfo =
{
	name = "Connecthook test plugin",
	author = "spumer, A1m`",
	description = "Connecthook extension check plugin",
	version = "1.0",
	url = "https://github.com/A1mDev/L4D2-ConnectHook"
};

public Action OnClientPreConnect(const char[] sName, const char[] sPassword, const char[] sIp, const char[] sSteamID, char sRejectReason[255]);
{
	PrintToServer("Name=%s, password=%s, IP=%s, steamID=%s", sName, sPassword, sIp, sSteamID);
	FormatEx(sRejectReason, sizeof(sRejectReason), "%s", "#Valve_Reject_Server_Full");

	return Plugin_Stop;
}
