// Simple test to visually confirm actiona of a Ring Oscillator
module ring_osc_tb();

  logic EN;
  logic OUT;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  ring_osc iDUT(.EN(EN),.OUT(OUT));
  
  initial begin
    EN = 0;               // start EN as low. What happens if you start EN as high?
	  #15;    // how long do I need to keep EN low for?
	  EN = 1;               // flip EN to see circuit in action
	  #60;    // how long do I need to run to verify that the ring oscillator is working?
	  $stop();
  end
 
endmodule