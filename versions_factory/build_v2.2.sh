#!/bin/bash
set_arch() { 
    echo "Select Architecture for v2.2.:" 
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
    sed -i "s/^Version:.*/Version: 2.2./" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch

BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_DIR="$BASE_DIR/pkg"
TERMUX_PREFIX="/data/data/com.termux/files/usr"
ESHRC_FILE="$HOME/.eshrc"

echo "⚙️  جاري برمجة محرك الـ .eshrc لصدفة ESH..."

# 1. إنشاء ملف .eshrc افتراضي إذا لم يكن موجوداً
if [ ! -f "$ESHRC_FILE" ]; then
cat << 'EOC' > "$ESHRC_FILE"
# ESH Configuration File
# Professional's Aliases
alias cls='clear'
alias ll='ls -la'
alias update='pkg update && pkg upgrade'
alias eshconf='nano ~/.eshrc'
EOC
echo "✅ تم إنشاء ملف ~/.eshrc الافتراضي."
fi

# 2. تحديث المكتبة لدعم معالجة الاختصارات (libesh.c)
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

// مصفوفة لتخزين الاختصارات (بسيطة للتوضيح)
typedef struct {
    char alias[50];
    char command[256];
} Alias;

Alias user_aliases[100];
int alias_count = 0;

// دالة لقراءة ملف .eshrc
void load_eshrc() {
    char path[512];
    sprintf(path, "%s/.eshrc", getenv("HOME"));
    FILE *f = fopen(path, "r");
    if (!f) return;

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "alias ", 6) == 0) {
            char *name = strtok(line + 6, "=");
            char *cmd = strtok(NULL, "'");
            if (name && cmd) {
                strcpy(user_aliases[alias_count].alias, name);
                strcpy(user_aliases[alias_count].command, cmd);
                alias_count++;
            }
        }
    }
    fclose(f);
}

// التحقق هل المدخل هو اختصار؟
char* check_alias(char* cmd) {
    for (int i = 0; i < alias_count; i++) {
        if (strcmp(cmd, user_aliases[i].alias) == 0) {
            return user_aliases[i].command;
        }
    }
    return NULL;
}

char* get_flag(const char* country) {
    if (strcmp(country, "SA") == 0 || strcmp(country, "AS") == 0) return "🇸🇦";
    if (strcmp(country, "PS") == 0) return "🇵🇸";
    if (strcmp(country, "AE") == 0) return "🇦🇪";
    return "🌐";
}

void run_first_time_setup() {
    char config_path[512];
    sprintf(config_path, "%s/.esh_profile", getenv("HOME"));
    if (access(config_path, F_OK) != 0) {
        char name[100], country[10];
        printf("\e[1;36m[ Setup Wizard ]\e[0m\n");
        printf("Your Name: "); scanf("%s", name);
        printf("Country Code: "); scanf("%s", country);
        FILE *f = fopen(config_path, "w");
        if (f) { fprintf(f, "NAME=%s\nCOUNTRY=%s\n", name, country); fclose(f); }
    }
}

void print_banner() {
    printf("\e[1;36m      _____  _____ _   _ \n     |  ___|/  ___| | | |   ⚡\n     | |__  \\ `--.| |_| |   ELECTRONIC\n     |  __|  `--. \\  _  |   SHELL v2.2.0\n     | |___ /\\__/ / | | |   By Professional\e[0m\n");
    printf("\e[1;30m--------------------------------------------------\e[0m\n");
}

char* get_custom_prompt() {
    static char prompt[1024];
    char cwd[256], name[100], country[10], config_path[512];
    sprintf(config_path, "%s/.esh_profile", getenv("HOME"));
    FILE *f = fopen(config_path, "r");
    if (f) { fscanf(f, "NAME=%s\nCOUNTRY=%s\n", name, country); fclose(f); }
    else { strcpy(name, "user"); strcpy(country, "UN"); }
    getcwd(cwd, sizeof(cwd));
    char *home = getenv("HOME"), display_path[256];
    if (home && strstr(cwd, home)) sprintf(display_path, "~%s", cwd + strlen(home));
    else strcpy(display_path, cwd);

    sprintf(prompt, "\e[1;30;44m %s %s \e[0;34;40m\e[1;37;40m %s \e[0;30;m ", 
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

# 3. تحديث البرنامج الرئيسي ليدمج محرك الـ Aliases (main.c)
cat << 'EOC' > $SRC_DIR/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "lib/libesh.h"

extern int esh_cd(char **args);

int main() {
    run_first_time_setup();
    load_eshrc(); // تحميل الإعدادات عند بدء التشغيل
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
                    // إذا كان اختصاراً، استبدله ونفذ
                    char final_cmd[512];
                    sprintf(final_cmd, "%s %s", real_cmd, line + strlen(cmd));
                    system(final_cmd);
                } else if (strcmp(cmd, "exit") == 0) {
                    free(line_copy); free(line); break;
                } else if (strcmp(cmd, "cd") == 0) {
                    char *args[64]; int i=0; args[0]=cmd;
                    while((args[++i]=strtok(NULL, " ")) != NULL);
                    esh_cd(args);
                } else {
                    char check[256];
                    sprintf(check, "command -v %s > /dev/null 2>&1", cmd);
                    if (system(check) == 0) system(line);
                    else printf("\e[1;31mESH: Command not found: %s\e[0m\n", cmd);
                }
            }
            free(line_copy);
        }
        free(line);
    }
    return 0;
}
EOC

# إعادة البناء
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_DIR$TERMUX_PREFIX/lib/libesh.so
gcc main.c commands.c -L$PKG_DIR$TERMUX_PREFIX/lib -lesh -lreadline -o $PKG_DIR$TERMUX_PREFIX/bin/esh
cd $BASE_DIR
dpkg-deb --build pkg esh_2.2._${ARCH}.deb
echo "✅ ESH 2.2.0 جاهز مع دعم .eshrc والـ Aliases!"
