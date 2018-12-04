#!/bin/bash
# depends on: bash, wget, curl, grep, python3, sed, pdflatex
number="$1"
# use current date if no number is given.
if [ -z "$number" ]; then
    siteurl="https://xkcd.com/"
    number="$(date +'%d-%m-%Y')"
else
    siteurl="https://xkcd.com/$number/"
fi

# function to decode url chars
htmldecode() {
    echo "$@" | python3 -c \
        'import html, sys; [print(html.unescape(l), end="") for l in sys.stdin]'
}

# create tempdir
directory="$(mktemp -d)"

# download, decode etc.
echo "$siteurl" > "$directory""/xkcd.url"
wget --quiet "$siteurl" -O "$directory""/xkcd.html"
htmldecode "$(grep "<img src.*title=.*alt=.*/>" "$directory""/xkcd.html" | \
    grep -o 'title=".*" alt' | cut -c 8- | rev | cut -c 6- | \
    rev)" > "$directory""/xkcd.txt"
wget --quiet "$(grep hotlinking/embedding "$directory""/xkcd.html" | \
    grep -o "https://.*png")" -O "$directory""/xkcd.png"
htmldecode "$(grep "^<title" "$directory""/xkcd.html" | cut -c 14- | rev | \
    cut -c 9- | rev)" > "$directory""/xkcd.title"
echo "$number"":" > "$directory""/xkcd.num"

# escape LaTeX-dangerous characters
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
escape_characters "$directory""/xkcd.title"
escape_characters "$directory""/xkcd.txt"
escape_characters "$directory""/xkcd.num"

# create document.
echo '
\documentclass[12pt,a4paper]{article}
\usepackage[margin=1cm]{geometry}
\usepackage{graphicx}
\usepackage[export]{adjustbox}
\usepackage[utf8x]{inputenc}

\begin{document}
\pagenumbering{gobble}
\begin{center}
  \null
  \vfill
  {\Large\bfseries \input{xkcd.num}\input{xkcd.title}} \\
  {\small\tt \input{xkcd.url}} \\[10pt]
  \includegraphics[scale=0.7,max width=0.95\textwidth,max height=0.9\textheight]{xkcd.png} \\[10pt]
  \parbox{0.7\textwidth}{
    \itshape \input{xkcd.txt}
  }
  \vfill
\end{center}
\end{document}
' > "$directory""/xkcd.tex"

# cleanup and save to cwd.
currentwdir="$(pwd)"
cd "$directory"
pdflatex xkcd.tex 1>/dev/null
cd "$currentwdir"
cp "$directory""/xkcd.pdf" "./xkcd-$number.pdf"
rm -r "$directory"

