#import "@preview/cetz:0.4.1" : *
#import calc: *
#import "utils.typ": *

///// COUNTER
#let global-counter = counter("global")
#let cite-counter = counter("cite")

///// COLORS
#let heading-1-color = red.darken(10%)
#let heading-2-color = green.darken(20%)
#let heading-3-color = purple.darken(20%)
#let item-color = blue
#let dev-accent-color = purple

#let a4h = 595
#let a4w = 842

#let color-box(c, color: dev-accent-color, title: [DEV]) = context {
  let stroke_width = 1pt
  let stroke_box = color + stroke_width
  let title = text(color, 10pt, align(center + horizon,
    [*#title*]
  ))
  let inset = 0pt
  let outset = 4pt

  let (width: titlew, height: titleh) = measure(title)
  titlew += 0.6em
  titleh += 0.3em

  let all = block(
    breakable: true,
    stroke: stroke_box,
    radius: 0pt,
    inset: inset,
    outset: outset,
    width: 100%,
    c
  )

  let dec = -0.5pt
  let offset = -0em
  let on-the-left = here().position().x.pt() <= a4h / 2
  block(breakable: true)[
  #place(
    dy: if on-the-left {- titleh + titlew - outset + dec}
        else {-titleh -outset + dec},
    dx: if on-the-left { 100% - titlew + outset + dec + offset }
        else {-titlew - outset - dec},
    rotate(if on-the-left {90deg} else { -90deg }, box(
      stroke: stroke_width + color,
      width: titlew,
      height: titleh,
      outset: dec,
      radius: 0pt,
      title
    ), origin: right + bottom)
  )
  #all
  ]
}

///// DEV
#let dev(c) = color-box(c)
#let warning(c) = color-box(c,
  color: orange,
  title: emoji.warning
)

///// ITEM
#let item(type, name, c) = {
  figure(
    placement: none,
    caption: name,
    kind: "agregyst:item",
    supplement: type,
    numbering: "1",
    c,
  )
}

#let citation-color(key) = {
  if key == <NAN> {
    gray
  } else if str(key) in colors-default {
    colors-default.at(str(key))
  } else {
    color-from-string(str(key), h: 80%, s: 80%, v: 100%)
  }
}

#let format-citation(key, supplement: none) = {
  set text(fill: citation-color(key))
  [\[]
  str(key)
  if supplement != none {
    [ #supplement]
  }
  [\]]
}

///// TABLEAU

#let bold-size = 0.85em

