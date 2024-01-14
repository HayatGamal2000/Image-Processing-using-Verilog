module dwt_idwt_tb;

reg    HCLK, HRESETn;
wire   Write_Done;


Top DUT (
	.HCLK(HCLK),		
	.HRESETn(HRESETn),		
	.Write_Done(Write_Done)
);


initial 
begin 
    HCLK = 0;
    HRESETn     = 0;
    #25 HRESETn = 1;
	
// only first image need 2500000
	
	 #5348320
	if(Write_Done == 1'b1 )
     $display("DWT is Done");
   else
     $display("DWT doesn't work successfully");
  
   #100
   $stop;
	
	 
end

always #10 HCLK = ~HCLK;
endmodule

