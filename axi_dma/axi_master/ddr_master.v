`timescale 1 ns / 1 ps

module ddr_master #(
    parameter ID_WIDTH                  = 4,
    parameter ADDR_WIDTH                = 32,
    parameter DATA_WIDTH                = 32,
    parameter AWUSER_WIDTH              = 1,
    parameter ARUSER_WIDTH              = 1, 
    parameter WUSER_WIDTH               = 1, 
    parameter RUSER_WIDTH               = 1,  
    parameter BUSER_WIDTH               = 1,
    parameter AW_LEN                    = 16,
    parameter AR_LEN                    = 16,
    parameter AW_BURST                  = 2'b01,
    parameter AR_BURST                  = 2'b01

)
(   //clk & reset
    input areset_n,
    input aclk,
    input aw_base_address,
    input ar_base_address,

    //BRAM signal
    output bram_ar_address,
    output bram_aw_address,
    //FPGA IP signal is written by zhang
    input init_read;
    input init_write;
    //aw channel signals
    output [ID_WIDTH-1:0]       aw_id,
    output [ADDR_WIDTH-1:0]     aw_addr,
    output [7:0]                aw_len,
    output [2:0]                aw_size,
    output [1:0]                aw_burst,//be assignde to a specific value
    output                      aw_lock,
    output [3:0]                aw_cache,
    output [2:0]                aw_prot,
    output [3:0]                aw_qos,
    output [AWUSER_WIDTH-1:0]   aw_user,
    output                      aw_valid,
    input                       aw_ready,

    //w channel signals
    output [DATA_WIDTH-1:0]     w_data,
    output [DATA_WIDTH/8-1:0]   w_strb,
    output                      w_last,
    output [WUSER_WIDTH-1:0]    w_user,
    output                      w_valid,
    input                       w_ready,
    
    //b channel signals
    input  [ID_WIDTH-1:0]       b_id,
    input  [1:0]                b_resp,
    input  [BUSER_WIDTH-1:0]    b_user,
    input                       b_valid,
    output                      b_ready,

    //ar channel signals
    output [ID_WIDTH-1:0]       ar_id,
    output [ADDR_WIDTH-1:0]     ar_addr,
    output [7:0]                ar_len,
    output [2:0]                ar_size;
    output [1:0]                ar_burst,
    output                      ar_lock,
    output [3:0]                ar_cache,
    output [2:0]                ar_prot;
    output [3:0]                ar_qos;
    output [ARUSER_WIDTH-1:0]   ar_user,
    output                      ar_valid,
    input                       ar_ready,

    //r cahnnel signals
    input [ID_WIDTH-1]          r_id,
    input [DATA_WIDTH-1]        r_data,
    input [1:0]                 r_resp,
    input                       r_last,
    input  [RUSER_WIDTH-1:0]    r_user,
    input                       r_valid,
    output                      r_ready          
);


//this function get a log base 2
function integer clogb2 (input integer bit_depth);              
	  begin                                                           
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
	      bit_depth = bit_depth >> 1;                                 
	    end                                                           
	  endfunction

//----------------------------
//assign value to some signal
//----------------------------

//aw channel signal value
assign aw_id        = 'b0; 
assign aw_len       = AW_LEN-1;
assign aw_size      = clogb2((DATA_WIDTH/8)-1);
assign aw_burst     = AW_BURST;
assign aw_lock      = 1'b0;
assign aw_cache     = 4'b0010;
assign aw_prot      = 3'h0;
assign aw_qos       = 4'h0;
assign aw_user      = 'b1;

//w channel signal value
assign w_strb       = {(DATA_WIDTH/8){1'b1}};
assign w_user       = 'b0;

//ar channel signal value 
assign ar_id        = 'b0;
assign ar_len       = AR_LEN-1;
assign ar_size      = clogb2((DATA_WIDTH/8)-1);
assign ar_burst     = AR_BURST;
assign ar_lock      = 1'b0;
assign ar_cache     = 4'b0010;
assign ar_prot      = 3'h0;
assign ar_qos       = 4'h0;
assign ar_user      = 'b1;

 
//------------------------
//w_last r_last signal
//------------------------

//w channel w_last  and write_done siganl signal
localparam integer COUNTER_WIDTH    =   clogb2(AW_LEN-1);
reg [COUNTER_WIDTH:0]    write_counter;
reg [COUNTER_WIDTH:0]    read_counter;
reg         aw_addr_offset;
reg         write_done;
reg         read_done;
reg         w_last;
reg         burst_write_active;
reg         burst_read_active;
reg         aw_valid;
reg         ar_valid;
reg         b_ready;
reg         w_valid;
reg         r_ready;
wire        burst_size_byte;
assign      burst_size_byte = DATA_WIDTH/8;
assign      aw_addr = aw_base_address;
assign      ar_addr = ar_base_address;

always @ (posedge aclk , negedge arset_n)begin
    if(!areset_n)
        write_counter <= 'b0;
    else if(w_valid && w_ready)
    begin
        if(write_counter!= (AW_LEN-1))
            write_counter <= write_counter+1;
    end
    else
         write_counter    <= write_counter;
end

always @ (posedge aclk , negedge arset_n)begin
    if(!areset_n)
        w_last  <= 1'b0;
    else if((write_counter == (AW_LEN-2) && (AW_LEN>=2) && w_valid && w_ready)|| (AW_LEN == 1))
        w_last  <= 1'b1;
    else if(w_valid && w_ready)
        w_last  <= 1'b0;
    else if( w_last && (AW_LEN ==1))
        w_last  <= 1'b0;
    else
        w_last  <= w_last;
end

always @(posedge aclk,negedge areset_n)begin
    if(!areset_n)
        write_done  <= 1'b0;
    else if(b_valid && b_ready && (write_counter == AW_LEN-2))
        write_done  <= 1'b1;
    else
        write_done  <= write_done;
end

//use to  get the BRAM address r channel r_last signal 
always @ (posedge aclk , negedge arset_n)begin
    if(!areset_n)
        read_counter <= 'b0;
    else if(r_valid && r_ready)
    begin
        if(read_counter!= (AR_LEN-1))
            read_counter <= read_counter+1;
    end
    else
         read_counter    <= read_counter;
end

always @(posedge aclk,negedge areset_n)begin
    if(!areset_n)
        read_done  <= 1'b0;
    else if(r_valid && r_ready && (read_counter == AR_LEN-1))
        read_done  <= 1'b1;
    else
        read_done  <= read_done;
end


//--------------------------
//ADDRESS caculate //TODO connect to mig may be not right
//--------------------------

// //AW
// always @ (posedge aclk , negedge arset_n)begin
//     if(!areset_n)
//         aw_addr_offset <= 'b0;
//     else if(w_ready && w_valid)
//         aw_addr_offset <= aw_addr_offset + burst_size_byte;
//     else 
//         aw_addr_offset <= aw_addr_offset;
// end

// //AR
// always @ (posedge aclk , negedge arset_n)begin
//     if(!areset_n)
//         ar_addr_offset <= 'b0;
//     else if(r_ready && r_valid)
//         ar_addr_offset <= ar_addr_offset + burst_size_byte;
//     else 
//         ar_addr_offset <= ar_addr_offset;
// end



//---------------------------
//5 channels hansshake signal
//---------------------------

//aw_valid
always @ (posedge aclk,negedge arset_n)begin
    if(!areset_n)
        aw_valid    <=  'b0;
    else if(!aw_valid && start_burst_write)
        aw_valid    <= 1'b1;
    else if(aw_valid && aw_ready)
        aw_valid    <= 1'b0;
    else
        aw_valid    <= aw_valid;
end

//w_valid
always @ (posedge aclk,negedge arset_n)begin
    if(!areset_n)
        w_valid    <=  'b0;
    else if(!w_valid && start_burst_write)
        w_valid    <= 1'b1;
    else if(w_valid && w_ready && w_last)
        w_valid    <= 1'b0;
    else
        w_valid    <= w_valid;
end

//b_ready
always @ (posedge aclk,negedge arset_n)begin
    if(!areset_n)
        b_ready     <= 'b0;
    else if(b_valid && !b_ready)
        b_ready     <= 1'b1;
    else if(b_ready)
        b_ready     <= 1'b0;
    else
        b_ready     <= b_ready;
end

//ar_validA
always @ (posedge aclk,negedge arset_n)begin
    if(!areset_n)
        aw_valid    <=  'b0;
    else if(!ar_valid && start_burst_read)
        ar_valid    <= 1'b1;
    else if(ar_valid && ar_ready)
        ar_valid    <= 1'b0;
    else
        ar_valid    <= ar_valid;
end

//r_ready
always @ (posedge aclk,negedge arset_n)begin
    if(!areset_n)
        r_ready     <= 'b0;
    else if(r_valid)begin
        if(r_last && r_ready)
            r_ready     <= 1'b0;
        else
            r_ready     <= 1'b1;
    end
end

//-----------------------------
//FSM
//-----------------------------
parameter [1:0] IDEL       =   2'b00;
parameter [1:0] READ       =   2'b01;
parameter [1:0] WRITE      =   2'b10;

reg [1:0]  master_state; 
reg        start_burst_write;
reg        start_burst_read;

always @ (posedge aclk,negedge arset_n)begin
    if(!areset_n)
    begin
        master_state        <= IDLE;
        start_burst_write   <= 'b0;
        start_burst_read    <= 'b0;
    end
    else begin
        case(master_state)
            IDLE:begin
                if(full)
                    master_state    <= IDEL;
                else if(init_read)    
                    master_state    <= READ;
                else if(init_write)
                    master_state    <= WRITE;
            end
            READ:begin
                if(read_done)
                    master_state    <= IDLE;
                else begin
                    master_state    <= READ;
                    if(!ar_valid && !start_burst_read && !burst_read_active)//start_burst_read is a signal to indicate the read is begining ,the second cycle ,this signal will be 0.
                        start_burst_read   <= 1'b1;
                    else
                        start_burst_read   <= 1'b0;
            end
            end
            WRITE:begin
                if(write_done)
                    master_state    <= IDLE;
                else begin
                    master_state    <= WRITE;
                    if(!aw_valid && !start_burst_write && !burst_write_active)
                        start_burst_write   <= 1'b1;
                    else
                        start_burst_write    <= 1'b0;
                end
            end
            default:begin
                master_state        <= IDLE;
            end
        endcase
    end
end

//burst_write_active signal & burst_reda_active signal
always @(posedge aclk , negedge areset_n)begin
    if(!areset_n)
        burst_write_active  <= 1'b0;
    else if(start_burst_write)
        burst_write_active  <= 1'b1;
    else if(b_valid && b_ready)
        burst_write_active  <= 'b0;
end


always @(posedge aclk , negedge areset_n)begin
    if(!areset_n)
        burst_read_active  <= 1'b0;
    else if(start_burst_write)
        burst_read_active  <= 1'b1;
    else if(r_valid && r_ready && r_last)
        burst_write_active  <= 'b0;
end


endmodule