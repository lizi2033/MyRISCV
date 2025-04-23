`include "defines.v"

module wb (
    input  wire [`InstBus]      inst_i                      ,            
    input  wire [`InstAddrBus]  inst_addr_i                 ,   
    input  wire [`MemBus]       mem_rdata_i                 ,    
    input  wire                 reg_we_i                    ,                    
    input  wire [`RegAddrBus]   reg_waddr_i                 ,    
    input  wire [`RegBus]       reg_wdata_i                 ,       
    input  wire [`RegBus]       reg1_rdata_i                ,       
    input  wire [`RegBus]       reg2_rdata_i                ,       
    input  wire                 csr_we_i                    ,                    
    input  wire [`MemAddrBus]   csr_waddr_i                 ,    
    input  wire [`RegBus]       csr_rdata_i                 ,        
    input  wire                 div_we_i                    ,
    input  wire [`RegBus]       div_wdata_i                 ,
    input  wire [`RegAddrBus]   div_waddr_i                 ,
    input  wire                 int_assert_i                ,                
    input  wire [`InstAddrBus]  int_addr_i                  ,    
    input  wire [31:0]          op1_add_op2_res_i           ,
    input  wire [31:0]          op1_jump_add_op2_jump_res_i ,
    input  wire                 op1_ge_op2_signed_i         ,
    input  wire                 op1_ge_op2_unsigned_i       ,
    input  wire                 op1_eq_op2_i                ,

    // to regs
    output wire [`RegBus]       reg_wdata_o                 ,     
    output wire                 reg_we_o                    ,                 
    output wire [`RegAddrBus]   reg_waddr_o                 , 

    // to csr reg               
    output reg [`RegBus]        csr_wdata_o                 ,      
    output wire                 csr_we_o                    ,                 
    output wire [`MemAddrBus]   csr_waddr_o                 , 

    // to ctrl              
    output wire                 hold_flag_o                 ,              
    output wire                 jump_flag_o                 ,              
    output wire [`InstAddrBus]  jump_addr_o                  

    
);
 
wire[6:0] opcode;
wire[2:0] funct3;
wire[6:0] funct7;
wire[4:0] rd;
wire[4:0] uimm;

wire[31:0] op1_add_op2_res;
wire[31:0] op1_jump_add_op2_jump_res;
wire op1_ge_op2_signed;
wire op1_ge_op2_unsigned;
wire op1_eq_op2;

