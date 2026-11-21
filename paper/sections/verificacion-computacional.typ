#import "../style.typ": *

// Tabla con el estilo del apéndice (líneas horizontales, sin rejilla).
#let tabla(columns, align: center, ..cells) = {
  set text(size: 8.5pt)
  table(
    columns: columns,
    align: align,
    inset: (x: 6pt, y: 3.5pt),
    stroke: none,
    ..cells,
  )
}

// Celda de la tabla de torres: en negrita si m <= 4 (régimen 4n + 2).
#let v(x, pocas: false) = if pocas { strong[#x] } else { [#x] }

= Verificación computacional <sec:verificacion>

Las demostraciones anteriores no dependen de ningún cálculo, pero pueden contrastarse en tableros pequeños: una búsqueda exhaustiva en el grafo de posiciones determina el mínimo exacto de un tablero fijo, lo que constituye una demostración asistida por computador para ese tablero. Estas comprobaciones confirman las fórmulas, incluido el cambio de régimen entre $m = 4$ y $m = 5$, y, como la búsqueda no usa ninguno de nuestros lemas, permiten detectar errores en los argumentos.

== Herramienta

Usamos la herramienta `swaprows` (repositorio `github.com/mrpurpo/16rooks`, carpeta `code/`, versión `8fe8a14`), cuyo `README` describe los algoritmos, su exactitud y los comandos para reproducir cada resultado. Empleamos tres funciones: `solve`, que calcula el mínimo exacto por búsqueda en anchura y, con `--count`, el número de secuencias óptimas; `check`, que verifica de forma independiente que una lista de movimientos es legal y termina en la posición final; y `bound`, la cota inferior por asignación de piezas a casillas destino con distancias en el tablero vacío. Una implementación de referencia independiente (`tests/reference.py`, BFS sin optimizaciones) reprodujo los valores de la @tab:torres con $n <= 3$ y los conteos de la @tab:estructura. Los cálculos se hicieron en un portátil con Intel Core i7-13620H y 16 GB de memoria.

== Mínimos exactos para torres

La @tab:torres recoge el mínimo calculado con `solve` en $25$ tableros. Todos coinciden con el @thm:rooks y la @prop:rows: $4n + 2$ para $m in {3, 4}$ (en negrita) y $4n + 1$ para $m >= 5$, lo que confirma de forma independiente que la cota $4n + 1$ es exacta y el salto entre $m = 4$ y $m = 5$, la parte más delicada de la demostración.

#figure(
  tabla(
    9,
    table.hline(stroke: 0.8pt),
    table.header([$n$ \\ $m$], [$3$], [$4$], [$5$], [$6$], [$7$], [$8$], [$9$], [$10$]),
    table.hline(stroke: 0.4pt),
    [$2$], v(10, pocas: true), v(10, pocas: true), v(9), v(9), v(9), v(9), v(9), v(9),
    [$3$], v(14, pocas: true), v(14, pocas: true), v(13), v(13), v(13), v(13), v(13), v(13),
    [$4$], v(18, pocas: true), v(18, pocas: true), v(17), v(17), v(17), v(17), [], [],
    [$5$], v(22, pocas: true), v(22, pocas: true), v(21), [], [], [], [], [],
    table.hline(stroke: 0.8pt),
  ),
  caption: [Mínimo exacto $T_min (m, n)$ para torres, calculado por búsqueda exhaustiva. En negrita, los tableros con $m in {3, 4}$. Las casillas vacías exceden la memoria disponible.],
) <tab:torres>

El espacio de posiciones crece muy rápido: el caso mayor ($m = n = 5$) recorrió unas $2.5 dot 10^8$ posiciones, mientras que el tablero de $8 times 8$ tiene $binom(64, 8) binom(56, 8) approx 6.3 dot 10^18$, fuera del alcance de una búsqueda exhaustiva. Los cálculos complementan la demostración, pero no la reemplazan.

== Estructura de las soluciones óptimas

La demostración de la @prop:rows muestra que toda secuencia de $4n + 1$ movimientos tiene una estructura rígida. Para comprobarlo, un programa autocontenido (`tests/structure.py`, que no comparte código con `solve`) enumera _todas_ las secuencias óptimas en seis tableros con $m >= 5$ y verifica en cada una que:

+ hay exactamente una columna excepcional $c_*$, que cumple $ell_* = 0$ y $"out"_* = 1$, y toda otra columna cumple $"out"_j = ell_j >= 1$;
+ $V = 4n - L$, es decir, cada torre alcanza exactamente la cota del @lem:vert;
+ exactamente tres torres pasan por $c_*$, ninguna hace movimientos largos, y sus filas de estacionamiento son distintas.

#figure(
  tabla(
    4,
    table.hline(stroke: 0.8pt),
    table.header([Tablero ($m times n$)], [$T_min$], [Secuencias óptimas], [Cumplen 1–3]),
    table.hline(stroke: 0.4pt),
    [$5 times 2$], [$9$], [$432$], [$432$],
    [$6 times 2$], [$9$], [$1 thin 728$], [$1 thin 728$],
    [$7 times 2$], [$9$], [$4 thin 320$], [$4 thin 320$],
    [$8 times 2$], [$9$], [$8 thin 640$], [$8 thin 640$],
    [$5 times 3$], [$13$], [$168 thin 144$], [$168 thin 144$],
    [$6 times 3$], [$13$], [$1 thin 034 thin 304$], [$1 thin 034 thin 304$],
    table.hline(stroke: 0.8pt),
  ),
  caption: [Enumeración completa de las secuencias óptimas para torres. Los conteos coinciden con los de `solve --count`, obtenidos con un programa distinto.],
) <tab:estructura>

Las $1 thin 217 thin 568$ secuencias examinadas cumplen las tres propiedades sin excepción (@tab:estructura), e incluso el orden $2 <= p_E < p_Q < p_S <= m - 1$ de las filas de estacionamiento que establece la demostración; un error en el análisis del caso de igualdad de la @prop:rows probablemente se habría manifestado aquí como alguna violación.

== Otras piezas

- *Reyes.* `solve` reproduce la fórmula $2n(m - 1)$ de la @prop:kings en los $12$ tableros con $n in {2, 3, 4}$ y $m in {3, 4, 5, 6}$. En $8 times 8$, la cota de `bound` es $112$, lo que certifica por computador la optimalidad de la construcción.
- *Caballos.* La cota por asignación en $8 times 8$ es $64$, como en la @prop:knights.
- *Alfiles.* Como la búsqueda se separa por color de casilla, el tablero de $8 times 8$ se resuelve exactamente: `solve` recorre unas $1.2 dot 10^8$ posiciones en unos $40$ segundos y obtiene $30$, confirmando la @prop:bishops.
- *Construcciones.* Las cinco secuencias del Apéndice (@sec:apendice) pasan `check`: son legales y terminan en la posición final; la de las damas respeta además la alternancia estricta de turnos.

Por contraste, la cota por asignación da solo $16$ para torres y damas en $8 times 8$, lejos de $33$ y $23$: ignora que las piezas se bloquean entre sí, que es justamente lo que capturan el @lem:horiz y el principio extremal.
