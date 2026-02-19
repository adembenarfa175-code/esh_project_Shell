#!/bin/bash
# Oh My Esh - Core Engine
ESH_LIB="$HOME/esh-project/oh-my-esh/lib/core.sh"
ESH_THEMES="$HOME/esh-project/Esh-of-theme/themes"

# تحميل المكتبة الأساسية
[ -f "$ESH_LIB" ] && source "$ESH_LIB"

# تحميل الثيم المختار (pro-neon كمثال)
[ -f "$ESH_THEMES/pro-neon.esh" ] && source "$ESH_THEMES/pro-neon.esh"

echo -e "\e[1;32m[✔] Oh-My-Esh Framework Loaded!\e[0m"
