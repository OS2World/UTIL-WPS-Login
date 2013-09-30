#include "login.h"
#include "logindlg.h"

/* Globale Variablen                                                       */

HAB								hab;
HWND 							hwndRahmen		=0L;
LoginRecordType		LoginDaten;
HPIPE							ph_read;
HPIPE							ph_write;
LogFile						*ProtokollDatei;
char							*LogFileName;
ULONG             LoginExeID;
ULONG							Program_Close_Requested=0;

TID Log_tid;
TID Dialog_tid;
TID Starter_tid;
TID TermSnoop_tid;

int main(int argc, char *argv[])
{
	HMQ			hmq;
	HWND		hwndAnwendung =0L;
	QMSG		qmsg;
	APIRET	rc;                         /* Version 0.2 4.1.1994              */
	ULONG		Fensterstil	=	0L;						/* énderung 26.8.94                  */

	hab=WinInitialize(0);

	hmq=WinCreateMsgQueue(hab,0);
	rc=WinCancelShutdown(hmq,TRUE);

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
			"login utility version 0.45pl3 (09-27-96) by Jens Glathe\n\nusage: login <userfile> <workplace shell> [logfile]\n",
			"Information",
			0,
			MB_OK|MB_INFORMATION);
	}
	else{

		/* Logproze· initialisieren.                                           */

		if ((rc=DosCreatePipe(&ph_read,&ph_write,0x1000))!=NO_ERROR)
		{
			WinMessageBox(
				HWND_DESKTOP,
				HWND_DESKTOP,
				"Could not start login protocol pipe. Aborting... ",
				"Error",
				0,
				MB_OK|MB_ERROR);
			WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
		}

		if (argv[3]==NULL)
		{
			LogFileName=strdup("login.log");
		} else
		{
			LogFileName=argv[3];
		}
		ProtokollDatei=[LogFile alloc];
		Log_tid=[ProtokollDatei initWithPipe: ph_read andFileName: LogFileName
			andFlags: LF_WRITE|LF_APPEND andBufSize: 0x1000];

		logprintf("Starting login program. argv[1]=%s argv[2]=%s argv[3]=%s\n",
			argv[1],argv[2],argv[3]);
		/* Zuweisungen fÅr die Starter-Task ausfÅhren                          */

		LoginDaten.UserFile=argv[1];
		LoginDaten.Program=argv[2];

		TermSnoop_tid=(TID)objc_thread_create(TermSnoop,NULL);
		if((Dialog_tid=(TID)objc_thread_create(LoginDlgThread,&LoginDaten))==-1)
		{
			logprintf("Could not start login dialog thread.\n");
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

		logprintf("Program is terminating. Killing child processes and cleaning up memory...\n");
		rc=DosKillThread(TermSnoop_tid);
		rc=DosKillThread(Starter_tid);
		rc=DosStopSession(STOP_SESSION_ALL,LoginExeID);
		rc=DosWaitThread(&TermSnoop_tid,DCWW_WAIT);
		rc=DosWaitThread(&Starter_tid,DCWW_WAIT);
		rc=DosWaitThread(&Dialog_tid,DCWW_WAIT);
		rc=DosSleep(1);														//Dem Log-Proze· eine Chance geben
		rc=DosClose(ph_write);
		[ProtokollDatei free];
		rc=DosWaitThread(&Log_tid,DCWW_WAIT);
		if (argv[3]==NULL)
		{
			free(LogFileName);
		}
		rc=WinDestroyWindow(hwndRahmen);
		rc=WinDestroyMsgQueue(hmq);
		rc=WinTerminate(hab);
		return rc;
	}
	return 0;
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
					if((Starter_tid=(TID)objc_thread_create(StarterThread,&LoginDaten))==-1)
					{
						logprintf("Could not start starter thread.\n");
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
					logprintf("Attempt to log in from user %s, password typed: %s\n",
						LoginData->Username,LoginData->Password);
					WinPostMsg(hwndRahmen, WM_COMMAND, (MPARAM)LOGINDLG_SUCCESSFUL,
						(MPARAM) 0);
					/*WinDismissDlg( hwnd, TRUE );*/  /* Removes the dialog box       */
					return (MRESULT) TRUE;
					/* beenden                                                       */
				}
				break;

				case LOGIN_SYSSHUTDOWN:
				{
					logprintf("System shutdown requested.\n");
					objc_thread_create(ShutdownThread,NULL);
					WinDismissDlg( hwnd, TRUE );  /* Removes the dialog box       */
					return (MRESULT) TRUE;
				}
				break;

				case LOGINDLG_QUIT:					 /* Das war's */
				{
					WinDismissDlg( hwnd, TRUE );  /* Removes the dialog box       */
					return (MRESULT) TRUE;
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
					objc_thread_create(ShakeWindow,(void *)hwnd);
					logprintf("Previous login attempt was not successful.\n");
					return (MRESULT) TRUE;
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
	objc_thread_exit();
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

	PID								LoginExePID;
	HMQ 							hmqStarterThread;
	APIRET 						rc;
	BOOL							success;
	PRFPROFILE				profiledata;

/* Version 0.45pl3: Dem zu startenden Programm RUNWORKPLACE-Eigenschaft verleihen. */
	HQUEUE						TerminationQueue;			/*Queue fÅr die zu startende  Sitzung  */
	HEV								QueueSem=0;
	char							QueueName[255]="\\QUEUES\\login";
	#define						QUEUENAMELENGTH 13
	REQUESTDATA				AppData; 				/*von der Sitzung zurÅckgelieferte Daten*/
	ULONG							AppDataLength;
	PVOID							AppDataAdress;
	ULONG							AppDataCode=0L;
	BOOL32						QueueFlags=0L;
	BYTE							QueuePriority;
	ULONG							QRetryCount=0;	/* ZÑhler fÅr fehlgeschlagene Versuche,*/
																		/* eine Queue aufzubauen               */
	CHAR							*Number;
	CHAR							buffer[35];
	ULONG							System_Shutdown_Flag=0;

	LoginExeDaten.PgmTitle=Logindata->Program;
	LoginExeDaten.PgmName=Logindata->Program;

	hmqStarterThread=WinCreateMsgQueue(hab,0);

	if ((Benutzerdatei=fopen(Logindata->UserFile,"r"))!=NULL){
		fgets(TestString,254,Benutzerdatei);
		TestString[strlen(TestString)-1]='\0';
		if (strcmp(TestString, COOKIE)==0){

			/* Nach dem Passwort suchen                                          */

			if (CheckForPassword(LoginData,Benutzerdatei)){

				logprintf("Previous login attempt was successful, starting desktop...\n");
				/* Hier geschieht das Umschalten der INI-Datei                     */

				if (fgets(TestString,254,Benutzerdatei)!=NULL){
					TestString[strlen(TestString)-1]='\0';

					/* FÅr profiledata mu· Speicher alloziert werden                 */
					profiledata.pszUserName=malloc(256);
					profiledata.pszSysName=malloc(256);
					profiledata.cchUserName=256;
					profiledata.cchSysName=256;

					if ((success=PrfQueryProfile(hab,&profiledata))==TRUE){

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

						rc=NO_ERROR;
						/* Endlosschleife fÅr RUNWORKPLACE-Verhalten */
						while ((rc==NO_ERROR) && (System_Shutdown_Flag==0))
						{

							while((rc=DosCreateQueue(      /* Termination-Queue fÅr die Sitzung*/
								&TerminationQueue,
								QUE_PRIORITY|QUE_CONVERT_ADDRESS,
								QueueName))!=NO_ERROR)
							{

								QueueName[QUEUENAMELENGTH]='\0';
								strcat(QueueName,Number=_itoa(QRetryCount,buffer,10));
								QRetryCount++;
							}

							LoginExeDaten.TermQ=QueueName;

							rc=DosStartSession(&LoginExeDaten,&LoginExeID,&LoginExePID);
							if ((rc!=NO_ERROR)&&(rc!=ERROR_SMG_START_IN_BACKGROUND))
							{
								logprintf("Could not start workplace application,rc=%lu\n",rc);
								WinMessageBox(
									HWND_DESKTOP,
									HWND_DESKTOP,
									"Could not start workplace application",
									"Error",
									0,
									MB_OK|MB_ERROR);
								WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
							}

#ifdef __LOGIN_TERMTEST_

							logprintf("Preparing Termination Test...\n");
							objc_thread_create(QuitThread,NULL);
#endif

							rc=DosReadQueue(					 	/* auf Beendigung der Sitzung warten */
								TerminationQueue,
								&AppData,
								&AppDataLength,
								&AppDataAdress,
								AppDataCode,
								QueueFlags,
								&QueuePriority,
								QueueSem);

							if(rc==NO_ERROR)
							{
								rc=DosFreeMem(AppDataAdress);
								rc=DosCloseQueue(TerminationQueue);

							} else
							{
								logprintf("DosReadQueue(%s) failed, rc=%lu. Program is \
terminating...\n",LoginExeDaten.TermQ,rc);
								DosCloseQueue(TerminationQueue);
							}

							DosEnterCritSec();
							System_Shutdown_Flag=Program_Close_Requested;
							DosExitCritSec();
							if (System_Shutdown_Flag)
								logprintf("This is a system shutdown, no restart...\n");
							else
							{
								logprintf("Workplace process terminated, restarting...\n");
								DosSleep(5000);
							}
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
			logprintf("User Data file corrupted\n");
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
		logprintf("User Data file not found\n");
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
	if (Benutzerdatei!=NULL) fclose(Benutzerdatei);
	objc_thread_exit();
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
	objc_thread_exit();

}

void ShutdownThread (void *Data)
{
	HMQ				hmqKillWindow;
	APIRET 		rc;

	hmqKillWindow=WinCreateMsgQueue(hab,0);
	rc=WinCancelShutdown(hmqKillWindow,TRUE);
	rc=DosWaitThread(&Dialog_tid,DCWW_WAIT);
	rc=WinShutdownSystem(hab,hmqKillWindow);
	WinDestroyMsgQueue(hmqKillWindow);
	objc_thread_exit();
}

int logprintf(const char *format, ...)
{
	char		*scratchbuf=malloc(0x1000);
	char		*EndPtr;
	time_t 	EventTime;
	ULONG		byteswritten;
	int			result;
	va_list arg_ptr;

	time(&EventTime);
	result=sprintf(scratchbuf,"\r%s ",ctime(&EventTime));
	EndPtr=scratchbuf+strlen(scratchbuf);
	// \n durch : ersetzen
	*(EndPtr-2)=':';
	va_start(arg_ptr,format);
	result=vsprintf(EndPtr,format,arg_ptr);
	va_end(arg_ptr);
	DosWrite(ph_write,scratchbuf,strlen(scratchbuf),&byteswritten);
	free(scratchbuf);
	return result;
}

#ifdef __LOGIN_TERMTEST_

void QuitThread(void *Data)
{
	HMQ			hmqQuitProg;
	APIRET	rc;

	hmqQuitProg=WinCreateMsgQueue(hab,0);
	DosSleep(10000);
	WinPostMsg(hwndRahmen, WM_QUIT, (MPARAM)0,(MPARAM)0);
	rc=WinDestroyMsgQueue(hmqQuitProg);
	objc_thread_exit();
}
#endif

/* Ternination-Snooper */
void TermSnoop(void *Data)
{
	HMQ			TSq=WinCreateMsgQueue(hab,0);
	APIRET	rc;
	QMSG		msg;

	rc=DosSetPriority(PRTYS_THREAD,PRTYC_TIMECRITICAL,5,0);
	while ((rc=WinGetMsg(hab,&msg,0L,0,0)));
	//WM_QUIT
	rc=DosEnterCritSec();
	Program_Close_Requested=1;
	rc=DosExitCritSec();
	logprintf("TermSnoop: WM_QUIT received. Killing desktop process...\n");
	rc=DosStopSession(STOP_SESSION_ALL,LoginExeID);
	rc=WinDestroyMsgQueue(TSq);
	objc_thread_exit();
}

