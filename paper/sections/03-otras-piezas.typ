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
  Cada uno de los $16$ reyes debe recorrer una distancia vertical de $7$ filas y avanza a lo sumo una fila por movimiento, lo que entrega inmediatamente la cota inferior $T >= 16 dot 7 = 98$. Para alcanzar la igualdad, basta notar que dos reyes ubicados inicialmente en la misma columna pueden avanzar hacia sus filas destino en paralelo y sortearse entre sí dando un paso diagonal hacia una columna adyacente (y regresando al paso siguiente): dichos pasos diagonales siguen avanzando una fila en la dirección objetivo, por lo que ningún rey pierde movimientos verticales y el intercambio completo se realiza en exactamente $7$ movimientos por rey, totalizando $112$.
]

Una posible secuencia de movimientos que llega a la solución es: (a1-b2, a8-a7, a7-a6, ..., a2-a1, b2-a3, a3-a4, ..., a7-a8) que llega a 14 movimientos para intercambiar dos reyes de una columna, y realizamos la misma maniobra para cada columna para obtener $8*14=112=T$. La construcción completa debe estar en el apéndice:

#figure(
  table(
    columns: 8,
    align: center,
    stroke: 0.5pt,
    table.header([*N.º*], [*Movimiento*], [*N.º*], [*Movimiento*], [*N.º*], [*Movimiento*], [*N.º*], [*Movimiento*]),
    [1], [B a1-b2], [29], [B c1-d2], [57], [B e1-f2], [85], [B g1-h2],
    [2], [N a8-a7], [30], [N c8-c7], [58], [N e8-e7], [86], [N g8-g7],
    [3], [N a7-a6], [31], [N c7-c6], [59], [N e7-e6], [87], [N g7-g6],
    [4], [N a6-a5], [32], [N c6-c5], [60], [N e6-e5], [88], [N g6-g5],
    [5], [N a5-a4], [33], [N c5-c4], [61], [N e5-e4], [89], [N g5-g4],
    [6], [N a4-a3], [34], [N c4-c3], [62], [N e4-e3], [90], [N g4-g3],
    [7], [N a3-a2], [35], [N c3-c2], [63], [N e3-e2], [91], [N g3-g2],
    [8], [N a2-a1], [36], [N c2-c1], [64], [N e2-e1], [92], [N g2-g1],
    [9], [B b2-a3], [37], [B d2-c3], [65], [B f2-e3], [93], [B h2-g3],
    [10], [B a3-a4], [38], [B c3-c4], [66], [B e3-e4], [94], [B g3-g4],
    [11], [B a4-a5], [39], [B c4-c5], [67], [B e4-e5], [95], [B g4-g5],
    [12], [B a5-a6], [40], [B c5-c6], [68], [B e5-e6], [96], [B g5-g6],
    [13], [B a6-a7], [41], [B c6-c7], [69], [B e6-e7], [97], [B g6-g7],
    [14], [B a7-a8], [42], [B c7-c8], [70], [B e7-e8], [98], [B g7-g8],
    [15], [B b1-c2], [43], [B d1-e2], [71], [B f1-g2], [99], [B h1-g2],
    [16], [N b8-b7], [44], [N d8-d7], [72], [N f8-f7], [100], [N h8-h7],
    [17], [N b7-b6], [45], [N d7-d6], [73], [N f7-f6], [101], [N h7-h6],
    [18], [N b6-b5], [46], [N d6-d5], [74], [N f6-f5], [102], [N h6-h5],
    [19], [N b5-b4], [47], [N d5-d4], [75], [N f5-f4], [103], [N h5-h4],
    [20], [N b4-b3], [48], [N d4-d3], [76], [N f4-f3], [104], [N h4-h3],
    [21], [N b3-b2], [49], [N d3-d2], [77], [N f3-f2], [105], [N h3-h2],
    [22], [N b2-b1], [50], [N d2-d1], [78], [N f2-f1], [106], [N h2-h1],
    [23], [B c2-b3], [51], [B e2-d3], [79], [B g2-f3], [107], [B g2-h3],
    [24], [B b3-b4], [52], [B d3-d4], [80], [B f3-f4], [108], [B h3-h4],
    [25], [B b4-b5], [53], [B d4-d5], [81], [B f4-f5], [109], [B h4-h5],
    [26], [B b5-b6], [54], [B d5-d6], [82], [B f5-f6], [110], [B h5-h6],
    [27], [B b6-b7], [55], [B d6-d7], [83], [B f6-f7], [111], [B h6-h7],
    [28], [B b7-b8], [56], [B d7-d8], [84], [B f7-f8], [112], [B h7-h8],
  ),
  caption: [Solución de 112 movimientos para el intercambio de reyes en el tablero de $8 times 8$ (B = blancas, N = negras).],
)

