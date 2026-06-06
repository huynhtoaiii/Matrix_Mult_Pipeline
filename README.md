# Matrix_Mult_Pipeline
# Matrix_Multiplier_SCA

A 4x4 Matrix Multiplication Accelerator on Xilinx FPGA, comparing Non-Pipeline vs. Pipeline architectures, integrated with simulated Side-Channel Analysis (SCA).

## 🚀 Features
* **Non-Pipeline Core:** Area-optimized (~208 LUTs), 262-cycle latency.
* **Pipeline Core:** Speed-optimized (~5200 LUTs), 4-cycle latency, Fmax @ 152.4 MHz.
* **SCA Evaluation:** Python script to parse `.vcd` files, modeling Hamming Distance and performing Welch's T-test (TVLA) for power leakage analysis.

## 🛠️ Tech Stack
* **Hardware:** Verilog, Xilinx Vivado (Target: Nexys A7).
* **Security Analysis:** Python (NumPy, PyVCD, Matplotlib).
