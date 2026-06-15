// Christian Watts 12196341
// d_low = 1 (primary = max), d_high = 4 (secondary = max-min)

`timescale 1ns/1ps

module tb_window_analyzer;

    logic clk;
    logic rst;
    logic start;
    logic din_valid;
    logic [7:0] din;
    logic [7:0] dout;
    logic       dout_valid;
    logic       busy;
    logic       done;
    logic [7:0] frame1 [0:4];
    logic [7:0] frame2 [0:0];
    logic [7:0] frame3 [0:6];
    logic [7:0] frame4 [0:6];
    logic [7:0] frame5 [0:6];
    logic [7:0] frame6 [0:14];

    logic [7:0] last_primary;
    logic [7:0] last_secondary;
    int result_count;

    window_analyzer DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .din_valid(din_valid),
        .din(din),
        .dout(dout),
        .dout_valid(dout_valid),
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (dout_valid) begin
            $display("OUTPUT: dout=%0d", dout);
            result_count++;

            if (result_count == 1)
                last_primary = dout;
            else if (result_count == 2)
                last_secondary = dout;
        end
    end

    task automatic print_frame_summary(input int L, input logic [7:0] samples[]);
        int i;
        logic [7:0] max_v, min_v, range_v;

        max_v = samples[0];
        min_v = samples[0];

        for (i = 1; i < L; i++) begin
            if (samples[i] > max_v) max_v = samples[i];
            if (samples[i] < min_v) min_v = samples[i];
        end

        range_v = (max_v - min_v) & 8'hFF;

        $display("\nVariables");
        $display("L = %0d", L);
        $write("Samples: ");
        for (i = 0; i < L; i++)
            $write("%0d ", samples[i]);
        $write("\n");
        $display("Expected MAX = %0d", max_v);
        $display("Expected MIN = %0d", min_v);
        $display("Expected MAX-MIN = %0d", range_v);
        $display("DUT primary result = %0d", last_primary);
        $display("DUT secondary result = %0d", last_secondary);
        
        if (last_primary == max_v && last_secondary == range_v)
            $display("PASS\n");
        else
            $display("FAIL\n");
    endtask

    task automatic send_frame(input int L, input logic [7:0] samples []);
        int i;
        
        start     = 1;
        din_valid = 1;
        din       = L;

        @(posedge clk);
        #1;
        start = 0;

        for (i = 0; i < L; i++) begin
            din = samples[i];
            din_valid = 1;
            @(posedge clk);
            #1;
        end

        din_valid = 0;
        din = 0;
    endtask

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        din_valid = 0;
        din = 0;

        frame1 = '{50, 50, 50, 50, 50};
        frame2 = '{128};
        frame3 = '{200, 150, 100, 50, 0, 255, 255};
        frame4 = '{1, 2, 3, 4, 5, 6, 7};
        frame5 = '{255, 200, 150, 100, 50, 25, 0};
        frame6 = '{5, 100, 200, 7, 255, 0, 80, 90, 33, 17, 250, 249, 1, 2, 3};

        repeat (3) @(posedge clk);
        rst = 0;
        repeat (3) @(posedge clk);

        $display("\nFrame 1\n");
        send_frame(5, frame1);
        wait(done);
        @(posedge clk);
        print_frame_summary(5, frame1);
        result_count = 0;
        repeat (2) @(posedge clk);

        $display("\nFrame 2\n");
        send_frame(1, frame2);
        wait(done);
        @(posedge clk);
        print_frame_summary(1, frame2);
        result_count = 0;
        repeat (2) @(posedge clk);

        $display("\nFrame 3\n");
        send_frame(7, frame3);
        wait(done);
        @(posedge clk);
        print_frame_summary(7, frame3);
        result_count = 0;
        repeat (2) @(posedge clk);

        $display("\nFrame 4\n");
        send_frame(7, frame4);
        wait(done);
        @(posedge clk);
        print_frame_summary(7, frame4);
        result_count = 0;
        repeat (2) @(posedge clk);

        $display("\nFrame 5\n");
        send_frame(7, frame5);
        wait(done);
        @(posedge clk);
        print_frame_summary(7, frame5);
        result_count = 0;
        repeat (2) @(posedge clk);

        $display("\nFrame 6\n");
        send_frame(15, frame6);
        wait(done);
        @(posedge clk);
        print_frame_summary(15, frame6);
        result_count = 0;

        $display("\nALL DONE! HOORAY!\n");

        #50 $finish;
    end

    initial begin
        #5000;
        $display("\nERROR: Simulation timeout");
        $finish;
    end

endmodule