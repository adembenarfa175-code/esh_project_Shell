#include "../include/libesh.h"
#include <stdio.h>

void load_c_plugin(char* plugin_name) {
    printf("\e[1;34m[Plugin System]\e[0m Loading C-Plugin: %s\n", plugin_name);
    // هنا سيتم إضافة منطق dlopen مستقبلاً لتحميل ملفات .so
}
