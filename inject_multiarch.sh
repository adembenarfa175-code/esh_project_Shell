#!/bin/bash
FACTORY_DIR="$HOME/esh-project/versions_factory"
CONTROL_FILE="$HOME/esh-project/pkg/DEBIAN/control"

echo "⚙️ جاري حقن ميزة المعماريات المتعددة في سكربتات المصنع..."

for script in $FACTORY_DIR/build_v*.sh; do
    # الحصول على رقم الإصدار من اسم الملف (مثلاً 3.0)
    VER_NUM=$(echo $script | grep -oP 'v[0-9.]+' | sed 's/v//')

    # إضافة وظيفة ضبط المعمارية في بداية الملف بعد الـ Shebang
    sed -i '2i \
set_arch() { \
    echo "Select Architecture for v'$VER_NUM':" \
    echo "1) aarch64 (Default)" \
    echo "2) amd64" \
    echo "3) x86_64" \
    read -p "Choice [1-3]: " arch_choice \
    case $arch_choice in \
        2) ARCH="amd64" ;; \
        3) ARCH="x86_64" ;; \
        *) ARCH="aarch64" ;; \
    esac \
    sed -i "s/^Architecture:.*/Architecture: $ARCH/" '"$CONTROL_FILE"' \
    sed -i "s/^Version:.*/Version: '$VER_NUM'/" '"$CONTROL_FILE"' \
} \
set_arch' "$script"

    # تعديل أمر dpkg-deb ليكون مرناً مع المعمارية المختارة
    sed -i 's/dpkg-deb --build pkg.*/dpkg-deb --build pkg esh_'"$VER_NUM"'_${ARCH}.deb/' "$script"
done

echo "✅ تم التعديل! كل سكربتات البناء الآن تسألك عن المعمارية قبل البدء."
