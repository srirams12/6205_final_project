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

def difference_function(signal, max_lag):
    diff = np.zeros(max_lag)
    for t in range(1, max_lag):
        diff[t] = np.sum((signal[:-t] - signal[t:]) ** 2)
    return diff

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


# sine wave
frequency = 300
sample_rate = 16000
amplitude = 127
t = np.linspace(0, 1, sample_rate, endpoint=False)
t = t[:1000]
sine_wave = amplitude * (np.sin(2 * np.pi * frequency * t) + 1)
# sine_wave = np.clip(sine_wave, -255, 255)

# singing C
# sample_rate, signal = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/final_project_files/sim/c_sing.wav')
# signal = signal[30000:30500]

sample_rate, signal = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/final_project_files/sim/scale_actual.wav')
signal_c = signal[29400:30400]
signal_d = signal[44000:45000]
signal_e = signal[58000:59000]
signal_f = signal[72000:73000]
signal_g = signal[86000:87000]
signal_a = signal[100000:101000]
signal_b = signal[113200:114200]
signal_c_high = signal[133000:134000]

signals = [signal_c, signal_d, signal_e, signal_f, signal_g, signal_a, signal_b, signal_c_high]

sample_rate, signal_actual = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/final_project_files/test_scripts/tones.wav')
print(f'{len(signal_actual)=}')
signal_actual = signal_actual[20000:20500]



# step response
step = [127]
for i in range(255):
    step.append(255)

def convert_to_signed(value):
    if value & (1 << 8):  # MSB is 1, indicating negative number
        # Two's complement conversion to get the signed integer
        return value - (1 << 9)  # Subtract 2^9 to get the negative number
    else:
        return value

# C: 266
# D: 296
# E: 333
# F: 347
# G: 400
# A: 444
# B: 500
# C: 533

@cocotb.test()
async def test_a(dut):
    filtered = []
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    dut.start_computation.value = 0
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    dut.rst_in.value = 0

    # send audio into buffer
    for i in range(len(signal_actual)):
        dut.audio_in.value = int(signal_actual[i])
        dut.audio_in_valid.value = 1

        await ClockCycles(dut.clk_in, 1)
        dut.audio_in_valid.value = 0

        await ClockCycles(dut.clk_in, 30)

    # start computation
    dut.start_computation.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.start_computation.value = 0

    # # get values out of buffer
    filtered = [int(i) for i in dut.my_yinner.sig_buffer.value]
    plt.plot([i for i in range(len(signal_actual))], [int(f) for f in signal_actual])
    plt.show()

    # # wait for computation to be done
    # # await RisingEdge(dut.f_out_valid)
    clock_cycles = 0
    while dut.my_yinner.state.value != 2:
        await ClockCycles(dut.clk_in, 1)
        clock_cycles += 1
    
    taus = []
    sum_df = []
    df_zeros = []
    prods = []
    for tau in range(80):
        await ClockCycles(dut.clk_in, 1)
        taus.append(tau)
        sum_df.append(int(dut.my_yinner.diff_sum.value))
        df_zeros.append(int(dut.my_yinner.sum_times_point_one.value))
        prods.append(int(dut.my_yinner.product.value))


    dif_func = [int(i) for i in dut.my_yinner.df_buffer.value]

    # cmndf = [dif_func[i] * i / sum_df[i] for i in range(2, 80)]


    # tau_final = int(dut.tau_final.value)
    # print(f'{tau_final=}')


    # actual_dif_func = difference_function(np.array(filtered), 80)

    # plt.plot([i for i in range(len(cmndf))], cmndf)
    # plt.show()

    # print(f'{cmndf[20]=}')

    # print(f'{[sum_df[i]/df_zeros[i] for i in range(3, 10)]=}')
    plt.plot(taus[0:], df_zeros)
    plt.plot(taus[0:], prods)

    plt.show()

    await ClockCycles(dut.clk_in, 5000)

    print(f'{clock_cycles+500=}')




def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    source_files = ['yinner.sv', 'divider.sv', 'audio_processing.sv', 'bandpass.sv']
    sources = [proj_path / "hdl" / file for file in source_files ]
    build_test_args = ["-Wall"]
    parameters = {'WINDOW_SIZE': 500} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="audio_processing",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="audio_processing",
        test_module="test_audio_processing",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()