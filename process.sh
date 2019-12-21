#!/bin/bash

dir_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  source $dir_script/variables.sh

torrent_dir="$TR_TORRENT_DIR"
torrent_name="$TR_TORRENT_NAME"
torrent_id="$TR_TORRENT_ID"
torrent_path="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

function encode {
# Function variables.
  CheckDownloadedMP4=$(find "$dir_downloads" -type f -regex ".*\.\(mp4\)" | wc -l)
  CheckDownloadedNotMP4=$(find "$dir_downloads" -type f -regex ".*\.\(mkv\|wmv\|flv\|webm\|mov\|avi\|m4v\)" | wc -l)
  IsMP4=$(find "$dir_downloads" -type f -size +1G -regex ".*\.\(mp4\)")
  NotMP4=$(find "$dir_downloads" -type f -size +1G -regex ".*\.\(mkv\|wmv\|flv\|webm\|mov\|avi\|m4v\)")

  if [ "$CheckDownloadedMP4" -ge 1 ] && ! pgrep -x "ffmpeg" > /dev/null;
  then
    for i in $IsMP4;
    do
      mv "$i" $dir_encoded
    done
  elif [ "$CheckDownloadedNotMP4" -ge 1 ] && ! pgrep -x "ffmpeg" > /dev/null;
  then
    for i in $NotMP4;
    do
      filename=$(basename "$i");
      extension="${filename##*.}";
      filename="${filename%.*}";
      echo -e "${color_yellow}Converting $i...${color_reset}"
      ffmpeg -i $i -codec copy $dir_encoded/"$filename".mp4
      echo -e "${color_green}Done converting $i.${color_reset}"
    done
  fi
}

# CONTROLER
RARFind=$(find "$torrent_path" -type f -regex ".*\.\(rar\)" | wc -l)
if [ "$RARFind" -ge 1 ];
then
  cd $torrent_path
  unrar e "*.rar"
  encode
  transmission-remote -t $torrent_id --remove-and-delete
else
  encode
  transmission-remote -t $torrent_id --remove-and-delete
fi
