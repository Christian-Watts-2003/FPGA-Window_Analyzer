// Christian Watts 12196341
// d_low = 1 (primary = max), d_high = 4 (secondary = max-min)

`timescale 1ns/1ps

module window_analyzer(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic din_valid,
    input  logic [7:0] din,
    output logic [7:0] dout,
    output logic       dout_valid,
    output logic       busy,
    output logic       done
);

    logic [7:0] sample_mem [0:15];
    logic [4:0] length_reg;
    logic [4:0] wr_idx;
    logic [4:0] rd_idx;
    logic [7:0] max_reg;
    logic [7:0] min_reg;

    typedef enum logic [2:0] {
        IDLE,
        COLLECT,
        COMPUTE_PRIMARY,
        COMPUTE_SECONDARY,
        OUTPUT_PRIMARY,
        OUTPUT_SECONDARY
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            length_reg <= 0;
            wr_idx     <= 0;
            rd_idx     <= 0;
            max_reg    <= 0;
            min_reg    <= 8'hFF;
            dout       <= 0;
            dout_valid <= 0;
            done       <= 0;
            busy       <= 0;
        end else begin
            dout_valid <= 0;
            done       <= 0;

            case (state)
                IDLE: begin
                    busy <= 0;
                    if (start && din_valid) begin
                        length_reg <= din[3:0];
                        wr_idx     <= 0;
                        busy       <= 1;
                    end
                end

                COLLECT: begin
                    if (din_valid && wr_idx < length_reg) begin
                        sample_mem[wr_idx] <= din;
                        wr_idx <= wr_idx + 1;
                    end
                    
                    if (wr_idx == length_reg) begin
                        rd_idx  <= 0;
                        max_reg <= 0;
                    end
                end

                COMPUTE_PRIMARY: begin
                    if (rd_idx < length_reg) begin
                        if (rd_idx == 0 || sample_mem[rd_idx] > max_reg)
                            max_reg <= sample_mem[rd_idx];
                        rd_idx <= rd_idx + 1;
                    end
                    
                    if (rd_idx == length_reg) begin
                        rd_idx  <= 0;
                        min_reg <= 8'hFF;
                    end
                end

                COMPUTE_SECONDARY: begin
                    if (rd_idx < length_reg) begin
                        if (rd_idx == 0 || sample_mem[rd_idx] < min_reg)
                            min_reg <= sample_mem[rd_idx];
                        rd_idx <= rd_idx + 1;
                    end
                end

                OUTPUT_PRIMARY: begin
                    dout       <= max_reg;
                    dout_valid <= 1;
                end

                OUTPUT_SECONDARY: begin
                    dout       <= (max_reg - min_reg) & 8'hFF;
                    dout_valid <= 1;
                    done       <= 1;
                    busy       <= 0;
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;

        case (state)
            IDLE:
                if (start && din_valid)
                    next_state = COLLECT;

            COLLECT:
                if (wr_idx == length_reg)
                    next_state = COMPUTE_PRIMARY;

            COMPUTE_PRIMARY:
                if (rd_idx == length_reg)
                    next_state = COMPUTE_SECONDARY;

            COMPUTE_SECONDARY:
                if (rd_idx == length_reg)
                    next_state = OUTPUT_PRIMARY;

            OUTPUT_PRIMARY:
                next_state = OUTPUT_SECONDARY;

            OUTPUT_SECONDARY:
                next_state = IDLE;
        endcase
    end

endmodule