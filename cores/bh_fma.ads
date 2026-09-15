with Interfaces; use Interfaces;
package Bh_Fma with SPARK_Mode is
  subtype Bits32 is Interfaces.Unsigned_32;
  subtype Bits64 is Interfaces.Unsigned_64;

  function Exp_Field (Bits : Bits32) return Bits32
    is (Shift_Right (Bits, 23) and 255)
    with Post => Exp_Field'Result <= 255;

  function Mant_Field (Bits : Bits32) return Bits32
    is (if Exp_Field (Bits) = 0 then 0 else ((Bits and 16#7FFFFF#) xor 16#800000#))
    with Post => Mant_Field'Result <= 16#FFFFFF#;

  function Sign_Bit (Bits : Bits32) return Bits32
    is (Bits and 16#80000000#)
    with Post => Sign_Bit'Result = 0 or else Sign_Bit'Result = 16#80000000#;

  function Product_Sign (X : Bits32; Y : Bits32) return Bits32
    is (Sign_Bit (X xor Y))
    with Post => Product_Sign'Result = 0 or else Product_Sign'Result = 16#80000000#;

  function Product_Exponent (X : Bits32; Y : Bits32) return Integer
    is (Integer (Exp_Field (X)) + Integer (Exp_Field (Y)) - 127)
    with Post => Product_Exponent'Result in -127 .. 383;

  function Is_Special (X : Bits32; Y : Bits32; Z : Bits32) return Boolean
    is (Exp_Field (X) = 255 or else Exp_Field (Y) = 255
        or else Product_Exponent (X, Y) >= 255 or else Exp_Field (Z) = 255);

  function Is_Nan_Result (X : Bits32; Y : Bits32; Z : Bits32) return Boolean
    is ((Exp_Field (X) = 255 and then (Mant_Field (X) /= 16#800000# or else Mant_Field (Y) = 0))
        or else (Exp_Field (Y) = 255 and then (Mant_Field (Y) /= 16#800000# or else Mant_Field (X) = 0))
        or else (Exp_Field (Z) = 255 and then Mant_Field (Z) /= 16#800000#)
        or else (Exp_Field (Z) = 255 and then (Exp_Field (X) = 255 or else Exp_Field (Y) = 255)
                 and then Sign_Bit (Z) /= Product_Sign (X, Y)));

  function Special_Result (X : Bits32; Y : Bits32; Z : Bits32) return Bits32
    is (if Is_Nan_Result (X, Y, Z) then 16#7FC00000#
        elsif Exp_Field (Z) = 255 then Z
        else (Product_Sign (X, Y) or 16#7F800000#))
    with Pre  => Is_Special (X, Y, Z),
         Post => Exp_Field (Special_Result'Result) = 255;

  function Product_Mantissa (X : Bits32; Y : Bits32) return Bits64
    is (Shift_Right (Shift_Left (Bits64 (Mant_Field (X)) * Bits64 (Mant_Field (Y)), 3), 23)
        or (if (Shift_Left (Bits64 (Mant_Field (X)) * Bits64 (Mant_Field (Y)), 3) and 16#7FFFFF#) /= 0
            then 1 else 0));

  function Addend_Mantissa (Z : Bits32) return Bits32
    is (Shift_Left (Mant_Field (Z), 3));

  function Is_Early_Zero (X : Bits32; Y : Bits32) return Boolean
    is (Product_Mantissa (X, Y) = 0 or else Product_Exponent (X, Y) < 0);

  function Early_Result (X : Bits32; Y : Bits32; Z : Bits32) return Bits32
    is (if Addend_Mantissa (Z) /= 0 then Z else (Sign_Bit (Z) and Product_Sign (X, Y)));

  function Semi_Sticky_Shift64 (Var : Bits64; Amount : Natural) return Bits64
    is (if Amount >= 64 then 0
        elsif Shift_Right (Var, Amount) = 0 then 0
        elsif Shift_Left (Shift_Right (Var, Amount), Amount) = Var then Shift_Right (Var, Amount)
        else (Shift_Right (Var, Amount) or 1));

  function Semi_Sticky_Shift32 (Var : Bits32; Amount : Natural) return Bits32
    is (if Amount >= 32 then 0
        elsif Shift_Right (Var, Amount) = 0 then 0
        elsif Shift_Left (Shift_Right (Var, Amount), Amount) = Var then Shift_Right (Var, Amount)
        else (Shift_Right (Var, Amount) or 1));

  function Sum_Exponent (P_E : Integer; Z_E : Integer) return Integer
    is (if P_E > Z_E then P_E else Z_E)
    with Pre  => P_E in 0 .. 254 and then Z_E in 0 .. 254,
         Post => Sum_Exponent'Result in 0 .. 254
                 and then Sum_Exponent'Result >= P_E
                 and then Sum_Exponent'Result >= Z_E;

  function Aligned_P (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits64
    is (if P_E < Sum_Exponent (P_E, Z_E)
        then Semi_Sticky_Shift64 (P_M, Sum_Exponent (P_E, Z_E) - P_E)
        else P_M)
    with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

  function Aligned_Z (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32
    is (if Z_E < Sum_Exponent (P_E, Z_E)
        then Semi_Sticky_Shift32 (Z_M, Sum_Exponent (P_E, Z_E) - Z_E)
        else Z_M)
    with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

  function Sum_Sign (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32
    is (if Aligned_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
          >= Bits64 (Aligned_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
       then P_Sign else Z_Sign)
    with Pre  => P_E in 0 .. 254 and then Z_E in 0 .. 254,
         Post => Sum_Sign'Result = P_Sign or else Sum_Sign'Result = Z_Sign;

  function Signed_Z (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32
    is (if Z_Sign /= Sum_Sign (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
        then not Aligned_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
        else Aligned_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
    with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

  function Signed_P (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits64
    is (if P_Sign /= Sum_Sign (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
        then not Aligned_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
        else Aligned_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
    with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

  function Sum_Mantissa (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32
    is (Bits32 ((Bits64 (Signed_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
                 + Signed_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
                 + (if P_Sign /= Z_Sign then 1 else 0))
                and 16#FFFFFFFF#))
    with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

  function Msb_Index (V : Bits32) return Natural
    is (if    Shift_Right (V, 31) /= 0 then 31
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

  function Lzc32 (V : Bits32) return Natural
    is (31 - Msb_Index (V))
    with Pre  => V /= 0,
         Post => Lzc32'Result <= 31;

  function Norm_Shift (R_M : Bits32) return Integer
    is (5 - Lzc32 (R_M))
    with Pre  => R_M /= 0,
         Post => Norm_Shift'Result in -26 .. 5;

  function Norm_Exponent (R_M : Bits32; R_E : Integer) return Integer
    is (R_E + Norm_Shift (R_M))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254,
         Post => Norm_Exponent'Result in -26 .. 259;

  function Is_Overflow (R_M : Bits32; R_E : Integer) return Boolean
    is (Norm_Exponent (R_M, R_E) >= 255)
    with Pre => R_M /= 0 and then R_E in 0 .. 254;

  function Final_Exponent (R_M : Bits32; R_E : Integer) return Integer
    is (if Norm_Exponent (R_M, R_E) <= 0 then 0 else Norm_Exponent (R_M, R_E))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
         Post => Final_Exponent'Result in 0 .. 254;

  function Final_Shift (R_M : Bits32; R_E : Integer) return Integer
    is (if Norm_Exponent (R_M, R_E) <= 0 then Norm_Shift (R_M) + 1 else Norm_Shift (R_M))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254,
         Post => Final_Shift'Result in -26 .. 5;

  function Shifted_Mantissa (R_M : Bits32; R_E : Integer) return Bits32
    is (if Final_Shift (R_M, R_E) <= 0
        then Shift_Left (R_M, -Final_Shift (R_M, R_E))
        else (Shift_Right (R_M, Final_Shift (R_M, R_E))
              or (if (R_M and (Bits32 (Final_Shift (R_M, R_E)) or 1)) /= 0 then 1 else 0)))
    with Pre => R_M /= 0 and then R_E in 0 .. 254;

  function Assembled (R_M : Bits32; R_E : Integer) return Bits32
    is (Shift_Left (Bits32 (Final_Exponent (R_M, R_E)), 23)
        + (Shift_Right (Shifted_Mantissa (R_M, R_E), 3) and 16#7FFFFF#))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
         Post => Assembled'Result <= 16#7F7FFFFF#;

  function Rounded (R_M : Bits32; R_E : Integer) return Bits32
    is (Assembled (R_M, R_E)
        + (if ((Shifted_Mantissa (R_M, R_E) and 7) + (Assembled (R_M, R_E) and 1)) > 4 then 1 else 0))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
         Post => Rounded'Result <= 16#7F800000#;

  function Flushed (R_M : Bits32; R_E : Integer) return Bits32
    is (if Shift_Right (Rounded (R_M, R_E), 23) = 0 then 0 else Rounded (R_M, R_E))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254 and then not Is_Overflow (R_M, R_E),
         Post => Flushed'Result <= 16#7F800000#
                 and then (Flushed'Result = 0 or else Shift_Right (Flushed'Result, 23) /= 0);

  function Normalize_Round (R_M : Bits32; R_E : Integer; R_Sign : Bits32) return Bits32
    is (if Is_Overflow (R_M, R_E) then (R_Sign or 16#7F800000#)
        else (R_Sign or Flushed (R_M, R_E)))
    with Pre  => R_M /= 0 and then R_E in 0 .. 254
                 and then (R_Sign = 0 or else R_Sign = 16#80000000#),
         Post => (Normalize_Round'Result and 16#80000000#) = R_Sign
                 and then ((Shift_Right (Normalize_Round'Result, 23) and 255) /= 0
                           or else (Normalize_Round'Result and 16#7FFFFFFF#) = 0);

  function Sum_M (X : Bits32; Y : Bits32; Z : Bits32) return Bits32
    is (Sum_Mantissa (Product_Mantissa (X, Y), Product_Exponent (X, Y), Product_Sign (X, Y),
                      Addend_Mantissa (Z), Integer (Exp_Field (Z)), Sign_Bit (Z)))
    with Pre => not Is_Special (X, Y, Z) and then not Is_Early_Zero (X, Y);

  function Sum_E (X : Bits32; Y : Bits32; Z : Bits32) return Integer
    is (Sum_Exponent (Product_Exponent (X, Y), Integer (Exp_Field (Z))))
    with Pre  => not Is_Special (X, Y, Z) and then not Is_Early_Zero (X, Y),
         Post => Sum_E'Result in 0 .. 254;

  function Sum_S (X : Bits32; Y : Bits32; Z : Bits32) return Bits32
    is (Sum_Sign (Product_Mantissa (X, Y), Product_Exponent (X, Y), Product_Sign (X, Y),
                  Addend_Mantissa (Z), Integer (Exp_Field (Z)), Sign_Bit (Z)))
    with Pre  => not Is_Special (X, Y, Z) and then not Is_Early_Zero (X, Y),
         Post => Sum_S'Result = 0 or else Sum_S'Result = 16#80000000#;

  function Fma_Bh (X : Bits32; Y : Bits32; Z : Bits32) return Bits32
    is (if Is_Special (X, Y, Z) then Special_Result (X, Y, Z)
        elsif Is_Early_Zero (X, Y) then Early_Result (X, Y, Z)
        elsif Sum_M (X, Y, Z) = 0 then (Sign_Bit (Z) and Product_Sign (X, Y))
        else Normalize_Round (Sum_M (X, Y, Z), Sum_E (X, Y, Z), Sum_S (X, Y, Z)))
    with Post => (Exp_Field (Fma_Bh'Result) /= 0)
                 or else ((Fma_Bh'Result and 16#7FFFFFFF#) = 0);

end Bh_Fma;