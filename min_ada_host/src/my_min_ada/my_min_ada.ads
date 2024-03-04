with Min_Ada; use Min_Ada;

package My_Min_Ada is

   procedure Min_Application_Handler (
      ID             : Min_Ada.App_ID;
      Payload        : Min_Ada.Min_Payload;
      Payload_Length : Min_Ada.Byte
   );

   procedure Override_Min_Application_Handler;
end My_Min_Ada;
