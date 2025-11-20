#!/usr/bin/env bash
set -eEuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

source "$SCRIPT_DIR/imports/global.sh"

#############################
################## FUNCTIONS
changelogs() {
    cat <<EOF
    2.5 - Charcount option, code cleanup
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
Usage: $PROGRAM [options]

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

# detects which tools the user has
set_clipboard_cmds() {
    if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
        clip_copy="wl-copy"
        clip_paste="wl-paste"
    elif command -v xclip >/dev/null 2>&1; then
        clip_copy="xclip -selection clipboard"
        clip_paste="xclip -selection clipboard -o"
    else
        echo "[error] No wl-copy or xclip found." >&2
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

# get title from --ti
get_title() {
    echo "# Ranking ${scheme} ${1}"
}

# get month query for tsv (YYMM -> 20YY-MM)
get_month_query() {
    local input=$1
    local num_year="20${input:0:2}"
    local num_month="${input: -2}"
    echo "${num_year}-${num_month}-"
}

# display help command, i used to use the whole help page but that cluttered everything
disphelpcmd() {
    echo "[info] Try $PROGRAM --help, or checking the wiki on the github repo. (https://github.com/ashasndr/rkf/wiki/Config)"
    exit 1
}

# turns YYMM into "Monthname 20YY"
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

## removes line ends from windows pastes
lnend() {
    sed 's/\r//'
}

# goes back to dos type text
backtodos() {
    if [ $has_windows == true ]; then
        sed -i 's/$/\r/'
    else
        cat
    fi
}

# updates the tsv with the clipvoard content
update_db() {
    if [[ ! -d "$SCRIPT_DIR/tsv" ]]; then
        mkdir tsv
    fi

    if [[ -z "$scheme" ]]; then
        echo "[error] you must specify a scheme (-m/-n)" >&2
    else
        $clip_paste | grep -v "NEW: Want to join the editing team?" > "$SCRIPT_DIR/tsv/${scheme}.tsv"
        echo "[info] Updated ${scheme} record"
    fi
}

###################
#### PARSE FLAGS
parse_args() {
    # reset this in case we reuse this later
    OPTIND=1

    if [[ -z "$*" ]]; then
        disphelpcmd
    fi

    while getopts ":23dmenwhacktrs-:" opt; do
        case "$opt" in
            m) scheme="Monstercat" ;;
            n) scheme="NCS" ;;
            e) has_emojis=$(! $has_emojis && echo true || echo false) ;;
            2) lines=2 ;;
            3) lines=3 ;;
            c) has_copy=$(! $has_copy && echo true || echo false) ;;
            a) has_avgcalc=$(! $has_avgcalc && echo true || echo false) ;;
            d) has_display=$(! $has_display && echo true || echo false) ;;
            k) has_charcount=$(! $has_charcount && echo true || echo false) ;;
            w) has_windows=true ;;
            s) has_separators=$(! $has_separators && echo true || echo false) ;;
            r) has_recover=true ;;
            t) has_tsv_source=true ;;
            h) usage 0 ;;

            # long options after a double dash. optind used instead of shift to keep the ability to stack small args
            -)
                case "${OPTARG}" in
                    title|ti)
                        title="# Ranking ${scheme} ${!OPTIND}"
                        OPTIND=$((OPTIND + 1))
                        ;;
                    subtitle|sb)
                        subtitle="-# ${!OPTIND}"
                        OPTIND=$((OPTIND + 1))
                        ;;
                    fulltitle|full|ft)
                        title="# ${!OPTIND}"
                        OPTIND=$((OPTIND + 1))
                        ;;
                    expresstitle|et|yymm)
                        local arg="${!OPTIND}"
                        month_query=$(get_month_query "$arg")
                        title=$(unexpress_title "$arg")
                        OPTIND=$((OPTIND + 1))
                        ;;
                    errors|err)
                        $DISPLAY "$ERROR_FILE"
                        exit 0
                        ;;
                    copyerrors|cperr)
                        $clip_copy < "$ERROR_FILE"
                        exit 0
                        ;;
                    last)
                        $DISPLAY "$RANK_OUTPUT"
                        exit 0
                        ;;
                    copylast|cplast)
                        $clip_copy < "$RANK_OUTPUT"
                        exit 0
                        ;;
                    mcatalog|mcatsh)
                        echo "https://docs.google.com/spreadsheets/d/116LycNEkWChmHmDK2HM2WV85fO3p3YTYDATpAthL8_g/edit" | $clip_copy
                        echo "https://docs.google.com/spreadsheets/d/116LycNEkWChmHmDK2HM2WV85fO3p3YTYDATpAthL8_g/edit"
                        exit 0
                        ;;
                    ncsinfo|ncssh|ninf)
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
                    updatedb|dbupd|db)
                        update_db
                        exit 0
                        ;;
                    help)
                        usage 0
                        ;;
                    *)
                        echo "[error] Unknown flag: --${OPTARG}" >&2
                        disphelpcmd
                        ;;
                esac
                ;;
            \?)  # invalid short option
                echo "[error] Unknown flag: -$OPTARG" >&2
                disphelpcmd
                ;;
            :)   # missing argument for option that requires one
                echo "[error] Option -$OPTARG requires an argument." >&2
                disphelpcmd
                ;;
        esac
    done

    shift $((OPTIND - 1))
}



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

