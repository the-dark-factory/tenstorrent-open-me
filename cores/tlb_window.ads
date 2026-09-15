with Interfaces; use Interfaces;
package Tlb_Window with SPARK_Mode is

   subtype Addr64 is Interfaces.Unsigned_64;

   function Is_Pow2 (S : Addr64) return Boolean;

   function Aligned_Base (A : Addr64; Size : Addr64) return Addr64
     with
       Pre => Is_Pow2 (Size),
       Post => (Aligned_Base'Result mod Size = 0)
               and then (Aligned_Base'Result <= A)
               and then (A - Aligned_Base'Result < Size);

   function Offset_In_Window (A : Addr64; Size : Addr64) return Addr64
     with
       Pre => Is_Pow2 (Size),
       Post => (Offset_In_Window'Result < Size)
               and then (Aligned_Base (A, Size) + Offset_In_Window'Result = A);

   function Usable_Size (Handle_Size : Addr64; Offset : Addr64) return Addr64
     with
       Pre => Offset <= Handle_Size,
       Post => Usable_Size'Result = Handle_Size - Offset;

   function Validate (Offset : Addr64; Size : Addr64; Window_Size : Addr64) return Boolean
     with
       Post => (Validate'Result = (Offset <= Window_Size and then Size <= Window_Size - Offset));

end Tlb_Window;