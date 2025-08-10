#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define GET_RAND_FP ((float)rand() / ((float)(RAND_MAX) + (float)(1)))

int main(int argc, char **argv) {
    int matrix_size;
    int i, j, k;
    float **L, **U, **A;
    float sum;
    char filename[100];
    FILE *fp;

    // Check arguments
    if (argc != 2) {
        printf("Usage: %s <matrix_size>\n", argv[0]);
        printf("Example: %s 128\n", argv[0]);
        return 1;
    }

    matrix_size = atoi(argv[1]);
    if (matrix_size <= 0) {
        printf("Error: Matrix size must be positive\n");
        return 1;
    }

    printf("Generating %dx%d LUD matrix...\n", matrix_size, matrix_size);

    // Allocate memory for matrices
    L = (float**)malloc(matrix_size * sizeof(float*));
    U = (float**)malloc(matrix_size * sizeof(float*));
    A = (float**)malloc(matrix_size * sizeof(float*));

    for (i = 0; i < matrix_size; i++) {
        L[i] = (float*)malloc(matrix_size * sizeof(float));
        U[i] = (float*)malloc(matrix_size * sizeof(float));
        A[i] = (float*)malloc(matrix_size * sizeof(float));
    }

    // Initialize random seed
    srand(time(NULL));

    // Generate L and U matrices
    printf("Generating L and U matrices...\n");
    for (i = 0; i < matrix_size; i++) {
        for (j = 0; j < matrix_size; j++) {
            if (i == j) {
                // Diagonal of L is 1, U has random values
                L[i][j] = 1.0;
                U[i][j] = GET_RAND_FP;
            } else if (i > j) {
                // Lower triangular part of L, upper part of U is 0
                L[i][j] = GET_RAND_FP;
                U[i][j] = 0.0;
            } else {
                // Upper triangular part of U, lower part of L is 0
                L[i][j] = 0.0;
                U[i][j] = GET_RAND_FP;
            }
        }
    }

    // Calculate A = L * U
    printf("Computing A = L * U...\n");
    for (i = 0; i < matrix_size; i++) {
        for (j = 0; j < matrix_size; j++) {
            sum = 0.0;
            for (k = 0; k < matrix_size; k++) {
                sum += L[i][k] * U[k][j];
            }
            A[i][j] = sum;
        }
    }

    // Save matrix A (the main input file for LUD)
    sprintf(filename, "%d.dat", matrix_size);
    fp = fopen(filename, "w");
    if (!fp) {
        printf("Error: Cannot create file %s\n", filename);
        return 1;
    }

    // Write matrix size first, then the matrix data
    fprintf(fp, "%d\n", matrix_size);
    for (i = 0; i < matrix_size; i++) {
        for (j = 0; j < matrix_size; j++) {
            fprintf(fp, "%f ", A[i][j]);
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
    printf("Generated: %s\n", filename);

    // Save reference L matrix
    sprintf(filename, "l-%d.dat", matrix_size);
    fp = fopen(filename, "w");
    if (fp) {
        for (i = 0; i < matrix_size; i++) {
            for (j = 0; j < matrix_size; j++) {
                fprintf(fp, "%f ", L[i][j]);
            }
            fprintf(fp, "\n");
        }
        fclose(fp);
        printf("Generated: %s\n", filename);
    }

    // Save reference U matrix
    sprintf(filename, "u-%d.dat", matrix_size);
    fp = fopen(filename, "w");
    if (fp) {
        for (i = 0; i < matrix_size; i++) {
            for (j = 0; j < matrix_size; j++) {
                fprintf(fp, "%f ", U[i][j]);
            }
            fprintf(fp, "\n");
        }
        fclose(fp);
        printf("Generated: %s\n", filename);
    }

    // Free memory
    for (i = 0; i < matrix_size; i++) {
        free(L[i]);
        free(U[i]);
        free(A[i]);
    }
    free(L);
    free(U);
    free(A);

    printf("Done! Files created:\n");
    printf("  %d.dat     - Main matrix A for LUD algorithm\n", matrix_size);
    printf("  l-%d.dat   - Reference L matrix (lower triangular)\n", matrix_size);
    printf("  u-%d.dat   - Reference U matrix (upper triangular)\n", matrix_size);

    return 0;
}