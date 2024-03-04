with Ada.Real_Time; use Ada.Real_Time;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with My_Min_Ada;

with STM32;
with STM32.Device; use STM32.Device;
with STM32.GPIO; use STM32.GPIO;
with STM32.SPI;  use STM32.SPI;
with STM32.USARTs;  use STM32.USARTs;

with HAL;           use HAL;

with STM32.Board;

with Uart_For_Board;
with Min_Ada;

with Screen_Draw;

procedure Min_Ada_Target is
   Frame_Count             : Integer := 10;
   Data_Points_Per_Payload : Integer := 120;

   type Payload_Arr is
      array (1 .. Frame_Count) of Min_Ada.Min_Payload;

   Period          : constant Time_Span := Milliseconds (250);  -- arbitrary
   Next_Release    : Time := Clock;
   Temp            : Unbounded_String;
   Context         : Min_Ada.Min_Context;
   Payload_Index   : Integer;
   Data_Count      : Integer;
   Frame_Index     : Integer;
   Payloads        : Payload_Arr;
   Payload_Indexes : array (1 .. Frame_Count) of Integer;

   type Min_Reading_Bytes is array (1 .. 2) of Min_Ada.Byte;

   procedure Send_Data(Input : Integer) is
      Value           : Integer;
      Value_Bytes     : Min_Reading_Bytes with Address => Value'Address;
   begin
      Frame_Index := 1;
      --  Iterate through all the frames
      while Frame_Index < Frame_Count + 1 loop

         --  Iterate through all the data points
         while Data_Count < Data_Points_Per_Payload loop
            Value := Input; -- Since we have no ADC to read, we just use the Input value
            Payloads (Frame_Index) (Min_Ada.Byte (Payload_Index)) := 
               Value_Bytes (2);
            Payload_Index := Payload_Index + 1;
            Payloads (Frame_Index) (Min_Ada.Byte (Payload_Index)) := 
               Value_Bytes (1);
            Payload_Index := Payload_Index + 1;
            Data_Count := Data_Count + 1;
         end loop;
         Payload_Indexes (Frame_Index) := Payload_Index;
         Frame_Index := Frame_Index + 1;
         Data_Count := 0;
         Payload_Index := 1;
      end loop;

      Frame_Index := 1;
      while Frame_Index < Frame_Count + 1 loop
         if Frame_Index = 1 then
            Min_Ada.Send_Frame (
               Context => Context,
               ID => Min_Ada.App_ID (Input + 4),
               Payload => Payloads(Frame_Index),
               Payload_Length => Min_Ada.Byte (Payload_Indexes(Frame_Index) - 1)
            );
         else
            Min_Ada.Send_Frame (
               Context => Context,
               ID => Min_Ada.App_ID (Input),
               Payload => Payloads(Frame_Index),
               Payload_Length => Min_Ada.Byte (Payload_Indexes(Frame_Index) - 1)
            );
         end if;
         Frame_Index := Frame_Index + 1;
      end loop;
   end Send_Data;
begin
   Uart_For_Board.Initialize;

   --  Init min
   Min_Ada.Min_Init_Context (Context);
   Payload_Index := 1;
   Data_Count := 0; -- Max of 51 for now
   Frame_Index := 1;

   My_Min_Ada.Override_Tx_Byte;

   Screen_Draw.WriteMsg("UART and MIN context init complete.");

   delay 2.0; -- Wait two seconds before starting so we can see the msg above

   declare
      Input_Counter: Integer;
   begin
      Input_Counter := 1;
      loop
         If Input_Counter > 5 then
            Input_Counter := 1;
         end if;

         Screen_Draw.WriteMsg("Sending data:" & Integer'Image(Input_Counter));
         Send_Data(Input_Counter);
         delay 1.0;
         Input_Counter := Input_Counter + 1;
      end loop;
   end;
end Min_Ada_Target;
