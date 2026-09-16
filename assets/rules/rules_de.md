<!--@zapzap-->
Ein Familienkartenspiel für mindestens drei Spieler. Das Ziel ist es, die niedrigste Summe
in der Hand zu haben.

## Das Prinzip

In jeder Runde versuchen die Spieler, ihre hohen Karten loszuwerden. Ein Spieler, der glaubt,
die niedrigste Hand am Tisch zu haben, kann **ZapZap** ansagen. Die Ansage beendet die Runde
und zwingt alle, ihre Karten zu zeigen.

## Punktezählung

- **ZapZap erfolgreich** — der Spieler, der ansagte, hatte tatsächlich die niedrigste Hand:
  er erhält **0 Punkte**.
- **ZapZap misslungen oder kontern** — ein anderer Spieler hat eine Hand mit gleichem oder
  niedrigerem Wert: der Ansagende erhält die Punktzahl seiner Hand **plus eine Strafe von
  (Anzahl der Spieler − 1) × 5 Punkte**.
- **Die anderen Spieler** erhalten die Punktzahl ihrer Hand.

Die Gesamtpunkte summieren sich von Runde zu Runde, und das Ziel ist, niedrig zu bleiben.

## Ausscheidung und Ranking

Ein Spieler wird **ausgeschieden, sobald er 100 Punkte überschreitet**. Die abschließende
Rangliste ergibt sich aus der Reihenfolge der Ausscheidungen in umgekehrter Reihenfolge:
der zuletzt Ausgeschiedene wird Erster, der zuerst Ausgeschiedene wird Letzter.

Wenn nur noch zwei Spieler übrig sind, wird das Spiel im **golden score** Modus gespielt:
der Verlierer des Finales erhält die Punktzahl, die ihn auf genau 101 Punkte bringt.

## Das Übrige ist Sache eures Tisches

Die Details der Kartenverteilung, des Nachziehens und der Spielregeln unterscheiden sich
von Gruppe zu Gruppe. Dieser Text beschreibt die Punktezählung, die die App beherrscht.
Nutzt den Button „Bearbeiten", um eure eigenen Regeln hinzuzufügen.

<!--@uno-->
Ein schnelles Kartenspiel für 2 bis 10 Spieler mit einem Spezialblatt von 108 Karten.
Das Ziel einer Runde ist es, alle Karten vor den anderen loszuwerden.

## Spielaufbau

Jeder Spieler erhält **7 Karten**. Die übrigen Karten bilden den Nachziehstapel; die erste
Karte wird umgedreht, um den Ablagestapel zu öffnen.

## Spielablauf

Man legt eine Karte ab, die der obersten Karte des Ablagestapels nach **Farbe**, **Zahl**
oder **Symbol** entspricht. Schwarze Karten lassen sich auf alles ablegen und ermöglichen
die Wahl der nächsten Farbe. Wenn man keine Karte ablegen kann, zieht man eine Karte und
spielt sie, falls sie passt.

Spezielle Karten verändern den Spielablauf: **Aussetzen** überspringt den nächsten Spieler,
**Richtungswechsel** dreht die Spielrichtung um, **+2** zwingt den nächsten Spieler, zwei
Karten zu ziehen und eine Runde auszusetzen, der **Joker** bestimmt die Farbe, und der
**Joker +4** lässt den nächsten Spieler vier Karten ziehen.

Ein Spieler, der nur noch eine Karte hat, muss **„Uno"** ansagen. Wenn er es vergisst und
man zieht ihn zur Rechenschaft, bevor der nächste Spieler gespielt hat, zieht er
Strafkarten.

## Punktezählung

Die Runde endet, sobald ein Spieler seine letzte Karte abgeworfen hat. Man zählt dann die
Karten, die in den Händen der anderen Spieler verbleiben:

- **nummerierte Karten**: ihr Nennwert;
- **Aussetzen, Richtungswechsel, +2**: je 20 Punkte;
- **Joker und Joker +4**: je 50 Punkte.

Nach der häufigsten Regel **kassiert** der Spieler, der fertig ist, die Summe aller Karten,
die die anderen noch in der Hand haben, und das Spiel geht bis **500 Punkte**.

Viele Tische spielen es umgekehrt: jeder verbucht, was ihm in der Hand bleibt, als Strafe,
und der niedrigste Gesamtpunktstand gewinnt. Das ist die Version, die CountScore standardmäßig
erwartet. Wenn ihr nach 500 Punkte spielt, ändert den Spieltyp, damit der höhere Punktstand
gewinnt.

