--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: © 2026 The Dark Factory Ltd

pragma SPARK_Mode (Off);
--  DIFFERENTIAL HARNESS — INSTRUMENTATION, NOT FACTORY PRODUCT.
--  Explicitly SPARK_Mode Off: this is I/O glue, it carries no contracts, it
--  proves nothing, and it is never admitted to the ledger. Its only job is to
--  drive the ADMITTED cores over the same inputs the tt-npe oracle was given.
--  The cores themselves came through the lane; this did not and must not.
--
--  Input on stdin, whitespace separated:
--     1 arrived expected finish wait current      (checkpoint)
--     2 rows cols r c sr sc er ec                 (grid bounds)

with Ada.Text_IO;                   use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Checkpoint_Pkg;
with Grid_Bounds_Pkg;
with Rate_Resolution_Pkg;
with Transfer_Progress_Pkg;
with Timestep_Pkg;

procedure Diff_Harness is
   Tag : Long_Long_Integer;

   function B2I (B : Boolean) return Long_Long_Integer is (if B then 1 else 0);

   procedure Put_LLI (V : Long_Long_Integer) is
   begin
      Put (V, Width => 0);
   end Put_LLI;
begin
   loop
      begin
         Get (Tag);
      exception
         when others => exit;
      end;

      if Tag = 1 then
         declare
            Arrived, Expected, Finish, Wait, Current : Long_Long_Integer;
         begin
            Get (Arrived); Get (Expected); Get (Finish); Get (Wait); Get (Current);
            --  their end_cycle starts at 0 and only becomes `finish` once
            --  something has arrived; mirror that in what we hand the core.
            declare
               Eff_Finish : constant Checkpoint_Pkg.Cycle_Count :=
                 (if Arrived > 0 then Checkpoint_Pkg.Cycle_Count (Finish) else 0);
               A : constant Checkpoint_Pkg.Arrival_Count :=
                 Checkpoint_Pkg.Arrival_Count (Arrived);
               E : constant Checkpoint_Pkg.Arrival_Count :=
                 Checkpoint_Pkg.Arrival_Count (Expected);
               W : constant Checkpoint_Pkg.Delay_Cycles :=
                 Checkpoint_Pkg.Delay_Cycles (Wait);
               C : constant Checkpoint_Pkg.Cycle_Count :=
                 Checkpoint_Pkg.Cycle_Count (Current);
            begin
               Put ("A,");
               Put_LLI (B2I (Checkpoint_Pkg.May_Proceed (A, E, Eff_Finish, W, C)));
               Put (",");
               Put_LLI (Long_Long_Integer (Checkpoint_Pkg.Release_Cycle (Eff_Finish, W)));
               Put (",");
               Put_LLI (B2I (Checkpoint_Pkg.All_Arrived (A, E)));
               New_Line;
            end;
         end;

      elsif Tag = 2 then
         declare
            Rows, Cols, R, C, Sr, Sc, Er, Ec : Long_Long_Integer;
         begin
            Get (Rows); Get (Cols); Get (R); Get (C);
            Get (Sr); Get (Sc); Get (Er); Get (Ec);
            declare
               use Grid_Bounds_Pkg;
               Rw : constant Dimension  := Dimension (Rows);
               Cl : constant Dimension  := Dimension (Cols);
               Rr : constant Coordinate := Coordinate (R);
               Cc : constant Coordinate := Coordinate (C);
               In_B : constant Boolean  := In_Bounds (Rw, Cl, Rr, Cc);
            begin
               Put ("B,");
               Put_LLI (B2I (In_B));
               Put (",");
               if In_B then
                  Put_LLI (Long_Long_Integer (Cell_Of (Rw, Cl, Rr, Cc)));
               else
                  Put_LLI (-1);
               end if;
               Put (",");
               Put_LLI (Long_Long_Integer
                 (Rectangle_Cells (Coordinate (Sr), Coordinate (Sc),
                                   Coordinate (Er), Coordinate (Ec))));
               New_Line;
            end;
         end;
      elsif Tag = 3 then
         declare
            Ps, Np, Ls, Hs, Lr, Hr, Mx : Long_Long_Integer;
         begin
            Get (Ps); Get (Np); Get (Ls); Get (Hs); Get (Lr); Get (Hr); Get (Mx);
            declare
               use Rate_Resolution_Pkg;
               Steady : constant Milli_Rate :=
                 Interpolate_Rate (Packet_Size (Ls), Packet_Size (Hs),
                                   Milli_Rate (Lr), Milli_Rate (Hr),
                                   Packet_Size (Ps));
               W : constant Weight := Steady_State_Weight (Packet_Count (Np));
               R : constant Milli_Rate := Blend_Rates (Milli_Rate (Mx), Steady, W);
            begin
               Put ("C,");
               Put_LLI (Long_Long_Integer (R));
               New_Line;
            end;
         end;
      elsif Tag = 4 then
         declare
            Total, Moved, Rate, Step, St, Cur : Long_Long_Integer;
         begin
            Get (Total); Get (Moved); Get (Rate); Get (Step); Get (St); Get (Cur);
            declare
               use Transfer_Progress_Pkg;
               Sp : constant Cycle_Span :=
                 Active_Cycles (Cycle_Span (Step), Cycle_Count (Cur), Cycle_Count (St));
               Bm : constant Byte_Count :=
                 Bytes_Moved_This_Step (Byte_Count (Total), Byte_Count (Moved), Sp, Byte_Rate (Rate));
               Af : constant Byte_Count :=
                 Moved_After_Step (Byte_Count (Total), Byte_Count (Moved), Sp, Byte_Rate (Rate));
            begin
               Put ("D,"); Put_LLI (Long_Long_Integer (Sp));
               Put (","); Put_LLI (Long_Long_Integer (Bm));
               Put (","); Put_LLI (Long_Long_Integer (Af));
               New_Line;
            end;
         end;

      elsif Tag = 5 then
         declare
            Step, Cur, Test : Long_Long_Integer;
         begin
            Get (Step); Get (Cur); Get (Test);
            declare
               use Timestep_Pkg;
               Ss : constant Cycle_Count :=
                 Step_Start (Cycle_Count (Cur), Step_Cycles (Step));
               Ps : constant Cycle_Count :=
                 Previous_Step_Start (Cycle_Count (Cur), Step_Cycles (Step));
               Ip : constant Boolean :=
                 In_Previous_Step (Cycle_Count (Cur), Step_Cycles (Step), Cycle_Count (Test));
               Ad : constant Extended_Cycle :=
                 Advance (Cycle_Count (Cur), Step_Cycles (Step));
            begin
               Put ("E,"); Put_LLI (Long_Long_Integer (Ss));
               Put (","); Put_LLI (Long_Long_Integer (Ps));
               Put (","); Put_LLI (B2I (Ip));
               Put (","); Put_LLI (Long_Long_Integer (Ad));
               New_Line;
            end;
         end;
      end if;
   end loop;
end Diff_Harness;
