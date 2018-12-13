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
    if(idx >= boardSize) return; // handles index range error causing memcheck errors

    int posX = idx % x;    // x coordinate
    int posY = idx / x;    // y coordinate

    int leftX = (posX + x - 1) % x;   // one left of idx
    int rightX = (posX + 1) % x;      // one right of idx
    int posYUp = (posY + y - 1) % y;   // one up of idx
    int posYDown = (posY + 1) % y;     // one down of idx

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
    int x, y;                       // board dimensions
    int *d_board, *d_boardR;        // int array pointers
    char* filename = argv[argc-1];  // filename from command line, last argument
    string line;                    // str line to extract from file
    vector<string> vec;             // vec vec to extract board dimensions
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
        if(!line.empty()){
            vec.push_back(line);
        }
        // printf("%s\n",line.c_str());
    }
    infile.close();

    // Use vector size for board dimensions
    y = vec.size();
    x = vec.front().size();
    
    int board[x*y], boardR[x*y];   
    // printf("height: %d | width: %d\n", y, x);

    // Vector List to Single Dimension Array Conversion | -,X replaced with 0,1
    for(i=0; i<y; i++){
        for(j=0; j<x; j++){
            if(vec[i][j] == '-'){
                board[i*x+j]=0;
                boardR[i*x+j]=0;
            }
            else if(vec[i][j] == 'X'){ 
                board[i*x+j]=1; 
                boardR[i*x+j]=1;
            }
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
        nextBoard<<<xy,32>>>(x, y, d_board, d_boardR); // 1024 threads per block
        cudaDeviceSynchronize();
        // Swapping CUDA Kernel input board
        int *temp = d_board;
        d_board = d_boardR;
        d_boardR = temp;
        // if -v, then print each iteration

        if(verbose==true){
            // Animate - Clear terminal
            printf("\033[2J\033[H");
            usleep(10000);

            cudaMemcpy(board, d_board, sizeof(int)*x*y, cudaMemcpyDeviceToHost);
            cudaDeviceSynchronize();
            for(j=0; j<y; j++){
                for(k=0; k<x; k++){
                    if(board[j*x+k]== 0) cout << '-';
                    else if(board[j*x+k]== 1 ) cout << 'X';         
                }
                cout << '\n';
            }
            cout << '\n';
        }
        
    }
    // Copy board back from device memory after iterations
    cudaMemcpy(boardR, d_board, sizeof(int)*x*y, cudaMemcpyDeviceToHost);

    // Free memory
    cudaFree(d_board);
    cudaFree(d_boardR);

    // Print final board to console
    if(verbose==false){
        for(i=0; i<y; i++){
            for(j=0; j<x; j++){
                if(boardR[i*x+j]== 0) cout << '-';
                else if(boardR[i*x+j]== 1 ) cout << 'X';         
            }
            cout << '\n';
        }
    }
}