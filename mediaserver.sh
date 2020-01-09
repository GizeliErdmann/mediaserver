#!/bin/bash

dir_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  source $dir_script/variables.sh

function install_config {
# Function conditions.
  if [ ! -e "$file_config" ];
  then
    echo -e "${color_yellow}Creating config file...${color_reset}"
    echo '{ "branch": "", "rclone": "", "crontab": "", "mediamanager": "", "adguard": "", "heimdall": "" }' > $file_config
    # User input.
    while true; do
        read -p "$(echo -e "${color_blue}Enable Media Manager? (Yy/Nn): ${color_reset}")" yn
        case $yn in
            [Yy]* ) ask_mediamanager="enabled"; break;;
            [Nn]* ) ask_mediamanager="disabled"; break;;
            * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
        esac
    done
    while true; do
        read -p "$(echo -e "${color_blue}Enable Plex Server? (Yy/Nn): ${color_reset}")" yn
        case $yn in
            [Yy]* ) ask_plexserver="enabled"; break;;
            [Nn]* ) ask_plexserver="disabled"; break;;
            * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
        esac
    done
    while true; do
        read -p "$(echo -e "${color_blue}Enable MotionEye? (Yy/Nn): ${color_reset}")" yn
        case $yn in
            [Yy]* ) ask_motioneye="enabled"; break;;
            [Nn]* ) ask_motioneye="disabled"; break;;
            * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
        esac
    done
    while true; do
        read -p "$(echo -e "${color_blue}Enable AdGuard Home? (Yy/Nn): ${color_reset}")" yn
        case $yn in
            [Yy]* ) ask_adguard="enabled"; break;;
            [Nn]* ) ask_adguard="disabled"; break;;
            * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
        esac
    done
    while true; do
        read -p "$(echo -e "${color_blue}Enable Heimdall? (Yy/Nn): ${color_reset}")" yn
        case $yn in
            [Yy]* ) ask_heimdall="enabled"; break;;
            [Nn]* ) ask_heimdall="disabled"; break;;
            * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
        esac
    done
    # Reads user's input into the config file.
    jq '."branch" = ""' $file_config | sponge $file_config
    jq '."mediamanager" = "'$ask_mediamanager'"' $file_config | sponge $file_config
    jq '."plexserver" = "'$ask_plexserver'"' $file_config | sponge $file_config
    jq '."motioneye" = "'$ask_motioneye'"' $file_config | sponge $file_config
    jq '."adguard" = "'$ask_adguard'"' $file_config | sponge $file_config
    jq '."heimdall" = "'$ask_heimdall'"' $file_config | sponge $file_config
    jq '."rclone" = "install"' $file_config | sponge $file_config
    jq '."crontab" = "wipe"' $file_config | sponge $file_config

  elif [ -e "$file_config" ];
  then
    echo -e "${color_yellow}Removing existing config file...${color_reset}"
    rm $file_config
    install_config
  fi
  gitbranch=$(git branch)
  if [ "$gitbranch" == "* master" ];
  then
    jq '."branch" = "master"' $file_config | sponge $file_config
    git config credential.helper store 'cache --timeout=5400'
    git fetch --quiet origin master
    git reset --quiet --hard origin/master
  elif [ "$gitbranch" == "* beta" ];
  then
    jq '."branch" = "beta"' $file_config | sponge $file_config
    git config credential.helper store 'cache --timeout=5400'
    git fetch --quiet origin beta
    git reset --quiet --hard origin/beta
  fi
}

function install_directories {
# Function variables.
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  jsonstatus_adguard=($(jq -r ".adguard" $file_config))
  jsonstatus_heimdall=($(jq -r ".heimdall" $file_config))
# Function Conditions.
  # Creates samba share point root.
  if [ "$jsonstatus_mediamanager" == "enabled" ];
  then
    echo -e "${color_yellow}Creating local and remote directories...${color_reset}"
    mkdir "$dir_remote"
    mkdir "$dir_local"
    mkdir "$dir_downloads"
    mkdir "$dir_downloads/movies"
    mkdir "$dir_downloads/series"
    mkdir "$dir_downloads/music"
    mkdir "$dir_watch"
    mkdir "$dir_encoded"
    echo -e "${color_yellow}Creating configuration directory...${color_reset}"
    mkdir "$dir_config"
    mkdir "$dir_config_radarr"
    mkdir "$dir_config_jackett"
    mkdir "$dir_config_sonarr"
    mkdir "$dir_config_transmission"
    mkdir "$dir_config_transmission/movies"
    mkdir "$dir_config_transmission/series"
    mkdir "$dir_config_transmission/music"
  fi
  if [ "$jsonstatus_plexserver" == "enabled" ];
  then
    if [ ! -d "$dir_remote" ];
    then
      mkdir "$dir_remote"
    fi
    if [ ! -d "$dir_config" ];
    then
      mkdir "$dir_config"
    fi
    if [ ! -d "$dir_local" ];
    then
      mkdir "$dir_local"
    fi
    mkdir "$dir_config_plex"
    mkdir "$dir_config_duckdns"
    mkdir "$dir_plex_transcode"
  fi
  if [ "$jsonstatus_adguard" == "enabled" ];
  then
    if [ ! -d "$dir_config" ];
    then
      mkdir "$dir_config"
    fi
    if [ ! -d "$dir_config_adguard" ];
    then
      mkdir "$dir_config_adguard"
      mkdir "$dir_adguard_data"
      mkdir "$dir_adguard_config"
    fi
  fi
  if [ "$jsonstatus_heimdall" == "enabled" ];
  then
    if [ ! -d "$dir_config" ];
    then
      mkdir "$dir_config"
    fi
    if [ ! -d "$dir_config_heimdall" ];
    then
      mkdir "$dir_config_heimdall"
    fi
  fi
  chgrp -R 1000 "$dir_remote"
  chgrp -R 1000 "$dir_local"
  echo -e "${color_green}Done creating directories.${color_reset}"
}

