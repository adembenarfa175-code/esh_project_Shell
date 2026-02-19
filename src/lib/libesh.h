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
