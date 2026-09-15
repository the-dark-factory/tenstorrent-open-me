package Dram_Bank_Mirror with SPARK_Mode is

   function Mirror_Bank (Harvested_Bank : Natural; Num_Banks : Positive) return Natural
     with Pre => Harvested_Bank < Num_Banks and then Num_Banks mod 2 = 0 and then Num_Banks >= 2,
          Post =>
            (if Harvested_Bank < Num_Banks / 2 then
               Mirror_Bank'Result = Harvested_Bank + Num_Banks / 2 - 1
               and then Mirror_Bank'Result >= Num_Banks / 2 - 1
               and then Mirror_Bank'Result < Num_Banks - 1
             else
               Mirror_Bank'Result = Harvested_Bank - Num_Banks / 2
               and then Mirror_Bank'Result < Num_Banks / 2);

end Dram_Bank_Mirror;