#let tableau(
  margin: 12pt,
  nb-columns : 2,
  body
) = {
  global-counter.step()
  cite-counter.update(0)

  set footnote.entry(gap: 0.1em, clearance: 0em, separator: none)
  set text(
    costs: (hyphenation: 100%, runt: 100%, widow: 100%, orphan: 100%),
    number-width: "proportional",
    fractions: true,
    size: 14pt,
    lang: "fr",
    font: "New Computer Modern"
  )
  show math.equation: set text(weight: "regular")
  set list(tight: false,  body-indent: 0.4em, spacing: 0.5em, marker: ("‣", "•", "–"))
  show strong: set text(bold-size)
  show link: it => underline(stroke: black, it)
  show raw: set text(font: "New Computer Modern Mono")
  set page(
    flipped: true,
    margin: margin,
    columns: nb-columns,
    background: {
      for i in range(1, nb-columns) {
        place(dx: i * 100% / nb-columns, dy: 0 * 40%,
          rotate(90deg, origin: left + bottom,
            line(length: 100%)
          )
        )
      }
    }
  )
  set par(
    justify: true,
    linebreaks: "optimized",
    leading: 0.6em,
    spacing: 0.6em,
    hanging-indent: 0em,
  )
  set footnote.entry(gap: 0.4em, clearance: 2pt, indent: 0pt)

  show figure.where(kind: "agregyst:item"): set align(start)
  show figure.where(kind: "agregyst:item"): set block(breakable: true)
  show figure.where(kind: "agregyst:item"): it => {
    underline({
      set text(fill: item-color, size: bold-size, weight: "bold")
      it.caption.supplement
      sym.space.nobreak
      it.caption.counter.display()
    })
    [ ]
    text(size: bold-size, weight: "bold", it.caption.body)
    it.body
  }

  show bibliography: set heading(numbering: none)
  show bibliography: it => {
    show heading: set text(fill: black)
    show heading: underline

    assert.eq(it.sources.len(), 1, message: "expected exactly one bibliography source")
    if type(it.sources.first()) != bytes {
      // We use `assert(false)` instead of `panic()` so that the error message
      // is printed as a string instead of its repr being printed.
      assert(
        false,
        message: "cannot read bibliography from file, try `bibliography(read(\"" + it.sources.first() + "\", encoding: none))`",
      )
    }
    let file = yaml(it.sources.first())

    heading(
      numbering: none,
      if it.title == auto {
        [Bibliographie]
      } else {
        it.title
      },
    )

    let short-author(author) = {
      let parts = author.split(",").map(str.trim)
      assert(parts.len() in (1, 2))
      if parts.len() == 1 {
        return parts.first()
      }
      let (last-name, first-name) = parts
      [#first-name.clusters().first().~#last-name]
    }

    let display-entry(key) = {
      let book = file.at(str(key))

      let authors = book.author
      if type(authors) == str {
        authors = (authors,)
      }

      h(0.8em)
      [ ]
      format-citation(key)
      sym.space.nobreak
      authors.map(short-author).join(last: [ & ])[, ]
      [, ]
      text(style: "italic", book.title)
      [.]
      linebreak()
    }

    let done = ()
    for elt in query(cite) {
      if elt.key != <NAN> and elt.key not in done {
        display-entry(elt.key)
        done.push(elt.key)
      }
    }

    if it.full {
      for k in file.keys() {
        let key = label(k)
        if key != <NAN> and key not in done {
          display-entry(key)
        }
      }
    }
  }

  show cite : it => {
    format-citation(it.key, supplement: it.supplement)
    let lbl = label("cite_" + cite-counter.display() + "_" + global-counter.display())

    if query(selector(lbl).before(here())).len() == 0 {
    // if query(selector(lbl)).len() == 0 {
    [
      #metadata(str(it.key))
      #lbl
      #cite-counter.step()
    ]
    }
  }

  show title: set text(size: 0.65em)
  show title: set block(spacing: 0.9em)
  show title: underline

  show heading: set block(spacing: 0.7em)
  show heading: underline

  show heading.where(level: 1): set heading(numbering: n => numbering("I.", n))
  show heading.where(level: 1): set text(size: 0.77em, fill: heading-1-color)

  show heading.where(level: 2): set heading(numbering: (.., n) => numbering("A.", n))
  show heading.where(level: 2): set text(size: 0.75em, fill: heading-2-color)

  show heading.where(level: 3): set heading(numbering: (.., n) => numbering("1.", n))
  show heading.where(level: 3): set text(size: 0.8em, fill: heading-3-color)

  std.title()
  body
}

#let short-item-dictionnary = (
  "Définition" : "Def",
  "Problème" : "Prob",
  "Proposition" : "Prop",
  "Propriété" : "Prop",
  "Complexité" : "Complex",
  "Notation" : "Not",
  "Méthode" : "Métho",
  "Implémentation" : "Implem",
  "Application" : "App",
  "Remarque" : "Rem",
  "Théorème" : "Thm",
  "Exemple" : "Ex",
  "Algorithme" : "Algo",
  "Pratique" : "Prat",
  "Motivation" : "Motiv",

  // ANGLAIS
  "Definition" : "Def",
  "Property" : "Prop",
  "Remark": "Rem",
  "Implementation": "Implem",
  "Example": "Ex",
  "Alorithm": "Algo",
  "Theorem": "Thm",
)
#let short-item-type(item) = {
  // assert(type(item) == content, message: "Some error")
  let text = if type(item) == content and item.func() == text {
    item.text
  } else if type(item) == str {
    item
  }
  if text != none and text in short-item-dictionnary {
    short-item-dictionnary.at(text)
  } else {
    item
  }
}

