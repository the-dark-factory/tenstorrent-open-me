package Timestep_Pkg with SPARK_Mode => On, Pure is

   subtype Step_Cycles is Long_Long_Integer range 1 .. 1_048_576;

   subtype Cycle_Count is Long_Long_Integer range 0 .. 50_000_000_000;

   subtype Extended_Cycle is Long_Long_Integer range 0 .. 50_001_048_576;

   subtype Work_Count is Long_Long_Integer range 0 .. 1_048_576;

   function Step_Start (Current : Cycle_Count; Length : Step_Cycles) return Cycle_Count
     is (Cycle_Count (Long_Long_Integer (Current) - Long_Long_Integer (Length)))
     with Pre => Long_Long_Integer (Current) >= Long_Long_Integer (Length),
          Post => (Step_Start'Result = Cycle_Count (Long_Long_Integer (Current) - Long_Long_Integer (Length))
           and then Step_Start'Result <= Current
           and then (if Current = Length then Step_Start'Result = 0));

   function Previous_Step_Start (Current : Cycle_Count; Length : Step_Cycles) return Cycle_Count
     is (if Long_Long_Integer (Current) >= 2 * Long_Long_Integer (Length) then Cycle_Count (Long_Long_Integer (Current) - 2 * Long_Long_Integer (Length)) else 0)
     with Pre => Long_Long_Integer (Current) >= Long_Long_Integer (Length),
          Post => (Previous_Step_Start'Result = (if Long_Long_Integer (Current) >= 2 * Long_Long_Integer (Length) then Cycle_Count (Long_Long_Integer (Current) - 2 * Long_Long_Integer (Length)) else 0)
           and then Previous_Step_Start'Result >= 0
           and then Previous_Step_Start'Result <= Step_Start (Current, Length));

   function In_Previous_Step (Current : Cycle_Count; Length : Step_Cycles; Test : Cycle_Count) return Boolean
     is ((Long_Long_Integer (Test) >= Long_Long_Integer (Previous_Step_Start (Current, Length)) and then Long_Long_Integer (Test) < Long_Long_Integer (Step_Start (Current, Length))))
     with Pre => Long_Long_Integer (Current) >= Long_Long_Integer (Length),
          Post => (In_Previous_Step'Result = (Long_Long_Integer (Test) >= Long_Long_Integer (Previous_Step_Start (Current, Length)) and then Long_Long_Integer (Test) < Long_Long_Integer (Step_Start (Current, Length)))
           and then (if Long_Long_Integer (Test) < Long_Long_Integer (Previous_Step_Start (Current, Length)) then In_Previous_Step'Result = False)
           and then (if Long_Long_Integer (Test) >= Long_Long_Integer (Step_Start (Current, Length)) then In_Previous_Step'Result = False));

   function Advance (Current : Cycle_Count; Length : Step_Cycles) return Extended_Cycle
     is (Extended_Cycle (Long_Long_Integer (Current) + Long_Long_Integer (Length)))
     with Post => (Advance'Result = Extended_Cycle (Long_Long_Integer (Current) + Long_Long_Integer (Length))
           and then Long_Long_Integer (Advance'Result) > Long_Long_Integer (Current)
           and then (if Current = 50_000_000_000 then Long_Long_Integer (Advance'Result) > 50_000_000_000));

   function Ran_Too_Long (Cycle : Extended_Cycle) return Boolean
     is (Long_Long_Integer (Cycle) > 50_000_000_000)
     with Post => (Ran_Too_Long'Result = (Long_Long_Integer (Cycle) > 50_000_000_000)
           and then (if Cycle = 50_000_000_000 then Ran_Too_Long'Result = False));

   function Run_Complete (Live : Work_Count; Queued : Work_Count) return Boolean
     is ((Live = 0 and then Queued = 0))
     with Post => (Run_Complete'Result = (Live = 0 and then Queued = 0)
           and then (if Live > 0 then Run_Complete'Result = False)
           and then (if Queued > 0 then Run_Complete'Result = False));

end Timestep_Pkg;
