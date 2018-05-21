# Audio Playback Device
The following repository contains the code I wrote for a playback device as part of a course at UBC. This system makes use of the Avalon Memory Mapped inteface and the handshaking protocol.

NOTE: All the files were initially provided by my instructor, during the course and were only edited by me.

NOTE: The Flash memory was programmed with a section of the "American hero song" using the programmer tool in Quartus.

s_mem.v: The quartus generated code for on-chip memory

The three files I edited and implemented the code for are described below:

flash_reader.sv: This was the first step of my implementation. This program uses an implicit statemachine to ensure the correct values are being copied from the flash memory of the De1-SoC by reading a select few of them and then writting them to and on-chip memory that was described in quartus.

music.sv: A statemachine that uses the code from flash_reader to sample all the values from flash memory and sends them to the audio core of the De1-SoC which makes use of FIFOs

chipmunks.sv: A statemachine that allows three modes of control for playback of the audio described below. The modes are accessed by configuring seitches 0-1 on the FPGA in the shown configurations.
               
              1. SW[1:0] = 00 or 11: Normal mode(no changes to playback)
              2. SW[1:0] = 01 : Chipmink mode, Playback is twice as fast.
              3. SW[1:0] = 10 : Slow mode, Playback is twice as slow.
              
 
