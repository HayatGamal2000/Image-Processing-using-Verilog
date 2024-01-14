module DWT_Haar_inv
#(parameter WIDTH 	= 20,							// Image width
			HEIGHT 	= 30,								// Image height
			BMP_HEADER_NUM = 54							// Header for bmp image
)
(
	input HCLK,												// Clock	
	input HRESETn,											// Reset active low
	input hsync,											// Hsync pulse						
    input signed [9:0]  DATA_R_cA,						// Red 8-bit 
    input signed [9:0]  DATA_G_cA,						// Green 8-bit
    input signed [9:0]  DATA_B_cA,						// Blue 8-bit 
    input signed [9:0]  DATA_R_cH,						// Red 8-bit 
    input signed [9:0]  DATA_G_cH,						// Green 8-bit
    input signed [9:0]  DATA_B_cH,						// Blue 8-bit 
	input signed [9:0]  DATA_R_cV,						// Red 8-bit 
    input signed [9:0]  DATA_G_cV,						// Green 8-bit
    input signed [9:0]  DATA_B_cV,						// Blue 8-bit 
    input signed [9:0]  DATA_R_cD,						// Red 8-bit 
    input signed [9:0]  DATA_G_cD,						// Green 8-bit
    input signed [9:0]  DATA_B_cD,						// Blue 8-bit 
	output 	reg	 ctrl_data_Done,
	output reg signed [8:0]  DATA_R_L0,
	output reg signed [8:0]  DATA_G_L0,
	output reg signed [8:0]  DATA_B_L0,
	output reg signed [8:0]  DATA_R_L1,
	output reg signed [8:0]  DATA_G_L1,
	output reg signed [8:0]  DATA_B_L1,
	output reg signed [8:0]  DATA_R_H0,
	output reg signed [8:0]  DATA_G_H0,
	output reg signed [8:0]  DATA_B_H0,
	output reg signed [8:0]  DATA_R_H1,
	output reg signed [8:0]  DATA_G_H1,
	output reg signed [8:0]  DATA_B_H1
);	

reg signed [18:0] data_count;									// Counting data
wire done;													// done flag
// counting variables


parameter Width = WIDTH/2; 
parameter Height = HEIGHT/2; 

// Writing RGB888 even and odd data to the temp memory
always@(*) begin
			DATA_R_L0 = 0;
			DATA_G_L0 = 0;
			DATA_B_L0 = 0;
			DATA_R_L1 = 0;
			DATA_G_L1 = 0;
			DATA_B_L1 = 0;
			DATA_R_H0 = 0;
			DATA_G_H0 = 0;
			DATA_B_H0 = 0;
			DATA_R_H1 = 0;
			DATA_G_H1 = 0;
			DATA_B_H1 = 0;
        if(hsync) begin
			/////////////////////////////LL ///////////////////////////////
			DATA_R_L0 = (DATA_R_cA + DATA_R_cH) >> 1;
			DATA_G_L0 = (DATA_G_cA + DATA_G_cH) >> 1;
			DATA_B_L0 = (DATA_B_cA + DATA_B_cH) >> 1;
			
            DATA_R_L1 = (DATA_R_cA - DATA_R_cH) >> 1;
			DATA_G_L1 = (DATA_G_cA - DATA_G_cH) >> 1;
			DATA_B_L1 = (DATA_B_cA - DATA_B_cH) >> 1;
			////////////////////////////HL //////////////////////////
			DATA_R_H0 = (DATA_R_cV + DATA_R_cD) >> 1;
			DATA_G_H0 = (DATA_G_cV + DATA_G_cD) >> 1;
			DATA_B_H0 = (DATA_B_cV + DATA_B_cD) >> 1;
			////////////////////////////HH //////////////////////////
			DATA_R_H1 = (DATA_R_cV - DATA_R_cD) >> 1;
			DATA_G_H1 = (DATA_G_cV - DATA_G_cD) >> 1;
			DATA_B_H1 = (DATA_B_cV - DATA_B_cD) >> 1;
        end
    end



// data counting
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else if(data_count < (Width*HEIGHT/2)) begin
        if(hsync)
			data_count <= data_count + 1; // pixels counting for create done flag
    end
end
assign done = (data_count == (Width*HEIGHT/2))? 1'b1: 1'b0; // done flag once all pixels were processed
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        ctrl_data_Done <= 0;
    end
    else begin
		ctrl_data_Done <= done;
    end
end

endmodule