`timescale 1ns/1ps

module lif_neuron_tb;

// Inputs
reg clk;
reg rst;
reg spike_in;
reg signed [7:0] weight;
reg signed [7:0] threshold;
reg signed [7:0] leak;
reg [3:0] refractory_cycles;

// Output
wire spike_out;

// Instantiate neuron module
lif_neuron uut (
    .clk(clk),
    .rst(rst),
    .spike_in(spike_in),
    .weight(weight),
    .threshold(threshold),
    .leak(leak),
    .refractory_cycles(refractory_cycles),
    .spike_out(spike_out)
);

// Clock: 10ns period
always #5 clk = ~clk;


// Spike generator
task send_spike;
begin
    @(posedge clk);
    spike_in = 1;

    @(posedge clk);
    spike_in = 0;
end
endtask


// Simulation
initial begin
    // Dump waveform
    $dumpfile("lif_neuron.vcd");
    $dumpvars(0, lif_neuron_tb);

    // Init
    clk = 0;
    rst = 1;
    spike_in = 0;

    weight    = 8'sd5;
    threshold = 8'sd10;
    leak      = 8'sd1;
    refractory_cycles = 4;

    // Reset for a few cycles
    repeat (3) @(posedge clk);
    rst = 0;

    // Test 1: Single spike
    send_spike();   // membrane value should increase by 5 but leak occurs simultaneously so membrane increases by 5-1 = 4
    repeat (3) @(posedge clk); // allow leak

    // Test 2: Multiple spikes and trigger firing
    send_spike();   // +4 -> 4
    send_spike();   // +4 -> 8 is what should happen but according to the definition of send_spike() it goes to 1 on rising edge of clock cycle N and 0 on rising edge of clock cycle N+1 this one more leak occurs before the next send_spike() thus +4-1 -> 7
    send_spike();   // +4-1 -> 10 which is equal to the threshold so it spikes and the value of membrane goes to 0
    send_spike();   // nothing happens as during refractory period
    
    // Wait (refractory) 
    repeat (6) @(posedge clk);

    // Test 3: Spike after refractory
    send_spike();
    send_spike();

    repeat (10) @(posedge clk);

    $finish;
end


// Debug print on terminal
always @(posedge clk) begin
    $display("t=%0t | spike_in=%b | membrane=%0d | spike_out=%b",
             $time, spike_in, uut.membrane, spike_out);
end

endmodule