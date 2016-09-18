#!/bin/bash
# ncmpcpp2scrobblr.sh: last.fm/audioscrobbler song submission script for ncmpcpp 
# by CrimsonGlory
# based on mp3blstr2dscrbblr.sh 0.4 by Alexander Heinlein <alexander.heinlein@web.de>
#
# License: GPL v3
#
# version: 0.1
#

# perl audioscrobbler plugin directory
# (http://search.cpan.org/~roam/Audio-Scrobbler-0.01/lib/Audio/Scrobbler.pm)
# plugin binary/script
#BIN="../bin/scrobbler-helper"
BIN="./Audio-Scrobbler-0.01/bin/scrobbler-helper"

# maximum retries if first submission failed
MAX_RETRIES=15
# seconds to wait before second submission
# this value increases during further retries
WAIT=10


# check for scrobbler binary
if ! which $BIN >/dev/null
then
    echo "$BIN doesn't exist, make sure libaudio-scrobbler-perl is installed"
    exit
fi

# we need 2 + 7 arguments:
#  -P <client> -V <clientversion>
#  title, artist, album, year, comment, genre, length
# note: - comment will be left empty
#       - genre will be specified globally

# unfortunately mp3blaster isn't recognized as client >:(
CLIENT="mpd"
CLIVER="0.11"
while [ 1 ]; do

    # now get all information from ncmpcpp
    genre=$(/usr/bin/ncmpcpp --now-playing "{%g}")
    title=$(/usr/bin/ncmpcpp --now-playing "{%t}|{%f}")
    artist=$(/usr/bin/ncmpcpp --now-playing "{%a}|{<unknown>}")
    album=$(/usr/bin/ncmpcpp --now-playing "{%b}|{<unknown>}")
    year=$(/usr/bin/ncmpcpp --now-playing "{%y}")
    length=$(/usr/bin/ncmpcpp --now-playing "%l" | grep -E -o -e "^[0-9]+:[0-9]+$" | sed "s/:/*60+/g"  | bc | tr -d \"\n\" )

    # check if we have artist and title
    # else print error message to stderr
    if [ "$title" = "" ] || [ "$artist" = "" ]
    then
        echo "error: $(grep "^path " $MP3_STAT | cut -d ' ' -f2-) has no/invalid ID tag" 1>&2
    elif [ "$titleprev" == "$title" ] && [ "$artistprev" == "$artist" ] && [ "$albumprev" == "$album" ]
    then
        echo "same song";
    else
        echo "titleprev=$titleprev"
        echo "title=$title"
        echo "artistprev=$artistprev"
        echo "artist=$artist"
        echo "albumprev=$albumprev"
        echo "album=$album"

        # and finally execute plugin
        if [ -n "$DIR" ]; then cd "$DIR"; fi

        # creating function and variable for multiple use
        SUBMIT="$BIN -P $CLIENT -V $CLIVER \"$title\" \"$artist\" \"$album\" \"$year\" \"\" \"$genre\" \"$length\""
        submit()
        {
            "$BIN" -P "$CLIENT" -V "$CLIVER" "$title" "$artist" "$album" "$year" "" "$genre" "$length" >/dev/null
        }

        echo
        echo "executing $SUBMIT"
        echo
        submit

        retval="$?"
        # known return values:
        #   22 bad hostname
        #  104 Connection reset by peer
        #  110 connection timeout
        #  111 Connection refused (fuck you)
        #  114 couldn't complete handshake
        #  115 connection timeout
        #  255 couldn't complete handshake
        #  500 read timeout / EOF

        # last submission failed, resubmit
        if [ "$retval" ==  "22" ] || [ "$retval" == "104" ] || [ "$retval" == "110" ] || [ "$retval" == "111" ] || [ "$retval" == "114" ] || [ "$retval" == "115" ] || [ "$retval" == "255" ] || [ "$retval" == "500" ]
        then
            for ((i = 1; i <= MAX_RETRIES; i++))
            do
                echo "waiting for $WAIT seconds..."
                sleep $WAIT
                echo "retry #$i: executing $SUBMIT"
                submit

                if [ "$?" == "0" ]
                then
                    exit 0
                fi

                # doubling next wait, server may be down for any length of time
                let "WAIT = $WAIT * 2"
            done
            echo "couldn't submit song after $MAX_RETRIES retries: $?" 1>&2
        elif [ "$retval" != "0" ]
        then
            echo "return value: $retval" 1>&2
        fi

    fi

    sleep 30 
    titleprev=$title
    artistprev=$artist
    albumprev=$album
done
