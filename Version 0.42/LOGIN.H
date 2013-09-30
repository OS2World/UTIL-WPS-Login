#define INCL_WIN
#define INCL_DOSSESMGR
#define INCL_WINDIALOGS
#define INCL_WINSHELLDATA
#define INCL_DOSPROCESS								/* Neu in Version 0.41               */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>

#define ID_MAIN									1000

/* Commands fÅr Prozessablauf                                              */

#define LOGINDLG_SUCCESSFUL 		0x1001
#define LOGINDLG_NOSUCCESS      0x1002
#define LOGINDLG_QUIT           0x1003

/* Magic Cookie fÅr die Benutzerdatei                                      */

#define COOKIE "Benutzerdatei fuer Login (c) 1994 Jens Glathe\0"

/* Konstanten fÅr die SchÅttelanimation                                    */
#define ShakeCount 2
#define ShakeDelay 2L
#define ShakeWidth DisplayWidth/30 /* DisplayWidth ist in ShakeWindow definert */

typedef struct _LoginRecordType
{
	char Username[255];
	char Password[255];
	char *UserFile;
	char *Program;
} LoginRecordType;


/* Prototyp fÅr die Fensterfunktion                                        */

MRESULT EXPENTRY LoginWinFunc(
		HWND hwnd,
		ULONG msg,
		MPARAM mp1,
		MPARAM mp2);

/* Main-Prototyp                                                           */

int main(int argc, char *argv[]);

/* Threadfunktion fÅr den Login- Dialog                                    */

#pragma linkage (LoginDlgThread,optlink)
VOID LoginDlgThread(void *LoginData);

/* Dialogfunktion-Prototyp                                                 */

MRESULT EXPENTRY LoginDlgProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2 );

/* Dienstfunktion                                                          */

VOID SetSysMenu(HWND hwnd);

/* Threadfunktion fÅr den Starter                                          */

#pragma linkage (StarterThread,optlink)
VOID StarterThread(void *LoginData);

/* Subfunktion des Starters                                                */

ULONG CheckForPassword(LoginRecordType *Data, FILE *Datei);

/* Subfunktion des Dialogfensters zum Zentrieren auf dem Bildschirm        */
void CenterWindow(HWND hwnd);

/* Subfunktion des Dialogfensters zum SchÅtteln (als thread)               */

#pragma linkage (ShakeWindow,optlink)
void ShakeWindow(void *Handle);

#pragma alloc_text(	temporary, LoginDlgProc, SetSysMenu, LoginDlgThread, StarterThread, CenterWindow)

