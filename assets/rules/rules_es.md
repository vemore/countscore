<!--@zapzap-->
Juego de cartas familiar, a partir de tres jugadores. El objetivo es tener en la mano el total más bajo.

## El principio

En cada ronda, los jugadores buscan vaciar su mano de las cartas altas. Un jugador que piense tener la mano más baja de la mesa puede anunciar **ZapZap**. El anuncio detiene la ronda y obliga a todos a revelar su juego.

## Conteo

- **ZapZap exitoso** — el anunciante efectivamente tenía la mano mínima: marca **0 puntos**.
- **ZapZap fallido o contraído** — otro jugador tiene una mano igual o más baja: el anunciante marca el valor de su mano **más una penalización de (número de jugadores − 1) × 5 puntos**.
- **Los otros jugadores** marcan el valor de su mano.

Los totales se acumulan de ronda en ronda, y se busca mantenerse bajo.

## Eliminación y clasificación

Un jugador es **eliminado en cuanto supera 100 puntos**. La clasificación final se lee al revés del orden de eliminación: el último eliminado es primero, el primero eliminado es último.

Cuando quedan solo dos jugadores, la partida se juega en **golden score** (muerte súbita): el perdedor de la final recibe la puntuación que lo lleva exactamente a 101 puntos.

## El resto pertenece a tu mesa

El detalle de la distribución, el robo y lo que se permite colocar varía de un grupo a otro. Este texto describe el conteo, que es lo que la aplicación sabe hacer. Usa el botón "modificar" para agregar tus propios hábitos.

<!--@uno-->
Juego de cartas rápido, de 2 a 10 jugadores, con una baraja especial de 108 cartas. El objetivo de una ronda es deshacerse de todas tus cartas antes que los demás.

## Preparación

Cada jugador recibe **7 cartas**. El resto forma el mazo; se voltea la primera carta para abrir el descarte.

## Desarrollo

En tu turno, colocas una carta que coincida con la carta superior del descarte por el **color**, el **número** o el **símbolo**. Las cartas negras se pueden colocar sobre cualquier cosa y permiten elegir el color que sigue. Si no puedes colocar nada, robas, y juegas la carta robada si te sirve.

Las cartas especiales cambian el curso del turno: **Pasar** salta al siguiente jugador, **Inversa** cambia el sentido del juego, **+2** obliga al siguiente a robar dos cartas y pasar su turno, el **Comodín** fija el color, y el **Comodín +4** hace robar cuatro cartas al siguiente.

Un jugador que solo tiene una carta debe anunciar **"Uno"**. Si lo olvida y se le atrapan antes de que el siguiente jugador haya jugado, roba cartas como penalización.

## Conteo

La ronda termina en cuanto un jugador coloca su última carta. Se cuentan entonces las cartas que quedan en las manos:

- **cartas numeradas**: su valor nominal;
- **Pasar, Inversa, +2**: 20 puntos cada una;
- **Comodín y Comodín +4**: 50 puntos cada uno.

En la regla más difundida, quien terminó **recibe** la suma de todo lo que queda en los otros, y la partida va hasta **500 puntos**.

Muchas mesas juegan lo opuesto: cada uno marca lo que le quedaba en la mano, como una penalización, y el total más bajo gana. Es esta versión la que CountScore espera por defecto. Si juegas a 500, modifica el tipo de juego para que el puntaje más alto gane.

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
Juego de descarte de 3 a 7 jugadores, con una baraja de 52 cartas. El objetivo de una ronda es deshacerse de todas tus cartas primero, para convertirse en Presidente.

## Preparación

Se distribuyen todas las cartas. La jerarquía va del 2, la más débil, hasta el As, la más fuerte — en muchas mesas, el 2 es en cambio la carta más fuerte, o actúa como comodín. Acuerden antes de empezar.

## Desarrollo

El primer jugador coloca una carta, o varias cartas del **mismo valor**. Cada jugador siguiente debe colocar **la misma cantidad de cartas**, de valor estrictamente superior, o pasar su turno. Cuando todos pasan, la mano se cierra y el último en colocar lanza lo que quiera.

Cuatro cartas idénticas colocadas o completadas a menudo cierran el turno inmediatamente: es el **poker**, y muchas mesas le hacen invertir la jerarquía hasta el final de la mano.

## Los títulos

El orden en que los jugadores se deshacen de sus cartas da los títulos de la ronda: el primero es **Presidente**, el segundo **Vice-Presidente**, el último **Perdedor**, el penúltimo **Vice-Perdedor**.

En la siguiente ronda, los títulos imponen un intercambio antes de jugar: el Perdedor da sus **dos mejores cartas** al Presidente, quien le devuelve dos cartas de su elección; el Vice-Perdedor y el Vice-Presidente intercambian una carta de la misma forma.

## Conteo

El Presidente a menudo cuenta los puntos, pero rara vez de la misma forma dos veces. Los sistemas más comunes asignan 2 puntos al Presidente y 1 al Vice-Presidente, o bien 3, 2 y 1 a los tres primeros.

Otro hábito, más simple de llevar en un papel, consiste en marcar un punto de penalización al último de cada ronda y eliminar al que acumule demasiados. Es esta versión la que CountScore espera por defecto, con un puntaje más bajo ganando y una partida que termina por encima de **11 puntos**. Si tu mesa marca al derecho, cambia el sentido del puntaje en el tipo de juego.

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
