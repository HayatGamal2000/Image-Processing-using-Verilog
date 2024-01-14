module image_write_inv_dwt
#(parameter WIDTH 	= 20,							// Image width
			HEIGHT 	= 30,								// Image height
			//INFILE  = "output.bmp",						// Output image
			INFILE  = "output.hex",						// Output image
			START_UP_DELAY = 100, 				// Delay during start up time
			HSYNC_DELAY = 160					// Delay between HSYNC pulses	
			//BMP_HEADER_NUM = 54							// Header for bmp image
)
(
	input HCLK,												// Clock	
	input HRESETn,											// Reset active low
	input hsync,											// Hsync pulse						
    input signed [8:0]  DATA_R_L0,						// Red 8-bit 
    input signed [8:0]  DATA_G_L0,						// Green 8-bit
    input signed [8:0]  DATA_B_L0,						// Blue 8-bit 
    input signed [8:0]  DATA_R_L1,						// Red 8-bit 
    input signed [8:0]  DATA_G_L1,						// Green 8-bit
    input signed [8:0]  DATA_B_L1,						// Blue 8-bit 
	input signed [8:0]  DATA_R_H0,						// Red 8-bit 
    input signed [8:0]  DATA_G_H0,						// Green 8-bit
    input signed [8:0]  DATA_B_H0,						// Blue 8-bit 
    input signed [8:0]  DATA_R_H1,						// Red 8-bit 
    input signed [8:0]  DATA_G_H1,						// Green 8-bit
    input signed [8:0]  DATA_B_H1,						// Blue 8-bit 
	output	 Write_Done,
	output reg HSYNC	
	
);	

parameter Width = WIDTH/2; 
//parameter Height = HEIGHT/2;  

reg Write_Done_LH;
//integer BMP_header [0 : BMP_HEADER_NUM - 1];		// BMP header
reg signed [9:0] temp_L_inv  [0 : Width*HEIGHT*3 - 1];		// Temporary memory for image
reg signed [9:0] temp_H_inv  [0 : Width*HEIGHT*3 - 1];		// Temporary memory for image

parameter sizeOfLengthReal = WIDTH*HEIGHT*3 ; 		// image data : 197652 bytes: 364 * 181 *3 

reg signed [9 : 0]   temp_out_img [0 : sizeOfLengthReal-1];	// memory to store  8-bit data image
reg [7 : 0]   Out_img [0 : sizeOfLengthReal-1];	// memory to store  8-bit data image
// local parameters for FSM
localparam		ST_IDLE 	= 2'b00,		// idle state
				ST_VSYNC	= 2'b01,			// state for creating vsync 
				ST_HSYNC	= 2'b10,			// state for creating hsync 
				ST_DATA		= 2'b11;		// state for data processing 
reg [1:0] cstate, 						// current state
		  nstate;							// next state			
reg start;									// start signal: trigger Finite state machine beginning to operate
reg Write_Done_d;								// delayed finishing input image signal: use to create start signal
reg 		ctrl_vsync_run; 				// control signal for vsync counter  
reg [8:0]	ctrl_vsync_cnt;			// counter for vsync
reg 		ctrl_hsync_run;				// control signal for hsync counter
reg [8:0]	ctrl_hsync_cnt;			// counter  for hsync
reg 		ctrl_data_run;					// control signal for data processing

reg signed [9:0] org_R_L_inv  [0 : Width*HEIGHT - 1]; 	// temporary storage for R component
reg signed [9:0] org_G_L_inv  [0 : Width*HEIGHT - 1];	// temporary storage for G component
reg signed [9:0] org_B_L_inv  [0 : Width*HEIGHT - 1];	// temporary storage for B component
reg signed [9:0] org_R_H_inv  [0 : Width*HEIGHT - 1]; 	// temporary storage for R component
reg signed [9:0] org_G_H_inv  [0 : Width*HEIGHT - 1];	// temporary storage for G component
reg signed [9:0] org_B_H_inv  [0 : Width*HEIGHT - 1];	// temporary storage for B component
reg [ 8:0] row; // row index of the image
reg [ 7:0] col; // column index of the image
reg [ 8:0] y; // row index of the image
reg [ 7:0] x; // column index of the image
reg [16:0] data_count_processing; // data counting for entire pixels of the image
 


reg signed [18:0] data_count;									// Counting data
wire done;													// done flag
// counting variables
integer i,j;
integer k, l, m;
integer fd1;



