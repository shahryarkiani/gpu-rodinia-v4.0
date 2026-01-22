/***********************************************************************************
  Implementing Breadth first search on CUDA using algorithm given in HiPC'07
  paper "Accelerating Large Graph Algorithms on the GPU using CUDA"

  Copyright (c) 2008 International Institute of Information Technology - Hyderabad. 
  All rights reserved.

  Permission to use, copy, modify and distribute this software and its documentation for 
  educational purpose is hereby granted without fee, provided that the above copyright 
  notice and this permission notice appear in all copies of this software and that you do 
  not sell the software.

  THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY OF ANY KIND,EXPRESS, IMPLIED OR 
  OTHERWISE.

  Created by Pawan Harish.
  
  NVTX Profiling Version - Enhanced with NVTX ranges for NSYS profiling
 ************************************************************************************/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>
#include <nvtx3/nvToolsExt.h>

#define MAX_THREADS_PER_BLOCK 512

// NVTX Color definitions for different phases
#define NVTX_COLOR_RED    0xFFFF0000
#define NVTX_COLOR_GREEN  0xFF00FF00
#define NVTX_COLOR_BLUE   0xFF0000FF
#define NVTX_COLOR_YELLOW 0xFFFFFF00
#define NVTX_COLOR_CYAN   0xFF00FFFF
#define NVTX_COLOR_MAGENTA 0xFFFF00FF
#define NVTX_COLOR_ORANGE 0xFFFFA500
#define NVTX_COLOR_PURPLE 0xFF800080

int no_of_nodes;
int edge_list_size;
FILE *fp;

//Structure to hold a node information
struct Node
{
	int starting;
	int no_of_edges;
};

#include "kernel.cu"
#include "kernel2.cu"

void BFSGraph(int argc, char** argv);

////////////////////////////////////////////////////////////////////////////////
// Main Program
////////////////////////////////////////////////////////////////////////////////
int main( int argc, char** argv) 
{
	nvtxEventAttributes_t eventAttrib = {0};
	eventAttrib.version = NVTX_VERSION;
	eventAttrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
	eventAttrib.colorType = NVTX_COLOR_ARGB;
	eventAttrib.color = NVTX_COLOR_BLUE;
	eventAttrib.messageType = NVTX_MESSAGE_TYPE_ASCII;
	eventAttrib.message.ascii = "BFS Main Program";
	nvtxRangePushEx(&eventAttrib);

	no_of_nodes=0;
	edge_list_size=0;
	BFSGraph( argc, argv);

	nvtxRangePop();
	return 0;
}

