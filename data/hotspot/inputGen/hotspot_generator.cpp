/*********************

Hotspot Generator - All-in-One Tool
Expands hotspot input files and automatically verifies the results
Usage: ./hotspot_generator <input_size> <multiplier> <temp_in> <power_in> <temp_out> <power_out> [options]

Options:
  --no-verify    Skip verification step
  --verify-only  Only verify (don't expand)
  --quiet        Minimal output

*/

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <ctime>

using namespace std;

class HotspotGenerator {
private:
    int inSize;
    int multiplier;
    int outSize;
    char* tempIn;
    char* powerIn;
    char* tempOut;
    char* powerOut;
    bool quiet;
    
public:
    HotspotGenerator(int inSize, int multiplier, char* tempIn, char* powerIn, char* tempOut, char* powerOut, bool quiet = false) 
        : inSize(inSize), multiplier(multiplier), tempIn(tempIn), powerIn(powerIn), tempOut(tempOut), powerOut(powerOut), quiet(quiet) {
        outSize = inSize * multiplier;
    }
    
    bool expand() {
        if (!quiet) {
            cout << "EXPANDING: " << inSize << "x" << inSize << " → " << outSize << "x" << outSize << " (" << multiplier << "x multiplier)\n";
            cout << "Input files: " << tempIn << ", " << powerIn << "\n";
            cout << "Output files: " << tempOut << ", " << powerOut << "\n\n";
        }
        
        double val;
        fstream fs;
        double ** outMatr;

        // Allocate 2d array of doubles
        outMatr = (double **) malloc(outSize * sizeof(double *));
        if (!outMatr) {
            cerr << "Error: Failed to allocate memory for output matrix\n";
            return false;
        }
        
        for (int i = 0; i < outSize; i++) {
            outMatr[i] = (double *) malloc(outSize * sizeof(double));
            if (!outMatr[i]) {
                cerr << "Error: Failed to allocate memory for output matrix row " << i << "\n";
                return false;
            }
        }

        // Expand temperature file
        if (!quiet) cout << "Expanding temperature data...\n";
        fs.open(tempIn, ios::in);
        if (!fs) {
            cerr << "Error: Failed to open temperature input file: " << tempIn << "\n";
            return false;
        }
        
        for (int row = 0; row < inSize; row++) {
            for (int col = 0; col < inSize; col++) {
                fs >> val;
                for (int rowOff = 0; rowOff < multiplier; rowOff++) {
                    for (int colOff = 0; colOff < multiplier; colOff++) {
                        outMatr[multiplier * row + rowOff][multiplier * col + colOff] = val;
                    }
                }
            }
            
            // Progress for large expansions
            if (!quiet && inSize > 500 && (row % (inSize / 10)) == 0) {
                cout << "   Progress: " << (row * 100 / inSize) << "%\n";
            }
        }
        fs.close();

        fs.open(tempOut, ios::out);
        if (!fs) {
            cerr << "Error: Failed to open temperature output file: " << tempOut << "\n";
            return false;
        }
        fs.precision(6);
        fs.setf(ios::fixed);
        for (int row = 0; row < outSize; row++) {
            for (int col = 0; col < outSize; col++) {
                fs << outMatr[row][col] << "\n";
            }
        }
        fs.close();
        if (!quiet) cout << "Temperature data written to " << tempOut << "\n";

        // Expand power file
        if (!quiet) cout << "Expanding power data...\n";
        fs.open(powerIn, ios::in);
        if (!fs) {
            cerr << "Error: Failed to open power input file: " << powerIn << "\n";
            return false;
        }
        
        for (int row = 0; row < inSize; row++) {
            for (int col = 0; col < inSize; col++) {
                fs >> val;
                for (int rowOff = 0; rowOff < multiplier; rowOff++) {
                    for (int colOff = 0; colOff < multiplier; colOff++) {
                        outMatr[multiplier * row + rowOff][multiplier * col + colOff] = val;
                    }
                }
            }
            
            // Progress for large expansions
            if (!quiet && inSize > 500 && (row % (inSize / 10)) == 0) {
                cout << "   Progress: " << (row * 100 / inSize) << "%\n";
            }
        }
        fs.close();

        fs.open(powerOut, ios::out);
        if (!fs) {
            cerr << "Error: Failed to open power output file: " << powerOut << "\n";
            return false;
        }
        fs.precision(6);
        fs.setf(ios::fixed);
        for (int row = 0; row < outSize; row++) {
            for (int col = 0; col < outSize; col++) {
                fs << outMatr[row][col] << "\n";
            }
        }
        fs.close();
        if (!quiet) cout << "Power data written to " << powerOut << "\n";

        // Clean up
        for (int i = 0; i < outSize; i++)
            free(outMatr[i]);
        free(outMatr);

        if (!quiet) cout << "Expansion completed successfully!\n\n";
        return true;
    }