Generalizando a un tablero mxn, tenemos 2n reyes y para que un rey llegue al otro lado debe realizar m-1 movimientos por lo menos, por lo que obtenemos la cota inferior $T >= 2n(m-1)$, y nuevamente podemos tratar cada fila por separado y obtener una construcción sencilla en el minimo de movimientos.

Generalizando este caso aún más, para un tablero de casillas arbitrarias y los reyes de color negro y color blanco en casillas arbitrarias, donde el problema es intercambiar las posiciones de los reyes de color opuesto, el grafo de movimientos generado es exactamente el de multi-color pebble motion. Por lo tanto, a partir de esta teoría, se puede responder si el intercambio se puede realizar (Goraly and Hassin) y se sabe que encontrar el menor numero de movimientos que lleguen a la solucion es NP-Hard (Yu-LaValle), este problema también se parece a un problema de robótica que es el de Multi-Agent path finding, donde también se obtiene que encontrar el óptimo es difícil.

== Damas

#proposition(name: [Intercambio de damas, Tokarev @tokarev2005])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar las $8$ damas blancas de la fila $1$ con las $8$ damas negras de la fila $8$ es $23$.
] <prop:queens>

Este caso fue resuelto por S. I. Tokarev @tokarev2005 mediante un argumento elemental de conteo por columnas: para cada una de las $6$ columnas centrales (`b` a `g`), la primera de las dos damas de dicha columna en moverse no puede llegar directamente a la fila opuesta (pues tanto su columna como las diagonales de largo $7$ que alcanzan la fila opuesta están bloqueadas o fuera de alcance), de modo que el par de damas de cada columna central requiere al menos $3$ movimientos en conjunto. Análogamente, entre las cuatro damas de las esquinas (`a1`, `a8`, `h1`, `h8`), la primera en moverse tampoco puede alcanzar directamente la fila opuesta, por lo que las cuatro esquinas necesitan al menos $5$ movimientos en total. Esto proporciona la cota inferior
$ T >= 6 dot 3 + 5 = 23, $
que se alcanza con la construcción exhibida en la @fig:damas-tokarev.

#figure(
  image("/assets/image.png", width: 52%),
  caption: [Construcción en $23$ movimientos para el intercambio de damas @tokarev2005.],
) <fig:damas-tokarev>

== Alfiles

#proposition(name: [Intercambio de alfiles])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ alfiles blancos de la fila $1$ con los $8$ alfiles negros de la fila $8$ es $32$.
] <prop:bishops>

*Esquema del análisis.* Como cada alfil permanece siempre en casillas de un único color, el problema se descompone en dos subproblemas completamente independientes: uno sobre las casillas claras ($4$ alfiles blancos y $4$ negros) y otro sobre las casillas oscuras ($4$ alfiles blancos y $4$ negros), simétricos entre sí. Además, al rotar el tablero $45 degree$ y considerar las diagonales como las líneas de deslizamiento, cada subproblema monocromático exhibe una estructura estrechamente isomorfa al intercambio de torres sobre una grilla ortogonal, lo que sugiere aplicar un conteo de movimientos análogo al de la @sec:problema-principal.

Para el caso 8x8 se puede observar que los alfiles no pueden cambiar de color de casilla, por lo que podemos tomar el problema como dos subproblemas de intercambio de 4 alfiles de color negro y 4 de color blanco, así reduciendo el problema para evitar clutter. Ahora, cada alfil necesita al menos dos movimientos para llegar a una casilla aceptada, con la excepcion de los alfiles de las diagonales, que tal como en el ejemplo de las torres, uno podría llegar en un movimiento si el opuesto se aparta de la diagonal, por lo que para que ambos lleguen a casillas aumentas se necesitan como mínimo 3 movimientos. Juntando esto para un solo subproblema, obtenemos que $T_1 >= 3 + 2*6 = 15$. Ya que el problema en las casillas blancas es el mismo que el de las casillas negras, podemos hacer la misma combinación que alcance el mínimo en la otra y obtener $T >= 15 + 15 = 30$.

Una construcción que alcanza el mínimo es la siguiente: (b2-h2, a1-e5, e5-b8, h8-a1, g1-d4, d4-h8, h2-g1, c1-a3, f8-h6, a3-f8, h6-c1, e1-a5, d8-h4, a5-d8, h4-e1)

