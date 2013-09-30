#include "GlobalUser.h"

@implementation GlobalUser: User

-initialize: (char *) SharedName
{
	[super init];
	return self;
}

-free
{
	return [super free];
}

-(BOOL) alreadyLoggedIn
{
	return FALSE;
}

- (BOOL) readAccess
{
	return FALSE;
}

- readEnd
{
	return self;
}

- (BOOL) writeAccess
{
	return FALSE;
}

- writeEnd
{
	return self;
}

@end