module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/sriram/Documents/digital_systems/final_project/final_project_files/sim/sim_build/bandpass.fst");
    $dumpvars(0, bandpass);
end
endmodule