function mount {
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  if [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "disable" ]] || [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "enabled" ]];
  then
    echo -e "${color_yellow}Mounting remote drive...${color_reset}"
    sudo systemctl stop remote-write
    sudo systemctl start remote-write
    echo -e "${color_green}Done mounting remote drive.${color_reset}"
  fi
  if [[ "$jsonstatus_plexserver" == "enabled" && "$jsonstatus_mediamanager" == "disabled" ]];
  then
    echo -e "${color_yellow}Mounting remote drive...${color_reset}"
    sudo systemctl stop remote-read
    sudo systemctl start remote-read
    echo -e "${color_yellow}Restarting Plex Media Server...${color_reset}"
    sudo docker restart plex
    echo -e "${color_green}Done restarting Plex Media Server.${color_reset}"
    echo -e "${color_green}Done mounting remote drive.${color_reset}"
  fi
}

function unmount {
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  if [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "disable" ]] || [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "enabled" ]];
  then
    echo -e "${color_yellow}Unounting remote drive...${color_reset}"
    sudo systemctl stop remote-write
    echo -e "${color_green}Done unmounting remote drive.${color_reset}"
  fi
  if [[ "$jsonstatus_plexserver" == "enabled" && "$jsonstatus_mediamanager" == "disabled" ]];
  then
    echo -e "${color_yellow}Unounting remote drive...${color_reset}"
    sudo systemctl stop remote-read
    echo -e "${color_green}Done unmounting remote drive.${color_reset}"
  fi
}

