with Ada.Text_IO;                   use Ada.Text_IO;
with Ada.Streams;                   use Ada.Streams;
with Ada.Strings.Unbounded;         use Ada.Strings.Unbounded;

with GNAT.Serial_Communications;    use GNAT.Serial_Communications;

with Min_Ada;
with My_Min_Ada;                    use My_Min_Ada;

procedure Min_Ada_Host is
   App_ID      : constant Min_Ada.App_ID := 6; --  The target program will look for this ID
   Context     : Min_Ada.Min_Context;
begin
   declare
      --  Variables for the serial read
      Buffer   : Stream_Element_Array (1 .. 1);
      Offset   : Stream_Element_Offset := 1;

      -- Variables for the serial write
      Payload : Min_Ada.Min_Payload;
   begin
      -- Initialize MIN context
      Min_Ada.Min_Init_Context (Context => Context);

      UART_Port.Open (Name => UART_Port_Name);
      UART_Port.Set
        (Rate      => B115200,
         Bits      => CS8,
         Stop_Bits => One,
         Parity    => None,
         Flow      => None);

      Override_Min_Application_Handler; --  We must override the handler to process received frames
      Override_Tx_Byte; --  We must override the handler to send MIN data over Serial

      Put_Line ("Waiting to receive frames...");
      New_Line;

      loop
         while not (My_Min_Ada.Received) loop
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

         delay 1.0;

         declare
            M : constant String := To_String (My_Min_Ada.Message_Received);
            --  M : constant String := "Msg from host";
         begin
            Put_Line("Echoing back received payload : " & M);
            New_Line;

            --  Convert Message string to array of bytes (payload)
            for K in M'Range loop
               Payload (Min_Ada.Byte (K))
                  := Min_Ada.Byte (Character'Pos (M (K)));
            end loop;

            --  Echo back payload via MIN frames (non-transport)
            Min_Ada.Send_Frame
            (Context        => Context,
               ID             => App_ID, 
               Payload        => Payload,
               Payload_Length => M'Length);
            
            My_Min_Ada.Received := False;

            New_Line; 
         end;
      end loop;

   exception
      when Serial_Error =>
         Put_Line ("Serial Error - Board not connected or serial connection already occupied");
   end;

   UART_Port.Close;

end Min_Ada_Host;
