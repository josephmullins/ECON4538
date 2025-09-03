// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [ECON4538 - Syllabus],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

This is an advanced undergraduate course in Labor Economics. Please read below for the course outline and syllabus.

= Class Times
<class-times>
== Lectures
<lectures>
Mondays and Wednesdays, 9:45am - 11am, Blegen Hall 240 Recitations

Fridays, 10:10am - 11am, Blegen Hall 215

= Email and Office Hours
<email-and-office-hours>
You will find details on how to contact me and sign up for office hours on the #link("https://canvas.umn.edu/")[course Canvas page];.

= Course Overview and Objectives
<course-overview-and-objectives>
In this course you will learn the basic tools of modern quantitative economics and apply them to questions concerning inequality in the labor market and the broader economy. We will be interested in understanding the models and tools that economists have developed to understand these phenomena, as well as in using these models to analyze the welfare implications of various government interventions. We will also review several approaches to quantifying and testing these economic models. Topics to be covered include: dynamic programming, solution methods of general equilibrium models, heterogeneous-agent macroeconomic models, models of human capital formation, and modern empirical evidence on the nature human capital.

= Student Learning Outcomes
<student-learning-outcomes>
On successfully completing this course, students should be familiar with some of the core concepts in modern quantitative economics. Students should be able to formalize an appropriate dynamic, stochastic, general equilibrium model to analyze a question of interest. Students should be able to solve and simulate such a model on a computer, for the purpose of interpreting data and conducting policy experiments.

= Course Prerequisites
<course-prerequisites>
I will assume that you are comfortable with micro concepts at the level of Econ 3101, 3102, such as the utility maximization problem and its related topics. I will also assume that you are comfortable with basic econometrics such as multivariate regression techniques as well as statistics at the level of Stat 3011. With regards to your math background, I will take as granted that you know how to work with calculus (derivatives). Students should be willing to invest time in learning a computer programming language such as `julia`.

= Textbook
<textbook>
We will use some chapters and problem sets from #emph[Recursive Macroeconomic Theory] @Ljungqvist2012[3rd edition] available online via the University Library. We will also make use of Journal Articles. I have provided links to electronic versions of the textbook and journal articles are available on the "Library Course Page".

== Additional Readings
<additional-readings>
You may also find some of the following books useful.

- John Stachurski, Economic Dynamics: Theory and Computation, 2nd edition, (2022).
- Christopher Pissarides, Equilibrium Unemployment Theory, 2nd edition, (2000).
- Jérôme Adda and Russell Cooper, Dynamic Economics: Quantitative Methods and Applications, (2003).
- Mario Miranda and Paul Fackler, Applied Computational Economics and Finance, (2002).
- Kenneth Judd, Numerical Methods in Economics, (1998).

= Course Software and Resources
<course-software-and-resources>
We will demonstrate and develop the computational tools you are learning using the `julia` programming language, which is well-suited for scientific computation and data analysis. LATIS provides a copy of `julia` on AppstoGo, but we recommend installing your own version, since it is completely free and open source. #link("https://julialang.org/")[See the website] for more details on the language and installation instructions.

Throughout the course, you may find the #link("https://julia.quantecon.org/intro.html")[QuantEcon] `julia` course (by Tom Sargent, John Stachurski, and Jesse Perla) a useful additional resource.

= Assessment
<assessment>
The course will be graded based on 6 problem sets (each worth 7%, 42% total), a midterm exam (20%), and a final exam (38%).

== Submission Guidelines
<submission-guidelines>
It is your responsibility to submit neat and legible solutions to the problem sets. Your TA may deduct marks for illegible submissions. Please follow these guidelines:

- All homework assignments must be submitted as a `Quarto` or `jupyter` notebook rendered as an html or pdf, with code and output showing all required results. You will be introduced to these notebooks through recitation materials.
- For questions requiring mathematical solutions, you may submit handwritten solutions if you prefer, but they must be submitted as a pdf using a scanner or scanning app on your phone.