Para la generalizacion en un tablero mxn se debería tener en cuenta si es posible una solucion, para lo cual se debe analizar la cantidad de alfiles de cada color en casillas blancas o negras, por ejemplo el caso 7x7 es imposible de solucionar ya que hay 3 alfiles negros en casillas blancas y 4 alfiles blancos en casillas blancas, por lo tanto no hay suficientes casillas para los alfiles blancos y esto implica que no existe solución en este caso. También puede suceder que esto si se cumpla, pero las dimensiones del tablero sean suficientemente bajas para que los alfiles no tengan libertad de movimiento suficiente para llegar a la posición solución, esto se observa en el caso de 8 filas y 2 columnas por ejemplo. También si el número de filas es suficientemente bajo de la misma manera es imposible llegar al solución (analizar por casos porque son pocos, no se me ocurre otro tipo de situación de solución unreachable). Además, mientras mayor sea el número de filas, más tendrá que viajar cada alfil y el número de movimientos que tiene que realizar cada uno para llegar a una casilla aceptada aumenta proporcionalmente. Por lo que se deja abierto encontrar una fórmula cerrada para el caso de un tablero mxn para los alfiles.

== Caballos

#proposition(name: [Intercambio de caballos])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ caballos blancos de la fila $1$ con los $8$ caballos negros de la fila $8$ es $64$.
] <prop:knights>

*Esquema del análisis.* Dado que el caballo es una pieza de salto (_leaper_) cuya legalidad de movimiento depende únicamente de que la casilla destino esté vacía, el problema se modela directamente como _colored pebble motion_ sobre el grafo de saltos del caballo $G_N$ del tablero $8 times 8$. De manera análoga a la resolución clásica del problema de Guarini mediante el despliegue del grafo de movimientos @dudeney1917 y a sus extensiones modernas vía grafos bipartitos y tripartitos @iordan2019 @iordan2021, el análisis de distancias mínimas en $G_N$ (junto con el carácter bipartito del grafo) permite acotar el número mínimo de saltos por caballo y construir un intercambio sin bloqueos.

En un tablero 8x8, como mínimo, un caballo debe dar 4 saltos para llegar a una casilla aceptada, por lo que el mínimo sería $T >= 4*16 = 64$, y la una construcción como esta llega al mínimo (ver el resto en Apéndice):

#figure(
  table(
    columns: 8,
    align: center,
    stroke: 0.5pt,
    table.header([*N.º*], [*Movimiento*], [*N.º*], [*Movimiento*], [*N.º*], [*Movimiento*], [*N.º*], [*Movimiento*]),
    [1], [B f1-e3], [17], [B d1-b2], [33], [B e1-g2], [49], [B e4-d6],
    [2], [N c8-d6], [18], [N e8-g7], [34], [N d8-b7], [50], [N d5-e3],
    [3], [B c1-d3], [19], [B e2-f4], [35], [B c6-d8], [51], [B f6-g8],
    [4], [N f8-e6], [20], [N d7-c5], [36], [N f3-e1], [52], [N c3-b1],
    [5], [B a1-b3], [21], [B d3-b4], [37], [B c4-b6], [53], [B b6-c8],
    [6], [N h8-g6], [22], [N e6-g5], [38], [N f5-g3], [54], [N g3-f1],
    [7], [B g1-e2], [23], [B f2-e4], [39], [B b6-a8], [55], [B g2-h4],
    [8], [N b8-d7], [24], [N c7-d5], [40], [N g3-h1], [56], [N b7-a5],
    [9], [B e3-g4], [25], [B d4-c6], [41], [B b4-c6], [57], [B h4-g6],
    [10], [N d6-b5], [26], [N e5-f3], [42], [N g5-f3], [58], [N a5-b3],
    [11], [B h1-f2], [27], [B f4-e6], [43], [B c6-b8], [59], [B e6-f8],
    [12], [N a8-c7], [28], [N c5-d3], [44], [N f3-g1], [60], [N d3-c1],
    [13], [B b1-a3], [29], [B a3-c4], [45], [B g4-f6], [61], [B d6-e8],
    [14], [N g8-h6], [30], [N h6-f5], [46], [N b5-c3], [62], [N e3-d1],
    [15], [B b3-d4], [31], [B b2-a4], [47], [B a4-b6], [63], [B g6-h8],
    [16], [N g6-e5], [32], [N g7-h5], [48], [N h5-g3], [64], [N b3-a1],
  ),
  caption: [Solución de 64 movimientos para el intercambio de caballos en el tablero de $8 times 8$ (B = blancas, N = negras).],
)

Notar que los problemas con caballos se suelen analizar con grafos ya que estos describen el movimiento de los caballos de forma más abstracta y nos da a disposición las herramientas de teoría de grafos. En específico, al confeccionar el grafo del movimiento de los caballos en un tablero general se forma un grafo bipartito (utilizar las referencias para explicar los avances aquí), y con esto se han encontrado métodos computacionales de llegar a la solución óptima para intercambiar los caballos de posición, sin embargo, el caso más general sigue siendo NP-hard ()
