with Min_Ada;

package Uart is

   --  Type for the values returned by Read function
   type Readings_Array is array (Integer range <>) of Float;

   --  Type to receive the data from the target
   D : constant := 0.1;
   type Reading is delta D range 0.0 .. 3000.0;

   --  Type to build a Reading from two Bytes
   type Reading_From_Bytes is array (1 .. 2) of Min_Ada.Byte;

   task type Read is
      entry Start;
      entry Stop;
   end Read;
end Uart;
