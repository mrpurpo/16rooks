// Estilo matemático minimalista (inspirado en artículos clásicos SIAM / AMS)

#let _thm-env(kind, supplement, name: none, italic: true, numbered: true, body) = figure(
  kind: kind,
  supplement: supplement,
  numbering: if numbered { "1" } else { none },
  outlined: false,
  caption: none,
  block(width: 100%)[
    #context {
      let num = if numbered {
        [ #counter(figure.where(kind: kind)).display("1")]
      }
      let title = if name != none { [ (#name)] }
      strong[#supplement#num#title.]
    }#h(0.4em)#if italic {
      set text(style: "italic")
      body
    } else {
      body
    }
  ],
)

#let theorem(name: none, numbered: true, body) = _thm-env("thm", [Teorema], name: name, numbered: numbered, body)
#let lemma(name: none, numbered: true, body) = _thm-env("lem", [Lema], name: name, numbered: numbered, body)
#let proposition(name: none, numbered: true, body) = _thm-env("prop", [Proposición], name: name, numbered: numbered, body)
#let corollary(name: none, numbered: true, body) = _thm-env("cor", [Corolario], name: name, numbered: numbered, body)
#let definition(name: none, numbered: true, body) = _thm-env("def", [Definición], name: name, italic: false, numbered: numbered, body)
#let problem(name: none, numbered: false, body) = _thm-env("prob", [Problema], name: name, italic: false, numbered: numbered, body)

#let proof(title: [Demostración], body) = block(breakable: true, above: 0.6em, below: 1em, width: 100%)[
  _#title._#h(0.4em)#body#h(1fr)$square.stroked$
]

#let remark(title: [Observación], body) = block(breakable: true, above: 0.8em, below: 0.8em, width: 100%)[
  _#title._#h(0.4em)#body
]

#let todo(body) = block(above: 0.5em, below: 0.8em, inset: (left: 0.7em), stroke: (left: 0.8pt + luma(160)))[
  #set text(size: 9.5pt, fill: luma(95))
  _Pendiente:_ #body
]

#let paper(
  title: [],
  short-title: none,
  author: [],
  affiliation: none,
  date: none,
  abstract: none,
  body,
) = {
  let running = if short-title != none { short-title } else { title }

  set page(
    paper: "a4",
    margin: (x: 2.8cm, top: 2.8cm, bottom: 2.8cm),
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 8.5pt)
        grid(
          columns: (1fr, auto),
          align: (left, right),
          smallcaps(running),
          counter(page).display("1"),
        )
      }
    },
    footer: context {
      if counter(page).get().first() == 1 {
        set text(size: 9pt)
        align(center, counter(page).display("1"))
      }
    },
  )

  set text(
    font: ("New Computer Modern", "Libertinus Serif", "Liberation Serif"),
    size: 10.5pt,
    lang: "es",
  )
  show math.equation: set text(font: "New Computer Modern Math")

  set par(
    justify: true,
    leading: 0.62em,
    spacing: 0.62em,
    first-line-indent: 1.5em,
  )

  // Encabezados sobrios estilo artículo matemático
  set heading(numbering: "1.1.")
  show heading.where(level: 1): it => {
    v(1.3em, weak: true)
    set text(size: 11.5pt, weight: "bold")
    block(below: 0.65em, it)
  }
  show heading.where(level: 2): it => {
    v(1em, weak: true)
    set text(size: 10.5pt, weight: "bold")
    block(below: 0.5em, it)
  }
  show heading.where(level: 3): it => {
    v(0.8em, weak: true)
    set text(size: 10.5pt, weight: "regular", style: "italic")
    block(below: 0.4em, it)
  }
  show heading.where(level: 4): it => {
    v(0.6em, weak: true)
    set text(size: 10pt, weight: "semibold")
    block(below: 0.3em, it)
  }

  // Entornos de teorema y figuras
  show figure.where(outlined: false): it => {
    set align(left)
    show math.equation.where(block: true): set align(center)
    block(breakable: true, above: 0.9em, below: 0.9em, width: 100%, it.body)
  }
  show figure.where(kind: image): it => {
    set text(size: 9.5pt)
    v(0.6em)
    it
    v(0.6em)
  }

  // Numerar solo las ecuaciones etiquetadas (estilo clásico AMS/SIAM)
  set math.equation(numbering: "(1)")
  show math.equation.where(block: true): it => {
    if it.numbering != none and not it.has("label") {
      counter(math.equation).update(n => n - 1)
      math.equation(it.body, block: true, numbering: none)
    } else {
      it
    }
  }
  show ref: it => {
    let el = it.element
    if el != none and el.func() == math.equation {
      link(el.location(), numbering(el.numbering, ..counter(math.equation).at(el.location())))
    } else {
      it
    }
  }

  // Citas numéricas en corchetes
  set cite(style: "ieee")

  // Bloque de título minimalista
  align(center)[
    #set par(first-line-indent: 0pt, justify: false)
    #v(0.4em)
    #text(13.5pt, weight: "bold")[#title]
    #v(0.65em)
    #text(10.5pt)[#smallcaps(author)]
    #if affiliation != none {
      v(0.2em)
      text(9.5pt, style: "italic")[#affiliation]
    }
    #if date != none {
      v(0.2em)
      text(9pt)[#date]
    }
    #v(1.1em)
  ]

  if abstract != none {
    align(center)[
      #block(width: 86%)[
        #set align(left)
        #set text(size: 9.5pt)
        #set par(justify: true, first-line-indent: 0pt, leading: 0.58em)
        #smallcaps[*Resumen.*]#h(0.4em)#abstract
      ]
    ]
    v(1.1em)
  }

  body
}
