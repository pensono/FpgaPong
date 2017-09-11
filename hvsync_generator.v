module hvsync_generator(clk, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);
input clk;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [8:0] CounterY;

//////////////////////////////////////////////////
reg [9:0] CounterX;
reg [9:0] CounterY;
wire CounterXmaxed = (CounterX==10'h320); //h2FF
wire CounterYmaxed = (CounterY==10'h20D); 

always @(posedge clk)
if(CounterXmaxed)
	CounterX <= 0;
else
	CounterX <= CounterX + 1;

always @(posedge clk)
if(CounterXmaxed) begin
	if(CounterYmaxed)
		CounterY <= 0;
	else
		CounterY <= CounterY + 1;
end

reg	vga_HS, vga_VS;
always @(posedge clk)
begin
	if (CounterX == 656)
		vga_HS <= 1; 
	else if (CounterX == 752)
		vga_HS <= 0;
	vga_VS <= (CounterY[9:1]==245); // change this value to move the display vertically
end

reg inDisplayArea;
always @(posedge clk)
if(inDisplayArea==0)
	inDisplayArea <= (CounterXmaxed) && (CounterY<480);
else
	inDisplayArea <= !(CounterX==639);
	
assign vga_h_sync = 1; // ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule
