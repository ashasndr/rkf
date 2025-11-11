#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./imports/global.sh

#############################
################## FUNCTIONS
changelogs() {
    cat <<EOF
    2.4 - Added wiki, config.conf, and --tet and --editconf
    2.3 - Added tsvs
    2.2 - Added recover save option, which recovers the temporary editing file
    2.1 - Added disco genre, made et YYMM instead of MMYY, recoded so reasonings can have dashes and improved output (shuf | nl thing)
    2.0 - Completely recoded everything, renamed to rkf, better error display, mcatalog support, full line copying support, the options people would "want" are now all enabled by default
    ---
    1.7 - Added markers and numeration (first update in a hot minute too)
    1.6 - Added windows compatibility through wsl
    1.5 - Added emotes arg, nocopy arg, added display arg. added dash miniargs
    1.4 - Renamed args norank to nork and ncsinfo to ninf, added title arg.
    1.3 - Reformatted to clear code, having an certain order isn't needed in arguments anymore. Added ncsinfo and import arg
    1.2 - Added nanify
    1.1 - Added order argument and help
    1.0 - Created with regular formatting
EOF
    exit 0

}

usage() {
    cat <<EOF
Usage: rkf [options]

Options:
  -n            Use the NCS scheme
  -m            Use the Monstercat scheme
  -e            Use VNF (Vip NCS Fans Server) discord emojis for genres
  -r            Use the last saved file and continue editing it
  -s            Disable separators (-=-= :emoji: =-=-)
  -t            Get from TSV files (MUST USE WITH --et/expresstitle)
  -2            2 lines (Artists, Songs)
  -3            3 lines (Genre, Artists, Songs)
                if neither 2 or 3 are selected, it'll default to full document lines.
  -d            Toggle display after execution
  -c            Toggle copy result after finished
  -w            Sets you to Windows (WSL) mode (but likely already auto-detects if you are on windows, only use if you are experiencing issues)

  --title "yourtext"        Set a title (Ranking (scheme) (yourtext))
        aka --ti
  --subtitle "yourtext"     Set the subtitle
        aka --sb
  --fulltitle "yourtext"    Set a title (yourtext)
        aka --ft
        aka --full
  --expresstitle YYMM       Set a title (Ranking (scheme) (MM converted to month) 20(YY))
        aka --et
        aka --yymm
  --tet                     Express title + TSV import
  --updatedb                Update db of a certain label (must have correct info in clipboard, and must be called with -n or -m)
        aka --dbupd
        aka --db
  -h, --help                Show this help message
  --last                    Shows last output
  --err                     Shows last error
  --cperr                   Copies last error
  --cplast                  Copies last output
  --mcatalog                Copies MCatalog URL
  --monstercatplaylist      Copies Monstercat playlist URL
  --ncsinfo                 Copies NCS Info URL
  --ncsplaylist             Copies NCS playlist URL
  --changelog               Display changelogs
EOF
    exit "$1"
}

set_clipboard_cmds() {
    if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
        clip_copy="wl-copy"
        clip_paste="wl-paste"
    elif command -v xclip >/dev/null 2>&1; then
        clip_copy="xclip -selection clipboard"
        clip_paste="xclip -selection clipboard -o"
    else
        echo "[error] No wl-copy/wl-paste or xclip found in PATH" >&2
        return 1
    fi
}

# this isn't really used anymore but i keep it here just in case
display_debug() {
    echo "[debug] title     : $title"
    echo "[debug] subtitle  : $subtitle"
    echo "[debug] scheme    : $scheme"
    if $has_emojis; then
        echo "[debug] i contain emojis"
    else
        echo "[debug] i do not contain emojis"
    fi
    echo "[debug] lines     : $lines"
}

get_title() {
    echo "# Ranking ${scheme} ${1}"
}

get_month_query() {
    local input=$1
    local num_year="20${input:0:2}"
    local num_month="${input: -2}"
    echo "${num_year}-${num_month}-"
}

disphelpcmd() {
    echo "Try rkf --help, or checking the wiki on the github repo. (https://github.com/ashasndr/rkf/wiki/Config)"
    exit 1
}

unexpress_title() {
    local input=$1
    # grabs first 2 charas  prepend 20 directly
    local num_year="20${input:0:2}"
    # grabs the last 2 charas
    local num_month="${input: -2}"

    month_query="${num_year}-${num_month}-"

    local month_name=""

    case "$num_month" in
        "01") month_name="January"      ;;
        "02") month_name="February"     ;;
        "03") month_name="March"        ;;
        "04") month_name="April"        ;;
        "05") month_name="May"          ;;
        "06") month_name="June"         ;;
        "07") month_name="July"         ;;
        "08") month_name="August"       ;;
        "09") month_name="September"    ;;
        "10") month_name="October"      ;;
        "11") month_name="November"     ;;
        "12") month_name="December"     ;;
    esac


    echo "# Ranking ${scheme} ${month_name} ${num_year}"
}

