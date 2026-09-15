with Interfaces; use Interfaces;
package Pcie_Alignment with SPARK_Mode is
   subtype Addr64 is Interfaces.Unsigned_64;

   function Is_Pow2 (S : Addr64) return Boolean with
     Post => Is_Pow2'Result = (S /= 0 and then (S and (S - 1)) = 0);

   function Aligned_By_Mod (Addr : Addr64; Page_Size : Addr64) return Boolean with
     Pre  => Page_Size >= 1,
     Post => Aligned_By_Mod'Result = (Addr mod Page_Size = 0);

   function Aligned_By_Mask (Addr : Addr64; Page_Size : Addr64) return Boolean with
     Pre  => Is_Pow2 (Page_Size),
     Post => Aligned_By_Mask'Result = ((Addr and (Page_Size - 1)) = 0);

   function Hugepage_Size_Valid (Size : Addr64; Page_Size : Addr64) return Boolean with
     Pre  => Page_Size >= 1,
     Post => Hugepage_Size_Valid'Result =
       (Size <= 2**30 and then Aligned_By_Mod (Size, Page_Size));

end Pcie_Alignment;