#!/usr/bin/env bash
source ./config.conf

#############################
################## GLOBALS
scheme=$default_scheme
has_emojis=$default_emojis
title=""
subtitle=""
lines=0
cols=""
has_charcount=$default_charcount
has_display=$default_display_after
has_copy=$default_copy
has_separators=$default_separators
has_windows=$is_os_windows
has_recover=false
month_query=""
has_avgcalc=$default_append_average
has_tsv_source=false

################
##### CONSTS
RANK_TEMP="./ranks/editing_ranking.temp"
DISPLAY="$display_util"
EDIT="$edit_util"
RANK_INPUT="./ranks/${input_file}"
RANK_OUTPUT="./ranks/${output_file}"
ERROR_FILE="./ranks/${err_file}"
PROGRAM=$0

readonly PROGRAM
readonly DISPLAY
readonly EDIT
readonly RANK_INPUT
readonly RANK_OUTPUT
readonly RANK_TEMP
readonly ERROR_FILE
