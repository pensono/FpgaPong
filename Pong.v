// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground, buttonLeft, buttonRight);

reg [1:0] cnt;
always @(posedge clk) cnt <= cnt + 1;

wire vga_clk;
assign vga_clk = cnt[1];

input clk,buttonLeft,buttonRight;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [8:0] location;

hvsync_generator syncgen(.clk(vga_clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

wire paddle = (location > CounterX) & (location < CounterX + 96) & (CounterY[8:3] == 40);
									 
wire R = CounterX[4] ^ CounterY[3];
wire G = CounterX[6] ^ CounterY[6];
wire B = CounterX[0] ^ CounterY[0];

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

assign leftPressed = ~buttonLeft; // Buttons are NC
assign rightPressed = ~buttonRight;

assign testGround = 0;
assign test = clk;
assign ground = 0;

endmodule
