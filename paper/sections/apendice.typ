#import "../style.typ": *

#let move-table(moves, cols: 4) = {
  let n = moves.len()
  let rows = calc.ceil(n / cols)
  let cells = ()
  for r in range(rows) {
    for c in range(cols) {
      let idx = c * rows + r
      if idx < n {
        let (color, mv) = moves.at(idx)
        cells.push([#(idx + 1)])
        cells.push(raw(color + " " + mv))
      } else {
        cells.push([])
        cells.push([])
      }
    }
  }
  let headers = range(cols).map(_ => ([*N.º*], [*Mov.*])).flatten()
  align(center)[
    #set text(size: 8.5pt)
    #table(
      columns: range(cols).map(_ => (auto, 1fr)).flatten(),
      inset: (x: 5pt, y: 3.5pt),
      align: range(cols).map(_ => (right, left)).flatten(),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header(..headers),
      table.hline(stroke: 0.4pt),
      ..cells,
      table.hline(stroke: 0.8pt),
    )
  ]
}

#pagebreak()
#counter(heading).update(0)
#set heading(numbering: "A.1.")

= Apéndice: Construcciones explícitas en el tablero $8 times 8$ <sec:apendice>

Se listan las secuencias óptimas completas en $8 times 8$ para todas las piezas resolubles. Las blancas (*B*) parten en `a1`–`h1` y las negras (*N*) en `a8`–`h8`; cada entrada indica el color y las casillas `origen-destino`.

== Torres ($33$ movimientos) <sec:ap-torres>

Construcción del @thm:rooks para $m = n = 8$ ($H = 8$ movimientos horizontales, $V = 25$ verticales, $L = 7$ movimientos largos):

#move-table(
  (
    ("B", "a1-a3"), ("N", "b8-b2"), ("N", "b2-a2"), ("B", "b1-b8"),
    ("N", "c8-c2"), ("N", "c2-b2"), ("B", "c1-c8"), ("N", "d8-d2"),
    ("N", "d2-c2"), ("B", "d1-d8"), ("N", "e8-e2"), ("N", "e2-d2"),
    ("B", "e1-e8"), ("N", "f8-f2"), ("N", "f2-e2"), ("B", "f1-f8"),
    ("N", "g8-g2"), ("N", "g2-f2"), ("B", "g1-g8"), ("N", "h8-h2"),
    ("N", "h2-g2"), ("B", "h1-h8"), ("N", "a8-a4"), ("N", "a4-h4"),
    ("B", "a3-a8"), ("N", "h4-h1"), ("N", "g2-g1"), ("N", "f2-f1"),
    ("N", "e2-e1"), ("N", "d2-d1"), ("N", "c2-c1"), ("N", "b2-b1"),
    ("N", "a2-a1"),
  ),
  cols: 4,
)

== Damas ($23$ movimientos) <sec:ap-damas>

Construcción de Tokarev @tokarev2005 (@prop:queens, @fig:damas-tokarev), adaptada a nuestra convención y con alternancia estricta de turnos:

#move-table(
  (
    ("B", "c1-a3"), ("N", "d8-a5"), ("B", "f1-h3"), ("N", "e8-h5"),
    ("B", "d1-d8"), ("N", "c8-c1"), ("B", "e1-e8"), ("N", "f8-f1"),
    ("B", "a3-f8"), ("N", "h5-d1"), ("B", "h3-c8"), ("N", "a5-e1"),
    ("B", "g1-h2"), ("N", "h8-h4"), ("B", "a1-h8"), ("N", "a8-a1"),
    ("B", "b1-a2"), ("N", "b8-b1"), ("B", "h2-b8"), ("N", "g8-g1"),
    ("B", "h1-a8"), ("N", "h4-h1"), ("B", "a2-g8"),
  ),
  cols: 4,
)

== Alfiles ($30$ movimientos) <sec:ap-alfiles>

Construcción de la @prop:bishops: los movimientos $1$–$15$ intercambian los alfiles de casillas oscuras (`a1, c1, e1, g1` con `b8, d8, f8, h8`), y los $16$–$30$ aplican la reflexión horizontal (`a` $arrow.l.r$ `h`) a las claras (`b1, d1, f1, h1` con `a8, c8, e8, g8`):

#move-table(
  (
    // Casillas oscuras (1-15)
    ("N", "b8-h2"), ("B", "a1-e5"), ("B", "e5-b8"), ("N", "h8-a1"),
    ("B", "g1-d4"), ("B", "d4-h8"), ("N", "h2-g1"), ("B", "c1-a3"),
    ("N", "f8-h6"), ("B", "a3-f8"), ("N", "h6-c1"), ("B", "e1-a5"),
    ("N", "d8-h4"), ("B", "a5-d8"), ("N", "h4-e1"),
    // Casillas claras (16-30, reflexión horizontal)
    ("N", "g8-a2"), ("B", "h1-d5"), ("B", "d5-g8"), ("N", "a8-h1"),
    ("B", "b1-e4"), ("B", "e4-a8"), ("N", "a2-b1"), ("B", "f1-h3"),
    ("N", "c8-a6"), ("B", "h3-c8"), ("N", "a6-f1"), ("B", "d1-h5"),
    ("N", "e8-a4"), ("B", "h5-e8"), ("N", "a4-d1"),
  ),
  cols: 4,
)

#pagebreak()

== Caballos ($64$ movimientos) <sec:ap-caballos>

Construcción de la @prop:knights, con $4$ saltos por caballo y alternancia estricta de bandos:

