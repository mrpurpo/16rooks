#import "../style.typ": *
#import "@preview/board-n-pieces:0.9.0": board, fen

= Introducción <sec:intro>

El presente trabajo aborda el Problema 1 de la Demuestratón del Encuentro Nacional de Ingeniería Matemática (ENIM 2026) @enim2026:

#problem(name: [Demuestratón ENIM 2026])[
  Sobre un tablero de ajedrez se colocan $8$ torres blancas en la primera fila y $8$ torres negras en la última. Se las puede mover horizontal o verticalmente todas las casillas que se quiera, siempre que no haya otra torre en el camino (incluida la posición final). ¿Cuál es el número mínimo de movimientos para dejar a todas las torres blancas en la última fila y a todas las negras en la primera? Estudie variaciones del problema reemplazando las torres por otras piezas del ajedrez.
]

#figure(
  board(
    fen("rrrrrrrr/8/8/8/8/8/8/RRRRRRRR"),
    square-size: 0.65cm,
    white-square-fill: luma(245),
    black-square-fill: luma(205),
    stroke: 0.6pt + black,
    display-numbers: false,
  ),
  caption: [Configuración inicial en el tablero estándar de $8 times 8$: ocho torres blancas en la primera fila y ocho torres negras en la última.],
) <fig:config-inicial>

En el planteamiento rigen las siguientes reglas: las piezas de un mismo color son indistinguibles entre sí (solo importa el conjunto final de casillas ocupadas por cada color), no se exige alternancia de turnos entre bandos y no están permitidas las capturas.

== Estado del problema <sec:estado>

El intercambio de dos filas de piezas en un tablero se sitúa en la intersección de tres líneas de la combinatoria y la informática teórica: el movimiento de fichas en grafos (_pebble motion on graphs_), la reconfiguración en grafos y grillas (_reconfigurations in graphs and grids_) y los puzles clásicos de intercambio de piezas de ajedrez. A diferencia de los problemas de alcanzabilidad —donde solo interesa decidir si una configuración final es accesible—, aquí buscamos determinar la longitud exacta de una secuencia mínima.

=== Movimiento de fichas en grafos (_Pebble Motion_) y fichas coloreadas

El desplazamiento de piezas sin capturas sobre un grafo discreto se modela mediante _pebble motion_ (o _multi-agent path finding_), donde los vértices representan casillas y cada movimiento traslada una ficha a un vértice adyacente vacío.

- *Fundamentos de alcanzabilidad y cotas generales.* El campo se inicia con Wilson @wilson1974, quien generalizó el puzle del $15$ a grafos arbitrarios caracterizando las configuraciones alcanzables mediante el grupo alternante, y con Kornhauser, Miller y Spirakis @kornhauser1984, quienes establecieron la cota clásica $O(n^3)$ sobre la longitud de las secuencias. Recientemente, Brunck et al. @brunck2023 extendieron la teoría de Wilson al régimen con múltiples vértices vacíos, reflejando la presencia de filas centrales desocupadas.
- *Fichas coloreadas (_Colored Pebble Motion_).* Dado que las piezas del mismo color son indistinguibles, el marco exacto corresponde a _colored pebble motion_ con dos clases de color. Goraly y Hassin @goraly2010 y Fujita et al. @fujita2012 caracterizaron la factibilidad y las clases de equivalencia en tiempo lineal; sin embargo, Yu y LaValle @yu2013 @yu2015 probaron que minimizar el número de movimientos es NP-hard en grafos generales incluso con solo dos grupos de fichas intercambiables.

Este modelo describe con exactitud a las piezas de salto o paso unitario (_leapers_, como caballos y reyes), cuyo grafo de movimiento es fijo. Para piezas deslizantes (torres, alfiles y damas), en cambio, un movimiento recorre múltiples casillas vacías colineales y puede ser bloqueado por piezas intermedias, haciendo que las transiciones dependan de la configuración completa.

