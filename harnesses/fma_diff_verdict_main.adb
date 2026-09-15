with Ada.Text_IO;
with Ada.Command_Line;
with Fma_Diff_Verdict_Pkg;

procedure Fma_Diff_Verdict_Main is
   function Flag (S : String) return Boolean is (S = "1");

   function Num (S : String) return Fma_Diff_Verdict_Pkg.Count is
     (Fma_Diff_Verdict_Pkg.Count'Value (S));

   L01_Real_Exit_Ok        : constant String := Ada.Text_IO.Get_Line;
   L02_Real_Checked        : constant String := Ada.Text_IO.Get_Line;
   L03_Real_Expected       : constant String := Ada.Text_IO.Get_Line;
   L04_Real_Mismatches     : constant String := Ada.Text_IO.Get_Line;
   L05_Real_Nan            : constant String := Ada.Text_IO.Get_Line;
   L06_Real_Inf            : constant String := Ada.Text_IO.Get_Line;
   L07_Real_Zero           : constant String := Ada.Text_IO.Get_Line;
   L08_Real_Finite         : constant String := Ada.Text_IO.Get_Line;
   L09_Mutant_Exit_Failed  : constant String := Ada.Text_IO.Get_Line;
   L10_Mutant_Checked      : constant String := Ada.Text_IO.Get_Line;
   L11_Mutant_Expected     : constant String := Ada.Text_IO.Get_Line;
   L12_Mutant_Mismatches   : constant String := Ada.Text_IO.Get_Line;
   L13_Usage_Exit_Failed   : constant String := Ada.Text_IO.Get_Line;
   L14_Usage_Printed       : constant String := Ada.Text_IO.Get_Line;

   Real_Ok : constant Boolean := Fma_Diff_Verdict_Pkg.Real_Run_Passes
     (Exit_Ok    => Flag (L01_Real_Exit_Ok),
      Checked    => Num (L02_Real_Checked),
      Expected   => Num (L03_Real_Expected),
      Mismatches => Num (L04_Real_Mismatches),
      Nan        => Num (L05_Real_Nan),
      Inf        => Num (L06_Real_Inf),
      Zero       => Num (L07_Real_Zero),
      Finite     => Num (L08_Real_Finite));

   Mutant_Ok : constant Boolean := Fma_Diff_Verdict_Pkg.Mutant_Run_Passes
     (Exit_Failed => Flag (L09_Mutant_Exit_Failed),
      Checked     => Num (L10_Mutant_Checked),
      Expected    => Num (L11_Mutant_Expected),
      Mismatches  => Num (L12_Mutant_Mismatches));

   Usage_Ok : constant Boolean := Fma_Diff_Verdict_Pkg.Usage_Run_Passes
     (Exit_Failed   => Flag (L13_Usage_Exit_Failed),
      Usage_Printed => Flag (L14_Usage_Printed));

   Verdict : constant Boolean := Fma_Diff_Verdict_Pkg.Accepted
     (Real_Ok => Real_Ok, Mutant_Ok => Mutant_Ok, Usage_Ok => Usage_Ok);
begin
   Ada.Text_IO.Put_Line
     ((if Verdict then "ACCEPTED" else "REFUSED")
      & " real=" & Boolean'Image (Real_Ok)
      & " mutant=" & Boolean'Image (Mutant_Ok)
      & " usage=" & Boolean'Image (Usage_Ok));

   if Verdict then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Fma_Diff_Verdict_Main;
