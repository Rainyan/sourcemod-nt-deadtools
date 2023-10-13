#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#include <neotokyo>

#pragma semicolon 1
#pragma newdecls required
#include "nt_deadtools/nt_deadtools_shared"


#define PLUGIN_VERSION "1.0.0"

#define LIFE_ALIVE 0
#define OBS_MODE_NONE 0
#define DAMAGE_YES 2
#define TRAIN_NEW 0xc0
#define SOLID_BBOX 2
#define EF_NODRAW 0x020

#if SOURCEMOD_V_MAJOR > 1
#define SUPPORTS_DROP_BYPASSHOOKS
#endif
#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR > 12
#define SUPPORTS_DROP_BYPASSHOOKS
#endif
#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR == 12 && SOURCEMOD_V_REV >= 6961
#define SUPPORTS_DROP_BYPASSHOOKS
#endif

#if !defined(SUPPORTS_DROP_BYPASSHOOKS)
static Handle g_hForwardDrop = INVALID_HANDLE;
#endif

ConVar g_cNoWeaponsDespawn;

int _flags[NEO_MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "NT DeadTools",
	description = "Base plugin for managing player death status for Neotokyo",
	author = "Rain",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rainyan/sourcemod-nt-deadtools"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("DeadTools_GetApiVersion", DeadTools_GetApiVersion);
	CreateNative("DeadTools_VerifyApiVersion", DeadTools_VerifyApiVersion);
	CreateNative("DeadTools_GetClientFlags", DeadTools_GetClientFlags);
	CreateNative("DeadTools_SetIsDownable", DeadTools_SetIsDownable);
	CreateNative("DeadTools_Revive", DeadTools_Revive);
	return APLRes_Success;
}

public int DeadTools_GetApiVersion(Handle plugin, int num_params)
{
	SetNativeCellRef(2, DEADTOOLS_VER_MINOR);
	return DEADTOOLS_VER_MAJOR;
}

public int DeadTools_VerifyApiVersion(Handle plugin, int num_params)
{
	int expected_major = GetNativeCell(1);
	int expected_minor = GetNativeCell(2);
	bool log_minor_warning = GetNativeCell(3);

	enum { NAG_OK, NAG_ERR, NAG_WARN };
	int nag = NAG_OK;
	if (DEADTOOLS_VER_MAJOR != expected_major)
	{
		nag = NAG_ERR;
	}
	else if (log_minor_warning && expected_minor > DEADTOOLS_VER_MINOR)
	{
		nag = NAG_WARN;
	}

	if (nag != NAG_OK)
	{
		char caller_url[256];
		GetPluginInfo(plugin, PlInfo_URL, caller_url, sizeof(caller_url));
		char callee_url[256];
		GetPluginInfo(INVALID_HANDLE, PlInfo_URL, callee_url, sizeof(callee_url));
		char semver_url[] = "https://semver.org/";

		char caller_name[PLATFORM_MAX_PATH];
		GetPluginInfo(plugin, PlInfo_Name, caller_name, sizeof(caller_name));

		char formatmsg[] = "SemVer mismatch: plugin \"%s\" expected DeadTools \
API version %d.%d but the server DeadTools is running API version %d.%d. \
Please consider updating this plugin (or DeadTools itself) to versions that \
match the required pinned DeadTools API version. For more info, see the \
project homepages of the plugin ( %s ), the DeadTools plugin ( %s ), and \
SemVer ( %s ).";
		int msg_size = strlen(formatmsg) + strlen(caller_name) + strlen(caller_url)
			+ strlen(callee_url) + sizeof(semver_url) - 1;
		char[] msg = new char[msg_size];
		Format(msg, msg_size, formatmsg,
			caller_name, expected_major, expected_minor,
			DEADTOOLS_VER_MAJOR, DEADTOOLS_VER_MINOR,
			caller_url, callee_url, semver_url
		);
		if (nag == NAG_ERR)
		{
			ThrowNativeError(1, "%s", msg);
		}
		else
		{
			// This may not stricly be an error if we don't call incompatible
			// APIs, so just log to server instead of panicing
			LogMessage("%s", msg);
		}
	}

	return 0; // void
}

static void CheckNativeClientValidity(int client)
{
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(1, "Invalid client index: %d", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowNativeError(1, "Client is not in game: %d", client);
	}
}

public int DeadTools_GetClientFlags(Handle plugin, int num_params)
{
	int client = GetNativeCell(1);
	CheckNativeClientValidity(client);
	return _flags[client];
}

stock int ToggleBitFlag(int flags, int flag, bool enabled)
{
	return enabled ? flags | flag : flags & ~flag;
}

