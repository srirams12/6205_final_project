module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/sriram/Documents/digital_systems/final_project/final_project_files/sim/sim_build/audio_processing.fst");
    $dumpvars(0, audio_processing);
end
endmodule
