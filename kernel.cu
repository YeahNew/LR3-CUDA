#include <stdlib.h>
#include <stdio.h>
#include <cuda.h>
#include <math.h>
#include <time.h>
#include <curand_kernel.h>

#define N 1024
#define BLOCKS 256
#define THREADS 256


__global__ void gpuPiCalculate(float* estimate, curandState* states) {
	unsigned long id = threadIdx.x + blockDim.x * blockIdx.x;
	int V = 0;
	float x, y;

	curand_init(id, id, 0, &states[id]);  //initialize curand

	for (int i = 0; i < N; i++) {
		x = curand_uniform(&states[id]);
		y = curand_uniform(&states[id]);
		V += (x * x + y * y <= 1.0f);
	}
	estimate[id] = 4.0f * V / (float)N;
}

float cpuPiCalculate(long n) {
	float x, y;
	long V = 0;
	for (long i = 0; i < n; i++) {
		x = rand() / (float)RAND_MAX;
		y = rand() / (float)RAND_MAX;
		V += (x * x + y * y <= 1.0f);
	}
	return 4.0f * V / n;
}

int main(int argc, char* argv[]) {
	clock_t start, stop;
	float host[BLOCKS * THREADS];
	float* dev;
	curandState* devStates;

	//Calc pi on GPu
	start = clock();
	cudaMalloc((void**)&dev, BLOCKS * THREADS * sizeof(float));
	cudaMalloc((void**)&devStates, THREADS * BLOCKS * sizeof(curandState));

	gpuPiCalculate << <BLOCKS, THREADS >> > (dev, devStates);

	cudaMemcpy(host, dev, BLOCKS * THREADS * sizeof(float), cudaMemcpyDeviceToHost);
	float gpuPI = 0;
	for (int i = 0; i < BLOCKS * THREADS; i++) {
		gpuPI += host[i];
	}
	gpuPI /= (BLOCKS * THREADS);
	stop = clock();

	printf("GPU PI= %f\n", gpuPI);
	printf("GPU Estimate time %f s.\n", (stop - start) / (float)CLOCKS_PER_SEC);
	
	//Calc pi on CPU
	start = clock();
	float cpuPI = cpuPiCalculate(BLOCKS * THREADS * N);
	stop = clock();
	printf("CPU PI= %f\n", cpuPI);
	printf("CPU Estimate time %f s.\n", (stop - start) / (float)CLOCKS_PER_SEC);

	return 0;
}
