/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Sample Extension
 * Copyright (C) 2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <isteamutils.h>

#undef DLL_EXPORT
#include <netadr.h>

#include "extension.h"
#include "util.h"
#include "CDetour/detours.h"

#define GAMECONFIG_FILE "connecthook"

ConnectHook g_ConnectHook;		/**< Global singleton for extension's main interface */

SMEXT_LINK(&g_ConnectHook);

CDetour *g_ConnectClientDetour = NULL;
IGameConfig *g_pGameConf = NULL;
IForward *g_pConnectForward = NULL;

typedef enum EAuthProtocol
{
	k_EAuthProtocolWONCertificate = 1,
	k_EAuthProtocolHashedCDKey = 2,
	k_EAuthProtocolSteam = 3,
} EAuthProtocol;

class CBaseServer;

void (*RejectConnection)(CBaseServer *, const netadr_t &address, const char *format, ...);


DETOUR_DECL_MEMBER10(ConnectClient,
	void *, netadr_s &, address, int, protocol, int, iChallange, int, nAuthProtocol,
	char const *, name, char const *, password, const char*, steamcert, int, len,
	void *, splitClients, bool, unknown1
) {
	if (nAuthProtocol != k_EAuthProtocolSteam)
	{
		return DETOUR_MEMBER_CALL(ConnectClient)(address, protocol, iChallange, nAuthProtocol, name, password, steamcert, len, splitClients, unknown1);
	}

	if (g_pConnectForward->GetFunctionCount() > 0)
	{
		uint64 ullSteamID = *(uint64 *)steamcert;
		CSteamID SteamID(ullSteamID);
		char rejectReason[255] = "";

		g_pConnectForward->PushString(name);
		g_pConnectForward->PushString(password);
		g_pConnectForward->PushString(address.ToString(true));
		g_pConnectForward->PushString(SteamID.Render());
		g_pConnectForward->PushStringEx(rejectReason, sizeof(rejectReason), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);

		cell_t result = Pl_Continue;
		g_pConnectForward->Execute(&result);

		if(result >= Pl_Handled)
		{
			RejectConnection((CBaseServer*)this, address, rejectReason);
			return NULL;
		}
	}

	return DETOUR_MEMBER_CALL(ConnectClient)(address, protocol, iChallange, nAuthProtocol, name, password, steamcert, len, splitClients, unknown1);
}

bool ConnectHook::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
	if (!gameconfs->LoadGameConfigFile(GAMECONFIG_FILE, &g_pGameConf, error, maxlength))
	{
		UTIL_Format(error, maxlength, "Could not read " GAMECONFIG_FILE ".txt: %s", error);
		return false;
	}

	if (!g_pGameConf->GetMemSig("CBaseServer_RejectConnection", (void **)(&RejectConnection)) || !RejectConnection)
	{
		UTIL_Format(error, maxlength, "Failed to find CBaseServer_RejectConnection function.\n");
		return false;
	}

	CDetourManager::Init(g_pSM->GetScriptingEngine(), g_pGameConf);
	return true;
}

void ConnectHook::SDK_OnAllLoaded()
{
	if (g_ConnectClientDetour == NULL)
	{
		g_ConnectClientDetour = DETOUR_CREATE_MEMBER(ConnectClient, "CBaseServer_ConnectClient");
		if (g_ConnectClientDetour)
		{
			g_ConnectClientDetour->EnableDetour();
		}
		else
		{
			g_pSM->LogError(myself, "Failed to setup ConnectClient detour");
		}
	}

	g_pConnectForward = forwards->CreateForward("OnClientPreConnect", ET_Event, 5, NULL, Param_String, Param_String, Param_String, Param_String, Param_String);
}

void ConnectHook::SDK_OnUnload()
{
	forwards->ReleaseForward(g_pConnectForward);

	if (g_ConnectClientDetour != NULL)
	{
		g_ConnectClientDetour->Destroy();
		g_ConnectClientDetour = NULL;
	}

	gameconfs->CloseGameConfigFile(g_pGameConf);
}

const char *CSteamID::Render() const // renders this steam ID to string
{
	static char szSteamID[64];

	switch (m_steamid.m_comp.m_EAccountType)
	{
	case k_EAccountTypeInvalid:
	case k_EAccountTypeIndividual:
		g_pSM->Format(szSteamID, sizeof(szSteamID), "STEAM_%u:%u:%u", 
			m_steamid.m_comp.m_EUniverse,
			(m_steamid.m_comp.m_unAccountID % 2) ? 1 : 0, (uint32)m_steamid.m_comp.m_unAccountID / 2
		);
		break;
	default:
		g_pSM->Format(szSteamID, sizeof(szSteamID), "%llu", ConvertToUint64());
	}
	
	return szSteamID;
}