init_values() {
    if [[ $lines -eq 0 ]]; then
        if [[ $scheme == "Monstercat" ]]; then
            cols="5 6 7"
        elif [[ $scheme == "NCS" ]]; then
            cols="3 4 5"
        fi
    elif [[ $lines -eq 2 ]]; then
        cols="1 2"
    else
        cols="1 2 3"
    fi
}

lnend() {
    sed 's/\r//'
}

backtodos() {
    if [ $has_windows == true ]; then
        sed -i 's/$/\r/'
    else
        cat
    fi
}

update_db() {
    if [ ! -d "./tsv" ]; then
        mkdir tsv
    fi

    if [ "$scheme" == "" ]; then
        echo "error: you must specify a scheme (-m/-n)"
    else
        $clip_paste > "./tsv/${scheme}.tsv"
        echo "updated ${scheme} record"
    fi
}

##                                          gets expanded to empty if does not exist
if grep -qi microsoft /proc/version || [ -n "${WSL_DISTRO_NAME:-}" ]; then
    has_windows=true
fi

set_clipboard_cmds

#############################
################## FLAG PARSING
if [[ $# -eq 0 ]]; then
    usage 1
fi

while getopts ":23dmenwhactrs-:" opt; do
    case $opt in
        m) scheme="Monstercat" ;;
        n) scheme="NCS" ;;
        e) has_emojis=!$has_emojis ;;
        2) lines=2 ;;
        3) lines=3 ;;
        c) has_copy=!$has_copy ;;
        a) has_avgcalc=!$has_avgcalc ;;
        d) has_display=!$has_display ;;
        w) has_windows=!$has_windows ;;
        s) has_separators=!$has_separators ;;
        r) has_recover=true ;;
        t) has_tsv_source=true ;;
        h) usage 0 ;;
        -) # long options
            case $OPTARG in
                title|ti)
                    title=$(echo "# Ranking ${scheme} ${!OPTIND}")
                    OPTIND=$((OPTIND + 1))
                    ;;
                tet)
                    has_tsv_source=true
                    ;&
                expresstitle|et|yymm)
                    month_query=$(get_month_query ${!OPTIND})
                    title=$(unexpress_title ${!OPTIND})
                    OPTIND=$((OPTIND + 1))
                    ;;
                subtitle|sb)
                    subtitle=$(echo "-# ${!OPTIND}")
                    OPTIND=$((OPTIND + 1))
                    ;;
                fulltitle|full|ft)
                    title=$(echo "# ${!OPTIND}")
                    OPTIND=$((OPTIND + 1))
                    ;;
                updatedb|dbupd|db)
                    update_db
                    exit 0
                    ;;
                config)
                    $edit ./config.sh
                    exit 0
                    ;;
                help)
                    usage 0 ;;
                errors|err)
                    $display errors.txt
                    exit 0
                    ;;
                copyerrors|cperr)
                    $clip_copy < errors.txt
                    exit 0
                    ;;
                last)
                    $display rankoutput.txt
                    exit 0
                    ;;
                copylast|cplast)
                    $clip_copy < rankoutput.txt
                    exit 0
                    ;;
                mcatalog|mcatsh)
                    echo "https://docs.google.com/spreadsheets/d/116LycNEkWChmHmDK2HM2WV85fO3p3YTYDATpAthL8_g/edit" | $clip_copy
                    echo "https://docs.google.com/spreadsheets/d/116LycNEkWChmHmDK2HM2WV85fO3p3YTYDATpAthL8_g/edit"
                    exit 0
                    ;;
                ncsinfo|ncssh)
                    echo "https://docs.google.com/spreadsheets/d/1XEPGiHCQ7thyRtyqei4yIuXaL-kXYQX-2bmx6ei99Is/edit?" | $clip_copy
                    echo "https://docs.google.com/spreadsheets/d/1XEPGiHCQ7thyRtyqei4yIuXaL-kXYQX-2bmx6ei99Is/edit?"
                    exit 0
                    ;;
                ncsplaylist|ncspl)
                    echo "https://www.youtube.com/playlist?list=PLv1Kobfrv9Wtx2X6OG6pzg4ZEqNfsgCyW" | $clip_copy
                    echo "https://www.youtube.com/playlist?list=PLv1Kobfrv9Wtx2X6OG6pzg4ZEqNfsgCyW"
                    exit 0
                    ;;
                monstercatplaylist|mcatplaylist|mcatpl)
                    echo "https://www.youtube.com/playlist?list=PLv1Kobfrv9Wuo9JgSkVcoFTpBukYKmSvu" | $clip_copy
                    echo "https://www.youtube.com/playlist?list=PLv1Kobfrv9Wuo9JgSkVcoFTpBukYKmSvu"
                    exit 0
                    ;;
                changelogs|cglg)
                    changelogs
                    ;;
                *)
                    echo "[error] Unknown flag: --$OPTARG" >&2
                    disphelpcmd
            esac
            ;;
        \?)
            echo "[error] Unknown flag: -$OPTARG" >&2
            disphelpcmd
    esac