# emojify: adds an emoji according to the genre parsed from the spreadsheet/tsv/whatever
emojify() {
    if [ "$has_emojis" ] && [ "$lines" -ne 2 ]; then
        # build a string "regex;;;emoji<<<>>>regex;;;emoji<<<>>>"
        # wonky approach but i couldn't think of anything better
        # if it works it works, god bless
        local mapping_str=""
        for genre in "${!GENRE_EMOJIS[@]}"; do
            emoji="${GENRE_EMOJIS[$genre]}"
            mapping_str+="${genre};;;${emoji}<<<>>>"
        done
        mapping_str=$(echo "${mapping_str}" | sed 's/<<<>>>$//')

        awk -v FS='\t' -v OFS='\t' \
            -v fallback_emoji="$DEFAULT_EMOJI" \
            -v mappings="$mapping_str" '
        BEGIN {
            # chops up the mapping str inputted into pairs of regexes and emojis
            pair_count = split(mappings, pairs, "<<<>>>")
            for (i = 1; i <= pair_count; i++) {
                split(pairs[i], rgem, ";;;")
                regex[i] = rgem[1]
                emoji[i] = rgem[2]
            }
        }

        function genre_of(genre, i) {
            for (i = 1; i <= pair_count; i++) {
                if (genre ~ regex[i]) return emoji[i]
            }
            return fallback_emoji
        }

        {
            if (NF == 3)
                $1 = genre_of($1)
            print
        }'
    else
        cat
    fi
}


# format_into_song: convert TSV fields into "Artist(s) - Song |"
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

# turns the EDIT output into a proper list (something like "Y. **:emoji: Alice, Bob - MySong.mp3 | X/10 - interesting track.")
afterformat() {
    # remove all errors
    : > "$ERROR_FILE"

    shuf | nl -w1 -s$'\t' | \
    awk -F'\t|\\|' -v OFS='|' -v ERR="$ERROR_FILE" '
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

        valid_count++
        printf "%s\t%06d\t**%s** | %s/%s - %s\n", rating, idx, text, rating, scale, reasoning
    }
    END {
        if (valid_count == 0) {
            print "[error] No valid rankings. Make sure you edited your ranking properly in this format: Song | X/10 - Reasoning.\n[info] Use argument -r to recover the last file you were editing." > "/dev/stderr"
            exit 1
        }
    }
    ' \
    | sort -t $'\t' -k1,1nr -k2,2n \
    | cut -f3- \
    | nl -w1 -s'. '
}


# add separators -=-= :emoji: =-=-
separatorify() {
    if [[ "$has_separators" == true ]]; then
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

# calculate average of all scores
avgcalc() {
    if [[ $has_avgcalc == true ]]; then
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

# checks if you're on wsl, if you have wl-copy or xclip installed
detect_tools() {
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        has_windows=true
    fi

    if [[ ! -d "./ranks" ]]; then
        mkdir ranks
    fi

    set_clipboard_cmds
}

# cleans up everything after your passage (extra commands pretty much)
sweep_floor() {
    if [[ $has_charcount == true ]]; then
        if [[ $has_emojis == true ]]; then
            charcount=$(( $(wc -c < "$RANK_OUTPUT") + ( $(grep -E "^#" < "$RANK_OUTPUT" | wc -l) * 21 ) ))
            # 21 is the amount of characters that discord adds per emoji in raw text
        else
            charcount=$(( $(wc -c < "$RANK_OUTPUT") ))
        fi
        echo "[info] characters: $charcount"
    fi

    if [[ $has_copy == true ]]; then
        $clip_copy < "$RANK_OUTPUT"
    fi
    if [[ $has_display == true ]]; then
        $DISPLAY "$RANK_OUTPUT"
    fi

    if [[ -s "$ERROR_FILE" ]]; then
        printf "[warning] The ranking has some errors, please double check them to make sure everything is properly done.\nplease run $PROGRAM --errors, or $PROGRAM --copyerrors" >&2
    fi
}

# extra error checks
validates() {
    if [[ $has_tsv_source == true ]] && [[ -z "$month_query" ]]; then
        echo "[error] TSV import requested but no month has been selected with --expresstitle" >&2
        exit 1
    fi
}


run_pre_process() {
    if [ $has_recover == true ]; then
        return 1
    fi
    if [ $has_tsv_source == true ]; then

        date_in_line=$(head -n 3 "$SCRIPT_DIR/tsv/${scheme}.tsv" | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')

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
                    printf "\n[info] Closing. if you want to update the local file, the command to update is $PROGRAM -n|m --db. \
make sure you have the whole catalog spreadsheet in your clipboard before running the command"
                    exit 1
                    ;;
            esac
        fi

        grep "${month_query}" "$SCRIPT_DIR/tsv/${scheme}.tsv" > "$RANK_INPUT"
    else
        $clip_paste > "$RANK_INPUT"
    fi
    lnend < "$RANK_INPUT" | parse_wanted_cols | filter_out_ep \
    | emojify | sed 's/ | /, /g' | format_into_song > "$RANK_TEMP";
}

edit_process() {
    # gives an error if the file is filled with meaningless clutter
    if [ $(grep "${DEFAULT_EMOJI}.  -  |" < "$RANK_TEMP" | wc -l) -ne 0 ]; then
        echo "[error] invalid values provided. ${month_query}\n[info] Your clipboard contents might be something unrelated, or you are using the wrong scheme (-n/-m)" >&2
        exit 1
    else
        $EDIT "$RANK_TEMP"
        {
            echo "$title"
            echo "$subtitle"
            afterformat < "$RANK_TEMP" | separatorify
            avgcalc < "$RANK_TEMP"
        } | backtodos > "$RANK_OUTPUT"
    fi
}

main() {
    detect_tools
    parse_args "$@"
    init_values
    validates
    run_pre_process
    edit_process
    sweep_floor
}

main "$@"
