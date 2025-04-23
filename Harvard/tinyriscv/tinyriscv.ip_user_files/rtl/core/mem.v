module mem (
    
// from exe
input  wire [`InstBus]          inst_i                      ,       
input  wire [`InstAddrBus]      inst_addr_i                 ,  
input  wire [`RegAddrBus]       reg1_raddr_i                ,
input  wire [`RegAddrBus]       reg2_raddr_i                ,
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
input  wire                     int_assert_i                , 
input  wire [`InstAddrBus]      int_addr_i                  ,   
input  wire [1:0]               mem_raddr_index_i           ,
input  wire [1:0]               mem_waddr_index_i           ,
input  wire [31:0]              op1_add_op2_res_i           ,
input  wire [31:0]              op1_jump_add_op2_jump_res_i ,
input  wire                     op1_ge_op2_signed_i         ,
input  wire                     op1_ge_op2_unsigned_i       ,
input  wire                     op1_eq_op2_i                ,
// from mem 
input  wire [`MemBus]           mem_rdata_i                 ,  

output wire [`InstBus]          inst_o                      ,       
output wire [`InstAddrBus]      inst_addr_o                 ,  
output wire [`RegAddrBus]       reg1_raddr_o                ,
output wire [`RegAddrBus]       reg2_raddr_o                ,
output wire                     reg_we_o                    ,     
output wire [`RegAddrBus]       reg_waddr_o                 ,  
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
// to mem   
output reg [`MemBus]            mem_wdata_o                 ,
output reg [`MemAddrBus]        mem_raddr_o                 ,
output reg [`MemAddrBus]        mem_waddr_o                 ,
output wire                     mem_we_o                    ,   
output wire                     mem_req_o                   ,  

output wire[`RegBus]            reg_wdata_o                 ,
output wire                     hold_flag_o                  

);

wire[6:0] opcode;
wire[2:0] funct3;
wire[6:0] funct7;
wire[4:0] rd;
wire[4:0] uimm;
     
wire[1:0] mem_raddr_index;
wire[1:0] mem_waddr_index;
wire[31:0] op1_add_op2_res;
wire[31:0] op1_jump_add_op2_jump_res;
wire op1_ge_op2_signed;
wire op1_ge_op2_unsigned;
wire op1_eq_op2;

reg hold_flag;
reg mem_we;
reg mem_req;
reg[`RegBus] reg_wdata;

assign opcode = inst_i[6:0];
assign funct3 = inst_i[14:12];
assign funct7 = inst_i[31:25];
assign rd = inst_i[11:7];
assign uimm = inst_i[19:15];

assign inst_o = inst_i;
assign inst_addr_o = inst_addr_i;
assign reg_we_o = reg_we_i;
assign reg_waddr_o = reg_waddr_i;
assign reg_wdata_o = reg_wdata;
assign reg1_rdata_o = reg1_rdata_i;
assign reg2_rdata_o = reg2_rdata_i;
assign csr_we_o = csr_we_i;
assign csr_waddr_o = csr_waddr_i;
assign csr_rdata_o = csr_rdata_i;

assign op1_add_op2_res = op1_add_op2_res_i;
assign op1_jump_add_op2_jump_res = op1_jump_add_op2_jump_res_i;
assign op1_ge_op2_signed = op1_ge_op2_signed_i;
assign op1_ge_op2_unsigned = op1_ge_op2_unsigned_i;
assign op1_eq_op2 = op1_eq_op2_i;
assign mem_raddr_index = mem_raddr_index_i;
assign mem_waddr_index = mem_waddr_index_i;

assign op1_add_op2_res_o = op1_add_op2_res;
assign op1_jump_add_op2_jump_res_o = op1_jump_add_op2_jump_res;
assign op1_ge_op2_signed_o = op1_ge_op2_signed;
assign op1_ge_op2_unsigned_o = op1_ge_op2_unsigned;
assign op1_eq_op2_o = op1_eq_op2;
assign div_we_o = div_we_i;
assign div_wdata_o = div_wdata_i;
assign div_waddr_o = div_waddr_i;

assign reg1_raddr_o  = reg1_raddr_i;
assign reg2_raddr_o  = reg2_raddr_i;

assign hold_flag_o = hold_flag;
// 响应中断时不写内存
assign mem_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: mem_we;

// 响应中断时不向总线请求访问内存
assign mem_req_o = (int_assert_i == `INT_ASSERT)? `RIB_NREQ: mem_req;

always @ (*) begin
    mem_req = `RIB_NREQ;
    reg_wdata = reg_wdata_i;
    case (opcode)
        `INST_TYPE_L: begin
        hold_flag = `HoldEnable;
            case (funct3)
                `INST_LB: begin
                    // hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    mem_req = `RIB_REQ;
                    mem_raddr_o = op1_add_op2_res;
                    case (mem_raddr_index)
                    2'b00: begin
                        reg_wdata = {{24{mem_rdata_i[7]}}, mem_rdata_i[7:0]};
                    end
                    2'b01: begin
                        reg_wdata = {{24{mem_rdata_i[15]}}, mem_rdata_i[15:8]};
                    end
                    2'b10: begin
                        reg_wdata = {{24{mem_rdata_i[23]}}, mem_rdata_i[23:16]};
                    end
                    default: begin
                        reg_wdata = {{24{mem_rdata_i[31]}}, mem_rdata_i[31:24]};
                    end
                endcase
                end
                `INST_LH: begin
                    // hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    mem_req = `RIB_REQ;
                    mem_raddr_o = op1_add_op2_res;
                    if (mem_raddr_index == 2'b0) begin
                        reg_wdata = {{16{mem_rdata_i[15]}}, mem_rdata_i[15:0]};
                    end else begin
                        reg_wdata = {{16{mem_rdata_i[31]}}, mem_rdata_i[31:16]};
                    end
                end
                `INST_LW: begin
                    // hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    mem_req = `RIB_REQ;
                    mem_raddr_o = op1_add_op2_res;
                    reg_wdata = mem_rdata_i;
                end
                `INST_LBU: begin
                    // hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    mem_req = `RIB_REQ;
                    mem_raddr_o = op1_add_op2_res;
                    case (mem_raddr_index)
                            2'b00: begin
                                reg_wdata = {24'h0, mem_rdata_i[7:0]};
                            end
                            2'b01: begin
                                reg_wdata = {24'h0, mem_rdata_i[15:8]};
                            end
                            2'b10: begin
                                reg_wdata = {24'h0, mem_rdata_i[23:16]};
                            end
                            default: begin
                                reg_wdata = {24'h0, mem_rdata_i[31:24]};
                            end
                        endcase
                end
                `INST_LHU: begin
                    // hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    mem_req = `RIB_REQ;
                    mem_raddr_o = op1_add_op2_res;
                    if (mem_raddr_index == 2'b0) begin
                        reg_wdata = {16'h0, mem_rdata_i[15:0]};
                    end else begin
                        reg_wdata = {16'h0, mem_rdata_i[31:16]};
                    end
                end
                default: begin
                    hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                    reg_wdata = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_S: begin
        reg_wdata = `ZeroWord;
        hold_flag = `HoldDisable;
            case (funct3)
                `INST_SB: begin
                    // hold_flag = `HoldDisable;
                    mem_we = `WriteEnable;
                    mem_req = `RIB_REQ;
                    mem_waddr_o = op1_add_op2_res;
                    mem_raddr_o = op1_add_op2_res;
                    case (mem_waddr_index)
                        2'b00: begin
                            mem_wdata_o = {24'h0, reg2_rdata_i[7:0]};
                        end
                        2'b01: begin
                            mem_wdata_o = {16'h0, reg2_rdata_i[7:0], 8'h0};
                        end
                        2'b10: begin
                            mem_wdata_o = {8'h0, reg2_rdata_i[7:0], 16'h0};
                        end
                        default: begin
                            mem_wdata_o = {reg2_rdata_i[7:0], 24'h0};
                        end
                    endcase
                end
                `INST_SH: begin
                    // hold_flag = `HoldDisable;
                    mem_we = `WriteEnable;
                    mem_req = `RIB_REQ;
                    mem_waddr_o = op1_add_op2_res;
                    mem_raddr_o = op1_add_op2_res;
                    if (mem_waddr_index == 2'b00) begin
                        mem_wdata_o = {16'h0, reg2_rdata_i[15:0]};
                    end else begin
                        mem_wdata_o = {reg2_rdata_i[15:0], 16'h0};
                    end
                end
                `INST_SW: begin
                    // hold_flag = `HoldDisable;
                    mem_we = `WriteEnable;
                    mem_req = `RIB_REQ;
                    mem_waddr_o = op1_add_op2_res;
                    mem_raddr_o = op1_add_op2_res;
                    mem_wdata_o = reg2_rdata_i;
                end
                default: begin
                    hold_flag = `HoldDisable;
                    mem_wdata_o = `ZeroWord;
                    mem_raddr_o = `ZeroWord;
                    mem_waddr_o = `ZeroWord;
                    mem_we = `WriteDisable;
                end
            endcase
        end
        default: begin
            hold_flag = `HoldDisable;
            mem_wdata_o = `ZeroWord;
            mem_raddr_o = `ZeroWord;
            mem_waddr_o = `ZeroWord;
            mem_we = `WriteDisable;
            reg_wdata = reg_wdata_i;
        end
    endcase
end

endmodule