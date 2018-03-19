// Pong VGA game
// (c) fpga4fun.com

module Pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground, buttonLeft, buttonRight);

parameter PADDLE_TOP = 448;
parameter PADDLE_WIDTH = 64;
parameter BLOCK_WIDTH = 16;
parameter LIFE_BLOCK_Y = 464;

parameter BALL_SIZE = 8;

reg [15:0] cnt;
always @(posedge clk) cnt <= cnt + 'd1;

reg [2:0] life = -1; // A 1 for each life

reg[14:0] pauseTime = -1;  // Ticks remaining of pause

wire vga_clk;
assign vga_clk = cnt[1];

wire game_clk;
assign game_clk = cnt[13];

reg[5:0] frameNumber;
always @(posedge vga_v_sync) frameNumber <= frameNumber + 1;

input clk,buttonLeft,buttonRight;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, test, testGround, ground;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [15:0] location = ((640 - PADDLE_WIDTH) / 2) << 6;

reg [15:0] ballX = ((640 / 2) + 4) << 6;
reg [14:0] ballY = (480 - 64) << 6;

reg ballGoingRight = 1;
reg ballGoingDown = 0;
reg[1:0] ballHorizSpeed;

reg[31:0] blocks [15:0];


initial begin
blocks[15] = 32'b0000000000011111111111111111111;
blocks[14] = 32'b0000000000010101010101010101011;
blocks[13] = 32'b0000000000011010101010101010101;
blocks[12] = 32'b0000000000010101010101010101011;
blocks[11] = 32'b0000000000011010111111111110101;
blocks[10] = 32'b0000000000010101111111111101011;
blocks[9]  = 32'b0000000000011010110000001110101;
blocks[8]  = 32'b0000000000010101110000001101011;
blocks[7]  = 32'b0000000000011010110000001110101;
blocks[6]  = 32'b0000000000010101111111111101011;
blocks[5]  = 32'b0000000000011010111111111110101;
blocks[4]  = 32'b0000000000010101010101010101011;
blocks[3]  = 32'b0000000000011010101010101010101;
blocks[2]  = 32'b0000000000010101010101010101011;
blocks[1]  = 32'b0000000000011010101010101010101;
blocks[0]  = 32'b0000000000011111111111111111111;
end

hvsync_generator syncgen(.clk(vga_clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

wire playing = (life[2]) | (pauseTime == 0);
									 
wire paddle = (CounterX > location[15:6]) & (CounterX < location[15:6] + PADDLE_WIDTH) & (CounterY[8:3] == PADDLE_TOP / 8);
wire ball = (CounterX > ballX[15:6]) & (CounterX < ballX[15:6] + BALL_SIZE) & (CounterY > ballY[14:6]) & (CounterY < ballY[14:6] + BALL_SIZE);
wire block = blocks[CounterY[7:4]][CounterX[9:5]] & (CounterY < 256);
wire lifeBall = (CounterY[8:3] == LIFE_BLOCK_Y / 8) & (CounterX[3]) & (CounterX[9:6] == 0) & 
		((CounterX[5:4] == 2'b00 & life[0]) | (CounterX[5:4] == 2'b01 & life[1]) | (CounterX[5:4] == 2'b10 & life[2]));
wire flashingLifeBall = lifeBall & (frameNumber[2] | playing);
		
wire R = paddle | flashingLifeBall | ball | (block & (CounterX[0] ^ CounterY[0] ^ frameNumber[0]));
wire G = paddle | flashingLifeBall | ball;
wire B = paddle | flashingLifeBall | ball | block;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

wire[9:0] ballLeft = ballX[15:6] + BALL_SIZE;
wire[8:0] ballBottom = ballY[14:6] + BALL_SIZE;

wire[9:0] leadingX = ballGoingRight ? ballLeft : ballX[15:6];
wire[8:0] leadingY = ballGoingDown ? ballBottom : ballY[14:6];

wire canCollide = ballY[14:6] < (ballGoingDown ? 239 : 256);

wire[5:0] difference = ballX[15:6] - location[15:6];

assign leftPressed = ~buttonLeft; // Buttons are NC
assign rightPressed = ~buttonRight;

always @(posedge game_clk) begin
	if (life[0] == 0) begin
		pauseTime <= -1; // Game over :(
		ballX <= (640 + 32) << 6; // Move offscreen
	end else	if (pauseTime != 0) begin
		pauseTime <= pauseTime - 1;
		location <= ((640 - PADDLE_WIDTH) / 2) << 6;
		ballX <= ((640 / 2) + 4) << 6;
		ballY <= (480 - 64) << 6;
		ballGoingDown <= 0;
		ballHorizSpeed <= 0;
	end else begin
		if (ballGoingRight) begin
			if (ballX[15:6] == 640 - 8)
				ballGoingRight <= 0;
			if (leadingX[4:0] == 0 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
				blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
				ballGoingRight <= 0;
			end
			ballX <= ballX + ballHorizSpeed + 1;
		end else begin
			if (ballX[15:6] == 0)
				ballGoingRight <= 1;
			if (leadingX[4:0] == 'b11111 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
				blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
				ballGoingRight <= 1;
			end
			ballX <= ballX - ballHorizSpeed - 1;
		end
			
		if (ballGoingDown) begin
			if (ballY[14:6] == 480) begin
				life <= {1'b0, life[2:1]};
				pauseTime <= -1;
			end
			if ((ballY[14:6] == PADDLE_TOP - BALL_SIZE) & (ballLeft > location[15:6]) & (ballX[15:6] < location[15:6] + PADDLE_WIDTH)) begin
				ballHorizSpeed <= 3 - (difference[4:3] ^ {2{difference[5]}});
				ballGoingRight <= difference[5];
				ballGoingDown <= 0;
			end
			if (leadingY[3:0] == 0 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
				blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
				ballGoingDown <= 0;
			end
			ballY <= ballY + 3;
		end else begin
			if (ballY[14:6] == 0)
				ballGoingDown <= 1;
			if (leadingY[3:0] == 'b1111 & canCollide & blocks[leadingY[7:4]][leadingX[9:5]]) begin
				blocks[leadingY[7:4]][leadingX[9:5]] <= 0;
				ballGoingDown <= 1;
			end
			ballY <= ballY - 3;
		end
	
		if (leftPressed)  begin
			if (location[15:6] != 640 - PADDLE_WIDTH)
				location <= location + 4;
		end else if (rightPressed) begin
			if (location[15:6] != 0) begin
				location <= location - 4;
			end
		end
	end
end

assign testGround = 0;
assign test = game_clk;
assign ground = 0;

endmodule
