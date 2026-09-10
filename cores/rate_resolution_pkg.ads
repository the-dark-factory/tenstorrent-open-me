package Rate_Resolution_Pkg with SPARK_Mode => On, Pure is

   subtype Milli_Rate is Long_Long_Integer range 1 .. 65_536_000;
   subtype Wide_Milli is Long_Long_Integer range 0 .. 65_536_000_000;
   subtype Permille is Long_Long_Integer range 1 .. 1_000;
   subtype Weight is Long_Long_Integer range 0 .. 1_000;
   subtype Byte_Rate is Long_Long_Integer range 1 .. 65_536;
   subtype Packet_Size is Long_Long_Integer range 1 .. 65_536;
   subtype Packet_Count is Long_Long_Integer range 1 .. 1_000_000;

   function Interpolate_Rate (Low_Size, High_Size : Packet_Size; Low_Rate, High_Rate : Milli_Rate; Size : Packet_Size) return Milli_Rate is ((Low_Rate + ((High_Rate - Low_Rate) * (Size - Low_Size)) / (High_Size - Low_Size))) with Pre => (Low_Size < High_Size and then Size in Low_Size .. High_Size), Post => (Interpolate_Rate'Result = Low_Rate + ((High_Rate - Low_Rate) * (Size - Low_Size)) / (High_Size - Low_Size) and then (if Size = Low_Size then Interpolate_Rate'Result = Low_Rate) and then (if Low_Rate <= High_Rate then Interpolate_Rate'Result >= Low_Rate and then Interpolate_Rate'Result <= High_Rate));

   function Steady_State_Weight (Count : Packet_Count) return Weight is (((Count - 1) * 1_000) / Count) with Post => (Steady_State_Weight'Result = ((Count - 1) * 1_000) / Count and then (if Count = 1 then Steady_State_Weight'Result = 0) and then Steady_State_Weight'Result < 1_000);

   function Blend_Rates (First_Rate, Steady_Rate : Milli_Rate; W : Weight) return Milli_Rate is ((Steady_Rate * W + First_Rate * (1_000 - W)) / 1_000) with Post => (Blend_Rates'Result = (Steady_Rate * W + First_Rate * (1_000 - W)) / 1_000 and then (if W = 1_000 then Blend_Rates'Result = Steady_Rate) and then (if W = 0 then Blend_Rates'Result = First_Rate) and then (if First_Rate <= Steady_Rate then Blend_Rates'Result >= First_Rate and then Blend_Rates'Result <= Steady_Rate));

   function Cap_By_Injection (Network_Limited, Injection : Milli_Rate) return Milli_Rate is (if Network_Limited < Injection then Network_Limited else Injection) with Post => (Cap_By_Injection'Result = (if Network_Limited < Injection then Network_Limited else Injection) and then Cap_By_Injection'Result <= Network_Limited and then Cap_By_Injection'Result <= Injection);

   function Floor_At_One (Value : Wide_Milli) return Wide_Milli is (if Value = 0 then 1 else Value) with Post => (Floor_At_One'Result = (if Value = 0 then 1 else Value) and then Floor_At_One'Result >= 1 and then (if Value >= 1 then Floor_At_One'Result = Value));

   function Apply_Derate (Rate : Milli_Rate; Factor : Permille) return Milli_Rate is (Milli_Rate (Floor_At_One (Wide_Milli (Rate) * Wide_Milli (Factor) / 1_000))) with Post => (Apply_Derate'Result = Milli_Rate (Floor_At_One (Wide_Milli (Rate) * Wide_Milli (Factor) / 1_000)) and then (if Rate >= 1_000 then Apply_Derate'Result <= Rate) and then (if Factor = 1_000 then Apply_Derate'Result = Rate) and then Apply_Derate'Result >= 1);

   function To_Whole_Bytes (Rate : Milli_Rate) return Byte_Rate is (Byte_Rate (Floor_At_One (Wide_Milli (Rate) / 1_000))) with Post => (To_Whole_Bytes'Result = Byte_Rate (Floor_At_One (Wide_Milli (Rate) / 1_000)) and then (if Rate >= 1_000 then To_Whole_Bytes'Result * 1_000 <= Rate) and then (if Rate >= 1_000 then Rate - To_Whole_Bytes'Result * 1_000 < 1_000) and then To_Whole_Bytes'Result >= 1);

end Rate_Resolution_Pkg;
