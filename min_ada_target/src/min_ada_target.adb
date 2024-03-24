with STM32.Board;           use STM32.Board;
with HAL.Touch_Panel;       use HAL.Touch_Panel;

with Uart_For_Board;

with Min_Ada;
with My_Min_Ada;

with Screen_Draw;
procedure Min_Ada_Target is
   Context     : Min_Ada.Min_Context;
   App_ID      : Min_Ada.App_ID := 5; --  The host program will look for this ID

   Sent_Count  : Integer := 1;
begin
   --  Initialize Serial/UART
   Uart_For_Board.Initialize;

   --  Initialize MIN
   Min_Ada.Min_Init_Context (Context => Context);
   My_Min_Ada.Override_Tx_Byte; --  We must override Tx_Byte in order the send the frames over serial

   Screen_Draw.WriteMsg ("UART & MIN ready. Tap to send msg.");

   loop
      declare
         Touch_State : constant TP_State := Touch_Panel.Get_All_Touch_Points;

         Message  : constant String := "Hello World" & Sent_Count'Image & "!"; --  What we want to send, can be anything
         Payload : Min_Ada.Min_Payload;  --  The message above needs to be converted to bytes
      begin
         --  We use the touch screen to send payloads

         --  Detect touch
         if Touch_State'Length = 1 then

            --  Convert Message string to array of bytes (payload)
            for K in Message'Range loop
               Payload (Min_Ada.Byte (K))
                  := Min_Ada.Byte (Character'Pos (Message (K)));
            end loop;

            --  Send our payload via MIN frames (non-transport)
            Min_Ada.Send_Frame
            (Context        => Context,
               ID             => 5, 
               Payload        => Payload,
               Payload_Length => Message'Length);

            --  Inform the user the message/payload was sent
            Screen_Draw.WriteMsg ("Sent: " & Message);

            Sent_Count := Sent_Count + 1;

            --  Wait for touch release (optional)
            while Touch_Panel.Get_All_Touch_Points'Length = 1 loop
               null;
            end loop;
         end if;
      end;
   end loop;

   --  Screen_Draw.WriteMsg ("Waiting to receive...");
   --  loop
   --     Uart_For_Board.Get_Msg (USART_1, Incoming);
   --     Screen_Draw.WriteMsg ("Received:" & Incoming);

   --     --  echo the received msg content back
   --     Uart_For_Board.Put_Msg (USART_1, Incoming);
   --  end loop;
end Min_Ada_Target;
