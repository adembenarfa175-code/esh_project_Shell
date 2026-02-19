#!/bin/bash
set_arch() { 
    echo "Select Architecture for v3.0.:" 
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
    sed -i "s/^Version:.*/Version: 3.0./" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch
BASE_DIR="$HOME/esh-project"
PKG_USR="$BASE_DIR/pkg/data/data/com.termux/files/usr"

echo "⚡ التحضير لإطلاق الجيل الثالث ESH v3.0.0..."

# 1. تحديث المكتبة الأساسية لدعم التدوين (Logging) والمسارات (libesh.c)
cat << 'EOC' > $BASE_DIR/src/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

// محرك التدوين (Logging Engine)
void log_command(const char* cmd) {
    FILE *log_file = fopen("/data/data/com.termux/files/usr/var/log/esh/session.log", "a");
    if (log_file) {
        time_t now; time(&now);
        char *date = ctime(&now);
        date[strlen(date) - 1] = '\0'; // إزالة سطر جديد
        fprintf(log_file, "[%s] EXEC: %s\n", date, cmd);
        fclose(log_file);
    }
}

void print_banner() {
    printf("\e[1;36m      _____  _____ _   _ \n     |  ___|/  ___| | | |   ⚡\n     | |__  \\ `--.| |_| |   ELECTRONIC\n     |  __|  `--. \\  _  |   SHELL v3.0.0\n     | |___ /\\__/ / | | |   By Professional\e[0m\n");
    printf("\e[1;30m--------------------------------------------------\e[0m\n");
    printf("\e[1;32m[SYSTEM] Core, Oh-My-Esh, and Themes Linked.\e[0m\n\n");
}

char* get_custom_prompt() {
    static char prompt[1024];
    char name[100], country[10];
    FILE *f = fopen("/data/data/com.termux/files/home/.esh_profile", "r");
    if (f) { fscanf(f, "NAME=%s\nCOUNTRY=%s\n", name, country); fclose(f); }
    else { strcpy(name, "pro"); strcpy(country, "AS"); }

    char cwd[256]; getcwd(cwd, sizeof(cwd));
    sprintf(prompt, "\e[1;30;44m %s %s \e[0;34;40m\e[1;37;40m %s \e[0;30;m ", 
            (strcmp(country,"AS")==0?"🇸🇦":"🌐"), name, cwd);
    return prompt;
}

void print_rprompt() {
    time_t t; time(&t); struct tm *tm = localtime(&t);
    printf("\033[s\033[1000C\033[10D\e[1;30m%02d:%02d:%02d\033[u", tm->tm_hour, tm->tm_min, tm->tm_sec);
}

void load_eshrc() { /* يتم استدعاء ملف .eshrc من هنا */ }
void run_first_time_setup() { /* معالج الإعداد */ }
EOC

# 2. تحديث البرنامج الرئيسي (main.c) ليكون المحرك المركزي
cat << 'EOC' > $BASE_DIR/src/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "lib/libesh.h"

int main() {
    // 1. تشغيل إطار العمل Oh-My-Esh (Shell Side)
    system("bash /data/data/com.termux/files/home/esh-project/oh-my-esh/oh-my-esh.sh");
    
    print_banner();
    
    while (1) {
        print_rprompt();
        char *line = readline(get_custom_prompt());
        if (!line) break;
        if (strlen(line) > 0) {
            add_history(line);
            log_command(line); // تدوين الأمر في السجل
            
            if (strcmp(line, "exit") == 0) break;
            system(line);
        }
        free(line);
    }
    return 0;
}
EOC

# 3. بناء النسخة 3.0.0 وتوزيعها في الهيكلية الجديدة
cd $BASE_DIR/src
gcc -fPIC -shared lib/libesh.c -o $PKG_USR/lib/libesh.so
gcc main.c commands.c -I$PKG_USR/include/esh -L$PKG_USR/lib -lesh -lreadline -o $PKG_USR/bin/esh

# تحديث ملف التحكم
sed -i 's/Version: .*/Version: 3.0.0/' $BASE_DIR/pkg/DEBIAN/control

cd $BASE_DIR
dpkg-deb --build pkg esh_3.0._${ARCH}.deb

echo "🔥 تم إطلاق العاصفة! ESH v3.0.0 جاهز للتثبيت."
