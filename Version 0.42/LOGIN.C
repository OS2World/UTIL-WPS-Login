#include "login.h"
#include "logindlg.h"

/* Globale Variablen                                                       */

HAB								hab;
HWND 							hwndRahmen		=0L;
LoginRecordType		LoginDaten;

TID Dialog_tid;
TID Starter_tid;

int main(int argc, char *argv[])
{
	HMQ			hmq;
	HWND		hwndAnwendung =0L;
	QMSG		qmsg;
	BOOL		success;
	APIRET	rc;                         /* Version 0.2 4.1.1994              */
	ULONG		Fensterstil	=	FCF_TITLEBAR|
												FCF_MINMAX|
												FCF_SYSMENU|
/*												FCF_TASKLIST|				Version 0.1 01.01.1994*/
												FCF_SIZEBORDER;

	hab=WinInitialize(0);

	hmq=WinCreateMsgQueue(hab,0);

	rc=WinRegisterClass(
		hab,
		(PSZ)"login window",
		(PFNWP)LoginWinFunc,
		CS_SIZEREDRAW,
		0);

	hwndRahmen=WinCreateStdWindow(
		HWND_DESKTOP,
		0L,
		&Fensterstil,
		"login window",
		"login window",
		0,
		(HMODULE)0L,
		ID_MAIN,
		&hwndAnwendung);

	if (argc<3){
		WinMessageBox(
			HWND_DESKTOP,
			HWND_DESKTOP,
			"login utility version 0.42 (05-10-94) by Jens Glathe\n\nusage: login <userfile> <workplace shell>\n",
			"Information",
			0,
			MB_OK|MB_INFORMATION);
	}
	else{

		/* Zuweisungen fÅr die Starter-Task ausfÅhren                          */

		LoginDaten.UserFile=argv[1];
		LoginDaten.Program=argv[2];

		if(Dialog_tid=_beginthread(LoginDlgThread,NULL,0x2000,&LoginDaten)==-1)
		{
			WinMessageBox(
				HWND_DESKTOP,
				HWND_DESKTOP,
				"Could not start login dialog thread. ",
				"Error",
				0,
				MB_OK|MB_ERROR);
			WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
		}

		while(WinGetMsg(hab, &qmsg, 0L, 0, 0))
			WinDispatchMsg(hab, &qmsg);

		rc=WinDestroyWindow(hwndRahmen);
		rc=WinDestroyMsgQueue(hmq);
		rc=WinTerminate(hab);
	return(rc);
	}
}

/* Rahmenfenster                                                           */

MRESULT EXPENTRY LoginWinFunc(
		HWND hwnd,
		ULONG msg,
		MPARAM mp1,
		MPARAM mp2)
{

	switch(msg)
	{
		case WM_CREATE:
		break;

		case WM_COMMAND:
		{
			USHORT command;
			command=SHORT1FROMMP(mp1);
			switch(command)
			{
				case LOGINDLG_SUCCESSFUL:
				{
					if(Starter_tid=_beginthread(StarterThread,NULL,0x3000,&LoginDaten)==-1)
					{
						WinMessageBox(
							HWND_DESKTOP,
							HWND_DESKTOP,
							"Could not start starter thread. ",
							"Error",
							0,
							MB_OK|MB_ERROR);
						WinPostMsg(hwnd, WM_QUIT, (MPARAM)0,(MPARAM)0);
					}
					return (MRESULT)TRUE;
				}
				break;

				default:
					return WinDefWindowProc(hwnd,msg,mp1,mp2);
			}
			break;
		}

		case WM_ERASEBACKGROUND:
			return (MRESULT) TRUE;

		case WM_PAINT:
			return WinDefWindowProc(hwnd,msg,mp1,mp2);

		case WM_CLOSE:
			WinPostMsg(hwnd, WM_QUIT, (MPARAM)0,(MPARAM)0);
			return (MRESULT) TRUE;
		break;

		default:
			return WinDefWindowProc(hwnd,msg,mp1,mp2);
	}
	return (MRESULT) FALSE;
}

/* Login-Dialog                                                            */

