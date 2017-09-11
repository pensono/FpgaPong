// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground);
input clk;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

hvsync_generator syncgen(.clk(clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

// Draw a border around the screen
wire R = (CounterY[3] | (CounterX==256));
//wire G = 0; //(CounterX[5] ^ CounterX[6]) | (CounterX==256)
wire B = (CounterX[4] | (CounterX==256));
//wire R = 1;
wire G = 1;
//wire B = 1;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

reg [23:0] cnt;
always @(posedge clk) cnt <= cnt + 24'd1;

assign test = cnt[22];
assign testGround = 0;

assign ground = 0;

endmodule
