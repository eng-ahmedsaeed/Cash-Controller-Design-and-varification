module cache_controller (
    input  wire        clk,
    input  wire        reset,

    input  wire        cpu_re,
    input  wire        cpu_we,
    input  wire [15:0] cpu_addr,
    input  wire [31:0] cpu_wdata,

    output reg  [31:0] cpu_rdata,
    output reg         ready
);

    /* ---------------- Parameters ---------------- */
    parameter ADDRESSLENGTH = 16;
    parameter DATALENGTH    = 32;
    parameter CASHENTRIES   = 256;
    parameter WAYS          = 4;
    parameter BLOCKSIZE     = 32;

    localparam NUM_SETS     = CASHENTRIES / WAYS;
    localparam INDEXLENGTH  = $clog2(NUM_SETS);
    localparam OFFSETLENGTH = $clog2(BLOCKSIZE / 8);
    localparam TAGLENGTH    = ADDRESSLENGTH - INDEXLENGTH - OFFSETLENGTH;

    /* ---------------- Wires ---------------- */
    wire [TAGLENGTH-1:0]   tag   = cpu_addr[15 -: TAGLENGTH];
    wire [INDEXLENGTH-1:0] index = cpu_addr[OFFSETLENGTH +: INDEXLENGTH];

    wire [31:0] cache_rdata;
    wire [31:0] ram_rdata;
    wire        hit;

    reg ram_re, ram_we;
    reg loade;

    /* ---------------- FSM ---------------- */
    localparam IDLE = 2'd0,
               RAM_WAIT = 2'd1,
               LOAD = 2'd2,
               DONE = 2'd3;

    reg [1:0] state, next_state;

    /* ---------------- Cache Instance ---------------- */
    Cache cache_inst (
        .clk(clk),
        .tag(tag),
        .index(index),
        .reset(reset),
        .we(cpu_we),
        .re(cpu_re),
        .datain(ram_rdata),
        .dataout(cache_rdata),
        .hit(hit),
        .loade(loade)
    );

    /* ---------------- RAM Instance ---------------- */
    RAM ram_inst (
        .clk(clk),
        .addr(cpu_addr),
        .datain(cpu_wdata),
        .dataout(ram_rdata),
        .RE(ram_re),
        .WE(ram_we)
    );

    /* ---------------- State Register ---------------- */
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    /* ---------------- FSM Logic ---------------- */
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (cpu_re && !hit)
                    next_state = RAM_WAIT;
                else if (cpu_re && hit)
                    next_state = DONE;
                else if (cpu_we)
                    next_state = DONE;
            end

            RAM_WAIT: begin
                next_state = LOAD;
            end

            LOAD: begin
                next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    /* ---------------- Output Logic ---------------- */
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ready     <= 0;
            cpu_rdata <= 0;
            ram_re    <= 0;
            ram_we    <= 0;
            loade     <= 0;
        end else begin
            ready  <= 0;
            ram_re <= 0;
            ram_we <= 0;
            loade  <= 0;

            case (state)
                IDLE: begin
                    if (cpu_re && !hit)
                        ram_re <= 1;
                    if (cpu_we)
                        ram_we <= 1;
                end

                LOAD: begin
                    loade <= 1;
                end

                DONE: begin
                    cpu_rdata <= hit ? cache_rdata : ram_rdata;
                    ready <= 1;
                end
            endcase
        end
    end

endmodule