void Usage(int argc, char**argv){

fprintf(stderr,"Usage: %s <input_file>\n", argv[0]);

}
////////////////////////////////////////////////////////////////////////////////
//Apply BFS on a Graph using CUDA
////////////////////////////////////////////////////////////////////////////////
void BFSGraph( int argc, char** argv) 
{
	nvtxEventAttributes_t eventAttrib = {0};
	eventAttrib.version = NVTX_VERSION;
	eventAttrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
	eventAttrib.colorType = NVTX_COLOR_ARGB;
	eventAttrib.messageType = NVTX_MESSAGE_TYPE_ASCII;

    char *input_f;
	if(argc!=2){
	Usage(argc, argv);
	exit(0);
	}
	input_f = argv[1];

	// File I/O Phase
	eventAttrib.color = NVTX_COLOR_GREEN;
	eventAttrib.message.ascii = "File I/O - Reading Graph";
	nvtxRangePushEx(&eventAttrib);

	printf("Reading File\n");
	//Read in Graph from a file
	fp = fopen(input_f,"r");
	if(!fp)
	{
		printf("Error Reading graph file\n");
		nvtxRangePop();
		return;
	}

	int source = 0;

	fscanf(fp,"%d",&no_of_nodes);

	int num_of_blocks = 1;
	int num_of_threads_per_block = no_of_nodes;

	//Make execution Parameters according to the number of nodes
	//Distribute threads across multiple Blocks if necessary
	if(no_of_nodes>MAX_THREADS_PER_BLOCK)
	{
		num_of_blocks = (int)ceil(no_of_nodes/(double)MAX_THREADS_PER_BLOCK); 
		num_of_threads_per_block = MAX_THREADS_PER_BLOCK; 
	}

	// allocate host memory
	Node* h_graph_nodes = (Node*) malloc(sizeof(Node)*no_of_nodes);
	bool *h_graph_mask = (bool*) malloc(sizeof(bool)*no_of_nodes);
	bool *h_updating_graph_mask = (bool*) malloc(sizeof(bool)*no_of_nodes);
	bool *h_graph_visited = (bool*) malloc(sizeof(bool)*no_of_nodes);

	int start, edgeno;   
	// initalize the memory
	for( unsigned int i = 0; i < no_of_nodes; i++) 
	{
		fscanf(fp,"%d %d",&start,&edgeno);
		h_graph_nodes[i].starting = start;
		h_graph_nodes[i].no_of_edges = edgeno;
		h_graph_mask[i]=false;
		h_updating_graph_mask[i]=false;
		h_graph_visited[i]=false;
	}

	//read the source node from the file
	fscanf(fp,"%d",&source);
	source=0;

	//set the source node as true in the mask
	h_graph_mask[source]=true;
	h_graph_visited[source]=true;

	fscanf(fp,"%d",&edge_list_size);

	int id,cost;
	int* h_graph_edges = (int*) malloc(sizeof(int)*edge_list_size);
	for(int i=0; i < edge_list_size ; i++)
	{
		fscanf(fp,"%d",&id);
		fscanf(fp,"%d",&cost);
		h_graph_edges[i] = id;
	}

	if(fp)
		fclose(fp);    

	printf("Read File\n");
	nvtxRangePop(); // End File I/O

	// Host Memory Allocation & Initialization Phase
	eventAttrib.color = NVTX_COLOR_YELLOW;
	eventAttrib.message.ascii = "Host Memory Setup";
	nvtxRangePushEx(&eventAttrib);

	// allocate mem for the result on host side
	int* h_cost = (int*) malloc( sizeof(int)*no_of_nodes);
	for(int i=0;i<no_of_nodes;i++)
		h_cost[i]=-1;
	h_cost[source]=0;

	nvtxRangePop(); // End Host Memory Setup

	// GPU Memory Allocation Phase
	eventAttrib.color = NVTX_COLOR_RED;
	eventAttrib.message.ascii = "GPU Memory Allocation";
	nvtxRangePushEx(&eventAttrib);

	//Copy the Node list to device memory
	Node* d_graph_nodes;
	cudaMalloc( (void**) &d_graph_nodes, sizeof(Node)*no_of_nodes) ;

	//Copy the Edge List to device Memory
	int* d_graph_edges;
	cudaMalloc( (void**) &d_graph_edges, sizeof(int)*edge_list_size) ;

	//Copy the Mask to device memory
	bool* d_graph_mask;
	cudaMalloc( (void**) &d_graph_mask, sizeof(bool)*no_of_nodes) ;

	bool* d_updating_graph_mask;
	cudaMalloc( (void**) &d_updating_graph_mask, sizeof(bool)*no_of_nodes) ;

	//Copy the Visited nodes array to device memory
	bool* d_graph_visited;
	cudaMalloc( (void**) &d_graph_visited, sizeof(bool)*no_of_nodes) ;

	// allocate device memory for result
	int* d_cost;
	cudaMalloc( (void**) &d_cost, sizeof(int)*no_of_nodes);

	//make a bool to check if the execution is over
	bool *d_over;
	cudaMalloc( (void**) &d_over, sizeof(bool));

	nvtxRangePop(); // End GPU Memory Allocation

	// Host to Device Memory Transfer Phase
	eventAttrib.color = NVTX_COLOR_CYAN;
	eventAttrib.message.ascii = "Host to Device Memory Transfer";
	nvtxRangePushEx(&eventAttrib);

	cudaMemcpy( d_graph_nodes, h_graph_nodes, sizeof(Node)*no_of_nodes, cudaMemcpyHostToDevice) ;
	cudaMemcpy( d_graph_edges, h_graph_edges, sizeof(int)*edge_list_size, cudaMemcpyHostToDevice) ;
	cudaMemcpy( d_graph_mask, h_graph_mask, sizeof(bool)*no_of_nodes, cudaMemcpyHostToDevice) ;
	cudaMemcpy( d_updating_graph_mask, h_updating_graph_mask, sizeof(bool)*no_of_nodes, cudaMemcpyHostToDevice) ;
	cudaMemcpy( d_graph_visited, h_graph_visited, sizeof(bool)*no_of_nodes, cudaMemcpyHostToDevice) ;
	cudaMemcpy( d_cost, h_cost, sizeof(int)*no_of_nodes, cudaMemcpyHostToDevice) ;

	printf("Copied Everything to GPU memory\n");
	nvtxRangePop(); // End H2D Transfer

	// Execution Configuration Setup
	eventAttrib.color = NVTX_COLOR_PURPLE;
	eventAttrib.message.ascii = "Execution Configuration";
	nvtxRangePushEx(&eventAttrib);

	// setup execution parameters
	dim3  grid( num_of_blocks, 1, 1);
	dim3  threads( num_of_threads_per_block, 1, 1);

	// Print execution configuration and interesting variables
	printf("\n=== BFS Execution Configuration ===\n");
	printf("Graph Properties:\n");
	printf("  Number of nodes: %d\n", no_of_nodes);
	printf("  Number of edges: %d\n", edge_list_size);
	double avg_degree = (double)edge_list_size / no_of_nodes;
	printf("  Average degree: %.2f\n", avg_degree);
	
	// Classify graph type based on average degree
	if (avg_degree <= 10) {
		printf("  Graph type: SPARSE (avg degree ≤ 10)\n");
	} else if (avg_degree >= 100) {
		printf("  Graph type: DENSE (avg degree ≥ 100)\n");
	} else {
		printf("  Graph type: NORMAL (10 < avg degree < 100)\n");
	}
	printf("  Source node: %d\n", source);
	printf("\nCUDA Execution Parameters:\n");
	printf("  Grid dimensions: (%d, %d, %d)\n", grid.x, grid.y, grid.z);
	printf("  Block dimensions: (%d, %d, %d)\n", threads.x, threads.y, threads.z);
	printf("  Total threads launched: %d\n", num_of_blocks * num_of_threads_per_block);
	printf("  Threads per block: %d\n", num_of_threads_per_block);
	printf("  Number of blocks: %d\n", num_of_blocks);

	printf("===================================\n\n");
	nvtxRangePop(); // End Execution Configuration

	// BFS Kernel Execution Phase
	eventAttrib.color = NVTX_COLOR_ORANGE;
	eventAttrib.message.ascii = "BFS Kernel Execution Loop";
	nvtxRangePushEx(&eventAttrib);

	int k=0;
	printf("Start traversing the tree\n");
	bool stop;
	//Call the Kernel untill all the elements of Frontier are not false
	do
	{
		// Mark each iteration
		char iteration_msg[64];
		sprintf(iteration_msg, "BFS Iteration %d", k);
		nvtxEventAttributes_t iterAttrib = {0};
		iterAttrib.version = NVTX_VERSION;
		iterAttrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
		iterAttrib.colorType = NVTX_COLOR_ARGB;
		iterAttrib.color = NVTX_COLOR_MAGENTA;
		iterAttrib.messageType = NVTX_MESSAGE_TYPE_ASCII;
		iterAttrib.message.ascii = iteration_msg;
		nvtxRangePushEx(&iterAttrib);

		//if no thread changes this value then the loop stops
		stop=false;
		cudaMemcpy( d_over, &stop, sizeof(bool), cudaMemcpyHostToDevice) ;

		// Kernel 1 execution
		nvtxEventAttributes_t kernel1Attrib = {0};
		kernel1Attrib.version = NVTX_VERSION;
		kernel1Attrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
		kernel1Attrib.colorType = NVTX_COLOR_ARGB;
		kernel1Attrib.color = NVTX_COLOR_CYAN;
		kernel1Attrib.messageType = NVTX_MESSAGE_TYPE_ASCII;
		kernel1Attrib.message.ascii = "Kernel1 Execution";
		nvtxRangePushEx(&kernel1Attrib);
		Kernel<<< grid, threads, 0 >>>( d_graph_nodes, d_graph_edges, d_graph_mask, d_updating_graph_mask, d_graph_visited, d_cost, no_of_nodes);
		// cudaDeviceSynchronize(); // Ensure kernel completion for accurate profiling
		nvtxRangePop();

		// Kernel 2 execution  
		nvtxEventAttributes_t kernel2Attrib = {0};
		kernel2Attrib.version = NVTX_VERSION;
		kernel2Attrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;
		kernel2Attrib.colorType = NVTX_COLOR_ARGB;
		kernel2Attrib.color = NVTX_COLOR_YELLOW;
		kernel2Attrib.messageType = NVTX_MESSAGE_TYPE_ASCII;
		kernel2Attrib.message.ascii = "Kernel2 Execution";
		nvtxRangePushEx(&kernel2Attrib);
		Kernel2<<< grid, threads, 0 >>>( d_graph_mask, d_updating_graph_mask, d_graph_visited, d_over, no_of_nodes);
		// cudaDeviceSynchronize(); // Ensure kernel completion for accurate profiling
		nvtxRangePop();

		cudaMemcpy( &stop, d_over, sizeof(bool), cudaMemcpyDeviceToHost) ;
		k++;
		
		nvtxRangePop(); // End iteration
	}
	while(stop);

	printf("BFS completed in %d iterations\n", k);
	nvtxRangePop(); // End BFS Kernel Execution

	// Device to Host Memory Transfer Phase
	eventAttrib.color = NVTX_COLOR_CYAN;
	eventAttrib.message.ascii = "Device to Host Memory Transfer";
	nvtxRangePushEx(&eventAttrib);

	// copy result from device to host
	cudaMemcpy( h_cost, d_cost, sizeof(int)*no_of_nodes, cudaMemcpyDeviceToHost) ;

	nvtxRangePop(); // End D2H Transfer

	// Result Output Phase
	eventAttrib.color = NVTX_COLOR_GREEN;
	eventAttrib.message.ascii = "Result Output to File";
	nvtxRangePushEx(&eventAttrib);

	//Store the result into a file
	FILE *fpo = fopen("result.txt","w");
	for(int i=0;i<no_of_nodes;i++)
		fprintf(fpo,"%d) cost:%d\n",i,h_cost[i]);
	fclose(fpo);
	printf("Result stored in result.txt\n");

	nvtxRangePop(); // End Result Output

	// Memory Cleanup Phase
	eventAttrib.color = NVTX_COLOR_RED;
	eventAttrib.message.ascii = "Memory Cleanup";
	nvtxRangePushEx(&eventAttrib);

	// cleanup memory
	free( h_graph_nodes);
	free( h_graph_edges);
	free( h_graph_mask);
	free( h_updating_graph_mask);
	free( h_graph_visited);
	free( h_cost);
	cudaFree(d_graph_nodes);
	cudaFree(d_graph_edges);
	cudaFree(d_graph_mask);
	cudaFree(d_updating_graph_mask);
	cudaFree(d_graph_visited);
	cudaFree(d_cost);
	cudaFree(d_over);

	nvtxRangePop(); // End Memory Cleanup
}

