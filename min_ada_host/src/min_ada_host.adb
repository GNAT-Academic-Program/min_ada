with Ada.Text_IO;                   use Ada.Text_IO;
with Ada.Streams;                   use Ada.Streams;

with GNAT.Serial_Communications;    use GNAT.Serial_Communications;

procedure Min_Ada_Host is
   S_Port      : aliased Serial_Port;
   S_Port_Name : constant Port_Name --  This will vary per system
                  := "/dev/cu.usbmodem103";

   Msg_Size : constant Integer := 20;
   subtype Message is Stream_Element_Array (1 .. Stream_Element_Offset (Msg_Size));

   --  Context for the min protocol
   --  Context     : Min_Ada.Min_Context;
begin
   declare
      Data        : constant String := "My message" & ASCII.NUL;
      Buffer      : Message;
   begin
      --  -- Initialize MIN context
      --  Min_Ada.Min_Init_Context (Context => Context);
      --  My_Min_Ada.Override_Min_Application_Handler; --  We must override the handler

      S_Port.Open (Name => S_Port_Name);

      S_Port.Set (Rate         => B115200,
                  Bits         => CS8,
                  Stop_Bits    => One,
                  Parity       => None,
                  Flow         => None);

      --  Convert message (String -> Stream_Element_Array)
      for K in Data'Range loop
         --  Put_Line(K'Image & ": Character '" & Data (K) & "' with pos:" & Integer'Image (Character'Pos (Data (K))));
         Buffer (Stream_Element_Offset (K)) := Character'Pos (Data (K));
      end loop;

      S_Port.Write (Buffer => Buffer);
      Put_Line ("Sent message '" & Data & "' through serial connection.");

      New_Line;
      Put_Line("Waiting for reply from board...");

      declare
         Buffer_Rcv     : Stream_Element_Array (1 .. 1);
         Last_Rcv       : Stream_Element_Offset;
         Received_Char  : Character;

         Msg_Rcv        : String (1 .. Msg_Size);
         Msg_Length     : Integer := 0;
      begin
         Put("Receiving data...");
         Msg_Rcv := (others => ASCII.NUL); --  Init the Msg string to NUL characters
         loop
            S_Port.Read (Buffer   => Buffer_Rcv,
                         Last     => Last_Rcv);
            Received_Char := Character'Val (Buffer_Rcv (1));
            Msg_Length := Msg_Length + 1;
            Msg_Rcv (Msg_Length) := Received_Char;
            exit when Received_Char = ASCII.NUL;
            delay 2.0;
         end loop;
            Put_Line("Complete!");
            New_Line;
            Put_Line ("Length:" & Msg_Length'Image);
            Put_Line("Reply from board: " & Msg_Rcv);

            --  for K in 1 .. Last_Rcv loop
            --     Put(Character'Val (Buffer_Rcv (K)));
            --  end loop;
      end;
      
   exception
      when Serial_Error =>
         Put_Line ("Serial Error - Board not connected or serial connection already active");
   end;

   S_Port.Close;

end Min_Ada_Host;
