--spXLA_RunDataCalc replaces spXLARunDataCalc_New. ECR #25128: mt/3-9-2003: Changed to handle duplicate Var_desc
--
CREATE PROCEDURE dbo.[spXLA_RunDataCalc_Bak_177] 
 	   @Var_Id  	 Integer
 	 , @Var_Desc 	 Varchar(50) = NULL
 	 , @Start_Time  	 datetime
 	 , @End_Time  	 datetime
 	 , @Prod_Id  	 Integer
 	 , @Group_Id  	 Integer
 	 , @Prop_Id  	 Integer
 	 , @Char_Id  	 Integer
 	 , @CalcType 	 TinyInt
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	 --Local identifiers
DECLARE 	 @Pu_Id  	  	  	  	 Integer
DECLARE @VariableCount 	  	  	 Integer
DECLARE @Data_Type_Id 	  	  	 Integer
 	 --"Query Types" Identifiers
DECLARE @qType  	  	  	  	 Tinyint
DECLARE @SingleProductNoEndTime 	  	 TinyInt 	 --1
DECLARE @SingleProduct 	  	  	 TinyInt 	 --2
DECLARE @SingleGroupNoEndTime 	  	 TinyInt 	 --3
DECLARE @SingleGroup 	  	  	 TinyInt 	 --4
DECLARE @SingleCharacteristicNoEndTime 	 TinyInt 	 --5
DECLARE @SingleCharacteristic 	  	 TinyInt 	 --6
DECLARE @GroupAndPropertyNoEndTime 	 TinyInt 	 --7
DECLARE @GroupAndProperty 	  	 TinyInt 	 --8
DECLARE @AnyProductNoEndTime 	  	 TinyInt 	 --9
DECLARE @AnyProduct 	  	  	 TinyInt 	 --10
--First verify that input variable is valid.
SELECT @VariableCount = 0
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	  	 --variable NOT SPECIFIED
    RETURN
  END
If @Var_Desc Is NULL --we have Var_Id
  BEGIN
    SELECT @Var_Desc = Var_Desc, @Pu_Id = Pu_Id, @Data_Type_Id = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
    SELECT @VariableCount = @@ROWCOUNT
    If @VariableCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	  	 --variable specified NOT FOUND
        RETURN
      END
    --EndIf: count = 0
  END
Else --we have Var_Desc
  BEGIN
    SELECT @Var_Id = Var_Id, @Pu_Id = Pu_Id, @Data_Type_Id = Data_Type_Id FROM Variables WHERE Var_Desc = @Var_Desc
    SELECT @VariableCount = @@ROWCOUNT
    If @VariableCount <> 1
      BEGIN
        If @VariableCount = 0
          SELECT [ReturnStatus] = -30 	  	 --variable specified NOT FoUND
        Else
          SELECT [ReturnStatus] = -33 	  	 --DUPLICATE FOUND for var_desc
        --EndIf:     
        RETURN
      END
    --EndIf: count <> 1
  END
--EndIf
If ISNUMERIC(@Data_Type_Id) = 0   	 --Non-numeric is illegal data type
  BEGIN 
    SELECT ReturnStatus = -20 	 --Indicates "Illegal Data Type"
    RETURN
  END
--EndIf
SELECT @SingleProductNoEndTime 	  	 = 1
SELECT @SingleProduct 	  	  	 = 2
SELECT @SingleGroupNoEndTime 	  	 = 3
SELECT @SingleGroup 	  	  	 = 4
SELECT @SingleCharacteristicNoEndTime 	 = 5
SELECT @SingleCharacteristic 	  	 = 6
SELECT @GroupAndPropertyNoEndTime 	 = 7
SELECT @GroupAndProperty 	  	 = 8
SELECT @AnyProductNoEndTime 	  	 = 9
SELECT @AnyProduct 	  	  	 = 10
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic  	 (Single Characteristic)
--   Group Only 	  	  	  	 (Single Group)
--   Group, Propery, AND Characteristic 	 (Group and Property)
--   Product Only 	  	  	 (Single Product)
--   No Product Information At All 	 (Any Product Info)
If @End_Time Is NULL
  BEGIN
    If @Prod_Id Is NOT NULL  	  	  	  	     SELECT @qType = @SingleProductNoEndTime
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NULL  	     SELECT @qType = @SingleGroupNoEndTime
    Else If @Group_Id Is NULL and @Prop_Id Is NOT NULL 	     SELECT @qType = @SingleCharacteristicNoEndTime
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NOT NULL  SELECT @qType = @GroupAndPropertyNoEndTime
    Else 	  	  	  	  	  	     SELECT @qType = @AnyProductNoEndTime
  END
