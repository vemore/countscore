<!--@zapzap-->
Juego de cartas familiar, primo del Yaniv, a partir de tres jugadores, con una baraja de 52
cartas y comodines. El objetivo es tener en la mano el total más bajo.

## Valor de las cartas

- **As**: 1 punto;
- **2 a 10**: su valor nominal;
- **Jota**: 11, **Reina**: 12, **Rey**: 13;
- **Comodín**: **0 puntos** mientras se juega la ronda, pero **25 puntos** si sigue en la
  mano en el momento del conteo.

## La repartición

El jugador que abre la ronda elige cuántas cartas recibe cada uno, **de 4 a 7**. Se
reparten las cartas, el resto forma el mazo, y se voltea una carta para abrir el descarte.
En la siguiente ronda, el siguiente jugador abre y elige, saltando los jugadores
eliminados.

## El turno de juego

Un turno siempre se hace en dos tiempos, en este orden:

1. **Colocar** una o varias cartas, en una sola combinación válida. Permanecen visibles
   sobre la mesa.
2. **Tomar una carta**, a tu elección: la carta oculta de la parte superior del mazo, o
   una de las cartas que el jugador anterior acaba de colocar.

No puedes tomar sin haber colocado, y no terminas tu turno sin haber tomado. Cuando el
mazo está vacío, se mezcla el descarte para hacer uno nuevo, dejando a un lado las
últimas cartas colocadas, que siguen disponibles.

## Las combinaciones

- **Una carta sola**.
- **Cartas del mismo valor**: un par, un trío, un póquer.
- **Una escalera** de al menos **tres cartas consecutivas del mismo palo**, por ejemplo
  5♠ 6♠ 7♠.

El comodín reemplaza cualquier carta, tanto en un grupo como en una escalera. Una escalera
de dos cartas, una escalera que mezcla palos o que salta un valor no se coloca.

## Anunciar ZapZap

En lugar de colocar, un jugador puede anunciar **ZapZap** si su mano vale **5 puntos o
menos**, contando los comodines como 0. El anuncio detiene la ronda y cada uno revela su
juego.

El anunciante es **contrado** si otro jugador tiene una mano **igual o más baja** que la
suya: no hay nada que hacer para contrar, basta con tener la mano.

## Conteo

- **La mano más baja** de la mesa marca **0 puntos**: el anunciante si su ZapZap tiene
  éxito, el que contrare si no.
- **Los otros jugadores** marcan el valor de su mano, cada comodín que queda en la mano
  cuenta **25 puntos**.
- **El anunciante contrado** marca el valor de su mano **más una penalización de (número
  de jugadores aún en juego − 1) × 5 puntos**.

Los totales se acumulan de ronda en ronda, y se busca mantenerse bajo.

## Eliminación y clasificación

Un jugador es **eliminado en cuanto supera 100 puntos**. La clasificación final se lee al
revés del orden de eliminación: el último eliminado es primero, el primero eliminado es
último.

## Golden score

Cuando solo quedan dos jugadores, la siguiente ronda es una final en **golden score**: la
repartición puede ir **de 4 a 10 cartas**, y es la **mano más baja de la ronda**, no el
total acumulado, la que designa al ganador. Un anunciante contrado, incluso en empate,
pierde la partida. El perdedor de la final recibe la puntuación que lo lleva exactamente a
101 puntos.

<!--@uno-->
Juego de cartas rápido, de 2 a 10 jugadores, con un mazo especial de 108 cartas. El objetivo
de una ronda es deshacerse de todas tus cartas antes que los demás.

## Preparación

Cada jugador recibe **7 cartas**. El resto forma el mazo; se voltea la primera carta para
abrir el descarte.

## Desarrollo

En tu turno, colocas una carta que coincida con la carta de la parte superior del descarte
por el **color**, el **número** o el **símbolo**. Las cartas negras se pueden colocar sobre
cualquier cosa y permiten elegir el color que sigue. Si no puedes colocar nada, tomas una
carta, y juegas la carta tomada si te sirve.

Las cartas especiales cambian el curso del turno: **Pasar** salta al siguiente jugador,
**Inversa** cambia el sentido del juego, **+2** obliga al siguiente a tomar dos cartas y
pasar su turno, el **Comodín** fija el color, y el **Comodín +4** hace tomar cuatro cartas
al siguiente.

Un jugador que solo tiene una carta debe anunciar **"Uno"**. Si lo olvida y se le atrapan
antes de que el siguiente jugador haya jugado, toma cartas como penalización.

## Conteo

La ronda termina en cuanto un jugador coloca su última carta. Se **embolsa** entonces el valor
de todas las cartas restantes en las manos de los otros:

- **cartas numeradas**: su valor nominal;
- **Pasar, Inversa, +2**: 20 puntos cada una;
- **Comodín y Comodín +4**: 50 puntos cada uno.

