module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/sriram/Documents/digital_systems/final_project/final_project_files/sim/sim_build/NoteLoader.fst");
    $dumpvars(0, NoteLoader);
end
endmodule
