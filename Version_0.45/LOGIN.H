#define INCL_WIN
#define INCL_DOSSESMGR
#define INCL_WINDIALOGS
#define INCL_WINSHELLDATA
#define INCL_DOSQUEUES
#define INCL_DOSERRORS
#define INCL_DOSPROCESS								/* Neu in Version 0.41               */

#include <objc/os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdarg.h>
#include "LogFile.h"
#include <objc/thread.h>

#define ID_MAIN									1000

/* Commands f�r Prozessablauf                                              */

#define LOGINDLG_SUCCESSFUL 		0x1001
#define LOGINDLG_NOSUCCESS      0x1002
#define LOGINDLG_QUIT           0x1003

/* Magic Cookie f�r die Benutzerdatei                                      */

#define COOKIE "Benutzerdatei fuer Login (c) 1994 Jens Glathe\0"

/* Konstanten f�r die Sch�ttelanimation                                    */
#define ShakeCount 10	/* ge�ndert am 17.7.1994                             */
#define ShakeDelay 2L
#define ShakeWidth DisplayWidth/30 /* DisplayWidth ist in ShakeWindow definert */

typedef struct _LoginRecordType
{
	char Username[255];
	char Password[255];
	char *UserFile;
	char *Program;
} LoginRecordType;


/* Prototyp f�r die Fensterfunktion                                        */

MRESULT EXPENTRY LoginWinFunc(
		HWND hwnd,
		ULONG msg,
		MPARAM mp1,
		MPARAM mp2);

/* Main-Prototyp                                                           */

int main(int argc, char *argv[]);

/* Threadfunktion f�r den Login- Dialog                                    */

VOID LoginDlgThread(void *LoginData);

/* Dialogfunktion-Prototyp                                                 */

MRESULT EXPENTRY LoginDlgProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2 );

/* Dienstfunktion                                                          */

VOID SetSysMenu(HWND hwnd);

/* Threadfunktion f�r den Starter                                          */

VOID StarterThread(void *LoginData);

/* Subfunktion des Starters                                                */

ULONG CheckForPassword(LoginRecordType *Data, FILE *Datei);

/* Subfunktion des Dialogfensters zum Zentrieren auf dem Bildschirm        */
void CenterWindow(HWND hwnd);

/* Subfunktion des Dialogfensters zum Sch�tteln (als thread)               */

void ShakeWindow(void *Handle);

/* Thread zu herunterfahren des Systems.                                   */
void ShutdownThread (void *Data);

/* Subfunktionen f�r die Protokollzwecke */
int logprintf(const char *format, ...);

#ifdef __LOGIN_TERMTEST_
/* Nur zu Debug-Zwecken */
void QuitThread(void *Data);
#endif

/* Ternination-Snooper */
void TermSnoop(void *Data);
