#!/bin/bash
echo "📦 إضافة مستودع ESH إلى نظامك..."
# إضافة المستودع بصيغة [trusted=yes] لأننا لم نقم بتوقيع الملفات بـ GPG بعد
echo "deb [trusted=yes] https://adembenarfa175-code.github.io/esh_project_Shell/esh-repo stable main" | sudo tee /etc/apt/sources.list.d/esh.list
sudo apt update
sudo apt install esh -y
echo "🚀 ESH مثبت الآن وجاهز للاستخدام!"
