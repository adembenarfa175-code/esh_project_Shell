#!/bin/bash
set_arch() { 
    echo "Select Architecture for v2.0.:" 
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
    sed -i "s/^Version:.*/Version: 2.0./" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch

BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_DIR="$BASE_DIR/pkg"
TERMUX_PREFIX="/data/data/com.termux/files/usr"

echo "⚡ جاري حقن جينات Powerlevel10k في المحرك ESH 2.0.0..."

# 1. تحديث المكتبة لدعم الشرائح الملونة (libesh.c)
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

// الشعار الذي صممه المحترف
void print_banner() {
    printf("\e[1;36m      _____  _____ _   _ \e[0m\n");
    printf("\e[1;36m     |  ___|/  ___| | | |\e[0m   \e[1;33m⚡\e[0m\n");
    printf("\e[1;36m     | |__  \\ `--.| |_| |\e[0m   \e[1;32mELECTRONIC\e[0m\n");
    printf("\e[1;36m     |  __|  `--. \\  _  |\e[0m   \e[1;32mSHELL v2.0.0\e[0m\n");
    printf("\e[1;36m     | |___ /\\__/ / | | |\e[0m   \e[1;30mGPLv3 Licensed\e[0m\n");
    printf("\e[1;36m     \\____/ \\____/\\_| |_/\e[0m   \e[1;34mBy Professional\e[0m\n");
    printf("\n\e[1;37m[ \e[1;33mℹ\e[1;37m ] Electron speed active in your terminal...\e[0m\n");
    printf("\e[1;30m--------------------------------------------------\e[0m\n");
}

// دالة لجلب حالة البطارية (خاص بترمكس/أندرويد)
int get_battery() {
    FILE *fp = fopen("/sys/class/power_supply/battery/capacity", "r");
    int cap = 0;
    if (fp) {
        fscanf(fp, "%d", &cap);
        fclose(fp);
    }
    return cap;
}

char* get_custom_prompt() {
    static char prompt[1024];
    char cwd[256];
    char *user = getenv("USER");
    if (!user) user = "user";
    
    getcwd(cwd, sizeof(cwd));
    char *home = getenv("HOME");
    char display_path[256];
    if (home && strstr(cwd, home)) {
        sprintf(display_path, "~%s", cwd + strlen(home));
    } else {
        strcpy(display_path, cwd);
    }

    // بناء Prompt بنمط الشرائح (Powerlevel Style)
    // شريحة المستخدم (خلفية زرقاء) | شريحة المسار (خلفية سوداء فاتحة)
    sprintf(prompt, 
        "\e[1;30;44m %s \e[0;34;40m\e[1;37;40m %s \e[0;30;m ", 
        user, display_path);
            
    return prompt;
}

void print_rprompt() {
    time_t rawtime;
    struct tm *info;
    char time_str[80];
    time(&rawtime);
    info = localtime(&rawtime);
    strftime(time_str, 80, "%H:%M:%S", info);

    int bat = get_battery();
    char *bat_color = (bat < 20) ? "\e[1;31m" : "\e[1;32m";

    // طباعة الوقت والبطارية في أقصى اليمين مع أيقونات
    printf("\033[s\033[1000C\033[20D \e[1;30m%s \e[0m| %s%d%% 🔋 \033[u", time_str, bat_color, bat);
}
EOC

# 2. تحديث البرنامج الرئيسي ليكون أكثر سلاسة (main.c)
cat << 'EOC' > $SRC_DIR/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "lib/libesh.h"

extern int esh_cd(char **args);
extern int esh_exit(char **args);

int main() {
    char *line;
    char *args[64];
    int status = 1;

    print_banner();
    
    rl_bind_key('\t', rl_complete);

    while (status) {
        print_rprompt();
        line = readline(get_custom_prompt());

        if (!line) break;

        if (strlen(line) > 0) {
            add_history(line);
            
            char *line_copy = strdup(line);
            args[0] = strtok(line_copy, " ");
            if (args[0] == NULL) { free(line_copy); free(line); continue; }

            int i = 0;
            while (args[i] != NULL) {
                args[++i] = strtok(NULL, " ");
            }

            if (strcmp(args[0], "cd") == 0) {
                status = esh_cd(args);
            } else if (strcmp(args[0], "exit") == 0) {
                status = esh_exit(args);
            } else {
                system(line);
            }
            free(line_copy);
        }
        free(line);
    }
    return 0;
}
EOC

# 3. إعادة بناء الحزمة بالإصدار الجديد 2.0.0
echo "🔨 جاري البناء والتربيط..."
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_DIR$TERMUX_PREFIX/lib/libesh.so
gcc main.c commands.c -L$PKG_DIR$TERMUX_PREFIX/lib -lesh -lreadline -o $PKG_DIR$TERMUX_PREFIX/bin/esh

# تحديث ملف التحكم للحزمة
sed -i 's/Version: .*/Version: 2.0.0/' $PKG_DIR/DEBIAN/control

cd $BASE_DIR
dpkg-deb --build pkg esh_2.0._${ARCH}.deb

echo "✅ تم ترقية ESH إلى 2.0.0 بنجاح!"
echo "📦 ثبت الحزمة الآن: dpkg -i esh_2.0.0_aarch64.deb"
