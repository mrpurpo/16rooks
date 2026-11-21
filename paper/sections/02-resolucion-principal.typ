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

Resta probar $T_min (m, n) <= 4n + 1$. La hipótesis $m >= 5$ es la que permite esta construcción, pues utiliza cinco filas distintas ($1, 2, 3, 4$ y $m$; para $m in {3, 4}$ el mínimo sube a $4n + 2$, @prop:rows). La @fig:construccion ilustra las cuatro etapas del esquema:

+ *Preparación ($1$ movimiento, panel a):* la blanca de $c_1$ sube a la fila $3$, dejando libre $(1, 2)$.
+ *Barrido de $c_2, dots, c_n$ ($3(n - 1)$ movimientos, paneles b–c):* de izquierda a derecha, en cada columna $c_j$ la negra baja a la fila $2$ y se corre una columna a la izquierda, a $(j - 1, 2)$; con $c_j$ vacía, la blanca sube hasta la fila $m$ en un movimiento largo.
+ *Cierre de $c_1$ ($4$ movimientos, paneles d–e):* la negra de $c_1$ baja a la fila $4$ y cruza hasta $c_n$; la blanca de $c_1$ termina de subir a la fila $m$ y la negra en $(n, 4)$ baja a $(n, 1)$.
+ *Descenso final ($n - 1$ movimientos, panel f):* las $n - 1$ negras estacionadas en la fila $2$ bajan un paso a la fila $1$.

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
  Supongamos que una secuencia tiene $T = 4n + 1$ movimientos. Veremos que toda la holgura de @eq:cota4n se concentra en una única columna excepcional $c_*$, por la que pasan tres torres sin movimientos largos cuyas filas intermedias de estacionamiento cumplen $2 <= p_E < p_Q < p_S <= m - 1$; esto exige al menos tres filas intermedias y, por tanto, $m >= 5$.

  _Dónde está la holgura._ En @eq:cota4n, $T - 4n = 1$ implica que un único sumando vale $1$ y los demás se anulan. Si $"out"_j = ell_j$ valiera en toda columna, el @lem:sinholgura y el @lem:extremal darían una contradicción como en el @thm:rooks. Existe, pues, una única columna $c_*$ con $"out"_* = ell_* + 1$, mientras que $"out"_j = ell_j >= 1$ para toda $c_j != c_*$, y $V = 4n - L$. Esta igualdad dice que el @lem:vert es exacto en cada pieza: toda torre con movimiento largo hace un único movimiento vertical, y toda torre sin movimientos largos hace exactamente dos, ambos hacia su fila final (si uno retrocediera, el otro recorrería al menos $m$ filas), deteniéndose en una sola fila intermedia que llamamos su _fila de estacionamiento_.

  _La columna $c_*$ cumple $ell_* = 0$._ Si fuera $ell_* >= 1$ y $tau_*$ su primer movimiento largo, antes de $tau_*$ no podría salir una sola torre de $c_*$ (pues no entraría ninguna antes de $tau_*$ y fallaría el @lem:extremal). Como $"out"_* = ell_* + 1$ y el @lem:horiz fuerza una salida entre movimientos largos consecutivos, salen exactamente dos torres de $c_*$ antes de $tau_*$ y ninguna después del último movimiento largo. Aplicando lo mismo a la secuencia invertida (@lem:simetrias), en ella salen dos torres de $c_*$ antes de su primer movimiento largo y por conteo entra una; en la secuencia original esa entrada sería una salida posterior al último movimiento largo de $c_*$, contradicción. Así, $ell_* = 0$ y $"out"_* = 1$.

  _La torre que entra en $c_*$ ($p_E < p_Q$)._ Como $ell_* = 0$ y $"out"_* = 1$, de $c_*$ sale en toda la partida una sola torre original $S$ (_sale_), entra una sola torre $E$ (_entra_) y la otra torre original $Q$ (_queda_) nunca sale de $c_*$. Pasando a la conjugada si hace falta (@lem:simetrias), suponemos $Q$ blanca y $S$ negra. Sea $tau = tau_a$ el primer movimiento largo de toda la secuencia ($a != *$). Por el @lem:sinholgura, antes de $tau$ sale de $c_a$ una torre original y no puede entrar en ninguna $c_j != c_*$ (pues $tau <= tau_j$); luego esa torre es $E$, y su entrada en $c_*$ es el único movimiento horizontal anterior a $tau$. Como $E$ ya no sale de $c_*$, termina en la fila $1$ debajo de la blanca $Q$, luego $E$ es negra y permanece bajo $Q$ desde que entra; además, en ese turno $S$ sigue en $c_*$ sobre $Q$, pues su salida es horizontal y, por tanto, posterior a $tau$. Ni $E$ ni $Q$ hacen movimientos largos: antes de $tau$ no hay ninguno, y desde entonces ambas permanecen en $c_*$, que no tiene ninguno. Además, $E$ no pudo salir de $c_a$ por la fila $1$ porque allí seguía la blanca original de $c_a$. Por tanto, cuando $E$ entra en $c_*$, tanto $E$ como $Q$ están en sus filas intermedias de estacionamiento, con $2 <= p_E < p_Q <= m - 1$.

  _La torre que sale de $c_*$ ($p_Q < p_S$)._ En la secuencia invertida (@lem:simetrias), $c_*$ y la blanca $Q$ conservan su papel y la única torre que entra en $c_*$ es $S$. El paso anterior aplicado a la invertida muestra que, al deshacer la reflexión vertical, en la secuencia original $S$ sale de $c_*$ desde su fila de estacionamiento $p_S$ estando $Q$ en $p_Q$, con $p_Q < p_S <= m - 1$. Así, $2 <= p_E < p_Q < p_S <= m - 1$, lo que obliga a $m >= 5$.
]

#remark[
  La demostración prueba algo más fuerte: en toda secuencia de $4n + 1$ movimientos, tres torres se estacionan en la columna excepcional en tres filas intermedias distintas. En la construcción del @thm:rooks, la columna excepcional es $c_1$, donde la negra llegada desde $c_2$ ($E$) se estaciona en la fila $2$, la blanca original ($Q$) en la $3$ y la negra original ($S$) en la $4$; el uso de esas filas no es un accidente.
]

Para $m in {3, 4}$ basta usar una sola fila intermedia (la fila $2$): tras el mismo barrido de $c_2, dots, c_n$, las negras estacionadas en la fila $2$ liberan $c_1$ con un único movimiento extra, alcanzando $4n + 2$ movimientos (@fig:construccion-pocas):

+ *Barrido de $c_2, dots, c_n$ ($3(n - 1)$ movimientos):* igual que en el @thm:rooks, pero sin preparación; las negras quedan en $(1, 2), dots, (n - 1, 2)$ y $(n, 2)$ queda libre.
+ *Descenso parcial ($n - 2$ movimientos, panel a):* las negras de $c_2, dots, c_(n-1)$ bajan de la fila $2$ a la fila $1$.
+ *Liberación de $c_1$ ($2$ movimientos, panel b):* la negra estacionada en $(1, 2)$ cruza la fila $2$ hasta $c_n$ y baja a $(n, 1)$.
+ *Cierre de $c_1$ ($5$ movimientos, paneles c–e):* la negra de $(1, m)$ baja a la fila $2$ y se aparta a $c_2$; la blanca de $c_1$ sube a la fila $m$ en un movimiento largo, y la negra regresa a $c_1$ y baja a la fila $1$.

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