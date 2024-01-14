`include "parameter.v" 						// Include definition file
module DWT_Haar
#(parameter WIDTH 	= 20,							// Image width
			HEIGHT 	= 30,								// Image height
			START_UP_DELAY = 100, 				// Delay during start up time
			HSYNC_DELAY = 160					// Delay between HSYNC pulses	
)
(
	input HCLK,												// Clock	
	input HRESETn,											// Reset active low
	input hsync_in,											// Hsync pulse			
    input       signed [8:0]  DATA_WRITE_R_L,						// Red 8-bit data (odd)
    input       signed [8:0]  DATA_WRITE_G_L,						// Green 8-bit data (odd)
    input       signed [8:0]  DATA_WRITE_B_L,						// Blue 8-bit data (odd)
    input       signed [8:0]  DATA_WRITE_R_H,						// Red 8-bit data (even)
    input       signed [8:0]  DATA_WRITE_G_H,						// Green 8-bit data (even)
    input       signed [8:0]  DATA_WRITE_B_H,						// Blue 8-bit data (even)
	output 	reg	              Write_Done,
	output  reg signed [9:0]  DATA_R_cA,
	output  reg signed [9:0]  DATA_G_cA,
	output  reg signed [9:0]  DATA_B_cA,
                             
	output  reg signed [9:0]  DATA_R_cH,
	output  reg signed [9:0]  DATA_G_cH,
	output  reg signed [9:0]  DATA_B_cH,
                          
	output  reg signed [9:0]  DATA_R_cV,
	output  reg signed [9:0]  DATA_G_cV,
	output  reg signed [9:0]  DATA_B_cV,
                        
	output  reg signed [9:0]  DATA_R_cD,
	output  reg signed [9:0]  DATA_G_cD,
	output  reg signed [9:0]  DATA_B_cD,
	output     VSYNC,								// Vertical synchronous pulse
	// This signal is often a way to indicate that one entire image is transmitted.
	// Just create and is not used, will be used once a video or many images are transmitted.
	output reg HSYNC,								// Horizontal synchronous pulse	
	output			  ctrl_done					// Done flag
	
);		

parameter Width = WIDTH/2; 
reg signed [8:0] total_image_L  [0 : Width*HEIGHT*3 - 1];		// Temporary memory for image
reg signed [8:0] total_image_H  [0 : Width*HEIGHT*3 - 1];		// Temporary memory for image
reg [17:0] data_count;									// Counting data
wire done;													// done flag
// counting variables
integer i,j;
integer k, l, m;
integer fd; 

parameter sizeOfLengthReal = Width*HEIGHT*3 ; 		// image data : 197652 bytes: 364 * 181 *3 

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

//reg signed [8:0] temp_image_L  [0 : (Width)*HEIGHT*3 - 1];		// Temporary memory for image
//reg signed [8:0] temp_image_H  [0 : (Width)*HEIGHT*3 - 1];
reg signed [8:0] org_R_L  [0 : Width*HEIGHT - 1]; 	// temporary storage for R component
reg signed [8:0] org_G_L  [0 : Width*HEIGHT - 1];	// temporary storage for G component
reg signed [8:0] org_B_L  [0 : Width*HEIGHT - 1];	// temporary storage for B component
reg signed [8:0] org_R_H  [0 : Width*HEIGHT - 1]; 	// temporary storage for R component
reg signed [8:0] org_G_H  [0 : Width*HEIGHT - 1];	// temporary storage for G component
reg signed [8:0] org_B_H  [0 : Width*HEIGHT - 1];	// temporary storage for B component
reg [ 8:0] row; // row index of the image
reg [ 7:0] col; // column index of the image
reg [16:0] data_count_processing; // data counting for entire pixels of the image
 


// row and column counting for temporary memory of image 
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        l <= 0;
        m <= 0;
    end else begin
        if(hsync_in &&!Write_Done ) begin
            if(m == Width-1) begin
                m <= 0;
                l <= l + 1; // count to obtain row index of the out_BMP temporary memory to save image data
            end else begin
                m <= m + 1; // count to obtain column index of the out_BMP temporary memory to save image data
            end
        end
    end
end
// Writing RGB888 even and odd data to the temp memory
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        for(k=0;k<Width*HEIGHT*3;k=k+1) begin
            total_image_L[k] <= 0;
			total_image_H[k] <= 0;
        end
    end else begin
        if(hsync_in && !Write_Done) begin
            total_image_L[Width*3*(HEIGHT-l-1)+3*m+2] <= DATA_WRITE_R_L;
            total_image_L[Width*3*(HEIGHT-l-1)+3*m+1] <= DATA_WRITE_G_L;
            total_image_L[Width*3*(HEIGHT-l-1)+3*m  ] <= DATA_WRITE_B_L;
            total_image_H[Width*3*(HEIGHT-l-1)+3*m+2] <= DATA_WRITE_R_H;
            total_image_H[Width*3*(HEIGHT-l-1)+3*m+1] <= DATA_WRITE_G_H;
            total_image_H[Width*3*(HEIGHT-l-1)+3*m+0] <= DATA_WRITE_B_H;
        end
    end
end
// data counting
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else if(data_count < (Width*HEIGHT)) begin
        if(hsync_in )
			data_count <= data_count + 1; // pixels counting for create done flag
    end
end
assign done = (data_count == (Width*HEIGHT))? 1'b1: 1'b0; // done flag once all pixels were processed
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        Write_Done <= 0;
    end
    else begin
		Write_Done <= done;
    end
end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//-------------- APPLY 1-D Haar for colomns		----------------------//

	always@(start) begin
	if(Write_Done)begin
		if(start == 1'b1) begin
			
			for(i=0; i<HEIGHT; i=i+1) begin
				for(j=0; j<Width; j=j+1) begin
					org_R_L[Width*i+j] = total_image_L[Width*3*(HEIGHT-i-1)+3*j+0]; // save Red component
					org_G_L[Width*i+j] = total_image_L[Width*3*(HEIGHT-i-1)+3*j+1];// save Green component
					org_B_L[Width*i+j] = total_image_L[Width*3*(HEIGHT-i-1)+3*j+2];// save Blue component

					org_R_H[Width*i+j] = total_image_H[Width*3*(HEIGHT-i-1)+3*j+0]; // save Red component
					org_G_H[Width*i+j] = total_image_H[Width*3*(HEIGHT-i-1)+3*j+1];// save Green component
					org_B_H[Width*i+j] = total_image_H[Width*3*(HEIGHT-i-1)+3*j+2];// save Blue component
				end
			end
		end
	end
end
//-------Begin to read image file once reset was high by creating a starting pulse (start)-------//
always@(posedge HCLK, negedge HRESETn,posedge Write_Done)
begin
    if(!HRESETn) begin
        start <= 0;
		Write_Done_d <= 0;
    end
	else begin											//        		______ 				
			Write_Done_d <= Write_Done;							//       	|		|
			if(Write_Done == 1'b1 && Write_Done_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
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
	else if(Write_Done)begin
			cstate <= nstate; // update next state 
		end
end


//--------- State Transition --------------//
// IDLE . VSYNC . HSYNC . DATA
always @(*) begin
	if(Write_Done)begin
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
				if(ctrl_done)
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
	if(Write_Done)begin
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
	else if(Write_Done)begin
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
    end
	else begin
		if(Write_Done)begin
			if(ctrl_data_run) begin
				if(row == HEIGHT - 2) begin
					col <= col + 1;
				end
				if(row == HEIGHT - 2) 
					row <= 0;
				else 
					row <= row + 2; // reading 1 pixels from each image
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
    else begin
		if(Write_Done)begin
			if(ctrl_data_run)
				data_count_processing <= data_count_processing + 1;
		end
    end
end
assign VSYNC = ctrl_vsync_run;
assign ctrl_done = (data_count_processing == (Width*HEIGHT/2))? 1'b1: 1'b0; // done flag 



//-------------  Image processing   ---------------//
always @(*) begin
	
	HSYNC   = 1'b0;
	DATA_R_cA = 0;
	DATA_G_cA = 0;
	DATA_B_cA = 0;                                       
	DATA_R_cH = 0;
	DATA_G_cH = 0;
	DATA_B_cH = 0;        
    DATA_R_cV = 0;
	DATA_G_cV = 0;
	DATA_B_cV = 0;                                       
	DATA_R_cD = 0;
	DATA_G_cD = 0;
	DATA_B_cD = 0; 
	if(Write_Done)begin
		if(ctrl_data_run) begin
			
			HSYNC   = 1'b1;
			/**************************************/		
			/*	      	DWT_2-D_Haar       		*/
			/**************************************/
			/////////////////////////////////////////////////LL/////////////////////////////////////////////////
			DATA_R_cA = org_R_L[Width * row + col  ] + org_R_L[Width * (row+1) + col ];
			DATA_G_cA = org_G_L[Width * row + col  ] + org_G_L[Width * (row+1) + col ];
			DATA_B_cA = org_B_L[Width * row + col  ] + org_B_L[Width * (row+1) + col ];
			/////////////////////////////////////////////////LH/////////////////////////////////////////////////
			DATA_R_cH = org_R_L[Width * row + col  ] - org_R_L[Width * (row+1) + col ];
			DATA_G_cH = org_G_L[Width * row + col  ] - org_G_L[Width * (row+1) + col ];
			DATA_B_cH = org_B_L[Width * row + col  ] - org_B_L[Width * (row+1) + col ];
			/////////////////////////////////////////////////HL/////////////////////////////////////////////////
			DATA_R_cV = org_R_H[Width * row + col  ] + org_R_H[Width * (row+1) + col ]; 
			DATA_G_cV = org_G_H[Width * row + col  ] + org_G_H[Width * (row+1) + col ]; 
			DATA_B_cV = org_B_H[Width * row + col  ] + org_B_H[Width * (row+1) + col ]; 
			/////////////////////////////////////////////////HH/////////////////////////////////////////////////
			DATA_R_cD = org_R_H[Width * row + col  ] - org_R_H[Width * (row+1) + col ];
			DATA_G_cD = org_G_H[Width * row + col  ] - org_G_H[Width * (row+1) + col ];
			DATA_B_cD = org_B_H[Width * row + col  ] - org_B_H[Width * (row+1) + col ];								                     
		end
	end
end

endmodule