function install_dependencies {
# Function variables.
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  jsonstatus_motioneye=($(jq -r ".motioneye" $file_config))
  jsonstatus_rclone=($(jq -r ".rclone" $file_config))
  jsonstatus_adguard=($(jq -r ".adguard" $file_config))
  jsonstatus_heimdall=($(jq -r ".heimdall" $file_config))
  ask_mediamanager_rclonetoken=""
  ask_mediamanager_rclonedrive=""
  ask_mediamanager_rclonepass=""
  ask_mediamanager_plexip=""
  ask_mediamanager_plexlogin=""
  ask_mediamanager_plexpass=""
# Adds non-free repository for all sources.
  echo -e "${color_yellow}Adding non-free repository...${color_reset}"
  sudo apt-get -y -qq install software-properties-common && sudo apt-add-repository non-free > /dev/null
  sudo apt-get -y -qq update > /dev/null
  echo -e "${color_green}Done adding non-free repository...${color_reset}"
# Install dependencies for both Media Manager and Plex Server
  if [[ "$jsonstatus_mediamanager" == "enabled" || "$jsonstatus_plexserver" == "enabled" ]];
  then
    echo -e "${color_yellow}Installing main dependencies...${color_reset}"
    sudo apt-get -y -qq install zip unzip unrar unionfs-fuse > /dev/null
    echo -e "${color_green}Done installing main dependencies...${color_reset}"
    # Sets up fuse.
    echo -e "${color_yellow}Setting up fuse...${color_reset}"
    sudo tee $file_fuse <<-EOF
user_allow_other
EOF
    echo -e "${color_green}Done setting up fuse.${color_reset}"
    # Install primary dependencies.
    echo -e "${color_yellow}Installing Docker and Docker-compose...${color_reset}"
    cd $dir_script
    sudo apt-get -y -qq install apt-transport-https ca-certificates gnupg2 software-properties-common > /dev/null
    curl --silent -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get -y -qq update > /dev/null
    sudo apt-get -y -qq install docker-ce docker-ce-cli containerd.io > /dev/null
    sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    # Installs Rclone.
    if [ ! -f "/usr/bin/rclone" ];
    then
      echo -e "${color_yellow}Installing Rclone...${color_reset}"
      rclone_version=$(curl -s "https://github.com/rclone/rclone/releases/latest" | grep -o 'tag/[v.0-9]*' | awk -F/ '{print $2}')
      curl --silent -LO https://github.com/rclone/rclone/releases/download/"$rclone_version"/rclone-"$rclone_version"-linux-amd64.zip
      unzip -qq rclone*.zip
      sudo mv rclone*/rclone /usr/bin
      sudo mv rclone*/rclone.1 /usr/local/share/man/man1
      sudo mandb
      rm rclone*.zip
      rm -r rclone*
      echo -e "${color_green}Done installing Rclone...${color_reset}"
    fi
    if [ ! -f "$file_rcloneconfig" ];
    then
      echo -e "${color_yellow}Creating blank Rclone config file...${color_reset}"
      touch $file_rcloneconfig
      echo -e "${color_yellow}Setting up Rclone for your cloud service...${color_reset}"
      read -p "$(echo -e "${color_blue}Insert drive access token for your cloud drive: ${color_reset}")" ask_mediamanager_rclonetoken
      read -p "$(echo -e "${color_blue}Insert the team drive ID for your cloud drive: ${color_reset}")" ask_mediamanager_rclonedrive
      read -p "$(echo -e "${color_blue}Insert drive encryption password for your cloud drive: ${color_reset}")" ask_mediamanager_rclonepass
      echo "[media_source]" >> $file_rcloneconfig
      echo "type = drive" >> $file_rcloneconfig
      echo "scope = drive" >> $file_rcloneconfig
      echo "token = $ask_mediamanager_rclonetoken" >> $file_rcloneconfig
      echo "team_drive = $ask_mediamanager_rclonedrive" >> $file_rcloneconfig
      echo "[media_encrypt]" >> $file_rcloneconfig
      echo "type = crypt" >> $file_rcloneconfig
      echo "remote = media_source:" >> $file_rcloneconfig
      echo "filename_encryption = standard" >> $file_rcloneconfig
      echo "directory_name_encryption = true" >> $file_rcloneconfig
      echo "password = $ask_mediamanager_rclonepass" >> $file_rcloneconfig
      if [ "$jsonstatus_plexserver" == "enabled" ];
      then
        read -p "$(echo -e "${color_blue}Insert the Plex Server ip address and port (default is 127.0.0.1:32400): ${color_reset}")" ask_mediamanager_plexip
        read -p "$(echo -e "${color_blue}Insert the Plex Server login: ${color_reset}")" ask_mediamanager_plexlogin
        read -p "$(echo -e "${color_blue}Insert the Plex Server password: ${color_reset}")" ask_mediamanager_plexpass
        echo "[media_encrypt_cache]" >> $file_rcloneconfig
        echo "type = cache" >> $file_rcloneconfig
        echo "remote = $dir_plex_googledrive" >> $file_rcloneconfig
        echo "plex_url = $ask_mediamanager_plexip" >> $file_rcloneconfig
        echo "plex_username = $ask_mediamanager_plexlogin" >> $file_rcloneconfig
        echo "plex_password = $ask_mediamanager_plexpass" >> $file_rcloneconfig
        echo "chunk_size = 64M" >> $file_rcloneconfig
        echo "info_age = 5d" >> $file_rcloneconfig
        echo "chunk_total_size = 15G" >> $file_rcloneconfig
        jq '."rclone" = "installed"' $file_config | sponge $file_config
      fi
    fi
  fi
  echo -e "${color_green}Done installing dependencies.${color_reset}"
# Installs services and Media Manager dependencies.
  if [ "$jsonstatus_mediamanager" == "enabled" ];
  then
    echo -e "${color_yellow}Installing Media Manager specific dependencies...${color_reset}"
    sudo apt-get -y -qq install mediainfo ffmpeg transmission-cli > /dev/null
    echo -e "${color_green}Done installing Media Manager specific dependencies...${color_reset}"
    # Installs services for Media Manager.
    echo -e "${color_yellow}Installing Jackett...${color_reset}"
    sudo docker pull linuxserver/jackett:latest
    sudo docker create \
      --name=jackett \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 9117:9117 \
      -v $dir_config_jackett:/config \
      -v $dir_local:/local \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/jackett:latest
    echo -e "${color_green}Done installing Jackett.${color_reset}"
    echo -e "${color_yellow}Installing Radarr...${color_reset}"
    sudo docker pull linuxserver/radarr:latest
    sudo docker create \
      --name=radarr \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 7878:7878 \
      -v $dir_config_radarr:/config \
      -v $dir_local:/local \
      -v $dir_downloads/movies:/downloads \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/radarr:latest
    echo -e "${color_green}Done installing Radarr...${color_reset}"
    echo -e "${color_yellow}Installing Sonarr...${color_reset}"
    sudo docker pull linuxserver/sonarr:latest
    sudo docker create \
      --name=sonarr \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 8989:8989 \
      -v $dir_config_sonarr:/config \
      -v $dir_local:/local \
      -v $dir_downloads/series:/downloads \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/sonarr:latest
    echo -e "${color_green}Done installing Sonarr...${color_reset}"
    echo -e "${color_yellow}Installing Lidarr...${color_reset}"
    sudo docker pull linuxserver/lidarr:latest
    sudo docker create \
    -e VERSION=latest \
      --name=lidarr \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 8686:8686 \
      -v $dir_config_lidarr:/config \
      -v $dir_local:/local \
      -v $dir_downloads/music:/downloads \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/lidarr:latest
    echo -e "${color_green}Done installing Sonarr...${color_reset}"
    echo -e "${color_yellow}Installing Transmission for movies...${color_reset}"
    sudo docker pull linuxserver/transmission:latest
    sudo docker create \
      --name=transmission_movies \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 9091:9091 \
      -p 51413:51413 \
      -p 51413:51413/udp \
      -v $dir_config_transmission/movies:/config \
      -v $dir_script:/scripts \
      -v $dir_watch:/watch \
      -v $dir_local:/local \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/transmission:latest
    echo -e "${color_green}Done installing Transmission for movies...${color_reset}"
    echo -e "${color_yellow}Installing Transmission for series...${color_reset}"
    sudo docker pull linuxserver/transmission:latest
    sudo docker create \
      --name=transmission_series \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 9092:9092 \
      -p 51414:51414 \
      -p 51414:51414/udp \
      -v $dir_config_transmission/series:/config \
      -v $dir_script:/scripts \
      -v $dir_watch:/watch \
      -v $dir_local:/local \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/transmission:latest
    echo -e "${color_green}Done installing Transmission for series...${color_reset}"
    echo -e "${color_yellow}Installing Transmission for music...${color_reset}"
    sudo docker pull linuxserver/transmission:latest
    sudo docker create \
      --name=transmission_music \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -p 9093:9093 \
      -p 51415:51415 \
      -p 51415:51415/udp \
      -v $dir_config_transmission/music:/config \
      -v $dir_script:/scripts \
      -v $dir_watch:/watch \
      -v $dir_local:/local \
      -v $dir_remote:/remote \
      --restart unless-stopped \
      linuxserver/transmission:latest
    echo -e "${color_green}Done installing Transmission for music...${color_reset}"
    echo -e "${color_green}Done installing Media Manager services...${color_reset}"
    echo -e "${color_yellow}Setting up Media manager services...${color_reset}"
    sudo docker start transmission_movies
    sudo docker stop transmission_movies
    sudo docker start transmission_series
    sudo docker stop transmission_series
    sudo docker start transmission_music
    sudo docker stop transmission_music
    # Sets up transmission.
    jq '."script-torrent-done-enabled" = true' $file_transmission_movies | sponge $file_transmission_movies
    jq '."script-torrent-done-filename" = "/scripts/unrar.sh"' $file_transmission_movies | sponge $file_transmission_movies
    jq '."script-torrent-done-enabled" = true' $file_transmission_series | sponge $file_transmission_series
    jq '."script-torrent-done-filename" = "/scripts/unrar.sh"' $file_transmission_series | sponge $file_transmission_series
    jq '."script-torrent-done-enabled" = true' $file_transmission_music | sponge $file_transmission_music
    jq '."script-torrent-done-filename" = "/scripts/unrar.sh"' $file_transmission_music | sponge $file_transmission_music
    jq '."download-dir" = "/local/downloads/movies"' $file_transmission_movies | sponge $file_transmission_movies
    jq '."download-dir" = "/local/downloads/series"' $file_transmission_series | sponge $file_transmission_series
    jq '."download-dir" = "/local/downloads/music"' $file_transmission_music | sponge $file_transmission_music
    jq '."download-queue-size" = 1' $file_transmission_movies | sponge $file_transmission_movies
    jq '."download-queue-size" = 1' $file_transmission_series | sponge $file_transmission_series
    jq '."download-queue-size" = 5' $file_transmission_music | sponge $file_transmission_music
    jq '."incomplete-dir-enabled" = false' $file_transmission_movies | sponge $file_transmission_movies
    jq '."incomplete-dir-enabled" = false' $file_transmission_series | sponge $file_transmission_series
    jq '."incomplete-dir-enabled" = false' $file_transmission_music | sponge $file_transmission_music
    jq '."ratio-limit-enabled" = true' $file_transmission_movies | sponge $file_transmission_movies
    jq '."ratio-limit-enabled" = true' $file_transmission_series | sponge $file_transmission_series
    jq '."ratio-limit-enabled" = true' $file_transmission_music | sponge $file_transmission_music
    jq '."ratio-limit" = 0' $file_transmission_movies | sponge $file_transmission_movies
    jq '."ratio-limit" = 0' $file_transmission_series | sponge $file_transmission_series
    jq '."ratio-limit" = 0' $file_transmission_music | sponge $file_transmission_music
    jq '."rpc-port" = 9091' $file_transmission_movies | sponge $file_transmission_movies
    jq '."rpc-port" = 9092' $file_transmission_series | sponge $file_transmission_series
    jq '."rpc-port" = 9093' $file_transmission_music | sponge $file_transmission_music
    jq '."peer-port" = 51413' $file_transmission_movies | sponge $file_transmission_movies
    jq '."peer-port" = 51414' $file_transmission_series | sponge $file_transmission_series
    jq '."peer-port" = 51415' $file_transmission_music | sponge $file_transmission_music
    echo -e "${color_green}Done setting up Transmission.${color_reset}"
    echo -e "${color_yellow}Starting up Media manager services...${color_reset}"
    sudo docker start sonarr
    sudo docker start radarr
    sudo docker start lidarr
    sudo docker start jackett
    sudo docker restart transmission_movies
    sudo docker restart transmission_series
    sudo docker restart transmission_music
    echo -e "${color_green}Done starting up Media Manager services...${color_reset}"
  fi

  # Installs services for Plex Server.
  if [ "$jsonstatus_plexserver" == "enabled" ];
  then
    echo -e "${color_yellow}Installing Plex Media Server...${color_reset}"
    sudo docker pull linuxserver/plex:latest
    sudo docker create \
      --name=plex \
      --net=host \
      --restart unless-stopped \
      -e VERSION=latest \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -e PLEX_CLAIM="claim-br3Z_58i1xKNy_19C9o8" \
      -v $dir_config_plex:/config \
      -v $dir_plex_transcode:/transcode \
      -v $dir_remote:/remote \
      linuxserver/plex:latest
    echo -e "${color_green}Done installing Plex Media Server...${color_reset}"
    echo -e "${color_yellow}Installing DuckDNS...${color_reset}"
    sudo docker pull linuxserver/duckdns:latest
    sudo docker create \
      --name=duckdns \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Sao_Paulo \
      -e SUBDOMAINS=brlocal1 \
      -e TOKEN=23383238-2d63-4e1c-b5cb-81c38c0441ed \
      -v $dir_config_duckdns:/config \
      --restart unless-stopped \
      linuxserver/duckdns:latest
    echo -e "${color_green}Done installing DuckDNS...${color_reset}"
    echo -e "${color_yellow}Setting Plex Media Server...${color_reset}"
    sudo docker start plex
    echo -e "${color_yellow}Starting up Plex Server services...${color_reset}"
    sudo docker restart plex
    sudo docker start duckdns
    echo -e "${color_green}Done starting up Plex Server services...${color_reset}"
  fi
  # Installs services for MotionEye.
  if [ "$jsonstatus_motioneye" == "enabled" ];
  then
    echo -e "${color_yellow}Installing MotionEye...${color_reset}"
    sudo docker pull ccrisan/motioneye:master-amd64
    sudo docker run \
      --name="motioneye" \
      -p 8765:8765 \
      --hostname="motioneye" \
      -v /etc/localtime:/etc/localtime:ro \
      -v /etc/motioneye:/etc/motioneye \
      -v /var/lib/motioneye:/var/lib/motioneye \
      --restart unless-stopped \
      --detach=true \
      ccrisan/motioneye:master-amd64
    jq '."motioneye" = "installed"' $file_config | sponge $file_config
    sudo docker start motioneye
    echo -e "${color_green}Done installing MotionEye.${color_reset}"
  fi
  # Installs services for AdGuard Home.
  if [ "$jsonstatus_adguard" == "enabled" ];
  then
    echo -e "${color_yellow}Installing AdGuard Home...${color_reset}"
    sudo docker pull adguard/adguardhome
    sudo docker run --name adguardhome \
    -v /home/server/mediaserver/config/adguard/data:/opt/adguardhome/work \
    -v /home/server/mediaserver/config/adguard/config:/opt/adguardhome/conf \
    -p 53:53/tcp \
    -p 53:53/udp \
    -p 67:67/udp \
    -p 69:69/tcp \
    -p 69:69/udp \
    -p 81:81/tcp \
    -p 444:444/tcp \
    -p 853:853/tcp \
    -p 3000:3000/tcp \
    -d adguard/adguardhome
    jq '."adguard" = "installed"' $file_config | sponge $file_config
    sudo docker start adguardhome
    echo -e "${color_green}Done installing AdGuard Home.${color_reset}"
  fi
  if [ "$jsonstatus_heimdall" == "enabled" ];
  then
    echo -e "${color_yellow}Installing Heimdall...${color_reset}"
    sudo docker pull linuxserver/heimdall
    sudo docker create \
    --name=heimdall \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=America/Sao_Paulo \
    -p 80:80 \
    -p 443:443 \
    -v $dir_config_heimdall:/config \
    --restart unless-stopped \
    linuxserver/heimdall
    jq '."heimdall" = "installed"' $file_config | sponge $file_config
    sudo docker start heimdall
    echo -e "${color_green}Done installing AdGuard Home.${color_reset}"
  fi
}

