1. download font from github
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip

2. create local user directory to host font:
    mkdir ~/.local/share/fonts

3. move font to this directory

4. register your font (may require to run as **sudo**)
    fc-cache -vf ~/.local/share/fonts

5. check installation
    fc-list