public int DeadTools_SetIsDownable(Handle plugin, int num_params)
{
	int client = GetNativeCell(1);
	CheckNativeClientValidity(client);
	bool enabled = GetNativeCell(2);
	int flag = DEADTOOLS_FLAG_DOWNABLE;
	_flags[client] = enabled ? (_flags[client] | flag) : (_flags[client] & ~flag);

	return 0; // void
}

public int DeadTools_Revive(Handle plugin, int num_params)
{
	int client = GetNativeCell(1);
	CheckNativeClientValidity(client);
	// nothing to do if client is not downed
	if (_flags[client] & DEADTOOLS_FLAG_DOWN)
	{
		Revive(client);
	}
	return 0; // void
}

void InitGameData()
{
	Handle gd = LoadGameConfigFile("neotokyo/deadtools");
	if (!gd)
	{
		SetFailState("Failed to load GameData");
	}
	DynamicDetour dd = DynamicDetour.FromConf(gd, "Fn_CNEOPlayer__OnPlayerDeath");
	if (!dd)
	{
		SetFailState("Failed to create detour");
	}
	if (!dd.Enable(Hook_Pre, PlayerKilled))
	{
		SetFailState("Failed to detour");
	}
	CloseHandle(gd);
}

public void OnAllPluginsLoaded()
{
	InitGameData();

	g_cNoWeaponsDespawn = FindConVar("sm_ntdrop_nodespawn");

#if !defined(SUPPORTS_DROP_BYPASSHOOKS)
	g_hForwardDrop = CreateGlobalForward("OnGhostDrop", ET_Event, Param_Cell);
#endif

	if (!HookEventEx("game_round_start", OnRoundStart))
	{
		SetFailState("Failed to hook event");
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		_flags[client] &= ~DEADTOOLS_FLAG_DOWN;
	}
}

public void OnClientDisconnect_Post(int client)
{
	_flags[client] &= ~DEADTOOLS_FLAG_DOWN;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEdict(entity))
	{
		return;
	}

	int i = 0;
	for (; i < sizeof(weapons_secondary); ++i)
	{
		if (StrEqual(classname, weapons_secondary[i]))
		{
			if (!SDKHookEx(entity, SDKHook_Touch, OnWeaponTouch))
			{
				SetFailState("SDK hook failed");
			}
			return;
		}
	}
	for (i = 0; i < sizeof(weapons_grenade); ++i)
	{
		if (StrEqual(classname, weapons_grenade[i]))
		{
			if (!SDKHookEx(entity, SDKHook_Touch, OnWeaponTouch))
			{
				SetFailState("SDK hook failed");
			}
			return;
		}
	}
	if (StrEqual(classname, "weapon_knife"))
	{
		if (!SDKHookEx(entity, SDKHook_Touch, OnWeaponTouch))
		{
			SetFailState("SDK hook failed");
		}
		return;
	}
	for (i = 0; i < sizeof(weapons_primary); ++i)
	{
		if (StrEqual(classname, weapons_primary[i]))
		{
			if (!SDKHookEx(entity, SDKHook_Touch, OnWeaponTouch))
			{
				SetFailState("SDK hook failed");
			}
			return;
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse,
	float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum,
	int& tickcount, int& seed, int mouse[2])
{
	if (_flags[client] & DEADTOOLS_FLAG_DOWN)
	{
		// Don't allow the downed to use buttons other than these
#define ALLOWED_BUTTONS (IN_SCORE)
		buttons &= ALLOWED_BUTTONS;
	}
	return Plugin_Continue;
}

public Action OnWeaponTouch(int entity, int other)
{
	// Did not touch client
	if (other < 1 || other > MaxClients)
	{
		return Plugin_Continue;
	}
	return (_flags[other] & DEADTOOLS_FLAG_DOWN)
		? Plugin_Handled : Plugin_Continue;
}

void DropWeapon(int client, int weapon)
{
// For versions of SM that don't support reporting the weapon drop via the call,
// we need to manually call the nt_ghostdrop forward.
// This is kind of nasty but necessary for other plugins that rely on this info.
#if defined(SUPPORTS_DROP_BYPASSHOOKS)
	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR, false);
#else
	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);

	Call_StartForward(g_hForwardDrop);
	Call_PushCell(client);
	Call_Finish();
#endif
}

