module ex (
    // from id
    input  wire [`InstBus]      inst_i                      ,   // 指令内容
    input  wire [`InstAddrBus]  inst_addr_i                 ,   // 指令地址
    input  wire [`RegAddrBus]   reg1_raddr_i                ,
    input  wire [`RegAddrBus]   reg2_raddr_i                ,
    input  wire [`RegBus]       reg1_rdata_i                ,   // 通用寄存器1输入数据
    input  wire [`RegBus]       reg2_rdata_i                ,   // 通用寄存器2输入数据
    input  wire                 reg_we_i                    ,   // 是否写通用寄存器
    input  wire [`RegAddrBus]   reg_waddr_i                 ,   // 写通用寄存器地址
    input  wire                 int_assert_i                ,   // 中断发生标志
    input  wire [`InstAddrBus]  int_addr_i                  ,   // 中断跳转地址
    input  wire                 csr_we_i                    ,   // 是否写CSR寄存器
    input  wire [`MemAddrBus]   csr_waddr_i                 ,   // 写CSR寄存器地址
    input  wire [`RegBus]       csr_rdata_i                 ,   // CSR寄存器输入数据
    input  wire [`MemAddrBus]   op1_i                       ,
    input  wire [`MemAddrBus]   op2_i                       ,
    input  wire [`MemAddrBus]   op1_jump_i                  ,
    input  wire [`MemAddrBus]   op2_jump_i                  ,
    // from div         
    input wire                  div_ready_i                 ,   // 除法运算完成标志
    input wire  [`RegBus]       div_result_i                ,   // 除法运算结果
    input wire                  div_busy_i                  ,   // 除法运算忙标志
    input wire  [`RegAddrBus]   div_reg_waddr_i             ,   // 除法运算结束后要写的寄存器地址
    // to em
    output wire [`InstBus]      inst_o                      ,   // 指令内容
    output wire [`InstAddrBus]  inst_addr_o                 ,   // 指令地址
    output wire [`RegAddrBus]   reg1_raddr_o                ,
    output wire [`RegAddrBus]   reg2_raddr_o                ,
    output wire [`RegBus]       reg1_rdata_o                ,   // 通用寄存器1输入数据
    output wire [`RegBus]       reg2_rdata_o                ,   // 通用寄存器2输入数据
    output wire                 reg_we_o                    ,   // 是否写通用寄存器
    output wire [`RegAddrBus]   reg_waddr_o                 ,   // 写通用寄存器地址
    output wire [`RegBus]       reg_wdata_o                 ,
    output wire                 csr_we_o                    ,   // 是否写CSR寄存器
    output wire [`MemAddrBus]   csr_waddr_o                 ,   // 写CSR寄存器地址
    output wire [`RegBus]       csr_rdata_o                 ,   // CSR寄存器输入数据
    output wire [1:0]           mem_raddr_index_o           ,
    output wire [1:0]           mem_waddr_index_o           ,
    output wire [31:0]          op1_add_op2_res_o           ,
    output wire [31:0]          op1_jump_add_op2_jump_res_o ,
    output wire                 op1_ge_op2_signed_o         ,
    output wire                 op1_ge_op2_unsigned_o       ,
    output wire                 op1_eq_op2_o                ,
    // to div           
    output wire                 div_start_o                 ,   // 开始除法运算标志
    output reg  [`RegBus]       div_dividend_o              ,   // 被除数
    output reg  [`RegBus]       div_divisor_o               ,   // 除数
    output reg  [2:0]           div_op_o                    ,   // 具体是哪一条除法指令
    output reg  [`RegAddrBus]   div_reg_waddr_o             ,   // 除法运算结束后要写的寄存器地址
    output wire                 div_we_o                    ,   // 是否写除法寄存器
    output wire [`RegBus]       div_wdata_o                 ,   // 除法寄存器写数据
    output wire [`RegAddrBus]   div_waddr_o                 ,   // 除法寄存器写地址
    output wire                 div_hold_flag_o             ,   // 除法运算暂停标志
    output wire                 div_jump_flag_o             ,   // 除法运算跳转标志
    output wire [`InstAddrBus]  div_jump_addr_o             ,   // 除法运算跳转地址
    
    output wire                 is_load_o                   ,
    output wire                 jump_flag_o                 ,   // 跳转标志
    output wire [`InstAddrBus]  jump_addr_o                      // 跳转地址

);
    
    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    wire[4:0] rd;
    wire[4:0] uimm;
    wire[31:0] reg1_data_invert;
    wire[31:0] reg2_data_invert;       
    wire[1:0] mem_raddr_index;
    wire[1:0] mem_waddr_index;
    wire[`DoubleRegBus] mul_temp;
    wire[`DoubleRegBus] mul_temp_invert;
    wire[31:0] sr_shift;
    wire[31:0] sri_shift;
    wire[31:0] sr_shift_mask;
    wire[31:0] sri_shift_mask;
    wire[31:0] op1_add_op2_res;
    wire[31:0] op1_jump_add_op2_jump_res;
    wire op1_ge_op2_signed;
    wire op1_ge_op2_unsigned;
    wire op1_eq_op2;
    reg hold_flag;
    reg jump_flag;
    reg[`InstAddrBus] jump_addr;
    reg[`RegBus] mul_op1;
    reg[`RegBus] mul_op2;

    reg div_start;
    reg div_we;         
    reg[`RegBus] div_wdata;
    reg[`RegAddrBus] div_waddr;
    reg div_hold_flag;
    reg div_jump_flag;          
    reg[`InstAddrBus] div_jump_addr;
    reg  is_load;

    reg[`RegBus] reg_wdata;
    
assign opcode = inst_i[6:0];
assign funct3 = inst_i[14:12];
assign funct7 = inst_i[31:25];
assign rd = inst_i[11:7];
assign uimm = inst_i[19:15];

assign sr_shift = reg1_rdata_i >> reg2_rdata_i[4:0];
assign sri_shift = reg1_rdata_i >> inst_i[24:20];
assign sr_shift_mask = 32'hffffffff >> reg2_rdata_i[4:0];
assign sri_shift_mask = 32'hffffffff >> inst_i[24:20];

assign op1_add_op2_res = op1_i + op2_i;
assign op1_jump_add_op2_jump_res = op1_jump_i + op2_jump_i;

assign reg1_data_invert = ~reg1_rdata_i + 1;
assign reg2_data_invert = ~reg2_rdata_i + 1;

// 有符号数比较
assign op1_ge_op2_signed = $signed(op1_i) >= $signed(op2_i);
// 无符号数比较
assign op1_ge_op2_unsigned = op1_i >= op2_i;
assign op1_eq_op2 = (op1_i == op2_i);

assign mul_temp = mul_op1 * mul_op2;
assign mul_temp_invert = ~mul_temp + 1;

assign mem_raddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) & 2'b11;
assign mem_waddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]}) & 2'b11;