function install_crontab {
# Function variables.
  jsonstatus_crontab=($(jq -r ".crontab" $file_config))
  jsonstatus_branch=($(jq -r ".branch" $file_config))
  cron_update="* * * * * /bin/bash $dir_script/mediamanager.sh --update"
  cron_betaupdate="* * * * * /bin/bash $dir_script/mediamanager.sh --betaupdate"
# Function conditions.
  # Removes all script's cron jobs.
  if [ "$jsonstatus_crontab" == "wipe" ];
  then
    echo -e "${color_yellow}Removing existing cronjobs...${color_reset}"
    crontab -r
    echo -e "${color_green}Done removing existing cronjobs...${color_reset}"
    jq '."crontab" = "install"' $file_config | sponge $file_config
  fi
  # Determines that crontab must be installed.
  jsonstatus_crontab=($(jq -r ".crontab" $file_config))
  # Adds auto update and mount cron jobs.
  if [[ "$jsonstatus_branch" == "master" && "$jsonstatus_crontab" == "install" ]];
  then
    echo -e "${color_yellow}Adding cron jobs...${color_reset}"
    ( crontab -l | grep -v -F "$cron_update" ; echo "$cron_update" ) | crontab -
    echo -e "${color_green}Done adding cron jobs.${color_reset}"
  elif [[ "$jsonstatus_branch" == "beta" && "$jsonstatus_crontab" == "install" ]];
  then
    echo -e "${color_yellow}Adding cron jobs...${color_reset}"
    ( crontab -l | grep -v -F "$cron_betaupdate" ; echo "$cron_betaupdate" ) | crontab -
    echo -e "${color_green}Done adding cron jobs.${color_reset}"
  fi
  jq '."crontab" = "installed"' $file_config | sponge $file_config
}

