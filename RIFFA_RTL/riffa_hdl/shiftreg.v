// ----------------------------------------------------------------------
// Copyright (c) 2016, The Regents of the University of California All
// rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
// 
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
// 
//     * Neither the name of The Regents of the University of California
//       nor the names of its contributors may be used to endorse or
//       promote products derived from this software without specific
//       prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL REGENTS OF THE
// UNIVERSITY OF CALIFORNIA BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
// OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
// TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// ----------------------------------------------------------------------
/*
 Filename: shiftreg.v
 Version: 1.0
 Verilog Standard: Verilog-2001

 Description: A simple parameterized shift register. 
 
 Notes: Any modifications to this file should meet the conditions set
 forth in the "Trellis Style Guide"
 
 Author: Dustin Richmond (@darichmond) 
 Co-Authors:
 */
`timescale 1ns/1ns
module shiftreg
    #(parameter C_DEPTH=10,
      parameter C_WIDTH=32,
      parameter C_VALUE=0
      )
    (input                            CLK,
     input                            RST_IN,
     input [C_WIDTH-1:0]              WR_DATA,
     output [(C_DEPTH+1)*C_WIDTH-1:0] RD_DATA);

    // Start Flag Shift Register. Data enables are derived from the 
    // taps on this shift register.

    wire [(C_DEPTH+1)*C_WIDTH-1:0]    wDataShift;
    reg [C_WIDTH-1:0]                 rDataShift[C_DEPTH:0];
    //定义了一个存储矩阵，用于存储WR_DATA数据。

    assign wDataShift[(C_WIDTH*0)+:C_WIDTH] = WR_DATA;
    //定义了一个很长的wDataShift wire类型数据用于将数据串联起来
    always @(posedge CLK) begin
        rDataShift[0] <= WR_DATA;
    end
    //用于将输入数据存入rDataShift矩阵的第0层
    genvar                                     i;
    generate
        for (i = 1 ; i <= C_DEPTH; i = i + 1) begin : gen_sr_registers
            assign wDataShift[(C_WIDTH*i)+:C_WIDTH] = rDataShift[i-1];
            //for循环用于将rDataShift的中的数据赋值给之前定义的wDataShift
            always @(posedge CLK) begin
                if(RST_IN)
                    rDataShift[i] <= C_VALUE;
                else
                    rDataShift[i] <= rDataShift[i-1];
            //将rDataShift的数据向上移动，每个周期上移一层
            end
        end
    endgenerate
    assign RD_DATA = wDataShift;
//每个周期将rDataShift的数据向上移动一层，并且将数据赋值给wDataShift，用于表示移位寄存器中的状态
//这个模块实现了一位寄存器的功能，可以将输入数据每个周期向wire型的数据高位移动数据位宽的长度

endmodule
//在verilog中，for循环用于复制电路，对于上面的for循环，就是对i从0-C_DEPTH进行复制时序
//电路逻辑，每个逻辑单元都是并行的
//可以将数据根据输入的顺序，向高位移动，先进入的数据在高位，后进入的数据在低位。