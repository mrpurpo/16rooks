#import "style.typ": *

#let _meses = ("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
#let _hoy = datetime.today()

#show: paper.with(
  title: [Cotas Óptimas de Movimientos para el Problema de Intercambio de $2n$-Torres],
  short-title: [Intercambio óptimo de $2n$-torres],
  author: [Sebastián Gabriel Morón Romero],
  affiliation: [Demuestratón ENIM 2026],
  date: [#_hoy.day() de #_meses.at(_hoy.month() - 1) de #_hoy.year()],
  draft: true,
  abstract: [Determinamos el número mínimo exacto de movimientos necesarios para intercambiar dos filas opuestas de $n$ torres blancas y $n$ torres negras en un tablero de $m times n$ para todo $m >= 3$ y $n >= 2$, sin capturas ni alternancia obligatoria de turnos. Demostramos que dicho mínimo es $4n + 1$ cuando $m >= 5$ ($33$ en el tablero estándar de $8 times 8$) y $4n + 2$ cuando $m in {3, 4}$, combinando una descomposición en movimientos horizontales y verticales con un argumento extremal y construcciones explícitas que alcanzan la cota. Adicionalmente, estudiamos las variaciones del problema al reemplazar las torres por las restantes piezas del ajedrez en el tablero de $8 times 8$.],
)

#include "sections/01-introduccion.typ"
#include "sections/02-resolucion-principal.typ"
#include "sections/03-otras-piezas.typ"
#include "sections/verificacion-computacional.typ"
#include "sections/04-conclusiones.typ"
#include "sections/declaracion-herramientas.typ"
#include "sections/referencias.typ"
#include "sections/apendice.typ"
