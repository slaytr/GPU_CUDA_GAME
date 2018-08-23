#include <iostream>
#include <fstream> // file input
#include <string> 
#include <vector> // list
#include <unistd.h> // getopt
#include <stdlib.h> // exit

using namespace std;

// global var
int i, j, k; // ITERATE VARIABLES

// cuda kernel
__global__ void nextBoard(int x, int y, int* board, int* boardR)
{     
    int boardSize = x * y;
    int idx = blockDim.x*blockIdx.x+threadIdx.x;

    if(idx >= boardSize) return; // handles index range error
    
    // x, y coordinates
    int posX = idx % x;    // x coordinate
    int posY = idx / x;    // y coordinate

    int leftX = (posX + x - 1) % x;   // one left of idx
    int rightX = (posX + 1) % x;      // one right of idx

    int posYUp = (posY + y - 1) % y;   // one up of idx
    int posYDown = (posY + 1) % y;     // one down of idx

    // TEST - no values exceed board size
    // if((posX > boardSize|| posY > boardSize || leftX > boardSize || rightX > boardSize || posYUp > boardSize || posYDown > boardSize)) printf("Error");

    // Alive neighbours for each point idx
    int neighbours = board[leftX + posYUp*x] 
        + board[posX + posYUp*x] 
        + board[rightX + posYUp*x]
        + board[leftX + posY*x] 
        + board[rightX + posY*x]
        + board[leftX + posYDown*x] 
        + board[posX + posYDown*x] 
        + board[rightX + posYDown*x];

    
    // Assigning new cell value
    boardR[posX+posY*x] = (neighbours == 3 || (neighbours == 2 && board[posY * x + posX])) ? 1 : 0;
}

int main(int argc, char **argv)
{
    int x, y;                       // BOARD DIMENSIONS
    int *d_board, *d_boardR;        // ARRAY POINTERS
    char* filename = argv[argc-1];  // filename from command line, last argument
    string line;                    // str line to extract from file
    vector<string> vec;             // vec vec to extract BOARD DIMENSIONS
    int option;                     // getopt var
    int iter = 1;                   // board iteration variable
    bool verbose = false;       

    // getopt - iterations and verbose
    while((option = getopt(argc, argv, "i:v"))!=-1){
        switch (option) {
            case 'i' :
                iter = atoi(optarg);
                // printf("%d", iter);
                break;
            case 'v' : 
                verbose = true;
                // printf("verbose");
                break;
            default : 
                printf("you broke it");       
        }
    }

    // Get input file, convert into vector, could be replace with a function
    ifstream infile(filename);
    while (!infile.eof()){
        getline(infile, line);
        vec.push_back(line);
    }
    infile.close();

    // Use vector size for board dimensions
    y = vec.size();
    x = vec.front().size();

    int board[x*y], boardR[x*y];

    // Vector List to Single Dimension Array Conversion | -,X replaced with 0,1
    for(i=0; i<x; i++){
        for(j=0; j<y; j++){
            if(vec[i][j] == '-'){
                board[i*x+j]=0;
                boardR[i*x+j]=0;
            }
            else if(vec[i][j] == 'X'){ 
                board[i*x+j]=1; 
                boardR[i*x+j]=1;
            }
            else cout << "Your input contains invalid characters";
        }
    }

    // Allocate device memory for board arrays
    cudaMalloc((void **)&d_board, sizeof(int)*x*y);
    cudaMalloc((void **)&d_boardR, sizeof(int)*x*y);

    // Copy host arrays to device 
    cudaMemcpy(d_board, board, sizeof(int)*x*y, cudaMemcpyHostToDevice);
    cudaMemcpy(d_boardR, boardR, sizeof(int)*x*y, cudaMemcpyHostToDevice);

    // for calculating cuda blocks, board size/threads for blocks needed
    const int xy = 1 + ((x*y-1)/32);

    // Pick number of iterations to run board on GPU
    for(i=0; i<iter; i++){
        nextBoard<<<xy,32>>>(x, y, d_board, d_boardR); // 32 threads per block
        cudaDeviceSynchronize();
        // Swapping CUDA Kernel input board
        int *temp = d_board;
        d_board = d_boardR;
        d_boardR = temp;
        
        // if -v, then print each iteration
        if(verbose==true){
            cudaMemcpy(board, d_board, sizeof(int)*x*y, cudaMemcpyDeviceToHost);
            for(j=0; j<x; j++){
                for(k=0; k<y; k++){
                    if(board[j*x+k]== 0) cout << '-';
                    else if(board[j*x+k]== 1 ) cout << 'X';         
                }
                cout << '\n';
            }
        }
        cout << '\n';
    }
    // Copy board back from device memory after iter
    cudaMemcpy(boardR, d_boardR, sizeof(int)*x*y, cudaMemcpyDeviceToHost);

    // Free memory
    cudaFree(d_board);
    cudaFree(d_boardR);

    // Print final board to console
    if(verbose==false){
        for(i=0; i<x; i++){
            for(j=0; j<y; j++){
                if(boardR[i*x+j]== 0) cout << '-';
                else if(boardR[i*x+j]== 1 ) cout << 'X';         
            }
            cout << '\n';
        }
    }
}