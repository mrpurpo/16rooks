#import "../style.typ": *
#import "@preview/board-n-pieces:0.9.0": board, fen

// Tablero de las figuras: `pos` es la parte de posición de una cadena FEN
// (fila superior primero; `r` = torre negra, `R` = torre blanca).
#let tablero(pos, filas: 6, columnas: 5, tam: 0.42cm, ..args) = {
  set text(size: 7.5pt)
  board(
    fen(pos),
    square-size: tam,
    white-square-fill: rgb("#f0d9b5"),
    black-square-fill: rgb("#b58863"),
    arrow-fill: rgb("#1d4ed8c0"),
    stroke: 0.5pt + black,
    display-numbers: true,
    file-numbering: j => if j == columnas { $c_n$ } else { $c_#j$ },
    rank-numbering: r => if r == filas { $m$ } else { $#r$ },
    ..args,
  )
}

// Un tablero con su rótulo debajo.
#let panel(rotulo, tab) = align(center, stack(
  dir: ttb,
  spacing: 0.5em,
  tab,
  block(width: 4.2cm, text(size: 8.5pt, hyphenate: false, rotulo)),
))

= Resolución del problema principal <sec:problema-principal>

#theorem(name: [Intercambio óptimo de torres en $m times n$])[
  En un tablero de $m >= 5$ filas y $n >= 2$ columnas, el número mínimo de movimientos para intercambiar las dos filas de torres es
  $ T_min (m, n) = 4n + 1. $
] <thm:rooks>

== Notación

Un _movimiento_ desplaza una sola torre cualquier número de casillas a lo largo de su fila o columna, sin saltar sobre otras torres. Fijamos una secuencia que realiza el intercambio, con $T$ movimientos numerados $1, dots, T$; el movimiento $t$ ocurre en el _turno_ $t$. Un movimiento es _horizontal_ si la torre se desplaza dentro de su fila y _vertical_ si lo hace dentro de su columna; si $H$ y $V$ cuentan unos y otros, $T = H + V$. Un movimiento vertical es _largo_ si va de la fila $1$ a la fila $m$ o viceversa; como la torre no salta, _en el turno de un movimiento largo la columna no contiene ninguna otra torre_.

Sean $c_1, dots, c_n$ las columnas de izquierda a derecha y $(j, r)$ la casilla de $c_j$ en la fila $r$. Las dos _torres originales_ de $c_j$ son la blanca en $(j, 1)$ y la negra en $(j, m)$. Una _salida_ de $c_j$ es un movimiento horizontal que parte de $c_j$, y una _entrada_ en $c_j$ uno que termina en ella; cada movimiento horizontal es la salida de una columna y la entrada en otra. Definimos
$
  "out"_j & = \#{"salidas de" c_j}, \
    ell_j & = \#{"torres que realizan al menos un movimiento largo en" c_j},
$
de modo que $H = sum_(j=1)^n "out"_j$ (todas las sumas sobre columnas recorren $c_1, dots, c_n$). Si $L$ es el número de torres con al menos un movimiento largo (en cualquier columna), entonces $L <= sum_(j=1)^n ell_j$.

El número de torres de una columna solo cambia con movimientos horizontales (cada entrada suma una y cada salida resta una), y al inicio y al final cada columna contiene exactamente dos.

== Cota inferior

Los lemas de esta sección, y con ellos la cota $T >= 4n + 1$, valen para todo $m >= 3$ y $n >= 2$; la hipótesis $m >= 5$ solo interviene en la construcción.

#lemma(name: [Movimientos verticales])[
  Se cumple $V >= 4n - L$.
] <lem:vert>

#proof[
  Los movimientos verticales de cada torre deben desplazarla en total $m - 1$ filas. Una torre con algún movimiento largo hace al menos un movimiento vertical; cualquier otro movimiento vertical recorre a lo sumo $m - 2$ filas, así que una torre sin movimientos largos hace al menos dos. Por lo tanto,
  $ V >= L dot 1 + underbrace((2n - L), #align(center)[torres sin \ mov. largo]) dot 2 = 4n - L. $
]

