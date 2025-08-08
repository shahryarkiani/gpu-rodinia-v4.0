/*********************

Hotspot3D Generator - 3D Thermal Simulation Data Generator
Creates 3D hotspot datasets by expanding existing 2D or 3D data
Usage: ./hotspot3D_generator <input_type> <args...>

Modes:
  2D-to-3D: Convert 2D hotspot data to 3D by replicating across layers
  3D-expand: Expand existing 3D data to larger grid sizes or more layers
  3D-layers: Change number of layers in existing 3D data

*/

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <cmath>
#include <vector> // Added for vector usage

using namespace std;

class Hotspot3DGenerator {
private:
    bool quiet;
    
public:
    Hotspot3DGenerator(bool quiet = false) : quiet(quiet) {}
    
    // Convert 2D hotspot data to 3D by replicating across layers
    bool convertFrom2D(int gridSize, int layers, char* temp2D, char* power2D, char* temp3D, char* power3D) {
        if (!quiet) {
            cout << "🔄 CONVERTING 2D → 3D\n";
            cout << "📐 Grid: " << gridSize << "×" << gridSize << " → " << gridSize << "×" << gridSize << "×" << layers << "\n";
            cout << "📁 2D files: " << temp2D << ", " << power2D << "\n";
            cout << "📄 3D files: " << temp3D << ", " << power3D << "\n\n";
        }
        
        int totalValues2D = gridSize * gridSize;
        int totalValues3D = gridSize * gridSize * layers;
        
        // Read 2D temperature data
        ifstream tempIn(temp2D);
        if (!tempIn) {
            cerr << "❌ Error: Cannot open 2D temperature file: " << temp2D << "\n";
            return false;
        }
        
        vector<float> temp2DData(totalValues2D);
        for (int i = 0; i < totalValues2D; i++) {
            tempIn >> temp2DData[i];
        }
        tempIn.close();
        
        // Read 2D power data
        ifstream powerIn(power2D);
        if (!powerIn) {
            cerr << "❌ Error: Cannot open 2D power file: " << power2D << "\n";
            return false;
        }
        
        vector<float> power2DData(totalValues2D);
        for (int i = 0; i < totalValues2D; i++) {
            powerIn >> power2DData[i];
        }
        powerIn.close();
        
        // Write 3D temperature data (replicate each 2D layer)
        ofstream tempOut(temp3D);
        if (!tempOut) {
            cerr << "❌ Error: Cannot create 3D temperature file: " << temp3D << "\n";
            return false;
        }
        
        tempOut.precision(6);
        tempOut.setf(ios::fixed);
        
        if (!quiet) cout << "🌡️  Replicating temperature data across " << layers << " layers...\n";
        
        for (int row = 0; row < gridSize; row++) {
            for (int col = 0; col < gridSize; col++) {
                for (int layer = 0; layer < layers; layer++) {
                    int index2D = row * gridSize + col;
                    // Add slight variation between layers (temperature gradient)
                    float tempVariation = temp2DData[index2D] + (layer * 0.1f); // Small gradient
                    tempOut << tempVariation << "\n";
                }
            }
            
            if (!quiet && gridSize > 100 && (row % (gridSize / 10)) == 0) {
                cout << "   Progress: " << (row * 100 / gridSize) << "%\n";
            }
        }
        tempOut.close();
        
        // Write 3D power data (replicate each 2D layer)
        ofstream powerOut(power3D);
        if (!powerOut) {
            cerr << "❌ Error: Cannot create 3D power file: " << power3D << "\n";
            return false;
        }
        
        powerOut.precision(6);
        powerOut.setf(ios::fixed);
        
        if (!quiet) cout << "⚡ Replicating power data across " << layers << " layers...\n";
        
        for (int row = 0; row < gridSize; row++) {
            for (int col = 0; col < gridSize; col++) {
                for (int layer = 0; layer < layers; layer++) {
                    int index2D = row * gridSize + col;
                    // Add variation between layers (power distribution)
                    float powerVariation = power2DData[index2D] * (0.8f + layer * 0.05f); // Varying power
                    powerOut << powerVariation << "\n";
                }
            }
        }
        powerOut.close();
        
        if (!quiet) {
            cout << "✅ 3D conversion completed!\n";
            cout << "📊 Created " << totalValues3D << " values from " << totalValues2D << " values\n\n";
        }
        
        return true;
    }
    