= Course Outline
<course-outline>
== Dynamic Programming and Applications
<dynamic-programming-and-applications>
An important set of mathematical tools for solving dynamic models. Topics include:

- Bellman’s principal of optimality and contraction mappings
- Mathematical and computational exposition (using julia) of dynamic programming tools, applied to:
  - Models of job search
  - Infinite horizon and life-cycle models of savings

#strong[Reading];: #cite(<Ljungqvist2012>, form: "prose") Chapters 3-6.

== Savings and incomplete markets
<savings-and-incomplete-markets>
Review of the main theoretical models describing savings and self-insurance of agents under uncertainity and incomplete markets.

- Main savings problems
- Incomplete markets models as #cite(<Huggett1993>, form: "prose");, #cite(<aiyagari1994>, form: "prose");, #cite(<krusell1998>, form: "prose")
- Consumption inequality and income uncertainity.

#strong[Reading];: #cite(<Ljungqvist2012>, form: "prose") Chapters 17-18. #cite(<Deaton1991>, form: "prose");, #cite(<blundell1998>, form: "prose");, #cite(<Huggett1993>, form: "prose");, #cite(<aiyagari1994>, form: "prose");, #cite(<krusell1998>, form: "prose")

== Facts about Inequality
<facts-about-inequality>
We review and replicate facts about labor market inequality in the United States. Topics include:

- Documenting income inequality @moffitt2011[#cite(<Heathcote2010>, form: "prose");, #cite(<Heathcote2023>, form: "prose");, #cite(<Guvenen2021>, form: "prose");]
- Estimation of income risk @moffitt2011[#cite(<Meghir2004>, form: "prose");, #cite(<Low2010>, form: "prose");, #cite(<Guvenen2009>, form: "prose");]
- Welfare implications of income inequality @Storesletten2004
  - Redistribution vs Insurance
- The Intergenerational Elasticity of Earnings @corak2013[#cite(<mazumder2018>, form: "prose");]
- Skills and Inequality @Heckman2006[#cite(<Cunha2008a>, form: "prose");, #cite(<Cunha2009>, form: "prose");]

== Theories of Human Capital and Inequality
<theories-of-human-capital-and-inequality>
We introduce textbook theories of human capital formation and examine their empirical content. We develop computational tools to bring these theories to data. Topics include:

- The Becker-Tomes model of intergenerational inequality via human capital investment @Becker1979[#cite(<Becker1986>, form: "prose");]
  - Policy implications of the model (efficiency and redistribution)
- Debates on the empirical and conceptual merits of the Becker-Tomes model @Goldberger1989[#cite(<Mulligan1999>, form: "prose");, #cite(<Cunha2006>, form: "prose");, #cite(<Cunha2007>, form: "prose");]
- Quantitative and theoretical extensions of the baseline model @Lee2019[#cite(<Caucutt2020>, form: "prose");]

== Connecting Human Capital Theory with Evidence
<connecting-human-capital-theory-with-evidence>
We survey some empirical work that connects the theory with data. Topics include:

- A review of econometric methods for causal inference
- Evidence of the effect of social programs on child skill formation and long-run outcomes @Dahl2012[#cite(<Barr2022>, form: "prose");, #cite(<Bastian2018>, form: "prose");, #cite(<Carneiro2021>, form: "prose");, #cite(<bailey2024>, form: "prose");,]
- Evidence of the effect of early childhood education on skill formation and long-run outcomes @heckman2010[#cite(<Garcia2020>, form: "prose");, #cite(<Kline2016>, form: "prose");]
- Evidence of the effect of parenting and home interventions on skill formation and long-run outcomes @ATTANASIO2020[#cite(<Walker2022>, form: "prose");, #cite(<Carneiro2024>, form: "prose");]
- Estimating the technology of skill formation. @Cunha2008b[#cite(<ATTANASIO2020>, form: "prose");]

= Grading, Policies, and Procedures
<grading-policies-and-procedures>
Please see the course Canvas page for the department grading scale and a statement of University policies and procedures.

#bibliography("reading\_list.bib")

