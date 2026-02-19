#!/bin/bash
BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_USR="$BASE_DIR/pkg/data/data/com.termux/files/usr"

echo "💎 إطلاق النسخة المستقرة ESH v3.1.0..."

# 1. تحديث main.c لإضافة دعم Heredoc مع التنفيذ الفعلي
cat << 'EOC' > $SRC_DIR/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <unistd.h>
#include "lib/libesh.h"

void execute_with_heredoc(char *command, char *delimiter) {
    char *h_line;
    char temp_file[] = "/tmp/esh_heredocXXXXXX";
    int fd = mkstemp(temp_file);
    
    if (fd == -1) return;

    // جمع أسطر Heredoc وكتابتها في ملف مؤقت
    while ((h_line = readline("heredoc> ")) != NULL) {
        if (strcmp(h_line, delimiter) == 0) {
            free(h_line);
            break;
        }
        write(fd, h_line, strlen(h_line));
        write(fd, "\n", 1);
        free(h_line);
    }
    close(fd);

    // تنفيذ الأمر الفعلي باستخدام الملف المؤقت كإدخال
    char final_cmd[1024];
    sprintf(final_cmd, "%s < %s", command, temp_file);
    system(final_cmd);

    // تنظيف الملف المؤقت
    unlink(temp_file);
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
                char *cmd_part = strtok(strdup(line), "<<");
                char *delim = strstr(line, "<<") + 2;
                while(*delim == ' ') delim++;
                execute_with_heredoc(cmd_part, delim);
            } else if (strcmp(line, "exit") == 0) {
                break;
            } else {
                system(line);
            }
        }
        free(line);
    }
    return 0;
}
EOC

# 2. بناء المكتبة والبرنامج (64-bit)
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_USR/lib/libesh.so
gcc main.c commands.c -I$SRC_DIR -L$PKG_USR/lib -lesh -lreadline -o $PKG_USR/bin/esh

# 3. تحديث سجلات المصنع
sed -i 's/Version: .*/Version: 3.1.0/' $BASE_DIR/pkg/DEBIAN/control
cd $BASE_DIR
dpkg-deb --build pkg esh_3.1.0_aarch64.deb

echo "✅ ESH v3.1.0 جاهز الآن مع دعم Heredoc حقيقي!"
