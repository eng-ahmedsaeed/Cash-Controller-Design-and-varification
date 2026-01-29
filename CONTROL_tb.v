module CONTROL_tb;

    // ---------------- CPU signals ----------------
    reg         clk;
    reg         reset;
    reg         cpu_re;
    reg         cpu_we;
    reg [15:0]  cpu_addr;
    reg [31:0]  cpu_wdata;

    wire [31:0] cpu_rdata;
    wire        ready;

    // ---------------- DUT ----------------
    cache_controller dut (
        .clk(clk),
        .reset(reset),
        .cpu_re(cpu_re),
        .cpu_we(cpu_we),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .ready(ready)
    );

    // ---------------- Clock ----------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 20 ns period
    end

    // ============================================================
    // ======================= TASKS =============================
    // ============================================================

    // -------- READ --------
    task cpu_read(input [15:0] addr);
    begin
        // 1) prepare address
        @(negedge clk);
        cpu_addr = addr;

        // 2) assert read
        @(negedge clk);
        cpu_re = 1'b1;

        // 3) wait for response (ready is asserted on posedge clk)
        @(posedge ready);
        $display("[%0t] READ  addr=%0d | hit=%0d | data=%h",
                  $time, addr, dut.cache_inst.hit, cpu_rdata);

        // 4) deassert read safely
        @(negedge clk);
        cpu_re = 1'b0;

        // 5) separation cycle (VERY IMPORTANT)
        @(negedge clk);
    end
    endtask

    // -------- WRITE --------
    task cpu_write(input [15:0] addr, input [31:0] data);
    begin
        // 1) prepare address + data
        @(negedge clk);
        cpu_addr  = addr;
        cpu_wdata = data;

        // 2) assert write
        @(negedge clk);
        cpu_we = 1'b1;

        // 3) wait for completion
        @(posedge ready);
        $display("[%0t] WRITE addr=%0d | data=%h",
                  $time, addr, data);

        // 4) deassert write safely
        @(negedge clk);
        cpu_we = 1'b0;

        // 5) separation cycle
        @(negedge clk);
    end
    endtask

    // ============================================================
    // ======================= TEST ===============================
    // ============================================================

    initial begin
        // -------- init --------
        reset     = 1;
        cpu_re    = 0;
        cpu_we    = 0;
        cpu_addr  = 0;
        cpu_wdata = 0;

        // hold reset for few cycles
        repeat (2) @(negedge clk);
        reset = 0;

        // -------- test sequence --------
        cpu_read (16'd0);                // MISS
        cpu_read (16'd0);                // HIT

        cpu_read (16'd9);                // MISS
        cpu_read (16'd9);                // HIT

        cpu_write(16'd2, 32'hAAAAAAAA);  // WRITE
        cpu_read (16'd2);   
        #5             // HIT after write

        $display("=================================");
        $display("===== TEST FINISHED CLEANLY =====");
        $display("=================================");
        $stop;
    end

endmodule
