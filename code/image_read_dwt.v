`include "parameter.v" 						// Include definition file
module image_read_dwt
#(
  parameter WIDTH 	= 20, 					// Image width(number of columns)
			HEIGHT 	= 30, 						// Image height (number of rows)
			INFILE  = "input.hex", 				// image file
			START_UP_DELAY = 100, 				// Delay during start up time
			HSYNC_DELAY = 160					// Delay between HSYNC pulses	
)

(
	input HCLK,										// clock					
	input HRESETn,									// Reset (active low)
	output VSYNC,								// Vertical synchronous pulse
	// This signal is often a way to indicate that one entire image is transmitted.
	// Just create and is not used, will be used once a video or many images are transmitted.
	output reg HSYNC,								// Horizontal synchronous pulse
	// An HSYNC indicates that one line of the image is transmitted.
	// Used to be a horizontal synchronous signals for writing bmp file.
    output reg signed [8:0]  DATA_R_L,				// 8 bit Red data (even)
    output reg signed [8:0]  DATA_G_L,				// 8 bit Green data (even)
    output reg signed [8:0]  DATA_B_L,				// 8 bit Blue data (even)
    output reg signed [8:0]  DATA_R_H,				// 8 bit Red  data (odd)
    output reg signed [8:0]  DATA_G_H,				// 8 bit Green data (odd)
    output reg signed [8:0]  DATA_B_H,				// 8 bit Blue data (odd)
	// Process and transmit 2 pixels in parallel to make the process faster, you can modify to transmit 1 pixels or more if needed
	output			  ctrl_done					// Done flag
);
			

parameter sizeOfLengthReal = WIDTH*HEIGHT*3 ; 		// image data : 395304 bytes: 364 * 362 *3 
// local parameters for FSM
localparam		ST_IDLE 	= 2'b00,		// idle state
				ST_VSYNC	= 2'b01,			// state for creating vsync 
				ST_HSYNC	= 2'b10,			// state for creating hsync 
				ST_DATA		= 2'b11;		// state for data processing 
reg [1:0] cstate, 						// current state
		  nstate;							// next state			
reg start;									// start signal: trigger Finite state machine beginning to operate
reg HRESETn_d;								// delayed reset signal: use to create start signal
reg 		ctrl_vsync_run; 				// control signal for vsync counter  
reg [8:0]	ctrl_vsync_cnt;			// counter for vsync
reg 		ctrl_hsync_run;				// control signal for hsync counter
reg [8:0]	ctrl_hsync_cnt;			// counter  for hsync
reg 		ctrl_data_run;					// control signal for data processing
reg [7 : 0]   total_memory [0 : sizeOfLengthReal-1];	// memory to store  8-bit data image
// temporary memory to save image data : size will be WIDTH*HEIGHT*3
integer temp_BMP   [0 : WIDTH*HEIGHT*3 - 1];			
integer org_R  [0 : WIDTH*HEIGHT - 1]; 	// temporary storage for R component
integer org_G  [0 : WIDTH*HEIGHT - 1];	// temporary storage for G component
integer org_B  [0 : WIDTH*HEIGHT - 1];	// temporary storage for B component
// counting variables
integer i, j;
// temporary signals for calculation: details in the paper.

reg [ 8:0] row; // row index of the image
reg [ 8:0] col; // column index of the image
reg [16:0] data_count; // data counting for entire pixels of the image




// -------- Reading data from input file ----------//
initial begin
    $readmemh(INFILE,total_memory,0,sizeOfLengthReal-1); // read file from INFILE
end
// use 3 intermediate signals RGB to save image data
always@(start) begin
    if(start == 1'b1) begin
        for(i=0; i<WIDTH*HEIGHT*3 ; i=i+1) begin
            temp_BMP[i] = total_memory[i+0][7:0]; 
        end
        
        for(i=0; i<HEIGHT; i=i+1) begin
            for(j=0; j<WIDTH; j=j+1) begin
                org_R[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+0]; // save Red component
                org_G[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+1];// save Green component
                org_B[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+2];// save Blue component
            end
        end
    end
end


//-------Begin to read image file once reset was high by creating a starting pulse (start)-------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(!HRESETn) begin
        start <= 0;
		HRESETn_d <= 0;
    end
    else begin											//        		______ 				
        HRESETn_d <= HRESETn;							//       	|		|
		if(HRESETn == 1'b1 && HRESETn_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
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
    else begin
        cstate <= nstate; // update next state 
    end
end


//--------- State Transition --------------//
// IDLE . VSYNC . HSYNC . DATA
always @(*) begin
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
				if(col == WIDTH - 2)
					nstate = ST_HSYNC;
				else
					nstate = ST_DATA;
			end
		end
	endcase
end


// --- counting for time period of vsync, hsync, data processing ----  //
always @(*) begin
	ctrl_vsync_run = 0;
	ctrl_hsync_run = 0;
	ctrl_data_run  = 0;
	case(cstate)
		ST_VSYNC: 	begin ctrl_vsync_run = 1; end 	// trigger counting for vsync
		ST_HSYNC: 	begin ctrl_hsync_run = 1; end	// trigger counting for hsync
		ST_DATA: 	begin ctrl_data_run  = 1; end	// trigger counting for data processing
	endcase
end
// counters for vsync, hsync
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        ctrl_vsync_cnt <= 0;
		ctrl_hsync_cnt <= 0;
    end
    else begin
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
		if(ctrl_data_run) begin
			if(col == WIDTH - 2) begin
				row <= row + 1;
			end
			if(col == WIDTH - 2) 
				col <= 0;
			else 
				col <= col + 2; // reading 2 pixels in parallel
		end
	end
end


//----------------Data counting---------- ---------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(ctrl_data_run)
			data_count <= data_count + 1;
    end
end
assign VSYNC = ctrl_vsync_run;
assign ctrl_done = (data_count == ((WIDTH*HEIGHT)/2))? 1'b1: 1'b0; // done flag 



//-------------  Image processing   ---------------//
always @(*) begin
	
	HSYNC   = 1'b0;
	DATA_R_L = 0;
	DATA_G_L = 0;
	DATA_B_L = 0;                                       
	DATA_R_H = 0;
	DATA_G_H = 0;
	DATA_B_H = 0;                                         
	if(ctrl_data_run) begin
		
		HSYNC   = 1'b1;
		`ifdef DWT_1D_Haar 
		/**************************************/		
		/*	      	DWT_1-D_Haar       		*/
		/**************************************/
		/////////////////////////////////////////////////L/////////////////////////////////////////////////
		DATA_R_L = ( org_R[WIDTH * row + col  ] + org_R[WIDTH * row + col+1  ]) >>1;
		DATA_G_L = ( org_G[WIDTH * row + col  ] + org_G[WIDTH * row + col+1  ]) >>1;
		DATA_B_L = ( org_B[WIDTH * row + col  ] + org_B[WIDTH * row + col+1  ]) >>1;
		/////////////////////////////////////////////////H/////////////////////////////////////////////////
        DATA_R_H = ( org_R[WIDTH * row + col  ] - org_R[WIDTH * row + col+1  ]) >>1;
		DATA_G_H = ( org_G[WIDTH * row + col  ] - org_G[WIDTH * row + col+1  ]) >>1;
		DATA_B_H = ( org_B[WIDTH * row + col  ] - org_B[WIDTH * row + col+1  ]) >>1;
		`endif
	end
end

endmodule

