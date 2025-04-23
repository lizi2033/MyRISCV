 /*                                                                      
 Copyright 2019 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */

`include "defines.v"

// tinyriscv处理器核顶层模块
module tinyriscv(

    input  wire                     clk                 ,
    input  wire                     rst                 ,

    output wire [`MemAddrBus]       rib_ex_addr_o       ,   // 读、写外设的地址
    input  wire [`MemBus]           rib_ex_data_i       ,   // 从外设读取的数据
    output wire [`MemBus]           rib_ex_data_o       ,   // 写入外设的数据
    output wire                     rib_ex_req_o        ,   // 访问外设请求
    output wire                     rib_ex_we_o         ,   // 写外设标志

    
    output wire [`MemAddrBus]       rib_pc_addr_o       ,   // 取指地址
    input  wire [`MemBus]           rib_pc_data_i       ,   // 取到的指令内容
`ifdef Harvard
    output wire                     rib_pc_req_o        ,
    output wire                     inst_we_o           ,
    output wire [`MemAddrBus]       inst_addr_o         ,
    output wire [`MemBus]           inst_data_o         ,
    input  wire [`MemBus]           inst_data_i         ,
`endif

    input  wire [`RegAddrBus]       jtag_reg_addr_i     ,   // jtag模块读、写寄存器的地址
    input  wire [`RegBus]           jtag_reg_data_i     ,   // jtag模块写寄存器数据
    input  wire                     jtag_reg_we_i       ,   // jtag模块写寄存器标志
    output wire [`RegBus]           jtag_reg_data_o     ,   // jtag模块读取到的寄存器数据

    input  wire                     rib_hold_flag_i     ,   // 总线暂停标志
    input  wire [`Hold_Flag_Bus]    axil_hold_flag_i    ,   // axil暂停标志
    input  wire [`Flush_Flag_Bus]   axil_flush_flag_i   ,
    input  wire                     jtag_halt_flag_i    ,    // jtag暂停标志
    input  wire                     jtag_reset_flag_i   ,   // jtag复位PC标志
    
    input  wire [`INT_BUS]          int_i                   // 中断信号

    );

    // pc_reg模块输出信号
	wire[`InstAddrBus] pc_pc_o;

    // if_id模块输出信号
	wire[`InstBus] if_inst_o;
    wire[`InstAddrBus] if_inst_addr_o;
    wire[`INT_BUS] if_int_flag_o;

    // id模块输出信号
    wire[`RegAddrBus] id_reg1_raddr_o;
    wire[`RegAddrBus] id_reg2_raddr_o;
    wire[`InstBus] id_inst_o;
    wire[`InstAddrBus] id_inst_addr_o;
    wire[`RegBus] id_reg1_rdata_o;
    wire[`RegBus] id_reg2_rdata_o;
    wire id_reg_we_o;
    wire[`RegAddrBus] id_reg_waddr_o;
    wire[`MemAddrBus] id_csr_raddr_o;
    wire id_csr_we_o;
    wire[`RegBus] id_csr_rdata_o;
    wire[`MemAddrBus] id_csr_waddr_o;
    wire[`MemAddrBus] id_op1_o;
    wire[`MemAddrBus] id_op2_o;
    wire[`MemAddrBus] id_op1_jump_o;
    wire[`MemAddrBus] id_op2_jump_o;

    // id_ex模块输出信号
    wire[`InstBus] ie_inst_o;
    wire[`InstAddrBus] ie_inst_addr_o;
    wire ie_reg_we_o;
    wire[`RegAddrBus] ie_reg_waddr_o;
    wire[`RegBus] ie_reg1_rdata_o;
    wire[`RegBus] ie_reg2_rdata_o;
    wire ie_csr_we_o;
    wire[`MemAddrBus] ie_csr_waddr_o;
    wire[`RegBus] ie_csr_rdata_o;
    wire[`MemAddrBus] ie_op1_o;
    wire[`MemAddrBus] ie_op2_o;
    wire[`MemAddrBus] ie_op1_jump_o;
    wire[`MemAddrBus] ie_op2_jump_o;

    // ex模块输出信号
    wire ex_reg_we_o;
    wire ex_div_start_o;
    wire[`RegBus] ex_div_dividend_o;
    wire[`RegBus] ex_div_divisor_o;
    wire[2:0] ex_div_op_o;
    wire[`RegAddrBus] ex_div_reg_waddr_o;
    wire ex_csr_we_o;
    wire[`MemAddrBus] ex_csr_waddr_o;

    // regs模块输出信号
    wire[`RegBus] regs_rdata1_o;
    wire[`RegBus] regs_rdata2_o;

    // csr_reg模块输出信号
    wire[`RegBus] csr_data_o;
    wire[`RegBus] csr_clint_data_o;
    wire csr_global_int_en_o;
    wire[`RegBus] csr_clint_csr_mtvec;
    wire[`RegBus] csr_clint_csr_mepc;
    wire[`RegBus] csr_clint_csr_mstatus;

    // ctrl模块输出信号
    wire[`Hold_Flag_Bus] ctrl_hold_flag_o;
    wire[`Flush_Flag_Bus] ctrl_flush_flag_o;
    wire ctrl_jump_flag_o;
    wire[`InstAddrBus] ctrl_jump_addr_o;

    // div模块输出信号
    wire[`RegBus] div_result_o;
	wire div_ready_o;
    wire div_busy_o;
    wire[`RegAddrBus] div_reg_waddr_o;

    // clint模块输出信号
    wire clint_we_o;
    wire[`MemAddrBus] clint_waddr_o;
    wire[`MemAddrBus] clint_raddr_o;
    wire[`RegBus] clint_data_o;
    wire[`InstAddrBus] clint_int_addr_o;
    wire clint_int_assert_o;
    wire clint_hold_flag_o;


    assign rib_ex_addr_o = (mem_mem_we_o == `WriteEnable)? mem_mem_waddr_o: mem_mem_raddr_o;
    assign rib_ex_data_o = mem_mem_wdata_o;
    assign rib_ex_req_o = mem_mem_req_o;
    assign rib_ex_we_o = mem_mem_we_o;

    
    assign rib_pc_addr_o = pc_pc_o;
`ifdef Harvard
    assign rib_pc_req_o = 0;
    assign inst_we_o   = 1'b0;
    assign inst_addr_o = pc_pc_o;
    assign inst_data_o = 32'h0;
`endif


    // pc_reg模块例化
    pc_reg u_pc_reg(
        .clk                            (clk                    ),
        .rst                            (rst                    ),
        .jtag_reset_flag_i              (jtag_reset_flag_i      ),
        .pc_o                           (pc_pc_o                ),
        .hold_flag_i                    (ctrl_hold_flag_o       ),
        .jump_flag_i                    (ctrl_jump_flag_o       ),
        .jump_addr_i                    (ctrl_jump_addr_o       )
    );

    // ctrl模块例化
    ctrl u_ctrl(
        .rst                            (rst                    ),
        .jump_flag_i                    (ex_jump_flag_o         ),
        .jump_addr_i                    (ex_jump_addr_o         ),
        .hold_flag_id_i                 (id_hold_flag_o         ),
        .hold_flag_mem_i                (mem_hold_flag_o        ),
        .hold_flag_rib_i                (rib_hold_flag_i        ),
        .hold_flag_axil_i               (axil_hold_flag_i       ),
        .hold_flag_o                    (ctrl_hold_flag_o       ),
        .flush_flag_o                   (ctrl_flush_flag_o      ),
        .hold_flag_clint_i              (clint_hold_flag_o      ),
        .jump_flag_o                    (ctrl_jump_flag_o       ),
        .jump_addr_o                    (ctrl_jump_addr_o       ),
        .jtag_halt_flag_i               (jtag_halt_flag_i       )
    );

    // regs模块例化
    regs u_regs(
        .clk                            (clk                    ),
        .rst                            (rst                    ),
        .we_i                           (wb_reg_we_o            ),
        .waddr_i                        (wb_reg_waddr_o         ),
        .wdata_i                        (wb_reg_wdata_o         ),
        .raddr1_i                       (id_reg1_raddr_o        ),
        .rdata1_o                       (regs_rdata1_o          ),
        .raddr2_i                       (id_reg2_raddr_o        ),
        .rdata2_o                       (regs_rdata2_o          ),
        .jtag_we_i                      (jtag_reg_we_i          ),
        .jtag_addr_i                    (jtag_reg_addr_i        ),
        .jtag_data_i                    (jtag_reg_data_i        ),
        .jtag_data_o                    (jtag_reg_data_o        )
    );

    // csr_reg模块例化
    csr_reg u_csr_reg(
        .clk                            (clk                    ),
        .rst                            (rst                    ),
        .we_i                           (wb_csr_we_o            ),
        .raddr_i                        (id_csr_raddr_o         ),
        .waddr_i                        (wb_csr_waddr_o         ),
        .data_i                         (wb_csr_wdata_o         ),
        .data_o                         (csr_data_o             ),
        .global_int_en_o                (csr_global_int_en_o    ),
        .clint_we_i                     (clint_we_o             ),
        .clint_raddr_i                  (clint_raddr_o          ),
        .clint_waddr_i                  (clint_waddr_o          ),
        .clint_data_i                   (clint_data_o           ),
        .clint_data_o                   (csr_clint_data_o       ),
        .clint_csr_mtvec                (csr_clint_csr_mtvec    ),
        .clint_csr_mepc                 (csr_clint_csr_mepc     ),
        .clint_csr_mstatus              (csr_clint_csr_mstatus  )
    );

    // if_id模块例化
    if_id u_if_id(
        .clk                            (clk                ),
        .rst                            (rst                ),
`ifdef Harvard
        .inst_i                         (inst_data_i        ),
`else
        .inst_i                         (rib_pc_data_i      ),
`endif
        .inst_addr_i                    (pc_pc_o            ),
        .int_flag_i                     (int_i              ),
        .int_flag_o                     (if_int_flag_o      ),
        .hold_flag_i                    (ctrl_hold_flag_o   ),
        .flush_flag_i                   (ctrl_flush_flag_o  ),
        .inst_o                         (if_inst_o          ),
        .inst_addr_o                    (if_inst_addr_o     )
    );

    // id模块例化
    id u_id(
        .rst                            (rst                ),
        .inst_i                         (if_inst_o          ),
        .inst_addr_i                    (if_inst_addr_o     ),
        .reg1_rdata_i                   (regs_rdata1_o      ),
        .reg2_rdata_i                   (regs_rdata2_o      ),
        .ex_jump_flag_i                 (wb_jump_flag_o     ),
        .is_load_i                      (is_load_o          ),
        .ex_reg_we_i                    (ex_reg_we_o        ),
        .ex_reg_waddr_i                 (ex_reg_waddr_o     ),
        .ex_reg_wdata_i                 (ex_reg_wdata_o     ),
        .mem_reg_we_i                   (mem_reg_we_o       ),
        .mem_reg_waddr_i                (mem_reg_waddr_o    ),
        .mem_reg_wdata_i                (mem_reg_wdata_o    ),
        .reg1_raddr_o                   (id_reg1_raddr_o    ),
        .reg2_raddr_o                   (id_reg2_raddr_o    ),
        .inst_o                         (id_inst_o          ),
        .inst_addr_o                    (id_inst_addr_o     ),
        .reg1_rdata_o                   (id_reg1_rdata_o    ),
        .reg2_rdata_o                   (id_reg2_rdata_o    ),
        .reg_we_o                       (id_reg_we_o        ),
        .reg_waddr_o                    (id_reg_waddr_o     ),
        .op1_o                          (id_op1_o           ),
        .op2_o                          (id_op2_o           ),
        .op1_jump_o                     (id_op1_jump_o      ),
        .op2_jump_o                     (id_op2_jump_o      ),
        .csr_rdata_i                    (csr_data_o         ),
        .csr_raddr_o                    (id_csr_raddr_o     ),
        .csr_we_o                       (id_csr_we_o        ),
        .csr_rdata_o                    (id_csr_rdata_o     ),
        .csr_waddr_o                    (id_csr_waddr_o     ),
        .hold_flag_o                    (id_hold_flag_o     )
    );

    wire[`RegAddrBus]   ie_reg1_raddr_o;
    wire[`RegAddrBus]   ie_reg2_raddr_o;
    // id_ex模块例化
    id_ex u_id_ex(
        .clk                            (clk                ),
        .rst                            (rst                ),
        .inst_i                         (id_inst_o          ),
        .inst_addr_i                    (id_inst_addr_o     ),
        .reg1_raddr_i                   (id_reg1_raddr_o    ),
        .reg2_raddr_i                   (id_reg2_raddr_o    ),  
        .reg_we_i                       (id_reg_we_o        ),
        .reg_waddr_i                    (id_reg_waddr_o     ),
        .reg1_rdata_i                   (id_reg1_rdata_o    ),
        .reg2_rdata_i                   (id_reg2_rdata_o    ),
        .hold_flag_i                    (ctrl_hold_flag_o   ),
        .flush_flag_i                   (ctrl_flush_flag_o  ),
        .inst_o                         (ie_inst_o          ),
        .inst_addr_o                    (ie_inst_addr_o     ),
        .reg1_raddr_o                   (ie_reg1_raddr_o    ),
        .reg2_raddr_o                   (ie_reg2_raddr_o    ),
        .reg_we_o                       (ie_reg_we_o        ),
        .reg_waddr_o                    (ie_reg_waddr_o     ),
        .reg1_rdata_o                   (ie_reg1_rdata_o    ),
        .reg2_rdata_o                   (ie_reg2_rdata_o    ),
        .op1_i                          (id_op1_o           ),
        .op2_i                          (id_op2_o           ),
        .op1_jump_i                     (id_op1_jump_o      ),
        .op2_jump_i                     (id_op2_jump_o      ),
        .op1_o                          (ie_op1_o           ),
        .op2_o                          (ie_op2_o           ),
        .op1_jump_o                     (ie_op1_jump_o      ),
        .op2_jump_o                     (ie_op2_jump_o      ),
        .csr_we_i                       (id_csr_we_o        ),
        .csr_waddr_i                    (id_csr_waddr_o     ),
        .csr_rdata_i                    (id_csr_rdata_o     ),
        .csr_we_o                       (ie_csr_we_o        ),
        .csr_waddr_o                    (ie_csr_waddr_o     ),
        .csr_rdata_o                    (ie_csr_rdata_o     )
    );

    wire [`InstBus]         ex_inst_o;
    wire [`InstAddrBus]     ex_inst_addr_o;
    wire [`RegAddrBus]      ex_reg1_raddr_o;
    wire [`RegAddrBus]      ex_reg2_raddr_o;
    wire [`RegBus]          ex_reg1_rdata_o;
    wire [`RegBus]          ex_reg2_rdata_o;
    wire [`RegBus]          ex_csr_rdata_o;
    wire [1:0]              ex_mem_raddr_index_o;
    wire [1:0]              ex_mem_waddr_index_o;
    wire [`MemAddrBus]      ex_op1_add_op2_res_o;
    wire [`MemAddrBus]      ex_op1_jump_add_op2_jump_res_o;
    wire                    ex_op1_ge_op2_signed_o;
    wire                    ex_op1_ge_op2_unsigned_o;
    wire                    ex_op1_eq_op2_o;
    wire                    ex_div_we_o;
    wire [`RegBus]          ex_div_wdata_o;
    wire [`RegAddrBus]      ex_div_waddr_o;      
    wire                    ex_div_hold_flag_o;
    wire                    ex_div_jump_flag_o;
    wire [`InstAddrBus]     ex_div_jump_addr_o;
    wire                    ex_jump_flag_o;
    wire [`InstAddrBus]     ex_jump_addr_o;
    wire [`RegAddrBus]      ex_reg_waddr_o;
    wire [`RegBus]          ex_reg_wdata_o;
    wire                    is_load_o;
    //ex模块例化
    ex u_ex(
        .inst_i                         (ie_inst_o                      ),         
        .inst_addr_i                    (ie_inst_addr_o                 ),  
        .reg1_raddr_i                   (ie_reg1_raddr_o                ),
        .reg2_raddr_i                   (ie_reg2_raddr_o                ),  
        .reg1_rdata_i                   (ie_reg1_rdata_o                ),   
        .reg2_rdata_i                   (ie_reg2_rdata_o                ),
        .reg_we_i                       (ie_reg_we_o                    ),       
        .reg_waddr_i                    (ie_reg_waddr_o                 ),
        .int_assert_i                   (clint_int_assert_o             ), 
        .int_addr_i                     (clint_int_addr_o               ),      
        .csr_we_i                       (ie_csr_we_o                    ),       
        .csr_waddr_i                    (ie_csr_waddr_o                 ),    
        .csr_rdata_i                    (ie_csr_rdata_o                 ),    
        .op1_i                          (ie_op1_o                       ),
        .op2_i                          (ie_op2_o                       ),
        .op1_jump_i                     (ie_op1_jump_o                  ),
        .op2_jump_i                     (ie_op2_jump_o                  ),
        .div_ready_i                    (div_ready_o                    ),
        .div_result_i                   (div_result_o                   ),
        .div_busy_i                     (div_busy_o                     ),
        .div_reg_waddr_i                (div_reg_waddr_o                ),
        .div_start_o                    (ex_div_start_o                 ),     
        .div_dividend_o                 (ex_div_dividend_o              ),  
        .div_divisor_o                  (ex_div_divisor_o               ),   
        .div_op_o                       (ex_div_op_o                    ),        
        .div_reg_waddr_o                (ex_div_reg_waddr_o             ),
        .div_hold_flag_o                (ex_div_hold_flag_o             ),//------------------------------------
        .div_jump_flag_o                (ex_div_jump_flag_o             ),
        .div_jump_addr_o                (ex_div_jump_addr_o             ),
        .inst_o                         (ex_inst_o                      ), 
        .inst_addr_o                    (ex_inst_addr_o                 ),
        .reg1_raddr_o                   (ex_reg1_raddr_o                ),
        .reg2_raddr_o                   (ex_reg2_raddr_o                ),  
        .reg1_rdata_o                   (ex_reg1_rdata_o                ), 
        .reg2_rdata_o                   (ex_reg2_rdata_o                ),     
        .reg_we_o                       (ex_reg_we_o                    ),     
        .reg_waddr_o                    (ex_reg_waddr_o                 ),
        .reg_wdata_o                    (ex_reg_wdata_o                 ),
        .csr_we_o                       (ex_csr_we_o                    ),     
        .csr_waddr_o                    (ex_csr_waddr_o                 ),  
        .csr_rdata_o                    (ex_csr_rdata_o                 ),  
        .div_we_o                       (ex_div_we_o                    ),          
        .div_wdata_o                    (ex_div_wdata_o                 ),       
        .div_waddr_o                    (ex_div_waddr_o                 ),
        .mem_raddr_index_o              (ex_mem_raddr_index_o           ),
        .mem_waddr_index_o              (ex_mem_waddr_index_o           ),
        .op1_add_op2_res_o              (ex_op1_add_op2_res_o           ),
        .op1_jump_add_op2_jump_res_o    (ex_op1_jump_add_op2_jump_res_o ),
        .op1_ge_op2_signed_o            (ex_op1_ge_op2_signed_o         ),
        .op1_ge_op2_unsigned_o          (ex_op1_ge_op2_unsigned_o       ),
        .op1_eq_op2_o                   (ex_op1_eq_op2_o                ),
        .is_load_o                      (is_load_o                      ),
        .jump_flag_o                    (ex_jump_flag_o                 ),
        .jump_addr_o                    (ex_jump_addr_o                 )
    );

    wire [`InstBus]         em_inst_o;
    wire [`InstAddrBus]     em_inst_addr_o;
    wire [`RegAddrBus]      em_reg1_raddr_o;
    wire [`RegAddrBus]      em_reg2_raddr_o;
    wire                    em_reg_we_o;
    wire [`RegAddrBus]      em_reg_waddr_o;
    wire [`RegBus]          em_reg_wdata_o;
    wire [`RegBus]          em_reg1_rdata_o;
    wire [`RegBus]          em_reg2_rdata_o;
    wire [`RegBus]          em_csr_rdata_o;
    wire                    em_csr_we_o;
    wire [`MemAddrBus]      em_csr_waddr_o;
    wire                    em_div_we_o;
    wire [`RegBus]          em_div_wdata_o;
    wire [`RegAddrBus]      em_div_waddr_o;
    wire [1:0]              em_mem_raddr_index_o;          
    wire [1:0]              em_mem_waddr_index_o;                   
    wire [31:0]             em_op1_add_op2_res_o;          
    wire [31:0]             em_op1_jump_add_op2_jump_res_o;
    wire                    em_op1_ge_op2_signed_o;        
    wire                    em_op1_ge_op2_unsigned_o;      
    wire                    em_op1_eq_op2_o;               
    ex_mem u_ex_mem(
        .clk                            (clk                            ),
        .rst                            (rst                            ),
        .hold_flag_i                    (ctrl_hold_flag_o               ),
        .flush_flag_i                   (ctrl_flush_flag_o              ),
        .inst_i                         (ex_inst_o                      ),  
        .reg1_raddr_i                   (ex_reg1_raddr_o                ),
        .reg2_raddr_i                   (ex_reg2_raddr_o                ),   
        .reg1_rdata_i                   (ex_reg1_rdata_o                ),
        .reg2_rdata_i                   (ex_reg2_rdata_o                ),
        .reg_we_i                       (ex_reg_we_o                    ),    
        .reg_waddr_i                    (ex_reg_waddr_o                 ),
        .reg_wdata_i                    (ex_reg_wdata_o                 ),  
        .csr_rdata_i                    (ex_csr_rdata_o                 ),
        .csr_we_i                       (ex_csr_we_o                    ),
        .csr_waddr_i                    (ex_csr_waddr_o                 ),
        .div_we_i                       (ex_div_we_o                    ),          
        .div_wdata_i                    (ex_div_wdata_o                 ),       
        .div_waddr_i                    (ex_div_waddr_o                 ),  
        .mem_raddr_index_i              (ex_mem_raddr_index_o           ),
        .mem_waddr_index_i              (ex_mem_waddr_index_o           ),
        .op1_add_op2_res_i              (ex_op1_add_op2_res_o           ),
        .op1_jump_add_op2_jump_res_i    (ex_op1_jump_add_op2_jump_res_o ),
        .op1_ge_op2_signed_i            (ex_op1_ge_op2_signed_o         ),
        .op1_ge_op2_unsigned_i          (ex_op1_ge_op2_unsigned_o       ),
        .op1_eq_op2_i                   (ex_op1_eq_op2_o                ),  
        .inst_o                         (em_inst_o                      ), 
        .inst_addr_o                    (em_inst_addr_o                 ),
        .reg1_raddr_o                   (em_reg1_raddr_o                ),
        .reg2_raddr_o                   (em_reg2_raddr_o                ),
        .reg1_rdata_o                   (em_reg1_rdata_o                ),
        .reg2_rdata_o                   (em_reg2_rdata_o                ),
        .reg_we_o                       (em_reg_we_o                    ),       
        .reg_waddr_o                    (em_reg_waddr_o                 ),
        .reg_wdata_o                    (em_reg_wdata_o                 ),  
        .csr_rdata_o                    (em_csr_rdata_o                 ),    
        .csr_we_o                       (em_csr_we_o                    ),       
        .csr_waddr_o                    (em_csr_waddr_o                 ),    
        .div_we_o                       (em_div_we_o                    ),          
        .div_wdata_o                    (em_div_wdata_o                 ),       
        .div_waddr_o                    (em_div_waddr_o                 ),
        .mem_raddr_index_o              (em_mem_raddr_index_o           ),
        .mem_waddr_index_o              (em_mem_waddr_index_o           ),
        .op1_add_op2_res_o              (em_op1_add_op2_res_o           ),
        .op1_jump_add_op2_jump_res_o    (em_op1_jump_add_op2_jump_res_o ),
        .op1_ge_op2_signed_o            (em_op1_ge_op2_signed_o         ),
        .op1_ge_op2_unsigned_o          (em_op1_ge_op2_unsigned_o       ),
        .op1_eq_op2_o                   (em_op1_eq_op2_o                )
    );

wire [`InstBus]     mem_inst_o                      ;
wire [`InstAddrBus] mem_inst_addr_o                 ;
wire[`RegAddrBus]   mem_reg1_raddr_o                ;
wire[`RegAddrBus]   mem_reg2_raddr_o                ;
wire                mem_reg_we_o                    ;
wire[`RegAddrBus]   mem_reg_waddr_o                 ;
wire [`RegBus]      mem_reg1_rdata_o                ;
wire [`RegBus]      mem_reg2_rdata_o                ;
wire                mem_csr_we_o                    ;
wire[`MemAddrBus]   mem_csr_waddr_o                 ;  
wire[`RegBus]       mem_csr_rdata_o                 ;
wire                mem_div_we_o                    ;
wire[`RegBus]       mem_div_wdata_o                 ;
wire[`RegAddrBus]   mem_div_waddr_o                 ;
wire[31:0]          mem_op1_add_op2_res_o           ;
wire[31:0]          mem_op1_jump_add_op2_jump_res_o ;
wire                mem_op1_ge_op2_signed_o         ;
wire                mem_op1_ge_op2_unsigned_o       ;
wire                mem_op1_eq_op2_o                ;
wire[`MemBus]       mem_mem_wdata_o                 ;
wire[`MemAddrBus]   mem_mem_raddr_o                 ;
wire[`MemAddrBus]   mem_mem_waddr_o                 ;
wire                mem_mem_we_o                    ;
wire                mem_mem_req_o                   ;
wire[`RegBus]       mem_reg_wdata_o                 ;
wire                mem_hold_flag_o                 ;    
    // mem模块例化
    mem u_mem(
        .inst_i                         (em_inst_o                      ),   
        .inst_addr_i                    (em_inst_addr_o                 ),
        .reg1_raddr_i                   (em_reg1_raddr_o                ),
        .reg2_raddr_i                   (em_reg2_raddr_o                ),          
        .reg_we_i                       (em_reg_we_o                    ),                    
        .reg_waddr_i                    (em_reg_waddr_o                 ),  
        .reg_wdata_i                    (em_reg_wdata_o                 ),  
        .reg1_rdata_i                   (em_reg1_rdata_o                ),       
        .reg2_rdata_i                   (em_reg2_rdata_o                ),       
        .csr_we_i                       (em_csr_we_o                    ),                    
        .csr_waddr_i                    (em_csr_waddr_o                 ),    
        .csr_rdata_i                    (em_csr_rdata_o                 ),  
        .div_we_i                       (em_div_we_o                    ),          
        .div_wdata_i                    (em_div_wdata_o                 ),       
        .div_waddr_i                    (em_div_waddr_o                 ),   
        .int_assert_i                   (clint_int_assert_o             ),                
        .int_addr_i                     (clint_int_addr_o               ),    
        .mem_raddr_index_i              (em_mem_raddr_index_o           ),
        .mem_waddr_index_i              (em_mem_waddr_index_o           ),
        .op1_add_op2_res_i              (em_op1_add_op2_res_o           ),
        .op1_jump_add_op2_jump_res_i    (em_op1_jump_add_op2_jump_res_o ),
        .op1_ge_op2_signed_i            (em_op1_ge_op2_signed_o         ),
        .op1_ge_op2_unsigned_i          (em_op1_ge_op2_unsigned_o       ),
        .op1_eq_op2_i                   (em_op1_eq_op2_o                ),
        .mem_rdata_i                    (rib_ex_data_i                  ), 
        .mem_wdata_o                    (mem_mem_wdata_o                ),       
        .mem_raddr_o                    (mem_mem_raddr_o                ),   
        .mem_waddr_o                    (mem_mem_waddr_o                ),   
        .mem_we_o                       (mem_mem_we_o                   ),                  
        .mem_req_o                      (mem_mem_req_o                  ),  
        .hold_flag_o                    (mem_hold_flag_o                ),
        .inst_o                         (mem_inst_o                     ),  
        .inst_addr_o                    (mem_inst_addr_o                ),   
        .reg1_raddr_o                   (mem_reg1_raddr_o               ),
        .reg2_raddr_o                   (mem_reg2_raddr_o               ),  
        .reg_we_o                       (mem_reg_we_o                   ),       
        .reg_waddr_o                    (mem_reg_waddr_o                ),
        .reg_wdata_o                    (mem_reg_wdata_o                ),
        .reg1_rdata_o                   (mem_reg1_rdata_o               ),
        .reg2_rdata_o                   (mem_reg2_rdata_o               ),
        .csr_we_o                       (mem_csr_we_o                   ),     
        .csr_waddr_o                    (mem_csr_waddr_o                ),  
        .csr_rdata_o                    (mem_csr_rdata_o                ),  
        .div_we_o                       (mem_div_we_o                   ),          
        .div_wdata_o                    (mem_div_wdata_o                ),       
        .div_waddr_o                    (mem_div_waddr_o                ), 
        .op1_add_op2_res_o              (mem_op1_add_op2_res_o          ),
        .op1_jump_add_op2_jump_res_o    (mem_op1_jump_add_op2_jump_res_o),
        .op1_ge_op2_signed_o            (mem_op1_ge_op2_signed_o        ),
        .op1_ge_op2_unsigned_o          (mem_op1_ge_op2_unsigned_o      ),
        .op1_eq_op2_o                   (mem_op1_eq_op2_o               )
    );

