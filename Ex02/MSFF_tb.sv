// Simple test to visually check that MSFF stores values correctly
module MSFF_tb();

  logic clk,d,q;

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  MSFF iDUT(.clk(clk), .d(d), .q(q));
  
  initial begin
    clk=0;    // initialize clk and d
	  d=0;
	  repeat(2) @(posedge clk); // wait for 2 posedge of clk
	  d=1;        // change input value to be stored
	  @(posedge clk);           // wait for next posedge of clk
	  d=0;        // change input value again
	  @(posedge clk);
	  $stop();
  end
  
  // establish a clk that toggles every 5 time units
  always
    #5 clk=~clk;
	
endmodule