    bool verify() {
        if (!quiet) {
            cout << "VERIFYING: " << outSize << "x" << outSize << " files were correctly expanded from " << inSize << "x" << inSize << "\n";
            cout << "Total values to verify: " << (outSize * outSize * 2) << "\n\n";
        }
        
        double val;
        fstream fs;
        double ** inTempMatr;
        double ** inPowerMatr;

        // Allocate 2d arrays for input data
        inTempMatr = (double **) malloc(inSize * sizeof(double *));
        inPowerMatr = (double **) malloc(inSize * sizeof(double *));
        if (!inTempMatr || !inPowerMatr) {
            cerr << "Error: Failed to allocate memory for verification\n";
            return false;
        }
        
        for (int i = 0; i < inSize; i++) {
            inTempMatr[i] = (double *) malloc(inSize * sizeof(double));
            inPowerMatr[i] = (double *) malloc(inSize * sizeof(double));
            if (!inTempMatr[i] || !inPowerMatr[i]) {
                cerr << "Error: Failed to allocate memory for verification\n";
                return false;
            }
        }

        // Read input temperature file
        fs.open(tempIn, ios::in);
        if (!fs) {
            cerr << "Error: Failed to open input temperature file: " << tempIn << "\n";
            return false;
        }
        for (int row = 0; row < inSize; row++) {
            for (int col = 0; col < inSize; col++) {
                fs >> inTempMatr[row][col];
            }
        }
        fs.close();

        // Read input power file
        fs.open(powerIn, ios::in);
        if (!fs) {
            cerr << "Error: Failed to open input power file: " << powerIn << "\n";
            return false;
        }
        for (int row = 0; row < inSize; row++) {
            for (int col = 0; col < inSize; col++) {
                fs >> inPowerMatr[row][col];
            }
        }
        fs.close();

        // Verify output temperature file
        if (!quiet) cout << "Verifying temperature expansion...\n";
        fs.open(tempOut, ios::in);
        if (!fs) {
            cerr << "Error: Failed to open output temperature file: " << tempOut << "\n";
            return false;
        }
        
        for (int row = 0; row < outSize; row++) {
            for (int col = 0; col < outSize; col++) {
                fs >> val;
                int inputRow = row / multiplier;
                int inputCol = col / multiplier;
                
                if (val != inTempMatr[inputRow][inputCol]) {
                    cerr << "Temperature verification FAILED at output position (" << row << "," << col << ")\n";
                    cerr << "   Expected: " << inTempMatr[inputRow][inputCol] << ", Got: " << val << "\n";
                    cerr << "   Maps to input position (" << inputRow << "," << inputCol << ")\n";
                    fs.close();
                    return false;
                }
            }
            
            if (!quiet && outSize > 1000 && (row % (outSize / 10)) == 0) {
                cout << "   Temperature progress: " << (row * 100 / outSize) << "%\n";
            }
        }
        fs.close();
        if (!quiet) cout << "Temperature verification: PASSED\n";

        // Verify output power file
        if (!quiet) cout << "Verifying power expansion...\n";
        fs.open(powerOut, ios::in);
        if (!fs) {
            cerr << "Error: Failed to open output power file: " << powerOut << "\n";
            return false;
        }
        
        for (int row = 0; row < outSize; row++) {
            for (int col = 0; col < outSize; col++) {
                fs >> val;
                int inputRow = row / multiplier;
                int inputCol = col / multiplier;
                
                if (val != inPowerMatr[inputRow][inputCol]) {
                    cerr << "Power verification FAILED at output position (" << row << "," << col << ")\n";
                    cerr << "   Expected: " << inPowerMatr[inputRow][inputCol] << ", Got: " << val << "\n";
                    cerr << "   Maps to input position (" << inputRow << "," << inputCol << ")\n";
                    fs.close();
                    return false;
                }
            }
            
            if (!quiet && outSize > 1000 && (row % (outSize / 10)) == 0) {
                cout << "   Power progress: " << (row * 100 / outSize) << "%\n";
            }
        }
        fs.close();
        if (!quiet) cout << "Power verification: PASSED\n";

        // Clean up
        for (int i = 0; i < inSize; i++) {
            free(inTempMatr[i]);
            free(inPowerMatr[i]);
        }
        free(inTempMatr);
        free(inPowerMatr);

        if (!quiet) cout << "VERIFICATION SUCCESSFUL! Both files are correctly expanded.\n\n";
        return true;
    }
};

