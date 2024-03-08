module SyncFIFO #(
    parameter DEPTH = 1024,     // Depth of the FIFO
    parameter DATA_WIDTH = 128. // Width of the data
    parameter FIFO_PTR = 16     // Width of the pointer
)
(
    input wire clk,
    input wire reset_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0]rd_data,
    output wire empty,
    output wire full,
    output [FIFO_PTR-1:0] data_avail_cnt
);

    reg [DATA_WIDTH-1:0] fifo [DEPTH-1:0];
    reg [DEPTH-1:0] wr_ptr;
    reg [DEPTH-1:0] rd_ptr;
    reg [FIFO_PTR-:0] data_avail_cnt;
// fifo initial & read/write
genvar i;
always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        for(i=0;i<DEPTH;i=i+1)
            fifo[i]     <= 'b0;
    end
    else begin
        fifo[wr_ptr]    <= (wr_en && (full!=1'b1)) ? wr_data : fifo[wr_ptr];
        rd_data         <= (rd_en && (empty!=1'b1)) ? fifo[rd_ptr] : rd_data;
    end
end
// write pointer & read pointer
always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        wr_ptr <= 'b0;
    end
    else begin
        if(wr_ptr != DEPTH-1)
            wr_ptr <= (wr_en && (full!= 1'b1))? wr_ptr + 1 : wr_ptr;
        else 
            wr_ptr <= 'b0;
    end
end

always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        rd_ptr <= 'b0;
    end
    else begin
        if(rd_ptr != DEPTH-1)
            rd_ptr <= (rd_en && (empty!= 1'b1))? rd_ptr + 1 : rd_ptr;
        else 
            rd_ptr <= 'b0;
    end
end
// data_avail_cnt
always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        data_avail_cnt <= 'b0;
    end
    else begin
        if((wr_en && (full!= 1'b1)) && (rd_en && (empty!= 1'b1)))begin
            data_avail_cnt <= data_avail_cnt;
        end
        else begin 
            if(wr_en && (full!= 1'b1))
                data_avail_cnt <= data_avail_cnt + 1;
            else if(rd_en && (empty!= 1'b1))
                data_avail_cnt <= data_avail_cnt - 1;
        end
    end
end
// empty & full signal
assign empty    = (data_avail_cnt == 0) ;
assign full     = (data_avail_cnt == DEPTH);
endmodule