#!/bin/bash
BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_USR="$BASE_DIR/pkg/data/data/com.termux/files/usr"

echo "⚡ تحويل ESH إلى مستوى احترافية Zsh..."

# تحديث libesh.c لإضافة برومبت "المحترفين"
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include "libesh.h"

char* get_custom_prompt() {
    static char prompt[1024];
    char cwd[256];
    getcwd(cwd, sizeof(cwd));
    
    // محاكاة ستايل Zsh الخاص بك: ✔  الوقت  المسار 
    sprintf(prompt, "\e[1;32m ✔ \e[0;32;40m\e[1;37;40m %s \e[0;30;m ", cwd);
    return prompt;
}

void print_banner() {
    struct utsname sys_info;
    uname(&sys_info);
    printf("\e[1;36mESH Framework \e[1;33mv3.0.0\e[0m\n");
    printf("\e[1;37mOS: %s | Arch: %s\e[0m\n", sys_info.sysname, sys_info.machine);
    printf("\e[1;30m--------------------------------------------------\e[0m\n");
}

void log_command(const char* cmd) {
    // محرك تدوين سريع جداً
    FILE *f = fopen("/data/data/com.termux/files/usr/var/log/esh/session.log", "a");
    if(f) { fprintf(f, "%s\n", cmd); fclose(f); }
}
EOC

# إعادة بناء فورية لجميع معماريات 64-bit
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_USR/lib/libesh.so
gcc main.c commands.c -I$SRC_DIR -L$PKG_USR/lib -lesh -lreadline -o $PKG_USR/bin/esh

echo "✅ تم الحقن البرمجي! ESH الآن يمتلك روح Zsh وسرعة C."