Los otros jugadores no marcan nada en la ronda.

## Fin de la partida

Las rondas se encadenan hasta que un jugador alcanza **500 puntos**: el total más alto
gana. Así configura CountScore el Uno: el puntaje más alto gana, y la partida se detiene
en cuanto un total alcanza 500.

Algunas mesas juegan lo opuesto, cada uno marcando como penalización lo que le quedaba en
la mano, y el total más bajo ganando. Si es tu caso, modifica el tipo de juego para que el
puntaje más bajo gane.

<!--@scrabble-->
Juego de letras de 2 a 4 jugadores en un tablero de 15 × 15 casillas. Se marcan puntos formando palabras, como en un crucigrama.

## Preparación

Las letras se mezclan boca abajo. Cada jugador saca **7** y las mantiene en su atril. La primera palabra debe pasar por la casilla central.

## Desarrollo

En tu turno, colocas una o más fichas en la misma fila o columna, de manera que formen una palabra válida y toquen al menos una letra ya colocada. Todas las palabras creadas o extendidas por la jugada deben ser válidas. Después de jugar, completas tu atril a 7 letras.

Un jugador también puede **pasar** su turno, o **cambiar** letras por las del mazo si quedan suficientes fichas.

## Conteo

Cada letra tiene su valor; las letras raras valen más, el comodín vale cero.

El orden del cálculo cuenta:

1. primero se aplican las casillas **letra cuenta doble** y **letra cuenta triple** a las fichas colocadas en este turno;
2. se suman las letras de la palabra;
3. luego se aplican las casillas **palabra cuenta doble** y **palabra cuenta triple**. Dos casillas palabra cuenta doble en la misma palabra la multiplican por cuatro, dos casillas palabra cuenta triple por nueve;
4. todas las palabras formadas por la jugada se cuentan, cada una por su lado.

Una casilla multiplicadora solo sirve **una vez**, en el turno en que se cubre.

Colocar tus **siete letras en una sola jugada** suma un bono de **50 puntos**, que se añade después de los multiplicadores.

## Fin de la partida

La partida termina cuando el mazo está vacío y un jugador ha colocado su última letra, o cuando nadie puede jugar. Cada jugador resta de su total el valor de las letras que le quedan; quien terminó suma la suma de lo que guardan los demás. El total más alto gana.

<!--@skyjo-->
Juego de cartas de 2 a 8 jugadores, con una baraja de 150 cartas numeradas de **−2 a 12**. El objetivo es tener el total más bajo.

## Preparación

Cada jugador recibe **12 cartas** que dispone boca abajo frente a él, en una grilla de **3 filas por 4 columnas**, sin mirarlas. Cada uno voltea luego **dos** de su elección. El resto forma el mazo; se voltea una carta para abrir el descarte.

## Desarrollo

En tu turno, tienes dos opciones:

- **tomar la carta superior del descarte** e intercambiarla por una carta de tu grilla, boca abajo o visible; la carta reemplazada va al descarte, boca arriba;
- **robar** una carta: la intercambias de la misma forma, o la descartas y volteas una de tus cartas aún oculta.

Tu grilla siempre tiene doce casillas; solo aumenta la cantidad de cartas visibles.

**Columna idéntica** — si las tres cartas de una misma columna son visibles y tienen el mismo valor, la columna completa se retira y se descarta. No cuenta nada: es la mejor forma de bajar un total.

## Fin de una ronda

Tan pronto como un jugador ha **volteado sus doce cartas**, la ronda termina: los otros jugadores juegan un turno más, luego todos revelan lo que les queda.

## Conteo

Cada uno suma los valores de sus cartas. Las negativas se restan, lo que puede dar un total menor que cero. El resultado se suma al acumulado de rondas anteriores.

**La regla de duplicación**: el jugador que cerró la ronda ve su puntaje de la ronda **duplicado** si no tiene, estrictamente, el total más bajo de la ronda. La duplicación solo se aplica a un puntaje positivo — cerrar con un total negativo no cuesta nada.

## Fin de la partida

La partida termina al final de la ronda durante la cual un jugador alcanza o supera **100 puntos**. El total general más bajo gana.

<!--@president-->
Juego de descarte de 3 a 7 jugadores, con una baraja de 52 cartas. El objetivo de una ronda
es deshacerse de todas tus cartas primero, para convertirse en Presidente.

## Preparación

Se distribuyen todas las cartas. La jerarquía va del 2, el más débil, hasta el As, el más
fuerte — en muchas mesas, el 2 es en cambio la carta más fuerte, o sirve como comodín.
Acuerden antes de empezar.

## Desarrollo

El primer jugador coloca una carta, o varias cartas del **mismo valor**. Cada jugador
siguiente debe colocar **la misma cantidad de cartas**, de valor estrictamente superior, o
pasar su turno. Cuando todos pasan, la baza se cierra y el último en colocar lanza lo que
quiera.

