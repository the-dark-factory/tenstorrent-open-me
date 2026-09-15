with Interfaces; use Interfaces;
package Bh_Fma_Msb with SPARK_Mode is
   subtype Bits32 is Interfaces.Unsigned_32;

   function Msb_Index (V : Bits32) return Natural is (if    Shift_Right (V, 31) /= 0 then 31
       elsif Shift_Right (V, 30) /= 0 then 30
       elsif Shift_Right (V, 29) /= 0 then 29
       elsif Shift_Right (V, 28) /= 0 then 28
       elsif Shift_Right (V, 27) /= 0 then 27
       elsif Shift_Right (V, 26) /= 0 then 26
       elsif Shift_Right (V, 25) /= 0 then 25
       elsif Shift_Right (V, 24) /= 0 then 24
       elsif Shift_Right (V, 23) /= 0 then 23
       elsif Shift_Right (V, 22) /= 0 then 22
       elsif Shift_Right (V, 21) /= 0 then 21
       elsif Shift_Right (V, 20) /= 0 then 20
       elsif Shift_Right (V, 19) /= 0 then 19
       elsif Shift_Right (V, 18) /= 0 then 18
       elsif Shift_Right (V, 17) /= 0 then 17
       elsif Shift_Right (V, 16) /= 0 then 16
       elsif Shift_Right (V, 15) /= 0 then 15
       elsif Shift_Right (V, 14) /= 0 then 14
       elsif Shift_Right (V, 13) /= 0 then 13
       elsif Shift_Right (V, 12) /= 0 then 12
       elsif Shift_Right (V, 11) /= 0 then 11
       elsif Shift_Right (V, 10) /= 0 then 10
       elsif Shift_Right (V, 9) /= 0 then 9
       elsif Shift_Right (V, 8) /= 0 then 8
       elsif Shift_Right (V, 7) /= 0 then 7
       elsif Shift_Right (V, 6) /= 0 then 6
       elsif Shift_Right (V, 5) /= 0 then 5
       elsif Shift_Right (V, 4) /= 0 then 4
       elsif Shift_Right (V, 3) /= 0 then 3
       elsif Shift_Right (V, 2) /= 0 then 2
       elsif Shift_Right (V, 1) /= 0 then 1
       else 0)
   with Pre  => V /= 0,
        Post => Msb_Index'Result <= 31
                and then Shift_Right (V, Msb_Index'Result) = 1;

   function Lzc32 (V : Bits32) return Natural is (31 - Msb_Index (V))
   with Pre  => V /= 0,
        Post => Lzc32'Result = 31 - Msb_Index (V)
                and then Lzc32'Result <= 31;
end Bh_Fma_Msb;