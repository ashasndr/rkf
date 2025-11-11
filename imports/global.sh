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
has_display=$default_display_after
has_copy=$default_copy
has_separators=$default_separators
has_windows=$is_os_windows
has_recover=false
month_query=""
display=$display_util
edit=$edit_util
has_avgcalc=$default_append_average
has_tsv_source=false
