with Interfaces; use Interfaces;
package Bh_Fma_Primitives with SPARK_Mode is
   subtype Bits32 is Interfaces.Unsigned_32;
   subtype Bits64 is Interfaces.Unsigned_64;

   function Exp_Field (Bits : Bits32) return Bits32
     with Post => Exp_Field'Result = (Shift_Right (Bits, 23) and 255)
                  and then Exp_Field'Result <= 255;

   function Mant_Field (Bits : Bits32) return Bits32
     with Post => (if Exp_Field (Bits) = 0 then Mant_Field'Result = 0
                  else Mant_Field'Result = ((Bits and 16#7FFFFF#) xor 16#800000#));

   function Semi_Sticky_Shift (Var : Bits64; Amount : Natural) return Bits64
     with Post => (if Amount >= 64 then Semi_Sticky_Shift'Result = 0
                  elsif Shift_Right (Var, Amount) = 0 then Semi_Sticky_Shift'Result = 0
                  elsif Shift_Left (Shift_Right (Var, Amount), Amount) = Var
                    then Semi_Sticky_Shift'Result = Shift_Right (Var, Amount)
                  else Semi_Sticky_Shift'Result = (Shift_Right (Var, Amount) or 1));

end Bh_Fma_Primitives;