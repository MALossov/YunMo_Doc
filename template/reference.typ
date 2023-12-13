#import "font.typ": *

// #pagebreak()

// 支持的引文格式："apa", "chicago-author-date", "ieee", or "mla"
// [] TODO: DIY 国标引文格式
#let bibliography_file = "../reference/FPGA创新赛.bib"
  // 展示参考文献

#if bibliography_file != none {
  show bibliography: set text(font_size.xiaosi)
  show heading : it => {
    // set align(center)
    set text(font:songti, size: 0pt)
    it
  }
  bibliography(bibliography_file,
      title: [],
      style: "chicago-author-date")
}