done
shift $((OPTIND - 1))

##########################
###### ERROR CHECKING
if [[ $scheme == "" ]]; then
    echo "[error] No scheme specified."
    disphelpcmd
elif [[ $title = "" ]]; then
    echo "[error] No title specified"
    disphelpcmd
elif [[ $has_emojis && $lines -eq 2 ]]; then
    echo "[error] Cannot use emojis if you select only 2 columns"
    disphelpcmd
fi

init_values

############
### TEXT SORTING FUNCTIONS

filter_out_ep() {
    if [ "$lines" -ne 2 ]; then
        grep -Ev '^(EP|Double Single|Album|Compilation)'
    else
        cat
    fi
}

parse_wanted_cols() {
    awk -v cols="$cols" -v FS='\t' -v OFS='\t' '{
        n = split(cols, a, " ")
        for (i=1; i<=n; i++) printf "%s%s", $a[i], (i<n ? OFS : ORS)
    }'
}
# reminder for future ash if needed ORS=newline

emojify() {
    if [ "$has_emojis" ] && [ "$lines" -ne 2 ]; then
        awk -v FS='\t' -v OFS='\t' '
        function genre_of(genre) {
            if (genre ~ /Drum & Bass|Breaks|Neurofunk|Jump-Up/) return ":PinkCircle:"
            else if (genre ~ /Future House|Techno/) return ":PurpleCircle:"
            else if (genre ~ /Phonk|Brazilian Funk/) return ":TealCircle:"
            else if (genre ~ /Jersey Club|Hip Hop|Trap/) return ":GreenCircle:"
            else if (genre == "Future Bass") return ":LavenderCircle:"
            else if (genre ~ /Hardcore|Trance|Garage|Electronic|Hardstyle/) return ":WhiteCircle:"
            else if (genre == "Melodic Bass") return ":CyanCircle:"
            else if (genre ~ /Midtempo|Glitch Hop|Moombah/) return ":MintCircle:"
            else if (genre == "Melodic Dubstep") return ":CyanCircle:"
            else if (genre == "Dubstep") return ":BlueCircle:"
            else if (genre ~ /Pop|Synthwave|Synthpop|Traditional|Funk|Disco/) return ":OrangeCircle:"
            else if (genre == "Electro") return ":YellowCircle:"
            else if (genre == "Rock") return ":BlackCircle:"
            else if (genre ~ /Drumstep|Halftime/) return ":RedCircle:"
            else if (genre ~ /House$/ || genre == "Bass House") return ":YellowCircle:"
            else if (genre ~ /Chillout|Ambient|LoFi|Miscellaneous/) return ":WhiteCircle:"
            else return ":WhiteCircle:."
        }
        {
            if (NF == 3) {
                $1 = genre_of($1)
            }
            print
        }'
    else
        cat
    fi
}

format_into_song() {
    awk -v FS='\t' -v OFS=' ' '
    {
        for (i = 1; i <= NF; i++) {
            if (i < NF) {
                printf "%s%s", $i, OFS
            } else {
                printf "- %s | ", $i
            }
        }
        printf ORS
    }'
}

afterformat() {
    error_file="errors.txt"
    : > "$error_file"   # truncate errors

    shuf | nl -w1 -s$'\t' | \
    awk -F'\t|\\|' -v OFS='|' -v ERR="$error_file" '
    #   $1 = shuffle_index (int)
    #   $2 = song info text
    #   $3 = opinion
    {
        idx  = $1
        text = $2; sub(/[ \t]+$/, "", text)

        if (NF < 3) { print $0 > ERR; next }

        rest = $3

        if (match(rest, /^[ \t]*([0-9]+(\.[0-9])?)\/([0-9]+)[ \t]*-[ \t]*(.*)$/, m)) {
            rating    = m[1] + 0
            scale     = m[3] + 0
            reasoning = m[4]
            if (reasoning == "") reasoning = "no reasoning"
            if (scale != 10) { print $0 > ERR; next }
        } else {
            print $0 > ERR; next
        }

        printf "%s\t%06d\t**%s** | %s/%s - %s\n", rating, idx, text, rating, scale, reasoning
    }' \
    | sort -t $'\t' -k1,1nr -k2,2n \
    | cut -f3- \
    | nl -w1 -s'. '
}



