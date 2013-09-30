#include "LogFile.h"

@implementation LogFile:Object
{
	LogfileData MyData;
	TID					tid;
	APIRET			rc;
}

- (TID) initWithPipe: (HPIPE) apipe andFileName: (char *) afilename
	andFlags: (ULONG) aflag andBufSize: (ULONG) abufsize
{
	[super init];
	MyData.pipe=apipe;
	MyData.FileName=afilename;
	MyData.UniqueName=NULL;
	MyData.OperatingMode=aflag;
	MyData.BufSize=abufsize;
	MyData.object_self=self;
	if ((MyData.FileBuf=_tmalloc(MyData.BufSize))==NULL)
		[self error:"malloc(MyData.BufSize): no nemory available\n"];
	if ((tid=(TID)objc_thread_create(lfworker,&MyData))==0)
		[self error:"objc_thread_create(lfworker,&MyData): cannot start thread\n"];
	return tid;
}

-free
{
	rc=DosClose(MyData.pipe);									//Pipe schlieáen :)
	rc=DosWaitThread(&tid,DCWW_WAIT);         //... und auf Prozeátod warten.
	_tfree(MyData.FileBuf);                   //Speicher freigeben
	free(MyData.UniqueName);                  //dito
	return [super free];
}

@end

// Dieser Thread macht natrlich die eigentliche Arbeit:)
void lfworker(void *Data)
{
	APIRET				rc;
	ULONG					actiontaken;
	LogfileData		*MyData=((LogfileData *) Data);
	// Als erstes mssen wir uns um das OperationMode-Flag kmmern.
	if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_WRITE)==LF_READ)
	{
		// Offline-Betrieb, lesen von Logdatei.
		if ((rc=DosOpen(MyData->FileName,&MyData->file,&actiontaken,
			0,FILE_NORMAL,OPEN_ACTION_OPEN_IF_EXISTS,OPEN_FLAGS_SEQUENTIAL|
			OPEN_SHARE_DENYWRITE|OPEN_ACCESS_READONLY,NULL))==0)
		{
			// alles OK, Datei ge”ffnet, auf geht's
			rc=DosRead(MyData->file,MyData->FileBuf,MyData->BufSize,
				&MyData->BytesTransferred);
			while ((MyData->BytesTransferred!=0) && (rc==0))
			{
				rc=DosWrite(MyData->pipe,MyData->FileBuf,MyData->BytesTransferred,
					&MyData->BytesTransferred);
				if (rc==0)
				{
					rc=DosRead(MyData->file,MyData->FileBuf,MyData->BufSize,
						&MyData->BytesTransferred);
				}
			}
			//Nix mehr zu lesen oder Fehler, auf jeden Fall Ende.
			rc=DosClose(MyData->file);
			rc=DosClose(MyData->pipe);
		} else
		{
			// nix OK, Beschwerde einreichen!
			char *scratchbuf=malloc(256);
			sprintf(scratchbuf,"lfworker failed opening %s, rc=%lu",MyData->FileName,rc);
			[MyData->object_self error:scratchbuf];
			free(scratchbuf);
		}
	} else
	{
		// Online-Betrieb, schreiben in Logdatei.
		if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_OVERWRITE_IF_EXISTS)==
			LF_OVERWRITE_IF_EXISTS)
		{
			//Beim ersten mal ”ffnen wird die Datei ggf. berschrieben. Danach wird nur
			//noch angeh„ngt.
			if ((rc=DosOpen(MyData->FileName,&MyData->file,&actiontaken,
				0,FILE_NORMAL,OPEN_ACTION_CREATE_IF_NEW|OPEN_ACTION_REPLACE_IF_EXISTS,
				OPEN_FLAGS_SEQUENTIAL|
				OPEN_SHARE_DENYWRITE|OPEN_ACCESS_WRITEONLY,NULL))==0)
			{
				if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_CACHING)!=
					LF_CACHING)
				//Datei angelegt und leer. Wieder schlieáen, bis sie gebraucht wird.
					DosClose(MyData->file);
				rc=logloop(MyData);
				//Nix mehr zu lesen oder Fehler, auf jeden Fall Ende.
				rc=DosClose(MyData->file);
				rc=DosClose(MyData->pipe);
			} else
			{
				// nix OK, Beschwerde einreichen!
				char *scratchbuf=malloc(256);
				sprintf(scratchbuf,"lfworker failed opening %s, rc=%lu",MyData->FileName,rc);
				[MyData->object_self error:scratchbuf];
				free(scratchbuf);
			}
		} else
		{
			if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_UNIQUENAME)==
				LF_UNIQUENAME)
			{
				ULONG	Counter=0;										//eine nur hier ben”tigte Variable:)
				char  *Extension;										//dito
				//erstmal den Speicher fr den UniqueName holen.
				if ((MyData->UniqueName=malloc(strlen(MyData->FileName)+5))==NULL)
				{
					//Fehlerbehandlung
					[MyData->object_self error:
						"malloc(strlen(MyData->FileName)+5): no nemory available\n"];
				}
				strcpy(MyData->UniqueName,MyData->FileName);
				strcat(MyData->UniqueName,".0");	//Versionsendung anfgen
				while (((rc=DosOpen(MyData->UniqueName,&MyData->file,&actiontaken,
					0,FILE_NORMAL,OPEN_ACTION_CREATE_IF_NEW|OPEN_ACTION_FAIL_IF_EXISTS,
					OPEN_FLAGS_SEQUENTIAL|
					OPEN_SHARE_DENYWRITE|OPEN_ACCESS_WRITEONLY,NULL))==ERROR_OPEN_FAILED)
					&& Counter<1000)
				{
					Extension=strrchr(MyData->UniqueName,'.');
					if (Extension != NULL)
					{
					//Das "+1" ist dafr, daá der Punkt im Namen nicht berschrieben wird.
						_itoa(Counter,Extension+1,10);
						Counter++;
					} else
					{
						//Fataler Fehler. Wahrscheinlich ist der Heap korrupt.
						char *scratchbuf=malloc(256);
						sprintf(scratchbuf,"Fatal error: Extension=strrchr(MyData->\
UniqueName,'.') returned NULL which shouldn't happen. Possibly corrupted heap!");
						[MyData->object_self error:scratchbuf];
						free(scratchbuf);
					}
				}
				if (rc==0)
				{
					if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_CACHING)!=
						LF_CACHING)
					//Datei angelegt und leer. Wieder schlieáen, bis sie gebraucht wird.
						DosClose(MyData->file);
					rc=logloop(MyData);
					//Nix mehr zu lesen oder Fehler, auf jeden Fall Ende.
					rc=DosClose(MyData->file);
					rc=DosClose(MyData->pipe);
				} else
				{
					// Erzeugen eines UniqueNames schiefgegangen. Kann Datei nicht ”ffnen.
					char *scratchbuf=malloc(256);
					sprintf(scratchbuf,"lfworker failed opening %s, rc=%lu\n Creation of \
unique name failed.",MyData->UniqueName,rc);
					[MyData->object_self error:scratchbuf];
					free(scratchbuf);
				}
			} else
			{
				if ((MyData->OperatingMode & LF_APPEND)==LF_APPEND)
				{
					if ((rc=DosOpen(MyData->FileName,&MyData->file,&actiontaken,
						0,FILE_NORMAL,OPEN_ACTION_CREATE_IF_NEW|OPEN_ACTION_OPEN_IF_EXISTS,
						OPEN_FLAGS_SEQUENTIAL|
						OPEN_SHARE_DENYWRITE|OPEN_ACCESS_WRITEONLY,NULL))==NO_ERROR)
					{
						if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_CACHING)!=
							LF_CACHING)
						//Datei angelegt und leer. Wieder schlieáen, bis sie gebraucht wird.
							DosClose(MyData->file);
						rc=logloop(MyData);
						//Nix mehr zu lesen oder Fehler, auf jeden Fall Ende.
						rc=DosClose(MyData->file);
						rc=DosClose(MyData->pipe);
					} else
					{
						// Fehler. Irgendwas ist schiefgegangen.
						char *scratchbuf=malloc(256);
						sprintf(scratchbuf,"lfworker failed opening %s, rc=%lu",MyData->FileName,rc);
						[MyData->object_self error:scratchbuf];
						free(scratchbuf);
					}
				} else
				{
					// Nur neue Dateien anlegen.
					if ((rc=DosOpen(MyData->FileName,&MyData->file,&actiontaken,
						0,FILE_NORMAL,OPEN_ACTION_CREATE_IF_NEW|OPEN_ACTION_FAIL_IF_EXISTS,
						OPEN_FLAGS_SEQUENTIAL|
						OPEN_SHARE_DENYWRITE|OPEN_ACCESS_WRITEONLY,NULL))==NO_ERROR)
					{
						if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_CACHING)!=
							LF_CACHING)
						//Datei angelegt und leer. Wieder schlieáen, bis sie gebraucht wird.
							DosClose(MyData->file);
						rc=logloop(MyData);
						//Nix mehr zu lesen oder Fehler, auf jeden Fall Ende.
						rc=DosClose(MyData->file);
						rc=DosClose(MyData->pipe);
					} else
					{
						// Fehler. Irgendwas ist schiefgegangen.
						char *scratchbuf=malloc(256);
						sprintf(scratchbuf,"lfworker failed opening %s, rc=%lu",MyData->FileName,rc);
						[MyData->object_self error:scratchbuf];
						free(scratchbuf);
					}
				}
			}
		}
	}
	objc_thread_exit();
}

