#!/bin/bash

dir_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  source $dir_script/variables.sh

torrent_dir="$TR_TORRENT_DIR"
torrent_name="$TR_TORRENT_NAME"
torrent_id="$TR_TORRENT_ID"
torrent_path="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

# CONTROLER
RARFind=$(find "$torrent_path" -type f -regex ".*\.\(rar\)" | wc -l)
if [ "$RARFind" -ge 1 ];
then
  cd $torrent_path
  unrar e "*.rar"
else
  echo -e "${color_green}No RAR files found.${color_reset}"
fi
