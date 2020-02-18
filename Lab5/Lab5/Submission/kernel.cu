// Sandip Saha Joy

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <wb.h>

#define NUM_BINS 4096

#define CUDA_CHECK(ans)                                                   \
    { gpuAssert((ans), __FILE__, __LINE__); }

inline void gpuAssert(cudaError_t code, const char *file, int line,
	bool abort = true) {
	if (code != cudaSuccess) {
		fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code),
			file, line);
		if (abort)
			exit(code);
	}
}


__global__ void histogram_kernel(unsigned int *input, unsigned int *bin, int inputLength, int binLength)
{
	int i = blockIdx.x * blockDim.x + threadIdx.x;

	int x = i;
	while (x < inputLength)
	{
		atomicAdd(&(bin[input[x]]), 1);
		x += (blockDim.x * gridDim.x);
	}
	__syncthreads();
}


__global__ void histogram_kernel_optimized(unsigned int *input, unsigned int *bin, int inputLength, int binLength)
{
	int x;
	int i = blockIdx.x * blockDim.x + threadIdx.x;

	extern __shared__ unsigned int bin_shared[];

	x = threadIdx.x;
	while (x < binLength)
	{
		bin_shared[x] = 0;
		x += blockDim.x;
	}
	__syncthreads();

	x = i;
	while (x < inputLength)
	{
		atomicAdd(&(bin_shared[input[x]]), 1);
		x += (blockDim.x * gridDim.x);
	}
	__syncthreads();

	x = threadIdx.x;
	while (x < binLength)
	{
		atomicAdd(&(bin[x]), bin_shared[x]);
		x += blockDim.x;
	}
	__syncthreads();
}

__global__ void post_processing(unsigned int *bin, int binLength)
{
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	if (i < binLength)
	{
		if (bin[i] > 127)
			bin[i] = 127;
	}
}

int main(int argc, char *argv[]) {
	wbArg_t args;
	int inputLength;
	int binLength = NUM_BINS;
	unsigned int *hostInput;
	unsigned int *hostBins;
	unsigned int *deviceInput;
	unsigned int *deviceBins;

	args = wbArg_read(argc, argv);

	wbTime_start(Generic, "Importing data and creating memory on host");
	hostInput = (unsigned int *)wbImport(wbArg_getInputFile(args, 0),
		&inputLength, "Integer");
	hostBins = (unsigned int *)malloc(binLength * sizeof(unsigned int));
	wbTime_stop(Generic, "Importing data and creating memory on host");

	wbLog(TRACE, "The input length is ", inputLength);
	wbLog(TRACE, "The number of bins is ", binLength);

	wbTime_start(GPU, "Allocating GPU memory.");
	// TODO: Allocate GPU memory here
	cudaMalloc(&deviceInput, inputLength * sizeof(unsigned int));
	cudaMalloc(&deviceBins, binLength * sizeof(unsigned int));

	CUDA_CHECK(cudaDeviceSynchronize());
	wbTime_stop(GPU, "Allocating GPU memory.");

	wbTime_start(GPU, "Copying input memory to the GPU.");
	// TODO: Copy memory to the GPU here
	cudaMemcpy(deviceInput, hostInput, inputLength * sizeof(unsigned int), cudaMemcpyHostToDevice);

	CUDA_CHECK(cudaDeviceSynchronize());
	wbTime_stop(GPU, "Copying input memory to the GPU.");

	// Launch kernel
	// ----------------------------------------------------------
	wbLog(TRACE, "Launching kernel");
	wbTime_start(Compute, "Performing CUDA computation");

	// TODO: Perform kernel computation here
	dim3 gridDim(32);
	dim3 blockDim(1024);

	//histogram_kernel << <gridDim, blockDim, binLength * sizeof(unsigned int) >> >(deviceInput, deviceBins, inputLength, binLength);
	histogram_kernel_optimized << <gridDim, blockDim, binLength * sizeof(unsigned int) >> >(deviceInput, deviceBins, inputLength, binLength);
	post_processing << <gridDim, blockDim, binLength * sizeof(unsigned int) >> >(deviceBins, binLength);

	// You should call the following lines after you call the kernel.
	CUDA_CHECK(cudaGetLastError());
	CUDA_CHECK(cudaDeviceSynchronize());

	wbTime_stop(Compute, "Performing CUDA computation");

	wbTime_start(Copy, "Copying output memory to the CPU");
	// TODO: Copy the GPU memory back to the CPU here
	cudaMemcpy(hostBins, deviceBins, binLength * sizeof(unsigned int), cudaMemcpyDeviceToHost);

	CUDA_CHECK(cudaDeviceSynchronize());
	wbTime_stop(Copy, "Copying output memory to the CPU");

	wbTime_start(GPU, "Freeing GPU Memory");
	// TODO: Free the GPU memory here
	cudaFree(deviceInput);
	cudaFree(deviceBins);

	wbTime_stop(GPU, "Freeing GPU Memory");

	// Verify correctness
	// -----------------------------------------------------
	wbSolution(args, hostBins, binLength);

	free(hostBins);
	free(hostInput);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}























































































































































































































































//Reference: https://bit.ly/2Hf6HKz