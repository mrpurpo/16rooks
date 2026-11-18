#import "../style.typ": *

= Resolución del problema principal <sec:problema-principal>

En esta sección determinamos el número mínimo $T_min (m, n)$ de movimientos necesarios para intercambiar $n$ torres blancas ubicadas inicialmente en la fila $1$ con $n$ torres negras ubicadas en la fila $m$ de un tablero de $m$ filas y $n$ columnas.

#theorem(name: [Intercambio óptimo de torres en $m times n$])[
  En un tablero de $m >= 5$ filas y $n >= 2$ columnas, el número mínimo de movimientos para intercambiar las dos filas de torres es
  $ T_min (m, n) = 4n + 1. $
  En particular, para el tablero de ajedrez estándar ($m = n = 8$), el mínimo es $33$.
] <thm:rooks>

== Notación

Cada movimiento es _horizontal_ o _vertical_; sean $H$ y $V$ sus respectivas cantidades, de modo que el total es $T = H + V$. Un movimiento vertical se denomina _largo_ si recorre una columna completa (desde la fila $1$ hasta la fila $m$, o viceversa). Dado que un movimiento largo atraviesa todas las casillas de su columna, _en ese instante la columna no contiene ninguna otra torre_.

Para cada columna $c$, definimos
$
  "out"_c & = \#{"movimientos horizontales que salen de la columna " c}, \
    ell_c & = \#{"torres que realizan un movimiento largo en la columna " c}.
$
Cada movimiento horizontal abandona exactamente una columna, luego $H = sum_c "out"_c$. Si $L$ denota el número total de torres que realizan al menos un movimiento largo, entonces $L <= sum_c ell_c$.

== Cota inferior

Los siguientes dos lemas valen en realidad para todo $m >= 3$ y $n >= 2$.

#lemma(name: [Movimientos verticales])[
  Se cumple $V >= 4n - L$.
] <lem:vert>

#proof[
  Cada torre debe cambiar su fila inicial por la opuesta, cubriendo una distancia vertical de $m - 1$. Una torre que efectúa al menos un movimiento largo necesita como mínimo $1$ movimiento vertical; cualquier otra torre necesita al menos $2$, pues cada uno de sus movimientos verticales cubre a lo sumo $m - 2$ casillas. Sumando sobre las $2n$ torres se obtiene $V >= L + 2(2n - L) = 4n - L$.
]

#lemma(name: [Movimientos horizontales])[
  Para toda columna $c$, se cumple $"out"_c >= ell_c$ y $"out"_c >= 1$.
] <lem:horiz>

#proof[
  Sean $X_1, dots, X_ell$ las torres que realizan un movimiento largo en la columna $c$ (donde $ell = ell_c$), ordenadas según los instantes $t_1 < dots < t_ell$ de su primer movimiento largo en dicha columna.

  La columna $c$ comienza con dos torres y, en el instante $t_1$, contiene únicamente a $X_1$; por lo tanto, al menos una torre original de $c$ debió abandonarla mediante un movimiento horizontal antes de $t_1$. Además, justo después de $t_j$ la torre $X_j$ se encuentra en $c$, mientras que en $t_(j+1)$ únicamente $X_(j+1) != X_j$ ocupa $c$; en consecuencia, $X_j$ abandonó la columna $c$ mediante un movimiento horizontal durante el intervalo $(t_j, t_(j+1))$. Estas $ell$ salidas ocurren en intervalos disjuntos, por lo que son movimientos distintos y $"out"_c >= ell_c$.

  Finalmente, las dos torres originales de $c$ no pueden cruzarse dentro de la misma columna, pero al final la columna $c$ debe quedar con la torre blanca arriba de la negra; así, al menos una de las dos debe salir de la columna, luego $"out"_c >= 1$.
]

#proof(title: [Demostración de la cota inferior del @thm:rooks])[
  Combinando el @lem:vert y el @lem:horiz se obtiene la cota $4n$:
  $ T = H + V >= sum_c "out"_c + 4n - L >= sum_c ell_c + 4n - L >= sum_c ell_c + 4n - sum_c ell_c = 4n. $ <eq:cota4n>

  Supongamos por contradicción que $T = 4n$. Entonces todas las desigualdades en @eq:cota4n son igualdades; en particular, $"out"_c = ell_c$ para toda columna $c$. Como $"out"_c >= 1$, toda columna tiene al menos un movimiento largo; sea $t_1(c)$ el instante del primero en la columna $c$.

  1. La demostración del @lem:horiz identificó al menos una salida de $c$ antes de $t_1(c)$ y al menos una en cada intervalo posterior $(t_j, t_(j+1))$. Como $"out"_c = ell_c$, existe _exactamente una_ salida de $c$ antes de $t_1(c)$.
  2. El número de torres en una columna cambia solo por movimientos horizontales. Como $c$ inicia con $2$ torres, pierde exactamente una antes de $t_1(c)$ y contiene exactamente una en $t_1(c)$, _ninguna torre entra en $c$ antes de $t_1(c)$_.
  3. La torre que abandona $c$ antes de $t_1(c)$ entra en alguna columna $d != c$ en un instante $tau < t_1(c)$. Aplicando (2) a la columna $d$ se tiene $tau > t_1(d)$, de donde $t_1(d) < t_1(c)$.

  Así, toda columna posee otra cuyo primer movimiento largo ocurre estrictamente antes, contradiciendo la existencia de una columna con el primer movimiento largo de toda la secuencia. Por tanto, $T >= 4n + 1$.
]

