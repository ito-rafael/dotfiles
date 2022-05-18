# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/rafael/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=()
plugins+=(git)
plugins+=(sudo)
plugins+=(web-search)
plugins+=(dirhistory)
plugins+=(history-substring-search)
plugins+=(colored-man-pages)
#plugins+=(vi-mode)
#plugins+=(zsh-vi-mode)

#=======================================
# plugins setup
#=======================================
# zsh-autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
#-----------------------------
# zsh-syntax-highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#-----------------------------
# Powerline
powerline-daemon -q
source /usr/share/powerline/bindings/zsh/powerline.zsh
#-----------------------------
# zsh-vi-mode
source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.zsh
#=======================================

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# history search functionality
#bindkey "^[[A" history-beginning-search-backward
#bindkey "^[[B" history-beginning-search-forward

#=======================================
# alias section
#=======================================
# general
alias v=vim             # Vim
alias p=python          # Python
alias -g g='| grep'     # grep
alias m=man             # man
alias h=history         # history
#-----------------------------
# open config files
alias vv='vim ~/.vimrc'
alias zz='vim ~/.zshrc'
alias ii='vim ~/.config/i3/_config'
alias xx='vim ~/.Xmodmap'
# remote PC
alias lvv='ssh lbic cat ~/.vimrc | vim -'
alias lzz='ssh lbic cat ~/.zshrc | vim -'
alias lii='ssh lbic cat ~/.config/i3/_config | vim -'
alias lxx='ssh lbic cat ~/.Xmodmap | vim -'
# reload config files
alias rz='source ~/.zshrc'
alias ri='~/.config/i3/i3bang.rb && i3-msg restart'
alias rx='xmodmap ~/.Xmodmap'
#-----------------------------
# clipboard
#-----------------------------
# copy stdout
alias c='xclip -selection clipboard'
# copy pwd
alias pwdc='pwd | xclip -selection clipboard'
#-----------------------------
# Firefox
alias firefox=firefox-developer-edition
#-----------------------------
# OpenVPN LBiC
alias vpn-lbic='sudo openvpn /etc/openvpn/client/ito_rafael-conf-file.conf'
#-----------------------------
# adb / scrcpy
#-----------------------------
# IP:port
alias s20_ip='adb devices -l | grep SM_G980F | awk "{print \$1}"'
alias gw4_ip='adb devices -l | grep SM_R880 | awk "{print \$1}"'
# adb devices
alias -g s20="-s $(s20_ip)"
alias -g gw4="-s $(gw4_ip)"
# scrcpy
alias s="scrcpy s20 --prefer-text"
alias sw="scrcpy gw4 --prefer-text"
#-----------------------------
# ForX - Coinbase's API
# currency
function usd() { forx -q "${1:-1}" USD BRL }    # US Dollar
function eur() { forx -q "${1:-1}" EUR BRL }    # Euro
function gbp() { forx -q "${1:-1}" GBP BRL }    # Pound
function jpy() { forx -q "${1:-1}" JPY BRL }    # Yen
function cad() { forx -q "${1:-1}" CAD BRL }    # Canadian Dollar
function aud() { forx -q "${1:-1}" AUD BRL }    # Australian Dollar
# crypto
function btc() { forx -q "${1:-1}" BTC BRL }    # Bitcoin
function eth() { forx -q "${1:-1}" ETH BRL }    # Ethereum
#function bnb() { forx -q "${1:-1}" BNB BRL }    # Binance
#function xch() { forx -q "${1:-1}" XCH BRL }    # Chia

#=======================================
# Environment variables
#=======================================
# force applications to use the default language for output
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#=======================================
# other config
#=======================================
# use keychain to launch ssh-agent and ssh-add
eval $(keychain --noask --eval --quiet id_rsa)
#-----------------------------
# history-substring-search
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
#-----------------------------
# fix: workaround for history-substring-search work with zsh-vi-mode
zvm_after_init_commands+=("bindkey '^[[A' up-line-or-search" "bindkey '^[[B' down-line-or-search")