reg[`RegBus] reg_wdata;
reg reg_we;
reg[`RegAddrBus] reg_waddr;
reg hold_flag;
reg jump_flag;
reg[`InstAddrBus] jump_addr;

assign opcode = inst_i[6:0];
assign funct3 = inst_i[14:12];
assign funct7 = inst_i[31:25];
assign rd = inst_i[11:7];
assign uimm = inst_i[19:15];

assign op1_add_op2_res           = op1_add_op2_res_i;
assign op1_jump_add_op2_jump_res = op1_jump_add_op2_jump_res_i;
assign op1_ge_op2_signed         = op1_ge_op2_signed_i;
assign op1_ge_op2_unsigned       = op1_ge_op2_unsigned_i;
assign op1_eq_op2                = op1_eq_op2_i;
assign reg_wdata_o = reg_wdata | div_wdata_i;
// 响应中断时不写通用寄存器
assign reg_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: (reg_we || div_we_i);
assign reg_waddr_o = reg_waddr | div_waddr_i;

// // 响应中断时不写内存
// assign mem_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: mem_we;

// // 响应中断时不向总线请求访问内存
// assign mem_req_o = (int_assert_i == `INT_ASSERT)? `RIB_NREQ: mem_req;

// assign hold_flag_o = hold_flag || div_hold_flag;
assign hold_flag_o = hold_flag;
// assign jump_flag_o = jump_flag || div_jump_flag || ((int_assert_i == `INT_ASSERT)? `JumpEnable: `JumpDisable);
assign jump_flag_o = jump_flag || ((int_assert_i == `INT_ASSERT)? `JumpEnable: `JumpDisable);
// assign jump_addr_o = (int_assert_i == `INT_ASSERT)? int_addr_i: (jump_addr | div_jump_addr);
assign jump_addr_o = (int_assert_i == `INT_ASSERT)? int_addr_i : jump_addr;

// 响应中断时不写CSR寄存器
assign csr_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: csr_we_i;
assign csr_waddr_o = csr_waddr_i;

always @ (*) begin
    reg_we = reg_we_i;
    reg_waddr = reg_waddr_i;
    csr_wdata_o = `ZeroWord;
    reg_wdata = reg_wdata_i;
    case (opcode)
    `INST_TYPE_B: begin
        case (funct3)
            `INST_BEQ: begin
                hold_flag = `HoldDisable;
                jump_flag = op1_eq_op2 & `JumpEnable;
                jump_addr = {32{op1_eq_op2}} & op1_jump_add_op2_jump_res;
            end
            `INST_BNE: begin
                hold_flag = `HoldDisable;
                reg_wdata = `ZeroWord;
                jump_flag = (~op1_eq_op2) & `JumpEnable;
                jump_addr = {32{(~op1_eq_op2)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BLT: begin
                hold_flag = `HoldDisable;
                reg_wdata = `ZeroWord;
                jump_flag = (~op1_ge_op2_signed) & `JumpEnable;
                jump_addr = {32{(~op1_ge_op2_signed)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BGE: begin
                hold_flag = `HoldDisable;
                reg_wdata = `ZeroWord;
                jump_flag = (op1_ge_op2_signed) & `JumpEnable;
                jump_addr = {32{(op1_ge_op2_signed)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BLTU: begin
                hold_flag = `HoldDisable;
                reg_wdata = `ZeroWord;
                jump_flag = (~op1_ge_op2_unsigned) & `JumpEnable;
                jump_addr = {32{(~op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BGEU: begin
                hold_flag = `HoldDisable;
                reg_wdata = `ZeroWord;
                jump_flag = (op1_ge_op2_unsigned) & `JumpEnable;
                jump_addr = {32{(op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump_res;
            end
            default: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                reg_wdata = `ZeroWord;
            end
        endcase
        end
    `INST_JAL, `INST_JALR: begin
        hold_flag = `HoldDisable;
        jump_flag = `JumpEnable;
        jump_addr = op1_jump_add_op2_jump_res;
        reg_wdata = op1_add_op2_res;
    end
    `INST_LUI, `INST_AUIPC: begin
        hold_flag = `HoldDisable;
        jump_addr = `ZeroWord;
        jump_flag = `JumpDisable;
        reg_wdata = op1_add_op2_res;
    end
    `INST_NOP_OP: begin
        jump_flag = `JumpDisable;
        hold_flag = `HoldDisable;
        jump_addr = `ZeroWord;
        reg_wdata = `ZeroWord;
    end
    `INST_FENCE: begin
        hold_flag = `HoldDisable;
        reg_wdata = `ZeroWord;
        jump_flag = `JumpEnable;
        jump_addr = op1_jump_add_op2_jump_res;
    end
    `INST_CSR: begin
        jump_flag = `JumpDisable;
        hold_flag = `HoldDisable;
        jump_addr = `ZeroWord;
        case (funct3)
            `INST_CSRRW: begin
                csr_wdata_o = reg1_rdata_i;
                reg_wdata = csr_rdata_i;
            end
            `INST_CSRRS: begin
                csr_wdata_o = reg1_rdata_i | csr_rdata_i;
                reg_wdata = csr_rdata_i;
            end
            `INST_CSRRC: begin
                csr_wdata_o = csr_rdata_i & (~reg1_rdata_i);
                reg_wdata = csr_rdata_i;
            end
            `INST_CSRRWI: begin
                csr_wdata_o = {27'h0, uimm};
                reg_wdata = csr_rdata_i;
            end
            `INST_CSRRSI: begin
                csr_wdata_o = {27'h0, uimm} | csr_rdata_i;
                reg_wdata = csr_rdata_i;
            end
            `INST_CSRRCI: begin
                csr_wdata_o = (~{27'h0, uimm}) & csr_rdata_i;
                reg_wdata = csr_rdata_i;
            end
            default: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                reg_wdata = `ZeroWord;
            end
        endcase
    end
    default: begin
        jump_flag = `JumpDisable;
        hold_flag = `HoldDisable;
        jump_addr = `ZeroWord;
    end
    endcase
end

endmodule