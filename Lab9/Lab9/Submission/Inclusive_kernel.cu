// Sandip Saha Joy
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <wb.h>

#define BLOCK_SIZE 512 //TODO: You can change this

#define wbCheck(ans) { gpuAssert((ans), __FILE__, __LINE__); }

inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true)
{
	if (code != cudaSuccess)
	{
		fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
		if (abort) exit(code);
	}
}

__global__ void blockadd(int* g_aux, int* g_odata, int length){
	int index = blockIdx.x*blockDim.x + threadIdx.x;
	if (blockIdx.x > 0 && index < length)
		g_odata[index] += g_aux[blockIdx.x];

}
__global__ void scan(int *g_odata, int *g_idata, int *g_aux, int length){

	int index = blockIdx.x*blockDim.x + threadIdx.x;
	__shared__ float temp[BLOCK_SIZE];

	if (index < length){
		temp[threadIdx.x] = g_idata[index];
	}

	for (int stride = 1; stride <= threadIdx.x; stride *= 2){
		__syncthreads();
		float k = 0.0;
		if (threadIdx.x >= stride){
			k = temp[threadIdx.x - stride];
		}
		__syncthreads();
		temp[threadIdx.x] += k;
	}

	__syncthreads();

	if (index + 1 < length){
		g_odata[index + 1] = temp[threadIdx.x];
	}
	g_odata[0] = 0;


	if (g_aux != NULL && threadIdx.x == blockDim.x - 1){
		g_aux[blockIdx.x] = g_odata[index + 1];
		g_odata[index + 1] = 0;
	}
}

void recursive_scan(int* deviceOutput, int* deviceInput, int numElements){
	int numBlocks = (numElements / BLOCK_SIZE) + 1;
	if (numBlocks == 1){
		dim3 block(BLOCK_SIZE, 1);
		dim3 grid(numBlocks, 1);
		scan << <grid, block >> >(deviceOutput, deviceInput, NULL, numElements);
		cudaDeviceSynchronize();
	}
	else{
		int* deviceAux;
		cudaMalloc((void**)&deviceAux, (numBlocks*sizeof(int)));
		dim3 block(BLOCK_SIZE, 1);
		dim3 grid(numBlocks, 1);
		scan << <grid, block >> >(deviceOutput, deviceInput, deviceAux, numElements);
		cudaDeviceSynchronize();

		int *deviceAuxPass;
		cudaMalloc((void**)&deviceAuxPass, (numBlocks*sizeof(int)));
		dim3 grid2(1, 1);
		dim3 block2(numBlocks, 1, 1);
		scan << <grid2, block2 >> >(deviceAuxPass, deviceAux, NULL, numBlocks);
		cudaDeviceSynchronize();

		recursive_scan(deviceAuxPass, deviceAux, numBlocks);
		blockadd << <block2, block >> >(deviceAuxPass, deviceOutput, numElements);
		cudaDeviceSynchronize();

		cudaFree(deviceAux);
		cudaFree(deviceAuxPass);
	}

}

__global__ void scatter(int *in_d, int *index_d, int *out_d, int length) {
	int index = threadIdx.x + blockDim.x * blockIdx.x;
	if (index < length)
		out_d[index_d[index]] = in_d[index];
	__syncthreads();
}

__global__ void split_A(int *in_d, int *out_d, int length, int bit_d) {
	int index = threadIdx.x + blockDim.x * blockIdx.x;
	int bit = 0;
	if (index < length) {
		bit = in_d[index] & (1 << bit_d);
		if (bit > 0)
			bit = 1;
		else
			bit = 0;
		out_d[index] = 1 - bit;
	}
	__syncthreads();
}

__global__ void split_B(int *in_d, int *out_d, int length) {
	int index = threadIdx.x + blockDim.x * blockIdx.x;
	int x = in_d[length - 1] + out_d[length - 1];
	__syncthreads();
	if (index < length && out_d[index] == 0) {
		__syncthreads();
		in_d[index] = index - in_d[index] + x;
	}
}

void sort(int* d_deviceInput, int *d_deviceOutput, int numElements)
{
	//TODO: Modify this to complete the functionality of the sort on the deivce
	int *swap_T, *T;
	dim3 block(BLOCK_SIZE, 1);
	dim3 grid((numElements / BLOCK_SIZE) + 1, 1);
	cudaMalloc(&T, sizeof(int)*numElements);
	
	for (int bit = 0; bit < 15; bit++){
		split_A << <grid, block >> >(d_deviceInput, d_deviceOutput, numElements, bit);
		cudaDeviceSynchronize();

		recursive_scan(T, d_deviceOutput, numElements);
		cudaDeviceSynchronize();

		split_B << <grid, block >> >(T, d_deviceOutput, numElements);
		cudaDeviceSynchronize();

		scatter << <grid, block >> >(d_deviceInput, T, d_deviceOutput, numElements);
		cudaDeviceSynchronize();

		//swap
		swap_T = d_deviceInput;
		d_deviceInput = d_deviceOutput;
		d_deviceOutput = swap_T;

	}

}


int main(int argc, char **argv) {
	wbArg_t args;
	int *hostInput;  // The input 1D list
	int *hostOutput; // The output list
	int *deviceInput;
	int *deviceOutput;
	int numElements; // number of elements in the list

	args = wbArg_read(argc, argv);

	wbTime_start(Generic, "Importing data and creating memory on host");
	hostInput = (int *)wbImport(wbArg_getInputFile(args, 0), &numElements, "integral_vector");
	cudaHostAlloc(&hostOutput, numElements * sizeof(int), cudaHostAllocDefault);
	wbTime_stop(Generic, "Importing data and creating memory on host");

	wbLog(TRACE, "The number of input elements in the input is ", numElements);

	wbTime_start(GPU, "Allocating GPU memory.");
	wbCheck(cudaMalloc((void **)&deviceInput, numElements * sizeof(int)));
	wbCheck(cudaMalloc((void **)&deviceOutput, numElements * sizeof(int)));
	wbTime_stop(GPU, "Allocating GPU memory.");

	wbTime_start(GPU, "Clearing output memory.");
	wbCheck(cudaMemset(deviceOutput, 0, numElements * sizeof(int)));
	wbTime_stop(GPU, "Clearing output memory.");

	wbTime_start(GPU, "Copying input memory to the GPU.");
	wbCheck(cudaMemcpy(deviceInput, hostInput, numElements * sizeof(int),
		cudaMemcpyHostToDevice));
	wbTime_stop(GPU, "Copying input memory to the GPU.");

	wbTime_start(Compute, "Performing CUDA computation");
	sort(deviceInput, deviceOutput, numElements);
	wbTime_stop(Compute, "Performing CUDA computation");

	wbTime_start(Copy, "Copying output memory to the CPU");
	wbCheck(cudaMemcpy(hostOutput, deviceOutput, numElements * sizeof(float),
		cudaMemcpyDeviceToHost));
	wbTime_stop(Copy, "Copying output memory to the CPU");

	wbTime_start(GPU, "Freeing GPU Memory");
	cudaFree(deviceInput);
	cudaFree(deviceOutput);
	wbTime_stop(GPU, "Freeing GPU Memory");

	wbSolution(args, hostOutput, numElements);

	free(hostInput);
	cudaFreeHost(hostOutput);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}
