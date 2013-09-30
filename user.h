#ifndef _USER_H_
#define _USER_H_
#include <objc/os2.h>
#include <objc/Object.h>
#include <stdlib.h>

typedef struct _userdata
{
	BOOL	isDesktopAdmin;
	char	*name;
	char	*password;
	char	*desktopfile;
	char	*settingsfile;
} userdata;

typedef userdata *puserdata;

@interface User: Object
{
	puserdata	UserData;
}

-initialize;

-free;

- (BOOL) isEqual: (User *)Candidate;

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

