import cocotb
import os
import sys
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
import wave
import numpy as np
from scipy.io import wavfile
import matplotlib.pyplot as plt

def yin(signal, sample_rate, fmin=50, fmax=1500, threshold=0.1):
    """
    Estimate the fundamental frequency (F0) of a signal using the YIN algorithm.

    Parameters:
    - signal: numpy array, the input signal
    - sample_rate: int, the sampling rate of the signal
    - fmin: float, the minimum frequency to search (in Hz)
    - fmax: float, the maximum frequency to search (in Hz)
    - threshold: float, the threshold for the cumulative mean normalized difference

    Returns:
    - f0: float, the estimated fundamental frequency in Hz
    """
    
    # Step 1: Calculate the difference function
    def difference_function(signal, max_lag):
        diff = np.zeros(max_lag)
        for t in range(1, max_lag):
            diff[t] = np.sum((signal[:-t] - signal[t:]) ** 2)
        return diff

    # Step 2: Cumulative mean normalized difference function
    def cumulative_mean_normalized_difference(diff):
        cmndf = np.zeros(len(diff))
        cmndf[0] = 1
        for t in range(1, len(diff)):
            cmndf[t] = diff[t] / ((1 / t) * np.sum(diff[1:t+1])) if diff[t] != 0 else 1
        return cmndf

    # Convert fmin and fmax to lag values
    max_lag = int(sample_rate / fmin)
    min_lag = int(sample_rate / fmax)

    # Compute the difference function and the cumulative mean normalized difference
    diff = difference_function(signal, max_lag)
    cmndf = cumulative_mean_normalized_difference(diff)

    # Step 3: Apply absolute threshold
    below_threshold = np.where(cmndf[min_lag:] < threshold)[0]
    if len(below_threshold) == 0:
        return 0  # No F0 detected

    # Step 4: Find the first dip below the threshold
    lag = below_threshold[0] + min_lag

    # Step 5: Parabolic interpolation around the minimum
    if 1 <= lag < len(cmndf) - 1:
        better_lag = lag + (cmndf[lag - 1] - cmndf[lag + 1]) / (2 * (cmndf[lag - 1] - 2 * cmndf[lag] + cmndf[lag + 1]))
    else:
        better_lag = lag

    # Step 6: Convert lag to frequency
    f0 = sample_rate / better_lag if better_lag > 0 else 0
    return f0


# Parameters
frequency = 300
sample_rate = 8000
amplitude = 127
t = np.linspace(0, 1, sample_rate, endpoint=False)
t = t[:500]
sine_wave = amplitude * (np.sin(2 * np.pi * frequency * t) + 1)

sample_rate, signal = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/test_scripts/c_sing.wav')
signal = signal[20000:20501]
step = [127]
for i in range(255):
    step.append(255)

def convert_to_signed(value):
    if value & (1 << 8):  # MSB is 1, indicating negative number
        # Two's complement conversion to get the signed integer
        return value - (1 << 9)  # Subtract 2^9 to get the negative number
    else:
        return value

@cocotb.test()
async def test_a(dut):
    filtered = []
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    dut.rst_in.value = 0

    for i in range(len(signal)):
        dut.x_in.value = int(signal[i])
        dut.x_in_valid.value = 1

        await ClockCycles(dut.clk_in, 1)
        dut.x_in_valid.value = 0

        await FallingEdge(dut.y_out_valid)
        await ClockCycles(dut.clk_in, 2)
        filtered.append(convert_to_signed(int(dut.y_out.value)))
        # filtered.append(int(dut.y_out.value))

    

    # plt.plot([i for i in range(len(signal))], signal)
    # plt.show()
    print(f'{filtered[:10]=}')
    print(f'{max(filtered)=}')
    print(f'{min(filtered)=}')

    print(f'{yin(np.array(filtered), 8000)=}')
    plt.plot([i for i in range(len(filtered))], [int(f) for f in filtered])
    plt.show()

    # with wave.open('output.wav','wb') as wf:
    #     wf.setframerate(8000)
    #     wf.setnchannels(1)
    #     wf.setsampwidth(1)
    #     # samples = bytearray(filtered)
    #     wf.writeframes(filtered)
    #     print("Recording saved to output.wav")


    # await ClockCycles(dut.clk_in, 30000) #wait a few clock cycles

def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    source_files = ['bandpass.sv']
    sources = [proj_path / "hdl" / file for file in source_files ]
    build_test_args = ["-Wall"]
    parameters = {} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="bandpass",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="bandpass",
        test_module="test_bandpass",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()