== Construcción explícita en $4n + 1$ movimientos

Para cualquier tablero de $m >= 5$ filas y $n >= 2$ columnas (etiquetando las columnas $1, 2, dots, n$ de izquierda a derecha), las filas $1, 2, 3, 4, m$ son todas distintas. Esto permite ejecutar el siguiente esquema en $4n + 1$ movimientos:

1. *Preparación ($1$ movimiento):* La torre blanca de $(1, 1)$ sube a $(1, 3)$.
2. *Barrido de columnas $c = 2, dots, n$ ($3(n - 1)$ movimientos):* En cada columna $c$, la torre negra baja de $(c, m)$ a $(c, 2)$, se desplaza horizontalmente a $(c - 1, 2)$ y, al quedar vacía la columna $c$, la torre blanca sube en un movimiento largo de $(c, 1)$ a $(c, m)$.
3. *Cierre de la primera columna ($4$ movimientos):* La torre negra en $(1, m)$ baja a $(1, 4)$ y cruza horizontalmente por la fila $4$ vacía hasta $(n, 4)$; luego la torre blanca en $(1, 3)$ sube a $(1, m)$ y la torre negra en $(n, 4)$ baja a $(n, 1)$.
4. *Descenso final ($n - 1$ movimientos):* Las $n - 1$ torres negras estacionadas en $(n - 1, 2), dots, (1, 2)$ bajan un paso a la fila $1$.

El total es $1 + 3(n - 1) + 4 + (n - 1) = 4n + 1$, con $H = n$, $V = 3n + 1$ y $L = sum_c ell_c = n - 1$, verificando $V = 4n - L$ y $H = sum_c ell_c + 1$. Esto completa la demostración del @thm:rooks.

En particular, para $m = n = 8$ (columnas `a`–`h`), la secuencia resultante de $33$ movimientos es (ver listado completo sin abreviaciones en la @sec:ap-torres):

#block(breakable: false, inset: (left: 1.5em), above: 0.7em, below: 0.7em)[
  #set text(font: ("DejaVu Sans Mono", "Liberation Mono"), size: 9pt)
  #set par(first-line-indent: 0pt, leading: 0.7em)
  1. a1–a3 \
  2. b8–b2 #h(0.8em) 3. b2–a2 #h(0.8em) 4. b1–b8 #h(0.8em) 5. c8–c2 #h(0.8em) 6. c2–b2 #h(0.8em) 7. c1–c8 #h(0.8em) ... \
  20. h8–h2 #h(0.5em) 21. h2–g2 #h(0.5em) 22. h1–h8 \
  23. a8–a4 #h(0.5em) 24. a4–h4 #h(0.5em) 25. a3–a8 #h(0.5em) 26. h4–h1 \
  27. g2–g1 #h(0.5em) 28. f2–f1 #h(0.5em) 29. e2–e1 #h(0.5em) 30. d2–d1 #h(0.5em) 31. c2–c1 #h(0.5em) 32. b2–b1 #h(0.5em) 33. a2–a1
]

#remark[
  La prueba de minimalidad descansa sobre tres ideas: descomponer $T = H + V$ contando los movimientos horizontales por columna; intercambiar cada movimiento vertical largo (que ahorra un movimiento vertical) contra la salida horizontal requerida para vaciar la columna; y aplicar un principio extremal sobre el instante $t_1(c)$ del primer movimiento largo.
]

== Régimen de pocas filas ($m <= 4$)

Cuando $m <= 4$, las filas $3$ y $4$ dejan de estar simultáneamente disponibles como filas intermedias independientes, modificando el número mínimo de movimientos:

#proposition(name: [Casos $m in {2, 3, 4}$])[
  En un tablero de $m$ filas y $n >= 2$ columnas:
  1. Para $m = 4$, el mínimo requiere un movimiento adicional respecto del régimen $m >= 5$ al disponerse únicamente de dos filas intermedias.
  2. Para $m = 3$, la existencia de una sola fila central restringe el estacionamiento temporal e incrementa el número de movimientos necesarios.
  3. Para $m = 2$, el intercambio es imposible ($T_min (2, n) = infinity$), ya que el tablero carece de casillas vacías iniciales.
] <prop:rows>

#todo[Completar el desarrollo matemático y las cotas exactas para los casos $m = 4$ y $m = 3$.]
