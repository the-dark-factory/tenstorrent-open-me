with Interfaces; use Interfaces;
package Fma_Diff_Verdict_Pkg with SPARK_Mode is
   subtype Count is Interfaces.Unsigned_64;

   function Real_Run_Passes (Exit_Ok : Boolean; Checked : Count; Expected : Count; Mismatches : Count;
                             Nan : Count; Inf : Count; Zero : Count; Finite : Count) return Boolean
     is (Exit_Ok
         and then Expected > 0
         and then Checked = Expected
         and then Mismatches = 0
         and then Nan > 0 and then Inf > 0 and then Zero > 0 and then Finite > 0
         and then Nan <= Checked and then Inf <= Checked - Nan
         and then Zero <= Checked - Nan - Inf
         and then Finite = Checked - Nan - Inf - Zero)
     with Post => (if Real_Run_Passes'Result
                   then (Mismatches = 0 and then Checked > 0 and then Nan > 0
                         and then Inf > 0 and then Zero > 0 and then Finite > 0));

   function Mutant_Run_Passes (Exit_Failed : Boolean; Checked : Count; Expected : Count; Mismatches : Count) return Boolean
     is (Exit_Failed
         and then Expected > 0
         and then Checked = Expected
         and then Mismatches = Checked)
     with Post => (if Mutant_Run_Passes'Result then (Mismatches > 0 and then Mismatches = Checked));

   function Usage_Run_Passes (Exit_Failed : Boolean; Usage_Printed : Boolean) return Boolean
     is (Exit_Failed and then Usage_Printed);

   function Accepted (Real_Ok : Boolean; Mutant_Ok : Boolean; Usage_Ok : Boolean) return Boolean
     is (Real_Ok and then Mutant_Ok and then Usage_Ok)
     with Post => Accepted'Result = (Real_Ok and then Mutant_Ok and then Usage_Ok);

end Fma_Diff_Verdict_Pkg;