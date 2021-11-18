#!/bin/bash
# by TUVIMEN <suchora.dominik7@gmail.com>
# License: GNU GPLv3

by_name=1
by_rname=2
by_time=3
by_rtime=4
by_size=5
by_rsize=6
by_se=7
by_rse=8
by_le=9
by_rle=10
by_uled=11
by_ruled=12
by_type=13
by_rtype=14

SORT=$by_se
PAGE=0
SEARCH=""
NAME=$(basename "$0")

while [ $# -gt 0 ]
do
  case "$1" in
    -s|--sort)
      case "$2" in
        name) SORT=$by_name;;
        rname) SORT=$by_rname;;
        size) SORT=$by_size;;
        rsize) SORT=$by_rsize;;
        time) SORT=$by_time;;
        rtime) SORT=$by_rtime;;
        se) SORT=$by_se;;
        rse) SORT=$by_rse;;
        le) SORT=$by_le;;
        rle) SORT=$by_rle;;
        uled) SORT=$by_uled;;
        ruled) SORT=$by_ruled;;
        type) SORT=$by_type;;
        rtype) SORT=$by_rtype;;
      esac
      shift 2
      ;;
    -h|--help)
        echo -e "$NAME [OPTION]... [PATTERN]\nSearch for PATTERN in pb.\nExample: $NAME -s size -p 2 'archlinux'\n"
        echo -e "Options:\n  -s,  --sort TYPE\tsort using TYPE that can be: name, rname, size, rsize, time, rtime, se, rse, le, rle, uled, ruled, type, rtype"
        echo -e "  -p,  --page NUM\tshow page at NUM"
        echo -e "  -h,  --help\t\tshow help"
        echo -e "\nMagnet link will be copied via xclip."
        exit 0
        ;;
    -p|--page)
        PAGE="$2"
        shift
        shift
        ;;
    *)
      SEARCH="$1"
      shift
      ;;
  esac
done

#SEARCHP=$(tr ' ' '+' <<< "$SEARCH")
SEARCHP=$(tr ' ' '.' <<< "$SEARCH")

t1=$(mktemp)
t2=$(mktemp)
t_se=$(mktemp)
t_le=$(mktemp)
t_name=$(mktemp)
t_type=$(mktemp)
t_magnet=$(mktemp)
t_size=$(mktemp)
t_time=$(mktemp)
t_uled=$(mktemp)
trap 'rm "$t1" "$t2" "$t_size" "$t_time" "$t_uled" "$t_se" "$t_le" "$t_name" "$t_type" "$t_magnet"' EXIT

curl -s "https://tpb.party/search/$SEARCHP/$PAGE/$SORT/0" | hgrep 'tr' | sed 's/<i>Anonymous<\/i>/<a class="detDesc">Anonymous<\/a>/g' > "$t1"

grep -o "Size [0-9].*," "$t1" | sed 's/Size //; s/\&nbsp\;/ /; s/,//;' > "$t_size"

grep -o 'Uploaded [0-9].*[0-9],' "$t1" | sed 's/Uploaded //; s/&nbsp\;/-/; s/,//' > "$t_time"

hgrep 'a +class="detDesc"' "$t1" | grep -o '>.*<' | sed 's/^>//; s/<$//' > "$t_uled"

hgrep 'td +align="right"' "$t1" | sed '/>$/{N; s/>\n//}; s/<td align="right">//g; s/<\/td/ /g;' > "$t2"

cut -d ' ' -f1 "$t2" > "$t_se"

cut -d ' ' -f2 "$t2" > "$t_le"

hgrep 'a +class="detLink" +title' "$t1" | grep -o '>.*<' | sed 's/<//; s/>//; s/&.*;/\&/' > "$t_name"

hgrep 'center; a' "$t1" | grep -o '>.*<' | sed '/<$/{N; s/<\n/|/}; s/>//g; s/<//g' > "$t_type"

grep -o '<a href=".*" title="Download this torrent using magnet">' "$t1" | sed 's/<a href="//; s/".*//' > "$t_magnet"

nl <(paste "$t_type" "$t_size" "$t_time" "$t_name" "$t_se" "$t_le" "$t_uled")
echo -n 'num> '
read -r NUMBER
[ $NUMBER -gt 0 ] && sed "${NUMBER}q;d" "$t_magnet" | tee /dev/stderr | xclip -sel clip