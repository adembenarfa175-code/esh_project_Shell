#!/bin/bash
set_arch() { 
    echo "Select Architecture for v2.1.1.:" 
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
    sed -i "s/^Version:.*/Version: 2.1.1./" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch

BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_DIR="$BASE_DIR/pkg"
TERMUX_PREFIX="/data/data/com.termux/files/usr"

echo "🛠️  تحديث محرك البحث عن الأوامر في ESH..."

# تحديث ملف main.c لإضافة التحقق الذكي
cat << 'EOC' > $SRC_DIR/main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "lib/libesh.h"

extern int esh_cd(char **args);
extern int esh_exit(char **args);

int main() {
    run_first_time_setup();
    print_banner();
    
    rl_bind_key('\t', rl_complete);

    while (1) {
        print_rprompt();
        char *line = readline(get_custom_prompt());

        if (!line) break;

        if (strlen(line) > 0) {
            add_history(line);
            
            // تقسيم الأمر لأخذ الكلمة الأولى فقط للتحقق منها
            char *line_copy = strdup(line);
            char *cmd = strtok(line_copy, " ");

            if (cmd != NULL) {
                if (strcmp(cmd, "cd") == 0) {
                    // معالجة cd
                    char *args[64];
                    int i = 0;
                    args[0] = cmd;
                    while ((args[++i] = strtok(NULL, " ")) != NULL);
                    esh_cd(args);
                } else if (strcmp(cmd, "exit") == 0) {
                    free(line_copy); free(line);
                    break;
                } else {
                    // التحقق هل الأمر موجود في الـ PATH؟
                    char check_cmd[256];
                    sprintf(check_cmd, "command -v %s > /dev/null 2>&1", cmd);
                    
                    if (system(check_cmd) == 0) {
                        system(line); // تنفيذ الأمر إذا كان موجوداً
                    } else {
                        // الرسالة التي طلبتها يا Professional
                        printf("\e[1;31mESH: Command not found: %s\e[0m\n", cmd);
                    }
                }
            }
            free(line_copy);
        }
        free(line);
    }
    return 0;
}
EOC

# إعادة بناء المشروع
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_DIR$TERMUX_PREFIX/lib/libesh.so
gcc main.c commands.c -L$PKG_DIR$TERMUX_PREFIX/lib -lesh -lreadline -o $PKG_DIR$TERMUX_PREFIX/bin/esh

cd $BASE_DIR
dpkg-deb --build pkg esh_2.1.1._${ARCH}.deb

echo "✅ تم الإصلاح! الآن عند كتابة أمر خاطئ سيظهر لك: Command not found"