function install_services {
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  if [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "disable" ]] || [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "enabled" ]];
  then
    echo -e "${color_yellow}Creating remote-write service...${color_reset}"
    touch $dir_script/remote-write.service
    echo "[Unit]" >> $dir_script/remote-write.service
    echo "Description=Remote-Write" >> $dir_script/remote-write.service
    echo "Wants=network-online.target" >> $dir_script/remote-write.service
    echo "After=network-online.target" >> $dir_script/remote-write.service
    echo "" >> $dir_script/remote-write.service
    echo "[Service]" >> $dir_script/remote-write.service
    echo "Type=notify" >> $dir_script/remote-write.service
    echo "User=$USER" >> $dir_script/remote-write.service
    echo "Group=$USER" >> $dir_script/remote-write.service
    echo "ExecStart=/usr/bin/rclone mount --config $file_rcloneconfig --allow-other --uid 1000 --gid 1000 --fast-list --dir-cache-time 1000h $dir_plex_googledrive $dir_remote" >> $dir_script/remote-write.service
    echo "Restart=always" >> $dir_script/remote-write.service
    echo "RestartSec=10" >> $dir_script/remote-write.service
    echo "ExecStop=/bin/fusermount -u "/home/mediaserver/mediaserver/remote"" >> $dir_script/remote-write.service
    echo "" >> $dir_script/remote-write.service
    echo "[Install]" >> $dir_script/remote-write.service
    echo "WantedBy=multi-user.target" >> $dir_script/remote-write.service
    echo -e "${color_yellow}Installing remote-write service...${color_reset}"
    sudo mv $dir_script/remote-write.service $file_remote_write_service
    sudo systemctl daemon-reload
    sudo systemctl enable remote-write
    echo -e "${color_green}Done remote-write service.${color_reset}"
  fi
  if [[ "$jsonstatus_plexserver" == "enabled" && "$jsonstatus_mediamanager" == "disabled" ]];
  then
    echo -e "${color_yellow}Creating remote-read service...${color_reset}"
    touch $dir_script/remote-read.service
    echo "[Unit]" >> $dir_script/remote-read.service
    echo "Description=remote-read" >> $dir_script/remote-read.service
    echo "Wants=network-online.target" >> $dir_script/remote-read.service
    echo "After=network-online.target" >> $dir_script/remote-read.service
    echo "" >> $dir_script/remote-read.service
    echo "[Service]" >> $dir_script/remote-read.service
    echo "Type=notify" >> $dir_script/remote-read.service
    echo "User=$USER" >> $dir_script/remote-read.service
    echo "Group=$USER" >> $dir_script/remote-read.service
    echo "ExecStart=/usr/bin/rclone mount --config $file_rcloneconfig --allow-other --uid 1000 --gid 1000 --fast-list --read-only --dir-cache-time 1000h $dir_plex_googledrive $dir_remote" >> $dir_script/remote-read.service
    echo "Restart=always" >> $dir_script/remote-read.service
    echo "RestartSec=10" >> $dir_script/remote-read.service
    echo "ExecStop=/bin/fusermount -u "/home/mediaserver/mediaserver/remote"" >> $dir_script/remote-read.service
    echo "" >> $dir_script/remote-read.service
    echo "[Install]" >> $dir_script/remote-read.service
    echo "WantedBy=multi-user.target" >> $dir_script/remote-read.service
    echo -e "${color_yellow}Installing remote-read service...${color_reset}"
    sudo mv $dir_script/remote-read.service $file_remote_read_service
    sudo systemctl daemon-reload
    sudo systemctl enable remote-read
    echo -e "${color_green}Done remote-read service.${color_reset}"
  fi
}