wire [`InstBus]     mw_inst_o;
wire [`InstAddrBus] mw_inst_addr_o;
wire                mw_reg_we_o;
wire[`RegAddrBus]   mw_reg_waddr_o;
wire [`RegBus]      mw_reg_wdata_o;
wire [`RegBus]      mw_reg1_rdata_o;
wire [`RegBus]      mw_reg2_rdata_o;
wire                mw_csr_we_o;
wire[`MemAddrBus]   mw_csr_waddr_o;
wire[`RegBus]       mw_csr_rdata_o;
wire                mw_div_we_o;
wire[`RegBus]       mw_div_wdata_o;
wire[`RegAddrBus]   mw_div_waddr_o;
wire[31:0]          mw_op1_add_op2_res_o;
wire[31:0]          mw_op1_jump_add_op2_jump_res_o;
wire                mw_op1_ge_op2_signed_o;
wire                mw_op1_ge_op2_unsigned_o;
wire                mw_op1_eq_op2_o;
wire[`MemBus]       mw_mem_wdata_o ;
wire[`MemBus]       mw_mem_rdata_o  ;
wire[`MemAddrBus]   mw_mem_raddr_o ;
wire[`MemAddrBus]   mw_mem_waddr_o ;
wire                mw_mem_we_o    ;
wire                mw_mem_req_o   ;
    mem_wb u_mem_wb(
        .clk                                (clk                            ),
        .rst                                (rst                            ),
        .hold_flag_i                        (ctrl_hold_flag_o               ),
        .flush_flag_i                       (ctrl_flush_flag_o              ),
        .inst_i                             (mem_inst_o                     ),
        .inst_addr_i                        (mem_inst_addr_o                ),
        .reg_we_i                           (mem_reg_we_o                   ),
        .reg_waddr_i                        (mem_reg_waddr_o                ),
        .reg_wdata_i                        (mem_reg_wdata_o                ),  
        .reg1_rdata_i                       (mem_reg1_rdata_o               ),
        .reg2_rdata_i                       (mem_reg2_rdata_o               ),
        .csr_we_i                           (mem_csr_we_o                   ),
        .csr_waddr_i                        (mem_csr_waddr_o                ),
        .csr_rdata_i                        (mem_csr_rdata_o                ),
        .div_we_i                           (mem_div_we_o                   ),          
        .div_wdata_i                        (mem_div_wdata_o                ),       
        .div_waddr_i                        (mem_div_waddr_o                ), 
        .op1_add_op2_res_i                  (mem_op1_add_op2_res_o          ),
        .op1_jump_add_op2_jump_res_i        (mem_op1_jump_add_op2_jump_res_o),
        .op1_ge_op2_signed_i                (mem_op1_ge_op2_signed_o        ),
        .op1_ge_op2_unsigned_i              (mem_op1_ge_op2_unsigned_o      ),
        .op1_eq_op2_i                       (mem_op1_eq_op2_o               ),
        .mem_rdata_i                        (rib_ex_data_i                  ),
        .mem_wdata_i                        (mem_mem_wdata_o                ),       
        .mem_raddr_i                        (mem_mem_raddr_o                ),   
        .mem_waddr_i                        (mem_mem_waddr_o                ),   
        .mem_we_i                           (mem_mem_we_o                   ),                  
        .mem_rdata_o                        (mw_mem_rdata_o                 ),
        .mem_wdata_o                        (mw_mem_wdata_o                 ),       
        .mem_raddr_o                        (mw_mem_raddr_o                 ),   
        .mem_waddr_o                        (mw_mem_waddr_o                 ),   
        .mem_we_o                           (mw_mem_we_o                    ),                  
        .inst_o                             (mw_inst_o                      ), 
        .inst_addr_o                        (mw_inst_addr_o                 ),
        .reg_we_o                           (mw_reg_we_o                    ),                    
        .reg_waddr_o                        (mw_reg_waddr_o                 ), 
        .reg_wdata_o                        (mw_reg_wdata_o                 ),       
        .reg1_rdata_o                       (mw_reg1_rdata_o                ),       
        .reg2_rdata_o                       (mw_reg2_rdata_o                ),       
        .csr_we_o                           (mw_csr_we_o                    ),                    
        .csr_waddr_o                        (mw_csr_waddr_o                 ),    
        .csr_rdata_o                        (mw_csr_rdata_o                 ), 
        .div_we_o                           (mw_div_we_o                    ),          
        .div_wdata_o                        (mw_div_wdata_o                 ),       
        .div_waddr_o                        (mw_div_waddr_o                 ),
        .op1_add_op2_res_o                  (mw_op1_add_op2_res_o           ),
        .op1_jump_add_op2_jump_res_o        (mw_op1_jump_add_op2_jump_res_o ),
        .op1_ge_op2_signed_o                (mw_op1_ge_op2_signed_o         ),
        .op1_ge_op2_unsigned_o              (mw_op1_ge_op2_unsigned_o       ),
        .op1_eq_op2_o                       (mw_op1_eq_op2_o                )
    );

    wire[`RegBus]       wb_reg_wdata_o;
    wire                wb_reg_we_o;
    wire[`RegAddrBus]   wb_reg_waddr_o;
    wire [`RegBus]      wb_csr_wdata_o;
    wire                wb_csr_we_o;
    wire[`RegAddrBus]   wb_csr_waddr_o;
    wire                wb_hold_flag_o;
    wire                wb_jump_flag_o;
    wire[`InstAddrBus]  wb_jump_addr_o;
    wb u_wb(
        .inst_i                             (mw_inst_o                      ),
        .inst_addr_i                        (mw_inst_addr_o                 ),   
        .mem_rdata_i                        (rib_ex_data_i                  ),    
        .reg_we_i                           (mw_reg_we_o                    ),                    
        .reg_waddr_i                        (mw_reg_waddr_o                 ), 
        .reg_wdata_i                        (mw_reg_wdata_o                 ),       
        .reg1_rdata_i                       (mw_reg1_rdata_o                ),       
        .reg2_rdata_i                       (mw_reg2_rdata_o                ),       
        .csr_we_i                           (mw_csr_we_o                    ),                    
        .csr_waddr_i                        (mw_csr_waddr_o                 ),    
        .csr_rdata_i                        (mw_csr_rdata_o                 ), 
        .div_we_i                           (mw_div_we_o                    ),          
        .div_wdata_i                        (mw_div_wdata_o                 ),       
        .div_waddr_i                        (mw_div_waddr_o                 ),       
        .int_assert_i                       (clint_int_assert_o             ),                
        .int_addr_i                         (clint_int_addr_o               ),    
        .op1_add_op2_res_i                  (mw_op1_add_op2_res_o           ),
        .op1_jump_add_op2_jump_res_i        (mw_op1_jump_add_op2_jump_res_o ),
        .op1_ge_op2_signed_i                (mw_op1_ge_op2_signed_o         ),
        .op1_ge_op2_unsigned_i              (mw_op1_ge_op2_unsigned_o       ),
        .op1_eq_op2_i                       (mw_op1_eq_op2_o                ),
        .reg_wdata_o                        (wb_reg_wdata_o                 ),       
        .reg_we_o                           (wb_reg_we_o                    ),                   
        .reg_waddr_o                        (wb_reg_waddr_o                 ),   
        .csr_wdata_o                        (wb_csr_wdata_o                 ),        
        .csr_we_o                           (wb_csr_we_o                    ),                   
        .csr_waddr_o                        (wb_csr_waddr_o                 ),   
        .hold_flag_o                        (wb_hold_flag_o                 ),                
        .jump_flag_o                        (wb_jump_flag_o                 ),                
        .jump_addr_o                        (wb_jump_addr_o                 )
    );

    // div模块例化
    div u_div(
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .dividend_i             (ex_div_dividend_o      ),
        .divisor_i              (ex_div_divisor_o       ),
        .start_i                (ex_div_start_o         ),
        .op_i                   (ex_div_op_o            ),
        .reg_waddr_i            (ex_div_reg_waddr_o     ),
        .result_o               (div_result_o           ),
        .ready_o                (div_ready_o            ),
        .busy_o                 (div_busy_o             ),
        .reg_waddr_o            (div_reg_waddr_o        )
    );

    // clint模块例化
    clint u_clint(
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .int_flag_i             (if_int_flag_o          ),
        .inst_i                 (id_inst_o              ),
        .inst_addr_i            (id_inst_addr_o         ),
        .jump_flag_i            (ex_jump_flag_o         ),
        .jump_addr_i            (ex_jump_addr_o         ),
        .hold_flag_i            (ctrl_hold_flag_o       ),
        .div_started_i          (ex_div_start_o         ),
        .data_i                 (csr_clint_data_o       ),
        .csr_mtvec              (csr_clint_csr_mtvec    ),
        .csr_mepc               (csr_clint_csr_mepc     ),
        .csr_mstatus            (csr_clint_csr_mstatus  ),
        .we_o                   (clint_we_o             ),
        .waddr_o                (clint_waddr_o          ),
        .raddr_o                (clint_raddr_o          ),
        .data_o                 (clint_data_o           ),
        .hold_flag_o            (clint_hold_flag_o      ),
        .global_int_en_i        (csr_global_int_en_o    ),
        .int_addr_o             (clint_int_addr_o       ),
        .int_assert_o           (clint_int_assert_o     )
    );

endmodule
