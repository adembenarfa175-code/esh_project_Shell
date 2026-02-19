#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int esh_cd(char **args) {
    if (args[1] == NULL) {
        fprintf(stderr, "esh: expected argument to \"cd\"\n");
    } else {
        if (chdir(args[1]) != 0) {
            perror("esh");
        }
    }
    return 1;
}

int esh_exit(char **args) {
    return 0;
}
