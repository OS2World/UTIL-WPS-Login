// Header zur Klasse "LogFile", die das Deteihandling Åbernimmt. Im wesentlichen
// liest oder schreibt sie von/in einer/eine Pipe und schreibt/liest in eine
// Datei, die im schreibenden Fall nach jedem Schreiben wieder geschlossen wird.
// Der Modus wird durch das Flag "OperatingMode" festgelegt.

#ifndef __LOGFILE_H_
#define __LOGFILE_H_

#define INCL_DOS
#define INCL_DOSERRORS

#include <objc/os2.h>
#include <objc/Object.h>
#include <stdlib.h>
#include <string.h>
#include <objc/thread.h>

// Es folgen die Definitionen fÅr das Flag "OperatingMode"
#define LF_READ 0x0
#define LF_WRITE 0x1
#define LF_OVERWRITE_IF_EXISTS 0x2
#define LF_UNIQUENAME 0x4
#define LF_APPEND 0x8
#define LF_CACHING 0x10

typedef struct _LogfileData
{
	void		*FileBuf;
	ULONG		BufSize;
	ULONG		BytesTransferred;
	char 		*FileName;
	char		*UniqueName;
	HFILE		file;
	HPIPE		pipe;
	ULONG		OperatingMode;
	Object  *object_self;
} LogfileData;

@interface LogFile:Object
{
	LogfileData MyData;
	TID					tid;
	APIRET			rc;
}

- (TID) initWithPipe: (HPIPE) apipe andFileName: (char *) afilename
	andFlags: (ULONG) aflag andBufSize: (ULONG) abufsize;

-free;

@end

// Definition des Worker-Threads
void lfworker(void *Data);

// Subfunktionen des Worker-Threads
APIRET logloop(LogfileData *Data);

#endif
