#!/bin/bash
BASE_DIR="$HOME/esh-project"
REPO_URL="https://adembenarfa175-code.github.io/esh_project_Shell/esh-repo"

echo "⚙️ ضبط مستودع APT لـ ESH على GitHub Pages..."

cd $BASE_DIR/esh-repo

# 1. تحديث فهارس الحزم لتشمل المسارات الصحيحة
# سيقوم apt-ftparchive بتوليد القائمة بناءً على الملفات الموجودة في pool
apt-ftparchive packages pool/main > dists/stable/main/binary-aarch64/Packages
apt-ftparchive packages pool/main > dists/stable/main/binary-amd64/Packages

# ضغط الملفات (مهم لسرعة apt update)
gzip -fk dists/stable/main/binary-aarch64/Packages
gzip -fk dists/stable/main/binary-amd64/Packages

# 2. توليد ملف Release
apt-ftparchive release dists/stable > dists/stable/Release

echo "✅ تم تحديث الفهارس محلياً."

# 3. إنشاء سكربت التثبيت للمستخدمين (install_esh.sh)
cat << EOI > $BASE_DIR/install_esh.sh
#!/bin/bash
echo "📦 إضافة مستودع ESH إلى نظامك..."
# إضافة المستودع بصيغة [trusted=yes] لأننا لم نقم بتوقيع الملفات بـ GPG بعد
echo "deb [trusted=yes] $REPO_URL stable main" | sudo tee /etc/apt/sources.list.d/esh.list
sudo apt update
sudo apt install esh -y
echo "🚀 ESH مثبت الآن وجاهز للاستخدام!"
EOI

# 4. رفع التعديلات إلى GitHub
cd $BASE_DIR
git add .
git commit -m "APT: Configure repository for GitHub Pages hosting"
git push origin main

echo "🚀 تم الرفع! الآن مستودعك متاح رسمياً."
