
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/stephanienhile/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/stephanienhile/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/stephanienhile/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/stephanienhile/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/usr/local/opt/node@14/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Created by `pipx` on 2024-05-21 01:31:07
export PATH="$PATH:/Users/stephanienhile/.local/bin"
export FLUTTERPATH=/Users/stephanienhile/git/Hack/savo-ai/flutter
export PATH="$PATH:$FLUTTERPATH/bin"
