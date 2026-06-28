#define _GNU_SOURCE
#include <stdio.h>

int wiringPiSetup(void)
{
    fprintf(stderr, "[shim wiringPi] wiringPiSetup()\n");
    return 0;
}

void pinMode(int pin, int mode)
{
    fprintf(stderr, "[shim wiringPi] pinMode(%d, %d)\n", pin, mode);
}

void digitalWrite(int pin, int value)
{
    fprintf(stderr, "[shim wiringPi] digitalWrite(%d, %d)\n", pin, value);
}