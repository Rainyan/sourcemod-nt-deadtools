// Double-include prevention
#if defined _nt_deadtools_shared_included_
    #endinput
#endif
#define _nt_deadtools_shared_included_

#define DEADTOOLS_VER_MAJOR 1
#define DEADTOOLS_VER_MINOR 0

/// NT_RESPAWNS bit flags
///
// Client is "downed". This is a special state used by nt_respawns to place
// the player in limbo between being fully dead or alive.
#define DEADTOOLS_FLAG_DOWN		(1 << 0)
// Whether this client enters RESPAWN_FLAG_DOWN state upon death.
// If not, the player will die normally and cannot be revived for that round.
#define DEADTOOLS_FLAG_DOWNABLE	(1 << 1)