Cuatro cartas idénticas colocadas o completadas a menudo cierran el turno inmediatamente:
es el **póquer**, y muchas mesas le hacen invertir la jerarquía hasta el final de la baza.

## Los títulos

El orden en que los jugadores se deshacen de sus cartas da los títulos de la ronda: el
primero es **Presidente**, el segundo **Vice-Presidente**, el último **Perdedor**, el
penúltimo **Vice-Perdedor**.

En la siguiente ronda, los títulos imponen un intercambio antes de jugar: el Perdedor da
sus **dos mejores cartas** al Presidente, quien le devuelve dos cartas de su elección; el
Vice-Perdedor y el Vice-Presidente intercambian una carta de la misma forma.

## Conteo

El sistema de puntuación más común solo premia la parte superior del ranking: en cada ronda,
el **Presidente marca 2 puntos**, el **Vice-Presidente 1 punto**, y los demás no marcan
nada. El primer jugador en alcanzar **10 puntos** gana la partida. Así configura CountScore el
Presidente: el puntaje más alto gana, y la partida se detiene en cuanto un total
alcanza 10.

Existen otros sistemas: 3, 2 y 1 puntos para los tres primeros, o puntos negativos para el
Vice-Perdedor y el Perdedor. Algunas mesas marcan al revés un punto de penalización al
último de cada ronda, y el total más bajo gana. Ajusta el umbral o el sentido del puntaje
en el tipo de juego.

<!--@belote-->
Juego de manos a cuatro, en dos equipos de dos, con una baraja de 32 cartas. El objetivo es alcanzar primero un total acordado, más a menudo **1 000 puntos**.

## El orden de las cartas

Cambia según el palo:

- **en el triunfo**: Jota (20), 9 (14), As (11), 10 (10), Rey (4), Reina (3), 8 y 7 (0);
- **en el palo**: As (11), 10 (10), Rey (4), Reina (3), Jota (2), 9, 8 y 7 (0).

La Jota y el 9 de triunfo son por lo tanto las dos cartas más fuertes del juego.

## La toma

Se distribuyen cinco cartas a cada uno, luego se voltea una carta. Cada jugador puede **tomar** este palo como triunfo. Si nadie lo quiere en la primera vuelta, se repite ofreciendo elegir otro palo. El equipo que toma se convierte en el **bando tomador** y debe realizar su contrato.

## Desarrollo

Debes proporcionar el palo pedido. De lo contrario, debes **triunfar** si el adversario lidera la mano, y **sobretriunfar** si el triunfo ya colocado es más débil. El compañero que ya es maestro de la mano te dispensa de triunfar.

## Conteo

Una mano vale **162 puntos**: 152 puntos de cartas y **10 puntos por la última mano**, el *dix de der* (última baza).

- El bando tomador realiza su contrato si supera **81 puntos**. Cada bando marca entonces lo que recogió.
- Si no los alcanza, está **dentro** (belote et rebelote — frase que significa fracaso): marca cero y el adversario se embolsa los 162 puntos.
- **Belote y rebelote** — anunciar el Rey y la Reina de triunfo al jugarlos suma **20 puntos** extra. Este bono se mantiene incluso si el contrato falla.
- **Capot** — ganar las ocho manos suma un bono acordado de antemano, a menudo 90 o 100 puntos.

## Fin de la partida

Se suman las manos hasta que un equipo alcance el total fijado. El equipo con el puntaje más alto gana.

<!--@tarot-->
Juego de manos a contrato, de 3 a 5 jugadores, con una baraja de **78 cartas**: cuatro palos de 14 cartas y 21 triunfos, más la Excusa. Un jugador, el **tomador**, se enfrenta solo a los demás.

## Las bolas

Tres cartas maestras cuentan doble en el recuento y fijan el requisito del contrato: el **21**, el **Pequeño** (el triunfo 1) y la **Excusa**. Se llaman las **bolas** u oudlers.

## Los contratos

Después de la distribución, cada uno anuncia o pasa. Del menos exigente al más ambicioso: **Pequeño** (o Toma), **Guarda**, **Guarda sin el perro**, **Guarda contra el perro**. Los dos primeros contratos dejan que el tomador tome el perro — las cartas apartadas en la distribución — e intercambie la misma cantidad de cartas; los dos últimos no se la dan.

A cinco jugadores, el tomador **llama a un rey** antes de jugar: quien lo tenga se convierte en su compañero, sin decirlo de inmediato.

## Desarrollo

Debes proporcionar el palo pedido; de lo contrario, debes **jugar triunfo**, y subir al triunfo más fuerte ya colocado si puedes. La Excusa nunca gana la mano pero permanece en el bando de quien la jugó.

## Conteo

Las cartas se cuentan por parejas: Rey 4,5 · Reina 3,5 · Caballero 2,5 · Jota 1,5 · las otras 0,5. Las bolas valen 4,5 cada una.

