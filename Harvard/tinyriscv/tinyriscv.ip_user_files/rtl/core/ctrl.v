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

// 控制模块
// 发出跳转、暂停流水线信号
module ctrl(

    input wire                      rst,

    // from id
    input wire                      hold_flag_id_i,

    // from ex  
    input wire                      jump_flag_i,
    input wire[`InstAddrBus]        jump_addr_i,
    input wire                      hold_flag_ex_i,

    // from mem 
    input wire                      hold_flag_mem_i,

    // from rib 
    input wire                      hold_flag_rib_i,
    input wire [`Hold_Flag_Bus]     hold_flag_axil_i,

    // from jtag    
    input wire                      jtag_halt_flag_i,

    // from clint   
    input wire                      hold_flag_clint_i,

    output reg [`Hold_Flag_Bus]     hold_flag_o,
    output reg [`Flush_Flag_Bus]    flush_flag_o,

    // to pc_reg
    output reg                      jump_flag_o,
    output reg [`InstAddrBus]       jump_addr_o

    );


    always @ (*) begin
        // 默认不暂停
        hold_flag_o = `Hold_None;
        // 按优先级处理不同模块的请求
        if (hold_flag_axil_i != `Hold_None) begin
            hold_flag_o = hold_flag_axil_i;
        end else if (hold_flag_id_i == `HoldEnable || hold_flag_clint_i == `HoldEnable) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Id;
        end else if (hold_flag_rib_i == `HoldEnable) begin
            // 暂停PC，即取指地址不变
            // hold_flag_o = `Hold_Pc;
            hold_flag_o = `Hold_Ex;
        end else if (jtag_halt_flag_i == `HoldEnable) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Id;
        end else begin
            hold_flag_o = `Hold_None;
        end
    end

    always @(*) begin
        jump_addr_o = jump_addr_i;
        jump_flag_o = jump_flag_i;
        if (jump_flag_i == `JumpEnable) begin
            flush_flag_o = `Flush_Ex;
        end else begin
            flush_flag_o = `Flush_None;
        end
    end

endmodule
