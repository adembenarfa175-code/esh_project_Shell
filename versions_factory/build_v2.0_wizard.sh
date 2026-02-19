#!/bin/bash
set_arch() { 
    echo "Select Architecture for v2.0:" 
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
    sed -i "s/^Version:.*/Version: 2.0/" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch

BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_DIR="$BASE_DIR/pkg"
TERMUX_PREFIX="/data/data/com.termux/files/usr"
CONFIG_FILE="$HOME/.esh_profile"

echo "⚙️ جاري برمجة معالج الإعدادات الأولية لـ ESH..."

# 1. تحديث المكتبة لدعم الإعدادات والأعلام (libesh.c)
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

// دالة لجلب العلم بناءً على رمز الدولة
char* get_flag(const char* country) {
    if (strcmp(country, "USA") == 0) return "🇺🇸";
    if (strcmp(country, "UK") == 0) return "🇬🇧";
    if (strcmp(country, "AS") == 0 || strcmp(country, "SA") == 0) return "🇸🇦";
    if (strcmp(country, "DZ") == 0) return "🇩🇿";
    return "🌐";
}

// معالج الإعدادات الأولية
void run_first_time_setup() {
    char config_path[512];
    sprintf(config_path, "%s/.esh_profile", getenv("HOME"));

    if (access(config_path, F_OK) != 0) {
        char name[100], country[10];
        printf("\n\e[1;33m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\e[0m\n");
        printf("\e[1;33m┃   Welcome to ESH First-Time Setup        ┃\e[0m\n");
        printf("\e[1;33m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\e[0m\n\n");
        
        printf("\e[1;32m[?]\e[0m Enter your professional name: ");
        scanf("%s", name);
        printf("\e[1;32m[?]\e[0m Enter Country Code (USA/UK/AS/DZ): ");
        scanf("%s", country);

        FILE *f = fopen(config_path, "w");
        if (f) {
            fprintf(f, "NAME=%s\nCOUNTRY=%s\n", name, country);
            fclose(f);
        }
        printf("\n\e[1;32m[✓] Profile saved! Restarting Shell...\e[0m\n\n");
        sleep(1);
    }
}

void print_banner() {
    printf("\e[1;36m      _____  _____ _   _ \e[0m\n");
    printf("\e[1;36m     |  ___|/  ___| | | |\e[0m   \e[1;33m⚡\e[0m\n");
    printf("\e[1;36m     | |__  \\ `--.| |_| |\e[0m   \e[1;32mELECTRONIC\e[0m\n");
    printf("\e[1;36m     |  __|  `--. \\  _  |\e[0m   \e[1;32mSHELL v2.0.0\e[0m\n");
    printf("\e[1;36m     | |___ /\\__/ / | | |\e[0m   \e[1;34mBy Professional\e[0m\n");
    printf("\e[1;30m--------------------------------------------------\e[0m\n");
}

char* get_custom_prompt() {
    static char prompt[1024];
    char cwd[256], name[100], country[10];
    char config_path[512];
    sprintf(config_path, "%s/.esh_profile", getenv("HOME"));

    // قراءة الإعدادات
    FILE *f = fopen(config_path, "r");
    if (f) {
        fscanf(f, "NAME=%s\nCOUNTRY=%s\n", name, country);
        fclose(f);
    } else {
        strcpy(name, "user");
        strcpy(country, "UN");
    }

    getcwd(cwd, sizeof(cwd));
    char *home = getenv("HOME");
    char display_path[256];
    if (home && strstr(cwd, home)) {
        sprintf(display_path, "~%s", cwd + strlen(home));
    } else {
        strcpy(display_path, cwd);
    }

    // الـ Prompt الجديد مع العلم والاسم المخصص
    sprintf(prompt, 
        "\e[1;30;44m %s %s \e[0;34;40m\e[1;37;40m %s \e[0;30;m ", 
        get_flag(country), name, display_path);
            
    return prompt;
}

void print_rprompt() {
    time_t rawtime; struct tm *info; char t[80];
    time(&rawtime); info = localtime(&rawtime);
    strftime(t, 80, "%H:%M:%S", info);
    printf("\033[s\033[1000C\033[12D \e[1;30m%s\033[u", t);
}
EOC

# 2. تحديث ملف التعريفات (libesh.h)
cat << 'EOC' > $SRC_DIR/lib/libesh.h
#ifndef LIBESH_H
#define LIBESH_H
void print_banner();
char* get_custom_prompt();
void print_rprompt();
void run_first_time_setup(); // إضافة الدالة الجديدة
#endif
EOC

# 3. تحديث البرنامج الرئيسي لاستدعاء المعالج (main.c)
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
    run_first_time_setup(); // اطلب الإعدادات إذا كانت أول مرة
    print_banner();
    
    rl_bind_key('\t', rl_complete);
    while (1) {
        print_rprompt();
        char *line = readline(get_custom_prompt());
        if (!line) break;
        if (strlen(line) > 0) {
            add_history(line);
            if (strcmp(line, "exit") == 0) { free(line); break; }
            system(line);
        }
        free(line);
    }
    return 0;
}
EOC

# 4. إعادة البناء
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_DIR$TERMUX_PREFIX/lib/libesh.so
gcc main.c commands.c -L$PKG_DIR$TERMUX_PREFIX/lib -lesh -lreadline -o $PKG_DIR$TERMUX_PREFIX/bin/esh

cd $BASE_DIR
dpkg-deb --build pkg esh_2.0_${ARCH}.deb
echo "✅ تم التحديث! احذف ملف .esh_profile إذا أردت تجربة المعالج مرة أخرى."
