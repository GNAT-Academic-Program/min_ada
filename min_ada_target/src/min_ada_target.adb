with STM32.Device;          use STM32.Device;

with Uart_For_Board;
with Screen_Draw;

procedure Min_Ada_Target is
   Incoming : String (1 .. Uart_For_Board.Msg_Size);
begin
   Uart_For_Board.Initialize;

   Screen_Draw.WriteMsg ("Waiting to receive...");
   loop
      Uart_For_Board.Get_Msg (USART_1, Incoming);
      Screen_Draw.WriteMsg ("Received:" & Incoming);

      --  echo the received msg content back
      Uart_For_Board.Put_Msg (USART_1, Incoming);
   end loop;
end Min_Ada_Target;
