Login 0.45pl3 Developer-Seed README

Dies ist ein Programm, was ich schon sehr lange im Einsatz habe und sicher
Potential f�r gr��eres bietet.  Aus Faulheitsgr�nden wurde es in den letzten
Jahren aber nur um die Funktionen erweitert, die ich so brauchte :)

Was tut es?

Login �ffnet einen Dialog, in den man einen Benutzernamen und ein Passwort 
eintragen mu�. Nach erfolgter Eingabe wird in einer Datei dieses verifiziert 
und bei korrekter Anmeldung die in der Datei angegebene INI-Datei als USER_INI
gesetzt. Daraufhin startet das Programm die in argv[2] �bergebene Applikation
(z.B. PMSHELL.EXE). Login ist als RUNWORKPLACE-Ersatz gedacht und �berwacht 
deswegen, ob die gestartete Applikation beendet wird / abst�rzt. Geschieht
dieses, wird sie neu gestartet.

Mittels Login ist es m�glich, mehrere USER_INI-Dateien und damit auch mehrere 
Desktops zu verwalten. Die ganze Erstellungsarbeit und Verwaltung von 
Eintr�gen in den Ini-Dateien macht Login aber nicht.

Installation:

Man kopiere das Programm in ein Verzeichnis seiner Wahl :)
In der CONFIG.SYS mu� Login.exe als RUNWORKPLACE eingetragen werden. Beispiel:

SET RUNWORKPLACE=C:\UTILS\LOGIN\LOGIN.EXE C:\UTILS\LOGIN\USERDATA.LOGIN C:\OS2\PMSHELL.EXE C:\UTILS\LOGIN\LOGIN.LOG

Man beachte, da� alle dateien mit vollem Pfad angegeben werden m�ssen.

Parameter:

argv[1]: Datei mit Benutzernamen, Passworten und Referenzen auf Ini-Dateien. 
Eine Beispieldatei (userdata.login) ist im Paket mit bei. Die erste Zeile darf
nicht ge�ndert werden :)

argv[2]: Das zu startende Programm.

argv[3]: Logfile f�r alle Aktionen.

Das Programm ben�tigt die EMX-Runtime und die Objective-C-Runtime. Die 
Objective-C-Runtime-DLL ist dabei (objc.dll), der Quellcode ist bei mir 
erh�ltlich und unterliegt der GPL (ich habe ihn ja nur etwas ge�ndert).

Was soll das ganze?

Das Programm soll zeigen, da� es recht einfach m�glich ist, mehrere Desktops
zu benutzen und eine Anregung zur Entwicklung von entsprechender 
WPS-Funktionalit�t darstellen.

R�ckmeldungen und Hinweise bitte an:

Jens Glathe
Meraner Stra�e 33
10825 Berlin

Tel.: 030-8538648

email: jensajce@w271zrz.zrz.tu-berlin.de