MRESULT EXPENTRY LoginDlgProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2 )
{
	static	LoginRecordType *LoginData;
	static	BOOL Enter_Pressed_The_First_Time=FALSE;

	switch ( msg )
	{
		case WM_INITDLG:                    /* Zeiger merken                   */
			LoginData=mp2;
			SetSysMenu(hwnd);             		/* remove unused sys. menu items   */
			CenterWindow(hwnd);
			return (MRESULT) FALSE;
			break;

		/* Spezialbehandlung des ersten ENTER's                                */
		case WM_CHAR:
			{
				USHORT fskeyflags = SHORT1FROMMP( mp1);
				if (fskeyflags&KC_CHAR)
				{
					if (((SHORT1FROMMP( mp2)==13)||
						(SHORT1FROMMP( mp2)==9))&&
						!Enter_Pressed_The_First_Time)
					{
						Enter_Pressed_The_First_Time=TRUE;
						WinSetFocus(HWND_DESKTOP,WinWindowFromID( hwnd, LOGIN_PASSWORD));
						return (MRESULT) TRUE;
					}
				}
				return WinDefDlgProc( hwnd, msg, mp1, mp2 );
			}
			break;

		case WM_COMMAND:                    /* Posted by pushbutton or key     */
			/*
			 * PM sends a WM_COMMAND message when the user presses either
			 * the Enter or Escape pushbuttons.
			 */
			switch( SHORT1FROMMP( mp1 ) )     /* Extract the command value       */
			{
				case DID_OK:                    /* The Enter pushbutton or key.    */
																				/* WinQueryWindowText copies the   */
																				/* contents of the entry fields    */
				{
					WinQueryWindowText( WinWindowFromID( hwnd, LOGIN_NAME ),
															255,
															LoginData->Username );

					WinQueryWindowText( WinWindowFromID( hwnd, LOGIN_PASSWORD ),
															255,
															LoginData->Password );
					/* Vollzug an das Hauptprogramm melden                           */
					WinPostMsg(hwndRahmen, WM_COMMAND, (MPARAM)LOGINDLG_SUCCESSFUL,
						(MPARAM) 0);
					/*WinDismissDlg( hwnd, TRUE );*/  /* Removes the dialog box       */
					return (MRESULT) FALSE;
					/* beenden                                                       */
				}
				break;

				case DID_CANCEL:         /* The Cancel pushbutton or Escape key    */
				{

					WinPostMsg(hwnd, WM_COMMAND, (MPARAM)LOGINDLG_NOSUCCESS,
						(MPARAM) 0);
					/*WinDismissDlg( hwnd, TRUE );*/  /* Removes the dialog box       */
					return (MRESULT) FALSE;
				}
				break;

				case LOGINDLG_QUIT:					 /* Das war's */
				{
					WinDismissDlg( hwnd, TRUE );  /* Removes the dialog box       */
					return (MRESULT) FALSE;
				}
				break;

				case LOGINDLG_NOSUCCESS:		/* Das Fenster soll sich schÅtteln   */
				{
					LoginData->Username[0]='\0';
					LoginData->Password[0]='\0';
					WinSetWindowText(WinWindowFromID( hwnd, LOGIN_NAME ),
													 LoginData->Username );
					WinSetWindowText(WinWindowFromID( hwnd, LOGIN_PASSWORD ),
													 LoginData->Password );
					WinSetFocus(HWND_DESKTOP,WinWindowFromID( hwnd, LOGIN_NAME ));
					Enter_Pressed_The_First_Time=FALSE;

					/* Jetzt kommt die Animation. */
					_beginthread(ShakeWindow,NULL,0x1000,(void *)hwnd);
					return (MRESULT) FALSE;
				}

				default:
					break;
			}
			break;
		default:
      /*
       * Any event messages that the dialog procedure has not processed
       * come here and are processed by WinDefDlgProc.
       * This call MUST exist in your dialog procedure.
       */
			return WinDefDlgProc( hwnd, msg, mp1, mp2 );
	}
	return (MRESULT) FALSE;
}