#lemma(name: [Movimientos horizontales])[
  Para toda columna $c_j$, al menos una de las dos torres originales de $c_j$ sale de $c_j$ (en particular, $"out"_j >= 1$). Además, supongamos $ell_j >= 1$ y numeremos $X_1, dots, X_(ell_j)$ las torres que hacen un movimiento largo en $c_j$, según el orden de los turnos $t_1 < t_2 < dots < t_(ell_j)$ en que hacen su primer movimiento largo en $c_j$. Entonces sale al menos una torre de $c_j$ antes del turno $t_1$, y al menos una entre los turnos $t_k$ y $t_(k+1)$, para cada $k = 1, dots, ell_j - 1$. En particular, $"out"_j >= ell_j$.
] <lem:horiz>

#proof[
  _Salida de una torre original._ Si ninguna torre original saliera de $c_j$, ambas permanecerían en ella; como dos torres de una columna no se cruzan, la negra seguiría por encima de la blanca, contradiciendo que al final la blanca esté en la fila $m$ y la negra en la fila $1$.

  _Salidas asociadas a los movimientos largos._ Supongamos $ell_j >= 1$. Justo antes del turno $t_k$, la columna $c_j$ contiene únicamente a $X_k$. Antes de $t_1$, entonces, alguna torre original ya abandonó $c_j$, lo que exige una salida. Entre $t_k$ y $t_(k+1)$, la torre $X_k$, que está en $c_j$ justo después de $t_k$, debe haber salido, pues justo antes de $t_(k+1)$ la única torre de $c_j$ es $X_(k+1) != X_k$. Estas $ell_j$ salidas ocurren en intervalos de turnos disjuntos, luego son distintas y $"out"_j >= ell_j$.
]

Si una columna no tiene holgura en el @lem:horiz, su comportamiento antes del primer movimiento largo queda determinado.

#lemma(name: [Columnas sin holgura])[
  Si una columna $c_j$ cumple $"out"_j = ell_j$, entonces $ell_j >= 1$ y, llamando $tau_j$ al turno del primer movimiento largo en $c_j$, antes del turno $tau_j$ sale de $c_j$ exactamente una torre y no entra ninguna. Más aún, la torre que hace el movimiento largo del turno $tau_j$ es una de las torres originales de $c_j$ y permanece en $c_j$ desde el inicio hasta ese turno; la torre que sale antes de $tau_j$ es la otra torre original.
] <lem:sinholgura>

#proof[
  Por el @lem:horiz, $ell_j = "out"_j >= 1$, así que $tau_j = t_1$ está definido, y las $ell_j$ salidas que exhibe el lema son todas; en particular, antes de $tau_j$ sale exactamente una torre. Como $c_j$ tiene $2$ torres al inicio y $1$ justo antes de $tau_j$, si entran $e$ torres antes de $tau_j$ se tiene $2 - 1 + e = 1$, es decir, $e = 0$. Luego la torre del movimiento largo en $tau_j$ es original y nunca salió de $c_j$ (habría tenido que volver a entrar), y la única salida corresponde a la otra torre original.
]

#lemma(name: [Principio extremal])[
  No puede ocurrir que cada columna $c_j$ tenga al menos un movimiento largo y que ninguna torre entre en $c_j$ antes del turno $tau_j$ de su primer movimiento largo.
] <lem:extremal>

#proof[
  Supongamos que sí, y elijamos $c_a$ con $tau_a <= tau_j$ para todo $j$. Por el @lem:horiz, alguna torre sale de $c_a$ antes de $tau_a$; ese movimiento es una entrada en otra columna $c_b$ en un turno anterior a $tau_a <= tau_b$, contradiciendo la hipótesis.
]

