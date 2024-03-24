with Ada.Text_IO;    use Ada.Text_IO;

package body My_Min_Ada is

   procedure Min_Application_Handler (
      ID              : Min_Ada.App_ID;
      Payload         : Min_Ada.Min_Payload;
      Payload_Length  : Min_Ada.Byte
   ) is
      Message        : String (1 .. Integer (Payload_Length));
   begin

      Put_Line ("MIN Application Handler callback event.");

      --  Check if first frame ID is 5 (comes from our target device)
      --  We could reset a buffer here, if needed
      if ID = 5 then
         Put_Line ("First frame, has ID" & ID'Image);
      end if;

      --  Loop over all the data in the payload to reconstruct the msg
      for I in 1 .. Integer'Val (Payload_Length) loop
         Message (I) := Character'Val (Payload (Min_Ada.Byte (I)));
      end loop;

      Put_Line ("Payload data is : " & Message);
      New_Line;

   end Min_Application_Handler;

   --  Overrides Min_Application_Handler
   procedure Override_Min_Application_Handler
   is
   begin
      Min_Ada.Set_Min_Application_Handler_Callback (
         Callback => Min_Application_Handler'Access
      );
   end Override_Min_Application_Handler;

end My_Min_Ada;
