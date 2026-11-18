#import "../style.typ": *

= Variaciones con otras piezas en el tablero $8 times 8$ <sec:otras-piezas>

En esta sección analizamos las variaciones del Problema 1 obtenidas al reemplazar las torres por las restantes piezas del ajedrez en el tablero estándar de $8 times 8$.

== Peones

El intercambio de dos filas de peones es imposible: sin capturas, cada peón solo puede avanzar dentro de su propia columna y no puede sobrepasar a un peón adversario que bloquea su paso.

== Reyes

#proposition(name: [Intercambio de reyes])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ reyes blancos de la fila $1$ con los $8$ reyes negros de la fila $8$ es $112$.
] <prop:kings>

#proof[
  Cada uno de los $16$ reyes debe recorrer una distancia vertical de $7$ filas y avanza a lo sumo una fila por movimiento, lo que entrega inmediatamente la cota inferior $T >= 16 dot 7 = 112$. Para alcanzar la igualdad, basta notar que dos reyes ubicados inicialmente en la misma columna pueden avanzar hacia sus filas destino en paralelo y sortearse entre sí dando un paso diagonal hacia una columna adyacente (y regresando al paso siguiente): dichos pasos diagonales siguen avanzando una fila en la dirección objetivo, por lo que ningún rey pierde movimientos verticales y el intercambio completo se realiza en exactamente $7$ movimientos por rey, totalizando $112$.
]

Una posible secuencia de movimientos que llega a la solución es: (`a1-b2`, `a8-a7`, `a7-a6`, ..., `a2-a1`, `b2-a3`, `a3-a4`, ..., `a7-a8`), que toma $14$ movimientos para intercambiar dos reyes de una misma columna; repitiendo la misma maniobra en cada columna se obtiene $8 dot 14 = 112 = T$ (ver la construcción completa de $112$ movimientos en la @sec:ap-reyes).

Generalizando a un tablero mxn, tenemos 2n reyes y para que un rey llegue al otro lado debe realizar m-1 movimientos por lo menos, por lo que obtenemos la cota inferior $T >= 2n(m-1)$, y nuevamente podemos tratar cada fila por separado y obtener una construcción sencilla en el minimo de movimientos.

Generalizando este caso aún más, para un tablero de casillas arbitrarias y los reyes de color negro y color blanco en casillas arbitrarias, donde el problema es intercambiar las posiciones de los reyes de color opuesto, el grafo de movimientos generado es exactamente el de multi-color pebble motion. Por lo tanto, a partir de esta teoría, se puede responder si el intercambio se puede realizar (Goraly and Hassin) y se sabe que encontrar el menor numero de movimientos que lleguen a la solucion es NP-Hard (Yu-LaValle), este problema también se parece a un problema de robótica que es el de Multi-Agent path finding, donde también se obtiene que encontrar el óptimo es difícil.

== Damas

#proposition(name: [Intercambio de damas, Tokarev @tokarev2005])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar las $8$ damas blancas de la fila $1$ con las $8$ damas negras de la fila $8$ es $23$.
] <prop:queens>

Este caso fue resuelto por S. I. Tokarev @tokarev2005 mediante un argumento elemental de conteo por columnas: para cada una de las $6$ columnas centrales (`b` a `g`), la primera de las dos damas de dicha columna en moverse no puede llegar directamente a la fila opuesta (pues tanto su columna como las diagonales de largo $7$ que alcanzan la fila opuesta están bloqueadas o fuera de alcance), de modo que el par de damas de cada columna central requiere al menos $3$ movimientos en conjunto. Análogamente, entre las cuatro damas de las esquinas (`a1`, `a8`, `h1`, `h8`), la primera en moverse tampoco puede alcanzar directamente la fila opuesta, por lo que las cuatro esquinas necesitan al menos $5$ movimientos en total. Esto proporciona la cota inferior
$ T >= 6 dot 3 + 5 = 23, $
que se alcanza con la construcción exhibida en la @fig:damas-tokarev (ver transcripción explícita en la @sec:ap-damas).

#figure(
  image("/assets/image.png", width: 52%),
  caption: [Construcción en $23$ movimientos para el intercambio de damas @tokarev2005.],
) <fig:damas-tokarev>

== Alfiles

#proposition(name: [Intercambio de alfiles])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ alfiles blancos de la fila $1$ con los $8$ alfiles negros de la fila $8$ es $30$.
] <prop:bishops>

