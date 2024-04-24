with Ada.Text_IO; use Ada.Text_IO;
--  with Interfaces;  use Interfaces;

package body Min_Ada is

   --  Used to store the overridden procedures
   Min_Application_Handler_Callback : Min_Application_Handler_Access;
   Tx_Byte_Callback                 : Tx_Byte_Access;

   procedure Send_Frame (
      Context           : in out Min_Context;
      ID                : App_ID;
      Payload           : Min_Payload;
      Payload_Length    : Byte
   ) is
      Checksum          : Interfaces.Unsigned_32;
      Checksum_Bytes    : CRC_Bytes with Address => Checksum'Address;
      ID_Control        : Byte with Address => Header.ID'Address;
      Header            : Frame_Header :=
                           (
                              Header_1  => HEADER_BYTE,
                              Header_2  => HEADER_BYTE,
                              Header_3  => HEADER_BYTE,
                              ID        => ID,
                              Reserved  => 0,
                              Transport => 0
                           );
   begin
      Context.Tx_Header_Byte_Countdown := 2;
      GNAT.CRC32.Initialize (Context.Tx_Checksum);

      Tx_Byte (
         Data => Header.Header_1
      );
      Tx_Byte (
         Data => Header.Header_2
      );
      Tx_Byte (
         Data => Header.Header_3
      );

      --  Send App ID, reserved bit, transport bit (together as one byte)
      Stuffed_Tx_Byte (Context, ID_Control, True);

      Stuffed_Tx_Byte (Context, Payload_Length, True);

      for P in 1 .. Payload_Length loop
         Stuffed_Tx_Byte (Context, Payload (P), True);
      end loop;

      Checksum := GNAT.CRC32.Get_Value (Context.Tx_Checksum);

      Stuffed_Tx_Byte (Context, Checksum_Bytes (4), False);
      Stuffed_Tx_Byte (Context, Checksum_Bytes (3), False);
      Stuffed_Tx_Byte (Context, Checksum_Bytes (2), False);
      Stuffed_Tx_Byte (Context, Checksum_Bytes (1), False);

      Tx_Byte (
         Data => EOF_BYTE
      );
   end Send_Frame;

   procedure Tx_Byte (
      Data : Byte
   ) is
   begin
      --  Allow for user to override
      if Tx_Byte_Callback /= null then
         Tx_Byte_Callback.all (
            Data => Data
         );
      else
         Put_Line ("Make sure to override Tx_Byte");
      end if;
   end Tx_Byte;

   procedure Rx_Bytes (
      Context : in out Min_Context;
      Data    : Byte
   ) is
      Real_Checksum  : Interfaces.Unsigned_32;
   begin
      if Context.Rx_Header_Bytes_Seen = 2 then
         Context.Rx_Header_Bytes_Seen := 0;

         if Data = HEADER_BYTE then
            Context.Rx_Frame_State := RECEIVING_ID_CONTROL;
            return;

         elsif Data = STUFF_BYTE then
            --  Discard byte and carry on receiving the next character
            return;
         else
            --  Something has gone wrong. Give up on frame and look for header
            Context.Rx_Frame_State := SEARCHING_FOR_SOF;
            return;
         end if;
      end if;

      if Data = HEADER_BYTE then
         Context.Rx_Header_Bytes_Seen := Context.Rx_Header_Bytes_Seen + 1;
      else
         Context.Rx_Header_Bytes_Seen := 0;
      end if;

      case Context.Rx_Frame_State is
         when SEARCHING_FOR_SOF =>
            null;

         when RECEIVING_ID_CONTROL =>
            Context.Rx_Frame_ID_Control    := Data;
            Context.Rx_Frame_Payload_Bytes := 0;
            GNAT.CRC32.Initialize (Context.Rx_Checksum);
            GNAT.CRC32.Update (Context.Rx_Checksum, Character'Val (Data));

            if MSB_Is_One (
               Data => Data
            )
            then
               Context.Rx_Frame_State := SEARCHING_FOR_SOF;
            else
               Context.Rx_Frame_Seq   := 0;
               Context.Rx_Frame_State := RECEIVING_LENGTH;
            end if;

         when RECEIVING_SEQ =>
            Context.Rx_Frame_Seq := Data;
            GNAT.CRC32.Update (Context.Rx_Checksum, Character'Val (Data));
            Context.Rx_Frame_State := RECEIVING_LENGTH;

         when RECEIVING_LENGTH =>
            Context.Rx_Frame_Length := Data;
            Context.Rx_Control      := Data;
            GNAT.CRC32.Update (Context.Rx_Checksum, Character'Val (Data));

            if Context.Rx_Frame_Length > 0 then
               Context.Rx_Frame_State := RECEIVING_PAYLOAD;
            else
               Context.Rx_Frame_State := RECEIVING_CHECKSUM_4;
            end if;

         when RECEIVING_PAYLOAD =>
            Context.Rx_Frame_Payload_Buffer
               (Context.Rx_Frame_Payload_Bytes + 1) := Data;
            Context.Rx_Frame_Payload_Bytes :=
               Context.Rx_Frame_Payload_Bytes + 1;
            GNAT.CRC32.Update (Context.Rx_Checksum, Character'Val (Data));
            Context.Rx_Frame_Length :=
               Context.Rx_Frame_Length - 1;
            if Context.Rx_Frame_Length = 0 then
               Context.Rx_Frame_State := RECEIVING_CHECKSUM_4;
            end if;

         when RECEIVING_CHECKSUM_4 =>
            Context.Rx_Frame_Checksum (4) := Data;
            Context.Rx_Frame_State        := RECEIVING_CHECKSUM_3;

         when RECEIVING_CHECKSUM_3 =>
            Context.Rx_Frame_Checksum (3) := Data;
            Context.Rx_Frame_State        := RECEIVING_CHECKSUM_2;

         when RECEIVING_CHECKSUM_2 =>
            Context.Rx_Frame_Checksum (2) := Data;
            Context.Rx_Frame_State        := RECEIVING_CHECKSUM_1;

         when RECEIVING_CHECKSUM_1 =>
            Context.Rx_Frame_Checksum (1) := Data;

            Real_Checksum := GNAT.CRC32.Get_Value (Context.Rx_Checksum);
            declare
               Checksum_Bytes : CRC_Bytes with Address => Real_Checksum'Address;
            begin
               if Context.Rx_Frame_Checksum /= Checksum_Bytes then
                  --  Frame fails the checksum and is dropped
                  Context.Rx_Frame_State := SEARCHING_FOR_SOF;
                  Put_Line ("Frame dropped!");
               else
                  Context.Rx_Frame_State := RECEIVING_EOF;
               end if;
            end;

         when RECEIVING_EOF =>
            if Data = EOF_BYTE then
               --  Frame received OK, pass up data to handler
               Valid_Frame_Received (Context);
            end if;
            --  Look for next frame
            Context.Rx_Frame_State := SEARCHING_FOR_SOF;
      end case;

   end Rx_Bytes;

   procedure Valid_Frame_Received (
      Context : Min_Context
   ) is
   begin
      --  TODO: implement transport functionality
      Min_Application_Handler (
         ID             => App_ID (Context.Rx_Frame_ID_Control),
         Payload        => Context.Rx_Frame_Payload_Buffer,
         Payload_Length => Context.Rx_Frame_Payload_Bytes
      );
   end Valid_Frame_Received;

   procedure Stuffed_Tx_Byte (
      Context : in out Min_Context;
      Data    : Byte;
      CRC     : Boolean
   ) is
   begin
      Tx_Byte (
         Data => Data
      );
      if CRC then
         GNAT.CRC32.Update (Context.Tx_Checksum, Character'Val (Data));
      end if;

      if Data = HEADER_BYTE then
         Context.Tx_Header_Byte_Countdown :=
            Context.Tx_Header_Byte_Countdown - 1;

         if Context.Tx_Header_Byte_Countdown = 0 then
            Tx_Byte (
               Data => STUFF_BYTE
            );
            Context.Tx_Header_Byte_Countdown := 2;
         end if;
      else
         Context.Tx_Header_Byte_Countdown := 2;
      end if;

   end Stuffed_Tx_Byte;

   procedure Min_Init_Context (
      Context : in out Min_Context
   ) is
   begin
      Context.Rx_Header_Bytes_Seen := 0;
      Context.Rx_Frame_State := SEARCHING_FOR_SOF;
   end Min_Init_Context;

   function MSB_Is_One (
      Data : Byte
   ) return Boolean is
      MSB : Interfaces.Unsigned_8;
   begin
      MSB := Interfaces.Shift_Right (
         Value  => Interfaces.Unsigned_8 (Data),
         Amount => 7
      );
      if MSB = 1 then
         return True;
      else
         return False;
      end if;
   end MSB_Is_One;

   --  To override Min_Application_Handler
   procedure Set_Min_Application_Handler_Callback (
      Callback : Min_Application_Handler_Access
   ) is
   begin
      Min_Application_Handler_Callback := Callback;
   end Set_Min_Application_Handler_Callback;

   --  To override Tx_Byte
   procedure Set_Tx_Byte_Callback (
      Callback : Tx_Byte_Access
   ) is
   begin
      Tx_Byte_Callback := Callback;
   end Set_Tx_Byte_Callback;

   procedure Min_Application_Handler (
      ID             : App_ID;
      Payload        : Min_Payload;
      Payload_Length : Byte
   ) is
   begin
      --  Allow for user to override
      if Min_Application_Handler_Callback /= null then
         Min_Application_Handler_Callback.all (
            ID             => ID,
            Payload        => Payload,
            Payload_Length => Payload_Length
         );
      else
         Put_Line ("Make sure to override Min_Application_Handler");
      end if;
   end Min_Application_Handler;

   --  TRANSPORT LAYER START  --

   -- Claim a buffer slot from the FIFO. Returns 0 if there is no space.
   function Transport_Fifo_Push(
      Context     : access Min_Context;
      Data_Size   : UInt16
   ) return access Transport_Frame is
      Queue       : Transport_Fifo with Address => Context.Transport_Queue'Address;
      Ret         : access Transport_Frame := null;
   begin
      -- A frame is only queued if there aren't too many frames in the FIFO and there is space in the
      -- data ring buffer.
      if Queue.N_Frames < TRANSPORT_FIFO_MAX_FRAMES then
         -- Is there space in the ring buffer for the frame payload?
         if Queue.N_Ring_Buffer_Bytes <= TRANSPORT_FIFO_MAX_FRAME_DATA - Data_Size then
            Queue.N_Frames := Queue.N_Frames + 1;
            if Queue.N_Frames > Queue.N_Frames_Max then
               -- High-water mark of FIFO (for diagnostic purposes)
               Queue.N_Frames_Max := Queue.N_Frames;
            end if;
            -- Create FIFO entry
            Ret := Queue.Frames (Integer (Queue.Tail_Idx));
            Ret.Payload_Offset := Queue.Ring_Buffer_Tail_Offset;

            -- Claim ring buffer space
            Queue.N_Ring_Buffer_Bytes := Queue.N_Ring_Buffer_Bytes + Data_Size;
            if Queue.N_Ring_Buffer_Bytes > Queue.N_Ring_Buffer_Bytes_Max then
               -- High-water mark of ring buffer usage (for diagnostic purposes)
               Queue.N_Ring_Buffer_Bytes_Max := Queue.N_Ring_Buffer_Bytes;
            end if;
            Queue.Ring_Buffer_Tail_Offset := Queue.Ring_Buffer_Tail_Offset + Data_Size;
            Queue.Ring_Buffer_Tail_Offset := Queue.Ring_Buffer_Tail_Offset and TRANSPORT_FIFO_SIZE_FRAMES_MASK;

            -- Claim FIFO space
            Queue.Tail_Idx := Queue.Tail_Idx + 1;
            Queue.Tail_Idx := Queue.Tail_Idx and TRANSPORT_FIFO_SIZE_FRAMES_MASK;
         end if;
      end if;

      return Ret;
   end Transport_Fifo_Push;


   procedure Transport_Fifo_Pop (
      Context  : in out Min_Context
   ) is
      Queue    : Transport_Fifo with Address => Context.Transport_Queue'Address;
      Frame    : Transport_Frame with Address => Queue.Frames (Integer (Queue.Head_Idx))'Address;
   begin
      Queue.N_Frames := Queue.N_Frames - 1;
      Queue.Head_Idx :=  (Queue.Head_Idx + 1) and TRANSPORT_FIFO_SIZE_FRAMES_MASK;
      Queue.N_Ring_Buffer_Bytes := Queue.N_Ring_Buffer_Bytes - UInt16 (Frame.Payload_Length);
   end Transport_Fifo_Pop;

   function Transport_Fifo_Get (
      Context  : in out Min_Context;
      N        : Byte
   ) return Transport_Frame is
      Queue    : Transport_Fifo with Address => Context.Transport_Queue'Address;
      Idx      : constant Byte := Queue.Head_Idx;
   begin
      return Queue.Frames (Integer ((Idx + N) and TRANSPORT_FIFO_SIZE_FRAMES_MASK)); --  FIXME
   end Transport_Fifo_Get;

   procedure Transport_Fifo_Reset (
      Context  : in out Min_Context
   ) is
      Queue    : Transport_Fifo with Address => Context.Transport_Queue'Address;
   begin
      --  Clear down the transmission FIFO queue
      Queue.N_Frames := 0;
      Queue.Head_Idx := 0;
      Queue.Tail_Idx := 0;
      Queue.N_Ring_Buffer_Bytes := 0;
      Queue.Ring_Buffer_Tail_Offset := 0;
      Queue.Sn_Max := 0;
      Queue.Sn_Min := 0;
      Queue.Rn := 0;

      --  Reset the timers
      Queue.Last_Received_Anything_Ms := Now;
      Queue.Last_Sent_Ack_Time_Ms := Now;
      Queue.Last_Received_Frame_Ms := 0;
   end Transport_Fifo_Reset;

   procedure Send_Ack (
      Context : in out Min_Context
   ) is
   begin
      --  In the embedded end we don't reassemble out-of-order frames and so never ask for retransmits. Payload is
      --  always the same as the sequence number.

      --  if (ON_WIRE_SIZE(0) <= min_tx_space(self->port)) {
      --    on_wire_bytes(self, ACK, self->transport_fifo.rn, &self->transport_fifo.rn, 0, 0xffU, 1U);
      --    self->transport_fifo.last_sent_ack_time_ms = now;
      --  }
      null;
   end Send_Ack;

   procedure Send_Reset (
      Context : in out Min_Context
   ) is
   begin
      null; --  TODO
   end Send_Reset;

   procedure Transport_Reset (
      Context           : in out Min_Context;
      Inform_Other_Side : Boolean
   ) is
   begin
      if Inform_Other_Side then
         --  Tell the other end we have gone away
        Send_Reset (Context => Context);
      end if;

      -- Throw our frames away
      Transport_Fifo_Reset (Context => Context);
   end Transport_Reset;

   function Queue_Frame (
      Context        : in out Min_Context;
      ID             : App_ID;
      Payload        : Min_Payload;
      Payload_Length : Byte
   ) return Boolean is
      Frame       : access Transport_Frame := null;
      Offset      : UInt16;
   begin
      --  Claim a FIFO slot, reserve space for payload
      Frame := Transport_Fifo_Push(Context => Context, Data_Size => UInt16 (Payload_Length));

      --  We are just queueing here: the poll() function puts the frame into the window and on to the wire
      if Frame = null then --  TODO: check this logic
         Context.Transport_Queue.Dropped_Frames := Context.Transport_Queue.Dropped_Frames + 1;
         return False;
      else
         Frame := Context.Transport_Queue.Frames (Frame_Idx);  --  FIXME: This is entirely wrong

         --  Copy frame details into frame slot, copy payload into ring buffer
         Frame.Min_Id := Byte (ID and 16#3F#);
         Frame.Payload_Length := Payload_Length;

         Offset := Frame.Payload_Offset;
         For I in 1 .. Payload_Length loop
               Payloads_Ring_Buffer (Integer (Offset)) := Payload (I);
               Offset := UInt16 ((Offset + 1) and TRANSPORT_FIFO_SIZE_FRAMES_MASK);
         end loop;

         return True;
      end if;
   end Queue_Frame;

   procedure Queue_Has_Space (
      Context        : in out Min_Context;
      Payload_Length : Byte
   ) is
   begin
      null;
   end Queue_Has_Space;

   procedure Poll(
      Context        : in out Min_Context;
      Buffer         : out Min_Payload;
      Buffer_Length  : out Byte
   ) is
   begin
      null;
   end Poll;

end Min_Ada;
