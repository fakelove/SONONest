#!/usr/bin/env bash

### Sononest Bootstrap

# This script will install the necessary dependencies, code and init scripts to run a the sononest server
# It should only be run on a clean raspbian image for the raspberry pi
# TODO: add mongodb install

### Configuration
# Set the hostname and static ip here
# Setup logfile
name='sononest'

# Quit on error
set -e

# Our banner
echo
echo "Ｓｏｎｏｎｅｓｔ  Ｂｏｏｔｓｔｒａｐ"
echo

# Display colorized error output
function _error() {
    COLOR='\033[00;31m' # red
    RESET='\033[00;00m' # white
    echo -e "${COLOR}[SonoNest ERROR] ${@}${RESET}"
    exit 1
}

# Display colorized warning output
function _info() {
    COLOR='\033[00;32m' # green
    RESET='\033[00;00m' # white
    echo -e "${COLOR}[SonoNest INFO] ${@}${RESET}"
}

### Permissions
# We ask for the administrator password upfront, and update a timestamp until
# the script is finished

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

### Install software dependencies
_info "Installing software dependencies"
_info "Updating software list"
sudo aptitude update
_info "Upgrading system software"
sudo aptitude upgrade -y
#_info "Installing package dependencies"
if [[ ! -f `which npm` ]]; then
    version="0.10.20"
    _info "Installing node.js ${version}"
    pushd /usr/local
    sudo wget http://nodejs.org/dist/v${version}/node-v${version}-linux-arm-pi.tar.gz
    sudo tar xzf node-v${version}-linux-arm-pi.tar.gz --strip=1
    popd
fi
_info "Installing libraries"
npm install

### Init scripts
# Generate the install initscripts using foreman

_info "Installing initscript"
initscript=`dirname $PWD`/sononest
sudo cp $initscript /etc/init.d/ || _error "failed to copy initscript"
_info "Enabling initscript"
sudo update-rc.d sononest defaults || _error "failed to enable initscript"

### Network config
_info "Setting hostname to ${name}"
oldname=`hostname`

[[ `hostname` -ne ${name} ]] || sudo hostname ${name}
[[ -e /etc/hostname ]] || sudo touch /etc/hostname
grep -q ${name} /etc/hostname || sudo sed -ie "1s/.*/${name}/" /etc/hostname
grep -q ${name} /etc/hosts || sudo sed -ie "s/${oldname}/${name}/" /etc/hosts

_info "done!"