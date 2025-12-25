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
wire [TAGLENGTH-1:0]   tag   = cpu_addr[ADDRESSLENGTH-1 -: TAGLENGTH];
wire [INDEXLENGTH-1:0] index = cpu_addr[OFFSETLENGTH +: INDEXLENGTH];

    wire [31:0] cache_rdata;
    wire [31:0] ram_rdata;
    wire        hit;
reg [31:0] ram_rdata_reg;
    reg ram_re, ram_we;
    reg loade;

    /* ---------------- FSM ---------------- */
    localparam IDLE = 3'd0,
               RAM_WAIT = 3'd1,
               LOAD1 = 3'd2,
               LOAD2 = 3'd3,
               DONE = 3'd4;
    reg [2:0] state, next_state;

    /* ---------------- Cache Instance ---------------- */
    Cache cache_inst (
        .clk(clk),
        .tag(tag),
        .index(index),
        .reset(reset),
        .we(cpu_we),
        .re(cpu_re),
        .datain(loade ? ram_rdata_reg : cpu_wdata),
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
        .WE(ram_we),
        .reset(reset)
    );

    /* ---------------- State Register ---------------- */
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    /* ---------------- FSM Logic ---------------- */

    //next state logic
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
                next_state = LOAD1;
            end

            LOAD1: begin
                next_state = LOAD2;
            end
            LOAD2: begin
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
            ram_rdata_reg <= 0;

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
                RAM_WAIT: begin
                    ram_re <= 1;
                end

                LOAD1: begin
                    ram_rdata_reg <= ram_rdata; 
                end
                LOAD2: begin
                    loade <= 1;

                    end

                DONE: begin
                    cpu_rdata <= hit ? cache_rdata : ram_rdata_reg;
                    ready <= 1;
                end
            endcase
        end
    end

endmodule
