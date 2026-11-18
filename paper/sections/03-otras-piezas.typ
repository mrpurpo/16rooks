#import "../style.typ": *

= Variaciones con otras piezas en el tablero $8 times 8$ <sec:otras-piezas>

En esta sección estudiamos las variaciones del Problema 1 obtenidas al reemplazar las torres por las restantes piezas del ajedrez en el tablero estándar de $8 times 8$, discutiendo además sus extensiones a tableros de $m times n$ y su conexión con la literatura revisada en la @sec:estado.

== Peones

El intercambio de dos filas de peones es imposible: en ausencia de capturas, cada peón solo puede avanzar dentro de su propia columna y no puede sobrepasar a un peón adversario que bloquea su paso.

== Reyes

#proposition(name: [Intercambio de reyes])[
  En un tablero de $m >= 3$ filas y $n >= 2$ columnas, el número mínimo de movimientos para intercambiar $n$ reyes blancos en la fila $1$ con $n$ reyes negros en la fila $m$ es
  $ T_min (m, n) = 2n(m - 1). $
  En particular, para el tablero estándar de $8 times 8$, el mínimo es $112$.
] <prop:kings>

#proof[
  *Cota inferior.* Cada uno de los $2n$ reyes debe recorrer una distancia vertical de $m - 1$ filas avanzando a lo sumo una fila por movimiento, de donde se sigue inmediatamente que $T >= 2n(m - 1)$.

  *Construcción óptima.* Como $m >= 3$ y $n >= 2$, podemos intercambiar los dos reyes de cada columna $c$ de manera independiente utilizando una columna adyacente $c'$ solo de forma transitoria en la fila $2$: el rey blanco da un paso diagonal $(c, 1) -> (c', 2)$ ($1$ movimiento), el rey negro desciende recto $(c, m) -> (c, m - 1) -> dots -> (c, 1)$ ($m - 1$ movimientos) y finalmente el rey blanco regresa diagonalmente $(c', 2) -> (c, 3)$ y asciende recto hasta $(c, m)$ ($m - 2$ movimientos). Ningún rey pierde pasos verticales, por lo que cada columna requiere exactamente $2(m - 1)$ movimientos y las $n$ columnas en conjunto alcanzan $2n(m - 1)$. Para $m = n = 8$, la maniobra en la primera columna es `a1-b2`, `a8-a7`, ..., `a2-a1`, `b2-a3`, `a3-a4`, ..., `a7-a8` ($14$ movimientos), y su repetición sobre las $8$ columnas proporciona la secuencia explícita de $112$ movimientos listada en la @sec:ap-reyes.
]

#remark(title: [Relación con _pebble motion_ y _multi-agent path finding_])[
  Si el problema se generaliza a un tablero arbitrario con posiciones iniciales y finales arbitrarias de reyes blancos y negros, el grafo de movimientos coincide exactamente con el modelo de _multi-color pebble motion_ sobre la grilla con diagonales. En ese régimen general, la factibilidad puede decidirse en tiempo lineal mediante el algoritmo de Goraly y Hassin @goraly2010 (véase también Fujita et al. @fujita2012), pero hallar una secuencia de longitud mínima es NP-hard incluso con solo dos clases de color, tal como demostraron Yu y LaValle @yu2013 @yu2015 en el contexto de _multi-agent path finding_ (véase el panorama de Ma @ma2022).
]

== Damas

#proposition(name: [Intercambio de damas, Tokarev @tokarev2005])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar las $8$ damas blancas de la fila $1$ con las $8$ damas negras de la fila $8$ es $23$.
] <prop:queens>