El tomador debe alcanzar un umbral que depende de la **cantidad de bolas** que recogió:

| Bolas | Puntos a reunir |
|---|---|
| 0 | 56 |
| 1 | 51 |
| 2 | 41 |
| 3 | 36 |

La diferencia con este umbral, aumentada por una base de 25 puntos, se **multiplica por el contrato**: ×1 para el Pequeño, ×2 para la Guarda, ×4 para la Guarda sin, ×6 para la Guarda contra.

El **Pequeño al final** — jugar el Pequeño en la última mano — vale 10 puntos, multiplicados de la misma forma. El **puñado** y el **slam** suman sus propias primas.

## Fin de la partida

El tomador gana o pierde su puntaje, y los defensores marcan lo opuesto. Los totales se acumulan sobre tantas manos como se quiera; el total más alto gana.

<!--@bridge-->
Juego de manos a contrato, a cuatro, en dos equipos de dos, con una baraja de 52 cartas. Una mano se juega en dos tiempos: las **pujas**, luego el **juego de la carta**.

## Las pujas

Cada uno a su turno anuncia un contrato, pasa, dobla o redobla. Una puja indica un **nivel** y un **palo de triunfo** (o *Sin triunfo*). El nivel se cuenta **por encima de seis manos**: un contrato de 3 Sin triunfo se compromete a realizar 6 + 3 = **9 manos** de 13.

Las pujas terminan después de tres pases consecutivos. El último contrato anunciado se convierte en el contrato de la mano, y quien nombró el palo primero en su bando se convierte en el **declarante**. Su compañero extiende su juego: es el **muerto**.

## El juego de la carta

Debes proporcionar el palo pedido. De lo contrario, juegas lo que quieras, incluyendo triunfo. La mano va a la carta de triunfo más fuerte, o, si no hay ninguna, a la carta más fuerte del palo pedido.

## Conteo

Solo las manos **pujadas** cuentan bajo la línea:

- **20 puntos** por mano en Tréboles o Diamantes;
- **30 puntos** por mano en Corazones o Picas;
- **40 puntos** por la primera mano en Sin triunfo, luego 30 por mano siguiente.

Un contrato que alcanza **100 puntos** es un **game** (juego); suma una prima de **300 puntos** si el bando no es vulnerable, **500** si lo es. Por debajo, un contrato realizado suma una pequeña prima de parcial. Las manos realizadas más allá del contrato se cuentan en prima, pero no cuentan para el juego.

Un contrato **fallido** suma puntos al adversario, según el número de bazas faltantes, la vulnerabilidad, y si el contrato fue doblado o no.

El **pequeño slam** (doce manos anunciadas) y el **gran slam** (los trece) suman primas importantes.

## Dos fórmulas

En **robro** (robus), se juega hasta que un bando gana dos juegos. En **torneo**, cada mano se marca por separado y se compara con otras mesas. CountScore simplemente suma las manos: el total más alto gana.

<!--@rami-->
Juego de combinaciones de 2 a 6 jugadores, con dos barajas de 52 cartas y sus comodines. El objetivo es colocar todas tus cartas en combinaciones y deshacerte de la última.

## Preparación

Cada jugador recibe **13 o 14 cartas** según el hábito de la mesa. El resto forma el mazo; se voltea una carta para abrir el descarte.

## Las combinaciones

- **La escala**: al menos tres cartas consecutivas del mismo palo.
- **El trío o el poker**: tres o cuatro cartas del mismo valor, de palos diferentes.

El **comodín** reemplaza cualquier carta y toma su valor en la combinación.

## Desarrollo

En tu turno, robas una carta — del mazo o del descarte — luego descartas una. Entre los dos, puedes colocar combinaciones en la mesa y completar las que ya están allí.

**El primer pase** es obligatorio: solo puedes abrir con un conjunto de combinaciones que sumen al menos **51 puntos**, y generalmente no antes de la segunda ronda.

## Valor de las cartas

Las cartas del 2 al 10 valen su número. Jota, Reina y Rey valen **10**. El As vale **11** cuando sigue al Rey en una escala o en un trío, y **1** cuando abre una escala frente al 2.

## Conteo

La ronda termina en cuanto un jugador ha colocado todas sus cartas. Los demás cuentan entonces lo que les queda en la mano, **como penalización**:

- las cartas no colocadas, a su valor;
- un **comodín** que quedó en la mano: **20 puntos**;
- un jugador que **no colocó nada en absoluto** a menudo recibe una penalización fija de **100 puntos**.

Las penalizaciones se acumulan de ronda en ronda, y se busca mantenerse bajo.

## Fin de la partida

Un jugador es **eliminado en cuanto supera 100 puntos**. La partida continúa entre los supervivientes; el último en pie, o el total más bajo, gana. Muchas mesas juegan a 200 o 500 puntos: ajusta el umbral en el tipo de juego.

