#include "login.h"

int main( int argc, char *argv[])
{
	StdApp 				*login_app=[[StdApp alloc] init];
	GlobalUser    *globaluser=[[GlobalUser alloc] initialize:
									SHARED_MEM_NAME];

	if ([globaluser alreadyLoggedIn]==TRUE)
	{
		StdDialog *configDialog=[[StdDialog alloc] initWithId: CONFIG_TITLE];
		[configDialog runModalFor: nil];
		[configDialog free];
	} else
	{
		StdDialog *loginDialog=[[StdDialog alloc] initWithId: LOGIN_TITLE];
		[loginDialog runModalFor: nil];
		[loginDialog free];
	}
	[globaluser free];
	[login_app free];
	return 0;
}