Else
  BEGIN
    If @Prod_Id Is NOT NULL  	  	  	  	     SELECT @qType = @SingleProduct
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NULL  	     SELECT @qType = @SingleGroup
    Else If @Group_Id Is NULL and @Prop_Id Is NOT NULL 	     SELECT @qType = @SingleCharacteristic
    Else If @Group_Id Is NOT NULL and @Prop_Id Is NOT NULL  SELECT @qType = @GroupAndProperty
    Else 	  	  	  	  	  	     SELECT @qType = @AnyProduct
  END
--EndIf @End_Time Is NULL
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
DECLARE @@Duration 	  	 Real
DECLARE @@Start_Time  	  	 DateTime
DECLARE @@Minimum 	  	 Real
DECLARE @@Maximum 	  	 Real
DECLARE @@Cpk 	  	  	 Real
DECLARE @@StdDev 	  	 Real
DECLARE @@In_Warning 	  	 Real
DECLARE @@In_Limit 	  	 Real
DECLARE @@Conf_Index 	  	 Real
DECLARE @@Num_Values 	  	 Real
DECLARE @@Value 	  	  	 Real
SELECT @SQLString =  ''
If @qType = @AnyProductNoEndTime --  {[@ProdId, @GroupId, @PropId, @CharId] are NULL}, @End_Time NULL
  BEGIN
    SELECT @SQLString = @SQLString + 
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL 
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values 
 	    	     FROM  gb_rsum RS
 	    	     JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) +
 	   	  ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	        + ') FOR READ ONLY'
    EXECUTE (@SQlString)
  END