<!--@coinche-->
Variante de la belote donde se anuncia el contrato en una subasta, a cuatro, en dos equipos de dos, con una baraja de 32 cartas. El objetivo es alcanzar primero el total acordado, que CountScore fija en **1 000 puntos**.

## El orden y el valor de las cartas

Son los de la belote: en el triunfo, Jota (20), 9 (14), As (11), 10 (10), Rey (4), Reina (3), 8 y 7 (0); en el otro palo, As (11), 10 (10), Rey (4), Reina (3), Jota (2), 9, 8 y 7 (0). Una mano vale siempre **162 puntos**, el *dix de der* incluido.

## Las subastas

Cada jugador recibe sus ocho cartas, sin carta de cara. A su turno, se pasa o se anuncia un número de puntos y un palo de triunfo: al menos **80**, luego por escalones de 10, cada anuncio debe superar el anterior. El **capot** — prometer las ocho bazas — es el anuncio más alto. Muchas mesas también permiten el *sin triunfo* y el *todo triunfo*.

Un adversario que duda del contrato puede hacer **coinche**, lo que duplica la apuesta; el equipo que subastó puede entonces hacer **surcoinche**, lo que la cuadruplica. Las subastas terminan después de tres pases consecutivos, o en cuanto una coinche no es respondida.

## Desarrollo

Se juegan las ocho bazas como en la belote: servir el palo, hacer triunfo si no se puede, sobretriunfo. El Rey y la Reina de triunfo anunciados en *belote* y *rebelote* valen **20 puntos** para el equipo que los tiene.

## Conteo

- **Contrato realizado** — el equipo que subastó reunió al menos los puntos anunciados. Marca el valor de su contrato más los puntos recogidos, y la defensa marca lo que recogió.
- **Contrato fallido** — el equipo que subastó no marca nada, y la defensa marca **160 puntos** más el valor del contrato.
- Una coinche multiplica por **2** el valor del contrato, una surcoinche por **4**.

La forma de redondear y contar los puntos recogidos varía de una mesa a otra; anota en cada mano el puntaje de cada equipo tal como tu mesa lo calcula.

## Fin de la partida

La partida se detiene en cuanto un equipo alcanza **1 000 puntos**, y el puntaje más alto gana. Las mesas que juegan a 2 000 puntos cambian el umbral en el tipo de juego.

<!--@yahtzee-->
Juego de dados a partir de un jugador, con **cinco dados** y una hoja de anotación. La partida se juega en **13 rondas**: en cada ronda, cada jugador completa una casilla en su hoja.

## La ronda de juego

Se lanzan los cinco dados, luego se pueden relanzar los que se quiera, **dos veces** como máximo: tres lanzamientos en total. Luego se anota el resultado en una casilla aún vacía, a elección. Si el resultado no encaja en ninguna casilla, se tacha una, que vale cero.

## Sección superior

Seis casillas, **de Unos a Seises**: se anota la suma de los dados del valor elegido. Tres Cincos en la casilla de Cincos valen 15.

Un total de al menos **63 puntos** en la sección superior — tres dados de cada valor — suma un bono de **35 puntos**.

## Sección inferior

- **Tercia** — tres dados iguales: la suma de los cinco dados.
- **Póquer** — cuatro dados iguales: la suma de los cinco dados.
- **Full** — una tercia y un par: **25 puntos**.
- **Escalera pequeña** — cuatro valores consecutivos: **30 puntos**.
- **Escalera grande** — cinco valores consecutivos: **40 puntos**.
- **Yahtzee** — cinco dados iguales: **50 puntos**.
- **Suerte** — cualquier combinación: la suma de los cinco dados.

Un nuevo Yahtzee, cuando la casilla Yahtzee ya tiene 50, suma un bono de **100 puntos** y se anota además en otra casilla vacía.

## Fin de la partida

Después de la decimotercera ronda, cada jugador suma sus dos secciones y sus bonos; el puntaje más alto gana. En CountScore, anota los puntos de la casilla completada como una ronda, o el total de la hoja en una sola ronda.

<!--@phase10-->
Juego de combinaciones de 2 a 6 jugadores, con una baraja especial de cartas numeradas del 1 al 12 en cuatro colores, **Comodines** y cartas **Pasar**. Cada jugador debe realizar, en orden, diez combinaciones impuestas: las **fases**.

## Las diez fases

1. dos tríos;
2. un trío y una escalera de cuatro;
3. un póquer y una escalera de cuatro;
4. una escalera de siete;
5. una escalera de ocho;
6. una escalera de nueve;
7. dos póqueres;
8. siete cartas del mismo color;
9. cinco cartas iguales y un par;
10. cinco cartas iguales y un trío.

