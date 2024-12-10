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

@cocotb.test()
async def test_a(dut):
    filtered = []
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    dut.rst_in.value = 0

    plt.plot([int(i) for i in dut.bram.value[4000:4500]])
    plt.show()

    plt.plot([int(i) for i in dut.bram.value[12000:12500]])
    plt.show()

    plt.plot([int(i) for i in dut.bram.value[20000:20500]])
    plt.show()



    # start computation
    dut.start.value = 1
    await ClockCycles(dut.clk_in, 1)
    # dut.start.value = 0

    await ClockCycles(dut.clk_in, 25000)
    plt.plot([int(i) for i in dut.audio_processor.sig_buffer])
    plt.show()

    await ClockCycles(dut.clk_in, 25000)
    plt.plot([int(i) for i in dut.audio_processor.sig_buffer])
    plt.show()

    await ClockCycles(dut.clk_in, 500000)

    notes = dut.results.value
    print(f'{notes=}')



def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    source_files = ['yinner.sv', 'yinner_song.sv', 'divider.sv', 'audio_processing.sv', 'bandpass.sv', 'NoteLoader.sv']
    sources = [proj_path / "hdl" / file for file in source_files ]
    build_test_args = ["-Wall"]
    parameters = {} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="NoteLoader",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="NoteLoader",
        test_module="test_NoteLoader",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()