#proof(title: [Demostración de la cota inferior del @thm:rooks])[
  Como $T = H + V$ y $H = sum_(j=1)^n "out"_j$,
  $ T - 4n = (V - (4n - L)) + sum_(j=1)^n ("out"_j - ell_j) + (sum_(j=1)^n ell_j - L), $ <eq:cota4n>
  donde los tres sumandos son enteros no negativos por el @lem:vert, el @lem:horiz (columna por columna) y $L <= sum_(j=1)^n ell_j$, respectivamente. Así $T >= 4n$.

  Si $T = 4n$, todos los sumandos se anulan; en particular, $"out"_j = ell_j$ para toda columna, sin que una salida de más en una columna pueda compensarse con una de menos en otra. (Esto no supone nada sobre cuántos movimientos largos hace cada torre: una torre con varios movimientos largos aumenta $V - (4n - L)$, de modo que tal secuencia simplemente tiene más de $4n$ movimientos.) Por el @lem:sinholgura, cada columna tiene entonces algún movimiento largo y ninguna torre entra en ella antes del primero, lo que el @lem:extremal declara imposible. Por lo tanto $T >= 4n + 1$.
]

== Construcción explícita en $4n + 1$ movimientos

Resta probar $T_min (m, n) <= 4n + 1$, lo que no es una formalidad: la cota inferior vale también para $m in {3, 4}$, donde el mínimo es $4n + 2$ (@prop:rows). La construcción es la que usa $m >= 5$, pues necesita las filas $1, 2, 3, 4$ y $m$, todas distintas. Para $m >= 5$ y $n >= 2$, el siguiente esquema intercambia las torres en $4n + 1$ movimientos (@fig:construccion):

+ *Preparación ($1$ movimiento).* La torre blanca de $(1, 1)$ sube a $(1, 3)$.
+ *Barrido de las columnas $c_2, dots, c_n$ ($3(n - 1)$ movimientos).* Para $j = 2, dots, n$, en este orden, la negra baja de $(j, m)$ a $(j, 2)$ y se desplaza a $(j - 1, 2)$; con $c_j$ libre, la blanca sube con un movimiento largo de $(j, 1)$ a $(j, m)$.
+ *Cierre de la columna $c_1$ ($4$ movimientos).* La torre negra de $(1, m)$ baja a $(1, 4)$ y cruza por la fila $4$, vacía, hasta $(n, 4)$; luego la blanca de $(1, 3)$ sube a $(1, m)$ y la negra de $(n, 4)$ baja a $(n, 1)$.
+ *Descenso final ($n - 1$ movimientos).* Las $n - 1$ negras estacionadas en $(1, 2), dots, (n - 1, 2)$ bajan a la fila $1$.

#figure(
  kind: image,
  grid(
    columns: 3,
    column-gutter: 0.6cm,
    row-gutter: 0.5cm,
    panel(
      [(a) Preparación.],
      tablero("rrrrr/5/5/5/5/RRRRR", arrows: ("a1a3",)),
    ),
    panel(
      [(b) Barrido de $c_2$: la negra baja y se hace a un lado.],
      tablero("rrrrr/5/5/R4/5/1RRRR", arrows: ("b6b2", "b2a2")),
    ),
    panel(
      [(c) Barrido de $c_2$: la blanca sube con un movimiento largo.],
      tablero("r1rrr/5/5/R4/r4/1RRRR", arrows: ("b1b6",)),
    ),

    panel(
      [(d) Tras barrer $c_2, dots, c_n$: la negra de $c_1$ cruza por la fila $4$.],
      tablero("rRRRR/5/5/R4/rrrr1/5", arrows: ("a6a4", "a4e4")),
    ),
    panel(
      [(e) Cierre de $c_1$.],
      tablero("1RRRR/5/4r/R4/rrrr1/5", arrows: ("a3a6", "e4e1")),
    ),
    panel(
      [(f) Descenso final.],
      tablero("RRRRR/5/5/5/rrrr1/4r", arrows: ("d2d1", "c2c1", "b2b1", "a2a1")),
    ),
  ),
  caption: [
    La construcción del @thm:rooks con $m = 6$ y $n = 5$ ($21$ movimientos). Las flechas indican los movimientos siguientes, en el orden del texto. Los pasos (b) y (c) se repiten en $c_3, dots, c_n$; la fila $5$ no se usa.
  ],
) <fig:construccion>

El total es $1 + 3(n - 1) + 4 + (n - 1) = 4n + 1$, lo que completa la demostración del @thm:rooks. Aquí $H = n$, $V = 3n + 1$ y $L = n - 1$ (las blancas de $c_2, dots, c_n$), así que $V = 4n - L$; toda la holgura de @eq:cota4n está en $c_1$, con una salida y ningún movimiento largo, mientras que $"out"_j = ell_j = 1$ en las demás columnas. Los $33$ movimientos para $m = n = 8$ se listan en la @sec:ap-torres.