#move-table(
  (
    ("B", "f1-e3"), ("N", "c8-d6"), ("B", "c1-d3"), ("N", "f8-e6"),
    ("B", "a1-b3"), ("N", "h8-g6"), ("B", "g1-e2"), ("N", "b8-d7"),
    ("B", "e3-g4"), ("N", "d6-b5"), ("B", "h1-f2"), ("N", "a8-c7"),
    ("B", "b1-a3"), ("N", "g8-h6"), ("B", "b3-d4"), ("N", "g6-e5"),
    ("B", "d1-b2"), ("N", "e8-g7"), ("B", "e2-f4"), ("N", "d7-c5"),
    ("B", "d3-b4"), ("N", "e6-g5"), ("B", "f2-e4"), ("N", "c7-d5"),
    ("B", "d4-c6"), ("N", "e5-f3"), ("B", "f4-e6"), ("N", "c5-d3"),
    ("B", "a3-c4"), ("N", "h6-f5"), ("B", "b2-a4"), ("N", "g7-h5"),
    ("B", "e1-g2"), ("N", "d8-b7"), ("B", "c6-d8"), ("N", "f3-e1"),
    ("B", "c4-b6"), ("N", "f5-g3"), ("B", "b6-a8"), ("N", "g3-h1"),
    ("B", "b4-c6"), ("N", "g5-f3"), ("B", "c6-b8"), ("N", "f3-g1"),
    ("B", "g4-f6"), ("N", "b5-c3"), ("B", "a4-b6"), ("N", "h5-g3"),
    ("B", "e4-d6"), ("N", "d5-e3"), ("B", "f6-g8"), ("N", "c3-b1"),
    ("B", "b6-c8"), ("N", "g3-f1"), ("B", "g2-h4"), ("N", "b7-a5"),
    ("B", "h4-g6"), ("N", "a5-b3"), ("B", "e6-f8"), ("N", "d3-c1"),
    ("B", "d6-e8"), ("N", "e3-d1"), ("B", "g6-h8"), ("N", "b3-a1"),
  ),
  cols: 4,
)

== Reyes ($112$ movimientos) <sec:ap-reyes>

Construcción de la @prop:kings columna por columna ($14$ movimientos por columna, $7$ por rey):

#move-table(
  (
    ("B", "a1-b2"), ("N", "a8-a7"), ("N", "a7-a6"), ("N", "a6-a5"),
    ("N", "a5-a4"), ("N", "a4-a3"), ("N", "a3-a2"), ("N", "a2-a1"),
    ("B", "b2-a3"), ("B", "a3-a4"), ("B", "a4-a5"), ("B", "a5-a6"),
    ("B", "a6-a7"), ("B", "a7-a8"),
    ("B", "b1-c2"), ("N", "b8-b7"), ("N", "b7-b6"), ("N", "b6-b5"),
    ("N", "b5-b4"), ("N", "b4-b3"), ("N", "b3-b2"), ("N", "b2-b1"),
    ("B", "c2-b3"), ("B", "b3-b4"), ("B", "b4-b5"), ("B", "b5-b6"),
    ("B", "b6-b7"), ("B", "b7-b8"),
    ("B", "c1-d2"), ("N", "c8-c7"), ("N", "c7-c6"), ("N", "c6-c5"),
    ("N", "c5-c4"), ("N", "c4-c3"), ("N", "c3-c2"), ("N", "c2-c1"),
    ("B", "d2-c3"), ("B", "c3-c4"), ("B", "c4-c5"), ("B", "c5-c6"),
    ("B", "c6-c7"), ("B", "c7-c8"),
    ("B", "d1-e2"), ("N", "d8-d7"), ("N", "d7-d6"), ("N", "d6-d5"),
    ("N", "d5-d4"), ("N", "d4-d3"), ("N", "d3-d2"), ("N", "d2-d1"),
    ("B", "e2-d3"), ("B", "d3-d4"), ("B", "d4-d5"), ("B", "d5-d6"),
    ("B", "d6-d7"), ("B", "d7-d8"),
    ("B", "e1-f2"), ("N", "e8-e7"), ("N", "e7-e6"), ("N", "e6-e5"),
    ("N", "e5-e4"), ("N", "e4-e3"), ("N", "e3-e2"), ("N", "e2-e1"),
    ("B", "f2-e3"), ("B", "e3-e4"), ("B", "e4-e5"), ("B", "e5-e6"),
    ("B", "e6-e7"), ("B", "e7-e8"),
    ("B", "f1-g2"), ("N", "f8-f7"), ("N", "f7-f6"), ("N", "f6-f5"),
    ("N", "f5-f4"), ("N", "f4-f3"), ("N", "f3-f2"), ("N", "f2-f1"),
    ("B", "g2-f3"), ("B", "f3-f4"), ("B", "f4-f5"), ("B", "f5-f6"),
    ("B", "f6-f7"), ("B", "f7-f8"),
    ("B", "g1-h2"), ("N", "g8-g7"), ("N", "g7-g6"), ("N", "g6-g5"),
    ("N", "g5-g4"), ("N", "g4-g3"), ("N", "g3-g2"), ("N", "g2-g1"),
    ("B", "h2-g3"), ("B", "g3-g4"), ("B", "g4-g5"), ("B", "g5-g6"),
    ("B", "g6-g7"), ("B", "g7-g8"),
    ("B", "h1-g2"), ("N", "h8-h7"), ("N", "h7-h6"), ("N", "h6-h5"),
    ("N", "h5-h4"), ("N", "h4-h3"), ("N", "h3-h2"), ("N", "h2-h1"),
    ("B", "g2-h3"), ("B", "h3-h4"), ("B", "h4-h5"), ("B", "h5-h6"),
    ("B", "h6-h7"), ("B", "h7-h8"),
  ),
  cols: 4,
)
