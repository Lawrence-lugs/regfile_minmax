// Parameterizable multi-port register file — flat (no banking).
//
// All write ports share the same flip-flop array; write priority is given to
// the highest-indexed port on a conflict (last write wins).
// All read ports are asynchronous (combinational mux from the FF array).
//
// Parameters:
//   NUM_RD_PORTS — number of simultaneous read ports
//   NUM_WR_PORTS — number of simultaneous write ports
//   BITWIDTH     — data width of each register (bits)
//   NUM_REGS     — number of registers (need not be a power of 2)

`default_nettype none

module regfile #(
    parameter int NUM_RD_PORTS = 2,
    parameter int NUM_WR_PORTS = 1,
    parameter int BITWIDTH     = 32,
    parameter int NUM_REGS     = 32
)(
    input  logic clk,
    input  logic rst_n,

    // Write ports (synchronous, active-high enable)
    input  logic [NUM_WR_PORTS-1:0]                          wr_en,
    input  logic [NUM_WR_PORTS-1:0][$clog2(NUM_REGS)-1:0]   wr_addr,
    input  logic [NUM_WR_PORTS-1:0][BITWIDTH-1:0]            wr_data,

    // Read ports (asynchronous / combinational)
    input  logic [NUM_RD_PORTS-1:0][$clog2(NUM_REGS)-1:0]   rd_addr,
    output logic [NUM_RD_PORTS-1:0][BITWIDTH-1:0]            rd_data
);

    logic [NUM_REGS-1:0][BITWIDTH-1:0] mem;

    // Synchronous write — higher port index wins on address collision
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_REGS; i++) mem[i] <= '0;
        end else begin
            for (int w = 0; w < NUM_WR_PORTS; w++) begin
                if (wr_en[w]) mem[wr_addr[w]] <= wr_data[w];
            end
        end
    end

    // Asynchronous read
    always_comb begin
        for (int r = 0; r < NUM_RD_PORTS; r++) begin
            rd_data[r] = mem[rd_addr[r]];
        end
    end

endmodule

`default_nettype wire
