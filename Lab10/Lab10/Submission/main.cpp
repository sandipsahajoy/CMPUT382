// Sandip Saha Joy
#include <wb.h>

#include <CL/opencl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define wbCheck(ans) { gpuAssert((ans), __FILE__, __LINE__); }

const char *getErrorString(cl_int error)
{
	switch (error){
		// run-time and JIT compiler errors
	case 0: return "CL_SUCCESS";
	case -1: return "CL_DEVICE_NOT_FOUND";
	case -2: return "CL_DEVICE_NOT_AVAILABLE";
	case -3: return "CL_COMPILER_NOT_AVAILABLE";
	case -4: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
	case -5: return "CL_OUT_OF_RESOURCES";
	case -6: return "CL_OUT_OF_HOST_MEMORY";
	case -7: return "CL_PROFILING_INFO_NOT_AVAILABLE";
	case -8: return "CL_MEM_COPY_OVERLAP";
	case -9: return "CL_IMAGE_FORMAT_MISMATCH";
	case -10: return "CL_IMAGE_FORMAT_NOT_SUPPORTED";
	case -11: return "CL_BUILD_PROGRAM_FAILURE";
	case -12: return "CL_MAP_FAILURE";
	case -13: return "CL_MISALIGNED_SUB_BUFFER_OFFSET";
	case -14: return "CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST";
	case -15: return "CL_COMPILE_PROGRAM_FAILURE";
	case -16: return "CL_LINKER_NOT_AVAILABLE";
	case -17: return "CL_LINK_PROGRAM_FAILURE";
	case -18: return "CL_DEVICE_PARTITION_FAILED";
	case -19: return "CL_KERNEL_ARG_INFO_NOT_AVAILABLE";

		// compile-time errors
	case -30: return "CL_INVALID_VALUE";
	case -31: return "CL_INVALID_DEVICE_TYPE";
	case -32: return "CL_INVALID_PLATFORM";
	case -33: return "CL_INVALID_DEVICE";
	case -34: return "CL_INVALID_CONTEXT";
	case -35: return "CL_INVALID_QUEUE_PROPERTIES";
	case -36: return "CL_INVALID_COMMAND_QUEUE";
	case -37: return "CL_INVALID_HOST_PTR";
	case -38: return "CL_INVALID_MEM_OBJECT";
	case -39: return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
	case -40: return "CL_INVALID_IMAGE_SIZE";
	case -41: return "CL_INVALID_SAMPLER";
	case -42: return "CL_INVALID_BINARY";
	case -43: return "CL_INVALID_BUILD_OPTIONS";
	case -44: return "CL_INVALID_PROGRAM";
	case -45: return "CL_INVALID_PROGRAM_EXECUTABLE";
	case -46: return "CL_INVALID_KERNEL_NAME";
	case -47: return "CL_INVALID_KERNEL_DEFINITION";
	case -48: return "CL_INVALID_KERNEL";
	case -49: return "CL_INVALID_ARG_INDEX";
	case -50: return "CL_INVALID_ARG_VALUE";
	case -51: return "CL_INVALID_ARG_SIZE";
	case -52: return "CL_INVALID_KERNEL_ARGS";
	case -53: return "CL_INVALID_WORK_DIMENSION";
	case -54: return "CL_INVALID_WORK_GROUP_SIZE";
	case -55: return "CL_INVALID_WORK_ITEM_SIZE";
	case -56: return "CL_INVALID_GLOBAL_OFFSET";
	case -57: return "CL_INVALID_EVENT_WAIT_LIST";
	case -58: return "CL_INVALID_EVENT";
	case -59: return "CL_INVALID_OPERATION";
	case -60: return "CL_INVALID_GL_OBJECT";
	case -61: return "CL_INVALID_BUFFER_SIZE";
	case -62: return "CL_INVALID_MIP_LEVEL";
	case -63: return "CL_INVALID_GLOBAL_WORK_SIZE";
	case -64: return "CL_INVALID_PROPERTY";
	case -65: return "CL_INVALID_IMAGE_DESCRIPTOR";
	case -66: return "CL_INVALID_COMPILER_OPTIONS";
	case -67: return "CL_INVALID_LINKER_OPTIONS";
	case -68: return "CL_INVALID_DEVICE_PARTITION_COUNT";

		// extension errors
	case -1000: return "CL_INVALID_GL_SHAREGROUP_REFERENCE_KHR";
	case -1001: return "CL_PLATFORM_NOT_FOUND_KHR";
	case -1002: return "CL_INVALID_D3D10_DEVICE_KHR";
	case -1003: return "CL_INVALID_D3D10_RESOURCE_KHR";
	case -1004: return "CL_D3D10_RESOURCE_ALREADY_ACQUIRED_KHR";
	case -1005: return "CL_D3D10_RESOURCE_NOT_ACQUIRED_KHR";
	default: return "Unknown OpenCL error";
	}
}

