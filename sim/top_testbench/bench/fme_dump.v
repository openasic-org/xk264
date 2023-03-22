//-------------------------------------------------------------------
//                                                                 
//  COPYRIGHT (C) 2011, VIPcore Group, Fudan University
//                                                                  
//  THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE      
//  EXPRESSED WRITTEN CONSENT OF VIPcore Group
//                                                                  
//  VIPcore       : http://soc.fudan.edu.cn/vip    
//  IP Owner 	  : Yibo FAN
//  Contact       : fanyibo@fudan.edu.cn             
//-------------------------------------------------------------------
// Filename       : fme_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump fme in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_FME

integer fp_fme;
integer fp_fme_in;
integer fp_fme_out;
integer i_fme;

initial begin
//	fp_fme  = $fopen("./dump/fme.dat","wb");
//  fp_fme_in  = $fopen("./dump/fme_input.dat","wb"); 
    fp_fme_out = $fopen("./dump/fme_output.dat","wb");
end


//--------------------------------------------------------------------------
//	dump FME variables                                                       
//--------------------------------------------------------------------------


//--------------------------------------------------------------------------
//	dump FME outputs for data check                                       
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_fme.sysif_done_fme_o) begin
		$fdisplay(fp_fme_out,"===== Frame: %d  MB x: %d  y: %d =====", 	tb_top.frame_num, 
																	tb_top.u_top.u_fme.sysif_cmb_x_i[7:0], 
																	tb_top.u_top.u_fme.sysif_cmb_y_i[7:0]);
		
		$fdisplay(fp_fme_out,"$imv       : %h", tb_top.u_top.u_fme.mcif_imv_o[191:0]);
		$fdisplay(fp_fme_out,"$fmv       : %h", tb_top.u_top.u_fme.mcif_fmv_o[255:0]);		
	end
end

//--------------------------------------------------------------------------
//	dump FME all inputs for tb_intra                                      
//--------------------------------------------------------------------------

                                      

`endif