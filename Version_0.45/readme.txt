Login 0.45pl3 Developer-Seed README

Dies ist ein Programm, was ich schon sehr lange im Einsatz habe und sicher
Potential fÅr grî·eres bietet.  Aus FaulheitsgrÅnden wurde es in den letzten
Jahren aber nur um die Funktionen erweitert, die ich so brauchte :)

Was tut es?

Login îffnet einen Dialog, in den man einen Benutzernamen und ein Passwort 
eintragen mu·. Nach erfolgter Eingabe wird in einer Datei dieses verifiziert 
und bei korrekter Anmeldung die in der Datei angegebene INI-Datei als USER_INI
gesetzt. Daraufhin startet das Programm die in argv[2] Åbergebene Applikation
(z.B. PMSHELL.EXE). Login ist als RUNWORKPLACE-Ersatz gedacht und Åberwacht 
deswegen, ob die gestartete Applikation beendet wird / abstÅrzt. Geschieht
dieses, wird sie neu gestartet.

Mittels Login ist es mîglich, mehrere USER_INI-Dateien und damit auch mehrere 
Desktops zu verwalten. Die ganze Erstellungsarbeit und Verwaltung von 
EintrÑgen in den Ini-Dateien macht Login aber nicht.

Installation:

Man kopiere das Programm in ein Verzeichnis seiner Wahl :)
In der CONFIG.SYS mu· Login.exe als RUNWORKPLACE eingetragen werden. Beispiel:

SET RUNWORKPLACE=C:\UTILS\LOGIN\LOGIN.EXE C:\UTILS\LOGIN\USERDATA.LOGIN C:\OS2\PMSHELL.EXE C:\UTILS\LOGIN\LOGIN.LOG

Man beachte, da· alle dateien mit vollem Pfad angegeben werden mÅssen.

Parameter:

argv[1]: Datei mit Benutzernamen, Passworten und Referenzen auf Ini-Dateien. 
Eine Beispieldatei (userdata.login) ist im Paket mit bei. Die erste Zeile darf
nicht geÑndert werden :)

argv[2]: Das zu startende Programm.

argv[3]: Logfile fÅr alle Aktionen.

Das Programm benîtigt die EMX-Runtime und die Objective-C-Runtime. Die 
Objective-C-Runtime-DLL ist dabei (objc.dll), der Quellcode ist bei mir 
erhÑltlich und unterliegt der GPL (ich habe ihn ja nur etwas geÑndert).

Was soll das ganze?

Das Programm soll zeigen, da· es recht einfach mîglich ist, mehrere Desktops
zu benutzen und eine Anregung zur Entwicklung von entsprechender 
WPS-FunktionalitÑt darstellen.

RÅckmeldungen und Hinweise bitte an:

Jens Glathe
Meraner Stra·e 33
10825 Berlin

Tel.: 030-8538648

email: jensajce@w271zrz.zrz.tu-berlin.de