//-------Header data for bmp image--------------------------//
// Windows BMP files begin with a 54-byte header: 
// initial begin
// 	BMP_header[ 0] = 66;BMP_header[28] =24;
// 	BMP_header[ 1] = 77;BMP_header[29] = 0;
// 	BMP_header[ 2] = 54;BMP_header[30] = 0;
// 	BMP_header[ 3] =  0;BMP_header[31] = 0;
// 	BMP_header[ 4] = 18;BMP_header[32] = 0;
// 	BMP_header[ 5] =  0;BMP_header[33] = 0;
// 	BMP_header[ 6] =  0;BMP_header[34] = 0;
// 	BMP_header[ 7] =  0;BMP_header[35] = 0;
// 	BMP_header[ 8] =  0;BMP_header[36] = 0;
// 	BMP_header[ 9] =  0;BMP_header[37] = 0;
// 	BMP_header[10] = 54;BMP_header[38] = 0;
// 	BMP_header[11] =  0;BMP_header[39] = 0;
// 	BMP_header[12] =  0;BMP_header[40] = 0;
// 	BMP_header[13] =  0;BMP_header[41] = 0;
// 	BMP_header[14] = 40;BMP_header[42] = 0;
// 	BMP_header[15] =  0;BMP_header[43] = 0;
// 	BMP_header[16] =  0;BMP_header[44] = 0;
// 	BMP_header[17] =  0;BMP_header[45] = 0;
// 	BMP_header[18] =  0;BMP_header[46] = 0;
// 	BMP_header[19] =  3;BMP_header[47] = 0;
// 	BMP_header[20] =  0;BMP_header[48] = 0;
// 	BMP_header[21] =  0;BMP_header[49] = 0;
// 	BMP_header[22] =  0;BMP_header[50] = 0;
// 	BMP_header[23] =  2;BMP_header[51] = 0;	
// 	BMP_header[24] =  0;BMP_header[52] = 0;
// 	BMP_header[25] =  0;BMP_header[53] = 0;
// 	BMP_header[26] =  1;
// 	BMP_header[27] =  0;
// end
// row and column counting for temporary memory of image 
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        l <= 0;
        m <= 0;
    end else begin
        if(hsync) begin
            if(m == HEIGHT-2) begin
                m <= 0;
                l <= l + 1; // count to obtain column index of the out_BMP temporary memory to save image data
            end else begin
                m <= m + 2; // count to obtain row index of the out_BMP temporary memory to save image data
            end
        end
    end
end
// Writing RGB888 even and odd data to the temp memory
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        for(k=0;k<Width*HEIGHT*3;k=k+1) begin
            temp_L_inv	[k] <= 0;
			temp_H_inv	[k] <= 0;
        end
    end else begin
        if(hsync) begin
			/////////////////////////////L_inv ///////////////////////////////
			temp_L_inv	[Width*3*(HEIGHT- m-1   )+3*l+2] <= DATA_R_L0;
			temp_L_inv	[Width*3*(HEIGHT- m-1   )+3*l+1] <= DATA_G_L0;
			temp_L_inv	[Width*3*(HEIGHT- m-1   )+3*l  ] <= DATA_B_L0;
            temp_L_inv	[Width*3*(HEIGHT-(m+1)-1)+3*l+2] <= DATA_R_L1;
			temp_L_inv	[Width*3*(HEIGHT-(m+1)-1)+3*l+1] <= DATA_G_L1;
			temp_L_inv	[Width*3*(HEIGHT-(m+1)-1)+3*l  ] <= DATA_B_L1;
			///////////////////////////H_inv ///////////////////////////////
			temp_H_inv	[Width*3*(HEIGHT- m-1   )+3*l+2] <= DATA_R_H0;
			temp_H_inv	[Width*3*(HEIGHT- m-1   )+3*l+1] <= DATA_G_H0;
			temp_H_inv	[Width*3*(HEIGHT- m-1   )+3*l  ] <= DATA_B_H0;
			temp_H_inv  [Width*3*(HEIGHT-(m+1)-1)+3*l+2] <= DATA_R_H1;
			temp_H_inv  [Width*3*(HEIGHT-(m+1)-1)+3*l+1] <= DATA_G_H1;
			temp_H_inv  [Width*3*(HEIGHT-(m+1)-1)+3*l  ] <= DATA_B_H1;
        end
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
        Write_Done_LH <= 0;
    end
    else begin
		Write_Done_LH <= done;
    end
