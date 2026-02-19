#!/bin/bash
BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_USR="$BASE_DIR/pkg/data/data/com.termux/files/usr"

echo "⚙️ إصلاح خطأ الربط وحقن محرك Heredoc..."

# 1. تحديث libesh.c لإضافة الدالة المفقودة
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

char* get_custom_prompt() {
    static char prompt[1024];
    char cwd[256]; getcwd(cwd, sizeof(cwd));
    sprintf(prompt, "\e[1;32m ✔ \e[0;32;40m\e[1;37;40m %s \e[0;30;m ", cwd);
    return prompt;
}

void print_rprompt() {
    time_t t; struct tm *tm;
    time(&t); tm = localtime(&t);
    printf("\033[s\033[1000C\033[10D\e[1;30m%02d:%02d:%02d\033[u", tm->tm_hour, tm->tm_min, tm->tm_sec);
}

void print_banner() {
    printf("\e[1;36mESH Pro (Zsh-Style) v3.0.1\e[0m\n");
    printf("\e[1;30m--------------------------------------------------\e[0m\n");
}
EOC

# 2. تحديث main.c لدعم Heredoc
cat << 'EOC' > $SRC_DIR/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "lib/libesh.h"

void handle_heredoc(char *delimiter) {
    char *h_line;
    char buffer[4096] = "";
    printf("heredoc> ");
    while ((h_line = readline("> ")) != NULL) {
        if (strcmp(h_line, delimiter) == 0) {
            free(h_line);
            break;
        }
        strcat(buffer, h_line);
        strcat(buffer, "\n");
        free(h_line);
    }
    printf("\e[1;33m[Heredoc Captured]:\e[0m\n%s", buffer);
}

int main() {
    print_banner();
    while (1) {
        print_rprompt();
        char *line = readline(get_custom_prompt());
        if (!line) break;
        if (strlen(line) > 0) {
            add_history(line);
            
            if (strstr(line, "<<")) {
                char *delim = strstr(line, "<<") + 2;
                while(*delim == ' ') delim++; // تخطي المسافات
                handle_heredoc(delim);
            } else if (strcmp(line, "exit") == 0) {
                free(line); break;
            } else {
                system(line);
            }
        }
        free(line);
    }
    return 0;
}
EOC

# 3. بناء النسخة المصححة
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_USR/lib/libesh.so
gcc main.c commands.c -I$SRC_DIR -L$PKG_USR/lib -lesh -lreadline -o $PKG_USR/bin/esh

echo "✅ تم الإصلاح وإضافة Heredoc! جرب كتابة: cat << EOF"
