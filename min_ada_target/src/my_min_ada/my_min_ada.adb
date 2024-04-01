with HAL;
with STM32.Device; use STM32.Device;

with Uart_For_Board;
with Screen_Draw;

package body My_Min_Ada is

   procedure Min_Application_Handler (
      ID              : Min_Ada.App_ID;
      Payload         : Min_Ada.Min_Payload;
      Payload_Length  : Min_Ada.Byte
   ) is
      Message         : String (1 .. Integer (Payload_Length));
   begin

      Screen_Draw.WriteMsg ("MIN Application Handler callback event.");

      --  Check if first frame ID is 6 (comes from our host device)
      --  We could reset a buffer here, if needed
      if ID = 6 then
         Screen_Draw.WriteMsg ("First frame, has ID" & ID'Image);
      end if;

      --  Loop over all the data in the payload to reconstruct the msg
      for I in 1 .. Integer'Val (Payload_Length) loop
         Message (I) := Character'Val (Payload (Min_Ada.Byte (I)));
      end loop;

      Screen_Draw.WriteMsg ("Payload data is : " & Message);

   end Min_Application_Handler;

   procedure Tx_Byte (
      Data : Min_Ada.Byte
   ) is
   begin
      Uart_For_Board.Put_Blocking(USART_1, HAL.UInt16 (Data));
   end Tx_Byte;

   --  Overrides Min_Application_Handler
   procedure Override_Min_Application_Handler
   is
   begin
      Min_Ada.Set_Min_Application_Handler_Callback (
         Callback => Min_Application_Handler'Access
      );
   end Override_Min_Application_Handler;

   --  Overrides Tx_Byte
   procedure Override_Tx_Byte
   is
   begin
      Min_Ada.Set_Tx_Byte_Callback (
         Callback => Tx_Byte'Access
      );
   end Override_Tx_Byte;

end My_Min_Ada;