end
////////////////////////////////////////////////////Inverse Image//////////////////////////////////////////////////////////////////

//-------------- APPLY inverse 1-D Haar	----------------------//

	always@(start) begin
	if(Write_Done_LH)begin
		if(start == 1'b1) begin
			
			for(i=0; i<HEIGHT; i=i+1) begin
				for(j=0; j<Width; j=j+1) begin
					org_R_L_inv [Width*i+j] = temp_L_inv [Width*3*(HEIGHT-i-1)+3*j+0]; // save Red component
					org_G_L_inv [Width*i+j] = temp_L_inv [Width*3*(HEIGHT-i-1)+3*j+1];// save Green component
					org_B_L_inv [Width*i+j] = temp_L_inv [Width*3*(HEIGHT-i-1)+3*j+2];// save Blue component
                                                          
					org_R_H_inv [Width*i+j] = temp_H_inv [Width*3*(HEIGHT-i-1)+3*j+0]; // save Red component
					org_G_H_inv [Width*i+j] = temp_H_inv [Width*3*(HEIGHT-i-1)+3*j+1];// save Green component
					org_B_H_inv [Width*i+j] = temp_H_inv [Width*3*(HEIGHT-i-1)+3*j+2];// save Blue component
				end
			end
		end
	end
end
//-------Begin to read image file once reset was high by creating a starting pulse (start)-------//
always@(posedge HCLK, negedge HRESETn,posedge Write_Done_LH)
begin
    if(!HRESETn) begin
        start <= 0;
		Write_Done_d <= 0;
    end
	else begin											//        		______ 				
			Write_Done_d <= Write_Done_LH;							//       	|		|
			if(Write_Done_LH == 1'b1 && Write_Done_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
				start <= 1'b1;
			else
				start <= 1'b0;
	end
end


//---Finite state machine for reading RGB888 data from memory and creating hsync and vsync pulses ----//
always@(posedge HCLK, negedge HRESETn)
begin
	if(~HRESETn) begin
		cstate <= ST_IDLE;
	end
	else if(Write_Done_LH)begin
			cstate <= nstate; // update next state 
		end
end


//--------- State Transition --------------//
// IDLE . VSYNC . HSYNC . DATA
always @(*) begin
	if(Write_Done_LH)begin
		case(cstate)
			ST_IDLE: begin
				if(start)
					nstate = ST_VSYNC;
				else
					nstate = ST_IDLE;
			end			
			ST_VSYNC: begin
				if(ctrl_vsync_cnt == START_UP_DELAY) 
					nstate = ST_HSYNC;
				else
					nstate = ST_VSYNC;
			end
			ST_HSYNC: begin
				if(ctrl_hsync_cnt == HSYNC_DELAY) 
					nstate = ST_DATA;
				else
					nstate = ST_HSYNC;
			end		
			ST_DATA: begin
				if(Write_Done)
					nstate = ST_IDLE;
				else begin
					if(row == HEIGHT - 2)
						nstate = ST_HSYNC;
					else
						nstate = ST_DATA;
				end
			end
		endcase
	end
end


// --- counting for time period of vsync, hsync, data processing ----  //
always @(*) begin
		ctrl_vsync_run = 0;
		ctrl_hsync_run = 0;
		ctrl_data_run  = 0;
	if(Write_Done_LH)begin
		case(cstate)
			ST_VSYNC: 	begin ctrl_vsync_run = 1; end 	// trigger counting for vsync
			ST_HSYNC: 	begin ctrl_hsync_run = 1; end	// trigger counting for hsync
			ST_DATA: 	begin ctrl_data_run  = 1; end	// trigger counting for data processing
		endcase
	end
end
// counters for vsync, hsync
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        ctrl_vsync_cnt <= 0;
		ctrl_hsync_cnt <= 0;
    end
	else if(Write_Done_LH)begin
			if(ctrl_vsync_run)
				ctrl_vsync_cnt <= ctrl_vsync_cnt + 1; // counting for vsync
			else 
				ctrl_vsync_cnt <= 0;
				
			if(ctrl_hsync_run)
				ctrl_hsync_cnt <= ctrl_hsync_cnt + 1;	// counting for hsync		
			else
				ctrl_hsync_cnt <= 0;
		end
end
// counting column and row index  for reading memory 
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        row <= 0;
		col <= 0;
		x <= 0;
		y <= 0;
    end
	else begin
		if(Write_Done_LH)begin
			if(ctrl_data_run) begin
				if(col == WIDTH/2 - 2) begin
					row <= row + 1;
				end
				if(col == WIDTH/2 - 2) 
					col <= 0;
				else 
					col <= col + 2; // reading 2 pixels in parallel
		
			if(x == WIDTH/4 - 1) begin
				y <= y + 1;
			end
			if(x == WIDTH/4 - 1) 
				x <= 0;
			else 
				x <= x + 1; 
			end
		end
	end
end



//----------------Data counting---------- ---------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count_processing <= 0;
    end
    else if(data_count_processing < (WIDTH*HEIGHT/2)) begin
		if(Write_Done_LH)begin
			if(ctrl_data_run)
				data_count_processing <= data_count_processing + 1;
		end
    end
end
assign VSYNC = ctrl_vsync_run;
assign Write_Done = (data_count_processing == (WIDTH*HEIGHT/2))? 1'b1: 1'b0; // done flag 



//-------------  Image processing   ---------------//
always @(*) begin
	
	HSYNC   = 1'b0;

	if(Write_Done_LH)begin
		if(ctrl_data_run) begin
			
			HSYNC   = 1'b1;
			/**************************************/		
			/*	      	DWT_2-D_Haar       		*/
			/**************************************/
			//////////////////////////////////////////////////////////////////////////////////////////////////
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+2]  = org_R_L_inv[Width * row + col    ] + org_R_H_inv[Width * row + col ];
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+1]  = org_G_L_inv[Width * row + col    ] + org_R_H_inv[Width * row + col ];
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+0]  = org_B_L_inv[Width * row + col    ] + org_R_H_inv[Width * row + col ];
			///////////////////////////////////////////////////////////////////////////   //////////////////////////////////////
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+5]  = org_R_L_inv[Width * row + col    ] - org_R_H_inv[Width * row + col ];
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+4]  = org_G_L_inv[Width * row + col    ] - org_R_H_inv[Width * row + col ];
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+3]  = org_B_L_inv[Width * row + col    ] - org_R_H_inv[Width * row + col ];
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+8]  = org_R_L_inv[Width * row + col+1  ] + org_R_H_inv[Width * row + col+1 ]; 
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+7]  = org_G_L_inv[Width * row + col+1  ] + org_R_H_inv[Width * row + col+1 ]; 
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+6]  = org_B_L_inv[Width * row + col+1  ] + org_R_H_inv[Width * row + col+1 ]; 
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+11] = org_R_L_inv[Width * row + col+1  ] - org_R_H_inv[Width * row + col+1 ];
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+10] = org_G_L_inv[Width * row + col+1  ] - org_R_H_inv[Width * row + col+1 ];
			temp_out_img [WIDTH*3*(HEIGHT-y-1)+12*x+9 ] = org_B_L_inv[Width * row + col+1  ] - org_R_H_inv[Width * row + col+1 ];								                     
		end
	end