function start_services {
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  jsonstatus_motioneye=($(jq -r ".motioneye" $file_config))
  jsonstatus_adguard=($(jq -r ".adguard" $file_config))
  jsonstatus_heimdall=($(jq -r ".heimdall" $file_config))
  if [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "disable" ]] || [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "enabled" ]];
  then
    sudo systemctl start remote-write
  fi
  if [[ "$jsonstatus_plexserver" == "enabled" && "$jsonstatus_mediamanager" == "disabled" ]];
  then
    sudo systemctl start remote-read
  fi
  if [ "$jsonstatus_motioneye" == "enabled" ];
  then
    sudo docker restart motioneye
  fi
  if [ "$jsonstatus_adguard" == "installed" ];
  then
    sudo docker restart adguardhome
  fi
  if [ "$jsonstatus_heimdall" == "installed" ];
  then
    sudo docker restart heimdall
  fi
  if [ "$jsonstatus_mediamanager" == "enabled" ];
  then
    sudo docker restart sonarr
    sudo docker restart radarr
    sudo docker restart lidarr
    sudo docker restart jackett
    sudo docker restart transmission_movies
    sudo docker restart transmission_series
    sudo docker restart transmission_music
  fi
  if [ "$jsonstatus_plexserver" == "enabled" ];
  then
    sudo docker restart plex
    sudo docker restart duckdns
  fi
  if [ "$jsonstatus_motioneye" == "enabled" ];
  then
    sudo docker restart motioneye
  fi
}