inline void gpuAssert(cl_int code, const char *file, int line, bool abort = true)
{
	if (code != CL_SUCCESS)
	{
		fprintf(stderr, "GPUassert: %s %s %d\n", getErrorString(code), file, line);
		if (abort) {
#if LAB_DEBUG
			system("pause");
#endif
			exit(code);
		}
	}
}

// TODO: Create Kernel
const char *kernelSource = "__kernel void vecAdd(__global float *a,		\n"
"												__global float *b,		\n"
"												__global float *c,		\n"
"												int n)					\n"
"{																		\n"
"	int id = get_global_id(0);											\n"
"	if(id<n)															\n"
"		c[id] = a[id] + b[id];											\n"
"}																		\n";

int main(int argc, char *argv[]) {
	wbArg_t args;
	int inputLength;
	int inputLengthBytes;
	float *hostInput1;
	float *hostInput2;
	float *hostOutput;
	cl_mem deviceInput1;
	cl_mem deviceInput2;
	cl_mem deviceOutput;

	cl_platform_id cpPlatform; // OpenCL platform
	cl_device_id device_id;    // device ID
	cl_context context;        // context
	cl_command_queue queue;    // command queue
	cl_program program;        // program
	cl_kernel kernel;          // kernel
	cl_event event;

	args = wbArg_read(argc, argv);

	wbTime_start(Generic, "Importing data and creating memory on host");
	hostInput1 =
		(float *)wbImport(wbArg_getInputFile(args, 0), &inputLength);
	hostInput2 =
		(float *)wbImport(wbArg_getInputFile(args, 1), &inputLength);
	inputLengthBytes = inputLength * sizeof(float);
	hostOutput = (float *)malloc(inputLengthBytes);
	wbTime_stop(Generic, "Importing data and creating memory on host");

	wbLog(TRACE, "The input length is ", inputLength);
	wbLog(TRACE, "The input size is ", inputLengthBytes, " bytes");


	// TODO: Insert code here
	size_t local, global;

	local = 512;
	global = ceil(inputLength / (float)local)*local;


	clGetPlatformIDs(1, &cpPlatform, NULL);
	clGetDeviceIDs(cpPlatform, CL_DEVICE_TYPE_GPU, 1, &device_id, NULL);

	context = clCreateContext(0, 1, &device_id, NULL, NULL, NULL);

	program = clCreateProgramWithSource(context, 1, &kernelSource, NULL, NULL);
	clBuildProgram(program, 0, NULL, NULL, NULL, NULL);

	kernel = clCreateKernel(program, "vecAdd", NULL);

	deviceInput1 = clCreateBuffer(context, CL_MEM_READ_ONLY, inputLengthBytes, NULL, NULL);
	deviceInput2 = clCreateBuffer(context, CL_MEM_READ_ONLY, inputLengthBytes, NULL, NULL);
	deviceOutput = clCreateBuffer(context, CL_MEM_WRITE_ONLY, inputLengthBytes, NULL, NULL);

	queue = clCreateCommandQueue(context, device_id, 0, NULL);
	clEnqueueWriteBuffer(queue, deviceInput1, CL_TRUE, 0, inputLengthBytes, hostInput1, 0, NULL, NULL);
	clEnqueueWriteBuffer(queue, deviceInput2, CL_TRUE, 0, inputLengthBytes, hostInput2, 0, NULL, NULL);

	clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&deviceInput1);
	clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&deviceInput2);
	clSetKernelArg(kernel, 2, sizeof(cl_mem), (void *)&deviceOutput);
	clSetKernelArg(kernel, 3, sizeof(int), &inputLength);

	clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global, &local, 0, NULL, NULL);
	clFinish(queue);
	clEnqueueReadBuffer(queue, deviceOutput, CL_TRUE, 0, inputLengthBytes, hostOutput, 0, NULL, NULL);

	wbSolution(args, hostOutput, inputLength);

	// release OpenCL resources
	clReleaseMemObject(deviceInput1);
	clReleaseMemObject(deviceInput2);
	clReleaseMemObject(deviceOutput);
	clReleaseProgram(program);
	clReleaseKernel(kernel);
	clReleaseCommandQueue(queue);
	clReleaseContext(context);

	// release host memory
	free(hostInput1);
	free(hostInput2);
	free(hostOutput);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}
