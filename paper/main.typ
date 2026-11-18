#import "style.typ": *

#let _meses = ("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
#let _hoy = datetime.today()

#show: paper.with(
  title: [Cotas Óptimas de Movimientos para el Problema de Intercambio de $2n$-Torres],
  short-title: [Intercambio óptimo de $2n$-torres],
  author: [Sebastián Gabriel Morón Romero],
  affiliation: [Demuestratón ENIM 2026],
  date: [#_hoy.day() de #_meses.at(_hoy.month() - 1) de #_hoy.year()],
  abstract: [Determinamos el número mínimo exacto de movimientos necesarios para intercambiar dos filas opuestas de $n$ torres blancas y $n$ torres negras en un tablero de $m times n$ ($m >= 5, n >= 2$) sin capturas ni alternancia obligatoria de turnos. Demostramos que dicho mínimo es $4n + 1$ ($33$ en el tablero estándar de $8 times 8$) mediante una descomposición en movimientos horizontales y verticales junto con un argumento extremal, exhibimos la construcción explícita que alcanza la cota y estudiamos las variaciones según el número de filas y el tipo de pieza en el tablero $8 times 8$.],
)

#include "sections/01-introduccion.typ"
#include "sections/02-resolucion-principal.typ"
#include "sections/03-otras-piezas.typ"
#include "sections/04-conclusiones.typ"
#include "sections/declaracion-herramientas.typ"
#include "sections/referencias.typ"
#include "sections/apendice.typ"
