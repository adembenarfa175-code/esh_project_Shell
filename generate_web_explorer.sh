#!/bin/bash
BASE_DIR="$HOME/esh-project"

echo "🌐 جاري بناء واجهة المتصفح الويب للمستودع..."

# دالة لإنشاء ملف HTML لكل مجلد
create_index() {
    local target_dir=$1
    local title=$2

    cat << EOT > "$target_dir/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESH Explorer - $title</title>
    <script src="https://kit.fontawesome.com/a076d05399.js" crossorigin="anonymous"></script>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0d1117; color: #c9d1d9; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 20px; }
        h1 { color: #58a6ff; border-bottom: 1px solid #30363d; padding-bottom: 10px; }
        .file-list { list-style: none; padding: 0; }
        .file-item { display: flex; align-items: center; padding: 10px; border-bottom: 1px solid #21262d; text-decoration: none; color: #c9d1d9; transition: 0.2s; }
        .file-item:hover { background: #1f242c; color: #58a6ff; }
        .file-item i { margin-right: 12px; width: 20px; text-align: center; }
        .back-btn { display: inline-block; margin-bottom: 20px; color: #8b949e; text-decoration: none; font-size: 14px; }
        .back-btn:hover { color: #c9d1d9; }
    </style>
</head>
<body>
    <div class="container">
        <a href="../index.html" class="back-btn">← Back to Parent Directory</a>
        <h1>📂 ESH Project: $title</h1>
        <div class="file-list" id="explorer">
            </div>
    </div>

    <script>
        // مصفوفة تحتوي على الملفات في هذا المجلد (سيتم توليدها برمجياً)
        const files = [
            $(ls -p "$target_dir" | grep -v "index.html" | sed "s/\(.*\)/'\1',/")
        ];

        const explorer = document.getElementById('explorer');
        files.forEach(file => {
            if (!file) return;
            const isDir = file.endsWith('/');
            const icon = isDir ? 'fa-folder' : 'fa-file-code';
            const link = document.createElement('a');
            link.href = file;
            link.className = 'file-item';
            link.innerHTML = \`<i class="fas \${icon}"></i> \${file}\`;
            explorer.appendChild(link);
        });
    </script>
</body>
</html>
EOT
}

# إنشاء ملفات Index في المسارات الحيوية
create_index "$BASE_DIR" "Root"
create_index "$BASE_DIR/src" "Source Code"
create_index "$BASE_DIR/src/lib" "Core Libraries"
create_index "$BASE_DIR/versions_factory" "Versions Factory"
create_index "$BASE_DIR/esh-repo" "APT Repository"

echo "✅ تم إنشاء واجهات HTML لجميع المجلدات."
