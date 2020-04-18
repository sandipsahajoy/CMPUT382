#include <algorithm>
#include <wb.h>

int main(int argc, char **argv) {
	wbArg_t args;
	int *hostInput;  // The input 1D list
	int numElements; // number of elements in the list

	args = wbArg_read(argc, argv);

	wbTime_start(Generic, "Importing data and creating memory on host");
	hostInput = (int*) wbImport(wbArg_getInputFile(args, 0), &numElements, "integral_vector");
	wbTime_stop(Generic, "Importing data and creating memory on host");

	wbLog(TRACE, "The number of input elements in the input is ",
		numElements);

	wbTime_start(Compute, "Performing Sort computation");
	std::sort(hostInput, hostInput + numElements);
	wbTime_stop(Compute, "Performing Sort computation");

	wbSolution(args, hostInput, numElements);

	free(hostInput);

#if LAB_DEBUG
	system("pause");
#endif

	return 0;
}
