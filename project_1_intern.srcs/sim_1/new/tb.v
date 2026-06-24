`timescale 1ns / 1ps

module tb_freezer_controller;
    reg clk, 
    reg raw_rst, 
    reg raw_door,
    reg raw_gas;
    reg signed [7:0] current_temp;

    wire compressor_relay, main_alarm, err_door_open, err_comp_fail, err_overheat, err_overcool, err_gas_leak;

    final_industrial_freezer #(
        .MAX_COOLING_TIME(32'd50), 
        .MAX_DOOR_TIME(32'd30),    
        .COMP_DELAY(32'd20)        
    ) uut (.*);

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (raw_rst) current_temp <= 8'd0;
        else if (!compressor_relay) current_temp <= current_temp - 1;
        else if (current_temp < 8'd0) current_temp <= current_temp + 1;
    end

    initial begin
        clk = 0; raw_rst = 1; current_temp = 0; raw_door = 0; raw_gas = 0;
        #20 raw_rst = 0;
        #50 current_temp = -10; 
        #200 raw_door = 1;      
        #100 raw_gas = 1;       
        #200 $finish;
    end
endmodule