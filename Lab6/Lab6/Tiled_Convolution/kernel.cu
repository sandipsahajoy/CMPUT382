// Sandip Saha Joy 
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <wb.h>

#define wbCheck(stmt)                                                     \
  do {                                                                    \
    cudaError_t err = stmt;                                               \
    if (err != cudaSuccess) {                                             \
      wbLog(ERROR, "Failed to run stmt ", #stmt);                         \
      return -1;                                                          \
	    }                                                                     \
    } while (0)

#define Mask_width 5
#define Mask_radius Mask_width / 2
#define TILE_WIDTH 16
#define w (TILE_WIDTH + Mask_width - 1)
#define clamp(x) (min(max((x), 0.0), 1.0))

__global__ void tiled_convolution(float *I, const float *M, float *P, int channels, int width, int height) {
	//TODO: INSERT CODE HERE

	__shared__ float N_ds[w][w];
	int Row = blockIdx.y * TILE_WIDTH + threadIdx.y;
	int Col = blockIdx.x * TILE_WIDTH + threadIdx.x;

	for (int channel = 0; channel < channels; channel++) 
	{
		int	ty = (threadIdx.y * TILE_WIDTH + threadIdx.x) / w;
		int tx = (threadIdx.y * TILE_WIDTH + threadIdx.x) % w;
		int row_o = blockIdx.y *TILE_WIDTH + ty;
		int col_o = blockIdx.x *TILE_WIDTH + tx;
		int row_i = row_o - Mask_radius;
		int col_i = col_o - Mask_radius;
		if (row_i >= 0 && row_i < height && col_i >= 0 && col_i < width)
			N_ds[ty][tx] = I[(row_i * width + col_i) * channels + channel];
		else
			N_ds[ty][tx] = 0;


		ty = (threadIdx.y * TILE_WIDTH + threadIdx.x + TILE_WIDTH * TILE_WIDTH) / w;
		tx = (threadIdx.y * TILE_WIDTH + threadIdx.x + TILE_WIDTH * TILE_WIDTH) % w;
		row_o = blockIdx.y *TILE_WIDTH + ty;
		col_o = blockIdx.x *TILE_WIDTH + tx;
		row_i = row_o - Mask_radius;
		col_i = col_o - Mask_radius;
		if (ty < w) 
		{
			if (row_i >= 0 && row_i < height && col_i >= 0 && col_i < width)
				N_ds[ty][tx] = I[(row_i * width + col_i) * channels + channel];
			else
				N_ds[ty][tx] = 0;
		}
		__syncthreads();


		float pixVal = 0;
		for (int row = 0; row < Mask_width; row++)
		{
			for (int col = 0; col < Mask_width; col++)
			{
				pixVal += N_ds[threadIdx.y + row][threadIdx.x + col] * M[row * Mask_width + col];
			}
		}

		if (Col < width  && Row < height)
		{
			P[(Row*width + Col)*channels + channel] = clamp(pixVal);
		}
		__syncthreads();
	}

}

int main(int argc, char *argv[]) {
	wbArg_t arg;
	int maskRows;
	int maskColumns;
	int imageChannels;
	int imageWidth;
	int imageHeight;
	char *inputImageFile;
	char *inputMaskFile;
	wbImage_t inputImage;
	wbImage_t outputImage;
	float *hostInputImageData;
	float *hostOutputImageData;
	float *hostMaskData;
	float *deviceInputImageData;
	float *deviceOutputImageData;
	float *deviceMaskData;

	arg = wbArg_read(argc, argv); /* parse the input arguments */

	inputImageFile = wbArg_getInputFile(arg, 0);
	inputMaskFile = wbArg_getInputFile(arg, 1);

	inputImage = wbImport(inputImageFile);
	hostMaskData = (float *)wbImport(inputMaskFile, &maskRows, &maskColumns);

	assert(maskRows == 5);    /* mask height is fixed to 5 in this mp */
	assert(maskColumns == 5); /* mask width is fixed to 5 in this mp */

	imageWidth = wbImage_getWidth(inputImage);
	imageHeight = wbImage_getHeight(inputImage);
	imageChannels = wbImage_getChannels(inputImage);

	outputImage = wbImage_new(imageWidth, imageHeight, imageChannels);

	hostInputImageData = wbImage_getData(inputImage);
	hostOutputImageData = wbImage_getData(outputImage);

	wbTime_start(GPU, "Doing GPU Computation (memory + compute)");

	wbTime_start(GPU, "Doing GPU memory allocation");
	//TODO: INSERT CODE HERE
	cudaMalloc(&deviceInputImageData, imageWidth * imageHeight * imageChannels * sizeof(float));
	cudaMalloc(&deviceMaskData, maskRows * maskColumns * sizeof(float));
	cudaMalloc(&deviceOutputImageData, imageWidth * imageHeight * imageChannels * sizeof(float));

	wbTime_stop(GPU, "Doing GPU memory allocation");

	wbTime_start(Copy, "Copying data to the GPU");
	//TODO: INSERT CODE HERE
	cudaMemcpy(deviceInputImageData, hostInputImageData, imageWidth * imageHeight * imageChannels * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(deviceMaskData, hostMaskData, maskRows * maskColumns * sizeof(float), cudaMemcpyHostToDevice);

	wbTime_stop(Copy, "Copying data to the GPU");

	wbTime_start(Compute, "Doing the computation on the GPU");
	//TODO: INSERT CODE HERE
	dim3 dimGrid(ceil((float)imageWidth / TILE_WIDTH), ceil((float)imageHeight / TILE_WIDTH));
	dim3 dimBlock(TILE_WIDTH, TILE_WIDTH, 1);

	tiled_convolution << <dimGrid, dimBlock >> >(deviceInputImageData, deviceMaskData, deviceOutputImageData, imageChannels, imageWidth, imageHeight);
	
	cudaDeviceSynchronize();
	wbTime_stop(Compute, "Doing the computation on the GPU");

	wbTime_start(Copy, "Copying data from the GPU");
	//TODO: INSERT CODE HERE
	cudaMemcpy(hostOutputImageData, deviceOutputImageData, imageWidth * imageHeight * imageChannels * sizeof(float), cudaMemcpyDeviceToHost);

	wbTime_stop(Copy, "Copying data from the GPU");

	wbTime_stop(GPU, "Doing GPU Computation (memory + compute)");

	wbSolution(arg, outputImage);

	//TODO: RELEASE CUDA MEMORY
	cudaFree(deviceInputImageData);
	cudaFree(deviceOutputImageData);
	cudaFree(deviceMaskData);

	free(hostMaskData);
	wbImage_delete(outputImage);
	wbImage_delete(inputImage);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}