<!--@scrabble-->
Ein Wortspiel für 2 bis 4 Spieler auf einem Brett mit 15 × 15 Feldern. Man sammelt Punkte,
indem man Wörter bildet, wie in einem Kreuzworträtsel.

## Spielaufbau

Die Buchstaben werden verdeckt gemischt. Jeder Spieler zieht **7** Buchstaben und behält sie
in seinem Ständer. Das erste Wort muss über das mittlere Feld führen.

## Spielablauf

Man legt eine oder mehrere Steine in derselben Reihe oder Spalte ab, um ein gültiges Wort
zu bilden und mindestens einen bereits gelegten Buchstaben zu berühren. Alle durch den Zug
gebildeten oder verlängerten Wörter müssen gültig sein. Nach dem Spielen füllt man seinen
Ständer wieder auf 7 Buchstaben auf.

Ein Spieler kann auch **passen** oder **Buchstaben gegen den Nachziehstapel austauschen**, falls
noch genug Steine vorhanden sind.

## Punktezählung

Jeder Buchstabe hat seinen Wert; seltene Buchstaben sind mehr wert, der Joker zählt null.

Die Reihenfolge der Berechnung ist wichtig:

1. zuerst werden die Felder **Buchstabe zählt doppelt** und **Buchstabe zählt dreifach** auf
   die in diesem Zug gelegten Steine angewendet;
2. die Buchstaben des Wortes werden addiert;
3. dann werden die Felder **Wort zählt doppelt** und **Wort zählt dreifach** angewendet. Zwei
   Felder „Wort zählt doppelt" im selben Wort multiplizieren es mit vier, zwei Felder
   „Wort zählt dreifach" mit neun;
4. alle durch den Zug gebildeten Wörter werden gezählt, jeweils für sich.

Ein Multiplikatorfeld wirkt sich **nur einmal aus**, nämlich beim Zug, in dem es bedeckt wird.

Alle **sieben Buchstaben in einem Zug** abzulegen bringt einen Bonus von **50 Punkte**,
der nach den Multiplikatoren addiert wird.

## Spielende

Das Spiel endet, wenn der Nachziehstapel leer ist und ein Spieler seinen letzten Buchstaben
gelegt hat, oder wenn niemand mehr spielen kann. Jeder Spieler zieht von seinem Gesamtpunktstand
den Wert der Buchstaben ab, die ihm verbleiben; der Spieler, der fertig ist, addiert die Summe
der Buchstaben, die die anderen noch haben. Der höchste Gesamtpunktstand gewinnt.

<!--@skyjo-->
Ein Kartenspiel für 2 bis 8 Spieler mit 150 nummerierten Karten von **−2 bis 12**. Das Ziel
ist es, die niedrigste Summe zu haben.

## Spielaufbau

Jeder Spieler erhält **12 Karten**, die er verdeckt vor sich auslegt, in einem Raster von
**3 Zeilen und 4 Spalten**, ohne sie anzuschauen. Jeder deckt anschließend **zwei** seiner
Wahl auf. Die übrigen Karten bilden den Nachziehstapel; eine Karte wird umgedreht, um den
Ablagestapel zu öffnen.

## Spielablauf

In jedem Zug hat ein Spieler zwei Möglichkeiten:

- **die oberste Karte des Ablagestapels nehmen** und sie gegen eine Karte aus seinem Raster
  austauschen, ob verdeckt oder offen; die ersetzte Karte geht verdeckt in den Ablagestapel;
- **vom Nachziehstapel ziehen**: er tauscht diese Karte auf die gleiche Weise aus, oder er
  legt sie weg und deckt dann eine seiner noch verdeckten Karten auf.

Das Raster hat immer zwölf Plätze; nur die Anzahl der offenen Karten wächst.

**Identische Spalte** — wenn alle drei Karten einer Spalte offen liegen und denselben Wert
haben, wird die ganze Spalte entfernt und abgeworfen. Sie zählt jetzt null: das ist der
beste Weg, um die Summe zu senken.

## Rundenende

Sobald ein Spieler **alle zwölf Karten aufgedeckt hat**, endet die Runde: die anderen Spieler
spielen noch einen Zug, dann zeigen alle ihre verbleibenden Karten.

## Punktezählung

Jeder addiert die Werte seiner Karten. Negative Werte werden abgezogen, was zu einer Summe
unter null führen kann. Das Ergebnis wird zur Gesamtpunkte der vorherigen Runden addiert.

