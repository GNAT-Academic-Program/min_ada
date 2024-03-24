with Ada.Text_IO;                   use Ada.Text_IO;
with Ada.Streams;                   use Ada.Streams;

with GNAT.Serial_Communications;    use GNAT.Serial_Communications;

with Min_Ada;
with My_Min_Ada;

procedure Min_Ada_Host is
   UART_Port      : aliased Serial_Port;
   UART_Port_Name : constant Port_Name --  This will vary per system
                  := "/dev/cu.usbmodem103";

   --  Context for the min protocol
   Context     : Min_Ada.Min_Context;
begin
   declare
      --  Variables for the serial read
      Buffer   : Ada.Streams.Stream_Element_Array (1 .. 1);
      Offset   : Ada.Streams.Stream_Element_Offset := 1;
   begin
      -- Initialize MIN context
      Min_Ada.Min_Init_Context (Context => Context);
      My_Min_Ada.Override_Min_Application_Handler; --  We must override the handler to process received frames

      UART_Port.Open (Name => UART_Port_Name);
      UART_Port.Set (Rate => B115200);

      Put_Line ("Waiting to receive frames...");
      New_Line;

      loop
         --  Read one byte from serial port
         UART_Port.Read(
            Buffer => Buffer,
            Last   => Offset
         );

         --  Send data to MIN protocol for processing
         Min_Ada.Rx_Bytes (
            Context => Context,
            Data => Min_Ada.Byte (Buffer (1))
         );
      end loop;
      
   exception
      when Serial_Error =>
         Put_Line ("Serial Error - Board not connected or serial connection already active on port");
   end;

   UART_Port.Close;

end Min_Ada_Host;