Una escalera puede mezclar colores. El Comodín reemplaza cualquier carta; la carta Pasar hace que un jugador pierda su turno.

## Desarrollo

Cada jugador recibe **10 cartas**. En tu turno, robas una carta, del mazo o del descarte, luego descartas una. Quien tiene en la mano la fase que debe realizar puede colocarla, completa y de una sola vez; desde entonces, puede completar las combinaciones colocadas en la mesa, las suyas como las de los otros.

La ronda termina en cuanto un jugador se ha deshecho de todas sus cartas. Los que colocaron su fase pasarán a la siguiente; los otros la reintentarán en la siguiente ronda.

## Conteo

Las cartas que quedan en la mano cuentan **como penalización**: **5 puntos** del 1 al 9, **10 puntos** del 10 al 12, **15 puntos** para un Pasar, **25 puntos** para un Comodín.

## Fin de la partida

El primer jugador en colocar su **décima fase** gana. Si varios lo logran en la misma ronda, el puntaje más bajo gana. CountScore no sigue las fases: anótalas en el comentario de la ronda, y declara terminada la partida cuando se coloca la décima.

<!--@flip7-->
Juego de cartas de riesgo a partir de tres jugadores, con una baraja de cartas numeradas del **0 al 12** — tantos ejemplares de cada número como su valor, y un solo 0 — a las que se añaden cartas modificadoras y cartas de acción. El objetivo es alcanzar **200 puntos** el primero.

## La ronda de juego

En cada turno, cada jugador aún en juego elige: **tomar** una carta más, colocada cara arriba frente a él, o **quedarse** y poner a salvo lo que ya tiene.

Quien voltea **un número que ya tiene** frente a él **se quema**: no marcará nada en la ronda. Quien alinea **siete números diferentes** detiene la ronda de inmediato para todos.

## Las cartas especiales

- **Modificadores**: +2, +4, +6, +8, +10, que se suman al total, y **×2**, que duplica la suma de los números.
- **Congelación**: el jugador apuntado se detiene de inmediato con lo que tiene.
- **Tres seguidas**: el jugador apuntado debe tomar tres cartas seguidas.
- **Segunda oportunidad**: se descarta con un número duplicado, en lugar de quemarse.

## Conteo

Un jugador que no se quemó marca la suma de sus números, duplicada si tiene el ×2, luego aumentada con sus modificadores. Alinear **siete números diferentes** suma **15 puntos** más. Un jugador que se quemó marca cero, sean cuales sean sus cartas.

## Fin de la partida

La partida se detiene al final de la ronda en la que un jugador alcanza **200 puntos**, y el puntaje más alto gana.

<!--@mille_bornes-->
Juego de cartas de carrera de autos, de 2 a 6 jugadores, más a menudo a cuatro en dos equipos de dos. Cada mano es un viaje de **1 000 kilómetros**; la partida se gana con **5 000 puntos**.

## Las cartas

- **Distancia**: 25, 50, 75, 100 y 200 kilómetros.
- **Accidentes**: Luz roja, Límite de velocidad, Sin gasolina, Pinchazo, Accidente.
- **Remedios**: Luz verde, Fin del límite, Gasolina, Rueda de repuesto, Reparaciones.
- **Protecciones**: Vehículo prioritario, Depósito extra, Llanta indestructible, As del volante — cada una protege para siempre contra un accidente.

## Desarrollo

Cada jugador recibe seis cartas. En tu turno, robas una carta y luego la juegas o la descartas. Necesitas una **Luz verde** antes de poder avanzar. Coloca tus cartas de distancia frente a ti, ataca a un adversario, y repara los accidentes que recibas. Bajo un límite de velocidad, solo puedes jugar distancias de 50 kilómetros o menos.

Una protección jugada en el momento exacto en que se recibe el accidente que contrarresta es un **golpe maestro**: el accidente se anula, y se vuelve a jugar de inmediato.

La mano termina cuando un jugador alcanza **exactamente 1 000 kilómetros**, o cuando el mazo se agota y nadie puede jugar.

## Conteo

- cada kilómetro recorrido: **1 punto**;
- cada protección: **100 puntos**, y **300 puntos** más por las cuatro;
- cada golpe maestro: **300 puntos**;
- viaje completado: **400 puntos**;
- viaje completado después de que se agotó el mazo: **300 puntos** más;
- viaje completado sin distancia de 200: **300 puntos** más;
- viaje completado sin que ningún adversario se moviera: **500 puntos** más.

Los baremos varían ligeramente según las ediciones; sigue el de tu caja.

## Fin de la partida

La partida se detiene en cuanto un jugador o un equipo alcanza **5 000 puntos**, y el puntaje más alto gana.

<!--@rummikub-->
Juego de combinaciones de 2 a 4 jugadores, con **106 fichas**: los números del 1 al 13 en cuatro colores, duplicados, y dos comodines. El objetivo de una ronda es colocar todas tus fichas.

