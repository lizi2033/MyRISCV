module mem_wb (
input  wire                     clk                         ,
input  wire                     rst                         ,
// from ctrl                
input  wire [`Hold_Flag_Bus]    hold_flag_i                 , 
input  wire [`Flush_Flag_Bus]   flush_flag_i                ,
input  wire [`InstBus]          inst_i                      ,      
input  wire [`InstAddrBus]      inst_addr_i                 , 
input  wire                     reg_we_i                    ,    
input  wire [`RegAddrBus]       reg_waddr_i                 , 
input  wire [`RegBus]           reg_wdata_i                 , 
input  wire [`RegBus]           reg1_rdata_i                ,
input  wire [`RegBus]           reg2_rdata_i                ,
input  wire                     csr_we_i                    ,    
input  wire [`MemAddrBus]       csr_waddr_i                 , 
input  wire [`RegBus]           csr_rdata_i                 , 
input  wire                     div_we_i                    ,
input  wire [`RegBus]           div_wdata_i                 , 
input  wire [`RegAddrBus]       div_waddr_i                 , 

input  wire [31:0]              op1_add_op2_res_i           ,
input  wire [31:0]              op1_jump_add_op2_jump_res_i ,
input  wire                     op1_ge_op2_signed_i         ,
input  wire                     op1_ge_op2_unsigned_i       ,
input  wire                     op1_eq_op2_i                ,

input  wire [`MemBus]           mem_rdata_i                 ,  
input  wire [`MemBus]           mem_wdata_i                 ,  
input  wire [`MemAddrBus]       mem_raddr_i                 ,  
input  wire [`MemAddrBus]       mem_waddr_i                 ,  
input  wire                     mem_we_i                    ,     
input  wire                     mem_req_i                   ,    

output wire [`InstBus]          inst_o                      ,       
output wire [`InstAddrBus]      inst_addr_o                 ,  
output wire                     reg_we_o                    ,     
output wire [`RegAddrBus]       reg_waddr_o                 ,  
output wire [`RegBus]           reg_wdata_o                 ,  
output wire [`RegBus]           reg1_rdata_o                , 
output wire [`RegBus]           reg2_rdata_o                , 
output wire                     csr_we_o                    ,     
output wire [`MemAddrBus]       csr_waddr_o                 ,  
output wire [`RegBus]           csr_rdata_o                 ,  
output wire                     div_we_o                    ,
output wire [`RegBus]           div_wdata_o                 ,  
output wire [`RegAddrBus]       div_waddr_o                 ,  

output wire [31:0]              op1_add_op2_res_o           ,
output wire [31:0]              op1_jump_add_op2_jump_res_o ,
output wire                     op1_ge_op2_signed_o         ,
output wire                     op1_ge_op2_unsigned_o       ,
output wire                     op1_eq_op2_o                ,
 
output wire [`MemBus]           mem_rdata_o                 , 
output wire [`MemBus]           mem_wdata_o                 , 
output wire [`MemAddrBus]       mem_raddr_o                 , 
output wire [`MemAddrBus]       mem_waddr_o                 , 
output wire                     mem_we_o                    

);

wire hold_en = (hold_flag_i > `Hold_Mem);
wire flush_en = (flush_flag_i > `Flush_Mem) || (hold_flag_i == `Hold_Mem);

wire[`InstBus] inst;
gen_pipe_dff #(32) inst_ff(clk, rst, hold_en, flush_en, `INST_NOP, inst_i, inst);
assign inst_o = inst;

wire[`InstAddrBus] inst_addr;
gen_pipe_dff #(32) inst_addr_ff(clk, rst, hold_en, flush_en, `ZeroWord, inst_addr_i, inst_addr);
assign inst_addr_o = inst_addr;

wire reg_we;
gen_pipe_dff #(1) reg_we_ff(clk, rst, hold_en, flush_en, `WriteDisable, reg_we_i, reg_we);
assign reg_we_o = reg_we;

wire[`RegAddrBus] reg_waddr;
gen_pipe_dff #(5) reg_waddr_ff(clk, rst, hold_en, flush_en, `ZeroReg, reg_waddr_i, reg_waddr);
assign reg_waddr_o = reg_waddr;

wire[`RegBus] reg_wdata;
gen_pipe_dff #(32) reg_wdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, reg_wdata_i, reg_wdata);
assign reg_wdata_o = reg_wdata;

wire[`RegBus] reg1_rdata;
gen_pipe_dff #(32) reg1_rdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, reg1_rdata_i, reg1_rdata);
assign reg1_rdata_o = reg1_rdata;

