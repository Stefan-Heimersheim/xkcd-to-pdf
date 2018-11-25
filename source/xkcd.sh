#!/bin/bash

#    xkcd-gen, a script to generate pdfs from xkcd comics
#    Copyright (C) 2018 Stefan Heimersheim
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

if [ $# -eq 0 ]
  then
    echo "Please give the xkcd ID as an argument"
else
    rm tmp/* -f
    wget https://xkcd.com/$1/ -O tmp/comic.html -q
    wget $(grep "Image URL" tmp/comic.html) -O tmp/image.png -q
    grep img\ src tmp/comic.html | grep title= | cut -d = -f 3 | cut -d \" -f 2 | recode html > tmp/hovertext.txt
    grep  \<title\> tmp/comic.html | cut -d : -f 2 | cut -d \< -f 1 | sed 's/^ //' > tmp/title.txt
    echo "https://xkcd.com/$1/" > tmp/url.txt
    # Bad characters:  #, %, $, _, ^, &, {, }
    sed -i 's/#/\\#/g' tmp/*.txt
    sed -i 's/%/\\%/g' tmp/*.txt
    sed -i 's/\$/\\$/g' tmp/*.txt
    sed -i 's/_/\\_/g' tmp/*.txt
    sed -i 's/\^/\\^/g' tmp/*.txt
    sed -i 's/&/\\&/g' tmp/*.txt
    sed -i 's/{/\\{/g' tmp/*.txt
    sed -i 's/}/\\}/g' tmp/*.txt
    pdflatex -output-directory=tmp/ template.tex
    mv tmp/template.pdf bin/$1.pdf
    xdg-open bin/$1.pdf
fi
