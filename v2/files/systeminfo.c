#include <stdio.h>
#include <stdlib.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>
#include <unistd.h>

int main (int argc, char *argv[]) {
    struct utsname kernel_info;
    struct sysinfo sys_info;
    char hostname[128];
    char machine[128];

    if (uname(&kernel_info) != 0) {
        perror("uname");
    }

    if (sysinfo(&sys_info) != 0) {
        perror("sysinfo");
    }

    printf("\nHello users world");
    printf("\n");
    pritnf("\nKernel: %s %s %s", kernel_info.sysname, kernel_info.release, kernel_info.version);
    printf("\nHostname %s", uname.nodename);
    printf("\nMachine: %s", uname.machine);
    printf("\n");
    printf("\nUptime: %ld:%ld:%ld", sys_info.uptime/3600, sys_info.uptime%3600/60, sys_info.uptime%60);
    printf("\nTotal RAM: %ldMB", (sys_info.totalram / 1024) / 1024 );
    printf("\nFree Ram: %ldMB", (sys_info.freeram / 1024) / 1024);
    printf("\nProcess count: %d", sys_info.procs);
    printf("\nPage size: %ld Bytes", getpagesize());
    printf("\n");

    return 0;
}