assign div_start_o = (int_assert_i == `INT_ASSERT)? `DivStop: div_start;
// assign div_start_o = div_start;
assign div_we_o = div_we;
assign div_wdata_o = div_wdata;
assign div_waddr_o = div_waddr;
assign div_hold_flag_o = div_hold_flag;

assign inst_addr_o = inst_addr_i;
assign reg1_raddr_o  = reg1_raddr_i;
assign reg2_raddr_o  = reg2_raddr_i;
assign reg_wdata_o = reg_wdata;
assign jump_flag_o = jump_flag;
assign jump_addr_o = (int_assert_i == `INT_ASSERT)? int_addr_i: jump_addr;

// assign reg_wdata_o = reg_wdata | div_wdata;
// 响应中断时不写通用寄存器
// assign reg_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: (reg_we || div_we);
// assign reg_waddr_o = reg_waddr | div_waddr;

// 响应中断时不写内存
// assign mem_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: mem_we;

// 响应中断时不向总线请求访问内存
// assign mem_req_o = (int_assert_i == `INT_ASSERT)? `RIB_NREQ: mem_req;

assign hold_flag_o = hold_flag || div_hold_flag;
// assign jump_flag_o = jump_flag || div_jump_flag || ((int_assert_i == `INT_ASSERT)? `JumpEnable: `JumpDisable);
// assign jump_addr_o = (int_assert_i == `INT_ASSERT)? int_addr_i: (jump_addr | div_jump_addr);

// 响应中断时不写CSR寄存器
// assign csr_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: csr_we_i;
// assign csr_waddr_o = csr_waddr_i;

assign inst_o = inst_i;
assign reg_we_o = reg_we_i;
assign reg_waddr_o = reg_waddr_i;
assign reg1_rdata_o = reg1_rdata_i;
assign reg2_rdata_o = reg2_rdata_i;
assign csr_we_o = csr_we_i;
assign csr_waddr_o = csr_waddr_i;
assign csr_rdata_o = csr_rdata_i;

assign mem_raddr_index_o            = mem_raddr_index           ;
assign mem_waddr_index_o            = mem_waddr_index           ;
assign op1_add_op2_res_o            = op1_add_op2_res           ;
assign op1_jump_add_op2_jump_res_o  = op1_jump_add_op2_jump_res ;
assign op1_ge_op2_signed_o          = op1_ge_op2_signed         ;
assign op1_ge_op2_unsigned_o        = op1_ge_op2_unsigned       ;
assign op1_eq_op2_o                 = op1_eq_op2                ;
assign is_load_o                     = is_load                  ;

