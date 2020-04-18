// Sandip Saha Joy
// Given a list (lst) of length n
// Output its sum = lst[0] + lst[1] + ... + lst[n-1];

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <wb.h>

#define BLOCK_SIZE 512 // TODO: You can change this

#define wbCheck(stmt)                                                     \
  do {                                                                    \
    cudaError_t err = stmt;                                               \
    if (err != cudaSuccess) {                                             \
      wbLog(ERROR, "Failed to run stmt ", #stmt);                         \
      return -1;                                                          \
			    }                                                                     \
        } while (0)

__global__ void total(float *input, float *output, int len) {
	// TODO: Load a segment of the input vector into shared memory
	// TODO: Traverse the reduction tree
	// TODO: Write the computed sum of the block to the output vector at the correct index

	__shared__ float partialSum[2 * BLOCK_SIZE];

	// each thread loads one element from global to shared mem
	unsigned int t = threadIdx.x;
	unsigned int start = 2 * blockIdx.x * BLOCK_SIZE;

	if (start + t < len){
		partialSum[t] = input[start + t];
	}
	else{
		partialSum[t] = 0.0;
	}
		
	if (start + t + BLOCK_SIZE < len){
		partialSum[t + BLOCK_SIZE] = input[start + t + BLOCK_SIZE];
	}
	else {
		partialSum[t + BLOCK_SIZE] = 0.0;
	}
		
	__syncthreads();


	// do reduction in shared mem
	for (int stride = BLOCK_SIZE; stride > 0; stride /= 2)
	{
		__syncthreads();
		if (t < stride)
		{
			partialSum[t] += partialSum[t + stride];
		}
	}

	// write result for this block to global mem
	if (t == 0)
	{
		output[blockIdx.x] = partialSum[0];
	}
	
}

int main(int argc, char **argv) {
	wbArg_t args;
	float *hostInput;  // The input 1D list
	float *hostOutput; // The output list
	float *deviceInput;
	float *deviceOutput;
	int numInputElements;  // number of elements in the input list
	int numOutputElements; // number of elements in the output list

	args = wbArg_read(argc, argv);

	wbTime_start(Generic, "Importing data and creating memory on host");
	hostInput =
		(float *)wbImport(wbArg_getInputFile(args, 0), &numInputElements);

	numOutputElements = numInputElements / (BLOCK_SIZE << 1);
	if (numInputElements % (BLOCK_SIZE << 1)) {
		numOutputElements++;
	}
	hostOutput = (float *)malloc(numOutputElements * sizeof(float));

	wbTime_stop(Generic, "Importing data and creating memory on host");

	wbLog(TRACE, "The number of input elements in the input is ",
		numInputElements);
	wbLog(TRACE, "The number of output elements in the input is ",
		numOutputElements);

	wbTime_start(GPU, "Allocating GPU memory.");
	// TODO: Allocate GPU memory here
	cudaMalloc(&deviceInput, sizeof(float)*numInputElements);
	cudaMalloc(&deviceOutput, sizeof(float)*numOutputElements);
	wbTime_stop(GPU, "Allocating GPU memory.");

	wbTime_start(GPU, "Copying input memory to the GPU.");
	// TODO: Copy memory to the GPU here
	cudaMemcpy(deviceInput, hostInput, sizeof(float)*numInputElements, cudaMemcpyHostToDevice);
	cudaMemcpy(deviceOutput, hostOutput, sizeof(float)*numOutputElements, cudaMemcpyHostToDevice);

	wbTime_stop(GPU, "Copying input memory to the GPU.");
	// TODO: Initialize the grid and block dimensions here
	dim3 dimGrid(((numInputElements + 1) / (BLOCK_SIZE) + 1), 1, 1);
	dim3 dimBlock(BLOCK_SIZE, 1);

	wbTime_start(Compute, "Performing CUDA computation");
	// TODO: Launch the GPU Kernel here
	total << <dimGrid, dimBlock >> >(deviceInput, deviceOutput, numInputElements);

	cudaDeviceSynchronize();
	wbTime_stop(Compute, "Performing CUDA computation");

	wbTime_start(Copy, "Copying output memory to the CPU");
	// TODO: Copy the GPU memory back to the CPU here
	cudaMemcpy(hostOutput, deviceOutput, sizeof(float)*numOutputElements, cudaMemcpyDeviceToHost);
	wbTime_stop(Copy, "Copying output memory to the CPU");

	// TODO:
	/********************************************************************
	* Reduce output vector on the host
	* NOTE: One could also perform the reduction of the output vector
	* recursively and support any size input. For simplicity, we do not
	* require that for this lab.
	********************************************************************/
	int x = 1;
	while (x < numOutputElements)
	{
		hostOutput[0] += hostOutput[x];
		x++;
	}

	wbTime_start(GPU, "Freeing GPU Memory");
	// TODO: Free the GPU memory here
	cudaFree(deviceInput);
	cudaFree(deviceOutput);

	wbTime_stop(GPU, "Freeing GPU Memory");

	wbSolution(args, hostOutput, 1);

	free(hostInput);
	free(hostOutput);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}
