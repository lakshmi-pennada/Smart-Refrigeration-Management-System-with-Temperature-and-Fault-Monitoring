`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.05.2026 20:54:02
// Design Name: 
// Module Name: Logic_gates
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module advanced_freezer_controller #(
    parameter signed [7:0] TARGET_LOW = -8'd20,
    parameter signed [7:0] TARGET_HIGH = -8'd18,
    parameter signed [7:0] CRITICAL_HOT = 8'd0,
    parameter signed [7:0] CRITICAL_COLD = -8'd30,
    parameter [31:0] MAX_COOLING_TIME = 32'd5000000,
    parameter [31:0] MAX_DOOR_TIME = 32'd2000000,
    parameter [31:0] COMP_DELAY = 32'd5000000
) (
    input wire clk, 
    input wire raw_rst,
    input wire signed [7:0] current_temp, 
    input wire raw_door, raw_gas,
    
    output reg compressor_relay, 
    output reg main_alarm,
    output reg err_door_open,
    output reg err_comp_fail,
    output reg err_overheat,
    output reg err_overcool,
    output reg err_gas_leak
);

    reg [2:0] door_s, gas_s;
    reg state; // 0: OFF, 1: ON
    reg [31:0] comp_timer, door_timer, delay_cnt;
    localparam COMP_OFF = 1'b0, COMP_ON = 1'b1;

    always @(posedge clk or posedge raw_rst) begin
        if (raw_rst) begin
            state <= COMP_OFF; compressor_relay <= 1'b1; main_alarm <= 1'b0;
            comp_timer <= 0; door_timer <= 0; delay_cnt <= 0;
            err_door_open <= 0; err_comp_fail <= 0; err_overheat <= 0;
            err_overcool <= 0; err_gas_leak <= 0;
            door_s <= 0; gas_s <= 0;
        end else begin
            // Input Synchronization
            door_s <= {door_s[1:0], raw_door};
            gas_s  <= {gas_s[1:0], raw_gas};
            
            // Error Detection
            err_gas_leak  <= gas_s[2];
            err_overheat  <= (current_temp >= CRITICAL_HOT);
            err_overcool  <= (current_temp <= CRITICAL_COLD);
            
            if (door_s[2]) begin
                if (door_timer < MAX_DOOR_TIME) door_timer <= door_timer + 1;
                else err_door_open <= 1;
            end else begin
                door_timer <= 0; err_door_open <= 0;
            end

            // Main Alarm Logic
            main_alarm <= (gas_s[2] | err_door_open | err_overheat | err_overcool | err_comp_fail);

            // Compressor FSM
            if (delay_cnt > 0) delay_cnt <= delay_cnt - 1;
            
            if (gas_s[2]) begin
                state <= COMP_OFF; compressor_relay <= 1'b1;
            end else begin
                case (state)
                    COMP_OFF: begin
                        comp_timer <= 0;
                        if (current_temp >= TARGET_HIGH && delay_cnt == 0) begin
                            state <= COMP_ON; compressor_relay <= 1'b0;
                        end
                    end
                    COMP_ON: begin
                        comp_timer <= comp_timer + 1;
                        if (current_temp <= TARGET_LOW) begin
                            state <= COMP_OFF; compressor_relay <= 1'b1; delay_cnt <= COMP_DELAY;
                        end else if (comp_timer >= MAX_COOLING_TIME) begin
                            err_comp_fail <= 1; state <= COMP_OFF; compressor_relay <= 1'b1;
                        end
                    end
                endcase
            end
        end
    end
endmodule