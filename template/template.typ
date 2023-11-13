#import "font.typ": *


#let Thesis(
  // 参考文献bib文件路径
) = {
  set page(paper:  "a4",
           margin: (
              top: 2.54cm,
              bottom: 2.54cm,
              left: 2.5cm,
              right: 2cm),
          footer: [
              #set align(center)
              #set text(size: 10pt, baseline: -3pt)
              #counter(page).display(
              "1")
            ],
          header: align(left)[  // 页眉左侧需要放入 images 文件夹中的图片 Header.png
      #image("images/Header.png", width: 50mm)
    ],
  )

  // 标题
  include "report_title.typ"

  // 正文
  include "body.typ"

  // 参考文献
  include "reference.typ"

  //附录
  include "appendix.typ"

}
