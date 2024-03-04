with Ada.Text_IO;    use Ada.Text_IO;

with GNAT.Serial_Communications;
with Uart;

with Gtk.Main, Gtk.Window;

procedure Min_Ada_Host is
   Window            : Gtk.Window.Gtk_Window;

   Is_Connected      : Boolean; -- Board connection status
   Serial_Port       : GNAT.Serial_Communications.Serial_Port;
   Port_Location     : constant
                        GNAT.Serial_Communications.Port_Name :=
                        "/dev/cu.usbmodem103"; -- This will vary per system

   --UART_obj          : Uart.Read;

   task Connect_Board;

   task body Connect_Board is
   begin
      Is_Connected := True;

      declare
      begin
         GNAT.Serial_Communications.Open
            (Port => Serial_Port,
            Name => Port_Location);

         GNAT.Serial_Communications.Set
            (Port => Serial_Port,
            Rate => GNAT.Serial_Communications.B921600);
      exception
         when GNAT.Serial_Communications.Serial_Error =>
            Put_Line("Serial Error - Board not connected");
            Is_Connected := False;
      end;

      If Is_Connected = True then
         --UART_obj.Start;
         Put_Line("Board connected! The program will end in 5 seconds.");
         delay 5.0;
         --UART_obj.Stop;
         GNAT.Serial_Communications.Close(Serial_Port);
         Put_Line("Disconnected!");
      end if;

      delay 1.0;
      Gtk.Main.Main_Quit;
   end Connect_Board;
begin
   Gtk.Main.Init;
   Gtk.Window.Gtk_New (Window);
   Window.Set_Default_Size (1200, 600);
   Gtk.Window.Show (Window);
   Gtk.Main.Main;
end Min_Ada_Host;
