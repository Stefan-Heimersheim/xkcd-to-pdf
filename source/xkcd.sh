#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "Please give the xkcd ID as an argument"
else
    rm tmp/* -f
    wget https://xkcd.com/$1/ -O tmp/comic.html -q
    wget $(grep "Image URL" tmp/comic.html) -O tmp/image.png -q
    grep img\ src tmp/comic.html | grep title= | cut -d = -f 3 | cut -d \" -f 2 | recode html > tmp/hovertext.txt
#    Works not in 1909 but in 1132:
#    grep Title\ text tmp/comic.html | cut -d : -f 2 | cut -d \} -f 1 | sed 's/^ //' | recode html > tmp/hovertext.txt
    grep  \<title\> tmp/comic.html | cut -d : -f 2 | cut -d \< -f 1 | sed 's/^ //' > tmp/title.txt
    echo "https://xkcd.com/$1/" > tmp/url.txt
    pdflatex -output-directory=tmp/ template.tex
    mv tmp/template.pdf bin/$1.pdf
fi