function stop_services {
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  jsonstatus_motioneye=($(jq -r ".motioneye" $file_config))
  jsonstatus_adguard=($(jq -r ".adguard" $file_config))
  jsonstatus_heimdall=($(jq -r ".heimdall" $file_config))
  if [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "disable" ]] || [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "enabled" ]];
  then
    sudo systemctl stop remote-write
  fi
  if [[ "$jsonstatus_plexserver" == "enabled" && "$jsonstatus_mediamanager" == "disabled" ]];
  then
    sudo systemctl stop remote-read
  fi
  if [ "$jsonstatus_motioneye" == "enabled" ];
  then
    sudo docker stop motioneye
  fi
  if [ "$jsonstatus_adguard" == "installed" ];
  then
    sudo docker stop adguardhome
  fi
  if [ "$jsonstatus_heimdall" == "installed" ];
  then
    sudo docker stop heimdall
  fi
  if [ "$jsonstatus_mediamanager" == "enabled" ];
  then
    sudo docker stop sonarr
    sudo docker stop radarr
    sudo docker stop lidarr
    sudo docker stop jackett
    sudo docker stop transmission_movies
    sudo docker stop transmission_series
    sudo docker stop transmission_music
  fi
  if [ "$jsonstatus_plexserver" == "enabled" ];
  then
    sudo docker stop plex
    sudo docker stop duckdns
  fi
  if [ "$jsonstatus_motioneye" == "enabled" ];
  then
    sudo docker stop motioneye
  fi
}

