// Double-include prevention
#if defined _nt_deadtools_natives_included_
    #endinput
#endif
#define _nt_deadtools_natives_included_

#include "nt_deadtools/nt_deadtools_shared"


/****
    * Returns the nt_deadtools plugin natives API version.
    * The version number follows Semantic Versioning MAJOR.MINOR scheme,
    * except for the PATCH version being unused.
    *
    * @param    int             Optional SemVer MINOR version by reference.
    * @return   int             SemVer MAJOR version.
****/
native int DeadTools_GetApiVersion(int& minor=0);

/****
    * Convenience function that throws a NativeError with help message
    * if the expected DeadTools MAJOR version mismatches what the server
    * is currently running.
    * Recommended to be called once, inside the OnAllPluginsLoaded forward.
    *
    * @param    int             Expected SemVer MAJOR version.
    *                           Defaults to the value in nt_deadtools_shared.
    * @param    int             Expected SemVer MINOR version.
    *                           Defaults to the value in nt_deadtools_shared.
    * @param    bool            Whether to print a non-error warning to server
    *                           log on MINOR version violation. Defaults to
    *                           true.
    * @throws   NativeError     If API version violates SemVer.
****/
native void DeadTools_VerifyApiVersion(int expected_major=DEADTOOLS_VER_MAJOR,
    int expected_minor=DEADTOOLS_VER_MINOR,
    bool log_minor_warning=true);

/****
    * Return nt_deadtools state bit flags for a client.
    * See the "DEADTOOLS_FLAG..." defines for details.
    *
    * @param    int             Client index.
    * @throws   NativeError     Client index <1, >MaxClients, !IsClientInGame
    * @return   int             DEADTOOLS_FLAG bitflags for this client.
****/
native int DeadTools_GetClientFlags(int client);

/****
    * Set whether a client can be "downed".
    * Downed is a special nt_deadtools state where the player feigns dead,
    * but can be potentially revived by another plugin calling
    * DeadTools_Revive.
    *
    * @param    int             Client index.
    * @throws   NativeError     Client index <1, >MaxClients, !IsClientInGame
****/
native void DeadTools_SetIsDownable(int client, bool downable);

/****
    * Revives a downed client.
    * If client is not downed, this call is a no-op.
    *
    * @param    int             Client index.
    * @throws   NativeError     client <1, client >MaxClients, !IsClientInGame
****/
native void DeadTools_Revive(int client);
