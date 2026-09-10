package Grid_Bounds_Pkg with SPARK_Mode => On, Pure is

   subtype Dimension is Long_Long_Integer range 1 .. 64;

   subtype Coordinate is Long_Long_Integer range 0 .. 63;

   subtype Cell_Index is Long_Long_Integer range 0 .. 4_095;

   subtype Cell_Count is Long_Long_Integer range 1 .. 4_096;

   function In_Bounds (Row_Count : Dimension; Col_Count : Dimension; Row : Coordinate; Col : Coordinate) return Boolean
     is ((Row < Long_Long_Integer (Row_Count)) and then (Col < Long_Long_Integer (Col_Count)))
     with Pre => (True), Post => (In_Bounds'Result = ((Row < Long_Long_Integer (Row_Count)) and then (Col < Long_Long_Integer (Col_Count))) and then (if Row >= Long_Long_Integer (Row_Count) then In_Bounds'Result = False) and then (if Col >= Long_Long_Integer (Col_Count) then In_Bounds'Result = False));

   function Cell_Of (Row_Count : Dimension; Col_Count : Dimension; Row : Coordinate; Col : Coordinate) return Cell_Index
     is (Cell_Index (Long_Long_Integer (Row) * Long_Long_Integer (Col_Count) + Long_Long_Integer (Col)))
     with Pre => (In_Bounds (Row_Count, Col_Count, Row, Col)), Post => (Cell_Of'Result = Cell_Index (Long_Long_Integer (Row) * Long_Long_Integer (Col_Count) + Long_Long_Integer (Col)) and then (Long_Long_Integer (Cell_Of'Result) < Long_Long_Integer (Row_Count) * Long_Long_Integer (Col_Count)) and then (if Row = 0 and Col = 0 then Cell_Of'Result = 0));

   function Is_Rectangle (First_Row : Coordinate; First_Col : Coordinate; Second_Row : Coordinate; Second_Col : Coordinate) return Boolean
     is ((First_Row <= Second_Row) and then (First_Col <= Second_Col))
     with Pre => (True), Post => (Is_Rectangle'Result = ((First_Row <= Second_Row) and then (First_Col <= Second_Col)) and then (if First_Row > Second_Row then Is_Rectangle'Result = False) and then (if First_Col > Second_Col then Is_Rectangle'Result = False) and then (if First_Row = Second_Row and First_Col = Second_Col then Is_Rectangle'Result = True));

   function Rectangle_Cells (First_Row : Coordinate; First_Col : Coordinate; Second_Row : Coordinate; Second_Col : Coordinate) return Cell_Count
     is (Cell_Count ((Long_Long_Integer (Second_Row) - Long_Long_Integer (First_Row) + 1) * (Long_Long_Integer (Second_Col) - Long_Long_Integer (First_Col) + 1)))
     with Pre => (Is_Rectangle (First_Row, First_Col, Second_Row, Second_Col)), Post => (Rectangle_Cells'Result = Cell_Count ((Long_Long_Integer (Second_Row) - Long_Long_Integer (First_Row) + 1) * (Long_Long_Integer (Second_Col) - Long_Long_Integer (First_Col) + 1)) and then (Rectangle_Cells'Result >= 1) and then (if First_Row = Second_Row and First_Col = Second_Col then Rectangle_Cells'Result = 1));

   function Rectangle_On_Grid (Row_Count : Dimension; Col_Count : Dimension; First_Row : Coordinate; First_Col : Coordinate; Second_Row : Coordinate; Second_Col : Coordinate) return Boolean
     is ((Is_Rectangle (First_Row, First_Col, Second_Row, Second_Col)) and then (In_Bounds (Row_Count, Col_Count, First_Row, First_Col)) and then (In_Bounds (Row_Count, Col_Count, Second_Row, Second_Col)))
     with Pre => (True), Post => (Rectangle_On_Grid'Result = ((Is_Rectangle (First_Row, First_Col, Second_Row, Second_Col)) and then (In_Bounds (Row_Count, Col_Count, First_Row, First_Col)) and then (In_Bounds (Row_Count, Col_Count, Second_Row, Second_Col))) and then (if not Is_Rectangle (First_Row, First_Col, Second_Row, Second_Col) then Rectangle_On_Grid'Result = False) and then (if not In_Bounds (Row_Count, Col_Count, Second_Row, Second_Col) then Rectangle_On_Grid'Result = False));

   function Rectangle_Contains (First_Row : Coordinate; First_Col : Coordinate; Second_Row : Coordinate; Second_Col : Coordinate; Row : Coordinate; Col : Coordinate) return Boolean
     is ((Row >= First_Row) and then (Row <= Second_Row) and then (Col >= First_Col) and then (Col <= Second_Col))
     with Pre => (Is_Rectangle (First_Row, First_Col, Second_Row, Second_Col)), Post => (Rectangle_Contains'Result = ((Row >= First_Row) and then (Row <= Second_Row) and then (Col >= First_Col) and then (Col <= Second_Col)) and then (if Row = First_Row and Col = First_Col then Rectangle_Contains'Result = True) and then (if Row = Second_Row and Col = Second_Col then Rectangle_Contains'Result = True));

end Grid_Bounds_Pkg;
