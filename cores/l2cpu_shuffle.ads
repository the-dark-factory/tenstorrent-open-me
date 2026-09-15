with Interfaces; use Interfaces;
package L2cpu_Shuffle with SPARK_Mode is
   subtype Word32 is Interfaces.Unsigned_32;

   function Unshuffle (Harvesting_Mask : Word32) return Word32
     with Pre => Harvesting_Mask <= 15,
          Post => Unshuffle'Result <= 15
          and then Unshuffle'Result =
            ((if ((not Harvesting_Mask) and 1) /= 0 then 1 else 0)
             or (if ((not Harvesting_Mask) and 8) /= 0 then 2 else 0)
             or (if ((not Harvesting_Mask) and 2) /= 0 then 4 else 0)
             or (if ((not Harvesting_Mask) and 4) /= 0 then 8 else 0));

   function Shuffle (Layout : Word32) return Word32
     with Pre => Layout <= 15,
          Post => Shuffle'Result <= 15
          and then Shuffle'Result =
            ((if ((not Layout) and 1) /= 0 then 1 else 0)
             or (if ((not Layout) and 2) /= 0 then 8 else 0)
             or (if ((not Layout) and 4) /= 0 then 2 else 0)
             or (if ((not Layout) and 8) /= 0 then 4 else 0))
          and then Unshuffle (Shuffle'Result) = Layout;

end L2cpu_Shuffle;