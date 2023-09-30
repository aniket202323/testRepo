CREATE PROCEDURE dbo.[spXLA_RunInfoCalculations_Bak_177] 
 	   @Start_Time  	 DateTime
 	 , @End_Time  	 DateTime
 	 , @Pu_Id  	 Integer
 	 , @Prod_Id  	 Integer
 	 , @Group_Id  	 Integer
 	 , @Prop_Id  	 Integer
 	 , @Char_Id  	 Integer
 	 , @CalcType 	 TinyInt   --1(Duration), 2(In_Warning), 3(In_Limit), 4(Conf_Index)
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
/*
 	 ----------------------------------------------------------------
 	  	 New Stored Procedure 
 	  	 Replaces spXLARunInfoCalc (Dynamic SQL removed) 
 	  	 10-23-2001 (MT) 
 	 ----------------------------------------------------------------
*/  
 	 --Recordset variables
DECLARE @Average 	  	 Real
DECLARE @StdDeviation 	  	 Real
DECLARE @TotalDuration 	  	 Real
DECLARE @TimeOfMin 	  	 DateTime
DECLARE @TimeOfMax 	  	 DateTime
 	 --Local variables
DECLARE @FetchCount  	  	 Int
DECLARE @TempValue 	  	 Real
DECLARE @TempMin  	  	 Real
DECLARE @TempMax  	  	 Real
DECLARE @SumXSqr 	  	 Real
DECLARE @SumDurationWeighted 	 Real
DECLARE @SQLString 	  	 Varchar(1000)
 	 --Cursor-related variables
DECLARE @@Start_Time  	  	 DateTime
DECLARE @@Duration 	  	 Real
DECLARE @@In_Warning 	  	 Real
DECLARE @@In_Limit 	  	 Real
DECLARE @@Conf_Index 	  	 Real
DECLARE @SingleProductNoTime 	  	 TinyInt 	  	 
DECLARE @SingleGroupNoTime 	  	 TinyInt
DECLARE @SingleCharacteristicNoTime 	 TinyInt
DECLARE @GroupAndPropertyNoTime 	  	 TinyInt
DECLARE @NoProductNoTime 	  	 TinyInt
 	 --Local variables with Start & End times
DECLARE @SingleProduct 	  	  	 TinyInt
DECLARE @SingleGroup 	  	  	 TinyInt
DECLARE @SingleCharacteristic 	  	 TinyInt
DECLARE @GroupAndProperty 	  	 TinyInt
DECLARE @NoProduct 	  	  	 TinyInt
SELECT @SingleProductNoTime 	  	 = 1
SELECT @SingleProduct 	  	  	 = 2
SELECT @SingleGroupNoTime 	  	 = 3
SELECT @SingleGroup 	  	  	 = 4
SELECT @SingleCharacteristicNoTime 	 = 5
SELECT @SingleCharacteristic 	  	 = 6
SELECT @GroupAndPropertyNoTime 	  	 = 7
SELECT @GroupAndProperty 	  	 = 8
SELECT @NoProductNoTime 	  	  	 = 9
SELECT @NoProduct 	  	  	 = 10
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
DECLARE @qType TinyInt
If @End_Time Is NULL
  BEGIN
    If @Prod_Id Is NOT NULL  	  	  	  	     SELECT @qType = @SingleProductNoTime 
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NULL  	     SELECT @qType = @SingleGroupNoTime
    Else If @Group_Id Is NULL and @Prop_Id Is NOT NULL 	     SELECT @qType = @SingleCharacteristicNoTime 
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NOT NULL  SELECT @qType = @GroupAndPropertyNoTime 
    Else 	  	  	  	  	  	     SELECT @qType = @NoProductNoTime 
  END
Else
  BEGIN
    If @Prod_Id Is NOT NULL  	  	  	  	     SELECT @qType = @SingleProduct 
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NULL  	     SELECT @qType = @SingleGroup 
    Else If @Group_Id Is NULL and @Prop_Id Is NOT NULL 	     SELECT @qType = @SingleCharacteristic 
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NOT NULL  SELECT @qType = @GroupAndProperty 
    Else 	  	  	  	  	  	     SELECT @qType = @NoProduct 
  END
