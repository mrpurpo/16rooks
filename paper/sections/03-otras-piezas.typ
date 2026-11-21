#import "../style.typ": *

= Variaciones con otras piezas en el tablero $8 times 8$ <sec:otras-piezas>

Estudiamos ahora el problema con las demás piezas en el tablero de $8 times 8$, junto con su comportamiento en tableros de $m times n$ y su relación con los modelos de la @sec:estado. Mantenemos la notación de la @sec:problema-principal, con las blancas inicialmente en la fila $1$ y las negras en la fila $m$.

== Peones

El intercambio es imposible: sin capturas, cada peón solo avanza dentro de su columna y no puede sobrepasar al peón adversario que la bloquea.

== Reyes

#proposition(name: [Intercambio de reyes])[
  En un tablero de $m >= 3$ filas y $n >= 2$ columnas, el número mínimo de movimientos para intercambiar $n$ reyes blancos en la fila $1$ con $n$ reyes negros en la fila $m$ es
  $ T_min (m, n) = 2n(m - 1). $
  En particular, para el tablero estándar de $8 times 8$, el mínimo es $112$.
] <prop:kings>

#proof[
  *Cota inferior.* Cada uno de los $2n$ reyes debe avanzar $m - 1$ filas y cambia de fila a lo sumo una unidad por turno, de donde $T >= 2n(m - 1)$.

  *Construcción óptima.* Como $m >= 3$ y $n >= 2$, cada columna $c_j$ tiene una fila intermedia y una columna adyacente $c_(j')$ ($j' = j + 1$ si $j < n$, y $j' = n - 1$ si $j = n$), lo que permite intercambiar sus dos reyes en $2(m - 1)$ movimientos sin alterar las demás columnas:
  + El rey blanco se aparta en diagonal de $(j, 1)$ a $(j', 2)$, libre porque los reyes de $c_(j')$ ocupan las filas $1$ y $m$ ($1$ movimiento).
  + El rey negro desciende por $c_j$ de $(j, m)$ a $(j, 1)$ ($m - 1$ movimientos).
  + El rey blanco regresa en diagonal a $(j, 3)$ y sube por $c_j$ hasta $(j, m)$ ($m - 2$ movimientos).

  Cada paso, vertical o diagonal, avanza una fila hacia el destino. Repitiendo la maniobra en $c_1, dots, c_n$ se obtienen $2n(m - 1)$ movimientos; la secuencia de $112$ para $m = n = 8$ está en la @sec:ap-reyes.
]

#remark(title: [Generalización a configuraciones arbitrarias])[
  Sobre un subconjunto arbitrario de casillas y con posiciones iniciales y finales cualesquiera, cada turno desplaza una pieza a un vértice adyacente vacío del grafo del rey, y el problema es exactamente _colored pebble motion_ con dos colores (_multi-agent path finding_ en robótica). Allí la factibilidad se decide en tiempo lineal (Goraly y Hassin @goraly2010; Fujita et al. @fujita2012), mientras que la optimalidad es NP-hard (Yu y LaValle @yu2013 @yu2015).
]

== Damas

#proposition(name: [Intercambio de damas, Tokarev @tokarev2005])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar las $8$ damas blancas de la fila $1$ con las $8$ damas negras de la fila $8$ es $23$.
] <prop:queens>

#proof[
  Seguimos el argumento de conteo de Tokarev @tokarev2005, dividiendo las $16$ damas en siete grupos: los $6$ pares de las columnas centrales (`b` a `g`) y las $4$ damas de las esquinas (`a1`, `a8`, `h1`, `h8`).

  *Cota inferior.* Desde una columna central, una diagonal que parte de la fila $1$ u $8$ recorre a lo sumo $6$ filas antes del borde lateral, así que no alcanza la fila opuesta. La primera dama de cada par central en moverse tiene además su columna bloqueada por la adversaria, por lo que necesita al menos $2$ movimientos y la segunda al menos $1$: $3$ por par. En las esquinas, la primera dama en moverse encuentra ocupadas su columna y su diagonal hacia la esquina opuesta y necesita $2$ movimientos, y las otras tres al menos $1$: $5$ en total. Sumando,
  $ T >= 6 dot 3 + 5 = 23. $

  *Construcción óptima.* La cota se alcanza con la construcción de Tokarev @tokarev2005 (@fig:damas-tokarev), transcrita en la @sec:ap-damas.
]

#figure(
  image("/assets/image.png", width: 52%),
  caption: [Construcción en $23$ movimientos para el intercambio de damas @tokarev2005.],
) <fig:damas-tokarev>

== Alfiles

#proposition(name: [Intercambio de alfiles])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ alfiles blancos de la fila $1$ con los $8$ alfiles negros de la fila $8$ es $30$.
] <prop:bishops>