public MRESReturn PlayerKilled(int client, DHookReturn hReturn, DHookParam hParams)
{
	/* The first & only parameter is a CTakeDamageInfo, with the layout:
	Vector	m_vecDamageForce; <-- offset 16 (4*sizeof(BYTE)); rest are contiguous
	Vector	m_vecDamagePosition;
	Vector	m_vecReportedPosition; // pos players are told damage is coming from
	EHANDLE	m_hInflictor;
	EHANDLE	m_hAttacker;
	float	m_flDamage;
	float	m_flMaxDamage;
	float	m_flBaseDamage; // dmg before skill level adjustments; for uniform dmg forces
	int		m_bitsDamageType;
	int		m_iDamageCustom;
	int		m_iDamageStats;
	int		m_iAmmoType;
	*/

	if (!(_flags[client] & DEADTOOLS_FLAG_DOWNABLE))
	{
		return MRES_Ignored; // Die normally
	}
	_flags[client] |= DEADTOOLS_FLAG_DOWN;

	// prevent "dying" multiple times while pretend dead
	SetEntityFlags(client, GetEntityFlags(client) | FL_GODMODE);

	SetInvisible(client, true);

	// If the cvar is null, we're probably running an older version of the
	// plugin which doesn't have this control exposed.
	// TODO: should then ideally detect whether the plugin is actually running
	bool must_kill_weps = ((g_cNoWeaponsDespawn == null) ||
		g_cNoWeaponsDespawn.BoolValue);

	// Need to strip guns because the player's attachments will remain visible,
	// (or alternatively need to drop them in the world).
	int weps_size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	char classname[12 + 1];
	for (int i = 0; i < weps_size; ++i)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1)
		{
			continue;
		}

		if (must_kill_weps)
		{
			if (!GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				continue;
			}

			// Don't destroy the ghost; instead drop it to the world
			if (StrEqual(classname, "weapon_ghost"))
			{
				DropWeapon(client, weapon);
				continue;
			}
			// Because most servers run plugins for weapons that never de-spawn,
			// explicitly destroy our guns to avoid overflowing the entity limit
			// for extended gameplay.
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
		else
		{
			DropWeapon(client, weapon);
		}
	}

	CreateRagdoll(client);

	int inflictor = hParams.GetObjectVar(1, 13 * 4, ObjectValueType_Ehandle);
	int attacker = hParams.GetObjectVar(1, 14 * 4, ObjectValueType_Ehandle);

	char weapon[32] = "world";
	if (client != attacker && attacker != 0 && IsValidEntity(inflictor))
	{
		if (!GetEntityClassname(inflictor, weapon, sizeof(weapon)))
		{
			SetFailState("Failed to get classname of attacker");
		}
	}

#if(0) // just for completeness sake; these aren't needed for this
	float dmg_force[3];
	hParams.GetObjectVarVector(1, 4 * 4, ObjectValueType_Vector, dmg_force);
	PrintToServer("dmg force: %f %f %f", dmg_force[0], dmg_force[1], dmg_force[2]);

	float dmg_pos[3];
	hParams.GetObjectVarVector(1, 7 * 4, ObjectValueType_Vector, dmg_pos);
	PrintToServer("damage pos: %f %f %f", dmg_pos[0], dmg_pos[1], dmg_pos[2]);

	float damage_reported_pos[3];
	hParams.GetObjectVarVector(1, 10 * 4, ObjectValueType_Vector,
		damage_reported_pos);
	PrintToServer("damage reported pos: %f %f %f",
		damage_reported_pos[0], damage_reported_pos[1], damage_reported_pos[2]);

	float damage = hParams.GetObjectVar(1, 15 * 4, ObjectValueType_Float);
	PrintToServer("damage: %f", damage);

	float max_damage = hParams.GetObjectVar(1, 16 * 4, ObjectValueType_Float);
	PrintToServer("max damage: %f", max_damage);

	// seems to return bogus values for us(?); unused by the mod?
	float base_damage = hParams.GetObjectVar(1, 17 * 4, ObjectValueType_Float);
	PrintToServer("base damage: %f", base_damage);

	int dmg_type = hParams.GetObjectVar(1, 18 * 4, ObjectValueType_Int);
	PrintToServer("bits damage type: %d", dmg_type);

	int dmg_custom = hParams.GetObjectVar(1, 19 * 4, ObjectValueType_Int);
	PrintToServer("damage custom: %d", dmg_custom);

	int dmg_stats = hParams.GetObjectVar(1, 20 * 4, ObjectValueType_Int);
	PrintToServer("damage stats: %d", dmg_stats);

	int ammo_type = hParams.GetObjectVar(1, 21 * 4, ObjectValueType_Int);
	PrintToServer("ammo type: %d", ammo_type);
#endif

	CreateFakeDeathEvent(
		GetClientUserId(client),
		GetClientUserId(attacker),
		weapon
	);

	int score = 1;
	if (GetClientTeam(client) == GetClientTeam(attacker))
	{
		score = -1;
	}
	SetPlayerXP(client, GetPlayerXP(client) + score);
	SetPlayerDeaths(client, GetPlayerDeaths(client) + 1);

	hReturn.Value = 0;

	return MRES_Supercede;
}