    // Expand 3D grid size (spatial expansion)
    bool expand3DGrid(int inputSize, int inputLayers, int multiplier, 
                      char* tempIn, char* powerIn, char* tempOut, char* powerOut) {
        int outputSize = inputSize * multiplier;
        
        if (!quiet) {
            cout << "🚀 EXPANDING 3D GRID\n";
            cout << "📐 Grid: " << inputSize << "×" << inputSize << "×" << inputLayers 
                 << " → " << outputSize << "×" << outputSize << "×" << inputLayers << "\n";
            cout << "📁 Input files: " << tempIn << ", " << powerIn << "\n";
            cout << "📄 Output files: " << tempOut << ", " << powerOut << "\n\n";
        }
        
        int totalValuesIn = inputSize * inputSize * inputLayers;
        int totalValuesOut = outputSize * outputSize * inputLayers;
        
        // Read input temperature data
        ifstream tempInFile(tempIn);
        if (!tempInFile) {
            cerr << "❌ Error: Cannot open input temperature file: " << tempIn << "\n";
            return false;
        }
        
        vector<float> tempData(totalValuesIn);
        for (int i = 0; i < totalValuesIn; i++) {
            tempInFile >> tempData[i];
        }
        tempInFile.close();
        
        // Read input power data
        ifstream powerInFile(powerIn);
        if (!powerInFile) {
            cerr << "❌ Error: Cannot open input power file: " << powerIn << "\n";
            return false;
        }
        
        vector<float> powerData(totalValuesIn);
        for (int i = 0; i < totalValuesIn; i++) {
            powerInFile >> powerData[i];
        }
        powerInFile.close();
        
        // Expand temperature data
        ofstream tempOutFile(tempOut);
        if (!tempOutFile) {
            cerr << "❌ Error: Cannot create output temperature file: " << tempOut << "\n";
            return false;
        }
        
        tempOutFile.precision(6);
        tempOutFile.setf(ios::fixed);
        
        if (!quiet) cout << "🌡️  Expanding temperature data...\n";
        
        for (int row = 0; row < outputSize; row++) {
            for (int col = 0; col < outputSize; col++) {
                for (int layer = 0; layer < inputLayers; layer++) {
                    // Map output coordinates to input coordinates
                    int inputRow = row / multiplier;
                    int inputCol = col / multiplier;
                    int inputIndex = inputRow * inputSize + inputCol + layer * inputSize * inputSize;
                    
                    tempOutFile << tempData[inputIndex] << "\n";
                }
            }
            
            if (!quiet && outputSize > 100 && (row % (outputSize / 10)) == 0) {
                cout << "   Progress: " << (row * 100 / outputSize) << "%\n";
            }
        }
        tempOutFile.close();
        
        // Expand power data
        ofstream powerOutFile(powerOut);
        if (!powerOutFile) {
            cerr << "❌ Error: Cannot create output power file: " << powerOut << "\n";
            return false;
        }
        
        powerOutFile.precision(6);
        powerOutFile.setf(ios::fixed);
        
        if (!quiet) cout << "⚡ Expanding power data...\n";
        
        for (int row = 0; row < outputSize; row++) {
            for (int col = 0; col < outputSize; col++) {
                for (int layer = 0; layer < inputLayers; layer++) {
                    int inputRow = row / multiplier;
                    int inputCol = col / multiplier;
                    int inputIndex = inputRow * inputSize + inputCol + layer * inputSize * inputSize;
                    
                    powerOutFile << powerData[inputIndex] << "\n";
                }
            }
        }
        powerOutFile.close();
        
        if (!quiet) {
            cout << "✅ 3D grid expansion completed!\n";
            cout << "📊 Expanded from " << totalValuesIn << " to " << totalValuesOut << " values\n\n";
        }
        
        return true;
    }
    
