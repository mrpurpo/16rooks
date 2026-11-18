# Intercambio óptimo de $2n$-torres

Trabajo para la **Demuestratón ENIM 2026** (Problema 1): determinar el número mínimo de movimientos para intercambiar una fila de $n$ torres blancas con una fila de $n$ torres negras en un tablero de $m \times n$, sin capturas ni alternancia de turnos.

## Resultado principal

Para todo tablero con $m \ge 5$ filas y $n \ge 2$ columnas, el mínimo es

$$T_{\min}(m, n) = 4n + 1,$$

es decir, **33 movimientos** en el tablero estándar de $8 \times 8$. El paper también analiza el régimen de pocas filas ($m \le 4$) y las variaciones con otras piezas en $8 \times 8$:

| Pieza   | Mínimo ($8 \times 8$) |
|---------|-----------------------|
| Torre   | 33                    |
| Dama    | 23                    |
| Alfil   | 30                    |
| Caballo | 64                    |
| Rey     | 112                   |
| Peón    | Imposible             |

## Estructura

```
paper/
├── main.typ            # Documento principal
├── style.typ           # Plantilla y entornos (teorema, lema, etc.)
├── referencias.bib     # Bibliografía
├── assets/             # Figuras
└── sections/           # Secciones del paper
code/                   # Código auxiliar
literature/             # Bibliografía en PDF (no versionada)
```

## Compilar

El paper está escrito en [Typst](https://typst.app). Desde la raíz del repositorio:

```sh
typst compile --root paper paper/main.typ
```

O con VS Code y la extensión [Tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist), que exporta el PDF al guardar. El paquete `@preview/board-n-pieces` se descarga automáticamente en la primera compilación.

Los PDFs (tanto el compilado como la literatura) no se versionan; ver `.gitignore`.
