with GNAT.CRC32;
with Interfaces; use Interfaces;

package Min_Ada is

   type Bit     is mod 2**1     with Size => 1;
   type UInt4   is mod 2**4     with Size => 4;
   type Byte    is mod 2**8     with Size => 8;
   type UInt16  is mod 2**16    with Size => 16;
   type UInt32  is mod 2**32    with Size => 32;

   --  Enable or disable the Transport layer
   --  TRANSPORT_PROTOCOL : constant Boolean := True;

   MAX_PAYLOAD : constant Byte := 255;

   --  TRANSPORT_PROTOCOL start
      TRANSPORT_FIFO_SIZE_FRAMES_BITS     : constant := 4;
      TRANSPORT_FIFO_SIZE_FRAME_DATA_BITS : constant := 10;

      TRANSPORT_FIFO_MAX_FRAMES           : constant := 2**TRANSPORT_FIFO_SIZE_FRAMES_BITS;
      TRANSPORT_FIFO_MAX_FRAME_DATA       : constant := 2**TRANSPORT_FIFO_SIZE_FRAME_DATA_BITS;

      --  Transport Timeouts
      TRANSPOT_ACK_RETRANSMIT_TIMEOUT_MS     : constant := 25;
      TRANSPORT_FRAME_RETRANSMIT_TIMEOUT_MS  : constant := 50;
      TRANSPORT_MAX_WINDOW_SIZE              : constant := 16;
      TRANSPORT_IDLE_TIMEOUT_MS              : constant := 1000;

      -- Transport Bytes
      ACK_BYTE    : constant Byte := 16#FF#;
      RESET_BYTE  : constant Byte := 16#FE#;

      type Payloads_Ring is array (1 .. TRANSPORT_FIFO_MAX_FRAME_DATA) of Byte;
      Payloads_Ring_Buffer : Payloads_Ring;

      Now : UInt32;

      TRANSPORT_FIFO_SIZE_FRAMES_MASK : constant := Byte ((2**TRANSPORT_FIFO_SIZE_FRAMES_BITS) - 1);
   --  TRANSPORT_PROTOCOL end

   HEADER_BYTE : constant Byte := 16#AA#; --  hex of 170
   STUFF_BYTE  : constant Byte := 16#55#; --  hex of 85
   EOF_BYTE    : constant Byte := 16#55#; --  hex of 85

   --  TRANSPORT_PROTOCOL start
   type Transport_Frame is record

      --  ID of frame
      Min_Id            : Byte;

      --  Sequence number of frame
      Seq               : Byte;

      --  When frame was last sent (used for re-send timeouts)
      Last_Sent_Time_Ms : UInt32;

      --  Where in the ring buffer the payload is
      Payload_Offset    : UInt16;

      --  How big the payload is
      Payload_Length    : Byte;
      
   end record;

   type Transport_Frames_Array is array (1 .. TRANSPORT_FIFO_MAX_FRAMES) of Transport_Frame;

   type Transport_Fifo is record
      Frames: Transport_Frames_Array;

      Last_Sent_Ack_Time_Ms      : UInt32;
      Last_Received_Anything_Ms  : UInt32;
      Last_Received_Frame_Ms     : UInt32;

      --  Diagnostic counters (optional)
      Dropped_Frames             : UInt32;
      Spurious_Acks              : UInt32;
      Sequence_Mismatch_Drop     : UInt32;
      Resets_Received            : UInt32;

      --  Number of bytes used in the payload ring buffer
      N_Ring_Buffer_Bytes        : UInt16;

      --  Largest number of bytes ever used
      N_Ring_Buffer_Bytes_Max    : UInt16;

      --  Tail of the payload ring buffer
      Ring_Buffer_Tail_Offset    : UInt16;

      --  Number of frames in the FIFO
      N_Frames                   : Byte;

      --  Larger number of frames in the FIFO
      N_Frames_Max               : Byte;

      --  Where frames are taken from in the FIFO
      Head_Idx                   : Byte;                 

      --  Where new frames are added
      Tail_Idx                   : Byte;

      -- Sequence numbers for transport protocol
      Sn_Min                     : Byte;
      Sn_Max                     : Byte;
      Rn                         : Byte;
   end record;
   --  TRANSPORT_PROTOCOL end

   type Frame_State is (
      SEARCHING_FOR_SOF,
      RECEIVING_ID_CONTROL,
      RECEIVING_SEQ,
      RECEIVING_LENGTH,
      RECEIVING_PAYLOAD,
      RECEIVING_CHECKSUM_4,
      RECEIVING_CHECKSUM_3,
      RECEIVING_CHECKSUM_2,
      RECEIVING_CHECKSUM_1,
      RECEIVING_EOF
   );

   type App_ID is mod 2**6
      with Size => 6;

   type Frame_Header is record
      Header_1  : Byte;
      Header_2  : Byte;
      Header_3  : Byte;
      ID        : App_ID;
      Reserved  : Bit;
      Transport : Bit;
   end record with Size => 32;
   pragma Pack (Frame_Header);

   type Min_Payload is array (1 .. MAX_PAYLOAD) of Byte;

   type CRC_Bytes is array (1 .. 4) of Byte;

   type Min_Context is record

      --  TRANSPORT_PROTOCOL start
      --  T-MIN queue of outgoing frames
      Transport_Queue         : Transport_Fifo;
      --  TRANSPORT_PROTOCOL end

      --  Payload received so far
      Rx_Frame_Payload_Buffer  : Min_Payload;

      --  Checksum received over the wire
      Rx_Frame_Checksum        : CRC_Bytes;

      --  Calculated checksum for receiving frame
      Rx_Checksum              : GNAT.CRC32.CRC32;

      --  Calculated checksum for sending frame
      Tx_Checksum              : GNAT.CRC32.CRC32;

      --  Countdown of header bytes to reset state
      Rx_Header_Bytes_Seen     : Byte;

      --  State of receiver
      Rx_Frame_State           : Frame_State;

      --  Length of payload received so far
      Rx_Frame_Payload_Bytes   : Byte;

      --  ID and control bit of frame being received
      Rx_Frame_ID_Control      : Byte;

      --  Sequence number of frame being received
      Rx_Frame_Seq             : Byte;

      --  Length of frame
      Rx_Frame_Length          : Byte;

      --  Control byte
      Rx_Control               : Byte;

      --  Count out the header bytes
      Tx_Header_Byte_Countdown : Byte;

      --  Number of the port associated with the context
      Port                     : Byte;
   end record;

   --  Type for overriding Min_Application_Handler
   type Min_Application_Handler_Access is access
      procedure (
         ID             : App_ID;
         Payload        : Min_Payload;
         Payload_Length : Byte
      );

   --  Type for overriding Tx_Byte
   type Tx_Byte_Access is access
      procedure (
         Data : Byte
      );

   --  TRANSPORT_PROTOCOL start
   function Queue_Frame (
      Context        : in out Min_Context;
      ID             : App_ID;
      Payload        : Min_Payload;
      Payload_Length : Byte
   ) return Boolean;

   procedure Queue_Has_Space (
      Context        : in out Min_Context;
      Payload_Length : Byte
   );

   procedure Poll(
      Context        : in out Min_Context;
      Buffer         : out Min_Payload;
      Buffer_Length  : out Byte
   );

   --  function Time_Ms()

   --  TRANSPORT_PROTOCOL end

   procedure Send_Frame (
      Context        : in out Min_Context;
      ID             : App_ID;
      Payload        : Min_Payload;
      Payload_Length : Byte
   );

   procedure Rx_Bytes (
      Context : in out Min_Context;
      Data    : Byte
   );

   procedure Tx_Byte (
      Data : Byte
   );

   procedure Stuffed_Tx_Byte (
      Context : in out Min_Context;
      Data    : Byte;
      CRC     : Boolean
   );

   procedure Min_Init_Context (
      Context : in out Min_Context
   );

   procedure Valid_Frame_Received (
      Context : Min_Context
   );

   function MSB_Is_One (
      Data : Byte
   ) return Boolean;

   procedure Min_Application_Handler (
      ID             : App_ID;
      Payload        : Min_Payload;
      Payload_Length : Byte
   );
 
   procedure Set_Min_Application_Handler_Callback (
      Callback : Min_Application_Handler_Access
   );

   procedure Set_Tx_Byte_Callback (
      Callback : Tx_Byte_Access
   );

end Min_Ada;
