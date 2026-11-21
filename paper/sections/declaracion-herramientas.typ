#import "../style.typ": *

#heading(level: 1, numbering: none)[Declaración de herramientas] <sec:declaracion-herramientas>

- *Inteligencia artificial:* _Claude_ se usó para elaborar la demostración inicial, hacer una búsqueda profunda en buscadores académicos y proponer artículos y libros relevantes; _Claude Code_, para generar el código del repositorio que busca combinaciones que resuelven el problema (ver Repositorio). _Gemini en VSCode (Antigravity)_ se usó para mejorar la claridad, el formato y la presentación del documento.
- *Lenguajes de programación:* _C++_, para el núcleo del repositorio que busca soluciones óptimas con las distintas piezas; _Python_, para la interfaz, el verificador independiente de secuencias (`check`), la cota por asignación (`bound`) y los programas de comprobación (`tests/reference.py`, `tests/structure.py`).
- *Buscadores académicos:* _Consensus_ y _Alphaxiv_, conectados a Claude, para buscar artículos en bases de datos confiables y verificables (véanse las Referencias).
- *Herramientas públicas:* _Lichess.org_ (`https://lichess.org/editor`), como tablero virtual para probar combinaciones manualmente en el tablero completo y en fracciones de este.
