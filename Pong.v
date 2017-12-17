// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground, buttonLeft, buttonRight);

parameter PADDLE_TOP = 448;
parameter PADDLE_WIDTH = 48;

parameter BALL_SIZE = 8;

reg [12:0] cnt;
always @(posedge clk) cnt <= cnt + 1;

wire vga_clk;
assign vga_clk = cnt[1];

wire game_clk;
assign game_clk = cnt[12];

input clk,buttonLeft,buttonRight;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [15:0] location;
reg [7:0] speed;

reg [15:0] ballX;
reg [14:0] ballY;

reg ballGoingLeft;
reg ballGoingDown;


hvsync_generator syncgen(.clk(vga_clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

wire paddle = (CounterX > location[15:6]) & (CounterX < location[15:6] + PADDLE_WIDTH) & (CounterY[8:3] == PADDLE_TOP / 8);
wire ball = (CounterX > ballX[15:6]) & (CounterX < ballX[15:6] + BALL_SIZE) & (CounterY > ballY[14:6]) & (CounterY < ballY[14:6] + BALL_SIZE);
									 
wire R = paddle | ball;
wire G = paddle | ball;
wire B = paddle | ball;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

always @(posedge game_clk) begin
	if (ballGoingLeft) begin
		if (ballX[15:6] == 640 - 8)
			ballGoingLeft <= 0;
		ballX <= ballX + 1;
	end else begin
		if (ballX[15:6] == 0)
			ballGoingLeft <= 1;
		ballX <= ballX - 1;
	end
		
	if (ballGoingDown) begin
		if (ballY[14:6] == 480 - 8)
			ballGoingDown <= 0; // Lose a life
		if ((ballY[14:6] == PADDLE_TOP - BALL_SIZE) & (ballX[15:6] > location[15:6]) & (ballX[15:6] < location[15:6] + PADDLE_WIDTH))
			ballGoingDown <= 0;
		ballY <= ballY + 1;
	end else begin
		if (ballY[14:6] == 0)
			ballGoingDown <= 1;
		ballY <= ballY - 1;
	end
end

assign leftPressed = ~buttonLeft; // Buttons are NC
assign rightPressed = ~buttonRight;


always @(posedge game_clk) begin
	if (leftPressed)  begin
		if (speed != -1)
			speed <= speed + 1;
		if (location[15:6] != 640 - 48)
			location <= location + speed[7:5];
	end else if (rightPressed) begin
		if (speed != -1)
			speed <= speed + 1;
		if (location[15:6] != 0) begin
			location <= location - speed[7:5];
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
