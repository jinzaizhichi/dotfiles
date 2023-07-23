#!/bin/bash


read -p "enter 'y' to continue,other,abort:" CONF

if [[ "$CONF" == "y"]]: then
  echo 'continue'
else
  echo 'abort'
  exit
fi


{{ if eq .chezmoi.osRelease.id "arch" -}}
#!/bin/bash
sudo pacman -S pass
git clone https://github.com/jinzaizhichi/.password-store.git

{{else if eq .chezmoi.osRelease.id "amzn" -}}
#!/bin/bash
sudo yum update
sudo yum install git base-devel
git clone https://github.com/jinzaizhichi/.password-store.git

{{end -}}
