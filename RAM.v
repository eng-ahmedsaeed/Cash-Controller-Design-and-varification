module RAM (
    clk,
    addr,
    datain,
    dataout,
    RE,
    WE

);
  input wire clk;
  parameter ADDLENGTH = 16;
  parameter DATALENGTH = 32;
  input wire [ADDLENGTH-1:0] addr;
  input wire [DATALENGTH-1:0] datain;
  input wire RE;
  input wire WE;
  output reg [DATALENGTH-1:0] dataout;
  reg [DATALENGTH-1:0] mem[0:ADDLENGTH-1];
initial begin
    $readmemh("ram_init.hex", mem);
end
  always @(posedge clk) begin
    if (WE) begin
      mem[addr] <= datain;
    end
    if (RE) begin
      dataout <= mem[addr];
    end
  end
endmodule
