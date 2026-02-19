#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <unistd.h>
#include "lib/libesh.h"

void execute_with_heredoc(char *command, char *delimiter) {
    char *h_line;
    char temp_file[] = "/tmp/esh_heredocXXXXXX";
    int fd = mkstemp(temp_file);
    
    if (fd == -1) return;

    // جمع أسطر Heredoc وكتابتها في ملف مؤقت
    while ((h_line = readline("heredoc> ")) != NULL) {
        if (strcmp(h_line, delimiter) == 0) {
            free(h_line);
            break;
        }
        write(fd, h_line, strlen(h_line));
        write(fd, "\n", 1);
        free(h_line);
    }
    close(fd);

    // تنفيذ الأمر الفعلي باستخدام الملف المؤقت كإدخال
    char final_cmd[1024];
    sprintf(final_cmd, "%s < %s", command, temp_file);
    system(final_cmd);

    // تنظيف الملف المؤقت
    unlink(temp_file);
}

int main() {
    print_banner();
    while (1) {
        print_rprompt();
        char *line = readline(get_custom_prompt());
        if (!line) break;
        if (strlen(line) > 0) {
            add_history(line);
            
            if (strstr(line, "<<")) {
                char *cmd_part = strtok(strdup(line), "<<");
                char *delim = strstr(line, "<<") + 2;
                while(*delim == ' ') delim++;
                execute_with_heredoc(cmd_part, delim);
            } else if (strcmp(line, "exit") == 0) {
                break;
            } else {
                system(line);
            }
        }
        free(line);
    }
    return 0;
}