**Die Verdoppelungsregel**: Der Spieler, der die Runde beendet hat, sieht seinen Rundenpunktstand
**verdoppelt**, wenn er nicht streng den niedrigsten Gesamtpunktstand der Runde hat. Die
Verdopplung gilt nur für einen positiven Punktstand — die Runde mit einer negativen Summe zu
beenden kostet nichts.

## Spielende

Das Spiel endet am Ende der Runde, in der ein Spieler **100 Punkte erreicht oder überschreitet**.
Der niedrigste Gesamtpunktstand gewinnt.

<!--@president-->
Ein Ablegespiel für 3 bis 7 Spieler mit einem 52er-Blatt. Das Ziel einer Runde ist es, als
Erster alle Karten loszuwerden und Präsident zu werden.

## Spielaufbau

Alle Karten werden verteilt. Die Hierarchie reicht von der 2, der schwächsten Karte, bis zum
Ass, der stärksten — bei vielen Tischen ist die 2 dagegen die stärkste Karte oder fungiert
als Wildcard. Einigt euch vorher.

## Spielablauf

Der erste Spieler legt eine Karte oder mehrere Karten **gleichen Wertes**. Jeder folgende
Spieler muss **die gleiche Anzahl Karten** legen, mit streng höherem Wert, oder passen. Wenn
alle gepasst haben, wird der Stich geschlossen und der zuletzt Gespielte eröffnet einen neuen
Stich mit einer Karte seiner Wahl.

Vier identische Karten in einem Stich schließen den Stich oft sofort: das ist ein **Vierling**,
und bei vielen Tischen kehrt er die Hierarchie bis zum Ende des Stiches um.

## Die Titel

Die Reihenfolge, in der die Spieler ihre Karten loswerden, bestimmt die Titel der Runde:
der erste ist **Präsident**, der zweite **Vizepräsident**, der letzte **Arsch**, der
vorletzte **Vize-Arsch**.

In der nächsten Runde erzwingen die Titel einen Austausch, bevor man spielt: Der Arsch gibt
seine **zwei besten Karten** dem Präsidenten, der ihm zwei Karten seiner Wahl zurückgibt; der
Vize-Arsch und der Vizepräsident tauschen auf die gleiche Weise eine Karte.

## Punktezählung

Der Präsident zählt oft die Punkte, aber selten auf die gleiche Weise zweimal. Die häufigsten
Systeme vergeben 2 Punkte für den Präsidenten und 1 für den Vizepräsidenten, oder 3, 2 und 1
für die ersten drei.

Eine andere, einfacher zu verfolgende Methode besteht darin, jedem Letzten jeder Runde einen
Strafpunkt zu geben und denjenigen auszuschließen, der zu viele sammelt. Das ist die Version,
die CountScore standardmäßig erwartet, mit niedrigerem Punktstand als Gewinn und einem Spiel,
das über **11 Punkte** endet. Wenn euer Tisch in die andere Richtung zählt, ändert die
Richtung im Spieltyp.

<!--@belote-->
Ein Stichspiel zu viert, in zwei Zweierteams, mit einem 32er-Blatt. Das Ziel ist es,
als Erstes eine vereinbarte Gesamtpunkte zu erreichen, meist **1.000 Punkte**.

## Die Kartenwerte

Sie ändern sich je nach Farbe:

- **im Trumpf**: Bube (20), 9 (14), Ass (11), 10 (10), König (4), Dame (3), 8 und 7 (0);
- **in der Farbe**: Ass (11), 10 (10), König (4), Dame (3), Bube (2), 9, 8 und 7 (0).

Der Trumpfbube und die Trumpf-9 sind also die zwei stärksten Karten des Spiels.

## Die Reizung

Fünf Karten werden an jeden Spieler verteilt, dann wird eine Karte aufgedeckt. Jeder Spieler
kann diese Farbe als Trumpf **reizen**. Wenn niemand im ersten Durchgang will, wird erneut
ein Durchgang gespielt, in dem jeder andere Farbe reizen kann. Das Team, das reizt, wird zur
**annehmen den Partei** und muss seinen Kontrakt erfüllen.

## Spielablauf

Man muss die verlangte Farbe bedienen. Falls nicht, muss man **mit Trumpf stechen**, wenn der
Gegner den Stich anführt, und **überstechen**, wenn der bereits gelegte Trumpf schwächer ist.
Der Partner, der den Stich bereits anführt, befreit vom Stechen.

## Punktezählung

Eine Partie ist **162 Punkte wert**: 152 Punkte aus Karten und **10 Punkte für den letzten Stich**,
den *dix de der* (Zehn der Hinteren).

