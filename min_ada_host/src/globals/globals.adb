with Ada.Text_IO; use Ada.Text_IO;

package body Globals is

   protected body Board_State_Change is

      -------------------------------------
      -- Change board state to Connected --
      -------------------------------------
      procedure Change_State_Connected is
      begin
         Current_Board_State := Connected;
      end Change_State_Connected;

      ----------------------------------------
      -- Change board state to Disconnected --
      ----------------------------------------
      procedure Change_State_Disconnected is
      begin
         Current_Board_State := Disconnected;
      end Change_State_Disconnected;

      ---------------------------------
      -- Returns current board state --
      ---------------------------------
      function Get_Board_State return Board_State is
      begin
         return Current_Board_State;
      end Get_Board_State;

   end Board_State_Change;

   protected body Processed_Data is

      -----------------------------------------------
      -- Sets processed data for specified channel --
      -----------------------------------------------
      procedure Set_Data (
         Channel : Integer;
         Data    : Uart.Readings_Array
      ) is
      begin
         case Channel is
            when 1 | 5 =>
               Processed_Data_Channel_1 := Data;
            when 2 | 6 =>
               Processed_Data_Channel_2 := Data;
            when 3 | 7 =>
               Processed_Data_Channel_3 := Data;
            when others =>
               Put_Line ("Error Processed_Data.Set_Data");
               Put_Line ("Wrong channel entered:" & Channel'Image);
         end case;
      end Set_Data;

      -----------------------------------------------
      -- Gets processed data for specified channel --
      -----------------------------------------------
      function Get_Data (
         Channel : Integer
      ) return Uart.Readings_Array is
         Default_Array : constant Uart.Readings_Array
            (1 .. Number_Of_Samples) := (others => 0.0);
      begin
         case Channel is
            when 1 | 5 =>
               return Processed_Data_Channel_1;
            when 2 | 6 =>
               return Processed_Data_Channel_2;
            when 3 | 7 =>
               return Processed_Data_Channel_3;
            when others =>
               Put_Line ("Error Processed_Data.Get_Data");
               Put_Line ("Wrong channel entered:" & Channel'Image);
               return Default_Array;
         end case;
      end Get_Data;

      -----------------------------------------------------
      -- Gets data point for specified channel and index --
      -----------------------------------------------------
      function Get_Data_Point (
         Channel : Integer;
         Index   : Integer
      ) return Float is
      begin
         case Channel is
            when 1 | 5 =>
               return Processed_Data_Channel_1 (Index);
            when 2 | 6 =>
               return Processed_Data_Channel_2 (Index);
            when 3 | 7 =>
               return Processed_Data_Channel_3 (Index);
            when others =>
               Put_Line ("Error Processed_Data.Get_Data_Point");
               Put_Line ("Wrong channel entered:" & Channel'Image);
               return 0.0;
         end case;
      end Get_Data_Point;
   end Processed_Data;

   protected body Buffered_Data is

      -----------------------------------------------------------------
      -- Sets unprocessed data point in buffer for specified channel --
      -----------------------------------------------------------------
      procedure Set_Data (
         Channel : Integer;
         Data    : Float
      ) is
      begin
         case Channel is
            when 1 | 5 =>
               Readings_Buffer_Channel_1.Data
                  (Readings_Buffer_Channel_1.Index) := Data;

               if Readings_Buffer_Channel_1.Index < Number_Of_Samples then
                  Readings_Buffer_Channel_1.Index :=
                     Readings_Buffer_Channel_1.Index + 1;
               else
                  Readings_Buffer_Channel_1.Index := 1;
                  Process_Data (
                     Channel => 1,
                     Buffer  => Readings_Buffer_Channel_1.Data
                  );
               end if;

            when 2 | 6 =>
               Readings_Buffer_Channel_2.Data
                  (Readings_Buffer_Channel_2.Index) := Data;

               if Readings_Buffer_Channel_2.Index < Number_Of_Samples then
                  Readings_Buffer_Channel_2.Index :=
                     Readings_Buffer_Channel_2.Index + 1;
               else
                  Readings_Buffer_Channel_2.Index := 1;
                  Process_Data (
                     Channel => 2,
                     Buffer  => Readings_Buffer_Channel_2.Data
                  );
               end if;

            when 3 | 7 =>
               Readings_Buffer_Channel_3.Data
                  (Readings_Buffer_Channel_3.Index) := Data;

               if Readings_Buffer_Channel_3.Index < Number_Of_Samples then
                  Readings_Buffer_Channel_3.Index :=
                     Readings_Buffer_Channel_3.Index + 1;
               else
                  Readings_Buffer_Channel_3.Index := 1;
                  Process_Data (
                     Channel => 3,
                     Buffer  => Readings_Buffer_Channel_3.Data
                  );
               end if;

            when others =>
               Put_Line ("Error Buffered_Data.Set_Data");
               Put_Line ("Wrong channel entered:" & Channel'Image);
         end case;
      end Set_Data;

      -----------------------------------------
      -- Resets buffer for specified channel --
      -----------------------------------------
      procedure Reset_Buffer (
         Channel : Integer
      ) is
      begin
         case Channel is
            when 1 | 5 =>
               Readings_Buffer_Channel_1.Index := 1;
            when 2 | 6 =>
               Readings_Buffer_Channel_2.Index := 1;
            when 3 | 7 =>
               Readings_Buffer_Channel_3.Index := 1;
            when others =>
               Put_Line ("Error Buffered_Data.Reset_Buffer");
               Put_Line ("Wrong channel entered:" & Channel'Image);
         end case;
      end Reset_Buffer;

      ----------------------------------------
      -- Does all the triggering processing --
      ----------------------------------------
      procedure Process_Data (
         Channel : Integer;
         Buffer  : Uart.Readings_Array
      ) is
         --  Denotes the start and end of the captured data
         --  This will be a subset of the data comming  in
         --  and will be half its size
         Capture_Start  : Integer;
         Capture_End    : Integer;

         --  To find the center point of the wave
         Data_Min       : Float   := 5000.0; --  Higher than max (3000)
         Data_Max       : Float   := 0.0;    --  Lower or equal to max

         --  The voltage value of the middle of the wave
         Trigger_Level  : Float;

         --  If all the trigger conditions are met
         Triggered      : Boolean := False;
      begin

         --  Set the trigger point in the center
         for I in 1 .. Number_Of_Samples loop
            Data_Min := Float'Min (Data_Min, Buffer (I));
            Data_Max := Float'Max (Data_Max, Buffer (I));
         end loop;
         Trigger_Level := (Data_Min + Data_Max) / 2.0;

         --  Loop over all the valid data buffer
         for I in (Number_Of_Samples / 4) + 1 ..
            Number_Of_Samples - (Number_Of_Samples / 4) loop

            --  Check if data meets trigger condition
            if Buffer (I + 1) > Trigger_Level and then
               Buffer (I) <= Trigger_Level
            then
               --  Take data before and after trigger point
               --  (trigger will be in center)
               Capture_Start := I - (Number_Of_Samples / 4) + 1;
               Capture_End := I + (Number_Of_Samples / 4);

               --  Make sure we have the correct number of samples
               --  (Should be half of the data buffer size)
               if (Capture_End - Capture_Start) /=
                  (Number_Of_Samples / 2) - 1
               then
                  Triggered     := False;
               else
                  Triggered     := True;
               end if;
            end if;
         end loop;

         --  Save the processed data in the processed data array
         --  only if we were able to trigger
         if Triggered then
            Globals.Processed_Data.Set_Data (
               Channel => Channel,
               Data    => Buffer (Capture_Start .. Capture_End)
            );
         end if;
      end Process_Data;

   end Buffered_Data;

end Globals;