FROM debian:latest

# install prerequisites required for external repos and Distrobox
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    apt-transport-https \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# download Brave Beta repo key and add the Beta sources list
RUN curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/brave-browser-beta-archive-keyring.gpg] https://brave-browser-apt-beta.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-beta.list

# install Brave Origin Beta
RUN apt-get update && apt-get install -y \
    brave-origin-beta \
    && rm -rf /var/lib/apt/lists/*

# create the managed policies directory & copy the dotfile
RUN mkdir -p /etc/brave/policies/managed
COPY extension_install_policy.json /etc/brave/policies/managed/