VOID LoginDlgThread(void *LoginData)
{
	APIRET	rc;
	HMQ			hmqLoginDlgThread;					/* Sonst lÑuft's nicht               */

	hmqLoginDlgThread=WinCreateMsgQueue(hab,0);

	WinDlgBox(	HWND_DESKTOP,						/* Place anywhere on desktop         */
							hwndRahmen,							/* Owned by frame                    */
							LoginDlgProc,						/* Address of dialog procedure       */
							(HMODULE)0,							/* Module handle                     */
							LOGIN_TITLE,						/* Dialog identifier in resource     */
							LoginData);							/* Initialization data               */

	rc=WinDestroyMsgQueue(hmqLoginDlgThread);
}

VOID StarterThread(void *LoginData)
{
	FILE 							*Benutzerdatei;
	LoginRecordType   *Logindata=LoginData;
	char							TestString[255];
	STARTDATA					LoginExeDaten={ /*Variablen fÅr die zu startende Sitzg.*/
		32,
		SSF_RELATED_CHILD,
		SSF_FGBG_FORE,
		SSF_TRACEOPT_NONE,
		0L,
		0L,
		0L,
		0L,
		0L,
		SSF_INHERTOPT_PARENT,
		SSF_TYPE_DEFAULT};

	ULONG             LoginExeID;
	PID								LoginExePID;
	HMQ 							hmqStarterThread;
	APIRET 						rc;
	BOOL							success;
	PRFPROFILE				profiledata;

	LoginExeDaten.PgmTitle=Logindata->Program;
	LoginExeDaten.PgmName=Logindata->Program;

	hmqStarterThread=WinCreateMsgQueue(hab,0);

	if (Benutzerdatei=fopen(Logindata->UserFile,"r")){
		fgets(TestString,254,Benutzerdatei);
		TestString[strlen(TestString)-1]='\0';
		if (strcmp(TestString, COOKIE)==0){

			/* Nach dem Passwort suchen                                          */

			if (CheckForPassword(LoginData,Benutzerdatei)){

				/* Hier geschieht das Umschalten der INI-Datei                     */

				if (fgets(TestString,254,Benutzerdatei)!=NULL){
					TestString[strlen(TestString)-1]='\0';

					/* FÅr profiledata mu· Speicher alloziert werden                 */
					profiledata.pszUserName=malloc(256);
					profiledata.pszSysName=malloc(256);
					profiledata.cchUserName=256;
					profiledata.cchSysName=256;

					if (success=PrfQueryProfile(hab,&profiledata)==TRUE){

						/* Der Unterschied ist klein, aber fein! WinSendMsg kehrt erst */
						/* nach Abarbeitung der Message zurÅck. :) Damit wird das Dia- */
						/* logfenster vor dem Starten der Applikation geschlossen (sieht*/
						/* schneller aus).                                              */

						WinSendMsg(WinWindowFromID(HWND_DESKTOP,LOGIN_TITLE), WM_COMMAND, (MPARAM)LOGINDLG_QUIT,
							(MPARAM)0);

						strcpy(profiledata.pszUserName,TestString);
						profiledata.cchUserName=strlen(profiledata.pszUserName);

						PrfReset(hab,&profiledata);   /* Das eigentliche Umsetzen      */

						/* allozierten Speicher wieder freigeben                       */

						free(profiledata.pszUserName);
						free(profiledata.pszSysName);

						if (rc=DosStartSession(&LoginExeDaten,&LoginExeID,&LoginExePID)){
							WinMessageBox(
								HWND_DESKTOP,
								HWND_DESKTOP,
								"Could not start workplace application",
								"Error",
								0,
								MB_OK|MB_ERROR);
							WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
						}
					}
				}
			} else {
				WinPostMsg(WinWindowFromID(HWND_DESKTOP,LOGIN_TITLE), WM_COMMAND, (MPARAM)LOGINDLG_NOSUCCESS,
					(MPARAM)0);
			}
		} else{
			WinPostMsg(WinWindowFromID(HWND_DESKTOP,LOGIN_TITLE), WM_COMMAND, (MPARAM)LOGINDLG_QUIT,
				(MPARAM)0);
			WinMessageBox(
				HWND_DESKTOP,
				HWND_DESKTOP,
				"User Data file not found or corrupted",
				"Error",
				0,
				MB_OK|MB_ERROR);
			WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
		}
	} else {
		WinPostMsg(WinWindowFromID(HWND_DESKTOP,LOGIN_TITLE), WM_COMMAND, (MPARAM)LOGINDLG_QUIT,
			(MPARAM)0);
		WinMessageBox(
			HWND_DESKTOP,
			HWND_DESKTOP,
			"User Data file not found or corrupted",
			"Error",
			0,
			MB_OK|MB_ERROR);
		WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
	}
	rc=WinDestroyMsgQueue(hmqStarterThread);
	fclose(Benutzerdatei);
}

