module music(input CLOCK_50, input CLOCK2_50, input [3:0] KEY, input [9:0] SW,
             input AUD_DACLRCK, input AUD_ADCLRCK, input AUD_BCLK, input AUD_ADCDAT,
             inout FPGA_I2C_SDAT, output FPGA_I2C_SCLK, output AUD_DACDAT, output AUD_XCK,
             output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2,
             output [6:0] HEX3, output [6:0] HEX4, output [6:0] HEX5,
             output reg [9:0] LEDR);
			
//DONE WITH RIGHT VOLUME

// signals that are used to communicate with the audio core
// DO NOT alter these -- we will use them to test your design

reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
logic read_s;
logic reset;

// signals that are used to communicate with the flash core
// DO NOT alter these -- we will use them to test your design

reg flash_mem_read;
reg flash_mem_waitrequest;
reg [22:0] flash_mem_address;
reg [31:0] flash_mem_readdata;
reg flash_mem_readdatavalid;
logic [3:0] flash_mem_byteenable;
logic rst_n, clk;

assign reset = ~(KEY[3]);
assign rst_n = KEY[3];
assign clk = CLOCK_50;
assign read_s = 1'b0;

//Internal Variables

integer i;

// To account for the sign of the samples we must break them into two signed variables prior to divison
// The divisor will also be stored in a signed register so the division goes smoothly

reg signed [15:0] temp_one;
reg signed [15:0] temp_two;
reg signed [6:0]  divisor;

//State declaration

enum {S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11} state;

// DO NOT alter the instance names or port names below -- we will use them to test your design

clock_generator my_clock_gen(CLOCK2_50, reset, AUD_XCK);
audio_and_video_config cfg(CLOCK_50, reset, FPGA_I2C_SDAT, FPGA_I2C_SCLK);
audio_codec codec(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);
flash flash_inst(.clk_clk(clk), .reset_reset_n(rst_n), .flash_mem_write(1'b0), .flash_mem_burstcount(1'b1),
                 .flash_mem_waitrequest(flash_mem_waitrequest), .flash_mem_read(flash_mem_read), .flash_mem_address(flash_mem_address),
                 .flash_mem_readdata(flash_mem_readdata), .flash_mem_readdatavalid(flash_mem_readdatavalid), .flash_mem_byteenable(flash_mem_byteenable), .flash_mem_writedata());


assign flash_mem_byteenable = 4'b1111;


always_ff @ (posedge CLOCK_50 or negedge rst_n) begin

    if ( rst_n == 1'b0 ) begin

    i <= 0;
    write_s <= 1'b0;
    flash_mem_address <= 0;
    flash_mem_read <= 0;
    divisor <= 7'b1000000; // This is equal to 64 and used to decrease the volume
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
            
            temp_one <= flash_mem_readdata[15:0];
            temp_two <= flash_mem_readdata[31:16];
            state <= S5;

        end

        // Start the wrtie process to FIFO first we wait until ready

        S5: begin
        			 
		write_s <= 1'b0;

             if (write_ready == 1'b1)  

	            state <= S6;

            else
            
                state <= S5;

        end

        // We now send the sample since the FIFO is ready

        S6:begin
            
            writedata_right <= (temp_one/divisor);
			writedata_left <= (temp_one/divisor);
		    write_s <= 1'b1;  // indicate we are writing a value
            state <= S7;

        end    


        // Wait to see if request has been recieved

        S7: begin

            if (write_ready == 1'b0) begin

                state <= S8;

            end else begin

                state <= S7;
            end

        end


        // WRTIE THE NEXT HALF OF THE TEMP!


        S8: begin
				 			 
		write_s <= 1'b0;

             if (write_ready == 1'b1)  

	            state <= S9;

            else
            
                state <= S8;

        end

        // We now send the sample since the FIFO is ready

        S9:begin
            
            writedata_right <= (temp_two/divisor);
			writedata_left <= (temp_two/divisor);
		    write_s <= 1'b1;  // indicate we are writing a value
            state <= S10;

        end    


        // Wait to see if request has been recieved

        S10: begin

            if (write_ready == 1'b0) begin

                state <= S11;

            end else begin

                state <= S10;
            end

        end



         S11: begin

            write_s <= 1'b0;
                
             if ( i == 24'h100000 ) begin  //1048576 because we are send 32 bit samples this number is half of 2097152 or 0x200000

             i <= 0;
             state <= S1;
                 
             end else begin

             i <= i + 1'b1;
             state <= S1;
                 
             end            
                

        end
   
        
        default: state <= S1;
    endcase
        
    end
    
end

endmodule: music