#let without-refs(it) = {
  let seq = [].func()
  let styled = {
    show strong : it => ""
    strong[Hey]
  }.func()
  if it.func() == seq {
    seq(it.children.map(without-refs))
  } else if it.func() == heading {
    let fields = it.fields()
    let body_it = fields.remove("body")
    heading(..fields, without-refs(body_it))
  } else if it.func() == underline {
    underline(without-refs(it.body))
  } else if it.func() == styled {
    without-refs(it.child)
  } else if it.func() == block {
    without-refs(it.body)
  } else if it.func() == ref {
    format-citation(it.target, supplement: if "supplement" in it.fields() { it.supplement })
  } else {
    it
  }
}

#let recap(
  show-heading-big-numeral: true,
) = {
  pagebreak()

  set text(9pt, weight: "black")
  set par(leading: 3pt)

  let length = 0.034em
  let debug = 0pt
  let padding = -10

  show: box.with(width: 100%, height: 100%)
  set align(center + horizon)

  context canvas(length: length, {
    import draw : *

    let xy(x, y) = (x * 1.5, y * 1.04)
    let get_real_page(p, x) = {
      p * 2 + if x >= a4w / 2 {1} else {0}
    }

    let ratio = 1em.to-absolute()
    let global_id = str(global-counter.get().at(0))

    rect(xy(0, - a4h * 1), (rel: xy(a4w, a4h)))
    rect(xy(0, - a4h * 2), (rel: xy(a4w, a4h)))
    rect(xy(0, - a4h * 3), (rel: xy(a4w, a4h)))
    line(xy(a4w / 2, 0), xy(a4w / 2, - a4h * 3))

    let fst_page = 1 // TODO: Remove that.
    let todo = ()
    let seen = ()
    let seen_citation = ()

    let cites = () // todo use this

    let compute_pos(pos, fst_page, seen, offset) = {
      let real_page = get_real_page((pos.page - fst_page), pos.x.pt())
      // * 2 + if pos.x.pt() >= a4w / 2 {1} else {0}
      let posx = if pos.x.pt() >= a4w / 2 {a4w / 2} else {0}
      let posy = - pos.y.pt() - (pos.page - fst_page) * a4h
      let f = ((page, x, y)) => (y < posy) and page == real_page
      if seen.any(f) {
        let (page, x, y) = seen.filter(f).sorted(key: ((page, x, y)) =>(page, y)).at(0)
        posy = y - offset
      }
      (real_page, posx, posy)
    }

    // Citation
    let citation_f(seen, pos, fst_page) = {}
    for i in range(0, cite-counter.get().at(0)) {
      let name = "cite_" + str(i) + "_" + global_id
      let lab = label(name)
      let pos = locate(lab).position()
      let item = query(lab).at(0).value
      cites.push((item, pos, fst_page))
    }

    let draw_cite_box(seen_citation, cite_attach, (p1, x1, y1)) = {
      let (name0, p0, x0, y0) = if seen_citation.len() == 0 {
        (<NAN>, 0, 0, 0)
      } else {
        seen_citation.at(seen_citation.len() - 1)
      }
      let current_page = p0
      if cite_attach != none {
        // Does not always terminate
        while (current_page != p1 + 1 and current_page < 7) {
          rect(
            xy(
              calc.rem(current_page, 2) * a4w / 2,
              if current_page == p0 { y0 }
              else { -calc.div-euclid(current_page, 2) * a4h },
            ),
            xy(
              (calc.rem(current_page, 2) + 1) * a4w / 2,
              if current_page == p1 and y1 != none { y1 }
              else { -(calc.div-euclid(current_page, 2) + 1) * a4h }
            ),
            fill: citation-color(name0).transparentize(80%),
            stroke: none
          )
          current_page += 1
        }
      }
    }

    let typeset-title(seen, seen_citation, pos, fst_page, item, cite_attach) = {
      let (real_page, posx, posy) = compute_pos(pos, fst_page, seen, 0)
      let (posx, posy, dx) = (posx + 10, posy, a4w / 2 - 20)
      let height_item = -measure(box(width: dx * length * 1.5, item, stroke: debug)).height.pt()
      let dy = height_item * 1.04 / (length.em * ratio.pt())
      let res = content(
        xy(posx, posy),
        (rel: xy(dx, dy)),
        box(width: 100%, height: 100%, item, stroke:debug),
        anchor: "north-west"
      )
      let (x, y) = (posx, posy) // citation pos
      res += draw_cite_box(seen_citation, cite_attach, (real_page, posx, posy))

      return (real_page, posx, posy + dy, res, x, y)
    }

    for elt in query(std.title) {
      let pos = elt.location().position()
      let item = without-refs(elt)
      todo.push(("title", (pos, fst_page, item)))
    }

    let simulate-heading(it) = {
      set text(size: 1.1em, fill: heading-1-color) if it.level == 1
      set text(size: 0.9em, fill: heading-2-color) if it.level == 2
      show: underline
      if it.numbering != none {
        numbering(it.numbering, ..counter(heading).at(it.location()))
        [ ]
      }
      without-refs(it.body)
    }

    let typeset-h1(seen, seen_citation, pos, fst_page, item, i, cite_attach) = {
      let (real_page, posx, posy) = compute_pos(pos, fst_page, seen, 10)
      let res
      if show-heading-big-numeral {
        res += content(
          xy(
            a4w / 4  + a4w / 2 * rem(real_page, 2),
            -a4h / 2  + - a4h * div-euclid(real_page, 2)
          ),
          text(140pt, gray.transparentize(70%), numbering("I", i + 1))
        )
      }

      let (x, y) = (posx, posy) // citation pos
      res += draw_cite_box(seen_citation, cite_attach, (real_page, posx, posy))

      let (posx, posy, dx) = (posx + 10, posy + padding, a4w / 2 - 20)
      let height_item = - measure(box(width: dx * length * 1.5, item, stroke:debug)).height.pt()
      let dy = height_item * 1.04 / (length.em * ratio.pt())
      res += content(
        xy(posx, posy),
        (rel: xy(dx, dy)),
        box(width: 100%, height: 100%, item, stroke:debug),
      )
      return (real_page, posx, posy + dy + padding, res, x, y)
    }

    for (i, elt) in query(heading.where(level: 1).before(here())).enumerate() {
      let pos = elt.location().position()
      todo.push(("h1", (pos, fst_page, simulate-heading(elt), i)))
    }

    let typeset-h2(seen, seen_citation, pos, fst_page, item, cite_attach) = {
      let (real_page, posx, posy) = compute_pos(pos, fst_page, seen, 0)

      let (posx, posy, dx) = (posx + 20, posy - 5, a4w / 2 - 30)
      let height_item = - measure(box(width: dx * length * 1.5, item, stroke:debug)).height.pt()
      let dy = height_item * 1.04 / (length.em * ratio.pt())

      let res = content(
        xy(posx, posy), (rel: xy(dx, dy)),
        box(
          width: 100%, height: 100%,
          item, stroke:debug),
      )

      let (x, y) = (posx, posy) // citation pos
      res += draw_cite_box(seen_citation, cite_attach, (real_page, posx, posy))

      return (real_page, posx, posy + dy + padding, res, x, y)
    }

    for elt in query(heading.where(level: 2).before(here())) {
      let pos = elt.location().position()
      todo.push(("h2", (pos, fst_page, simulate-heading(elt))))
    }

    // ITEM
    let item_f(seen, seen_citation, pos, fst_page, item_type, item, i, cite_attach) = {
      let (real_page, posx, posy) = compute_pos(pos, fst_page, seen, 0)
      item_type = short-item-type(item_type)
      item = text(black, item_type) + [ ] + item
      let res = content(
        xy(posx, posy), (rel: xy(40, - 35)),
        box(width: 100%, height: 100%, stroke: 1pt + black, outset: 0pt,
          align(center + horizon, [#i]))
      )

      let (x, y) = (posx, posy) // citation pos
      res += draw_cite_box(seen_citation, cite_attach, (real_page, posx, posy))

      let (posx, posy, dx) = (posx + 50, posy - 5, a4w / 2 - 60)
      let height_item = - measure(box(width: dx * length * 1.5, item, stroke:debug)).height.pt()

      let dy = height_item * 1.04 / (length.em * ratio.pt())
      res += content(xy(posx, posy), (rel: xy(dx, dy)),
        block(width : 100%, height: 100%,
          text(blue, item), stroke:debug),
      )
      return (real_page, posx, min(posy + 5 - 35, posy + dy), res, x, y)
    }

    for (i, elt) in query(figure.where(kind: "agregyst:item")).enumerate() {
      let pos = elt.location().position()
      let item = without-refs(elt.caption.body)
      todo.push(("item", (pos, fst_page, elt.supplement, item, i + 1)))
    }

    // Layout
    todo = todo.sorted(key:
      e => {
        let x = e.at(1).at(0).x.pt()
        let y = e.at(1).at(0).y.pt()
        let p = get_real_page(e.at(1).at(0).page, x)
        (p, y)
      })

    // Attach the citation to the right element
    for citation_attached_to_item in cites.map(
      ((cite_attach, (page:p0, x:x0, y:y0), fst_page)) => {
      let l = todo
        .enumerate()
        .filter(((i, (type, args))) => {
          let (page, x, y) = args.at(0)
          get_real_page(page, x.pt()) == get_real_page(p0, x0.pt())
        })
        .sorted(key: ((i, (type, args))) => {
          let (page, x, y) = args.at(0)
          abs(y.pt() - y0.pt())
        })
      if l.len() > 0 {
        let (i, (type_item, args)) = l.at(0)
        (i, (type_item, args, cite_attach))
      }
    }) {
      if citation_attached_to_item != none {
        let (i, (type_item, args, cite_attach)) = citation_attached_to_item
        todo.at(i) = (type_item, args, cite_attach)
      }
    }

    todo = todo.map(t => {
      if t.len() == 2 {
        (..t, none)
      } else {
        t
      }
    })

    for (type_element, args, cite_attach) in todo {
      let typeset = (
        title: typeset-title,
        h1: typeset-h1,
        h2: typeset-h2,
        item: item_f,
      )
      let (
        real_page, posx, posy, res, cite_x, cite_y
      ) = typeset.at(type_element)(
          seen, seen_citation, ..args, cite_attach
        )
      res
      if cite_attach != none {
        seen_citation.push((cite_attach, real_page, cite_x, cite_y))
      }
      seen.push((real_page, posx, posy))
    }
    draw_cite_box(seen_citation, "NAN", (5, 0, -a4h * 3))
  })
}

// Graph
#let graph(g) = canvas(length: 1em, {
    import draw: *
    let r = g.radius
    let links = g.links
    let nodes = g.nodes
    for node in nodes {
      circle(node.at(1), radius: r, name: node.at(0))
      content(node.at(0), [#node.at(0)])
    }
    for link in links {
      if (link.at(0) == "bezier") {
        set-style(mark: (end: ">"))
        bezier(
          (link.at(1), r, link.at(2)),
          (link.at(2), r, link.at(1)),
          link.at(3)
        )
      } else {
        set-style(mark: (end: ">"))
        line(..link)
      }
    }
})

#let authors(c) = {
  align(bottom + center, c)
}