end
///////////////////////////////////////////////////////////////////////////////////////////////////
//--------------Write .bmp file		----------------------//
initial begin
    fd1 = $fopen(INFILE, "wb+");
end
always@(Write_Done) begin // once the processing was done, bmp image will be created
    if(Write_Done == 1'b1) begin
		for(i=0; i<WIDTH*HEIGHT*3; i=i+1) begin
		////////////////////cA/////////////////////////////
			if(temp_out_img [i][9] == 1'b1 )
				Out_img[i] = 8'b0;
			else if (temp_out_img [i][8] == 1'b1 )               
				Out_img[i] = 8'b11111111;
			else                                       
				Out_img[i] = temp_out_img [i][7:0];			
		end
		
	
        //for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
        //    $fwrite(fd1, "%c", BMP_header[i][7:0]); // write the header
        //end
        
        for(i=0; i<WIDTH*HEIGHT*3; i=i+6) begin
		// write LL RGB (3 bytes) in a loop
            $fwrite(fd1, "%h\n", Out_img[i  ]);
            $fwrite(fd1, "%h\n", Out_img[i+1]);
            $fwrite(fd1, "%h\n", Out_img[i+2]);
			$fwrite(fd1, "%h\n", Out_img[i+3]);
            $fwrite(fd1, "%h\n", Out_img[i+4]);
            $fwrite(fd1, "%h\n", Out_img[i+5]);

		end
	end
end
endmodule