// Sandip Saha Joy
// Kernel for adding to vectors
// There are a few TODOs that you need to fill out
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <wb.h>

__global__ void vecAdd(float *in1, float *in2, float *out, int len) {
	// TODO: Insert code to implement vector addition here
	int i = threadIdx.x + blockDim.x*blockIdx.x;
	if (i<len) out[i] = in1[i] + in2[i];
}

int main(int argc, char **argv) {
	wbArg_t args;
	int inputLength;
	float *hostInput1;
	float *hostInput2;
	float *hostOutput;
	float *deviceInput1;
	float *deviceInput2;
	float *deviceOutput;

	args = wbArg_read(argc, argv);

	wbTime_start(Generic, "Importing data and creating memory on host");
	hostInput1 = (float *)wbImport(wbArg_getInputFile(args, 0), &inputLength);
	hostInput2 = (float *)wbImport(wbArg_getInputFile(args, 1), &inputLength);
	hostOutput = (float *)malloc(inputLength * sizeof(float));
	wbTime_stop(Generic, "Importing data and creating memory on host");

	wbLog(TRACE, "The input length is ", inputLength);
	int size = inputLength*sizeof(float);

	wbTime_start(GPU, "Allocating GPU memory.");
	// TODO: Allocate GPU memory here
	cudaMalloc((void**)&deviceInput1, size);
	cudaMalloc((void**)&deviceInput2, size);
	cudaMalloc((void**)&deviceOutput, size);
	wbTime_stop(GPU, "Allocating GPU memory.");

	wbTime_start(GPU, "Copying input memory to the GPU.");
	// TODO: Copy memory to the GPU here
	cudaMemcpy(deviceInput1, hostInput1, size, cudaMemcpyHostToDevice);
	cudaMemcpy(deviceInput2, hostInput2, size, cudaMemcpyHostToDevice);
	wbTime_stop(GPU, "Copying input memory to the GPU.");

	// TODO: Initialize the grid and block dimensions here
	// HINT: Look up CUDAs dim3 
	dim3 DimGrid((inputLength - 1) / 256 + 1, 1, 1);
	dim3 DimBlock(256, 1, 1);
	// Optional you might want to log the block and grid
	// dimensions as follows:
	// wbLog(TRACE, "Block dimension is ", blockDim.x);
	// wbLog(TRACE, "Grid dimension is ", gridDim.x);
	// Don't uncomment the above code, they do not work on the machines in the lab

	wbTime_start(Compute, "Performing CUDA computation");
	// TODO: Launch the GPU Kernel here
	vecAdd<<<DimGrid, DimBlock>>>(deviceInput1, deviceInput2, deviceOutput, inputLength);
	wbTime_stop(Compute, "Performing CUDA computation");

	wbTime_start(Copy, "Copying output memory to the CPU");
	// TODO: Copy the GPU memory back to the CPU here
	cudaMemcpy(hostOutput, deviceOutput, size, cudaMemcpyDeviceToHost);
	wbTime_stop(Copy, "Copying output memory to the CPU");

	wbTime_start(GPU, "Freeing GPU Memory");
	// TODO: Free the GPU memory here
	cudaFree(deviceInput1);
	cudaFree(deviceInput2);
	cudaFree(deviceOutput);
	wbTime_stop(GPU, "Freeing GPU Memory");

	cudaDeviceSynchronize();

	wbSolution(args, hostOutput, inputLength);

	free(hostInput1);
	free(hostInput2);
	free(hostOutput);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}