## Preparación

Cada jugador tira **14 fichas** y las ordena en su atril. El resto forma la pila, cara abajo.

## Las combinaciones

- **El grupo**: tres o cuatro fichas del mismo número, todas de colores diferentes.
- **La escalera**: al menos tres números consecutivos, del mismo color. El 1 no sigue al 13.

El comodín reemplaza cualquier ficha.

## Desarrollo

El **primer pase** debe sumar al menos **30 puntos**, solo con tus fichas. Luego, en tu turno, colocas todas las fichas que quieras, reordenando libremente las de la mesa — separar una escalera, completar un grupo, recuperar un comodín reemplazándolo — siempre que al final de tu turno cada combinación sea válida. Un jugador que no coloca nada tira una ficha.

## Conteo

La ronda termina en cuanto un jugador ha colocado su última ficha. Los otros cuentan el valor de sus fichas restantes **en negativo**, un comodín restante vale **30 puntos**; el ganador marca en positivo la suma de estas penalizaciones.

## Fin de la partida

Se juegan tantas rondas como se acordó, y el puntaje más alto gana.

<!--@six_nimmt-->
Juego de cartas de 2 a 10 jugadores, con **104 cartas** numeradas del 1 al 104. Cada carta tiene **cabezas de buey**, de una a siete: son puntos de penalización, y se busca recolectar la menor cantidad posible.

## Preparación

Cada jugador recibe **10 cartas**. Cuatro cartas se voltean en el centro: cada una abre una fila.

## Desarrollo

En cada turno, todos los jugadores eligen una carta en secreto y las revelan juntos. Se colocan de la más pequeña a la más grande. Cada carta se une a la fila que termina con la carta **más cercana por debajo** de la suya.

- El jugador cuya carta sería la **sexta** en una fila toma las cinco primeras, y su carta abre una nueva fila.
- El jugador cuya carta es más pequeña que todas las terminaciones de fila elige una fila, la toma, y su carta la reemplaza.

## Conteo

Después de diez turnos, cada jugador cuenta las cabezas de buey recogidas. En general: 1 cabeza por carta, **2** para múltiplos de 5, **3** para múltiplos de 10, **5** para dobles como 11 o 22, y **7** para el 55.

## Fin de la partida

Se encadenan las rondas, y el puntaje más bajo gana. CountScore elimina un jugador en cuanto **supera 66 cabezas de buey**. La regla original detiene la partida en cuanto un jugador totaliza 66: para seguirla al pie de la letra, fija el umbral en 65 en el tipo de juego.

<!--@qwirkle-->
Juego de fichas de 2 a 4 jugadores, con **108 fichas**: seis formas en seis colores, cada ficha en tres ejemplares. Se marcan puntos formando líneas.

## Preparación

Cada jugador tira **6 fichas** y las mantiene ocultas. El jugador que puede colocar la línea más larga comienza.

## Desarrollo

En tu turno, haces uno de los dos:

- **colocar** una o varias fichas, todas en una misma línea, tocando las fichas ya colocadas;
- **cambiar** fichas por la bolsa, sin colocar.

Todas las fichas en una línea comparten **ya sea el color, ya sea la forma**, y una línea nunca contiene la misma ficha dos veces — seis fichas como máximo. Después de colocar, completas tu mano a seis.

## Conteo

Marcas **un punto por ficha** en cada línea que creaste o extendiste durante el turno, las fichas ya colocadas incluidas. Una ficha que pertenece a dos líneas cuenta en cada una.

Completar una línea de seis fichas es un **Qwirkle**: suma **6 puntos** más, o sea **12 puntos** para la línea.

## Fin de la partida

Cuando la bolsa está vacía, el primer jugador que coloca todas sus fichas suma **6 puntos** más y detiene la partida. El puntaje más alto gana.

<!--@farkle-->
Juego de dados a partir de dos jugadores, con **seis dados**. El objetivo es alcanzar el primero **10 000 puntos**, sabiendo cuándo parar antes de perderlo todo.

## La ronda de juego

Se lanzan los seis dados, luego se aparta al menos un dado que marca. Entonces se puede **parar** y anotar los puntos acumulados, o **relanzar** los dados restantes para añadir más.

Un lanzamiento que no marca nada es un **Farkle**: los puntos de todo el turno se pierden. Si los seis dados marcaron, se pueden recoger todos y continuar.

## Las combinaciones

Un baremo común:

- un **1**: **100 puntos**; un **5**: **50 puntos**;
- tres dados iguales: **100 puntos × su valor**, y **1 000 puntos** para tres 1s;
- cuatro, cinco o seis dados iguales: un múltiplo de la tercia, según tu mesa;
- una escalera del 1 al 6: **1 500 puntos**; tres pares: **1 500 puntos**.

