#!/bin/bash
set_arch() { 
    echo "Select Architecture for v1.2.:" 
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
    sed -i "s/^Version:.*/Version: 1.2./" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch

# 1. التأكد من المتطلبات
pkg install readline -y

BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_DIR="$BASE_DIR/pkg"
TERMUX_PREFIX="/data/data/com.termux/files/usr"

echo "⚙️ جاري تحديث المحرك إلى مستوى Zsh Pro..."

# 2. تحديث المكتبة (دعم الـ Right Prompt والوقت)
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

void print_banner() {
    printf("\e[1;35m      ⚡ Electronic Shell (ESH) Pro ⚡\e[0m\n");
    printf("\e[1;30m------------------------------------------\e[0m\n");
}

char* get_custom_prompt() {
    static char prompt_buffer[512];
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

    char symbol = (getuid() == 0) ? '#' : '$';

    // [ [esh] [~/] user@localhost ]$ 
    sprintf(prompt_buffer, "\e[1;37m[ \e[1;32m[esh]\e[1;37m [ \e[1;34m%s\e[1;37m ] \e[1;33m%s@esh\e[1;37m ]%c \e[0m", 
            display_path, user, symbol);
            
    return prompt_buffer;
}

// دالة لمحاكاة الـ RPROMPT (الوقت في أقصى اليمين)
void print_rprompt() {
    time_t rawtime;
    struct tm *info;
    char buffer[80];
    time(&rawtime);
    info = localtime(&rawtime);
    strftime(buffer, 80, "%H:%M:%S", info);

    // استخدام ANSI لتحريك الكرسر لليمين ثم العودة
    // سنقوم بطباعته قبل سطر الإدخال
    printf("\033[s\033[1000C\033[8D\e[1;30m[%s]\033[u", buffer);
}
EOC

# 3. تحديث main.c (Readline + RPROMPT)
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
    
    // إعدادات Readline للإكمال التلقائي
    rl_bind_key('\t', rl_complete);

    while (status) {
        print_rprompt(); // طباعة الوقت جهة اليمين
        line = readline(get_custom_prompt());

        if (!line) break;

        if (strlen(line) > 0) {
            add_history(line);
            
            char *line_copy = strdup(line);
            args[0] = strtok(line_copy, " ");
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

# 4. بناء المكتبات والبرنامج
echo "📦 جاري الربط البرمجي (Linking)..."
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_DIR$TERMUX_PREFIX/lib/libesh.so
gcc main.c commands.c -L$PKG_DIR$TERMUX_PREFIX/lib -lesh -lreadline -o $PKG_DIR$TERMUX_PREFIX/bin/esh

# 5. بناء الحزمة v1.2.0
chmod 755 $PKG_DIR/DEBIAN
cd $BASE_DIR
dpkg-deb --build pkg esh_1.2._${ARCH}.deb

echo "✅ تم التحديث بنجاح يا Professional!"
echo "💡 الآن جرب: dpkg -i esh_1.2.0_aarch64.deb ثم شغل esh"