/* Passwort und Benutzername suchen, Dateiname zurÅckliefern               */

ULONG CheckForPassword(LoginRecordType *Data, FILE *Datei)
{
	char TestString[255];

	for(;;){
		if (fgets(TestString,254,Datei)!=NULL){
			TestString[strlen(TestString)-1]='\0';
			if (strcmp(TestString,Data->Username)==0){
				if (fgets(TestString,254,Datei)!=NULL){
					TestString[strlen(TestString)-1]='\0';
					if (strcmp(TestString,Data->Password)==0){
						return 1L;
					}
				} else return 0L;
			} else {
				if (fgets(TestString,254,Datei)==NULL) return 0L;	/* Umgehung*/
				if (fgets(TestString,254,Datei)==NULL) return 0L;
			}
		} else return 0L;
	}
}

/* Subfunktion des Dialogfensters zum Zentrieren auf dem Bildschirm        */
void CenterWindow(HWND hwnd)
{
	SHORT		SetPos_x, SetPos_y;
	SHORT		DisplayWidth, DisplayDepth;
	SWP			swp;

	DisplayWidth = WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN);
	DisplayDepth = WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN);
	WinQueryWindowPos(hwnd,(PSWP)&swp);
	SetPos_x=(SHORT)((DisplayWidth-swp.cx)/2);
	SetPos_y=(SHORT)((DisplayDepth-swp.cy)/2);
	WinSetWindowPos(hwnd, HWND_TOP, SetPos_x, SetPos_y, 0, 0, SWP_MOVE);
}

/* Subfunktion des Dialogfensters zum SchÅtteln (als thread) */
void ShakeWindow(void *Handle)
{
	HMQ     hmqShakeWindow;
	SHORT		SetPos_x, SetPos_y, SetPos_x_left, SetPos_x_right;
	SHORT		DisplayWidth, DisplayDepth;
	SWP			swp;
	ULONG   i;
	APIRET	rc;													/* Version 0.41                      */

	rc=DosSetPriority(									/* PrioritÑt heraufsetzten fÅrs SchÅtteln */
		PRTYS_THREAD,
		PRTYC_TIMECRITICAL,
		10L,
		0L);

	hmqShakeWindow=WinCreateMsgQueue(hab,0);

	/* Vorberechnungen */
	DisplayWidth = WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN);
	DisplayDepth = WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN);
	WinQueryWindowPos((HWND)Handle,(PSWP)&swp);
	SetPos_x=(SHORT)((DisplayWidth-swp.cx)/2);
	SetPos_y=(SHORT)((DisplayDepth-swp.cy)/2);

	SetPos_x_left=SetPos_x-ShakeWidth;
	SetPos_x_right=SetPos_x+ShakeWidth;

	for (i=0; i<ShakeCount; i++)
	{
		WinSetWindowPos((HWND)Handle, HWND_TOP, SetPos_x_left, SetPos_y, 0, 0, SWP_MOVE);
		DosSleep(ShakeDelay);
		WinSetWindowPos((HWND)Handle, HWND_TOP, SetPos_x_right, SetPos_y, 0, 0, SWP_MOVE);
		DosSleep(ShakeDelay);
	}

	/* abschlie·endes Zentrieren */
	WinSetWindowPos((HWND)Handle, HWND_TOP, SetPos_x, SetPos_y, 0, 0, SWP_MOVE);

	WinDestroyMsgQueue(hmqShakeWindow);

}