Solo los dados de un mismo lanzamiento se combinan. Muchas mesas piden un mínimo de **500 puntos** en un turno para anotar los primeros puntos.

## Fin de la partida

En cuanto un jugador alcanza **10 000 puntos**, cada uno de los otros juega un último turno, y el puntaje más alto gana. CountScore ofrece la pantalla de fin en cuanto se alcanza el umbral: elige «Continuar jugando» para dejar que los otros jueguen su último turno.

<!--@canasta-->
Juego de combinaciones a cuatro, en dos equipos de dos, con dos barajas de 52 cartas y cuatro comodines. El objetivo es formar **canastas** — combinaciones de siete cartas — y alcanzar el primero **5 000 puntos**.

## Las cartas

Los **comodines** y los **2** reemplazan cualquier carta. Los **3 rojos** no se juegan: se colocan en cuanto se reciben y suman un bono. Los **3 negros** sirven para bloquear el descarte.

## Desarrollo

Cada jugador recibe **11 cartas**. En tu turno, tomas dos cartas — o todo el descarte, si puedes usar su carta superior — colocas combinaciones, luego descartas una.

Una combinación reúne al menos tres cartas del mismo valor, con al menos dos naturales y tres comodines como máximo. Siete cartas forman una **canasta**: **pura** sin comodín, **mixta** con.

El primer pase de un equipo debe alcanzar un mínimo que sube con su puntaje: **50 puntos** hasta 1 495, **90** hasta 2 995, **120** más allá, y 15 con un puntaje negativo. Un equipo solo puede **terminar** la ronda con al menos una canasta.

## Conteo

- cartas colocadas: comodín **50**, As y 2 **20**, del Rey al 8 **10**, del 7 al 4 y el 3 negro **5**;
- canasta pura: **500 puntos**; canasta mixta: **300 puntos**;
- terminar la ronda: **100 puntos**;
- cada 3 rojo: **100 puntos**, y **800** por los cuatro.

Las cartas que quedan en la mano se restan, y los 3 rojos de un equipo que no colocó nada cuentan en su contra.

## Fin de la partida

La partida se detiene en cuanto un equipo alcanza **5 000 puntos**, y el puntaje más alto gana.

<!--@wizard-->
Juego de bazas con apuestas, de 3 a 6 jugadores, con **60 cartas**: una baraja de 52 cartas, más cuatro **Magos** y cuatro **Bufones**. El objetivo es predecir exactamente cuántas bazas ganarás.

## Las rondas

En la primera ronda cada jugador recibe **una carta**, dos en la segunda, y así sucesivamente hasta agotar la baraja: 20 rondas a tres, 15 a cuatro, 12 a cinco, 10 a seis. La siguiente carta se voltea y designa el triunfo.

## Las apuestas

Después de ver sus cartas, cada jugador anuncia, a su turno, cuántas bazas cree que ganará.

## Desarrollo

Debes servir el palo solicitado si puedes. Un **Mago** siempre se puede jugar y gana la baza — el primero jugado la gana. Un **Bufón** siempre se puede jugar y pierde la baza. Si no, la baza va al triunfo más fuerte, o a la carta más fuerte del palo solicitado.

## Conteo

- **apuesta exacta**: **20 puntos**, más **10 puntos** por baza ganada;
- **apuesta fallida**: **−10 puntos** por baza de diferencia, de más o de menos.

## Fin de la partida

Después de la última ronda, el puntaje más alto gana.

<!--@triomino-->
Juego de fichas de dominó triangular de 2 a 6 jugadores, con **56 fichas** cuya esquina tiene un número del 0 al 5. Se marcan puntos colocando fichas, y aún más formando figuras.

## Preparación

Las fichas se mezclan cara abajo. Cada jugador tira **9** con dos jugadores, **7** con tres o cuatro, **6** con más. El jugador que tiene el triple más alto comienza.

## Desarrollo

En tu turno, colocas una ficha cuyas **dos esquinas** de un lado corresponden a las del lado que toca. Entonces marcas la **suma de los tres números** de la ficha.

Quien no puede jugar tira una ficha, hasta tres veces: **−5 puntos** por ficha tirada, y **−10 puntos** más si sigue sin poder jugar.

## Los bonos

- abrir la partida con un triple: **10 puntos** más, más para el triple 0;
- cerrar un **puente**: **40 puntos**;
- cerrar un **hexágono**: **50 puntos**.

Los bonos varían según las ediciones; sigue los de tu caja.

## Fin de una ronda

La ronda termina cuando un jugador ha colocado su última ficha: marca **25 puntos** más la suma de las fichas que guardan los otros. Si la pila está vacía y nadie puede jugar, quien tiene la menor cantidad de puntos en la mano marca la diferencia.

## Fin de la partida

Se encadenan las rondas hasta el total acordado, a menudo 400 puntos, y el puntaje más alto gana. Fija este umbral en el tipo de juego.