#proof[
  Cada alfil conserva el color de su casilla, así que el problema se separa en dos subproblemas simétricos: casillas oscuras (blancos en `a1, c1, e1, g1`, negros en `b8, d8, f8, h8`) y claras (blancos en `b1, d1, f1, h1`, negros en `a8, c8, e8, g8`).

  *Cota inferior.* En las casillas oscuras, la única diagonal que une las filas $1$ y $8$ (recorriendo $7$ filas y $7$ columnas) es `a1`–`h8`. Por tanto, los $6$ alfiles fuera de `a1` y `h8` necesitan al menos $2$ movimientos cada uno; de los dos de las esquinas, el primero en moverse encuentra ocupada la esquina opuesta y necesita $2$, y el otro al menos $1$. Así,
  $ T_1 >= 3 + 6 dot 2 = 15, $
  y por reflexión horizontal las casillas claras requieren también $15$, de donde $T >= 30$.

  *Construcción óptima.* En las casillas oscuras se despeja primero la diagonal principal: el negro de `b8` va a `h2` ($1$); el blanco de `a1` llega a `b8` vía `e5` ($2$); el negro de `h8` recorre la diagonal hasta `a1` ($1$); el blanco de `g1` sube a `h8` vía `d4` ($2$), y el negro de `h2` entra en `g1` ($1$). Los pares restantes (`c1, f8` y `e1, d8`) se intercambian en $4$ movimientos cada uno rebotando en las columnas `a` y `h`, para un total de $7 + 4 + 4 = 15$. Reflejando horizontalmente para las casillas claras se obtienen los $30$ movimientos de la @sec:ap-alfiles.
]

#remark(title: [Sobre la generalización a tableros $m times n$])[
  Rotando el tablero $45 degree$, cada subproblema monocromático es análogo al intercambio de torres de la @sec:problema-principal, pero en $m times n$ surgen obstrucciones adicionales. Primero, el color exige que las filas $1$ y $m$ tengan las mismas cantidades de casillas de cada color, lo que falla si $m$ es par y $n$ impar (en $8 times 7$, la fila $1$ tiene $4$ oscuras y $3$ claras, y la fila $8$, $3$ y $4$), haciendo imposible el intercambio. Segundo, aun con cantidades iguales, los tableros demasiado estrechos (como $8 times 2$) o con muy pocas filas carecen de diagonales intermedias para que los alfiles se sorteen. Tercero, como un movimiento diagonal en un tablero de ancho $n$ avanza a lo sumo $n - 1$ filas, con $n$ fijo cada alfil efectúa al menos $ceil((m - 1) / (n - 1))$ rebotes entre los bordes laterales, lo que permite conjeturar que el mínimo por pieza crece asintóticamente en proporción a $m / n$. Queda abierto caracterizar las dimensiones $(m, n)$ en que el intercambio es factible y hallar una fórmula cerrada para su mínimo.
]

== Caballos

#proposition(name: [Intercambio de caballos])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ caballos blancos de la fila $1$ con los $8$ caballos negros de la fila $8$ es $64$.
] <prop:knights>

#proof[
  *Cota inferior.* Un caballo cambia su fila en $1$ o $2$ unidades por salto, así que cada uno de los $16$ necesita al menos $ceil(7 / 2) = 4$ saltos: $T >= 64$.

  *Construcción óptima.* Alcanzar $T = 64$ exige que cada caballo dé exactamente $4$ saltos hacia adelante, tres de $+2$ filas y uno de $+1$. Mediante búsqueda computacional (véase la Declaración de herramientas) se obtuvo la secuencia de la @sec:ap-caballos, con la siguiente estructura:
  + *Simetría central par a par:* cada movimiento blanco $2k - 1$ y el negro $2k$ que le sigue se corresponden por la rotación de $180 degree$, $(j, r) |-> (9 - j, 9 - r)$ (p. ej., `f1-e3` y `c8-d6`).
  + *Perfiles monótonos de filas:* los blancos de `a1, b1, c1, f1` recorren las filas $1 -> 3 -> 4 -> 6 -> 8$, y los de `d1, e1, g1, h1`, $1 -> 2 -> 4 -> 6 -> 8$; los negros siguen los perfiles simétricos $8 -> 6 -> 5 -> 3 -> 1$ y $8 -> 7 -> 5 -> 3 -> 1$.
  + *Desfase temporal:* las trayectorias que comparten casillas de paso (como `b6`, `c6`, `f3` y `g3`) se intercalan de modo que cada casilla se desocupa antes del siguiente salto a ella.
]

#remark(title: [Enfoque mediante teoría de grafos y complejidad])[
  Como el caballo es un _leaper_, un movimiento solo exige que la casilla destino esté vacía, y el problema equivale a _colored pebble motion_ sobre el grafo bipartito de saltos $G_N$. Este enfoque se origina en el problema de Guarini (1512) en $3 times 3$, resuelto desplegando el grafo de movimientos en ciclos disjuntos (Dudeney @dudeney1917). Iordan @iordan2019 @iordan2021 usó descomposiciones en grafos bipartitos y tripartitos para obtener algoritmos eficientes de intercambio óptimo de filas de caballos en tableros rectangulares estructurados. Para tableros y configuraciones arbitrarias, en cambio, Siegel @siegel2026 demostró que el problema es NP-hard, en consonancia con el caso general de fichas bicolores en grafos @yu2013 @yu2015.
]
