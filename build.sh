#!/bin/bash

CHAPTERS=400
CURLFLAGS="--compressed"
OUTPREFIX="bem"
OUTNAME="$OUTPREFIX-$CHAPTERS"
TMP1="/tmp/tmp1"


# create source dir if it doesn't exit
if [[ ! -e source ]]; then
    mkdir source
fi

# check for undownloaded chapters
for x in `seq $CHAPTERS`
do
    filename="source/$x.html"
    url="https://www.wuxiaworld.com/novel/the-book-eating-magician/bem-chapter-$x"
    if [[ ! -e $filename ]]; then
        echo "Downloading Chapter $x"
        curl $CURLFLAGS -o $filename $url
    fi
done

# create markdown dir if it doesn't exit
if [[ ! -e markdown ]]; then
    mkdir markdown
fi

# reformat to markdown
for x in `seq $CHAPTERS`
do
    input="source/$x.html"
    output="markdown/$x.md"
    if [[ ! -e $output ]]; then
        echo "stripping headers/footers: Chapter $x"
        grep -A 2 "fr-view" $input | head -n 2 > $TMP1
        echo "converting to markdown: Chapter $x"
        pandoc $TMP1 -f html-native_divs-native_spans -t markdown -o $output
    fi
done

# create cleanmd dir if it doesn't exit
if [[ ! -e cleanmd ]]; then
    mkdir cleanmd
fi

# remove div tags and rewrite chapter tag
for x in `seq $CHAPTERS`
do
    padded=`printf '%03d' $x`
    input="markdown/$x.md"
    output="cleanmd/$padded.md"
    if [[ ! -e $output ]]; then
        echo "cleaning markdown: Chapter $x"

        #chapter titles
		echo "# Chapter $x" > $output
		head -n -1 $input | sed 's/^\\\*.*\\\*.*\\\*$/---------/' | grep -v -e "chapters for the day" \
			-e "chapters will be updated after" -e "Patreon" -e "opening sponsored chapters" \
			-e "tier has early access to" -e 'support would be appreciate' -e "am busy with uni" \
			-e "BEM Artwork Page" -e "imgur" -e "urrent schedule.*chapters a week" \
			-e "will now be.*chapters a week" -e "oday I will do.*chapter.* of each story" \
			-e "I have also updated" -e "Check out updated posting days" -e "be appreciated.$">> $output
		tail -n 1 $input | grep -v -- "----" >> $output

        # reformat
        pandoc $output -o $TMP1
        mv $TMP1 $output
    fi
done

# create cover dir if it doesn't exit
if [[ ! -e cover ]]; then
    mkdir cover
fi
if [[ ! -e cover/raw_cover.png ]]; then
    echo "Fetching cover image"
    curl -o cover/raw_cover.png https://www.wuxiaworld.com/images/covers/bem.png
fi
if [[ ! -e cover/cover.png ]]; then
    echo "Resizing cover image"
    convert cover/raw_cover.png -resize 600x900\! cover/cover.png
fi

# Produce epub if current doesn't exist
if [[ ! -e ${OUTNAME}.epub ]]; then
    # ask to remove old ones
    rm -i $OUTPREFIX-*.epub
    echo 'building epub...'
    pandoc -S -o ${OUTNAME}.epub title.txt `ls cleanmd/*md | sort -n` --toc --epub-cover-image=cover/cover.png
fi

if [[ ! -e ${OUTNAME}.mobi ]]; then
    rm -i $OUTPREFIX-*.mobi
    echo 'building mobi...'
    kindlegen ${OUTNAME}.epub

    rm -i mobi7-$OUTPREFIX-*.mobi
    echo 'extracting mobi7...'
    # cd .. && git clone https://github.com/kevinhendricks/KindleUnpack.git
    python ../KindleUnpack/lib/kindleunpack.py -s ${OUTNAME}.mobi
    cp ${OUTNAME}/mobi7-${OUTNAME}.mobi .
    rm -rf $OUTNAME
fi

