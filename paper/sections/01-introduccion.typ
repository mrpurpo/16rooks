#import "../style.typ": *
#import "@preview/board-n-pieces:0.9.0": board, fen

= Introducción <sec:intro>

El presente trabajo aborda el Problema 1 de la Demuestratón del Encuentro Nacional de Ingeniería Matemática (ENIM 2026) @enim2026:

#problem(name: [Demuestratón ENIM 2026])[
  Sobre un tablero de ajedrez se colocan $8$ torres blancas en la primera fila y $8$ torres negras en la última. Se las puede mover horizontal o verticalmente todas las casillas que se quiera, siempre que no haya otra torre en el camino (incluida la posición final). ¿Cuál es el número mínimo de movimientos para dejar a todas las torres blancas en la última fila y a todas las negras en la primera? Estudie variaciones del problema reemplazando las torres por otras piezas del ajedrez.
]

#figure(
  board(
    fen("RRRRRRRR/8/8/8/8/8/8/rrrrrrrr"),
    square-size: 0.65cm,
    white-square-fill: luma(245),
    black-square-fill: luma(205),
    stroke: 0.6pt + black,
    display-numbers: false,
  ),
  caption: [Configuración inicial en el tablero estándar de $8 times 8$.],
) <fig:config-inicial>

Suponemos que las piezas de un mismo color son indistinguibles (fichas _no etiquetadas_, _unlabeled_), que no se exige alternancia de turnos y que no hay capturas: toda casilla atravesada o alcanzada en un movimiento debe estar vacía.

Nuestro objetivo es determinar y demostrar el número mínimo exacto de movimientos para intercambiar dos filas opuestas de $n$ torres en un tablero de $m times n$ ($m >= 3$, $n >= 2$), y resolver las variaciones en el tablero de $8 times 8$ con las demás piezas del ajedrez.

== Estado del problema <sec:estado>

Los problemas de intercambio de piezas se formulan dentro del modelo de _movimiento de fichas multicolores en grafos_ (_multi-color pebble motion_) @goraly2010: sobre un grafo simple conexo de $N$ vértices hay $p <= N$ fichas repartidas en clases de color de piezas indistinguibles, cada vértice aloja a lo sumo una ficha y un movimiento traslada una ficha a un vértice adyacente vacío. Se distinguen la versión de _factibilidad_ (si una configuración puede transformarse en otra) y la de _optimalidad_ (el número mínimo de movimientos o, como problema de decisión, si basta con $k$). El caso de fichas distinguibles se remonta al puzle del $15$ en una grilla de $4 times 4$, generalizado a grafos arbitrarios mediante el grupo alternante por Wilson @wilson1974 y acotado en $O(N^3)$ movimientos por Kornhauser, Miller y Spirakis @kornhauser1984. Para fichas agrupadas por colores, Goraly y Hassin @goraly2010 y Fujita et al. @fujita2012 caracterizaron las configuraciones alcanzables y demostraron que la factibilidad se decide en tiempo lineal.

Este modelo describe directamente a las piezas de paso unitario o salto fijo (_leapers_: reyes y caballos), cuyo grafo de adyacencia es estático. Las piezas deslizantes (torres, alfiles y damas), que recorren una línea entera de casillas vacías en un turno, corresponden en cambio al modelo de _reconfiguración en grafos y grillas_ de Călinescu, Dumitrescu y Pach @calinescu2008, donde un movimiento desplaza una ficha no etiquetada por cualquier camino de vértices vacíos. La torre en un tablero de $m times n$ es el caso de caminos rectilíneos, para el cual los autores dan cotas superiores e inferiores en el peor caso.

En tableros de ajedrez, el antecedente más cercano es el problema de Tokarev @tokarev2005: intercambiar $8$ damas blancas y $8$ negras en las filas extremas de un tablero de $8 times 8$ en $23$ movimientos. Para caballos, el problema se origina con Guarini (1512) en un tablero de $3 times 3$ @dudeney1917 y fue extendido a tableros de $3 times n$ y $4n times 4n$ por Iordan @iordan2019 @iordan2021 mediante grafos bipartitos y tripartitos. En cuanto a complejidad, aunque la factibilidad para fichas coloreadas es polinomial @goraly2010, la optimalidad es NP-hard en grafos generales incluso con dos clases de color del mismo tamaño (Yu y LaValle @yu2013 @yu2015; para puzles deslizantes etiquetados, véase @ratner1990 @hearn2009), para el deslizamiento rectilíneo en grillas (Cooper et al. @cooper2021) y para el intercambio óptimo de caballos en tableros conexos generales (Siegel @siegel2026). Frente a esta intratabilidad general, mostramos que la simetría de dos filas opuestas en un tablero rectangular permite determinar exactamente el mínimo.

== Resultados principales <sec:resultados-principales>

En la @sec:problema-principal demostramos (@thm:rooks y @prop:rows) que, para $m >= 3$ y $n >= 2$, el mínimo para torres es
$
  T_min (m, n) = cases(
    4n + 1 & quad "si" m >= 5\,,
    4n + 2 & quad "si" m in {3, 4},
  )
$
es decir, $T_min (8, 8) = 33$ en el tablero estándar; para $m = 2$ el intercambio es imposible por falta de casillas vacías.

En la @sec:otras-piezas determinamos el mínimo en $8 times 8$ para las demás piezas:
- *Peones:* imposible ($T_min = infinity$).
- *Reyes (@prop:kings):* $112$ movimientos ($2n(m - 1)$ en general, para $m >= 3$, $n >= 2$).
- *Damas (@prop:queens, Tokarev @tokarev2005):* $23$ movimientos.
- *Alfiles (@prop:bishops):* $30$ movimientos ($15$ por color de casilla).
- *Caballos (@prop:knights):* $64$ movimientos ($4$ saltos por caballo).
