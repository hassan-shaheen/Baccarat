module flash_reader(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
                    output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
                    output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
                    output logic [9:0] LEDR);

// You may use the SW/HEX/LEDR ports for debugging. DO NOT delete or rename any ports or signals.

logic clk, rst_n;

assign clk = CLOCK_50;
assign rst_n = KEY[3];

logic flash_mem_read, flash_mem_waitrequest, flash_mem_readdatavalid;
logic [22:0] flash_mem_address;
logic [31:0] flash_mem_readdata;
logic [3:0] flash_mem_byteenable;

//Internal Variables and on-chip memory

reg [7:0] j;
reg [7:0] i;
reg [7:0] addr;
reg [15:0] wrdata;
reg wren;
reg [31:0] temp;
wire [15:0] q;

//State declaration

enum {S1, S2, S3, S4, S5, S6, S7, S8} state;

flash flash_inst(.clk_clk(clk), .reset_reset_n(rst_n), .flash_mem_write(1'b0), .flash_mem_burstcount(1'b1),
                 .flash_mem_waitrequest(flash_mem_waitrequest), .flash_mem_read(flash_mem_read), .flash_mem_address(flash_mem_address),
                 .flash_mem_readdata(flash_mem_readdata), .flash_mem_readdatavalid(flash_mem_readdatavalid), .flash_mem_byteenable(flash_mem_byteenable), .flash_mem_writedata());

s_mem samples( .address(addr),
	           .clock(CLOCK_50),
	           .data(wrdata),
	           .wren(wren),
	           .q(q) );

assign flash_mem_byteenable = 4'b1111;

always_ff @(posedge CLOCK_50 or negedge rst_n) begin
    
if ( rst_n == 1'b0 ) begin

    i <= 0;
    j <= 0;
    addr <= 0; 
    wren <= 0;
    flash_mem_address <= 0;
    flash_mem_read <= 0;
    state <= S1;
    
end else begin

    case(state)
        
        S1: begin

        // Initiate the transfer and wait until wait request has been deasserted befor proceeding.

            flash_mem_address <= i;
            flash_mem_read <= 1'b1;

            if ( flash_mem_waitrequest == 1'b0 ) begin

                state <= S2;

            end else begin
                
                state <= S1;

            end
        
        end

        // We now wait for flash_mem_readdatavalid to tell us when the data is available for reading.

        S2: begin

            if ( flash_mem_readdatavalid == 1'b1 ) begin

                flash_mem_read <= 1'b0;
                state <= S3;
                
            end else begin
                
                state <= S2;

            end
            
        end

        // We need one cycle of latency between acceptance of read and the assertion of readdatavalid as per the avalon specification handed out in the lab document

        S3: begin
            
            state <= S4;

        end

        // We can now store the readdata into temporary variables

        S4: begin
            
            temp <= flash_mem_readdata;
            state <= S5;

        end

        // We can now write low and high temp to the on-chip memory. 

        S5: begin

            addr <= j;
            wrdata <= temp[15:0];
            wren <= 1'b1;
            state <= S6;
            
        end

         S6: begin

            addr <= j + 1'b1;
            wrdata <= temp[31:16];
            wren <= 1'b1;
            state <= S7;
            
        end

        // Increment i, disable wren and return to S1

        S7: begin

            wren <= 1'b0;

            if ( i < 127 ) begin   // Our memory has space for 256 16-bit words if we are storing 32-bit words then we only run the counter to half of that limit.
                
                i <= i + 1'b1;
                j <= j + 2'b10;
                state <= S1;            

            end else begin

                state <= S7;
                
            end

        end


        default: state <= S1;
    endcase
    
end


end

endmodule: flash_reader