with STM32.Device;      use STM32.Device;
with HAL;

with Uart_For_Board;

with Min_Ada;
with My_Min_Ada;

with Screen_Draw;
procedure Min_Ada_Target is
   App_ID      : constant Min_Ada.App_ID := 5; --  The host program will look for this ID
   Context     : Min_Ada.Min_Context;

   Sent_Count  : Integer := 1;
begin
   --  Initialize Serial/UART
   Uart_For_Board.Initialize;

   --  Initialize MIN
   Min_Ada.Min_Init_Context (Context => Context);
   My_Min_Ada.Override_Min_Application_Handler; --  We must override the handler to process received frames
   My_Min_Ada.Override_Tx_Byte; --  We must override Tx_Byte in order the send the frames over serial
   

   Screen_Draw.WriteMsg ("UART & MIN ready.");
   delay 1.0;

   declare
      Message     : constant String := "Hello World" & Sent_Count'Image & "!"; --  What we want to send, can be anything
      Payload     : Min_Ada.Min_Payload;  --  The message above needs to be converted to bytes

      Rcv_Data    : HAL.UInt16;
   begin
      --  Convert Message string to array of bytes (payload)
      for K in Message'Range loop
         Payload (Min_Ada.Byte (K))
            := Min_Ada.Byte (Character'Pos (Message (K)));
      end loop;

      --  Send our payload via MIN frames (non-transport)
      Min_Ada.Send_Frame
      (Context        => Context,
         ID             => App_ID, 
         Payload        => Payload,
         Payload_Length => Message'Length);

      --  Inform the user the message/payload was sent
      Screen_Draw.WriteMsg ("Sent: " & Message);

      Sent_Count := Sent_Count + 1;

      loop
         --  Read one byte from serial port
         Uart_For_Board.Get_Blocking (USART_1, Data => Rcv_Data);

         Screen_Draw.WriteMsg ("Received:" & Rcv_Data'Image);

         --  Send data to MIN protocol for processing
         Min_Ada.Rx_Bytes (
            Context => Context,
            Data => Min_Ada.Byte (Rcv_Data)
         );
      end loop;
   end;

end Min_Ada_Target;