// Dies ist die Schreibschleife.
APIRET logloop(LogfileData *Data)
{
	APIRET	rc=NO_ERROR;
	ULONG		actiontaken;
	char		*TheFileName;
	if (Data->UniqueName!=NULL)
	{
		TheFileName=Data->UniqueName;
	}	else
	{
		TheFileName=Data->FileName;
	}
	rc=DosRead(Data->pipe,Data->FileBuf,Data->BufSize,&Data->BytesTransferred);
	while ((rc==0) && (Data->BytesTransferred!=0))
	{
		if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_CACHING)!=
			LF_CACHING)
		{
			rc=DosOpen(TheFileName,&Data->file,&actiontaken,
				0,FILE_NORMAL,OPEN_ACTION_FAIL_IF_NEW|OPEN_ACTION_OPEN_IF_EXISTS,
				OPEN_FLAGS_SEQUENTIAL|
				OPEN_SHARE_DENYWRITE|OPEN_ACCESS_WRITEONLY,NULL);
			if (rc==NO_ERROR)
			{
				if ((rc=DosSetFilePtr(Data->file,0,FILE_END,&actiontaken))==NO_ERROR)
				{
				}
			}
		}
		if ((rc=DosWrite(Data->file,Data->FileBuf,Data->BytesTransferred,
			&actiontaken))==NO_ERROR)
		{
			if (actiontaken<Data->BytesTransferred)
			{
				fprintf(stderr,"Strange error: DosWrite(%s) returned NO_ERROR, but not\
all data is actually \nwritten. Continuing execution.\n",TheFileName);
			}
		}
		//Die Puffer leeren.
//		rc=DosResetBuffer(Data->file);
		if (((ULONG) ((LogfileData *) Data)->OperatingMode & LF_CACHING)!=
			LF_CACHING)
		//Datei angelegt und leer. Wieder schlieáen, bis sie gebraucht wird.
			DosClose(Data->file);
		rc=DosRead(Data->pipe,Data->FileBuf,Data->BufSize,&Data->BytesTransferred);
	}	return rc;
}