--EndIf
SELECT @SQLString =  ''
-- NOTE: Order By Clause must not be enclosed by parentheses
 	  	  	  	  	  	 
If @qType = @NoProductNoTime
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index 
 	            FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	      ' ORDER BY  Start_Time
 	  	  FOR READ ONLY' 	 
    EXECUTE (@SQlString)
  END
Else If @qType = @NoProduct
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index 
 	      	    FROM  gb_rsum 
 	     	   WHERE  Pu_Id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + '''  AND  ''' + CONVERT(Varchar(50), @End_Time) + '''' +
 	       ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END
Else If @qType = @SingleProductNoTime
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND prod_id = ' + CONVERT(Varchar(50), @Prod_Id) +
 	      ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	 
Else If @qType = @SingleProduct 	 
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  Pu_Id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + ''' AND prod_id = ' + CONVERT(Varchar(50), @Prod_Id) +
 	      ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END
Else If @qType = @SingleGroupNoTime
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	       	   ' AND  Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	       	   ' AND  prod_id IN 
 	  	  	  ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) + ')' +
 	      ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	  	  	  	  	  	  	 
Else If @qType = @SingleGroup
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	       	   ' AND  (Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + ''' )' +
 	       	   ' AND  prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) + ')' +
 	      ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	  	  	  	  	  	  	 
Else If @qType = @SingleCharacteristicNoTime
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	       	   ' AND  Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	       	   ' AND  prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + ' AND c.char_id = ' + CONVERT(Varchar(50), @Char_Id) + ')' + 
 	       ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
Else If @qType = @SingleCharacteristic 	 
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	       	   ' AND  (Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + ''' ) ' +
 	       	   ' AND  prod_id IN 
 	  	  	  ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + ' AND c.char_id = ' + CONVERT(Varchar(50), @Char_Id) + ')' +
 	      ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
