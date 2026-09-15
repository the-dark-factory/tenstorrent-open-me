with Interfaces; use Interfaces;
package Bh_Fma_Align_Add with SPARK_Mode is
   subtype Bits32 is Interfaces.Unsigned_32;
   subtype Bits64 is Interfaces.Unsigned_64;

   function Semi_Sticky_Shift64 (Var : Bits64; Amount : Natural) return Bits64 is
     (if Amount >= 64 then 0
      elsif Shift_Right (Var, Amount) = 0 then 0
      elsif Shift_Left (Shift_Right (Var, Amount), Amount) = Var then Shift_Right (Var, Amount)
      else (Shift_Right (Var, Amount) or 1));

   function Semi_Sticky_Shift32 (Var : Bits32; Amount : Natural) return Bits32 is
     (if Amount >= 32 then 0
      elsif Shift_Right (Var, Amount) = 0 then 0
      elsif Shift_Left (Shift_Right (Var, Amount), Amount) = Var then Shift_Right (Var, Amount)
      else (Shift_Right (Var, Amount) or 1));

   function Sum_Exponent (P_E : Integer; Z_E : Integer) return Integer is
     (if P_E > Z_E then P_E else Z_E)
     with Pre  => P_E in 0 .. 254 and then Z_E in 0 .. 254,
          Post => Sum_Exponent'Result in 0 .. 254
                  and then Sum_Exponent'Result >= P_E
                  and then Sum_Exponent'Result >= Z_E;

   function Aligned_P (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits64 is
     (if P_E < Sum_Exponent (P_E, Z_E)
      then Semi_Sticky_Shift64 (P_M, Sum_Exponent (P_E, Z_E) - P_E)
      else P_M)
     with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

   function Aligned_Z (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32 is
     (if Z_E < Sum_Exponent (P_E, Z_E)
      then Semi_Sticky_Shift32 (Z_M, Sum_Exponent (P_E, Z_E) - Z_E)
      else Z_M)
     with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

   function Sum_Sign (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32 is
     (if Aligned_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
        >= Bits64 (Aligned_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
     then P_Sign else Z_Sign)
     with Pre  => P_E in 0 .. 254 and then Z_E in 0 .. 254,
          Post => Sum_Sign'Result = P_Sign or else Sum_Sign'Result = Z_Sign;

   function Signed_Z (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32 is
     (if Z_Sign /= Sum_Sign (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
      then not Aligned_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
      else Aligned_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
     with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

   function Signed_P (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits64 is
     (if P_Sign /= Sum_Sign (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
      then not Aligned_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
      else Aligned_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
     with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;

   function Sum_Mantissa (P_M : Bits64; P_E : Integer; P_Sign : Bits32; Z_M : Bits32; Z_E : Integer; Z_Sign : Bits32) return Bits32 is
     (Bits32 ((Bits64 (Signed_Z (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign))
               + Signed_P (P_M, P_E, P_Sign, Z_M, Z_E, Z_Sign)
               + (if P_Sign /= Z_Sign then 1 else 0))
              and 16#FFFFFFFF#))
     with Pre => P_E in 0 .. 254 and then Z_E in 0 .. 254;
end Bh_Fma_Align_Add;