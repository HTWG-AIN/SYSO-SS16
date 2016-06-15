#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#define NUM_THREADS 4
#define NUM_ROUNDS 50
#define TEST_REPETITIONS 50
#define BUFFER_SIZE 128

typedef struct parameters {
    char *device_path;
    int open_test;
    int read_test;
    int write_test;
    int sleep_time_ms;
} program_params_t;

typedef struct thread_params {
    program_params_t *program_params;
    int thread_num;
} thread_params_t;

void *access_tests(void *arg);
void help();

int main(int argc, char *argv[]) {
    program_params_t *program_params;
    thread_params_t **thread_params;
    pthread_t *threads;
    int opt, i;

    srand(time(NULL));

    program_params = malloc(sizeof(program_params_t));

    while ((opt = getopt(argc, argv, "d:orwt:h")) != -1) {
        switch (opt) {
            case 'd':
                program_params->device_path = optarg;
                break;
            case 'o':
                program_params->open_test = 1;
                break;
            case 'r':
                program_params->read_test = 1;
                break;
            case 'w':
                program_params->write_test = 1;
                break;
            case 't':
                program_params->sleep_time_ms = atoi(optarg);
                break;
            case 'h':
                help();
                break;
        }
    }

    if (!program_params->device_path) {
        fprintf(stderr, "A device path must be supplied!\n");
        help();
        return EXIT_FAILURE;
    }

    threads = malloc(NUM_THREADS * sizeof(pthread_t));
    thread_params = malloc(NUM_THREADS * sizeof(thread_params_t *));
    for (i = 0; i < NUM_THREADS; i++) {
        thread_params[i] = malloc(sizeof(thread_params_t));
        thread_params[i]->program_params = program_params;
        thread_params[i]->thread_num = i;
        pthread_create(&threads[i], NULL, access_tests, thread_params[i]);
    }

    for (i = 0; i < NUM_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }

    for (i = 0; i < NUM_THREADS; i++) {
        free(thread_params[i]);
    }
    free(program_params);
    free(threads);
    free(thread_params);
    return 0;
}

void *access_tests(void *arg) {
    thread_params_t *params;
    program_params_t *prog_params;
    struct timespec sleep_time;
    int i, fd, n, res, aux;
    char buf[BUFFER_SIZE];

    params = (thread_params_t *) arg;
    prog_params = params->program_params;
    sleep_time.tv_sec = 0;
    sleep_time.tv_nsec = (1000000 * prog_params->sleep_time_ms);

    // TODO: arrange tests in functions
    if (prog_params->open_test) {
        // Open test
        printf("## thread%d: starting open_test...\n");
        for (i = 0; i < TEST_REPETITIONS; i++) {
            if ((fd = open(prog_params->device_path, O_RDONLY)) < 0) {
                fprintf(stderr, "-> thread%d: open_test%d: error opening file %s\n", params->thread_num, i, prog_params->device_path);
            } else {
                printf("-> thread%d: open_test%d completed succesfully\n", params->thread_num, i, prog_params->device_path);
                clock_nanosleep(CLOCK_REALTIME, 0, &sleep_time, NULL);
                if (close(fd) < 0) {
                    fprintf(stderr, "-> thread%d: open_test%d: error closing file %s\n", params->thread_num, i, prog_params->device_path);
                }
            }
        }
    }
    if (prog_params->read_test) {
        // Read test: read NUM_ROUNDS times from the device
        printf("## thread%d: starting read_test...\n");
        for (i = 0; i < TEST_REPETITIONS; i++) {
            if ((fd = open(prog_params->device_path, O_RDONLY)) < 0) {
                fprintf(stderr, "-> thread%d: read_test%d: error opening file %s\n", params->thread_num, i, prog_params->device_path);
            } else {
                n = NUM_ROUNDS;
                while (n-- && (res = read(fd, buf, BUFFER_SIZE)) >= 0);
                if (res < 0) {
                    fprintf(stderr, "-> thread%d: read_test%d: error reading data\n", params->thread_num, i);
                } else {
                    printf("-> thread%d: read_test%d completed succesfully\n", params->thread_num, i, prog_params->device_path);
                }
                if (close(fd) < 0) {
                    fprintf(stderr, "-> thread%d: read_test%d: error closing file %s\n", params->thread_num, i, prog_params->device_path);
                }
            }
        }
        clock_nanosleep(CLOCK_REALTIME, 0, &sleep_time, NULL);
    }
    if (prog_params->write_test) {
        // Write test: write NUM_ROUNDS times random data to the device
        printf("## thread%d: starting write_test...\n");
        for (i = 0; i < TEST_REPETITIONS; i++) {
            if ((fd = open(prog_params->device_path, O_WRONLY)) < 0) {
                fprintf(stderr, "-> thread%d: write_test%d: error opening file %s\n", params->thread_num, i, prog_params->device_path);
            } else {
                n = NUM_ROUNDS;
                aux = rand();
                while (n-- && (res = write(fd, &aux, sizeof(int))) >= 0) {
                    aux = rand();
                }
                if (res < 0) {
                    fprintf(stderr, "-> thread%d: write_test%d: error writing data\n", params->thread_num, i);
                } else {
                    printf("-> thread%d: write_test%d completed succesfully\n", params->thread_num, i, prog_params->device_path);
                }
                if (close(fd) < 0) {
                    fprintf(stderr, "-> thread%d: write_test%d: error closing file %s\n", params->thread_num, i, prog_params->device_path);
                }
            }
        }
        clock_nanosleep(CLOCK_REALTIME, 0, &sleep_time, NULL);
    }
}

void help() {
    // TODO: change usage like this: access [OPTIONS] [device ...]
    printf("\nUsage: access -d {device} [OPTIONS]\n"
           "\n"
           "\tOPTIONS:\n"
           "\t-o           perform open test\n"
           "\t-r           perform read test\n"
           "\t-w           perform write test\n"
           "\t-t {TIME}    waiting time in ms between operations (open/close for -o, reads for -r or writes for -w)\n"
           "\n");
}
