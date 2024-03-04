with GNAT.Serial_Communications;
with Uart;

package Globals is

   --  The port to connect to
   Port : GNAT.Serial_Communications.Serial_Port;

   type Board_State is (Disconnected, Connected);

   for Board_State use (
      Disconnected   => 0,
      Connected      => 1
   );

   --  Number of sample data points to collect
   --  Must be divisible by 4 for triggering
   Number_Of_Samples : constant Integer := 1200;

   type Readings_Buffer is record
      Data  : Uart.Readings_Array (1 .. Number_Of_Samples);
      Index : Integer := 1;
   end record;

   protected Board_State_Change is

      --  Changes the state of the board to Connected
      procedure Change_State_Connected;

      --  Changes the state of the board to Disconnected
      procedure Change_State_Disconnected;

      --  Gets current board state
      function Get_Board_State return Board_State;

   private
      Current_Board_State : Board_State := Disconnected;
   end Board_State_Change;

   protected Processed_Data is

      --  Sets the data array
      procedure Set_Data (
         Channel : Integer;
         Data    : Uart.Readings_Array
      );

      --  Gets the data array
      function Get_Data (
         Channel : Integer
      ) return Uart.Readings_Array;

      --  Gets the data array
      function Get_Data_Point (
         Channel : Integer;
         Index   : Integer
      ) return Float;

   private
      --  Arrays storing the processed data
      Processed_Data_Channel_1 : Uart.Readings_Array
         (1 .. Number_Of_Samples / 2) := (others => 0.0);

      Processed_Data_Channel_2 : Uart.Readings_Array
         (1 .. Number_Of_Samples / 2) := (others => 0.0);

      Processed_Data_Channel_3 : Uart.Readings_Array
         (1 .. Number_Of_Samples / 2) := (others => 0.0);

   end Processed_Data;

   protected Buffered_Data is

      --  Sets the buffer value at the current index
      procedure Set_Data (
         Channel : Integer;
         Data    : Float
      );

      --  Resets the buffer
      procedure Reset_Buffer (
         Channel : Integer
      );

      --  Does all the triggering processing
      procedure Process_Data (
         Channel : Integer;
         Buffer  : Uart.Readings_Array
      );

   private
      --  Arrays storing the raw data used as a buffer
      Readings_Buffer_Channel_1 : Readings_Buffer;

      Readings_Buffer_Channel_2 : Readings_Buffer;

      Readings_Buffer_Channel_3 : Readings_Buffer;

   end Buffered_Data;

end Globals;