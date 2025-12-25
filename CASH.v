module Cache (
    clk,
    tag,
    index,
    hit,
    dataout,
    datain,
    reset,
    we,
    re,
    loade
);


  parameter CASHENTRIES = 256;
  parameter WAYS = 4;
  parameter DATALENGTH = 32;
  parameter TAGLENGTH = 8;
  parameter LRULENGTH = 32;

  localparam INDEXLENGTH = $clog2(CASHENTRIES / WAYS);
  localparam NUM_SETS = CASHENTRIES / WAYS;


  input wire clk;

  input wire [TAGLENGTH-1:0] tag;
  input wire [INDEXLENGTH-1:0] index;
  input wire reset;
  input wire we;
  input wire re;
  input wire [DATALENGTH-1:0] datain;

  output reg [DATALENGTH-1:0] dataout;
  output reg hit;
  input wire loade;

  integer i, j;


  reg     [DATALENGTH-1:0] Data         [0:NUM_SETS-1][0:WAYS-1];
  reg     [ TAGLENGTH-1:0] Tag          [0:NUM_SETS-1][0:WAYS-1];
  reg                      Valid        [0:NUM_SETS-1][0:WAYS-1];
  reg     [ LRULENGTH-1:0] LRUcounter   [0:NUM_SETS-1][0:WAYS-1];



  integer                  selected_way;
  reg                      found_place;
  reg     [ LRULENGTH-1:0] min_lru;


  always @(posedge clk or posedge reset) begin

    if (reset) begin
      hit     <= 0;
      dataout <= 0;

      for (j = 0; j < NUM_SETS; j = j + 1) begin
        for (i = 0; i < WAYS; i = i + 1) begin
          Valid[j][i]      <= 0;
          LRUcounter[j][i] <= 0;
        end
      end
    end else if (re) begin
      hit <= 0;

      for (i = 0; i < WAYS; i = i + 1) begin
        if (Valid[index][i] && Tag[index][i] == tag) begin
          hit                  <= 1;
          dataout              <= Data[index][i];
          LRUcounter[index][i] <= LRUcounter[index][i] + 1;
        end
      end
    end else if (we) begin

      hit <= 0;

      for (i = 0; i < WAYS; i = i + 1) begin
        if (Valid[index][i] && Tag[index][i] == tag) begin
          hit                  <= 1;
          Data[index][i]       <= datain;
          LRUcounter[index][i] <= LRUcounter[index][i] + 1;
        end
      end
    end else if (loade) begin
      // Load data from memory into cache
 //here i have done some search and found the synthisize tool treat them as temporary variable and replace them by compartor in real hardware
      found_place = 0;
      selected_way = 0;
      hit <= 0;
///here i consider in scenrio of trying to load data that is already in cache
      for (i = 0; i < WAYS; i = i + 1) begin
        if (!Valid[index][i] && !found_place) begin
          selected_way = i;
          found_place  = 1;
        end
      end
      if (!found_place) begin
        min_lru = LRUcounter[index][0];
        selected_way = 0;

        for (i = 1; i < WAYS; i = i + 1) begin
          if (LRUcounter[index][i] < min_lru) begin
            min_lru = LRUcounter[index][i];
            selected_way = i;
          end
        end
      end
///here i considere that if  i loaded the data then gone to do some tasks if LRU is set to zero it will replace that data first and this wrong 
      Data[index][selected_way] <= datain;
      Tag[index][selected_way] <= tag;
      Valid[index][selected_way] <= 1'b1;
      LRUcounter[index][selected_way] <= LRUcounter[index][selected_way] + 1;
    end








  end


endmodule
