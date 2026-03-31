// Banked register file — read-port banking to reduce mux fanout.
//
// Banking strategy:
//   - NUM_BANKS identical sub-banks are instantiated, each a full copy of the
//     register array (all NUM_REGS registers, all NUM_WR_PORTS write ports).
//   - Read ports are split evenly across banks: each bank serves
//     NUM_RD_PORTS/NUM_BANKS read ports.
//   - All write ports are broadcast (duplicated) to every bank.
//
// Trade-off captured:
//   - More storage (×NUM_BANKS flip-flop area) but smaller mux trees per bank.
//   - When mux area dominates (high port counts) banking can break even or win.
//
// Constraint: NUM_RD_PORTS must be divisible by NUM_BANKS.

`default_nettype none

module regfile_banked #(
    parameter int NUM_RD_PORTS = 4,
    parameter int NUM_WR_PORTS = 1,
    parameter int BITWIDTH     = 32,
    parameter int NUM_REGS     = 32,
    parameter int NUM_BANKS    = 2
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [NUM_WR_PORTS-1:0]                          wr_en,
    input  logic [NUM_WR_PORTS-1:0][$clog2(NUM_REGS)-1:0]   wr_addr,
    input  logic [NUM_WR_PORTS-1:0][BITWIDTH-1:0]            wr_data,

    input  logic [NUM_RD_PORTS-1:0][$clog2(NUM_REGS)-1:0]   rd_addr,
    output logic [NUM_RD_PORTS-1:0][BITWIDTH-1:0]            rd_data
);

    localparam int RD_PER_BANK = NUM_RD_PORTS / NUM_BANKS;

    // Declare the intermediate array at module scope so yosys can resolve
    // its dimensions statically — avoids "Failed to detect width" on
    // generate-local wires.
    logic [NUM_BANKS-1:0][RD_PER_BANK-1:0][BITWIDTH-1:0] all_bank_rd;

    generate
        for (genvar b = 0; b < NUM_BANKS; b++) begin : gen_banks
            regfile #(
                .NUM_RD_PORTS (RD_PER_BANK),
                .NUM_WR_PORTS (NUM_WR_PORTS),
                .BITWIDTH     (BITWIDTH),
                .NUM_REGS     (NUM_REGS)
            ) u_bank (
                .clk     (clk),
                .rst_n   (rst_n),
                .wr_en   (wr_en),
                .wr_addr (wr_addr),
                .wr_data (wr_data),
                .rd_addr (rd_addr [b*RD_PER_BANK +: RD_PER_BANK]),
                .rd_data (all_bank_rd[b])
            );
        end
    endgenerate

    // Flatten the per-bank outputs into the module's read-data port
    always_comb begin
        for (int b = 0; b < NUM_BANKS; b++)
            for (int r = 0; r < RD_PER_BANK; r++)
                rd_data[b*RD_PER_BANK + r] = all_bank_rd[b][r];
    end

endmodule

`default_nettype wire
