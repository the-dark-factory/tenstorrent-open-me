with Interfaces; use Interfaces;
package Board_Type_Decode with SPARK_Mode is
   subtype Serial64 is Interfaces.Unsigned_64;

   type Board_Type is
     (Board_E150, Board_E300, Board_E75, Board_Nb_Cb, Board_Wh_4u,
      Board_N300, Board_N150, Board_Galaxy_Wh, Board_Bh_Scrappy,
      Board_P100a, Board_P150a, Board_P150b, Board_P150c, Board_P300b,
      Board_P300a, Board_P300c, Board_Galaxy_Bh, Board_Unknown);

   function Extract_Upi (Serial : Serial64) return Serial64
     with Post => Extract_Upi'Result <= 16#FFFFF#;

   function Decode_Board_Type (Serial : Serial64) return Board_Type
     with Post => Decode_Board_Type'Result =
       (case Extract_Upi (Serial) is
          when 16#3#          => Board_E150,
          when 16#A#          => Board_E300,
          when 16#7#          => Board_E75,
          when 16#8#          => Board_Nb_Cb,
          when 16#B#          => Board_Wh_4u,
          when 16#14#         => Board_N300,
          when 16#18#         => Board_N150,
          when 16#35#         => Board_Galaxy_Wh,
          when 16#36#         => Board_Bh_Scrappy,
          when 16#43#         => Board_P100a,
          when 16#40#         => Board_P150a,
          when 16#41#         => Board_P150b,
          when 16#42#         => Board_P150c,
          when 16#44#         => Board_P300b,
          when 16#45#         => Board_P300a,
          when 16#46#         => Board_P300c,
          when 16#47# | 16#202# => Board_Galaxy_Bh,
          when others         => Board_Unknown);

end Board_Type_Decode;