#proof[
  Seguimos el argumento elemental de S. I. Tokarev @tokarev2005. Para cada una de las $6$ columnas centrales (`b` a `g`), la primera de las dos damas de dicha columna en moverse no puede alcanzar la fila opuesta en un solo movimiento: su columna está bloqueada por la dama contraria y ninguna diagonal que parta de las casillas `b1`–`g1` o `b8`–`g8` tiene longitud vertical $7$ (pues recorrer $7$ filas en diagonal exige desplazarse también $7$ columnas, lo cual solo es posible desde las esquinas). Por tanto, esa primera dama requiere al menos $2$ movimientos y la otra al menos $1$, sumando al menos $3$ movimientos por cada columna central.

  Análogamente, entre las cuatro damas de las esquinas (`a1`, `a8`, `h1`, `h8`), la primera en moverse encuentra ocupadas tanto su columna como la diagonal principal hacia la esquina opuesta, por lo que tampoco puede llegar a la fila destino en un movimiento y requiere al menos $2$, mientras que las otras tres necesitan al menos $1$ cada una; esto da al menos $5$ movimientos para el grupo de las esquinas. Sumando sobre todos los grupos se obtiene la cota inferior
  $ T >= 6 dot 3 + 5 = 23. $

  La igualdad se alcanza mediante la construcción de $23$ movimientos de Tokarev @tokarev2005 ilustrada en la @fig:damas-tokarev y transcrita explícitamente en la @sec:ap-damas (respetando incluso la alternancia estricta de turnos).
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
  Como cada alfil se desplaza únicamente por casillas de un mismo color, el problema se descompone en dos subproblemas independientes y simétricos: uno sobre las casillas oscuras ($4$ alfiles blancos en `a1, c1, e1, g1` y $4$ negros en `b8, d8, f8, h8`) y otro sobre las casillas claras ($4$ blancos en `b1, d1, f1, h1` y $4$ negros en `a8, c8, e8, g8`).

  *Cota inferior.* Consideremos primero el subproblema de casillas oscuras. Para ir de la fila $1$ a la fila $8$ en un solo movimiento diagonal se requiere un desplazamiento horizontal de $7$ columnas, lo que únicamente es posible a lo largo de la diagonal principal `a1`–`h8`. En consecuencia, los $6$ alfiles que no están en `a1` ni en `h8` necesitan al menos $2$ movimientos cada uno. Para el par en las esquinas `a1` y `h8`, el primero de los dos en moverse encuentra la esquina opuesta ocupada y no puede llegar directamente a la fila destino, por lo que necesita al menos $2$ movimientos mientras que el segundo requiere al menos $1$ (al menos $3$ movimientos entre ambos). Así, el subproblema de casillas oscuras requiere al menos
  $ T_1 >= 3 + 6 dot 2 = 15 $
  movimientos. Por simetría, el subproblema de casillas claras también requiere al menos $15$ movimientos, luego $T >= 15 + 15 = 30$.

  *Construcción óptima.* El subproblema de casillas oscuras se resuelve en exactamente $15$ movimientos mediante la secuencia (`b8-h2`, `a1-e5`, `e5-b8`, `h8-a1`, `g1-d4`, `d4-h8`, `h2-g1`, `c1-a3`, `f8-h6`, `a3-f8`, `h6-c1`, `e1-a5`, `d8-h4`, `a5-d8`, `h4-e1`). Aplicando su reflexión horizontal (`a` $arrow.l.r$ `h`) sobre las casillas claras se obtiene la solución completa de $30$ movimientos detallada en la @sec:ap-alfiles.
]

#remark(title: [Observación sobre la generalización a tableros $m times n$])[
  Al rotar el tablero $45 degree$ y tomar las diagonales como líneas de deslizamiento, cada subproblema monocromático adquiere una estructura afín al intercambio de torres de la @sec:problema-principal, pero con obstrucciones adicionales en tableros generales de $m times n$:
  - *Invariante de color de casillas:* Para que el intercambio sea factible, la fila $1$ y la fila $m$ deben contener el mismo número de casillas de cada color. Esta condición falla siempre que $m$ es par y $n$ es impar (por ejemplo, en un tablero de $8 times 7$, la fila $1$ tiene $4$ casillas oscuras y $3$ claras, mientras que la fila $8$ tiene $3$ oscuras y $4$ claras), haciendo el intercambio imposible.
  - *Restricciones geométricas y crecimiento:* Incluso cuando las paridades coinciden, tableros demasiado estrechos (como $8 times 2$) o con muy pocas filas carecen de espacio para que los alfiles se sorteen. Por otra parte, al crecer $m$ manteniendo $n$ fijo, cada alfil debe rebotar sucesivamente entre los bordes laterales, aumentando el número mínimo de movimientos proporcionalmente a $m / n$. La obtención de una fórmula cerrada general para $m times n$ queda abierta.
]

== Caballos

#proposition(name: [Intercambio de caballos])[
  En un tablero de $8 times 8$, el número mínimo de movimientos para intercambiar los $8$ caballos blancos de la fila $1$ con los $8$ caballos negros de la fila $8$ es $64$.
] <prop:knights>

#proof[
  *Cota inferior.* Cada salto de caballo cambia la coordenada vertical en a lo sumo $2$ filas. Para recorrer la distancia vertical de $7$ filas entre la fila $1$ y la fila $8$, cada uno de los $16$ caballos necesita al menos $ceil(7 / 2) = 4$ saltos. Sumando sobre todas las piezas se obtiene $T >= 16 dot 4 = 64$.

  *Construcción óptima.* La igualdad se alcanza mediante la secuencia explícita de $64$ movimientos (con alternancia estricta de bandos y sin colisiones) listada en la @sec:ap-caballos.
]

#remark(title: [Enfoque por teoría de grafos y complejidad])[
  Al ser el caballo una pieza de salto (_leaper_), la legalidad de un movimiento depende únicamente de que la casilla destino esté vacía, por lo que el problema se modela exactamente como _colored pebble motion_ sobre el grafo de saltos del caballo $G_N$ (un grafo bipartito, pues cada salto alterna el color de la casilla; véase Knuth @knuth1994). Esta perspectiva proviene del despliegue del grafo en el problema clásico de Guarini (1512), popularizado por Dudeney @dudeney1917. En tableros rectangulares estructurados, Iordan @iordan2019 @iordan2021 aprovechó la estructura bipartita y tripartita de $G_N$ para obtener métodos eficientes de intercambio óptimo de filas de caballos. No obstante, para tableros y configuraciones generales, Siegel @siegel2026 demostró recientemente que determinar el número mínimo de movimientos en el problema óptimo de intercambio de caballos es NP-hard, en concordancia con la NP-dificultad general del movimiento óptimo de fichas bicolores en grafos @yu2013 @yu2015.
]
