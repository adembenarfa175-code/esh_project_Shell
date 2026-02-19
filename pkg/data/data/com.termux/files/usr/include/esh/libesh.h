#ifndef LIBESH_H
#define LIBESH_H

// الدوال الأساسية
void print_banner();
char* get_custom_prompt();
void print_rprompt();
void run_first_time_setup();

// دوال المحرك الجديد (Alias & Config)
void load_eshrc();
char* check_alias(char* cmd);

#endif