function update {
  cron_update="* * * * * /bin/bash $dir_script/mediamanager.sh --update"
  cron_betaupdate="* * * * * /bin/bash $dir_script/mediamanager.sh --betaupdate"
  jsonstatus_branch=($(jq -r ".branch" $file_config))
  if [ "$jsonstatus_branch" == "master" ];
  then
    git config credential.helper store 'cache --timeout=5400'
    remote=$(git ls-remote -h origin master | awk '{print $1}')
    local=$(git rev-parse HEAD)
    echo -e "Local: ${color_blue}$local${color_reset}"
    echo -e "Remote: ${color_blue}$remote${color_reset}"
    if [[ $local == $remote ]];
    then
      echo -e "${color_green}Commits match. Nothing to update.${color_reset}"
    else
      echo -e "${color_yellow}Commits don't match. Updating...${color_reset}"
      git fetch --quiet origin master
      git reset --quiet --hard origin/master
      chmod +x $dir_script/*.sh
      echo -e "${color_green}Update finished.${color_reset}"
    fi
  elif [ "$jsonstatus_branch" == "beta" ];
  then
    git config credential.helper store 'cache --timeout=5400'
    remote=$(git ls-remote -h origin beta | awk '{print $1}')
    local=$(git rev-parse HEAD)
    echo -e "Local: ${color_blue}$local${color_reset}"
    echo -e "Remote: ${color_blue}$remote${color_reset}"
    if [[ $local == $remote ]];
    then
      echo -e "${color_green}Commits match. Nothing to update.${color_reset}"
    else
      echo -e "${color_yellow}Commits don't match. Updating...${color_reset}"
      git fetch --quiet origin beta
      git reset --quiet --hard origin/beta
      chmod +x $dir_script/*.sh
      echo -e "${color_green}Update finished.${color_reset}"
    fi
  else
    echo -e "${color_red}Something went wrong while updating.${color_reset}"
  fi
}

function uninstall {
  jsonstatus_mediamanager=($(jq -r ".mediamanager" $file_config))
  jsonstatus_plexserver=($(jq -r ".plexserver" $file_config))
  jsonstatus_adguard=($(jq -r ".adguard" $file_config))
  jsonstatus_heimdall=($(jq -r ".heimdall" $file_config))
  echo -e "${color_yellow}Backing up config folder.${color_reset}"
  zip -qq -r "$HOME/config-backup.zip" $dir_config
  echo -e "${color_green}Done backing up config folder. It will be available in your home directory.${color_reset}"
  # Removes remote directory.
  if [ -d "$dir_remote" ];
  then
    echo -e "${color_yellow}Removing remote folder.${color_reset}"
    if [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "disable" ]] || [[ "$jsonstatus_mediamanager" == "enabled" && "$jsonstatus_plexserver" == "enabled" ]];
    then
      sudo systemctl disable remote-write
      sudo systemctl stop remote-write
      sudo rm $file_remote_write_service
    fi
    if [[ "$jsonstatus_plexserver" == "enabled" && "$jsonstatus_mediamanager" == "disabled" ]];
    then
      sudo systemctl disable remote-read
      sudo systemctl stop remote-read
      sudo rm $file_remote_read_service
    fi
    sudo rm -r $dir_remote
    echo -e "${color_green}Done removing remote folder.${color_reset}"
  fi
  # Stops docker containers.
  echo -e "${color_yellow}Stopping the following services:${color_reset}"
  if [ "$jsonstatus_plexserver" == "enabled" ];
  then
    sudo docker stop plex
    sudo docker stop duckdns
  fi
  if [ "$jsonstatus_adguard" == "installed" ];
  then
    sudo docker stop adguardhome
  fi
  if [ "$jsonstatus_heimdall" == "installed" ];
  then
    sudo docker stop heimdall
  fi
  if [ "$jsonstatus_mediamanager" == "enabled" ];
  then
    sudo docker stop sonarr
    sudo docker stop transmission_movies
    sudo docker stop transmission_series
    sudo docker stop transmission_music
    sudo docker stop radarr
    sudo docker stop jackett
  fi
  if [ "$jsonstatus_motioneye" == "enabled" ];
  then
    ssudo docker stop motioneye
  fi
  echo -e "${color_green}Done stopping services.${color_reset}"
  # Removes crontab.
  echo -e "${color_yellow}Removing crontab.${color_reset}"
  crontab -r
  echo -e "${color_green}Done removing crontab.${color_reset}"
  # Removes Rclone.
  while true; do
      read -p "$(echo -e "${color_blue}Uninstall Rclone? (Yy/Nn): ${color_reset}")" yn
      case $yn in
          [Yy]* )
          sudo rm /usr/bin/rclone
          sudo rm /usr/local/share/man/man1/rclone.1
          rm $file_rcloneconfig
          echo -e "${color_green}Rclone uninstalled.${color_reset}"; break
          ;;
          [Nn]* )
          echo -e "${color_green}Rclone will not be uninstalled.${color_reset}"; break
          ;;
          * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
      esac
  done
  while true; do
      read -p "$(echo -e "${color_blue}Uninstall Docker and it's containers? (Yy/Nn): ${color_reset}")" yn
      case $yn in
          [Yy]* )
          sudo apt-get -y -qq purge docker-ce > /dev/null
          sudo rm -rf /var/lib/docker
          sudo rm -r $dir_config
          sudo rm /usr/local/bin/docker-compose
          sudo apt-key del 0EBFCD88
          sudo add-apt-repository --remove "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
          echo -e "${color_green}Docker uninstalled.${color_reset}"; break
          ;;
          [Nn]* )
          echo -e "${color_green}Docker will not be uninstalled.${color_reset}"; break
          ;;
          * ) echo -e "${color_red}You need to answer yes or no.${color_reset}";;
      esac
  done
  # Removes other dependencies.
  echo -e "${color_green}Removing other dependencies and files...${color_reset}"
  sudo apt-get -y -qq remove ffmpeg zip unzip unrar mediainfo unionfs-fuse jq moreutils transmission-cli > /dev/null
  rm $file_config
  sudo apt-get -y -qq autoremove > /dev/null
  sudo apt-get -y -qq autoclean > /dev/null
  echo -e "${color_green}Done removing other dependencies and files.${color_reset}"
  # Removes script directory.
  if [[ $(sudo apt-key fingerprint 0EBFCD88 > /dev/null) = "" ]] && [ ! -f "/usr/bin/rclone" ];
  then
    cd
    sudo rm -rf $dir_script
    echo -e "${color_green}Done removing mediamanager's directory.${color_reset}"
    echo -e "${color_green}Type 'cd' to go back to your home directory.${color_reset}"
  else
    rm -r $dir_local
    echo -e "${color_green}mediamanager's directory will be preserved.${color_reset}"
  fi
}

# SCRIPT OPTIONS
# Instalation related option.
if [ "$1" == "--install" ];
then
  cd $dir_script
  install_config
  install_directories
  install_dependencies
  install_services
  start_services
  install_crontab
  mount
  exit
elif [ "$1" == "--reset" ];
then
  cd $dir_script
  rm $file_rcloneconfig
  rm $file_config
  install_config
  install_directories
  install_dependencies
  install_crontab
  mount
  exit
elif [ "$1" == "--uninstall" ];
then
  cd $dir_script
  uninstall
  exit
elif [ "$1" == "--update" ];
then
  cd $dir_script
  jq '."branch" = "master"' $file_config | sponge $file_config
  echo -e "${color_yellow}Checking for updates.${color_reset}"
  update
  exit
elif [ "$1" == "--betaupdate" ];
then
  cd $dir_script
  jq '."branch" = "beta"' $file_config | sponge $file_config
  echo -e "${color_yellow}Checking for updates from beta branch.${color_reset}"
  update
  exit
elif [ "$1" == "--mount" ];
then
  cd $dir_script
  mount
elif [ "$1" == "--unmount" ];
then
  unmount
elif [ "$1" == "--startall" ];
then
  cd $dir_script
  start_services
elif [ "$1" == "--stopall" ];
then
  cd $dir_script
  stop_services
elif [ "$1" == "--services" ];
then
  install_services
  start_services
else
  echo -e "${color_red} No command found.${color_reset}"
  exit
fi
