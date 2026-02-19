# محاكاة ميزة zsh-autosuggestions
alias suggest='history | tail -n 5'

# محاكاة zsh-syntax-highlighting (مبسطة)
# تلوين الأوامر التي تبدأ بـ 'sudo' أو 'rm' باللون الأحمر للتحذير
function check_syntax() {
    if [[ $1 == "rm"* ]]; then
        echo -e "\e[1;31m⚠️ Danger: $1\e[0m"
    fi
}
