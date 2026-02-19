#!/bin/bash
BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_USR="$BASE_DIR/pkg/data/data/com.termux/files/usr"

echo "🌈 جاري دمج lolcat مع شعار ESH الاحترافي..."

# 1. التأكد من وجود lolcat في النظام
if ! command -v lolcat &> /dev/null; then
    echo "📦 أداة lolcat غير موجودة، جاري تثبيتها..."
    pkg install ruby -y && gem install lolcat
fi

# 2. تحديث libesh.c لاستدعاء lolcat برمجياً
cat << 'EOC' > $SRC_DIR/lib/libesh.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libesh.h"

void print_banner() {
    // تخزين الشعار في متغير نصي كبير
    char banner[] = 
        "      _____  _____ _   _ \n"
        "     |  ___|/  ___| | | |   ⚡\n"
        "     | |__  \\ `--.| |_| |   ELECTRONIC\n"
        "     |  __|  `--. \\  _  |   SHELL v3.1.0\n"
        "     | |___ /\\__/ / | | |   By Professional\n"
        "--------------------------------------------------\n";

    // فتح أنبوب لإرسال النص إلى lolcat
    FILE *pipe = popen("lolcat", "w");
    if (pipe) {
        fprintf(pipe, "%s", banner);
        pclose(pipe);
    } else {
        // في حال فشل lolcat، اطبع الشعار العادي بلون سماوي
        printf("\e[1;36m%s\e[0m", banner);
    }
}

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
EOC

# 3. إعادة بناء المشروع (64-bit)
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_USR/lib/libesh.so
gcc main.c commands.c -I$SRC_DIR -L$PKG_USR/lib -lesh -lreadline -o $PKG_USR/bin/esh

# 4. تحديث نسخة المصنع
cp $SRC_DIR/lib/libesh.c $BASE_DIR/versions_factory/libesh_v3.1_lolcat.c

echo "✅ اكتمل الحقن! شعار ESH الآن يتلألأ بالألوان عبر lolcat."
