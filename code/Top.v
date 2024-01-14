`include "parameter.v" 						// Include definition file
module Top
#(parameter WIDTH 	= 364,							// Image width
			HEIGHT 	= 362							// Image height
)
(
	input  HCLK,										// clock					
	input  HRESETn,									// Reset (active low)
	output Write_Done
);

wire          vsync1;
wire          vsync2;
wire          hsync1,hsync2;
wire  [8:0]   DATA_R_L;
wire  [8:0]   DATA_G_L;
wire  [8:0]   DATA_B_L;
wire  [8:0]   DATA_R_H;
wire  [8:0]   DATA_G_H;
wire  [8:0]   DATA_B_H;
wire  [9:0]   DATA_R_cA;
wire  [9:0]   DATA_G_cA;
wire  [9:0]   DATA_B_cA;
wire  [9:0]   DATA_R_cH;
wire  [9:0]   DATA_G_cH;
wire  [9:0]   DATA_B_cH;
wire  [9:0]   DATA_R_cV;
wire  [9:0]   DATA_G_cV;
wire  [9:0]   DATA_B_cV;
wire  [9:0]   DATA_R_cD;
wire  [9:0]   DATA_G_cD;
wire  [9:0]   DATA_B_cD;
wire  [8:0]   DATA_R_L0;
wire  [8:0]   DATA_G_L0;
wire  [8:0]   DATA_B_L0;
wire  [8:0]   DATA_R_H0;
wire  [8:0]   DATA_G_H0;
wire  [8:0]   DATA_B_H0;
wire  [8:0]   DATA_R_L1;
wire  [8:0]   DATA_G_L1;
wire  [8:0]   DATA_B_L1;
wire  [8:0]   DATA_R_H1;
wire  [8:0]   DATA_G_H1;
wire  [8:0]   DATA_B_H1;








wire          ctrl_data_Done;
wire          row_dwt_done;
wire          col_dwt_done;
wire          hsync_out;







image_read_dwt #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) u_image_read 
( 
    .HCLK	                (HCLK),
    .HRESETn	            (HRESETn),
    .VSYNC	                (vsync),
    .HSYNC	                (hsync1),
    .DATA_R_L	            (DATA_R_L),
    .DATA_G_L	            (DATA_G_L),
    .DATA_B_L	            (DATA_B_L),
    .DATA_R_H	            (DATA_R_H),
    .DATA_G_H	            (DATA_G_H),
    .DATA_B_H	            (DATA_B_H),
	.ctrl_done				(row_dwt_done)
); 

DWT_Haar #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) u_DWT_Haar 
(
	.HCLK(HCLK),		
    .HRESETn(HRESETn),	
	.hsync_in(hsync1),	
	.DATA_WRITE_R_L(DATA_R_L),
	.DATA_WRITE_G_L(DATA_G_L),
	.DATA_WRITE_B_L(DATA_B_L),
	.DATA_WRITE_R_H(DATA_R_H),
	.DATA_WRITE_G_H(DATA_G_H),
	.DATA_WRITE_B_H(DATA_B_H),
	.Write_Done(Write_Done1),
	.DATA_R_cA(DATA_R_cA),
	.DATA_G_cA(DATA_G_cA),
	.DATA_B_cA(DATA_B_cA),         
	.DATA_R_cH(DATA_R_cH),
	.DATA_G_cH(DATA_G_cH),
	.DATA_B_cH(DATA_B_cH),        
	.DATA_R_cV(DATA_R_cV),
	.DATA_G_cV(DATA_G_cV),
	.DATA_B_cV(DATA_B_cV),        
	.DATA_R_cD(DATA_R_cD),
	.DATA_G_cD(DATA_G_cD),
	.DATA_B_cD(DATA_B_cD),
	.VSYNC(vsync2),
	.HSYNC(hsync2),
	.ctrl_done(col_dwt_done)	
);

DWT_Haar_inv #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) u_DWT_Haar_inv 
(
	.HCLK(HCLK),		
    .HRESETn(HRESETn),	
	.hsync(hsync2),	
	.DATA_R_cA(DATA_R_cA),
	.DATA_G_cA(DATA_G_cA),
	.DATA_B_cA(DATA_B_cA),         
	.DATA_R_cH(DATA_R_cH),
	.DATA_G_cH(DATA_G_cH),
	.DATA_B_cH(DATA_B_cH),        
	.DATA_R_cV(DATA_R_cV),
	.DATA_G_cV(DATA_G_cV),
	.DATA_B_cV(DATA_B_cV),        
	.DATA_R_cD(DATA_R_cD),
	.DATA_G_cD(DATA_G_cD),
	.DATA_B_cD(DATA_B_cD),
	.ctrl_data_Done(ctrl_data_Done),
	.DATA_R_L0(DATA_R_L0),
	.DATA_G_L0(DATA_G_L0),
	.DATA_B_L0(DATA_B_L0),
	.DATA_R_H0(DATA_R_H0),
	.DATA_G_H0(DATA_G_H0),
	.DATA_B_H0(DATA_B_H0),
	.DATA_R_L1(DATA_R_L1),
	.DATA_G_L1(DATA_G_L1),
	.DATA_B_L1(DATA_B_L1),
	.DATA_R_H1(DATA_R_H1),
	.DATA_G_H1(DATA_G_H1),
	.DATA_B_H1(DATA_B_H1)
);

image_write_inv_dwt #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) u_image_write_inv_dwt 
(
	.HCLK(HCLK),		
    .HRESETn(HRESETn),	
    .hsync(hsync2),
	.DATA_R_L0(DATA_R_L0),
	.DATA_G_L0(DATA_G_L0),
	.DATA_B_L0(DATA_B_L0),
	.DATA_R_H0(DATA_R_H0),
	.DATA_G_H0(DATA_G_H0),
	.DATA_B_H0(DATA_B_H0),
	.DATA_R_L1(DATA_R_L1),
	.DATA_G_L1(DATA_G_L1),
	.DATA_B_L1(DATA_B_L1),
	.DATA_R_H1(DATA_R_H1),
	.DATA_G_H1(DATA_G_H1),
	.DATA_B_H1(DATA_B_H1),
    .Write_Done(Write_Done),
	.HSYNC(hsync_out)
);


endmodule



