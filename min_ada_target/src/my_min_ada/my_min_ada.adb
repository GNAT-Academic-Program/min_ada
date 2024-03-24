with HAL;
with STM32.USARTs; use STM32.USARTs;
with STM32.Device; use STM32.Device;

with Uart_For_Board;

package body My_Min_Ada is

   procedure Tx_Byte (
      Data : Min_Ada.Byte
   ) is
   begin
      Uart_For_Board.Put_Blocking(USART_1, HAL.UInt16 (Data));
   end Tx_Byte;

   --  Overrides Tx_Byte
   procedure Override_Tx_Byte
   is
   begin
      Min_Ada.Set_Tx_Byte_Callback (
         Callback => Tx_Byte'Access
      );
   end Override_Tx_Byte;

end My_Min_Ada;