#remark[
  La prueba de minimalidad combina tres ideas: descomponer $T = H + V$ contando las salidas por columna; compensar cada movimiento vertical largo (que ahorra un movimiento vertical) con la salida necesaria para vaciar la columna; y un principio extremal sobre el turno del primer movimiento largo.
]

== Régimen de pocas filas ($m <= 4$)

Con $m <= 4$ faltan filas intermedias para la construcción anterior, y el mínimo aumenta en uno.

#proposition(name: [Casos $m in {2, 3, 4}$])[
  Sea $n >= 2$. Para $m = 2$ el intercambio es imposible, es decir, $T_min (2, n) = infinity$. Para $m in {3, 4}$,
  $ T_min (3, n) = T_min (4, n) = 4n + 2. $
] <prop:rows>

Para $m = 2$ no hay casillas vacías y ninguna torre puede moverse. Sea en adelante $m in {3, 4}$; la cota $T >= 4n + 1$ sigue valiendo. Resta probar que $4n + 1$ movimientos no bastan, para lo cual usamos dos simetrías, y exhibir una secuencia de $4n + 2$.

#lemma(name: [Simetrías])[
  Reflejar el tablero significa enviar la fila $r$ a la fila $m + 1 - r$. Dada una secuencia válida de $T$ movimientos, las siguientes también son secuencias válidas de $T$ movimientos:
  - la secuencia _invertida_, que recorre las posiciones de la original en orden inverso y refleja el tablero;
  - la secuencia _conjugada_, que intercambia los colores de todas las torres y refleja el tablero.
  Ambas conservan las columnas, el tipo de cada movimiento (horizontal, vertical, largo) y los valores $"out"_j$ y $ell_j$, e intercambian "arriba" y "abajo" en cada columna. En la invertida, además, el orden de los turnos se invierte y las salidas de $c_j$ son las entradas en $c_j$ de la original.
] <lem:simetrias>

#proof[
  Todo movimiento es reversible (la torre vuelve por la misma línea vacía), así que recorrer las posiciones al revés lleva de la posición final a la inicial, y al reflejar el tablero, de la inicial a la final. Intercambiar colores y reflejar fija tanto la posición inicial como la final. Ninguna operación cambia la columna ni el tipo de un movimiento; en la conjugada las salidas siguen siendo salidas, y en la invertida las salidas de $c_j$ son las entradas originales en $c_j$, cuyo número es $"out"_j$ porque $c_j$ tiene dos torres al inicio y al final.
]

