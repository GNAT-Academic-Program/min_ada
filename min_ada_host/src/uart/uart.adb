with GNAT.Serial_Communications;
with Ada.Streams;
with Globals;
with My_Min_Ada;

package body Uart is

   --  Reads the data from the UART and sends it to Min_Ada
   task body Read is

      --  Variables for the serial read
      Buffer   : Ada.Streams.Stream_Element_Array (1 .. 1);
      Offset   : Ada.Streams.Stream_Element_Offset := 1;

      --  Context for the min protocol
      Context  : Min_Ada.Min_Context;
   begin

      --  Waiting for parameters or exit request
      select
         accept Start do
            --  Initialize context
            Min_Ada.Min_Init_Context (Context => Context);
            My_Min_Ada.Override_Min_Application_Handler;

            loop
               --  Read one byte from serial port
               GNAT.Serial_Communications.Read (
                  Port   => Globals.Port,
                  Buffer => Buffer,
                  Last   => Offset
               );
               --  Send data to protocol for processing
               Min_Ada.Rx_Bytes (
                  Context => Context,
                  Data => Min_Ada.Byte (Buffer (1))
               );
            end loop;
         end Start;

      or accept Stop;
         -- Must raise something to give the stop signal to the main thread 
      end select;

      accept Stop;
   end Read;
end Uart;
