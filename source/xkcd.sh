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
tempdir=$(mktemp -d)
if [ $# -eq 0 ]
  then
    echo "Please give the xkcd ID as an argument"
else
    wget https://xkcd.com/$1/ -O $tempdir/comic.html -q
    wget $(grep "Image URL" $tempdir/comic.html) -O $tempdir/image.png -q
    grep img\ src $tempdir/comic.html | grep title= | cut -d = -f 3 | cut -d \" -f 2 | recode html > $tempdir/hovertext.txt
    grep  \<title\> $tempdir/comic.html | cut -d : -f 2 | cut -d \< -f 1 | sed 's/^ //' > $tempdir/title.txt
    echo "https://xkcd.com/$1/" > $tempdir/url.txt
    # Bad characters:  #, %, $, _, ^, &, {, }
    sed -i 's/#/\\#/g' $tempdir/*.txt
    sed -i 's/%/\\%/g' $tempdir/*.txt
    sed -i 's/\$/\\$/g' $tempdir/*.txt
    sed -i 's/_/\\_/g' $tempdir/*.txt
    sed -i 's/\^/\\^/g' $tempdir/*.txt
    sed -i 's/&/\\&/g' $tempdir/*.txt
    sed -i 's/{/\\{/g' $tempdir/*.txt
    sed -i 's/}/\\}/g' $tempdir/*.txt
    cat template.tex | sed "s|image.png|$tempdir/image.png|g" > $tempdir/template.tex
    pdflatex -output-directory=$tempdir/ $tempdir/template.tex
    mv $tempdir/template.pdf $tempdir/$1.pdf
    #cp $tempdir/$1.pdf bin/$1.pdf
    xdg-open $tempdir/$1.pdf
fi