#proof(title: [Demostración de la cota inferior $T >= 4n + 2$ para $m in {3, 4}$])[
  Supongamos que una secuencia tiene $T = 4n + 1$ movimientos; probaremos que entonces $m >= 5$.

  _Dónde está la holgura._ En @eq:cota4n, $T - 4n = 1$, así que exactamente un sumando vale $1$. Si no fuera un término $"out"_j - ell_j$, el @lem:sinholgura y el @lem:extremal darían una contradicción como en el @thm:rooks. Hay, pues, una única columna $c_*$ con $"out"_* = ell_* + 1$, las demás cumplen $"out"_j = ell_j$, y $V = 4n - L$. Esto último significa que el @lem:vert es exacto para cada torre: una torre con movimientos largos hace un único movimiento vertical, que es largo, y una sin movimientos largos hace exactamente dos, ambos hacia su fila final (si uno retrocediera, el otro recorrería al menos $m$ filas). Así, una torre sin movimientos largos solo pasa por su fila inicial, una fila intermedia, su _fila de estacionamiento_, y su fila final.

  _La columna $c_*$ no tiene movimientos largos._ Supongamos $ell_* >= 1$ y sea $tau_*$ su primer movimiento largo. Como cada torre hace a lo sumo un movimiento largo, los turnos $t_1 < dots < t_(ell_*)$ del @lem:horiz son todos los movimientos largos de $c_*$. Si antes de $tau_*$ saliera de $c_*$ una sola torre, el conteo del @lem:sinholgura mostraría que ninguna entra antes de $tau_*$, y toda columna cumpliría las hipótesis del @lem:extremal, lo cual es imposible. Como el @lem:horiz da además una salida entre movimientos largos consecutivos y $"out"_* = ell_* + 1$, salen exactamente dos torres antes de $tau_*$ y ninguna después del último movimiento largo. La secuencia invertida (@lem:simetrias) tiene también $4n + 1$ movimientos, columna excepcional $c_*$ y $ell_* >= 1$; en ella salen dos torres de $c_*$ antes de su primer movimiento largo y, como la columna pasa de $2$ torres a $1$, entra una. En la original, esa entrada es una salida posterior al último movimiento largo de $c_*$, una contradicción. Luego $ell_* = 0$.

  _La torre que entra en $c_*$._ Como $ell_* = 0$, se tiene $"out"_* = 1$: de $c_*$ sale una sola torre y, como empieza y termina con dos, entra una sola. Por el @lem:horiz, la que sale es original; la llamamos $S$ (_sale_) y $Q$ (_queda_) a la otra. Pasando a la conjugada si hace falta (@lem:simetrias), suponemos $Q$ blanca y $S$ negra.

  Sea $tau$, como objeto extremal, el turno del primer movimiento largo de la secuencia. Existe porque $n >= 2$ y toda columna $c_j != c_*$ cumple $ell_j = "out"_j >= 1$, y ocurre en una columna $c_a != c_*$, así que $tau = tau_a$. Por el @lem:sinholgura, antes de $tau$ sale de $c_a$ exactamente una torre original, que llamamos $E$ (_entra_), y la otra permanece en $c_a$ hasta $tau$. La salida de $E$ no es una entrada en una columna $c_j != c_*$, pues por el @lem:sinholgura nadie entra en $c_j$ antes de $tau_j >= tau$; luego $E$ es la única torre que entra en $c_*$. Como antes de $tau$ solo $c_*$ puede recibir torres y recibe una sola, esa entrada es el único movimiento horizontal anterior a $tau$.

  $E$ ya no sale de $c_*$, pues la única salida es la de $S != E$. Al final $c_*$ contiene a $Q$ y $E$; como $Q$ es blanca, $E$ es negra y termina en la fila $1$, por debajo de $Q$, y como no se cruzan, está por debajo de $Q$ desde que entra. Cuando $E$ entra, $S$ sigue en $c_*$ (su salida es horizontal y, por tanto, posterior a $tau$), por encima de $Q$. Así, en ese turno, fila de $E$ $<$ fila de $Q$ $<$ fila de $S <= m$.

  $E$ no hace movimientos largos: no hubo ninguno antes de su llegada a $c_*$ (anterior a $tau$) y $c_*$ no tiene ninguno. Solo pasa, entonces, por las filas $m$, $p_E$ (su fila de estacionamiento) y $1$. No entra a $c_*$ por la fila $m$, pues queda bajo $Q$, ni por la fila $1$, pues en $c_a$ estaba por encima de la otra torre original, blanca, que permanece allí hasta $tau$. Como un movimiento horizontal no cambia de fila, $E$ entra por $p_E$. En ese turno $Q$ está estrictamente entre $p_E$ y $m$ y, como tampoco hace movimientos largos, está en su fila de estacionamiento $p_Q$. Luego $p_E < p_Q$, lo que ya es imposible para $m = 3$, cuya única fila intermedia es la $2$.

  _La torre que sale de $c_*$._ En la secuencia invertida (@lem:simetrias), $c_*$ sigue siendo excepcional y sin movimientos largos, $Q$ sigue siendo blanca y sin salir de $c_*$, y la única torre que entra en $c_*$ es $S$. El paso anterior dice que $S$ entra por su fila de estacionamiento, bajo $Q$, que está en la suya. Deshaciendo la inversión, que intercambia "arriba" y "abajo", en la original $S$ sale de $c_*$ desde su fila de estacionamiento $p_S$ estando $Q$ en $p_Q$, con $p_Q < p_S$.

  En suma, $p_E < p_Q < p_S$ son tres filas distintas entre $2$ y $m - 1$, lo que exige $m >= 5$. Luego, para $m in {3, 4}$, $T >= 4n + 2$.
]

