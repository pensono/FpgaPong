// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground, buttonLeft, buttonRight);
input clk,buttonLeft,buttonRight;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [8:0] location;

hvsync_generator syncgen(.clk(clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
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

reg [23:0] cnt;
always @(posedge clk) cnt <= cnt + 24'd1;

assign leftPressed = ~buttonLeft; // Buttons are NC
assign rightPressed = ~buttonRight;
always @(posedge cnt[20])
begin
	if (leftPressed| rightPressed) begin
		if (leftPressed)
			location <= location + 1;
		else
			location <= location - 1;
	end
end

assign test = cnt[22];
assign testGround = 0;

assign ground = 0;

endmodule
