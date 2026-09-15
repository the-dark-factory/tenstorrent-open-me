package body Bh_Fma_Primitives with SPARK_Mode is

   function Exp_Field (Bits : Bits32) return Bits32 is
      Result : constant Bits32 := Shift_Right (Bits, 23) and 255;
   begin
      return Result;
   end Exp_Field;

   function Mant_Field (Bits : Bits32) return Bits32 is
      E : constant Bits32 := Exp_Field (Bits);
      Result : Bits32;
   begin
      if E = 0 then
         Result := 0;
      else
         Result := ((Bits and 16#7FFFFF#) xor 16#800000#);
      end if;
      return Result;
   end Mant_Field;

   function Semi_Sticky_Shift (Var : Bits64; Amount : Natural) return Bits64 is
      Result : Bits64;
   begin
      if Amount >= 64 then
         Result := 0;
      else
         declare
            SR : constant Bits64 := Shift_Right (Var, Amount);
         begin
            if SR = 0 then
               Result := 0;
            elsif Shift_Left (SR, Amount) = Var then
               Result := SR;
            else
               Result := (SR or 1);
            end if;
         end;
      end if;
      return Result;
   end Semi_Sticky_Shift;

end Bh_Fma_Primitives;