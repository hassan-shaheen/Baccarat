# Audio Playback Device
The following repository contains the code I wrote for a playback device as part of a course at UBC. This system makes use of the Avalon Memory Mapped inteface and the handshaking protocol.

NOTE: All the file was initially provided by my instructor, during the course and was only edited by me.

NOTE: The Flash memory was programmed with a section of the "American hero song" using the programmer tool in Quartus.

The changes I made and implemented to the code are described below:

chipmunks.sv: 

I set up an implicit statemachine that reads the data from the flash memory of the FPGA and sends it to the audio core which makes uses of FIFOs to playback the audio. 

The statemachine also allows three modes of control for playback of the audio described below. The modes are accessed by configuring seitches 0-1 on the FPGA in the shown configurations.
               
              1. SW[1:0] = 00 or 11: Normal mode(no changes to playback)
              2. SW[1:0] = 01 : Chipmink mode, Playback is twice as fast.
              3. SW[1:0] = 10 : Slow mode, Playback is twice as slow.
              
 
