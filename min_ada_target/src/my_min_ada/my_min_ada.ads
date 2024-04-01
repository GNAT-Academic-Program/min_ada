with Min_Ada; use Min_Ada;

package My_Min_Ada is

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