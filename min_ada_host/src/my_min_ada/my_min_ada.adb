with Ada.Text_IO; use Ada.Text_IO;

package body My_Min_Ada is

   procedure Min_Application_Handler (
      ID              : Min_Ada.App_ID;
      Payload         : Min_Ada.Min_Payload;
      Payload_Length  : Min_Ada.Byte
   ) is
      Message        : String (1 .. Integer (Payload_Length));
   begin

      Put_Line ("MIN Application Handler callback event.");

      Put_Line ("Frame has ID" & ID'Image);

      --  Loop over all the data in the payload to reconstruct the msg
      for I in 1 .. Integer'Val (Payload_Length) loop
         Message (I) := Character'Val (Payload (Min_Ada.Byte (I)));
      end loop;

      Put_Line ("Payload data is : " & Message);
      New_Line;

      Message_Received := To_Unbounded_String (Message);
      Received := True;

   end Min_Application_Handler;

   procedure Tx_Byte (
      Data : Min_Ada.Byte
   ) is
   begin
      --  Put_Line ("We are sending: " & Byte'Image (Data));
      Byte'Write(UART_Port'Access, Data);
      delay 0.1; --  TODO: Remove delay if possible (probably buffer tx byte calls and the send the whole buffer out in one go)
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