// 处理乘法指令
always @ (*) begin
    if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
        case (funct3)
            `INST_MUL, `INST_MULHU: begin
                mul_op1 = reg1_rdata_i;
                mul_op2 = reg2_rdata_i;
            end
            `INST_MULHSU: begin
                mul_op1 = (reg1_rdata_i[31] == 1'b1)? (reg1_data_invert): reg1_rdata_i;
                mul_op2 = reg2_rdata_i;
            end
            `INST_MULH: begin
                mul_op1 = (reg1_rdata_i[31] == 1'b1)? (reg1_data_invert): reg1_rdata_i;
                mul_op2 = (reg2_rdata_i[31] == 1'b1)? (reg2_data_invert): reg2_rdata_i;
            end
            default: begin
                mul_op1 = reg1_rdata_i;
                mul_op2 = reg2_rdata_i;
            end
        endcase
    end else begin
        mul_op1 = reg1_rdata_i;
        mul_op2 = reg2_rdata_i;
    end
end

// 处理除法指令
always @ (*) begin
    div_dividend_o = reg1_rdata_i;
    div_divisor_o = reg2_rdata_i;
    div_op_o = funct3;
    div_reg_waddr_o = reg_waddr_i;
    if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
        div_we = `WriteDisable;
        div_wdata = `ZeroWord;
        div_waddr = `ZeroWord;
        case (funct3)
            `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
                div_start = `DivStart;
                // div_jump_flag = `JumpEnable;
                div_hold_flag = `HoldEnable;
                // div_jump_addr = op1_jump_add_op2_jump_res;
            end
            default: begin
                div_start = `DivStop;
                // div_jump_flag = `JumpDisable;
                div_hold_flag = `HoldDisable;
                // div_jump_addr = `ZeroWord;
            end
        endcase
    end else begin
        // div_jump_flag = `JumpDisable;
        // div_jump_addr = `ZeroWord;
        if (div_busy_i == `True) begin
            div_start = `DivStart;
            div_we = `WriteDisable;
            div_wdata = `ZeroWord;
            div_waddr = `ZeroWord;
            div_hold_flag = `HoldEnable;
        end else begin
            div_start = `DivStop;
            div_hold_flag = `HoldDisable;
            if (div_ready_i == `DivResultReady) begin
                div_wdata = div_result_i;
                div_waddr = div_reg_waddr_i;
                div_we = `WriteEnable;
            end else begin
                div_we = `WriteDisable;
                div_wdata = `ZeroWord;
                div_waddr = `ZeroWord;
            end
        end
    end
end

    // 执行
always @ (*) begin
    is_load = 1'b0;
    case (opcode)
        `INST_TYPE_I: begin
        jump_flag = `JumpDisable;
        jump_addr = `ZeroWord;
            case (funct3)
                `INST_ADDI: begin
                    reg_wdata = op1_add_op2_res;
                end
                `INST_SLTI: begin
                    reg_wdata = {32{(~op1_ge_op2_signed)}} & 32'h1;
                end
                `INST_SLTIU: begin
                    reg_wdata = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                end
                `INST_XORI: begin
                    reg_wdata = op1_i ^ op2_i;
                end
                `INST_ORI: begin
                    reg_wdata = op1_i | op2_i;
                end
                `INST_ANDI: begin
                    reg_wdata = op1_i & op2_i;
                end
                `INST_SLLI: begin
                    reg_wdata = reg1_rdata_i << inst_i[24:20];
                end
                `INST_SRI: begin
                    if (inst_i[30] == 1'b1) begin
                        reg_wdata = (sri_shift & sri_shift_mask) | ({32{reg1_rdata_i[31]}} & (~sri_shift_mask));
                    end else begin
                        reg_wdata = reg1_rdata_i >> inst_i[24:20];
                    end
                end
                default: begin
                    reg_wdata = `ZeroWord;
                end
            endcase
        end
        `INST_TYPE_R_M: begin
            jump_flag = `JumpDisable;
            jump_addr = `ZeroWord;
            if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                case (funct3)
                    `INST_ADD_SUB: begin
                        if (inst_i[30] == 1'b0) begin
                            reg_wdata = op1_add_op2_res;
                        end else begin
                            reg_wdata = op1_i - op2_i;
                        end
                    end
                    `INST_SLL: begin
                        reg_wdata = op1_i << op2_i[4:0];
                    end
                    `INST_SLT: begin
                        reg_wdata = {32{(~op1_ge_op2_signed)}} & 32'h1;
                    end
                    `INST_SLTU: begin
                        reg_wdata = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                    end
                    `INST_XOR: begin
                        reg_wdata = op1_i ^ op2_i;
                    end
                    `INST_SR: begin
                        if (inst_i[30] == 1'b1) begin
                            reg_wdata = (sr_shift & sr_shift_mask) | ({32{reg1_rdata_i[31]}} & (~sr_shift_mask));
                        end else begin
                            reg_wdata = reg1_rdata_i >> reg2_rdata_i[4:0];
                        end
                    end
                    `INST_OR: begin
                        reg_wdata = op1_i | op2_i;
                    end
                    `INST_AND: begin
                        reg_wdata = op1_i & op2_i;
                    end
                    default: begin
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end else if (funct7 == 7'b0000001) begin
                case (funct3)
                    `INST_MUL: begin
                        reg_wdata = mul_temp[31:0];
                    end
                    `INST_MULHU: begin
                        reg_wdata = mul_temp[63:32];
                    end
                    `INST_MULH: begin
                        case ({reg1_rdata_i[31], reg2_rdata_i[31]})
                            2'b00: begin
                                reg_wdata = mul_temp[63:32];
                            end
                            2'b11: begin
                                reg_wdata = mul_temp[63:32];
                            end
                            2'b10: begin
                                reg_wdata = mul_temp_invert[63:32];
                            end
                            default: begin
                                reg_wdata = mul_temp_invert[63:32];
                            end
                        endcase
                    end
                    `INST_MULHSU: begin
                        if (reg1_rdata_i[31] == 1'b1) begin
                            reg_wdata = mul_temp_invert[63:32];
                        end else begin
                            reg_wdata = mul_temp[63:32];
                        end
                    end
                    default: begin
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end else begin
                reg_wdata = `ZeroWord;
            end
        end
        `INST_TYPE_L: begin
        jump_flag = `JumpDisable;
        jump_addr = `ZeroWord;
        reg_wdata = `ZeroWord;
        is_load = 1'b1;
    end
        `INST_TYPE_B: begin
        reg_wdata = `ZeroWord;
        case (funct3)
            `INST_BEQ: begin
                jump_flag = op1_eq_op2 & `JumpEnable;
                jump_addr = {32{op1_eq_op2}} & op1_jump_add_op2_jump_res;
            end
            `INST_BNE: begin
                jump_flag = (~op1_eq_op2) & `JumpEnable;
                jump_addr = {32{(~op1_eq_op2)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BLT: begin
                jump_flag = (~op1_ge_op2_signed) & `JumpEnable;
                jump_addr = {32{(~op1_ge_op2_signed)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BGE: begin
                jump_flag = (op1_ge_op2_signed) & `JumpEnable;
                jump_addr = {32{(op1_ge_op2_signed)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BLTU: begin
                jump_flag = (~op1_ge_op2_unsigned) & `JumpEnable;
                jump_addr = {32{(~op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump_res;
            end
            `INST_BGEU: begin
                jump_flag = (op1_ge_op2_unsigned) & `JumpEnable;
                jump_addr = {32{(op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump_res;
            end
            default: begin
                jump_flag = `JumpDisable;
                jump_addr = `ZeroWord;
            end
        endcase
        end
        `INST_JAL, `INST_JALR: begin
            jump_flag = `JumpEnable;
            jump_addr = op1_jump_add_op2_jump_res;
            reg_wdata = op1_add_op2_res;
        end
        `INST_LUI, `INST_AUIPC: begin
            jump_flag = `JumpDisable;
            jump_addr = `ZeroWord;
            reg_wdata = op1_add_op2_res;
        end
        `INST_FENCE: begin
            jump_flag = `JumpEnable;
            jump_addr = op1_jump_add_op2_jump_res;
            reg_wdata = `ZeroWord;
        end
        // `INST_CSR: begin
        //     jump_flag = `JumpDisable;
        //     jump_addr = `ZeroWord;
        //     case (funct3)
        //         `INST_CSRRW: begin
        //             reg_wdata = csr_rdata_i;
        //         end
        //         `INST_CSRRS: begin
        //             reg_wdata = csr_rdata_i;
        //         end
        //         `INST_CSRRC: begin
        //             reg_wdata = csr_rdata_i;
        //         end
        //         `INST_CSRRWI: begin
        //             reg_wdata = csr_rdata_i;
        //         end
        //         `INST_CSRRSI: begin
        //             reg_wdata = csr_rdata_i;
        //         end
        //         `INST_CSRRCI: begin
        //             reg_wdata = csr_rdata_i;
        //         end
        //         default: begin
        //             reg_wdata = `ZeroWord;
        //         end
        //     endcase
        // end
        default: begin
            jump_flag = `JumpDisable;
            jump_addr = `ZeroWord;
            reg_wdata = `ZeroWord;
        end
    endcase
end

endmodule