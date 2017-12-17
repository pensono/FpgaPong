// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground, buttonLeft, buttonRight);

parameter PADDLE_TOP = 448;
parameter PADDLE_WIDTH = 48;
parameter BLOCK_WIDTH = 16;

parameter BALL_SIZE = 8;

reg [15:0] cnt;
always @(posedge clk) cnt <= cnt + 'd1;

wire vga_clk;
assign vga_clk = cnt[1];

wire game_clk;
assign game_clk = cnt[12];

reg oddFrame;
always @(posedge vga_h_sync) oddFrame <= ~oddFrame;

input clk,buttonLeft,buttonRight;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [15:0] location;
reg [7:0] speed;

reg [15:0] ballX = ((640 / 2) + 4) << 6;
reg [14:0] ballY = (480 - 32) << 6;

reg ballGoingLeft = 1;
reg ballGoingDown = 0;

reg[31:0] blocks [15:0];


initial begin
blocks[15] = 32'b0000000000011111111111111111111;
blocks[14] = 32'b0000000000011101010101010101011;
blocks[13] = 32'b0000000000011010101010101010101;
blocks[12] = 32'b0000000000011101010101010101011;
blocks[11] = 32'b0000000000011010101010101010101;
blocks[10] = 32'b0000000000011101010101010101011;
blocks[9]  = 32'b0000000000011010101010101010101;
blocks[8]  = 32'b0000000000011101010101010101011;
blocks[7]  = 32'b0000000000011010101010101010101;
blocks[6]  = 32'b0000000000011101010101010101011;
blocks[5]  = 32'b0000000000011010101010101010101;
blocks[4]  = 32'b0000000000011101010101010101011;
blocks[3]  = 32'b0000000000011010101010101010101;
blocks[2]  = 32'b0000000000011101010101010101011;
blocks[1]  = 32'b0000000000011010101010101010101;
blocks[0]  = 32'b0000000000011111111111111111111;
end

hvsync_generator syncgen(.clk(vga_clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

wire paddle = (CounterX > location[15:6]) & (CounterX < location[15:6] + PADDLE_WIDTH) & (CounterY[8:3] == PADDLE_TOP / 8);
wire ball = (CounterX > ballX[15:6]) & (CounterX < ballX[15:6] + BALL_SIZE) & (CounterY > ballY[14:6]) & (CounterY < ballY[14:6] + BALL_SIZE);
wire block = blocks[CounterY[7:4]][CounterX[9:5]] & (CounterY < 256);

wire R = paddle | ball | (block & (CounterX[0] ^ oddFrame));
wire G = paddle | ball;
wire B = paddle | ball | block;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

wire[9:0] ballLeft = ballX[15:6] + BALL_SIZE;
wire[8:0] ballBottom = ballY[14:6] + BALL_SIZE;

wire[9:0] leadingX = ballGoingLeft ? ballLeft : ballX[15:6];
wire[8:0] leadingY = ballGoingDown ? ballBottom : ballY[14:6];

wire canCollide = ballY[14:6] < (ballGoingDown ? 239 : 256);

always @(posedge game_clk) begin
	if (ballGoingLeft) begin
		if (ballX[15:6] == 640 - 8)
			ballGoingLeft <= 0;
		if (leadingX[4:0] == 0 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
			blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
			ballGoingLeft <= 0;
		end
		ballX <= ballX + 1;
	end else begin
		if (ballX[15:6] == 0)
			ballGoingLeft <= 1;
		if (leadingX[4:0] == 'b11111 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
			blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
			ballGoingLeft <= 1;
		end
		ballX <= ballX - 1;
	end
		
	if (ballGoingDown) begin
		if (ballY[14:6] == 480)
			ballGoingDown <= 0; // Lose a life
		if ((ballY == PADDLE_TOP - BALL_SIZE) & (ballX[15:6] + BALL_SIZE > location[15:6]) & (ballX[15:6] < location[15:6] + PADDLE_WIDTH))
			ballGoingDown <= 0;
		if (leadingY[3:0] == 0 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
			blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
			ballGoingDown <= 0;
		end
		ballY <= ballY + 1;
	end else begin
		if (ballY[14:6] == 0)
			ballGoingDown <= 1;
		if (leadingY[3:0] == 'b1111 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
			blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
			ballGoingDown <= 1;
		end
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
assign test = game_clk;
assign ground = 0;

endmodule
