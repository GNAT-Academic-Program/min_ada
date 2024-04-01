with Min_Ada;                    use Min_Ada;
with GNAT.Serial_Communications; use GNAT.Serial_Communications;

with Ada.Strings.Unbounded;      use Ada.Strings.Unbounded;

package My_Min_Ada is

   UART_Port                 : aliased Serial_Port;

   UART_Port_Name            : constant Port_Name --  This will vary per system
                                 := "/dev/cu.usbmodem103";

   Message_Received          : Unbounded_String;
   Received                  : Boolean := False;

   --  Handle receiving MIN frames
   procedure Min_Application_Handler (
      ID             : Min_Ada.App_ID;
      Payload        : Min_Ada.Min_Payload;
      Payload_Length : Min_Ada.Byte
   );

   --  Handle sending MIN bytes over Serial
   procedure Tx_Byte (
      Data : Min_Ada.Byte
   );

   procedure Override_Min_Application_Handler;
   procedure Override_Tx_Byte;
end My_Min_Ada;
