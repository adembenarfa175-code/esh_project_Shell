#!/bin/bash
set_arch() { 
    echo "Select Architecture for v2.3.:" 
    echo "1) aarch64 (Default)" 
    echo "2) amd64" 
    echo "3) x86_64" 
    read -p "Choice [1-3]: " arch_choice 
    case $arch_choice in 
        2) ARCH="amd64" ;; 
        3) ARCH="x86_64" ;; 
        *) ARCH="aarch64" ;; 
    esac 
    sed -i "s/^Architecture:.*/Architecture: $ARCH/" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
    sed -i "s/^Version:.*/Version: 2.3./" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch
BASE_DIR="$HOME/esh-project"

echo "🚀 البدء في التوسعة الشاملة لإطارات عمل ESH..."

# --- 1. تحديث النواة (main.c) لاستدعاء إطار العمل ---
cat << 'EOC' > $BASE_DIR/src/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "lib/libesh.h"

int main() {
    run_first_time_setup();
    load_eshrc();
    
    // تشغيل محرك oh-my-esh عند البدء
    system("bash $HOME/esh-project/oh-my-esh/oh-my-esh.sh");

    print_banner();
    
    while (1) {
        print_rprompt();
        char *line = readline(get_custom_prompt());
        if (!line) break;
        if (strlen(line) > 0) {
            add_history(line);
            char *line_copy = strdup(line);
            char *cmd = strtok(line_copy, " ");
            if (cmd) {
                char *real_cmd = check_alias(cmd);
                if (real_cmd) {
                    char final_cmd[512];
                    sprintf(final_cmd, "%s %s", real_cmd, line + strlen(cmd));
                    system(final_cmd);
                } else if (strcmp(cmd, "exit") == 0) {
                    free(line_copy); free(line); break;
                } else {
                    system(line);
                }
            }
            free(line_copy);
        }
        free(line);
    }
    return 0;
}
EOC

# --- 2. توسعة oh-my-esh (المحرك الرئيسي) ---
cat << 'EOC' > $BASE_DIR/oh-my-esh/oh-my-esh.sh
#!/bin/bash
# Oh My Esh - Core Engine
ESH_LIB="$HOME/esh-project/oh-my-esh/lib/core.sh"
ESH_THEMES="$HOME/esh-project/Esh-of-theme/themes"

# تحميل المكتبة الأساسية
[ -f "$ESH_LIB" ] && source "$ESH_LIB"

# تحميل الثيم المختار (pro-neon كمثال)
[ -f "$ESH_THEMES/pro-neon.esh" ] && source "$ESH_THEMES/pro-neon.esh"

echo -e "\e[1;32m[✔] Oh-My-Esh Framework Loaded!\e[0m"
EOC

# --- 3. توسعة Esh-of-theme (الثيمات الاحترافية) ---
cat << 'EOC' > $BASE_DIR/Esh-of-theme/themes/pro-neon.esh
# Pro-Neon Theme for ESH
export ESH_THEME_NAME="Pro-Neon"
export PROMPT_COLOR="\e[1;35m" # البنفسجي النيوني
# هنا يمكن إضافة تعديلات حية على شكل البرومبت مستقبلاً
EOC

# --- 4. توسعة Esh-framework-Lite (النظام الخفيف) ---
cat << 'EOC' > $BASE_DIR/Esh-framework-Lite/core/init.sh
# محرك خفيف للمهام السريعة
alias fast='echo "Running in Lite Mode"'
EOC

# --- 5. إعادة بناء المشروع بالكامل ---
echo "🔨 جاري إعادة بناء النواة والربط الشامل..."
cd $BASE_DIR/src
gcc -fPIC -shared lib/libesh.c -o $BASE_DIR/pkg/data/data/com.termux/files/usr/lib/libesh.so
gcc main.c commands.c -L$BASE_DIR/pkg/data/data/com.termux/files/usr/lib -lesh -lreadline -o $BASE_DIR/pkg/data/data/com.termux/files/usr/bin/esh

cd $BASE_DIR
dpkg-deb --build pkg esh_2.3._${ARCH}.deb

echo "✅ اكتملت التوسعة الشاملة! ESH 2.3.0 جاهز الآن."
