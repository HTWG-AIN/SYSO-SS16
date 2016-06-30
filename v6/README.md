# Update Mechanismus in einem Paket System

#### Frage 1:
``` 
Wie könnte ein Update-Mechanismus aussehen, der das installierte Paket auf aktuellem Stand hält?
```

Man könnte einen Background Job starten der periodisch überprüft ob eine neue Version des Packetes existiert. Diese Überprüfung könnte zum Beispiel einmal am Tag durchgeführt werden. 

Eine weitere Möglichkeit wäre es das Paket in einem Paket Repository zu veröffentlichen. Wenn man das Repository nun zu Linux hinzufügt kümmert sich Linux von selbst darum, dass die Pakete geupdated werden.

Es wäre auch möglich die Software über ein Script zu starten das zuerst versucht das Paket zu updaten bevor es die Software startet.
 

#### Frage 2:
```
Wie können Sie die Menge der übertragenen Daten, trotz gleichbleibender Funktionalität, reduzieren?
``` 
Die Menge der übertragenen Daten lassen sich reduzieren in dem man nicht das gesamte Paket noch einmal schickt, sondern nur einen Patch überträgt. Dies bedeutet man überträgt nur einen Diff zwischen den Paket Versionen. Es gibt mehrere Möglichkeiten und ich bin mir unsicher was mehr Platz spart:
* Ein Binary-Diff des bereits gepackten Paketes.
* Ein Diff aller im Packet enthaltenen Dateien, diese Diffs werden dann wieder gepackt.

#### Frage 3:
```
Welche Vorteile bietet so ein Paketverwaltungssystem im Vergleich zur manuellen Softwareinstallation?
``` 

Ein Paketverwaltungssystem ist ein zentralisiertes System dies bedeutet, dass alle Schritte auf einmal durgehführt werden. Dadurch werden die Installation und die Verwaltung der Software für den Benutzer deutlich erleichtert. Der Benutzer muss sich nur dafür entscheiden Die Software zu installieren, und das Paketverwaltungssystem macht den Rest. 

Will der Benutzer im Gegensatz eine Software von Grund auf installieren, muss er sich nicht nur eine Datei (das Paket) herunterladen, sondern alle Source-Dateien der Software. Diese Dateien muss er dann compilen wofür er sich möglicherweise noch weitere Pakete besorgen muss von denen die Software abhängt. Anschließend sollte er das neu installierte Program dann zum Pfad hinzufügen damit es auch einfach aus der Konsole heraus bedient werden kann. De Software wird sich nicht selbständig updaten.

Je nach Paketverwaltungssystem werden entweder Source-Dateien und ein compile Skript übertragen, oder gleich eine bereits fertig compilte Software, bzw. ein Script welches die Betriebssystems-Architektur erkennt und mit diesem Wissen die richtige compilte Software herunterlädt. Dies hat den Vorteil, dass der Software Entwickler den Source-Code der Software nicht veröffentlichen muss.

#### Frage 4
```
Wie können Sie sicherstellen, dass das richtige Softwarepaket installiert wurde und nicht infizierte Schadsoftware eingeschleust wurde? (z.B. Übertragung etc.)
``` 

Man sollte sicherstellen, dass das Packet nur über eine gesicherte Leitung geladen wird. Um zu überprüfen ob man ein unverändertes Packet heruntergeladen hat, sollte man den Hash das Pakets mit einem online Bereitgestellen Hash vergleichen.

Das Packet könnte auch mittels Public-Key System verifiziert werden. Dies heißt, dass das Packet, eine Prüfsumme oder eine sonstige bekannte Komponente mit einem unbekannten Private-Key verschlüsselt wurden. Mit Hilfe eines online bereit gestellten Public-Keys kann nun die verschlüsselte Komponente entschlüsselt und überprüft werden.