*Esquema del análisis.* Como cada alfil permanece siempre en casillas de un único color, el problema se descompone en dos subproblemas completamente independientes: uno sobre las casillas claras ($4$ alfiles blancos y $4$ negros) y otro sobre las casillas oscuras ($4$ alfiles blancos y $4$ negros), simétricos entre sí. Además, al rotar el tablero $45 degree$ y considerar las diagonales como las líneas de deslizamiento, cada subproblema monocromático exhibe una estructura estrechamente isomorfa al intercambio de torres sobre una grilla ortogonal, lo que sugiere aplicar un conteo de movimientos análogo al de la @sec:problema-principal.

Para el caso $8 times 8$ se observa que los alfiles no pueden cambiar de color de casilla, por lo que podemos dividir el problema en dos subproblemas de intercambio de $4$ alfiles negros y $4$ blancos. Cada alfil necesita al menos dos movimientos para llegar a una casilla destino, con la excepción de los alfiles situados en la diagonal principal, donde uno puede llegar en un solo movimiento si el opuesto se aparta previamente, requiriendo entre ambos un mínimo de $3$ movimientos. Sumando para un subproblema monocromático obtenemos $T_1 >= 3 + 2 dot 6 = 15$. Por simetría entre casillas oscuras y claras se concluye $T >= 15 + 15 = 30$.

Una construcción que alcanza el mínimo en casillas oscuras es (`b8-h2`, `a1-e5`, `e5-b8`, `h8-a1`, `g1-d4`, `d4-h8`, `h2-g1`, `c1-a3`, `f8-h6`, `a3-f8`, `h6-c1`, `e1-a5`, `d8-h4`, `a5-d8`, `h4-e1`), y su reflexión horizontal resuelve las casillas claras (ver secuencia completa de $30$ movimientos en la @sec:ap-alfiles).

Para la generalizacion en un tablero mxn se debería tener en cuenta si es posible una solucion, para lo cual se debe analizar la cantidad de alfiles de cada color en casillas blancas o negras, por ejemplo el caso 7x7 es imposible de solucionar ya que hay 3 alfiles negros en casillas blancas y 4 alfiles blancos en casillas blancas, por lo tanto no hay suficientes casillas para los alfiles blancos y esto implica que no existe solución en este caso. También puede suceder que esto si se cumpla, pero las dimensiones del tablero sean suficientemente bajas para que los alfiles no tengan libertad de movimiento suficiente para llegar a la posición solución, esto se observa en el caso de 8 filas y 2 columnas por ejemplo. También si el número de filas es suficientemente bajo de la misma manera es imposible llegar al solución (analizar por casos porque son pocos, no se me ocurre otro tipo de situación de solución unreachable). Además, mientras mayor sea el número de filas, más tendrá que viajar cada alfil y el número de movimientos que tiene que realizar cada uno para llegar a una casilla aceptada aumenta proporcionalmente. Por lo que se deja abierto encontrar una fórmula cerrada para el caso de un tablero mxn para los alfiles.

== Caballos

#proposition(name: [Intercambio de caballos])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ caballos blancos de la fila $1$ con los $8$ caballos negros de la fila $8$ es $64$.
] <prop:knights>

*Esquema del análisis.* Dado que el caballo es una pieza de salto (_leaper_) cuya legalidad de movimiento depende únicamente de que la casilla destino esté vacía, el problema se modela directamente como _colored pebble motion_ sobre el grafo de saltos del caballo $G_N$ del tablero $8 times 8$. De manera análoga a la resolución clásica del problema de Guarini mediante el despliegue del grafo de movimientos @dudeney1917 y a sus extensiones modernas vía grafos bipartitos y tripartitos @iordan2019 @iordan2021, el análisis de distancias mínimas en $G_N$ (junto con el carácter bipartito del grafo) permite acotar el número mínimo de saltos por caballo y construir un intercambio sin bloqueos.

En un tablero de $8 times 8$, como mínimo cada caballo debe dar $4$ saltos para llegar a la fila opuesta, por lo que la cota inferior es $T >= 4 dot 16 = 64$. Esta cota se alcanza mediante la secuencia explícita de $64$ movimientos detallada en la @sec:ap-caballos.

Notar que los problemas con caballos se suelen analizar con grafos ya que estos describen el movimiento de los caballos de forma más abstracta y nos da a disposición las herramientas de teoría de grafos. En específico, al confeccionar el grafo del movimiento de los caballos en un tablero general se forma un grafo bipartito (utilizar las referencias para explicar los avances aquí), y con esto se han encontrado métodos computacionales de llegar a la solución óptima para intercambiar los caballos de posición, sin embargo, el caso más general sigue siendo NP-hard ()
