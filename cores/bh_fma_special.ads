with Interfaces; use Interfaces;
package Bh_Fma_Special with SPARK_Mode is
   subtype Bits32 is Interfaces.Unsigned_32;

   function Exp_Field (Bits : Bits32) return Bits32 is (Shift_Right (Bits, 23) and 255)
     with Post => Exp_Field'Result <= 255;

   function Mant_Field (Bits : Bits32) return Bits32 is (if Exp_Field (Bits) = 0 then 0 else ((Bits and 16#7FFFFF#) xor 16#800000#))
     with Post => Mant_Field'Result <= 16#FFFFFF#;

   function Sign_Bit (Bits : Bits32) return Bits32 is (Bits and 16#80000000#)
     with Post => Sign_Bit'Result = 0 or else Sign_Bit'Result = 16#80000000#;

   function Product_Sign (X : Bits32; Y : Bits32) return Bits32 is (Sign_Bit (X xor Y))
     with Post => Product_Sign'Result = 0 or else Product_Sign'Result = 16#80000000#;

   function Product_Exponent (X : Bits32; Y : Bits32) return Integer is (Integer (Exp_Field (X)) + Integer (Exp_Field (Y)) - 127)
     with Post => Product_Exponent'Result in -127 .. 383;

   function Is_Special (X : Bits32; Y : Bits32; Z : Bits32) return Boolean is (Exp_Field (X) = 255 or else Exp_Field (Y) = 255
       or else Product_Exponent (X, Y) >= 255 or else Exp_Field (Z) = 255);

   function Is_Nan_Result (X : Bits32; Y : Bits32; Z : Bits32) return Boolean is ((Exp_Field (X) = 255 and then (Mant_Field (X) /= 16#800000# or else Mant_Field (Y) = 0))
       or else (Exp_Field (Y) = 255 and then (Mant_Field (Y) /= 16#800000# or else Mant_Field (X) = 0))
       or else (Exp_Field (Z) = 255 and then Mant_Field (Z) /= 16#800000#)
       or else (Exp_Field (Z) = 255 and then (Exp_Field (X) = 255 or else Exp_Field (Y) = 255)
                and then Sign_Bit (Z) /= Product_Sign (X, Y)));

   function Special_Result (X : Bits32; Y : Bits32; Z : Bits32) return Bits32 is (if Is_Nan_Result (X, Y, Z) then 16#7FC00000#
       elsif Exp_Field (Z) = 255 then Z
       else (Product_Sign (X, Y) or 16#7F800000#))
     with Pre  => Is_Special (X, Y, Z),
          Post => Exp_Field (Special_Result'Result) = 255;

end Bh_Fma_Special;