with HAL;           use HAL;
with STM32.GPIO;    use STM32.GPIO;
with STM32.USARTs;  use STM32.USARTs;

with STM32.Device;  use STM32.Device;

with Ada.Real_Time; use Ada.Real_Time;

--with Beta_Types; use Beta_Types;

package Uart_For_Board is
   procedure Initialize_UART_GPIO;
   procedure Initialize;
   procedure Await_Send_Ready (This : USART) with Inline;
   procedure Put_Blocking (This : in out USART;  Data : UInt16);
end Uart_For_Board;
