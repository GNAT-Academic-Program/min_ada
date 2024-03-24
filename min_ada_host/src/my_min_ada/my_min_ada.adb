with Ada.Text_IO;    use Ada.Text_IO;

-- with Globals;

package body My_Min_Ada is

   --  Type to build a Reading from two Bytes
   type Reading_From_Bytes is array (1 .. 2) of Min_Ada.Byte;

   procedure Min_Application_Handler (
      ID              : Min_Ada.App_ID;
      Payload         : Min_Ada.Min_Payload;
      Payload_Length  : Min_Ada.Byte
   ) is
      Reading_Array   : Reading_From_Bytes;
      Current_Reading : Integer with Address => Reading_Array'Address;
   begin

      Put_Line ("MIN Application Handler callback event.");

      --  Check if first frame to reset the buffers (this makes sure the
      --  data in the buffers is always contiguous
      if ID = 5 or else ID = 6 or else ID = 7 then
         Put_Line ("First frame with ID: " & ID'Image);
         --  Globals.Buffered_Data.Reset_Buffer (
         --     Channel => Integer'Value (ID'Image)
         --  );
      end if;

      --  Loop over all the data in the payload
      for I in 1 .. Integer'Val (Payload_Length) loop
         if I mod 2 /= 0 then
            Reading_Array (2) := Payload (Min_Ada.Byte (I));
         else
            Reading_Array (1) := Payload (Min_Ada.Byte (I));

            Put_Line ("Payload data is :" & Integer'Image (Current_Reading));
            --  Save the current number in the data buffer
            --  Globals.Buffered_Data.Set_Data (
            --     Channel => Integer'Value (ID'Image),
            --     Data => Float (Current_Reading)
            --  );
         end if;
      end loop;
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
