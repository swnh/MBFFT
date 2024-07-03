#include <stdio.h>
#include <math.h>

#define N 16
#define PI 3.14159265358979323846

typedef struct {
    double real;
    double img;
} my_complex;

void make_twiddle(my_complex *W) {
    double delta = 2 * PI / N;
    int i;

    for (i = 0; i < N/2; i++) {
        W[i].real = cos(i * delta);
        W[i].img = -sin(i * delta);
    }
}

int main() {
    my_complex twiddle[N/2];
    int i;

    make_twiddle(twiddle);

    for (i = 0; i < N/2; i++) {
        int re_hex = (int)(twiddle[i].real * 32767); 
        int im_hex = (int)(twiddle[i].img  * 32767);
        printf("%04X%04X,\n", (unsigned short)im_hex, (unsigned short)re_hex);
        // printf("%f, %f\n", twiddle[i].real, twiddle[i].img);
    }

    return 0;
}