#remark[
  La demostración prueba algo más fuerte: en toda secuencia de $4n + 1$ movimientos, tres torres se estacionan en la columna excepcional en tres filas intermedias distintas. En la construcción del @thm:rooks, la columna excepcional es $c_1$, donde la negra llegada desde $c_2$ ($E$) se estaciona en la fila $2$, la blanca original ($Q$) en la $3$ y la negra original ($S$) en la $4$; el uso de esas filas no es un accidente.
]

Para la cota superior se repite el barrido, pero sin filas intermedias de sobra: las negras estacionadas se acumulan en la fila $2$, y sacar al final la que bloquea $c_1$ cuesta un turno más. El siguiente esquema funciona para todo $m >= 3$ y usa solo las filas $1$, $2$ y $m$ (@fig:construccion-pocas):

+ *Barrido de las columnas $c_2, dots, c_n$ ($3(n - 1)$ movimientos).* Como en el @thm:rooks, pero sin preparación. Al terminar, las negras ocupan $(1, 2), dots, (n - 1, 2)$ y $(n, 2)$ queda libre.
+ *Descenso parcial ($n - 2$ movimientos).* Las negras de $(j, 2)$, para $j = 2, dots, n - 1$, bajan a $(j, 1)$.
+ *Liberación de la columna $c_1$ ($2$ movimientos).* La negra de $(1, 2)$ recorre la fila $2$ hasta $(n, 2)$ y baja a $(n, 1)$.
+ *Cierre de la columna $c_1$ ($5$ movimientos).* La negra de $(1, m)$ baja a $(1, 2)$ y se aparta a $(2, 2)$; la blanca de $(1, 1)$ sube con un movimiento largo a $(1, m)$; la negra vuelve a $(1, 2)$ y baja a $(1, 1)$.

#figure(
  kind: image,
  grid(
    columns: 3,
    column-gutter: 0.6cm,
    row-gutter: 0.5cm,
    panel(
      [(a) Tras el barrido: descenso parcial.],
      tablero("rRRRR/rrrr1/R4", filas: 3, tam: 0.5cm, arrows: ("b2b1", "c2c1", "d2d1")),
    ),
    panel(
      [(b) Liberación de $c_1$.],
      tablero("rRRRR/r4/Rrrr1", filas: 3, tam: 0.5cm, arrows: ("a2e2", "e2e1")),
    ),
    panel(
      [(c) La negra de $c_1$ baja y se hace a un lado.],
      tablero("rRRRR/5/Rrrrr", filas: 3, tam: 0.5cm, arrows: ("a3a2", "a2b2")),
    ),

    panel(
      [(d) La blanca de $c_1$ sube con un movimiento largo.],
      tablero("1RRRR/1r3/Rrrrr", filas: 3, tam: 0.5cm, arrows: ("a1a3",)),
    ),
    panel(
      [(e) La negra vuelve y baja.],
      tablero("RRRRR/1r3/1rrrr", filas: 3, tam: 0.5cm, arrows: ("b2a2", "a2a1")),
    ),
    panel(
      [(f) Posición final.],
      tablero("RRRRR/5/rrrrr", filas: 3, tam: 0.5cm),
    ),
  ),
  caption: [
    La construcción para pocas filas con $m = 3$ y $n = 5$ ($22$ movimientos), desde el final del barrido (como en la @fig:construccion, sin el paso (a)). Para $m = 4$ los movimientos son los mismos y la fila $3$ no se usa.
  ],
) <fig:construccion-pocas>

Si $n = 2$, el descenso parcial es vacío y $(2, 2)$ está libre en el cierre porque la negra liberada ya bajó a $(2, 1)$. El total es
$ 3(n - 1) + (n - 2) + 2 + 5 = 4n + 2, $
lo que completa la demostración de la @prop:rows. Frente a la construcción del @thm:rooks, las torres originales de $c_1$ cuestan igual ($5$ movimientos); el movimiento adicional lo paga la negra estacionada en $(1, 2)$, que en lugar de bajar directamente sale por la fila $2$ y baja en $c_n$.