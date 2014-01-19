# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Set computer name
# name="sononest"
# scutil --set ComputerName $name
# scutil --set HostName $name
# scutil --set LocalHostName $name

# Install homebrew with cask
[[ `brew --version` > 0.9.4 ]] || ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
[[ `git --version | cut -d' ' -f3` > 1.8.3 ]] || brew install git --with-pcre
brew tap homebrew/dupes

# Install applications
function install_applications {
    local languages='ruby'
    local clis='mongodb node'
    local npm_clis='coffee-script'
    local rubygems='foreman'

    for language in $languages; do echo brew install $language; done
    for cli in $clis; do echo brew install $cli; done
    for npm_cli in $npm_clis; do echo npm install -g $npm_cli; done
    for rubygem in $rubygems; do echo gem install $rubygem; done
}

install_applications