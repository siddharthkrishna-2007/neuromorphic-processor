module lif_neuron (
    input clk,
    input rst,

    input spike_in,
    input signed [7:0] weight,      // wire and not parameter as if we wanna use for SNN purposes then the weight for different neurons while scaling should be variable
    input signed [7:0] threshold,   // same idea as weight
    input signed [7:0] leak,        // also same idea
    input [3:0] refractory_cycles,

    output reg spike_out
);

    // State
    reg signed [7:0] membrane;
    reg signed [7:0] next_membrane;
    reg [3:0] refractory;

    // Combinational: next state
    always @(*) begin
        // leak
        next_membrane = membrane - leak;

        // integrate spike
        if (spike_in)
            next_membrane = next_membrane + weight;

        // clamp to 0 as resting potential so it doesnt go to negative voltage on leak
        if (next_membrane < 0)
            next_membrane = 0;
    end

    // Sequential: state update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            membrane   <= 0;
            spike_out  <= 0;
            refractory <= 0;
        end else begin
            // default: spike is a 1-cycle pulse
            spike_out <= 0;

            // Refractory period
            if (refractory != 0) begin
                refractory <= refractory - 1;
                // hold membrane at reset
                membrane <= 0;
            end
            else begin
                // Threshold check
                if (next_membrane >= threshold) begin
                    spike_out  <= 1;
                    membrane   <= 0;
                    refractory <= refractory_cycles;
                end
                else begin
                    membrane <= next_membrane;
                end
            end
        end
    end

endmodule