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
// Filename       : ime_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump ime in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_IME

integer fp_ime;
integer fp_ime_in;
integer fp_ime_out;
integer i_ime;

initial begin
	fp_ime     = $fopen("./dump/ime.dat","wb");
//  fp_ime_in  = $fopen("./dump/ime_input.dat","wb"); 
    fp_ime_out = $fopen("./dump/ime_output.dat","wb");
end


//--------------------------------------------------------------------------
//	dump IME variables                                                       
//--------------------------------------------------------------------------
reg [127:0]	ime_pixel_line;

always @(posedge clk) begin
	if (tb_top.u_top.u_ime.sysif_start_i) begin
		$fdisplay(fp_ime,"===== Frame: %d  MB x: %d  y: %d =====", 	tb_top.frame_num,                 
																	tb_top.u_top.u_ime.sysif_mb_x_i[7:0], 
																	tb_top.u_top.u_ime.sysif_mb_y_i[7:0]);
		
		for (i_ime=0; i_ime<48; i_ime=i_ime+1'b1) begin
			ime_pixel_line = {
			tb_top.u_top.fetch.u_fetch_luma.u_ram0.ram_2p_64x48_r.mem_array[i_ime], 
			tb_top.u_top.fetch.u_fetch_luma.u_ram0.ram_2p_64x48_l.mem_array[i_ime]};
			$fwrite(fp_ime,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h | ", ime_pixel_line[7:0], 
		                           ime_pixel_line[15:8],
		                           ime_pixel_line[23:16],
		                           ime_pixel_line[31:24],
		                           ime_pixel_line[39:32],
		                           ime_pixel_line[47:40],
		                           ime_pixel_line[55:48],
		                           ime_pixel_line[63:56],
		                           ime_pixel_line[71:64],
		                           ime_pixel_line[79:72],
		                           ime_pixel_line[87:80],
		                           ime_pixel_line[95:88],
		                           ime_pixel_line[103:96],
		                           ime_pixel_line[111:104],
		                           ime_pixel_line[119:112],
		                           ime_pixel_line[127:120]);
		    
		    ime_pixel_line = {
			tb_top.u_top.fetch.u_fetch_luma.u_ram1.ram_2p_64x48_r.mem_array[i_ime], 
			tb_top.u_top.fetch.u_fetch_luma.u_ram1.ram_2p_64x48_l.mem_array[i_ime]};
			$fwrite(fp_ime,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h | ", ime_pixel_line[7:0], 
		                           ime_pixel_line[15:8],
		                           ime_pixel_line[23:16],
		                           ime_pixel_line[31:24],
		                           ime_pixel_line[39:32],
		                           ime_pixel_line[47:40],
		                           ime_pixel_line[55:48],
		                           ime_pixel_line[63:56],
		                           ime_pixel_line[71:64],
		                           ime_pixel_line[79:72],
		                           ime_pixel_line[87:80],
		                           ime_pixel_line[95:88],
		                           ime_pixel_line[103:96],
		                           ime_pixel_line[111:104],
		                           ime_pixel_line[119:112],
		                           ime_pixel_line[127:120]);
		    
		    ime_pixel_line = {
			tb_top.u_top.fetch.u_fetch_luma.u_ram2.ram_2p_64x48_r.mem_array[i_ime], 
			tb_top.u_top.fetch.u_fetch_luma.u_ram2.ram_2p_64x48_l.mem_array[i_ime]};
			$fwrite(fp_ime,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h | ", ime_pixel_line[7:0], 
		                           ime_pixel_line[15:8],
		                           ime_pixel_line[23:16],
		                           ime_pixel_line[31:24],
		                           ime_pixel_line[39:32],
		                           ime_pixel_line[47:40],
		                           ime_pixel_line[55:48],
		                           ime_pixel_line[63:56],
		                           ime_pixel_line[71:64],
		                           ime_pixel_line[79:72],
		                           ime_pixel_line[87:80],
		                           ime_pixel_line[95:88],
		                           ime_pixel_line[103:96],
		                           ime_pixel_line[111:104],
		                           ime_pixel_line[119:112],
		                           ime_pixel_line[127:120]);
		   
		   ime_pixel_line = {
			tb_top.u_top.fetch.u_fetch_luma.u_ram3.ram_2p_64x48_r.mem_array[i_ime], 
			tb_top.u_top.fetch.u_fetch_luma.u_ram3.ram_2p_64x48_l.mem_array[i_ime]};
			$fwrite(fp_ime,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h | ", ime_pixel_line[7:0], 
		                           ime_pixel_line[15:8],
		                           ime_pixel_line[23:16],
		                           ime_pixel_line[31:24],
		                           ime_pixel_line[39:32],
		                           ime_pixel_line[47:40],
		                           ime_pixel_line[55:48],
		                           ime_pixel_line[63:56],
		                           ime_pixel_line[71:64],
		                           ime_pixel_line[79:72],
		                           ime_pixel_line[87:80],
		                           ime_pixel_line[95:88],
		                           ime_pixel_line[103:96],
		                           ime_pixel_line[111:104],
		                           ime_pixel_line[119:112],
		                           ime_pixel_line[127:120]);
		                                                                        
		    ime_pixel_line = {
			tb_top.u_top.fetch.u_fetch_luma.u_ram4.ram_2p_64x48_r.mem_array[i_ime], 
			tb_top.u_top.fetch.u_fetch_luma.u_ram4.ram_2p_64x48_l.mem_array[i_ime]};
			$fwrite(fp_ime,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h | ", ime_pixel_line[7:0], 
		                           ime_pixel_line[15:8],
		                           ime_pixel_line[23:16],
		                           ime_pixel_line[31:24],
		                           ime_pixel_line[39:32],
		                           ime_pixel_line[47:40],
		                           ime_pixel_line[55:48],
		                           ime_pixel_line[63:56],
		                           ime_pixel_line[71:64],
		                           ime_pixel_line[79:72],
		                           ime_pixel_line[87:80],
		                           ime_pixel_line[95:88],
		                           ime_pixel_line[103:96],
		                           ime_pixel_line[111:104],
		                           ime_pixel_line[119:112],
		                           ime_pixel_line[127:120]); 
		     
		    ime_pixel_line = {
			tb_top.u_top.fetch.u_fetch_luma.u_ram5.ram_2p_64x48_r.mem_array[i_ime], 
			tb_top.u_top.fetch.u_fetch_luma.u_ram5.ram_2p_64x48_l.mem_array[i_ime]};
			$fwrite(fp_ime,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h \n", ime_pixel_line[7:0], 
		                           ime_pixel_line[15:8],
		                           ime_pixel_line[23:16],
		                           ime_pixel_line[31:24],
		                           ime_pixel_line[39:32],
		                           ime_pixel_line[47:40],
		                           ime_pixel_line[55:48],
		                           ime_pixel_line[63:56],
		                           ime_pixel_line[71:64],
		                           ime_pixel_line[79:72],
		                           ime_pixel_line[87:80],
		                           ime_pixel_line[95:88],
		                           ime_pixel_line[103:96],
		                           ime_pixel_line[111:104],
		                           ime_pixel_line[119:112],
		                           ime_pixel_line[127:120]);
		end

	end
end

//--------------------------------------------------------------------------
//	dump IME outputs for data check                                       
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_fme.sysif_done_fme_o) begin
		$fdisplay(fp_ime_out,"===== Frame: %d  MB x: %d  y: %d =====", 	tb_top.frame_num, 
																	tb_top.u_top.u_ime.sysif_mb_x_i[7:0], 
																	tb_top.u_top.u_ime.sysif_mb_y_i[7:0]);
		
		$fdisplay(fp_ime_out,"$imv       : %h", tb_top.u_top.u_ime.fmeif_imv_o[191:0]);
		$fdisplay(fp_ime_out,"$mb_type_o : %h", tb_top.u_top.u_ime.fmeif_mb_type_o[14:0]);		
	end
end

//--------------------------------------------------------------------------
//	dump IME all inputs for tb_intra                                      
//--------------------------------------------------------------------------
                                      

`endif