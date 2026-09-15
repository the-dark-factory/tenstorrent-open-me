with Interfaces; use Interfaces;
package Bh_Fma_Normalize_Round with SPARK_Mode is
   subtype Bits32 is Interfaces.Unsigned_32;

   function Msb_Index (V : Bits32) return Natural is (if    Shift_Right (V, 31) /= 0 then 31
       elsif Shift_Right (V, 30) /= 0 then 30
       elsif Shift_Right (V, 29) /= 0 then 29
       elsif Shift_Right (V, 28) /= 0 then 28
       elsif Shift_Right (V, 27) /= 0 then 27
       elsif Shift_Right (V, 26) /= 0 then 26
       elsif Shift_Right (V, 25) /= 0 then 25
       elsif Shift_Right (V, 24) /= 0 then 24
       elsif Shift_Right (V, 23) /= 0 then 23
       elsif Shift_Right (V, 22) /= 0 then 22
       elsif Shift_Right (V, 21) /= 0 then 21
       elsif Shift_Right (V, 20) /= 0 then 20
       elsif Shift_Right (V, 19) /= 0 then 19
       elsif Shift_Right (V, 18) /= 0 then 18
       elsif Shift_Right (V, 17) /= 0 then 17
       elsif Shift_Right (V, 16) /= 0 then 16
       elsif Shift_Right (V, 15) /= 0 then 15
       elsif Shift_Right (V, 14) /= 0 then 14
       elsif Shift_Right (V, 13) /= 0 then 13
       elsif Shift_Right (V, 12) /= 0 then 12
       elsif Shift_Right (V, 11) /= 0 then 11
       elsif Shift_Right (V, 10) /= 0 then 10
       elsif Shift_Right (V, 9) /= 0 then 9
       elsif Shift_Right (V, 8) /= 0 then 8
       elsif Shift_Right (V, 7) /= 0 then 7
       elsif Shift_Right (V, 6) /= 0 then 6
       elsif Shift_Right (V, 5) /= 0 then 5
       elsif Shift_Right (V, 4) /= 0 then 4
       elsif Shift_Right (V, 3) /= 0 then 3
       elsif Shift_Right (V, 2) /= 0 then 2
       elsif Shift_Right (V, 1) /= 0 then 1
       else 0)
   with Pre  => V /= 0,
        Post => Msb_Index'Result <= 31
                and then Shift_Right (V, Msb_Index'Result) = 1;

   function Lzc32 (V : Bits32) return Natural is (31 - Msb_Index (V))
   with Pre  => V /= 0,
        Post => Lzc32'Result <= 31;

   function Norm_Shift (R_M : Bits32) return Integer is (5 - Lzc32 (R_M))
   with Pre  => R_M /= 0,
        Post => Norm_Shift'Result in -26 .. 5;

   function Norm_Exponent (R_M : Bits32; R_E : Integer) return Integer is (R_E + Norm_Shift (R_M))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254,
        Post => Norm_Exponent'Result in -26 .. 259;

   function Is_Overflow (R_M : Bits32; R_E : Integer) return Boolean is (Norm_Exponent (R_M, R_E) >= 255)
   with Pre => R_M /= 0 and then R_E in 0 .. 254;

   function Final_Exponent (R_M : Bits32; R_E : Integer) return Integer is (if Norm_Exponent (R_M, R_E) <= 0 then 0 else Norm_Exponent (R_M, R_E))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
        Post => Final_Exponent'Result in 0 .. 254;

   function Final_Shift (R_M : Bits32; R_E : Integer) return Integer is (if Norm_Exponent (R_M, R_E) <= 0 then Norm_Shift (R_M) + 1 else Norm_Shift (R_M))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254,
        Post => Final_Shift'Result in -26 .. 5;

   function Shifted_Mantissa (R_M : Bits32; R_E : Integer) return Bits32 is (if Final_Shift (R_M, R_E) <= 0
       then Shift_Left (R_M, -Final_Shift (R_M, R_E))
       else (Shift_Right (R_M, Final_Shift (R_M, R_E))
             or (if (R_M and (Bits32 (Final_Shift (R_M, R_E)) or 1)) /= 0 then 1 else 0)))
   with Pre => R_M /= 0 and then R_E in 0 .. 254;

   function Assembled (R_M : Bits32; R_E : Integer) return Bits32 is (Shift_Left (Bits32 (Final_Exponent (R_M, R_E)), 23)
       + (Shift_Right (Shifted_Mantissa (R_M, R_E), 3) and 16#7FFFFF#))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
        Post => Assembled'Result <= 16#7F7FFFFF#;

   function Rounded (R_M : Bits32; R_E : Integer) return Bits32 is (Assembled (R_M, R_E)
       + (if ((Shifted_Mantissa (R_M, R_E) and 7) + (Assembled (R_M, R_E) and 1)) > 4 then 1 else 0))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
        Post => Rounded'Result <= 16#7F800000#;

   function Flushed (R_M : Bits32; R_E : Integer) return Bits32 is (if Shift_Right (Rounded (R_M, R_E), 23) = 0 then 0 else Rounded (R_M, R_E))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
        Post => Flushed'Result <= 16#7F800000#
                and then (Flushed'Result = 0 or else Shift_Right (Flushed'Result, 23) /= 0);

   function Normalize_Round (R_M : Bits32; R_E : Integer; R_Sign : Bits32) return Bits32 is (if Is_Overflow (R_M, R_E) then (R_Sign or 16#7F800000#)
       else (R_Sign or Flushed (R_M, R_E)))
   with Pre  => R_M /= 0 and then R_E in 0 .. 254
                and then (R_Sign = 0 or else R_Sign = 16#80000000#),
        Post => (Normalize_Round'Result and 16#80000000#) = R_Sign
                and then ((Shift_Right (Normalize_Round'Result, 23) and 255) /= 0
                          or else (Normalize_Round'Result and 16#7FFFFFFF#) = 0);

end Bh_Fma_Normalize_Round;