- Das annehmen de Team erfüllt seinen Kontrakt, wenn es über **81 Punkte** hinausgeht. Jedes Team
  verbucht dann, was es gemacht hat.
- Wenn es diese nicht erreicht, ist es **drin** (in den Minusbereich): Es erhält null Punkte und
  der Gegner bekommt die 162 Punkte.
- **Belote et rebelote** — das Ansagen von König und Dame des Trumpfes beim Spielen bringt
  **20 Punkte** Bonus. Dieser Bonus bleibt erhalten, auch wenn der Kontrakt fehlschlägt.
- **Capot** — alle acht Stiche zu gewinnen bringt einen vorher vereinbarten Bonus, oft 90 oder
  100 Punkte.

## Spielende

Man addiert die Partien, bis ein Team die festgelegte Gesamtpunkte erreicht. Das Team mit dem
höchsten Punktstand gewinnt.

<!--@tarot-->
Ein Stichspiel mit Kontrakten für 3 bis 5 Spieler mit einem Blatt von **78 Karten**: vier
Farben mit je 14 Karten und 21 Trümpfe, plus die Excuse. Ein Spieler, der **Preneur** (Bieter),
spielt allein gegen die anderen.

## Die Bouts

Drei Meisterkarten zählen doppelt im Abrechnung und bestimmen die Kontraktanforderung: die
**21**, der **Petit** (Trumpf 1) und die **Excuse**. Sie heißen die **Bouts** oder oudlers.

## Die Kontrakte

Nach der Kartenverteilung kündet jeder an oder passt. Von der am wenigsten ehrgeizig zur
ehrgeizigsten: **Petite** (oder Prise), **Garde**, **Garde sans le chien** (Garde ohne den
Hund), **Garde contre le chien** (Garde gegen den Hund). Die ersten beiden Kontrakte erlauben
dem Bieter, den Hund zu nehmen — die Karten, die bei der Verteilung zur Seite gelegt wurden —
und genauso viele Karten auszuwerfen; die letzten beiden geben ihm das nicht.

Bei fünf Spielern **ruft der Bieter einen König** vor dem Spielen auf: wer ihn hat, wird sein
Partner, ohne es sofort zu sagen.

## Spielablauf

Man muss die verlangte Farbe bedienen; falls nicht, muss man **Trumpf spielen** und auf den
stärksten bereits gelegten Trumpf hinaufsteigen, wenn man kann. Die Excuse gewinnt nie den Stich,
bleibt aber im Team desjenigen, der sie spielte.

## Punktezählung

Karten werden paarweise gezählt: König 4,5 · Dame 3,5 · Springer 2,5 · Bube 1,5 · andere 0,5.
Die Bouts zählen je 4,5.

Der Bieter muss eine Schwelle erreichen, die von der **Anzahl der Bouts** abhängt, die er
gesammelt hat:

| Bouts | Zu erreichende Punkte |
|---|---|
| 0 | 56 |
| 1 | 51 |
| 2 | 41 |
| 3 | 36 |

Der Unterschied zu dieser Schwelle, plus eine Basis von 25 Punkte, wird **mit dem Kontrakt
multipliziert**: ×1 für Petite, ×2 für Garde, ×4 für Garde sans, ×6 für Garde contre.

Der **Petit au bout** — den Petit im letzten Stich spielen — ist 10 Punkte wert, auf die
gleiche Weise multipliziert. Die **Poignée** (Handvoll) und der **Chelem** (Schlemm) fügen ihre
eigenen Boni hinzu.

## Spielende

Der Bieter gewinnt oder verliert seinen Punktstand, und die Verteidiger verbuchen das Gegenteil.
Die Gesamtpunkte sammeln sich über so viele Partien wie gewünscht an; der höchste Punktstand
gewinnt.

<!--@bridge-->
Ein Stichspiel mit Kontrakten für vier Spieler, in zwei Zweierteams, mit einem 52er-Blatt.
Eine Partie besteht aus zwei Phasen: die **Reizung** und das **Kartenspiel**.

## Die Reizung

Jeder bietet nacheinander einen Kontrakt an, passt, kontra oder surkontra. Ein Gebot gibt
eine **Höhe** und eine **Trumpffarbe** (oder *Ohne Trump*) an. Die Höhe wird **über sechs
Stiche** gezählt: Ein 3-Ohne-Trump-Kontrakt verpflichtet, 6 + 3 = **9 Stiche** aus 13
zu machen.