void SetInvisible(int client, bool is_invisible)
{
	if (is_invisible)
	{
		SetEntProp(client, Prop_Send, "m_fEffects",
			GetEntProp(client, Prop_Send, "m_fEffects") | EF_NODRAW);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_fEffects",
			GetEntProp(client, Prop_Send, "m_fEffects") & ~EF_NODRAW);
	}
}

static void Revive(int client)
{
	if (!(_flags[client] & DEADTOOLS_FLAG_DOWN))
	{
		ThrowError("Client %d was not down", client);
	}

	// Places the NT player in the world
	// TODO: figure out what this is
	static Handle call = INVALID_HANDLE;
	if (call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetSignature(SDKLibrary_Server,
			"\x56\x8B\xF1\x8B\x06\x8B\x90\xBC\x04\x00\x00\x57\xFF\xD2\x8B\x06",
			16
		);
		call = EndPrepSDKCall();
		if (call == INVALID_HANDLE)
		{
			ThrowError("Failed to prepare SDK call");
		}
	}
	SDKCall(call, client);

	SetEntProp(client, Prop_Send, "m_iObserverMode", OBS_MODE_NONE);
	SetEntProp(client, Prop_Send, "m_iHealth", 100);
	SetEntProp(client, Prop_Send, "m_lifeState", LIFE_ALIVE);
	SetEntProp(client, Prop_Send, "deadflag", 0);
	SetEntPropFloat(client, Prop_Send, "m_flDeathTime", 0.0);
	SetEntProp(client, Prop_Send, "m_bDucked", false);
	SetEntProp(client, Prop_Send, "m_bDucking", false);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", true);
	SetEntProp(client, Prop_Send, "m_nRenderFX", 0);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", 0.0);
	SetEntProp(client, Prop_Send, "m_nSolidType", SOLID_BBOX);
	SetEntProp(client, Prop_Data, "m_fInitHUD", 1);
	SetEntPropFloat(client, Prop_Data, "m_DmgTake", 0.0);
	SetEntPropFloat(client, Prop_Data, "m_DmgSave", 0.0);
	SetEntProp(client, Prop_Data, "m_afPhysicsFlags", 0);
	SetEntProp(client, Prop_Data, "m_bitsDamageType", 0);
	SetEntProp(client, Prop_Data, "m_bitsHUDDamage", -1);
	SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_YES);
	SetEntityMoveType(client, MOVETYPE_WALK);
	// declaring as variables for older sm compat
	float campvsorigin[3];
	float hackedgunpos[3] = { 0.0, 32.0, 0.0 };
	SetEntPropVector(client, Prop_Data, "m_vecCameraPVSOrigin", campvsorigin);
	SetEntPropVector(client, Prop_Data, "m_HackedGunPos", hackedgunpos);
	SetEntProp(client, Prop_Data, "m_bPlayerUnderwater", false);
	SetEntProp(client, Prop_Data, "m_iTrain", TRAIN_NEW);

	SetInvisible(client, false);
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_GODMODE);
	ChangeEdictState(client, 0);

	GivePlayerEquipment(client);

	_flags[client] &= ~DEADTOOLS_FLAG_DOWN;
}

static void GivePlayerEquipment(int client)
{
	static Handle call = INVALID_HANDLE;
	if (call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetSignature(SDKLibrary_Server,
			"\x83\xEC\x1C\x56\x8B\xF1\x8B\x86\xC0\x09\x00\x00", 12
		);
		call = EndPrepSDKCall();
		if (call == INVALID_HANDLE)
		{
			ThrowError("Failed to prepare SDK call");
		}
	}
	SDKCall(call, client);
}

static void CreateFakeDeathEvent(int victim_userid, int attacker_userid=0,
	const char[] weapon="world", int icon=0)
{
	Event event = CreateEvent("player_death", true);
	if (event == null)
	{
		ThrowError("Failed to create event");
	}

	event.SetInt("userid", victim_userid);
	event.SetInt("attacker", attacker_userid);
	event.SetString("weapon", weapon);
	event.SetInt("icon", icon);

	event.Fire();
}

// TODO: support gibbing
static void CreateRagdoll(int client)
{
	if (client < 0 || client >= MaxClients)
	{
		ThrowError("Invalid client index: %d", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowError("Client is not in game: %d", client);
	}

	int team = GetClientTeam(client);
	if (team != TEAM_JINRAI && team != TEAM_NSF)
	{
		ThrowError("Unexpected team %d", team);
	}

	static Handle call = INVALID_HANDLE;
	if (call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetSignature(SDKLibrary_Server,
			"\x53\x56\x57\x8B\xF9\x8B\x87\x1C\x0E\x00\x00", 11);
		call = EndPrepSDKCall();
		if (call == INVALID_HANDLE)
		{
			ThrowError("Failed to prepare SDK call");
		}
	}
	SDKCall(call, client);
}