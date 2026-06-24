`timescale 1ns / 1ps

module tb_freezer_controller;
    // 1. Declare inputs as reg and outputs as wire
    reg clk;
    reg raw_rst;
    reg signed [7:0] current_temp;
    reg raw_door;
    reg raw_gas;

    wire compressor_relay;
    wire main_alarm;
    wire err_door_open;
    wire err_comp_fail;
    wire err_overheat;
    wire err_overcool;
    wire err_gas_leak;

    // 2. Instantiate the Unit Under Test (UUT)
    // We override parameters to make the timing-based simulation run quickly
    advanced_freezer_controller #(
        .MAX_COOLING_TIME(32'd50), 
        .MAX_DOOR_TIME(32'd30),    
        .COMP_DELAY(32'd20)        
    ) uut (
        .clk(clk),
        .raw_rst(raw_rst),
        .current_temp(current_temp),
        .raw_door(raw_door),
        .raw_gas(raw_gas),
        .compressor_relay(compressor_relay),
        .main_alarm(main_alarm),
        .err_door_open(err_door_open),
        .err_comp_fail(err_comp_fail),
        .err_overheat(err_overheat),
        .err_overcool(err_overcool),
        .err_gas_leak(err_gas_leak)
    );

    // 3. Clock Generation: Toggles every 5ns for a 100MHz equivalent period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Thermal Feedback Logic (Simulates room temperature changes)
    always @(posedge clk) begin
        if (raw_rst) 
            current_temp <= 8'd0;
        else if (!compressor_relay) // Relay is Active-Low, so 0 = ON
            current_temp <= current_temp - 1; 
        else if (current_temp < 8'd0)
            current_temp <= current_temp + 1;
    end

    // 5. Stimulus Generation
    initial begin
        // Initialize Inputs
        raw_rst = 1;
        current_temp = 8'd0;
        raw_door = 0;
        raw_gas = 0;

        // Release Reset
        #20 raw_rst = 0;

        // Trigger Cooling cycle
        #50 current_temp = -8'd10; 

        // Trigger Door Alarm
        #200 raw_door = 1;

        // Trigger Gas Leak
        #100 raw_gas = 1;
        
        #200 $finish;
    end

endmodule