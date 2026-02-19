#!/bin/bash
BASE_DIR="$HOME/esh-project"
REPO_URL="git@github.com:adembenarfa175-code/esh_project_Shell.git"

echo "🌐 جاري بناء واجهات الويب وتحديث المستودع العالمي..."

# دالة توليد الـ HTML (المحسنة)
create_index() {
    local target_dir=$1
    local title=$2
    local back_path=$3

    cat << EOT > "$target_dir/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>ESH Explorer - $title</title>
    <style>
        body { font-family: sans-serif; background: #0d1117; color: #c9d1d9; padding: 40px; }
        .box { max-width: 800px; margin: auto; background: #161b22; border: 1px solid #30363d; border-radius: 6px; overflow: hidden; }
        .header { padding: 15px; background: #21262d; border-bottom: 1px solid #30363d; display: flex; justify-content: space-between; }
        .item { display: block; padding: 12px; border-bottom: 1px solid #21262d; text-decoration: none; color: #58a6ff; }
        .item:hover { background: #1f242c; }
        .item:last-child { border: none; }
    </style>
</head>
<body>
    <div class="box">
        <div class="header">
            <span>📂 Path: $title</span>
            <a href="$back_path" style="color: #8b949e; text-decoration: none;">↑ Back</a>
        </div>
        <div id="list"></div>
    </div>
    <script>
        const files = [$(ls -p "$target_dir" | grep -v "index.html" | sed "s/\(.*\)/'\1',/")];
        const container = document.getElementById('list');
        files.forEach(f => {
            if(!f) return;
            const a = document.createElement('a');
            a.href = f;
            a.className = 'item';
            a.innerText = f.endsWith('/') ? "📁 " + f : "📄 " + f;
            container.appendChild(a);
        });
    </script>
</body>
</html>
EOT
}

# توليد الصفحات في كافة المسارات المطلوبة
create_index "$BASE_DIR" "Root" "https://github.com/adembenarfa175-code/esh_project_Shell"
create_index "$BASE_DIR/src" "src/" "../index.html"
create_index "$BASE_DIR/src/lib" "src/lib/" "../index.html"
create_index "$BASE_DIR/esh-repo" "esh-repo/" "../index.html"
create_index "$BASE_DIR/versions_factory" "versions_factory/" "../index.html"

# الرفع إلى GitHub
cd $BASE_DIR
git add .
git commit -m "Web: Add dynamic directory explorers for all paths"
git push origin main

echo "🚀 تم التحديث! يمكنك الآن تصفح المستودع كأنه موقع ويب عبر GitHub Pages."