Die Gebote enden nach drei aufeinanderfolgenden Pässen. Das letzte Gebot wird zum Kontrakt
der Partie, und der Spieler, der die Farbe zuerst in seinem Team nannte, wird der
**Erklärer (Dummy Spieler)**. Sein Partner zeigt seine Karten: das ist der **Dummy**.

## Das Kartenspiel

Man muss die verlangte Farbe bedienen. Falls nicht, spielt man, was man will, einschließlich
Trumpf. Der Stich geht an den stärksten Trumpf oder, wenn kein Trumpf gespielt wurde, zur
stärksten Karte der verlangte Farbe.

## Punktezählung

Nur die **gemachten** Stiche zählen unterhalb der Linie:

- **20 Punkte** pro Stich in Kreuz oder Karo;
- **30 Punkte** pro Stich in Herz oder Pik;
- **40 Punkte** für den ersten Stich ohne Trump, dann 30 pro weiteren Stich.

Ein Kontrakt mit **100 Punkte** ist ein **Spiel**; er bringt einen Bonus von **300 Punkte**,
wenn das Team nicht angreifbar ist, **500**, wenn es angreifbar ist. Darunter bringt ein
erfüllter Kontrakt einen kleinen Teilbonus. Stiche über den Kontrakt hinaus zählen als Bonus,
aber nicht für das Spiel.

Ein **misslungener** Kontrakt gibt dem Gegner Punkte, je nachdem, um wie viele Stiche er verfehlt
wurde, der Anfälligkeit und ob der Kontrakt kontriert wurde oder nicht.

Der **kleine Schlemm** (zwölf angesagte Stiche) und der **große Schlemm** (alle dreizehn) bringen
große Boni.

## Zwei Formate

Im **Robber-Bridge** spielt man, bis ein Team zwei Spiele gewinnt. Im **Turnier** wird jede Partie
separat bewertet und mit anderen Tischen verglichen. CountScore addiert einfach die Partien:
der höchste Punktstand gewinnt.

<!--@rami-->
Ein Kombinationsspiel für 2 bis 6 Spieler mit zwei 52er-Blättern und deren Jokern. Das Ziel
ist es, alle Karten in Kombinationen abzulegen und die letzte abzuwerfen.

## Spielaufbau

Jeder Spieler erhält **13 oder 14 Karten**, je nach Gewohnheit des Tisches. Die übrigen Karten
bilden den Nachziehstapel; eine Karte wird umgedreht, um den Ablagestapel zu öffnen.

## Die Kombinationen

- **Die Folge**: mindestens drei Karten, die sich in derselben Farbe nacheinander folgen.
- **Der Drilling oder Vierling**: drei oder vier Karten gleichen Wertes, verschiedener Farben.

Der **Joker** ersetzt jede Karte und nimmt ihren Wert in der Kombination an.

## Spielablauf

In jeinem Zug zieht man eine Karte — vom Nachziehstapel oder vom Ablagestapel — und wirft
dann eine Karte ab. Dazwischen kann man Kombinationen auf den Tisch legen und die bereits
dort liegenden ergänzen.

**Der erste Auslage** ist beschränkt: man kann nur mit einem Satz von Kombinationen öffnen,
das zusammen mindestens **51 Punkte** ausmacht, und im Allgemeinen nicht vor dem zweiten Zug.

## Kartenwerte

Karten von 2 bis 10 zählen ihre Augenzahl. Bube, Dame und König zählen je **10**. Das Ass zählt
**11**, wenn es dem König in einer Folge oder einem Drilling folgt, und **1**, wenn es eine
Folge vor der 2 eröffnet.

## Punktezählung

Die Runde endet, sobald ein Spieler alle seine Karten abgeworfen hat. Die anderen zählen dann,
was ihnen in der Hand bleibt, **als Strafe**:

- nicht abgelegte Karten, zu ihrem Wert;
- ein **Joker** in der Hand: **20 Punkte**;
- ein Spieler, der **nichts abgeworfen hat** bekommt oft eine pauschale Strafstrafe von
  **100 Punkte**.

Die Strafen summieren sich von Runde zu Runde, und das Ziel ist, niedrig zu bleiben.

## Spielende

Ein Spieler wird **ausgeschieden, sobald er 100 Punkte überschreitet**. Das Spiel setzt sich
zwischen den Überlebenden fort; der letzte verbleibende Spieler oder der mit der niedrigsten
Gesamtpunkte gewinnt. Viele Tische spielen mit 200 oder 500 Punkte: passt die Schwelle in
deinem Spieltyp an.
