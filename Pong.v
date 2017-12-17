// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground, buttonLeft, buttonRight);

reg [14:0] cnt;
always @(posedge clk) cnt <= cnt + 1;

wire vga_clk;
assign vga_clk = cnt[1];

wire game_clk;
assign game_clk = cnt[14];

input clk,buttonLeft,buttonRight;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [15:0] location;
reg [5:0] speed;

hvsync_generator syncgen(.clk(vga_clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

wire paddle = (CounterX > location[15:6]) & (CounterX < location[15:6] + 48) & (CounterY[8:3] == 56);
									 
wire R = paddle; //CounterX[4] ^ CounterY[3];
wire G = paddle; //CounterX[6] ^ CounterY[6];
wire B = paddle;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

assign leftPressed = ~buttonLeft; // Buttons are NC
assign rightPressed = ~buttonRight;


always @(posedge game_clk) begin
	if (leftPressed)  begin
		if (speed != -1)
			speed <= speed + 1;
		if (location[15:6] != 640 - 48)
			location <= location + speed[5:2];
	end else if (rightPressed) begin
		if (speed != -1)
			speed <= speed + 1;
		if (location[15:6] != 0) begin
			location <= location - speed[5:2];
		end
	end else begin 
		if (speed != 0)
			speed <= speed - 1;
	end
end

assign testGround = 0;
assign test = clk;
assign ground = 0;

endmodule