separatorify() {
    if [ "$has_separators" = true ]; then
        last_emoji=""
        while IFS= read -r line; do
            if [[ "$line" =~ ([0-9]+(\.[0-9]+)?)/10 ]]; then
                score="${BASH_REMATCH[1]}"
            else
                continue
            fi

            [[ -z "$score" ]] && continue

            if [[ "$score" == *.* ]]; then
                score_no_dot="${score/./}"    # 9.5 -> 95
            else
                score_no_dot="${score}0"      # 9 -> 90
            fi

            [[ "$score_no_dot" =~ ^[0-9]+$ ]] || continue

            intscore=$((score_no_dot))

            # set current emoji
            if (( intscore < 25 )); then
                current_emoji=":x:"
            elif (( intscore < 45 )); then
                current_emoji=":-1:"
            elif (( intscore < 60 )); then
                current_emoji=":shrug:"
            elif (( intscore < 80 )); then
                current_emoji=":+1:"
            elif (( intscore == 100 )); then
                current_emoji=":star:"
            else
                current_emoji=":heart_eyes:"
            fi


            # only display emoji if different from last one
            if [[ "$current_emoji" != "$last_emoji" ]]; then
                echo -=-= "$current_emoji" =-=-
                last_emoji="$current_emoji"
            fi

            echo "$line"
        done
    else
        cat
    fi
}

avgcalc() {
    if [ $has_avgcalc == true ]; then
        awk -F'\\|' '
        {
            rating_part = $2
            gsub(/^[ \t]+/, "", rating_part)

            split(rating_part, parts, "-")
            gsub(/^[ \t]+|[ \t]+$/, "", parts[1])

            if (match(parts[1], /^([0-9]+(\.[0-9])?)\/([0-9]+)$/, m)) {
                rating = m[1] + 0
                scale  = m[3]
                if (scale == 10) {
                    sum += rating
                    count++
                }
            }
        }
        END {
            avg = sum / count
            printf "### Average monthly score: %.1f/10\n", avg
        }'
    fi
}

##########################
##### THE ACTUAL PROGRAM THAT DOES THE PROGRAM STUFF

if [ $has_recover == false ]; then
    if [ $has_tsv_source == true ]; then
        if [ $month_query == "" ]; then
            echo '[error] no month has been selected with --expresstitle'
            exit 1
        fi

        date_in_line=$(head -n 3 "tsv/${scheme}.tsv" | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')

        # 2025-05- turns into 2025-06-01
        month_end=$(date -d "${month_query}01 +1 month" +%F)

        t_line=$(date -d "$date_in_line" +%s)
        t_month=$(date -d "$month_end" +%s)

        if (( t_month > t_line )); then
            echo "[warning] selected month (${month_query::-1}) is in the future compared to the date stored ($date_in_line)."
            echo -n "do you wish to continue anyway? (n/y): "
            read -r answer
            case "$answer" in
                [Yy]*)
                    ;;
                *)
                    printf "\n[info] Closing. if you want to update the local file, the command to update is rkf -n|m --db. \
make sure you have the whole catalog spreadsheet in your clipboard before running the command"
                    exit 1
                    ;;
            esac
        fi

        grep "${month_query}" "./tsv/${scheme}.tsv" > rankinput.txt
    else
        $clip_paste > rankinput.txt
    fi
    lnend < rankinput.txt | parse_wanted_cols | filter_out_ep | emojify | sed 's/ | /, /g' | format_into_song > editing_ranking.temp
fi

## gives an error if the file is filled with meaningless clutter
if [ $(grep ':WhiteCircle:.  -  |' < editing_ranking.temp| wc -l) -ne 0 ]; then
    echo "[error] invalid values provided. ${month_query}"
    exit 1
else
    $edit editing_ranking.temp
    {
        echo "$title"
        echo "$subtitle"
        afterformat < editing_ranking.temp | separatorify
        avgcalc < editing_ranking.temp
    } | backtodos > rankoutput.txt
fi

if [[ $has_copy == true ]]; then
    $clip_copy < rankoutput.txt
fi
if [[ $has_display == true ]]; then
    $display rankoutput.txt
fi

if [ -s errors.txt ]; then
    printf "[warning] The ranking has some errors, please double check them to make sure everything is properly done.\nplease run rkf --errors, or rkf --copyerrors"
fi
