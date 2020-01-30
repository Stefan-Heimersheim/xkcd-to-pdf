#!/bin/bash

#    xkcd-gen, a script to generate pdfs from xkcd comics
#    Copyright (C) 2018-2020 Stefan Heimersheim, Lennart Klebl
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Dependencies: pdflatex, curl, sed, recode (alternatively python + python-html)

currentdir="$(pwd)"
tempdir=$(mktemp -d)

usage() {
    echo "Usage: xkcd.sh NUMBER [-2]"
}

if { [ $# -eq 2 ] && [ "$2" != "-2" ]; } || [ $# -gt 2 ]; then
   usage
   exit
fi

# Download commic, latest one if no number is given.
if [ -z "$1" ]; then
    curl https://xkcd.com > "$tempdir/comic.html"
    number=$(grep "og:url" $tempdir/comic.html  | cut -d / -f 4)
else
    curl "https://xkcd.com/$1/" > "$tempdir/comic.html"
    number="$1"
fi

# Download image
curl $(grep "Image URL" $tempdir/comic.html | cut -d : -f 2-3) > "$tempdir/image.png"

# Extract texts to hovertext.txt, title.txt, url.txt and number.txt
echo "$number" > "$tempdir/number.txt"
echo "https://xkcd.com/$number/" > "$tempdir/url.txt"
if [ -x "$(command -v decode)" ]; then
    echo Using decode
    grep img\ src "$tempdir/comic.html" | grep title= | cut -d = -f 3 | cut -d \" -f 2 | recode html > "$tempdir/hovertext.txt"
    grep  \<title\> "$tempdir/comic.html" | cut -d : -f 2 | cut -d \< -f 1 | sed 's/^ //' > "$tempdir/title.txt"
else
    echo Using python
    htmldecode() {
        echo "$@" | python3 -c \
        'import html, sys; [print(html.unescape(l), end="") for l in sys.stdin]'
    }
    htmldecode "$(grep "<img src.*title=.*alt=.*/>" "$tempdir""/comic.html" | \
        grep -o 'title=".*" alt' | cut -c 8- | rev | cut -c 6- | \
        rev)" > "$tempdir""/hovertext.txt"
    htmldecode "$(grep "^<title" "$tempdir""/comic.html" | cut -c 14- | rev | \
        cut -c 9- | rev)" > "$tempdir""/title.txt"
fi

# Escape characters that are problematic for LaTeX:  #, %, $, _, ^, &, {, }
function escape_characters () {
    sed -i 's/#/\\#/g' "$1"
    sed -i 's/%/\\%/g' "$1"
    sed -i 's/\$/\\$/g' "$1"
    sed -i 's/_/\\_/g' "$1"
    sed -i 's/\^/\\^/g' "$1"
    sed -i 's/&/\\&/g' "$1"
    sed -i 's/{/\\{/g' "$1"
    sed -i 's/}/\\}/g' "$1"
}

escape_characters "$tempdir/number.txt"
escape_characters "$tempdir/url.txt"
escape_characters "$tempdir/hovertext.txt"
escape_characters "$tempdir/title.txt"

# LaTeX templates
flavour1='\documentclass[a4paper]{article}
\usepackage[top=2cm,bottom=2cm,left=2cm,right=2cm]{geometry}
\usepackage[utf8]{inputenc}
\usepackage{graphicx}
\usepackage{hyperref}
\pagenumbering{gobble} 

\begin{document}
 \begin{center}
  {\Huge\textbf{\input{title.txt}}}\\
  {\Large\texttt{\input{url.txt}}}\\
  \vspace{0.05\textwidth}
  \includegraphics[width=\textwidth,height=0.8\textheight,keepaspectratio]{image.png}\\
  \vspace{0.05\textwidth}
  {\input{hovertext.txt}}
 \end{center}
\end{document}
'

flavour2='
\documentclass[12pt,a4paper]{article}
\usepackage[margin=1cm]{geometry}
\usepackage{graphicx}
\usepackage[export]{adjustbox}
\usepackage[utf8x]{inputenc}

\makeatletter
\define@key{Gin}{resolution}{\pdfimageresolution=#1\relax}
\makeatother

\begin{document}
\pagenumbering{gobble}
\begin{center}
  \null
  \vfill
  {\Large\bfseries \input{number.txt}: \input{title.txt}} \\
  {\small\tt \input{url.txt}} \\[10pt]
  \includegraphics[resolution=72,scale=0.7,max width=0.95\textwidth,max height=0.9\textheight]{image.png} \\[10pt]
  \parbox{0.7\textwidth}{
    \itshape \input{hovertext.txt}
  }
  \vfill
\end{center}
\end{document}
'

# Compiling the document

if [ "$2" != "-2" ]; then
    echo $flavour1 | sed "s|image.png|$tempdir/image.png|g" > "$tempdir/$number.tex"
else
    echo $flavour2 | sed "s|image.png|$tempdir/image.png|g" > "$tempdir/$number.tex"
fi
pdflatex -output-directory="$tempdir/" "$tempdir/$number.tex"
cp -i "$tempdir/$number.pdf" "$currentdir/xkcd-$number.pdf"
rm -r "$tempdir"
xdg-open $currentdir/xkcd-$number.pdf