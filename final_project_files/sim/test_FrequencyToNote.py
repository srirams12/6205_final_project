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
import time

@cocotb.test()
async def test_a(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    base_frequencies = [0 for _ in range(100)]
    base_frequencies[0]  = 262
    base_frequencies[1]  = 294
    base_frequencies[2]  = 330 
    base_frequencies[3]  = 349 
    base_frequencies[4]  = 392
    base_frequencies[5]  = 440 
    base_frequencies[6]  = 494
    base_frequencies[7]  = 523 
    # base_frequencies[8]  = 349 
    # base_frequencies[9]  = 370
    # base_frequencies[10]  = 392 
    # base_frequencies[11]  = 415
    # base_frequencies[12]  = 440
    # base_frequencies[13]  = 466
    # base_frequencies[14]  = 494
    # base_frequencies[15]  = 523
    # base_frequencies[16]  = 554
    # base_frequencies[17]  = 587
    # base_frequencies[18]  = 622
    # base_frequencies[19]  = 659
    # base_frequencies[20]  = 698 
    # base_frequencies[21]  = 740
    # base_frequencies[22] = 784 
    # base_frequencies[23] = 831
    # base_frequencies[24]  = 880 
    # base_frequencies[25]  = 932
    # base_frequencies[26]  = 988 

    for i in base_frequencies:
        dut.frequency.value = i
        await Timer(20, units="ns")

    

    


def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    source_files = ['FrequencyToNote.sv']
    sources = [proj_path / "hdl" / file for file in source_files ]
    build_test_args = ["-Wall"]
    parameters = {} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="FrequencyToNote",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="FrequencyToNote",
        test_module="test_FrequencyToNote",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()