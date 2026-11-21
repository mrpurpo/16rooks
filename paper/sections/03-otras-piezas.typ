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

  *Construcción óptima.* Como $m >= 3$ y $n >= 2$, los dos reyes de cada columna $c_j$ pueden intercambiarse en $2(m - 1)$ movimientos usando una columna vecina solo de paso: el rey blanco se aparta en diagonal a la fila $2$ de la columna vecina ($1$ movimiento), el negro baja recto por $c_j$ hasta $(j, 1)$ ($m - 1$ movimientos), y el blanco vuelve en diagonal a $(j, 3)$ para terminar de subir por $c_j$ ($m - 2$ movimientos). Como los dos pasos diagonales también avanzan una fila hacia el destino, ningún rey pierde turnos verticales. Repitiendo la maniobra en las $n$ columnas se obtienen $2n(m - 1)$ movimientos (véase la secuencia de $112$ movimientos para $8 times 8$ en la @sec:ap-reyes).
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

  *Cota inferior.* Desde una columna central, una diagonal que parte de la fila $1$ u $8$ recorre a lo sumo $6$ filas antes del borde lateral, así que no alcanza la fila opuesta. La primera dama de cada par central en moverse tiene además su columna bloqueada por la adversaria, por lo que necesita al menos $2$ movimientos y la segunda al menos $1$, es decir, $3$ movimientos por par. En las esquinas, la primera dama en moverse encuentra ocupadas su columna y su diagonal hacia la esquina opuesta y necesita $2$ movimientos, y las otras tres al menos $1$, por lo que deben hacer $5$ en total. Sumando,
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

  *Construcción óptima.* La cota $T_1 = 15$ en las casillas oscuras se alcanza haciendo que uno de los alfiles de las esquinas (`h8`) cruce la diagonal principal `h8`–`a1` en un solo movimiento (una vez despejadas ambas esquinas), mientras que los otros $7$ alfiles llegan a la fila opuesta en exactamente $2$ movimientos cada uno, pasando por una casilla intermedia ($1 + 7 dot 2 = 15$). Aplicando la reflexión horizontal de esta secuencia a las casillas claras se obtienen los $30$ movimientos listados en la @sec:ap-alfiles.
]

#remark(title: [Sobre la generalización a tableros $m times n$])[
  Al analizar el caso $m times n$, surgen algunas obstrucciones adicionales. Primero, el color exige que las filas $1$ y $m$ tengan las mismas cantidades de casillas de cada color, lo que falla si $m$ es par y $n$ impar, haciendo imposible el intercambio. Segundo, aun con cantidades iguales, los tableros demasiado estrechos (como $8 times 2$) o con muy pocas filas carecen de diagonales intermedias para que los alfiles se sorteen. Tercero, como un movimiento diagonal en un tablero de ancho $n$ avanza a lo sumo $n - 1$ filas, con $n$ fijo cada alfil efectúa al menos $ceil((m - 1) / (n - 1))$ rebotes entre los bordes laterales, lo que permite conjeturar que el mínimo por pieza crece asintóticamente en proporción a $m / n$. Queda abierto caracterizar las dimensiones $(m, n)$ en que el intercambio es factible y hallar una fórmula cerrada para su mínimo.
]

== Caballos

#proposition(name: [Intercambio de caballos])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ caballos blancos de la fila $1$ con los $8$ caballos negros de la fila $8$ es $64$.
] <prop:knights>

#proof[
  *Cota inferior.* Un caballo cambia su fila en $1$ o $2$ unidades por salto, así que cada uno de los $16$ necesita al menos $ceil(7 / 2) = 4$ saltos: $T >= 64$.

  *Construcción óptima.* Alcanzar $T = 64$ exige que cada caballo realice exactamente $4$ saltos hacia adelante (tres de avance vertical $+2$ y uno de $+1$). Mediante búsqueda computacional (véase la Declaración de herramientas) se obtuvo la secuencia de la @sec:ap-caballos, en la cual cada jugada blanca $2k - 1$ y la jugada negra siguiente $2k$ son centralmente simétricas por la rotación de $180 degree$ del tablero, y las trayectorias se dividen en dos perfiles monótonos de filas ($1 -> 3 -> 4 -> 6 -> 8$ y $1 -> 2 -> 4 -> 6 -> 8$, junto con sus simétricos) desfasados en el tiempo para no coincidir en las casillas intermedias de paso.
]

#remark(title: [Enfoque mediante teoría de grafos y complejidad])[
  Como el caballo es un _leaper_, un movimiento solo exige que la casilla destino esté vacía, y el problema equivale a _colored pebble motion_ sobre el grafo bipartito de saltos $G_N$. Este enfoque se origina en el problema de Guarini (1512) en $3 times 3$, resuelto desplegando el grafo de movimientos en ciclos disjuntos (Dudeney @dudeney1917). Iordan @iordan2019 @iordan2021 usó descomposiciones en grafos bipartitos y tripartitos para obtener algoritmos eficientes de intercambio óptimo de filas de caballos en tableros rectangulares estructurados. Para tableros y configuraciones arbitrarias, en cambio, Siegel @siegel2026 demostró que el problema es NP-hard, en consonancia con el caso general de fichas bicolores en grafos @yu2013 @yu2015.
]
