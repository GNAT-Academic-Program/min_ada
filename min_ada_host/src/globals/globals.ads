with GNAT.Serial_Communications;

package Globals is

   --  The port to connect to
   Port : GNAT.Serial_Communications.Serial_Port;

   type Board_State is (Disconnected, Connected);

   for Board_State use (
      Disconnected   => 0,
      Connected      => 1
   );

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

end Globals;