Else If @qType = @AnyProduct --{[@ProdId, @GroupId, @PropId, @CharId] are NULL}, @End_Time NOT NULL
  BEGIN
    SELECT @SQLString = 
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL 
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	              FROM  gb_rsum RS
 	              JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) +
 	           ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + '''' +
 	          ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @SingleProductNoEndTime -- @Prod_Id Is NOT NULL, @End_Time is NULL
  BEGIN
    SELECT @SQLString = @SQLString +  
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL 
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	              FROM  gb_rsum RS
 	              JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id)  +
 	           ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''  AND prod_id = ' + CONVERT(Varchar(50), @Prod_Id) + 
 	          ') FOR READ ONLY '
    EXECUTE (@SQLString)
  END
Else If @qType = @SingleProduct -- @Prod_Id NOT NULL, @End_Time NOT NULL
  BEGIN
    SELECT @SQLString = @SQLString +  
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL 
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) + 
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + ' AND Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + ''' AND prod_id = ' + CONVERT(Varchar(50), @Prod_Id) + 
 	          ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @SingleGroupNoEndTime --  @Group_Id NOT NULL, @Prop_Id NULL, @End_Time NULL 
  BEGIN
    SELECT @SQLString = @SQLString +  
 	 'DECLARE XLARunDataCalc_TCursor  CURSOR Global SCROLL
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS 
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) +
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + 
 	  	     ' AND  Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	  	     ' AND  prod_id in 
 	  	  	    ( SELECT  prod_id
 	  	      	        FROM  product_group_data 
 	  	     	       WHERE  product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) +
 	                  ' ) ' +
 	           ' ) FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @SingleGroup --  @Group_Id NOT NULL, @Prop_Id NULL, @End_Time NOT NULL 
  BEGIN
    SELECT @SQLString = @SQLString +  
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL 
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) + 
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + 
 	     	     ' AND  Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + '''  AND ''' + CONVERT(Varchar(50), @End_Time) + '''' +
 	     	     ' AND  prod_id in 
 	  	  	    ( SELECT  prod_id
 	  	      	        FROM  product_group_data 
 	  	     	       WHERE  product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) + 
 	  	  	  ' )' +
 	           ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @SingleCharacteristicNoEndTime 	 -- @Group_Id NULL, @Prop_Id NOT NULL, @End_Time NULL
  BEGIN
    SELECT @SQLString = @SQLString +  
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL  
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) + 
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) +
 	     	    '  AND  Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	     	    '  AND  prod_id in 
 	  	  	   ( SELECT  prod_id
 	  	      	       FROM  pu_characteristics 
 	  	     	      WHERE  prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + 
 	  	       	      ' AND  char_id = ' + CONVERT(Varchar(50), @Char_Id) + 
 	  	  	 ' )' +
 	            ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @SingleCharacteristic -- @Group_Id NULL, @Prop_Id NOT NULL, @End_Time NOT NULL
  BEGIN
    SELECT @SQLString = @SQLString +  
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL  
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS 
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) + 
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + 
 	     	     ' AND  Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + '''' +
 	     	     ' AND  prod_id in 
 	  	  	    ( SELECT  prod_id
 	  	      	        FROM  pu_characteristics 
 	  	     	       WHERE  prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + 
 	  	       	       ' AND  char_id = ' + CONVERT(Varchar(50), @Char_Id) + 
 	  	  	  ' )' +
 	            ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @GroupAndPropertyNoEndTime -- @Group_Id NOT NULL, @Prop_Id NOT NULL, @End_Time NULL
  BEGIN
    SELECT @SQLString = @SQLString +   	 
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL  
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS 
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND  RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) + 
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + 
 	     	     ' AND  Start_Time = ''' + CONVERT(Varchar(50), @Start_Time) + '''' +
 	     	     ' AND  prod_id IN 
 	  	  	    ( SELECT  C.prod_id
 	  	      	        FROM  pu_characteristics C 
 	  	      	        JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	     	       WHERE  prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + 
 	  	       	       ' AND  char_id = ' + CONVERT(Varchar(50), @Char_Id) + 
 	  	  	       ' AND  product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) + 
 	  	  	  ' )' +
 	           ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
Else If @qType = @GroupAndProperty 	  	  	 -- @Group_Id NOT NULL, @Prop_Id NOT NULL, @End_Time NOT NULL
  BEGIN
    SELECT @SQLString = @SQLString +   	 
 	 'DECLARE XLARunDataCalc_TCursor CURSOR Global SCROLL  
 	       FOR (SELECT  RS.start_time, RS.duration, RSD.Value, RSD.In_Warning, RSD.In_Limit, RSD.Conf_Index, RSD.StDev, RSD.Cpk, RSD.Minimum, RSD.Maximum, RSD.Num_Values
 	    	      FROM  gb_rsum RS 
 	    	      JOIN  gb_rsum_data RSD ON RSD.rsum_id = RS.rsum_id AND RSD.var_id = ' + CONVERT(Varchar(50), @Var_Id) + 
 	   	   ' WHERE  RS.pu_id = ' + CONVERT(Varchar(50), @Pu_Id) + 
 	     	     ' AND  Start_Time BETWEEN ''' + CONVERT(Varchar(50), @Start_Time) + ''' AND ''' + CONVERT(Varchar(50), @End_Time) + '''' +
 	     	     ' AND  prod_id IN 
 	  	  	    ( SELECT  C.prod_id
 	  	      	        FROM  pu_characteristics C 
 	  	      	        JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	     	       WHERE  prop_id = ' + CONVERT(Varchar(50), @Prop_Id) + 
 	  	       	       ' AND  char_id = ' + CONVERT(Varchar(50), @Char_Id) + 
 	  	       	       ' AND  product_grp_id = ' + CONVERT(Varchar(50), @Group_Id) +
 	  	  	  ' )' + 
 	            ') FOR READ ONLY'
    EXECUTE (@SQLString)
  END
--EndIf @QueryType..
OPEN XLARunDataCalc_TCursor  
SELECT @FetchCount = 0
SELECT @SumDurationWeighted = 0
SELECT @TotalDuration = 0
AVERAGE_LOOP:
--                                                         1        2            3           4              5         6      7          8          9
    FETCH NEXT FROM XLARunDataCalc_TCursor INTO @@Start_Time, @@Duration, @@Value, @@In_Warning, @@In_Limit, @@Conf_Index,  @@StdDev, @@Cpk, @@Minimum, @@Maximum, @@Num_Values
    If (@@Fetch_Status = 0)
 	 BEGIN
 	     SELECT @TempValue = Case @CalcType 
 	  	  	  	     When 1 Then @@Value 
 	  	  	  	     When 2 then @@In_Warning 
 	  	  	  	     When 3 then @@In_Limit 
 	  	  	  	     When 4 then @@Conf_Index 
 	  	  	  	     When 5 Then @@StdDev 
 	  	  	  	     When 6 Then @@Cpk 
 	  	  	  	     When 7 Then @@Minimum 
 	  	  	  	     When 8 Then @@Maximum 
 	  	  	  	     When 9 Then @@Num_Values 
 	  	  	  	 End
 	     SELECT @TotalDuration = @TotalDuration + @@Duration
 	     If @CalcType <> 9 	 
 	  	 SELECT @SumDurationWeighted = @SumDurationWeighted + @TempValue * @@Duration 
 	     Else
 	  	 SELECT @SumDurationWeighted = @SumDurationWeighted + @TempValue
 	   --EndIf
 	     SELECT @FetchCount = @FetchCount + 1
 	     GOTO AVERAGE_LOOP
 	 END
    --EndIf (@@Fetch_Status = 0)
    If @FetchCount > 0 AND @TotalDuration > 0 	 SELECT @Average = @SumDurationWeighted / @TotalDuration 
    Else  	  	  	  	  	 SELECT @Average = 0
--End Of Average Calculation Block
SELECT @FetchCount = 0
SELECT @SumXSqr = 0
STD_DEV_LOOP:
    If @FetchCount = 0
 	 FETCH FIRST FROM XLARunDataCalc_TCursor INTO @@Start_Time, @@Duration, @@Value, @@In_Warning, @@In_Limit, @@Conf_Index,  @@StdDev, @@Cpk, @@Minimum, @@Maximum, @@Num_Values
    Else
--                                                         1        2            3           4              5         6      7          8          9
 	 FETCH NEXT FROM XLARunDataCalc_TCursor INTO @@Start_Time, @@Duration, @@Value, @@In_Warning, @@In_Limit, @@Conf_Index,  @@StdDev, @@Cpk, @@Minimum, @@Maximum, @@Num_Values
    --EndIf
    If (@@Fetch_Status = 0)
 	 BEGIN
 	     SELECT @TempValue = Case @CalcType 
 	  	  	  	     When 1 Then @@Value 
 	  	  	  	     When 2 then @@In_Warning 
 	  	  	  	     When 3 then @@In_Limit 
 	  	  	  	     When 4 then @@Conf_Index 
 	  	  	  	     When 5 Then @@StdDev 
 	  	  	  	     When 6 Then @@Cpk 
 	  	  	  	     When 7 Then @@Minimum 
 	  	  	  	     When 8 Then @@Maximum 
 	  	  	  	     When 9 Then @@Num_Values 
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
CLOSE XLARunDataCalc_TCursor
DEALLOCATE XLARunDataCalc_TCursor
SELECT  	   Average = @Average
 	 , Minimum = @TempMin
 	 , Maximum = @TempMax
 	 , Total = @SumDurationWeighted
 	 , CountOfRows = @FetchCount
 	 , StandardDeviation = @StdDeviation
 	 , TimeOfMinimum = dbo.fnServer_CmnConvertFromDbTime(@TimeOfMin,@InTimeZone)
 	 , TimeOfMaximum = dbo.fnServer_CmnConvertFromDbTime(@TimeOfMax,@InTimeZone) 
