package Eth_Xy_Decode with SPARK_Mode is
   subtype Eth_Id is Natural range 0 .. 15;
   subtype Grid_X is Natural range 1 .. 9;
   subtype Grid_Y is Natural range 0 .. 6;

   function Encode_Id (X : Grid_X; Y : Grid_Y) return Eth_Id
     with Pre => (Y = 0 or Y = 6) and then X /= 5,
          Post => Encode_Id'Result = (if X <= 4 then 2 * X - 1 else 18 - 2 * X) + (if Y = 6 then 8 else 0);

   function Decode_X (Id : Eth_Id) return Grid_X
     with Post => (if Id mod 2 = 1 then Decode_X'Result = 1 + (Id mod 8) / 2
                   else Decode_X'Result = 9 - (Id mod 8) / 2)
                  and then Decode_X'Result /= 5;

   function Decode_Y (Id : Eth_Id) return Grid_Y
     with Post => Decode_Y'Result = (if Id > 7 then 6 else 0)
                  and then Encode_Id (Decode_X (Id), Decode_Y'Result) = Id;

end Eth_Xy_Decode;