void printUsage(char* programName) {
    cout << "Hotspot Generator - All-in-One Expansion and Verification Tool\n\n";
    cout << "Usage: " << programName << " <input_size> <multiplier> <temp_in> <power_in> <temp_out> <power_out> [options]\n\n";
    cout << "Parameters:\n";
    cout << "  input_size    Grid dimension of input files (e.g., 64 for 64×64)\n";
    cout << "  multiplier    Expansion factor (2 = double, 5 = 5x larger, etc.)\n";
    cout << "  temp_in       Input temperature filename\n";
    cout << "  power_in      Input power filename\n";
    cout << "  temp_out      Output temperature filename\n";
    cout << "  power_out     Output power filename\n\n";
    cout << "Options:\n";
    cout << "  --no-verify   Skip verification step (expand only)\n";
    cout << "  --verify-only Only verify existing files (don't expand)\n";
    cout << "  --quiet       Minimal output\n\n";
    cout << "Examples:\n";
    cout << "  " << programName << " 64 5 temp_64 power_64 temp_320 power_320\n";
    cout << "  " << programName << " 512 3 temp_512 power_512 temp_1536 power_1536 --quiet\n";
    cout << "  " << programName << " 64 4 temp_64 power_64 temp_256 power_256 --verify-only\n";
}

int main(int argc, char* argv[]) {
    if (argc < 7) {
        printUsage(argv[0]);
        return 1;
    }

    int inSize = atoi(argv[1]);
    int multiplier = atoi(argv[2]);
    char* tempIn = argv[3];
    char* powerIn = argv[4];
    char* tempOut = argv[5];
    char* powerOut = argv[6];

    bool noVerify = false;
    bool verifyOnly = false;
    bool quiet = false;

    // Parse options
    for (int i = 7; i < argc; i++) {
        if (strcmp(argv[i], "--no-verify") == 0) {
            noVerify = true;
        } else if (strcmp(argv[i], "--verify-only") == 0) {
            verifyOnly = true;
        } else if (strcmp(argv[i], "--quiet") == 0) {
            quiet = true;
        } else {
            cerr << "Unknown option: " << argv[i] << "\n";
            return 1;
        }
    }

    if (inSize <= 0 || multiplier <= 0) {
        cerr << "Error: Input size and multiplier must be positive integers\n";
        return 1;
    }

    if (noVerify && verifyOnly) {
        cerr << "Error: Cannot use both --no-verify and --verify-only\n";
        return 1;
    }

    HotspotGenerator generator(inSize, multiplier, tempIn, powerIn, tempOut, powerOut, quiet);

    clock_t startTime = clock();
    
    if (!quiet) {
        cout << "HOTSPOT GENERATOR - All-in-One Tool\n";
        cout << "======================================\n\n";
    }

    bool success = true;

    // Expand phase
    if (!verifyOnly) {
        if (!generator.expand()) {
            cerr << "Expansion failed!\n";
            return 1;
        }
    }

    // Verify phase
    if (!noVerify) {
        if (!generator.verify()) {
            cerr << "Verification failed!\n";
            return 1;
        }
    }

    clock_t endTime = clock();
    double duration = double(endTime - startTime) / CLOCKS_PER_SEC;

    if (!quiet) {
        cout << "PROCESS COMPLETED SUCCESSFULLY!\n";
        cout << "Total time: " << duration << " seconds\n";
        cout << "Ready for hotspot: ./hotspot " << (inSize * multiplier) << " 2 2 " << tempOut << " " << powerOut << " output.out\n";
    }

    return 0;
} 