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
// Filename       : ime_mv_cost.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                  calculate 16 MV cost inside one single
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_mv_cost(
    clk,
    rstn,    
    mvd_x_i,
    mvd_y_i,    
    lambda_i,    
    mv_cost_o
);

input clk;
input rstn;

input  [8:0]                    lambda_i;
input  [`IMVD_LEN-1:0 ]         mvd_x_i;   //6
input  [`IMVD_LEN-1:0 ]         mvd_y_i;

output [`MV_COST_BITS-1:0]      mv_cost_o;    //12 


       
reg    [`MV_COST_BITS-1:0]      mv_cost_o;        
reg    [`SE_LEN-1:0]            se_len_x,se_len_y; //5 

reg    [`MV_COST_BITS-1:0]      mv_cost_temp1,mv_cost_temp2,mv_cost_temp3,mv_cost_temp4,mv_cost_temp5,mv_cost_temp6,mv_cost_temp7,mv_cost_temp8,mv_cost_temp9,mv_cost_temp10,
                                mv_cost_temp11,mv_cost_temp13,mv_cost_temp14,mv_cost_temp16,mv_cost_temp18,mv_cost_temp20,mv_cost_temp23,mv_cost_temp25,mv_cost_temp29,
                                mv_cost_temp32,mv_cost_temp36,mv_cost_temp40,mv_cost_temp45,mv_cost_temp51,mv_cost_temp57,mv_cost_temp64,mv_cost_temp72,mv_cost_temp81,mv_cost_temp91;
reg    [`MV_COST_BITS-1:0]      mv_cost_wire;  


wire   [`FMVD_LEN + 2  :0]      codenum_mvd_x;  //5+2+1=8 
wire   [`FMVD_LEN + 2  :0]      codenum_mvd_y;

wire   [`FMVD_LEN - 1  :0]      mvd_x_wire;
wire   [`FMVD_LEN - 1  :0]      mvd_y_wire;


always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        mv_cost_o  <='b0; 
    else 
        mv_cost_o  <= mv_cost_wire;
end


assign mvd_x_wire = mvd_x_i << 2;
assign mvd_y_wire = mvd_y_i << 2;

assign codenum_mvd_x = (mvd_x_wire[`FMVD_LEN-1] == 1'b0)?((|mvd_x_wire == 1'b0)?1'b1:{mvd_x_wire,1'b0}):({~mvd_x_wire,1'b0}+2'd3);  //??????
assign codenum_mvd_y = (mvd_y_wire[`FMVD_LEN-1] == 1'b0)?((|mvd_y_wire == 1'b0)?1'b1:{mvd_y_wire,1'b0}):({~mvd_y_wire,1'b0}+2'd3);
  
always@(*)begin
    casex(codenum_mvd_x)
        'b1:                se_len_x = 1;
        'b1x:               se_len_x = 3;
        'b1xx:              se_len_x = 5;
        'b1xxx:             se_len_x = 7;
        'b1xxxx:            se_len_x = 9;
        'b1xxxxx:           se_len_x = 11;
        'b1xxxxxx:          se_len_x = 13;
        'b1xxxxxxx:         se_len_x = 15;
        'b1xxxxxxxx:        se_len_x = 17;
        'b1xxxxxxxxx:       se_len_x = 19;
        'b1xxxxxxxxxx:      se_len_x = 21;    //512~1023, -512~-1023
        default:            se_len_x = 0;
    endcase
end
    
always@(*)begin
    casex(codenum_mvd_y)
        'b1:                se_len_y = 1;
        'b1x:               se_len_y = 3;
        'b1xx:              se_len_y = 5;
        'b1xxx:             se_len_y = 7;
        'b1xxxx:            se_len_y = 9;
        'b1xxxxx:           se_len_y = 11;
        'b1xxxxxx:          se_len_y = 13;
        'b1xxxxxxx:         se_len_y = 15;
        'b1xxxxxxxx:        se_len_y = 17;
        'b1xxxxxxxxx:       se_len_y = 19;
        'b1xxxxxxxxxx:      se_len_y = 21;    //512~1023, -512~-1023
        default:            se_len_y = 0;
    endcase
end

 always@(*)begin
    mv_cost_temp1 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 1;
    mv_cost_temp2 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 2;
    mv_cost_temp3 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 3;
    mv_cost_temp4 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 4;
    mv_cost_temp5 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 5;
    mv_cost_temp6 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 6;
    mv_cost_temp7 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 7;
    mv_cost_temp8 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 8;
    mv_cost_temp9 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 9;
    mv_cost_temp10 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 10;
    mv_cost_temp11 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 11;
    mv_cost_temp13 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 13;
    mv_cost_temp14 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 14;
    mv_cost_temp16 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 16;
    mv_cost_temp18 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 18;
    mv_cost_temp20 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 20;
    mv_cost_temp23 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 23;
    mv_cost_temp25 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 25;
    mv_cost_temp29 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 29;
    mv_cost_temp32 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 32;
    mv_cost_temp36 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 36;
    mv_cost_temp40 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 40;
    mv_cost_temp45 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 45;
    mv_cost_temp51 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 51;
    mv_cost_temp57 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 57;
    mv_cost_temp64 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 64;
    mv_cost_temp72 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 72;
    mv_cost_temp81 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 81;
    mv_cost_temp91 = ({7'd0,se_len_x} + {7'd0,se_len_y}) * 91;
end
    
always@(*)begin
    case(lambda_i)
    1:      mv_cost_wire = mv_cost_temp1;
    2:      mv_cost_wire = mv_cost_temp2;
    3:      mv_cost_wire = mv_cost_temp3;
    4:      mv_cost_wire = mv_cost_temp4;
    5:      mv_cost_wire = mv_cost_temp5;  
    6:      mv_cost_wire = mv_cost_temp6;  
    7:      mv_cost_wire = mv_cost_temp7;  
    8:      mv_cost_wire = mv_cost_temp8;  
    9:      mv_cost_wire = mv_cost_temp9;  
    10:     mv_cost_wire = mv_cost_temp10;  
    11:     mv_cost_wire = mv_cost_temp11;
    13:     mv_cost_wire = mv_cost_temp13;   
    14:     mv_cost_wire = mv_cost_temp14;
    16:     mv_cost_wire = mv_cost_temp16;   
    18:     mv_cost_wire = mv_cost_temp18;
    20:     mv_cost_wire = mv_cost_temp20;
    23:     mv_cost_wire = mv_cost_temp23;
    25:     mv_cost_wire = mv_cost_temp25;
    29:     mv_cost_wire = mv_cost_temp29;
    32:     mv_cost_wire = mv_cost_temp32;
    36:     mv_cost_wire = mv_cost_temp36;
    40:     mv_cost_wire = mv_cost_temp40;
    45:     mv_cost_wire = mv_cost_temp45;
    51:     mv_cost_wire = mv_cost_temp51;
    57:     mv_cost_wire = mv_cost_temp57;
    64:     mv_cost_wire = mv_cost_temp64;
    72:     mv_cost_wire = mv_cost_temp72;
    81:     mv_cost_wire = mv_cost_temp81;
    91:     mv_cost_wire = mv_cost_temp91;
    
    //102:    // (lambda==102) -> qp ==51
      
    default: mv_cost_wire = 0;
        
    endcase
end        //end of case(lambda_i)
endmodule