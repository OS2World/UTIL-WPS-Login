#ifndef _GLOBALUSER_H_
#define _GLOBALUSER_H_
#define INCL_DOSMEMMGR
#define INCL_DOSSEMAPHORES
#include "User.h"

@interface GlobalUser: User
{
}

-initialize: (char *) SharedName;

-free;

-(BOOL) alreadyLoggedIn;

- (char *) name;

- (char *) password;

- (char *) desktopfile;

- (char *) settingsfile;

- copy:(User *)Source;

- (puserdata) userData;

- setName: (char *) Data;

- setPassword: (char *) Data;

- setDesktopfile: (char *) Data;

- setSettingsfile: (char *) Data;

@end

#endif
