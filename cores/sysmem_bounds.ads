with Interfaces; use Interfaces;
package Sysmem_Bounds with SPARK_Mode is
   subtype Addr64 is Interfaces.Unsigned_64;

   function Is_Pow2 (S : Addr64) return Boolean;

   function Page_Base (VA : Addr64; Page_Size : Addr64) return Addr64
     with Pre => Is_Pow2 (Page_Size),
          Post => (Page_Base'Result mod Page_Size = 0)
                  and then (Page_Base'Result <= VA)
                  and then (VA - Page_Base'Result < Page_Size);

   function Offset_From_Base (VA : Addr64; Page_Size : Addr64) return Addr64
     with Pre => Is_Pow2 (Page_Size),
          Post => (Offset_From_Base'Result < Page_Size)
                  and then (Page_Base (VA, Page_Size) + Offset_From_Base'Result = VA);

   function Mapped_Size (Buffer_Size : Addr64; Offset : Addr64; Page_Size : Addr64) return Addr64
     with Pre => Is_Pow2 (Page_Size)
                  and then (Offset < Page_Size)
                  and then (Buffer_Size <= Addr64'Last - Offset - (Page_Size - 1)),
          Post => (Mapped_Size'Result mod Page_Size = 0)
                  and then (Mapped_Size'Result >= Buffer_Size + Offset)
                  and then (Mapped_Size'Result - (Buffer_Size + Offset) < Page_Size);

   function Validate (Offset : Addr64; Size : Addr64; Buffer_Size : Addr64) return Boolean
     with Post => (Validate'Result = (Offset < Buffer_Size and then Size <= Buffer_Size - Offset));

end Sysmem_Bounds;