Else If @qType = @GroupAndPropertyNoTime
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	       	   ' AND  Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	       	   ' AND  prod_id IN 
 	  	  	 ( SELECT  c.prod_id
 	  	  	     FROM  pu_characteristics c 
 	  	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	  	    WHERE  c.prop_id = ' + CONVERT(Varchar(50), @Prop_Id) +
 	  	  	    ' AND  c.char_id = ' + CONVERT(Varchar(50), @Char_Id) +
 	  	  	    ' AND  g.product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) +
 	  	  	 ')' +
 	      ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
Else If @qType = @GroupAndProperty
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunInfoCalculations_TCursor CURSOR Global SCROLL  
 	     FOR SELECT  Start_Time, Duration, In_Warning, In_Limit, Conf_Index
 	      	    FROM  gb_rsum 
 	     	   WHERE  pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	       	   ' AND  (Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + ''' )' + 
 	       	   ' AND  prod_id IN 
 	  	  	  ( SELECT  C.prod_id
 	  	  	      FROM  pu_characteristics C 
 	  	  	      JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	  	     WHERE  C.prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + 
 	  	  	     ' AND  C.char_id = ' + CONVERT(Varchar(50), @Char_Id) + 
 	  	  	     ' AND  G.product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) +
 	  	  	 ')' +
 	       ' ORDER BY  Start_Time
 	  	 FOR READ ONLY'
    EXECUTE (@SQlString)
  END 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
--EndIf @qType ...
OPEN XLARunInfoCalculations_TCursor  
SELECT @FetchCount = 0
SELECT @SumDurationWeighted = 0
SELECT @TotalDuration = 0
AVERAGE_LOOP:
--                                             1           2             3           4              
    FETCH NEXT FROM XLARunInfoCalculations_TCursor INTO @@Start_Time, @@Duration, @@In_Warning, @@In_Limit, @@Conf_Index
    If (@@Fetch_Status = 0)
 	 BEGIN
 	     SELECT @TempValue = Case @CalcType 
 	  	  	  	     When 1 Then @@Duration 
 	  	  	  	     When 2 then @@In_Warning 
 	  	  	  	     When 3 then @@In_Limit 
 	  	  	  	     When 4 then @@Conf_Index 
 	  	  	  	 End
 	     SELECT @TotalDuration = @TotalDuration + @@Duration
 	     SELECT @SumDurationWeighted = @SumDurationWeighted + @TempValue * @@Duration 
 	     SELECT @FetchCount = @FetchCount + 1
 	     GOTO AVERAGE_LOOP
 	 END
    --EndIf (@@Fetch_Status = 0)
    --Get the Appropriate Average ..
    If @FetchCount = 0 AND (@TotalDuration = 0 OR @CalcType <> 1)
      BEGIN SELECT @Average = 0 END 
    Else
      BEGIN
          If @CalcType = 1  SELECT @Average = @TotalDuration / @FetchCount 
 	   Else              SELECT @Average = @SumDurationWeighted / @TotalDuration 
      END
  --EndIf
--End Of Average Calculation Block
SELECT @FetchCount = 0
SELECT @SumXSqr = 0
STD_DEV_LOOP:
    If @FetchCount = 0
 	 FETCH FIRST FROM XLARunInfoCalculations_TCursor INTO @@Start_Time, @@Duration, @@In_Warning, @@In_Limit, @@Conf_Index
    Else
        --                                           1           2             3           4              
        FETCH NEXT FROM XLARunInfoCalculations_TCursor INTO @@Start_Time, @@Duration, @@In_Warning, @@In_Limit, @@Conf_Index
    --EndIf
    If (@@Fetch_Status = 0)
 	 BEGIN
 	     SELECT @TempValue = Case @CalcType 
 	  	  	  	     When 1 Then @@Duration 
 	  	  	  	     When 2 then @@In_Warning 
 	  	  	  	     When 3 then @@In_Limit 
 	  	  	  	     When 4 then @@Conf_Index 
 	  	  	  	 End
 	     If @FetchCount = 0 	  	 --Initialize @TempMin, @TempMax
 	         BEGIN
 	  	     SELECT @TempMin = @TempValue
 	  	     SELECT @TempMax = @TempMin
 	  	     SELECT @TimeOfMin = @@Start_Time
 	  	     SELECT @TimeOfMax = @@Start_Time 
 	         END
 	     --EndIf
 	     If @TempValue < @TempMin
 	         BEGIN
 	  	     SELECT @TempMin = @TempValue
 	  	     SELECT @TimeOfMin = @@Start_Time
 	         END
 	     --EndIf
 	     If @TempValue > @TempMax
 	         BEGIN
 	  	     SELECT @TempMax = @TempValue
 	  	     SELECT @TimeOfMax = @@Start_Time
 	         END
 	     --EndIf
 	     SELECT @SumXSqr = @SumXSqr + POWER(@Average - @TempValue, 2)      
 	     SELECT @FetchCount = @FetchCount + 1
 	     GOTO STD_DEV_LOOP
 	 END
    --EndIf (@@Fetch_Status = 0)
    --If there is only one row MAX = MIN and standard deviation = 0
    If @FetchCount = 0  	  	 SELECT @StdDeviation = 0
    Else If @FetchCount = 1  	 SELECT @StdDeviation = 0 
    Else  	  	  	 SELECT @StdDeviation = POWER(@SumXSqr / (1.0 * (@FetchCount - 1)),0.5)
  --EndIf
--EndOf TimeOfMax-TimeOfMin-StandardDeviation Block
CLOSE XLARunInfoCalculations_TCursor
DEALLOCATE XLARunInfoCalculations_TCursor
--Note on Total: Duaration (CalcType = 1) use true total duration, the rest use weighted total
SELECT  	   Average = @Average
 	 , Minimum = @TempMin
 	 , Maximum = @TempMax
 	 , Total = Case @CalcType When 1 Then @TotalDuration Else @SumDurationWeighted End
 	 , CountOfRows = @FetchCount
 	 , StandardDeviation = @StdDeviation
 	 , TimeOfMinimum = dbo.fnServer_CmnConvertFromDbTime(@TimeOfMin,@InTimeZone)
 	 , TimeOfMaximum = dbo.fnServer_CmnConvertFromDbTime(@TimeOfMax,@InTimeZone)