    // Change number of layers in 3D data
    bool changeLayers(int gridSize, int inputLayers, int outputLayers,
                      char* tempIn, char* powerIn, char* tempOut, char* powerOut) {
        if (!quiet) {
            cout << "📚 CHANGING LAYER COUNT\n";
            cout << "📐 Grid: " << gridSize << "×" << gridSize << "×" << inputLayers 
                 << " → " << gridSize << "×" << gridSize << "×" << outputLayers << "\n";
            cout << "📁 Input files: " << tempIn << ", " << powerIn << "\n";
            cout << "📄 Output files: " << tempOut << ", " << powerOut << "\n\n";
        }
        
        int totalValuesIn = gridSize * gridSize * inputLayers;
        int totalValuesOut = gridSize * gridSize * outputLayers;
        
        // Read input data
        ifstream tempInFile(tempIn);
        if (!tempInFile) {
            cerr << "❌ Error: Cannot open input temperature file: " << tempIn << "\n";
            return false;
        }
        
        vector<float> tempData(totalValuesIn);
        for (int i = 0; i < totalValuesIn; i++) {
            tempInFile >> tempData[i];
        }
        tempInFile.close();
        
        ifstream powerInFile(powerIn);
        if (!powerInFile) {
            cerr << "❌ Error: Cannot open input power file: " << powerIn << "\n";
            return false;
        }
        
        vector<float> powerData(totalValuesIn);
        for (int i = 0; i < totalValuesIn; i++) {
            powerInFile >> powerData[i];
        }
        powerInFile.close();
        
        // Write output with modified layer count
        ofstream tempOutFile(tempOut);
        ofstream powerOutFile(powerOut);
        
        if (!tempOutFile || !powerOutFile) {
            cerr << "❌ Error: Cannot create output files\n";
            return false;
        }
        
        tempOutFile.precision(6);
        tempOutFile.setf(ios::fixed);
        powerOutFile.precision(6);
        powerOutFile.setf(ios::fixed);
        
        if (!quiet) cout << "🔄 Adjusting layer count...\n";
        
        for (int row = 0; row < gridSize; row++) {
            for (int col = 0; col < gridSize; col++) {
                for (int outLayer = 0; outLayer < outputLayers; outLayer++) {
                    // Map output layer to input layer (with interpolation/repetition)
                    int inLayer;
                    if (outputLayers <= inputLayers) {
                        // Reducing layers: sample evenly
                        inLayer = (outLayer * inputLayers) / outputLayers;
                    } else {
                        // Increasing layers: repeat with interpolation
                        inLayer = (outLayer * inputLayers) / outputLayers;
                        if (inLayer >= inputLayers) inLayer = inputLayers - 1;
                    }
                    
                    int inputIndex = row * gridSize + col + inLayer * gridSize * gridSize;
                    
                    // Add layer-specific variation
                    float tempVariation = tempData[inputIndex] + (outLayer - inLayer) * 0.05f;
                    float powerVariation = powerData[inputIndex] * (1.0f + (outLayer - inLayer) * 0.02f);
                    
                    tempOutFile << tempVariation << "\n";
                    powerOutFile << powerVariation << "\n";
                }
            }
        }
        
        tempOutFile.close();
        powerOutFile.close();
        
        if (!quiet) {
            cout << "✅ Layer adjustment completed!\n";
            cout << "📊 Changed from " << totalValuesIn << " to " << totalValuesOut << " values\n\n";
        }
        
        return true;
    }
};

