package Checkpoint_Pkg with SPARK_Mode => On, Pure is

   subtype Checkpoint_Id is Long_Long_Integer range -1 .. 1_048_575;

   subtype Arrival_Count is Long_Long_Integer range 0 .. 65_536;

   subtype Cycle_Count is Long_Long_Integer range 0 .. 50_000_000_000;

   subtype Delay_Cycles is Long_Long_Integer range 0 .. 1_000_000;

   subtype Release_Point is Long_Long_Integer range 0 .. 50_001_000_000;

   function Is_Defined (Id : Checkpoint_Id) return Boolean
     is (Id /= -1)
     with Post => (Is_Defined'Result = (Id /= -1) and then (if Id = -1 then Is_Defined'Result = False));

   function Record_Arrival (Arrived, Expected : Arrival_Count) return Arrival_Count
     is (Arrived + 1)
     with Pre => (Arrived < Expected), Post => (Record_Arrival'Result = Arrived + 1 and then Record_Arrival'Result <= Expected and then Record_Arrival'Result > Arrived);

   function Latest_Finish (Recorded, Newer : Cycle_Count) return Cycle_Count
     is (if Recorded >= Newer then Recorded else Newer)
     with Post => ((Latest_Finish'Result = Recorded and then Recorded >= Newer) or else (Latest_Finish'Result = Newer and then Newer > Recorded)) and then Latest_Finish'Result >= Recorded and then (Latest_Finish'Result = Recorded or else Latest_Finish'Result = Newer);

   function All_Arrived (Arrived, Expected : Arrival_Count) return Boolean
     is (Arrived = Expected)
     with Post => (All_Arrived'Result = (Arrived = Expected) and then (if Arrived < Expected then All_Arrived'Result = False));

   function Release_Cycle (Finish : Cycle_Count; Wait : Delay_Cycles) return Release_Point
     is (Release_Point (Long_Long_Integer (Finish) + Long_Long_Integer (Wait)))
     with Post => (Release_Cycle'Result = Release_Point (Long_Long_Integer (Finish) + Long_Long_Integer (Wait)) and then Long_Long_Integer (Release_Cycle'Result) >= Long_Long_Integer (Finish) and then (if Wait = 0 then Long_Long_Integer (Release_Cycle'Result) = Long_Long_Integer (Finish)));

   function May_Proceed (Arrived, Expected : Arrival_Count; Finish : Cycle_Count; Wait : Delay_Cycles; Current : Cycle_Count) return Boolean
     is (All_Arrived (Arrived, Expected) and then Long_Long_Integer (Current) >= Long_Long_Integer (Release_Cycle (Finish, Wait)))
     with Post => (May_Proceed'Result = (All_Arrived (Arrived, Expected) and then Long_Long_Integer (Current) >= Long_Long_Integer (Release_Cycle (Finish, Wait))) and then (if Arrived < Expected then May_Proceed'Result = False) and then (if Long_Long_Integer (Current) < Long_Long_Integer (Release_Cycle (Finish, Wait)) then May_Proceed'Result = False));

end Checkpoint_Pkg;
