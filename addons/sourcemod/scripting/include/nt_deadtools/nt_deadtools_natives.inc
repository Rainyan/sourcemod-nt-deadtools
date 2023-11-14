// Double-include prevention
#if defined _nt_deadtools_natives_included_
    #endinput
#endif
#define _nt_deadtools_natives_included_

#if defined(FLATTEN_INCLUDE_PATHS)
#include "nt_deadtools_shared"
#else
#include "nt_deadtools/nt_deadtools_shared"
#endif


/**
  * Returns the nt_deadtools plugin natives API version.
  * The version number follows Semantic Versioning MAJOR.MINOR scheme,
  * except for the PATCH version being unused.
  *
  * @param[out]    minor      Optional SemVer MINOR version by reference.
  * @return                   SemVer MAJOR version.
**/
native int DeadTools_GetApiVersion(int& minor=0);

/**
  * Convenience function that throws a NativeError with help message
  * if the expected DeadTools MAJOR version mismatches what the server
  * is currently running.
  * Recommended to be called once, inside the OnAllPluginsLoaded forward.
  *
  * @param    expected_major    Expected SemVer MAJOR version.
  *                             Defaults to the value in nt_deadtools_shared.
  * @param    expected_minor    Expected SemVer MINOR version.
  *                             Defaults to the value in nt_deadtools_shared.
  * @param    log_minor_warning Whether to print a non-error warning to server
  *                             log on MINOR version violation. Defaults to
  *                             true.
  * @throws   NativeError       If API version violates SemVer.
**/
native void DeadTools_VerifyApiVersion(int expected_major=DEADTOOLS_VER_MAJOR,
        expected_minor=DEADTOOLS_VER_MINOR,
         log_minor_warning=true);

/**
  * Register the calling plugin to use DeadTools.
  * A plugin intending to call any DeadTools natives is required to first
  * call this native one time, with the exception of the following natives:
  * DeadTools_GetApiVersion, DeadTools_VerifyApiVersion.
  * Calling any other DeadTools natives without having registered the calling
  * plugin by calling this native is unspecified behaviour, and may throw an
  * error.
  *
  * @throws   NativeError     Throws if called multiple times by the same
  *                           caller.
**/
native void DeadTools_RegisterPlugin();

/**
  * Unregister the calling plugin from using DeadTools.
  * This is only required to be called by plugins that have previously called
  * the native DeadTools_RegisterPlugin, and then wish to unregister that
  * DeadTools association state without unloading that calling plugin; a plugin
  * that has called DeadTools_RegisterPlugin will be automatically unregistered
  * when it unloads.
  * Calling this native when the calling plugin is not registered by a
  * prior call to the DeadTools_RegisterPlugin native is a no-op.
**/
native void DeadTools_UnregisterPlugin();

/**
  * Return DeadTools state bit flags for a client.
  * See the "DEADTOOLS_FLAG..." defines for details.
  *
  * @param    client          Client index.
  * @throws   NativeError     Client index <1, >MaxClients, !IsClientInGame
  * @return                   DEADTOOLS_FLAG bitflags for this client.
**/
native int DeadTools_GetClientFlags(int client);

/**
  * Set whether a client can be "downed".
  * Downed is a special nt_deadtools state where the player feigns dead, but
  * can be potentially revived by another plugin calling DeadTools_Revive.
  *
  * @param    client          Client index.
  * @param    downable        Whether client can be downed.
  * @throws   NativeError     Client index <1, >MaxClients, !IsClientInGame
**/
native void DeadTools_SetIsDownable(int client, bool downable);

/**
  * Revives a downed client.
  * If client is not downed, this call is a no-op.
  *
  * @param    client          Client index.
  * @throws   NativeError     client <1, client >MaxClients, !IsClientInGame
**/
native void DeadTools_Revive(int client);