void printUsage(char* programName) {
    cout << "Hotspot3D Generator - 3D Thermal Simulation Data Generator\n\n";
    cout << "MODES:\n\n";
    cout << "1. Convert 2D to 3D:\n";
    cout << "   " << programName << " 2d-to-3d <grid_size> <layers> <temp_2d> <power_2d> <temp_3d> <power_3d>\n\n";
    cout << "2. Expand 3D grid:\n";
    cout << "   " << programName << " expand-grid <input_size> <layers> <multiplier> <temp_in> <power_in> <temp_out> <power_out>\n\n";
    cout << "3. Change layer count:\n";
    cout << "   " << programName << " change-layers <grid_size> <input_layers> <output_layers> <temp_in> <power_in> <temp_out> <power_out>\n\n";
    cout << "OPTIONS:\n";
    cout << "   --quiet    Minimal output\n\n";
    cout << "EXAMPLES:\n";
    cout << "   # Convert 2D 64x64 to 3D 64x64x8\n";
    cout << "   " << programName << " 2d-to-3d 64 8 temp_64 power_64 temp_64x8 power_64x8\n\n";
    cout << "   # Expand 3D 64x64x8 to 256x256x8 (4x spatial)\n";
    cout << "   " << programName << " expand-grid 64 8 4 temp_64x8 power_64x8 temp_256x8 power_256x8\n\n";
    cout << "   # Change 512x512x8 to 512x512x16 (double layers)\n";
    cout << "   " << programName << " change-layers 512 8 16 temp_512x8 power_512x8 temp_512x16 power_512x16\n";
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printUsage(argv[0]);
        return 1;
    }
    
    bool quiet = false;
    
    // Check for --quiet flag
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "--quiet") == 0) {
            quiet = true;
            break;
        }
    }
    
    string mode = argv[1];
    Hotspot3DGenerator generator(quiet);
    
    clock_t startTime = clock();
    
    if (!quiet) {
        cout << "🔥 HOTSPOT3D GENERATOR\n";
        cout << "=====================\n\n";
    }
    
    bool success = false;
    
    if (mode == "2d-to-3d" && argc >= 8) {
        int gridSize = atoi(argv[2]);
        int layers = atoi(argv[3]);
        success = generator.convertFrom2D(gridSize, layers, argv[4], argv[5], argv[6], argv[7]);
        
        if (success && !quiet) {
            cout << "📋 Ready for hotspot3D: ./3D " << gridSize << " " << layers << " 100 " << argv[6] << " " << argv[7] << " output.out\n";
        }
    }
    else if (mode == "expand-grid" && argc >= 9) {
        int inputSize = atoi(argv[2]);
        int layers = atoi(argv[3]);
        int multiplier = atoi(argv[4]);
        success = generator.expand3DGrid(inputSize, layers, multiplier, argv[5], argv[6], argv[7], argv[8]);
        
        if (success && !quiet) {
            cout << "📋 Ready for hotspot3D: ./3D " << (inputSize * multiplier) << " " << layers << " 100 " << argv[7] << " " << argv[8] << " output.out\n";
        }
    }
    else if (mode == "change-layers" && argc >= 9) {
        int gridSize = atoi(argv[2]);
        int inputLayers = atoi(argv[3]);
        int outputLayers = atoi(argv[4]);
        success = generator.changeLayers(gridSize, inputLayers, outputLayers, argv[5], argv[6], argv[7], argv[8]);
        
        if (success && !quiet) {
            cout << "📋 Ready for hotspot3D: ./3D " << gridSize << " " << outputLayers << " 100 " << argv[7] << " " << argv[8] << " output.out\n";
        }
    }
    else {
        cerr << "❌ Error: Invalid mode or insufficient arguments\n\n";
        printUsage(argv[0]);
        return 1;
    }
    
    if (!success) {
        cerr << "❌ Generation failed!\n";
        return 1;
    }
    
    clock_t endTime = clock();
    double duration = double(endTime - startTime) / CLOCKS_PER_SEC;
    
    if (!quiet) {
        cout << "🏁 PROCESS COMPLETED SUCCESSFULLY!\n";
        cout << "⏱️  Total time: " << duration << " seconds\n";
    }
    
    return 0;
} 