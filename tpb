#!/bin/sh
# by Dominik Stanisław Suchora <suchora.dominik7@gmail.com>
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

SORT="$by_se"
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

while [ $# -gt 0 ]
do
  case "$1" in
    -s|--sort)
      case "$2" in
        name) SORT="$by_name";;
        rname) SORT="$by_rname";;
        size) SORT="$by_size";;
        rsize) SORT="$by_rsize";;
        time) SORT="$by_time";;
        rtime) SORT="$by_rtime";;
        se) SORT="$by_se";;
        rse) SORT="$by_rse";;
        le) SORT="$by_le";;
        rle) SORT="$by_rle";;
        uled) SORT="$by_uled";;
        ruled) SORT="$by_ruled";;
        type) SORT="$by_type";;
        rtype) SORT="$by_rtype";;
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
      SEARCH="$1"
      shift;;
  esac
done

#SEARCHP="$(echo "$SEARCH" | tr ' ' '+')"
SEARCHP="$(echo "$SEARCH" | tr ' ' '.')"

t1="$(mktemp)"
t2="$(mktemp)"
t_se="$(mktemp)"
t_le="$(mktemp)"
t_name="$(mktemp)"
t_type="$(mktemp)"
t_magnet="$(mktemp)"
t_size="$(mktemp)"
t_time="$(mktemp)"
t_uled="$(mktemp)"
trap 'rm "$t1" "$t2" "$t_size" "$t_time" "$t_uled" "$t_se" "$t_le" "$t_name" "$t_type" "$t_magnet"' EXIT

curl -s "$DOMAIN/search/$SEARCHP/$PAGE/$SORT/0" | hgrep 'td' | sed 's/<i>Anonymous<\/i>/<a class="detDesc">Anonymous<\/a>/g' > "$t1"
grep -o "Size [0-9].*," "$t1" | sed 's/Size //; s/\&nbsp\;/ /; s/,//;' > "$t_size"
grep -o 'Uploaded [0-9].*[0-9],' "$t1" | sed 's/Uploaded //; s/&nbsp\;/-/; s/,//' > "$t_time"
hgrep 'a +class="detDesc" @p"%i\n"' "$t1" > "$t_uled"
hgrep 'td +align="right" @p"%i\n"' "$t1" | sed 'N; s/\n/ /' > "$t2"
cut -d ' ' -f1 "$t2" > "$t_se"
cut -d ' ' -f2 "$t2" > "$t_le"
hgrep 'a +class="detLink" +title @p"%i\n"' "$t1" > "$t_name"
hgrep 'center; a @p"%i\n"' "$t1" | sed 'N; s/.*\n//' > "$t_type"
grep -oE 'magnet:\?[^"]+' "$t1" > "$t_magnet"

color_lines() {
    sed "s/^/\x1b[$1m/; s/$/\x1b[0m/" "$2" > "$3"
    cp "$3" "$2"
}

if [ "$COLOR" -eq 1 ]
then
    color_lines "$C_SIZE" "$t_size" "$t1"
    color_lines "$C_NAME" "$t_name" "$t1"
    color_lines "$C_LE" "$t_le" "$t1"
    color_lines "$C_SE" "$t_se" "$t1"
    color_lines "$C_AUTHOR" "$t_uled" "$t1"
    color_lines "$C_TIME" "$t_time" "$t1"
    color_lines "$C_CATEGORY" "$t_type" "$t1"
fi

paste -d "$DELIM" "$t_type" "$t_size" "$t_time" "$t_name" "$t_se" "$t_le" "$t_uled" | nl
printf 'num> '
read -r NUMBER
[ "$NUMBER" -gt 0 ] && sed "${NUMBER}q;d" "$t_magnet" | tee /dev/stderr | tr -d '\n' | xclip -sel clip
