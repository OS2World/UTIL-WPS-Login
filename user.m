#include "User.h"

@implementation User: Object

-initialize
{
	[super init];
	if ((UserData=(puserdata)malloc(sizeof(userdata)))==NULL)
	{
		return nil;
	} else
	{
		UserData->name=NULL;
		UserData->password=NULL;
		UserData->desktopfile=NULL;
		UserData->settingsfile=NULL;
	}
	return self;
}

-free
{
	free(UserData);
	return [super free];
}

- (BOOL) isEqual: (User *)Candidate
{
	if (strcmp(UserData->name,[Candidate name])==0)
	{
		if (strcmp(UserData->password,[Candidate password])==0)
		{
			return TRUE;
		} else return FALSE;
	} else return FALSE;
	return FALSE;
}

- (char *) name
{
	return UserData->name;
}

- (char *) password
{
	return UserData->password;
}

- (char *) desktopfile
{
	return UserData->desktopfile;
}

- (char *) settingsfile
{
	return UserData->settingsfile;
}

- copy:(User *)Source
{
	memcpy(UserData,[Source userData],sizeof(userdata));
	return self;
}

- (puserdata) userData
{
	return UserData;
}

- setName: (char *) Data
{
	UserData->name=(char *)realloc(UserData->name,strlen(Data)+1);
	memcpy(UserData->name, Data, strlen(Data)+1);
	return self;
}

- setPassword: (char *) Data
{
	UserData->password=(char *)realloc(UserData->password,strlen(Data)+1);
	memcpy(UserData->password, Data, strlen(Data)+1);
	return self;
}

- setDesktopfile: (char *) Data
{
	UserData->desktopfile=(char *)realloc(UserData->desktopfile,strlen(Data)+1);
	memcpy(UserData->desktopfile, Data, strlen(Data)+1);
	return self;
}

- setSettingsfile: (char *) Data
{
	UserData->settingsfile=(char *)realloc(UserData->settingsfile,strlen(Data)+1);
	memcpy(UserData->settingsfile, Data, strlen(Data)+1);
	return self;
}


@end

