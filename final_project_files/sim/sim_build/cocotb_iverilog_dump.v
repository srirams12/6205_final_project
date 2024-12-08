module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/sriram/Documents/digital_systems/final_project/final_project_files/sim/sim_build/FrequencyToNote.fst");
    $dumpvars(0, FrequencyToNote);
end
endmodule