=== Reconfiguración en grafos y grillas (_Reconfigurations in Graphs and Grids_)

El modelo teórico más cercano al movimiento de las torres es el introducido por Călinescu, Dumitrescu y Pach @calinescu2008:

- *Movimientos de largo alcance en grillas.* Un movimiento desplaza una ficha (_chip_) a lo largo de un camino arbitrario de vértices desocupados. El movimiento de una torre en un tablero de $m times n$ es el caso particular en que dicho camino sobre la grilla se restringe a trayectorias rectilíneas (horizontales o verticales). Su trabajo estudia cotas superiores e inferiores tanto para fichas etiquetadas como no etiquetadas.
- *Complejidad en grillas y puzles deslizantes.* Cooper et al. @cooper2021 probaron que minimizar movimientos en este modelo sobre grillas (motivado por pinzas ópticas) es NP-completo. Ello se enlaza con la complejidad clásica de puzles deslizantes —la PSPACE-completitud de Hearn y Demaine @hearn2009 y la NP-dificultad de secuencias óptimas en el $(n^2 - 1)$-puzle de Ratner y Warmuth @ratner1990 y Demaine y Rudoy @demaine2017— y con resultados recientes sobre ajedrez solitario por Brunner et al. @brunner2023.

=== Antecedentes en el tablero de ajedrez

El antecedente olímpico más cercano es el problema de S. I. Tokarev (_26th Tournament of Towns_, 2004/2005; _Kvant_, 2005, M1977) @tokarev2005 sobre el intercambio de $8$ damas blancas y $8$ damas negras, cuyo mínimo es $23$. Para caballos, la tradición se remonta al problema de Guarini (1512) en $3 times 3$, popularizado por Dudeney @dudeney1917 mediante el despliegue del grafo de movimientos; recientemente, Iordan @iordan2019 @iordan2021 estudió generalizaciones rectangulares vía grafos bipartitos y tripartitos, y Siegel @siegel2026 demostró que el problema óptimo general de intercambio de caballos es NP-hard.

== Objetivo del trabajo <sec:objetivo>

#todo[Redactar el objetivo concreto del trabajo.]

== Resultados principales <sec:resultados-principales>

El aporte central de este trabajo resuelve completamente el intercambio óptimo de dos filas de torres en tableros de $m times n$ para todo $m >= 5$ y $n >= 2$ (@thm:rooks en la @sec:problema-principal): el número mínimo de movimientos es exactamente
$ T_min (m, n) = 4n + 1, $
lo que da $33$ movimientos en el tablero estándar de $8 times 8$. También se analiza el comportamiento en los casos de pocas filas ($m in {2, 3, 4}$, @prop:rows).

En la @sec:otras-piezas se estudian las variaciones en el tablero de $8 times 8$ al reemplazar las torres por las restantes piezas del ajedrez. El siguiente cuadro resume los valores mínimos obtenidos:

#align(center)[
  #set text(size: 9.5pt)
  #table(
    columns: (auto, auto, 1fr),
    inset: (x: 10pt, y: 6pt),
    align: (left, center, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    [*Pieza*], [*Mínimo ($8 times 8$)*], [*Observación estructural*],
    table.hline(stroke: 0.4pt),
    [Torre], [$33$], [Caso particular del @thm:rooks ($4n + 1$ para $m >= 5, n = 8$).],
    [Dama], [$23$], [Resultado de Tokarev @tokarev2005: $6$ pares centrales en $3$ y $4$ esquinas en $5$.],
    [Alfil], [$30$], [Partición por color de casilla en dos subproblemas de $15$ movimientos.],
    [Caballo], [$64$], [Enfoque por teoría de grafos (extensión del método de Guarini).],
    [Rey], [$112$], [$7$ pasos por cada una de las $16$ piezas mediante cruces diagonales.],
    [Peón], [Imposible], [Sin capturas los peones no cambian de columna ni pueden sobrepasarse.],
    table.hline(stroke: 0.8pt),
  )
]
