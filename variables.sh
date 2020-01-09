#!/bin/bash

# GENERAL VARIABLES
time=$(date +%k)

  # Directory related variables
  dir_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  dir_remote="$dir_script/remote"
  dir_local="$dir_script/local"
  dir_downloads="$dir_local/downloads"
  dir_watch="$dir_local/watch"
  dir_encoded="$dir_local/encoded"
  dir_plex_googledrive="media_encrypt_cache:/plex"

  dir_plex_transcode="$dir_local/transcode"
  dir_plex_movies="$dir_remote/movies"
  dir_plex_series="$dir_remote/series"
  dir_plex_music="$dir_remote/music"
  dir_plex_other="$dir_remote/other"

  dir_config="$dir_script/config"
    dir_config_plex="$dir_config/plex"
    dir_config_radarr="$dir_config/radarr"
    dir_config_jackett="$dir_config/jackett"
    dir_config_sonarr="$dir_config/sonarr"
    dir_config_lidarr="$dir_config/lidarr"
    dir_config_duckdns="$dir_config/duckdns"
    dir_config_ombi="$dir_config/ombi"
    dir_config_transmission="$dir_config/transmission"
    dir_config_adguard="$dir_config/adguard"
    dir_adguard_data="$dir_config_adguard/data"
    dir_adguard_config="$dir_config_adguard/config"

  # Files related variables.
  file_config="$dir_script/.config.json"
  file_remote_write_service="/etc/systemd/system/remote-write.service"
  file_remote_read_service="/etc/systemd/system/remote-read.service"
  file_rcloneconfig="$dir_script/.rclone.conf"
  file_fuse="/etc/fuse.conf"
  file_transmission_movies="$dir_config_transmission/movies/settings.json"
  file_transmission_series="$dir_config_transmission/series/settings.json"
  file_transmission_music="$dir_config_transmission/music/settings.json"

  # Color preset variables
  color_reset='\033[0m'
  color_red='\033[1;31m'
  color_green='\033[1;32m'
  color_yellow='\033[1;33m'
  color_blue='\033[1;34m'
