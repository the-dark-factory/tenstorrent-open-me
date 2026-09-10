package Transfer_Progress_Pkg with SPARK_Mode => On, Pure is

   subtype Byte_Count is Long_Long_Integer range 0 .. 1_099_511_627_776;
   subtype Cycle_Count is Long_Long_Integer range 0 .. 50_000_000_000;
   subtype Cycle_Span is Long_Long_Integer range 0 .. 2_097_152;
   subtype Byte_Rate is Long_Long_Integer range 1 .. 65_536;

   function Remaining_Bytes (Total : Byte_Count; Moved : Byte_Count) return Byte_Count is
     (Total - Moved)
   with Pre => (Moved <= Total), Post => (Remaining_Bytes'Result = Total - Moved and then Remaining_Bytes'Result <= Total and then ((if Moved = Total then Remaining_Bytes'Result = 0)));

   function Active_Cycles (Step_Length : Cycle_Span; Current, Start : Cycle_Count) return Cycle_Span is
     (if Step_Length < Current - Start then Step_Length else Cycle_Span (Current - Start))
   with Pre => (Current >= Start and then Current - Start <= Cycle_Span'Last), Post => (Active_Cycles'Result = (if Step_Length < Current - Start then Step_Length else Cycle_Span (Current - Start)) and then Active_Cycles'Result <= Step_Length and then Active_Cycles'Result <= Cycle_Span (Current - Start));

   function Max_Transferrable_Bytes (Span : Cycle_Span; Rate : Byte_Rate) return Byte_Count is
     (Byte_Count (Span * Rate))
   with Post => (Max_Transferrable_Bytes'Result = Byte_Count (Span * Rate) and then (if Span = 0 then Max_Transferrable_Bytes'Result = 0));

   function Bytes_Moved_This_Step (Total, Moved : Byte_Count; Span : Cycle_Span; Rate : Byte_Rate) return Byte_Count is
     (if Remaining_Bytes (Total, Moved) < Max_Transferrable_Bytes (Span, Rate) then Remaining_Bytes (Total, Moved) else Max_Transferrable_Bytes (Span, Rate))
   with Pre => (Moved <= Total), Post => (Bytes_Moved_This_Step'Result = (if Remaining_Bytes (Total, Moved) < Max_Transferrable_Bytes (Span, Rate) then Remaining_Bytes (Total, Moved) else Max_Transferrable_Bytes (Span, Rate)) and then Bytes_Moved_This_Step'Result <= Remaining_Bytes (Total, Moved) and then Bytes_Moved_This_Step'Result <= Max_Transferrable_Bytes (Span, Rate) and then (if Moved = Total then Bytes_Moved_This_Step'Result = 0));

   function Moved_After_Step (Total, Moved : Byte_Count; Span : Cycle_Span; Rate : Byte_Rate) return Byte_Count is
     (Moved + Bytes_Moved_This_Step (Total, Moved, Span, Rate))
   with Pre => (Moved <= Total), Post => (Moved_After_Step'Result = Moved + Bytes_Moved_This_Step (Total, Moved, Span, Rate) and then Moved_After_Step'Result <= Total and then Moved_After_Step'Result >= Moved and then Moved_After_Step'Result - Moved = Bytes_Moved_This_Step (Total, Moved, Span, Rate));

   function Is_Complete (Total, Moved : Byte_Count) return Boolean is
     (Moved = Total)
   with Post => (Is_Complete'Result = (Moved = Total));

   function Cycles_Transferring (Bytes : Byte_Count; Rate : Byte_Rate) return Cycle_Span is
     (Cycle_Span ((Bytes + Rate - 1) / Rate))
   with Pre => (Bytes <= Byte_Count (Cycle_Span'Last * Rate)), Post => (Cycles_Transferring'Result = Cycle_Span ((Bytes + Rate - 1) / Rate) and then Cycles_Transferring'Result * Rate >= Bytes and then (if Cycles_Transferring'Result > 0 then (Cycles_Transferring'Result - 1) * Rate < Bytes) and then (if Bytes = 0 then Cycles_Transferring'Result = 0));

end Transfer_Progress_Pkg;
