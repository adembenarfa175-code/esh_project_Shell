#!/bin/bash
set_arch() { 
    echo "Select Architecture for v3.0:" 
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
    sed -i "s/^Version:.*/Version: 3.0/" /data/data/com.termux/files/home/esh-project/pkg/DEBIAN/control 
} 
set_arch
BASE_DIR="$HOME/esh-project"
SRC_DIR="$BASE_DIR/src"
PKG_USR="$BASE_DIR/pkg/data/data/com.termux/files/usr"

echo "🔧 جاري إصلاح تعريفات الجيل الثالث ESH v3.0.0..."

# 1. تحديث ملف الرأس (libesh.h) ليشمل دالة التدوين
cat << 'EOC' > $SRC_DIR/lib/libesh.h
#ifndef LIBESH_H
#define LIBESH_H

// دوال الواجهة والبرومبت
void print_banner();
char* get_custom_prompt();
void print_rprompt();
void run_first_time_setup();

// دوال المحرك (Core Engine)
void load_eshrc();
char* check_alias(char* cmd);

// محرك التدوين (Logging Engine) - الإصلاح هنا
void log_command(const char* cmd);

#endif
EOC

# 2. إعادة البناء (Compilation)
echo "🔨 إعادة بناء النواة (Core) والربط بالمكتبات..."
cd $SRC_DIR
gcc -fPIC -shared lib/libesh.c -o $PKG_USR/lib/libesh.so
gcc main.c commands.c -I$SRC_DIR -L$PKG_USR/lib -lesh -lreadline -o $PKG_USR/bin/esh

# 3. بناء الحزمة النهائية
cd $BASE_DIR
dpkg-deb --build pkg esh_3.0_${ARCH}.deb

echo "✅ تم الإصلاح! الآن ESH v3.0.0 مستقر وجاهز للعمل."
