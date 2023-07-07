#!/bin/sh
# by Dominik Stanisław Suchora <suchora.dominik7@gmail.com>
# License: GNU GPLv3

SORT='7' #se
PAGE=0
SEARCH=""
DOMAIN="https://tpb.party"
DELIM="\t"

C_LE="31"
C_SE="32"
C_SIZE="33"
C_CATEGORY="34"
C_AUTHOR="35"
C_TIME="36"
C_NAME="39"
COLOR=1

alias ucurl='curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) QtWebEngine/5.15.2 Chrome/87.0.4280.144 Safari/537.36" -H "Accept-Encoding: gzip, deflate" --compressed'

while [ $# -gt 0 ]
do
  case "$1" in
    -s|--sort)
      case "$2" in
        name) SORT='1';;
        rname) SORT='2';;
        size) SORT='3';;
        rsize) SORT='4';;
        time) SORT='5';;
        rtime) SORT='6';;
        se) SORT='7';;
        rse) SORT='8';;
        le) SORT='9';;
        rle) SORT='10';;
        uled) SORT='11';;
        ruled) SORT='12';;
        type) SORT='13';;
        rtype) SORT='14';;
      esac
      shift 2;;
    -h|--help)
        NAME="$(basename "$0")"
        printf "%s [OPTION]... [PATTERN]\nSearch for PATTERN in pb.\nExample: %s -s size -p 2 'archlinux'\n\n" "$NAME" "$NAME"
        printf "Options:\n  -s,  --sort TYPE\t\tsort using TYPE that can be: name, rname, size, rsize, time, rtime, se, rse, le, rle, uled, ruled, type, rtype\n"
        printf "  -d,  --domain DOMAIN\t\tset domain to DOMAIN\n"
        printf "  -D,  --delimiter DELIM\tset delimiter to DELIM\n"
        printf "  -p,  --page NUM\t\tshow page at NUM\n"
        printf "  -c,  --color\t\t\tcolor output\n"
        printf "  -C,  --no-color\t\tdisable coloring of output\n"
        printf "  -h,  --help\t\t\tshow help\n"
        printf "\nMagnet link will be copied via xclip.\n"
        exit 0;;
    -c|--color)
        COLOR=1
        shift;;
    -C|--no-color)
        COLOR=0
        shift;;
    -p|--page)
        PAGE="$2"
        shift 2;;
    -d|--domain)
        DOMAIN="$2"
        shift 2;;
    -D|--delimiter)
        DELIM="$2"
        shift 2;;
    *)
        if [ -z "$SEARCH" ]
        then
          SEARCH="$1"
        else
          SEARCH="$SEARCH $1"
        fi
        shift;;
  esac
done

#SEARCHP="$(echo "$SEARCH" | tr ' ' '+')"
SEARCHP="$(echo "$SEARCH" | tr ' ' '.')"

t1="$(ucurl -s "$DOMAIN/search/$SEARCHP/$PAGE/$SORT/0" | hgrep 'td' | sed 's/<i>Anonymous<\/i>/<a class="detDesc">Anonymous<\/a>/g')"
magnets="$(echo "$t1" | grep -oE 'magnet:\?[^"]+')" #magnet
{
echo "$t1" | hgrep 'center; a @p"%i\n"' | sed 'N; s/.*\n//' #type
echo "$t1" | grep -o "Size [0-9].*," | sed 's/Size //; s/\&nbsp\;/ /; s/,//;' #size
echo "$t1" | grep -o 'Uploaded [0-9A-Za-z].*[0-9],' | sed 's/Uploaded //; s/&nbsp\;/-/; s/,//' #time
echo "$t1" | hgrep 'a +class="detLink" +title @p"%i\n"' #name
t2="$(echo "$t1" | hgrep 'td +align="right" @p"%i\n"' | sed 'N; s/\n/ /')"
echo "$t2" | cut -d ' ' -f1 #se
echo "$t2" | cut -d ' ' -f2 #le
echo "$t1" | hgrep 'a +class="detDesc" @p"%i\n"' #uled
} | awk 'function print_fields(lines,fields,step) {
        colors[0] = '"$C_CATEGORY"'
        colors[1] = '"$C_SIZE"'
        colors[2] = '"$C_TIME"'
        colors[3] = '"$C_NAME"'
        colors[4] = '"$C_SE"'
        colors[5] = '"$C_LE"'
        colors[6] = '"$C_AUTHOR"'
        ORS = ""
        for (i = 0; i < step; i++) {
            for (j = 0; j < fields; j++) {
                if (j != 0)
                    print "'"$DELIM"'"
                if ('"$COLOR"')
                    print "\033["colors[j]"m"lines[(step*j)+i]"\033[0m"
                else
                    print lines[(step*j)+i]
            }
            printf "\n"
        }
    }

    BEGIN { l=0; fields = 7 }
    { lines[l++]=$0 }
    END {
        if (l >= fields)
        if (l%fields == 0) {
                step = l/fields
                print_fields(lines,fields,step)
        } else
            print "length of some data fields does not match the others"
    }' | nl

[ -z "$magnets" ] && exit 1
printf 'num> '
read -r NUMBER
[ "$NUMBER" -gt 0 ] && echo "$magnets" | sed "${NUMBER}q;d" | tee /dev/stderr | tr -d '\n' | xclip -sel clip
