with Ada.Text_IO;
with Ada.Command_Line;
with Interfaces;
with Bh_Fma;

procedure Fma_Diff_Main is
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   function Vendor_Fma
     (X : Interfaces.Unsigned_32;
      Y : Interfaces.Unsigned_32;
      Z : Interfaces.Unsigned_32) return Interfaces.Unsigned_32
     with Import, Convention => C, External_Name => "fma_model_bh";

   package U32_IO is new Ada.Text_IO.Modular_IO (Interfaces.Unsigned_32);

   Specials : constant array (1 .. 40) of Interfaces.Unsigned_32 := (
      16#00000000#, 16#80000000#, 16#00000001#, 16#80000001#, 16#007FFFFF#,
      16#807FFFFF#, 16#00800000#, 16#80800000#, 16#3F800000#, 16#BF800000#,
      16#40000000#, 16#C0000000#, 16#3F000000#, 16#3FFFFFFF#, 16#40000001#,
      16#3F800001#, 16#7F7FFFFF#, 16#FF7FFFFF#, 16#7F800000#, 16#FF800000#,
      16#7FC00000#, 16#FFC00000#, 16#7F800001#, 16#7FFFFFFF#, 16#1F800000#,
      16#20000000#, 16#1F7FFFFF#, 16#5F800000#, 16#5FFFFFFF#, 16#60000000#,
      16#00FFFFFF#, 16#01000000#, 16#3E800000#, 16#40800000#, 16#9F800000#,
      16#DF800000#, 16#7E800000#, 16#FE800000#, 16#00000002#, 16#12345678#);

   Edge_Exponents : constant array (1 .. 17) of Interfaces.Unsigned_32 :=
      (0, 1, 2, 63, 64, 65, 100, 126, 127, 128, 129, 190, 191, 192, 253, 254, 255);

begin
   if Ada.Command_Line.Argument_Count /= 1 and then Ada.Command_Line.Argument_Count /= 2 then
      Ada.Text_IO.Put_Line ("usage: fma_diff_main <random_count> [mutant]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   declare
      Random_Count : constant Interfaces.Unsigned_64 :=
         Interfaces.Unsigned_64'Value (Ada.Command_Line.Argument (1));
      Mutant : constant Boolean :=
         Ada.Command_Line.Argument_Count = 2
         and then Ada.Command_Line.Argument (2) = "mutant";

      Checked : Interfaces.Unsigned_64 := 0;
      Mismatches : Interfaces.Unsigned_64 := 0;
      Nan_Count : Interfaces.Unsigned_64 := 0;
      Inf_Count : Interfaces.Unsigned_64 := 0;
      Zero_Count : Interfaces.Unsigned_64 := 0;
      Finite_Count : Interfaces.Unsigned_64 := 0;
      Seed : Interfaces.Unsigned_64 := 16#9E3779B97F4A7C15#;

      procedure Next_Random (R : out Interfaces.Unsigned_32) is
      begin
         Seed := Seed xor Interfaces.Shift_Left (Seed, 13);
         Seed := Seed xor Interfaces.Shift_Right (Seed, 7);
         Seed := Seed xor Interfaces.Shift_Left (Seed, 17);
         R := Interfaces.Unsigned_32 (Seed and 16#FFFFFFFF#);
      end Next_Random;

      procedure Check (X, Y, Z : Interfaces.Unsigned_32) is
         Want : constant Interfaces.Unsigned_32 := Vendor_Fma (X, Y, Z);
         Got0 : constant Interfaces.Unsigned_32 := Bh_Fma.Fma_Bh (X, Y, Z);
         Got  : constant Interfaces.Unsigned_32 := (if Mutant then Got0 xor 1 else Got0);
         E    : constant Interfaces.Unsigned_32 := Interfaces.Shift_Right (Want, 23) and 255;
      begin
         Checked := Checked + 1;
         if E = 255 and then (Want and 16#7FFFFF#) /= 0 then
            Nan_Count := Nan_Count + 1;
         elsif E = 255 then
            Inf_Count := Inf_Count + 1;
         elsif (Want and 16#7FFFFFFF#) = 0 then
            Zero_Count := Zero_Count + 1;
         else
            Finite_Count := Finite_Count + 1;
         end if;

         if Got /= Want then
            Mismatches := Mismatches + 1;
            if Mismatches <= 10 then
               Ada.Text_IO.Put ("MISMATCH x=");
               U32_IO.Put (Item => X, Width => 13, Base => 16);
               Ada.Text_IO.Put (" y=");
               U32_IO.Put (Item => Y, Width => 13, Base => 16);
               Ada.Text_IO.Put (" z=");
               U32_IO.Put (Item => Z, Width => 13, Base => 16);
               Ada.Text_IO.Put (" vendor=");
               U32_IO.Put (Item => Want, Width => 13, Base => 16);
               Ada.Text_IO.Put (" ada=");
               U32_IO.Put (Item => Got, Width => 13, Base => 16);
               Ada.Text_IO.New_Line;
            end if;
         end if;
      end Check;

      I : Integer;
      J : Integer;
      K : Integer;
      N : Interfaces.Unsigned_64;
      R1 : Interfaces.Unsigned_32;
      R2 : Interfaces.Unsigned_32;
      R3 : Interfaces.Unsigned_32;
      R4 : Interfaces.Unsigned_32;

   begin
      for I in Specials'Range loop
         for J in Specials'Range loop
            for K in Specials'Range loop
               Check (Specials (I), Specials (J), Specials (K));
            end loop;
         end loop;
      end loop;

      for N in Interfaces.Unsigned_64 range 1 .. Random_Count loop
         Next_Random (R1);
         Next_Random (R2);
         Next_Random (R3);
         if (N and 1) = 0 then
            Check (R1, R2, R3);
         else
            Next_Random (R4);
            Check ((R1 and 16#807FFFFF#)
                     or Interfaces.Shift_Left (Edge_Exponents (Integer (R4 mod 17) + 1), 23),
                   (R2 and 16#807FFFFF#)
                     or Interfaces.Shift_Left (Edge_Exponents (Integer (Interfaces.Shift_Right (R4, 8) mod 17) + 1), 23),
                   (R3 and 16#807FFFFF#)
                     or Interfaces.Shift_Left (Edge_Exponents (Integer (Interfaces.Shift_Right (R4, 16) mod 17) + 1), 23));
         end if;
      end loop;

      Ada.Text_IO.Put_Line ("CHECKED" & Interfaces.Unsigned_64'Image (Checked));
      Ada.Text_IO.Put_Line ("MISMATCHES" & Interfaces.Unsigned_64'Image (Mismatches));
      Ada.Text_IO.Put_Line ("CLASSES nan" & Interfaces.Unsigned_64'Image (Nan_Count)
                            & " inf" & Interfaces.Unsigned_64'Image (Inf_Count)
                            & " zero" & Interfaces.Unsigned_64'Image (Zero_Count)
                            & " finite" & Interfaces.Unsigned_64'Image (Finite_Count));

      if Mismatches = 0 then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   end;
end Fma_Diff_Main;