wire[`RegBus] reg2_rdata;
gen_pipe_dff #(32) reg2_rdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, reg2_rdata_i, reg2_rdata);
assign reg2_rdata_o = reg2_rdata;

wire csr_we;
gen_pipe_dff #(1) csr_we_ff(clk, rst, hold_en, flush_en, `WriteDisable, csr_we_i, csr_we);
assign csr_we_o = csr_we;

wire[`MemAddrBus] csr_waddr;
gen_pipe_dff #(32) csr_waddr_ff(clk, rst, hold_en, flush_en, `ZeroWord, csr_waddr_i, csr_waddr);
assign csr_waddr_o = csr_waddr;

wire[`RegBus] csr_rdata;
gen_pipe_dff #(32) csr_rdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, csr_rdata_i, csr_rdata);
assign csr_rdata_o = csr_rdata;

//div
wire div_we;
gen_pipe_dff #(1) div_we_ff(clk, rst, hold_en, flush_en, `ZeroWord, div_we_i, div_we);
assign div_we_o = div_we;

wire[`RegAddrBus] div_waddr;
gen_pipe_dff #(5) div_waddr_ff(clk, rst, hold_en, flush_en, `ZeroWord, div_waddr_i, div_waddr);
assign div_waddr_o = div_waddr;

wire[`RegBus] div_wdata;
gen_pipe_dff #(32) div_wdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, div_wdata_i, div_wdata);
assign div_wdata_o = div_wdata;

wire[31:0] op1_add_op2_res;
gen_pipe_dff #(32) op1_add_op2_res_ff(clk, rst, hold_en, flush_en, `ZeroWord, op1_add_op2_res_i, op1_add_op2_res);
assign op1_add_op2_res_o = op1_add_op2_res;

wire[31:0] op1_jump_add_op2_jump_res;
gen_pipe_dff #(32) op1_jump_add_op2_jump_res_ff(clk, rst, hold_en, flush_en, `ZeroWord, op1_jump_add_op2_jump_res_i, op1_jump_add_op2_jump_res);
assign op1_jump_add_op2_jump_res_o = op1_jump_add_op2_jump_res;

wire op1_ge_op2_signed;
gen_pipe_dff #(1) op1_ge_op2_signed_ff(clk, rst, hold_en, flush_en, `ZeroWord, op1_ge_op2_signed_i, op1_ge_op2_signed);
assign op1_ge_op2_signed_o = op1_ge_op2_signed;

wire op1_ge_op2_unsigned;
gen_pipe_dff #(1) op1_ge_op2_unsigned_ff(clk, rst, hold_en, flush_en, `ZeroWord, op1_ge_op2_unsigned_i, op1_ge_op2_unsigned);
assign op1_ge_op2_unsigned_o = op1_ge_op2_unsigned;

wire op1_eq_op2;
gen_pipe_dff #(1) op1_eq_op2_ff(clk, rst, hold_en, flush_en, `ZeroWord, op1_eq_op2_i, op1_eq_op2);
assign op1_eq_op2_o = op1_eq_op2;


//mem
wire mem_we;
gen_pipe_dff #(1) mem_we_ff(clk, rst, hold_en, flush_en, `WriteDisable, mem_we_i, mem_we);
assign mem_we_o = mem_we;

wire mem_req;
gen_pipe_dff #(1) mem_req_ff(clk, rst, hold_en, flush_en, `RIB_NREQ, mem_req_i, mem_req);
assign mem_req_o = mem_req;

wire[`MemBus] mem_wdata;
gen_pipe_dff #(32) mem_wdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, mem_wdata_i, mem_wdata);
assign mem_wdata_o = mem_wdata;

wire[`MemAddrBus] mem_raddr;
gen_pipe_dff #(32) mem_raddr_ff(clk, rst, hold_en, flush_en, `ZeroWord, mem_raddr_i, mem_raddr);
assign mem_raddr_o = mem_raddr;

wire[`MemAddrBus] mem_waddr;
gen_pipe_dff #(32) mem_waddr_ff(clk, rst, hold_en, flush_en, `ZeroWord, mem_waddr_i, mem_waddr);
assign mem_waddr_o = mem_waddr;

wire[`MemBus] mem_rdata;
gen_pipe_dff #(32) mem_rdata_ff(clk, rst, hold_en, flush_en, `ZeroWord, mem_rdata_i, mem_rdata);
assign mem_rdata_o = mem_rdata;



endmodule