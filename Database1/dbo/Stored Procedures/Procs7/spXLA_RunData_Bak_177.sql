--spXLA_RunData is modified from spXLARunData_New. ECR #25128: mt/3-9-2003: Changed to handle duplicate Var_Desc in the system
--
CREATE PROCEDURE dbo.[spXLA_RunData_Bak_177] 
 	   @Var_Id  	  	 Integer 	  	 --Variable may be ID or Description
 	 , @Var_Desc 	  	 Varchar(50) 	 --
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @NeedProduct 	  	 TinyInt 	  	 -- 1= include applied product in ResultSet; 0, exclude
 	 , @TimeSort  	  	 SmallInt 
 	 , @DecimalSep 	  	 varchar(1)= NULL 	 --Added: TFS 24548
 	 , @InTimeZone 	 varchar(200) = null
AS
DECLARE @Pu_Id  	  	  	  	 Integer
DECLARE @Data_Type_Id 	  	  	 Integer
DECLARE @queryType 	  	  	 TinyInt
DECLARE @SingleProductNOEndAscend 	 TinyInt -- 1
DECLARE @SingleProductNOEndDescend 	 TinyInt -- 2
DECLARE @SingleProductYesEndAscend 	 TinyInt -- 3
DECLARE @SingleProductYesEndDescend 	 TinyInt -- 4
DECLARE @GroupNOEndAscend 	  	 TinyInt -- 5
DECLARE @GroupNOEndDescend 	  	 TinyInt -- 6
DECLARE @GroupYesEndAscend 	  	 TinyInt -- 7
DECLARE @GroupYesEndDescend 	  	 TinyInt -- 8
DECLARE @CharacteristicNOEndAscend 	 TinyInt -- 9 
DECLARE @CharacteristicNOEndDescend 	 TinyInt -- 10
DECLARE @CharacteristicYesEndAscend 	 TinyInt -- 11
DECLARE @CharacteristicYesEndDescend 	 TinyInt -- 12
DECLARE @GroupAndPropertyNOEndAscend 	 TinyInt -- 13 
DECLARE @GroupAndPropertyNOEndDescend 	 TinyInt -- 14
DECLARE @GroupAndPropertyYesEndAscend 	 TinyInt -- 15 
DECLARE @GroupAndPropertyYesEndDescend 	 TinyInt -- 16
DECLARE @NOProductNOEndAscend 	  	 TinyInt -- 17 
DECLARE @NOProductNOEndDescend 	  	 TinyInt -- 18
DECLARE @NOProductYesEndAscend 	  	 TinyInt -- 19 
DECLARE @NOProductYesEndDescend 	  	 TinyInt -- 20
 	 --For internal use
DECLARE @CountOfVariables               Integer
SELECT @SingleProductNOEndAscend  	 = 1
SELECT @SingleProductNOEndDescend  	 = 2
SELECT @SingleProductYesEndAscend  	 = 3
SELECT @SingleProductYesEndDescend  	 = 4
SELECT @GroupNOEndAscend  	  	 = 5
SELECT @GroupNOEndDescend  	  	 = 6
SELECT @GroupYesEndAscend  	  	 = 7
SELECT @GroupYesEndDescend  	  	 = 8
SELECT @CharacteristicNOEndAscend  	 = 9
SELECT @CharacteristicNOEndDescend 	 = 10
SELECT @CharacteristicYesEndAscend  	 = 11
SELECT @CharacteristicYesEndDescend  	 = 12
SELECT @GroupAndPropertyNOEndAscend  	 = 13
SELECT @GroupAndPropertyNOEndDescend  	 = 14
SELECT @GroupAndPropertyYesEndAscend  	 = 15
SELECT @GroupAndPropertyYesEndDescend  	 = 16
SELECT @NOProductNOEndAscend  	  	 = 17
SELECT @NOProductNOEndDescend  	  	 = 18
SELECT @NOProductYesEndAscend  	  	 = 19
SELECT @NOProductYesEndDescend  	  	 = 20
--Get Variable Information first
SELECT @Data_Type_Id  	 = -1
SELECT @Pu_Id  	  	 = -1
If @DecimalSep Is NULL SELECT @DecimalSep = '.' 
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	  	 --NO variable SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --We have Var_Id
  BEGIN
    SELECT @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE Var_Id = @Var_Id 
    SELECT @CountOfVariables = @@ROWCOUNT
    if @CountOfVariables = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	  	 --variable specified NOT FOUND
        RETURN
      END
    --EndIf: count = 0
  END
Else --We have Var_Desc
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id FROM variables v WHERE Var_Desc = @Var_Desc
    SELECT @CountOfVariables = @@ROWCOUNT
    If @CountOfVariables <> 1
      BEGIN
        If @CountOfVariables = 0
          SELECT [ReturnStatus] = -30 	  	 --variable specified NOT FOUND
        Else
          SELECT [ReturnStatus] = -33 	  	 --DUPLICATE FOUND for var_desc
        --EndIf:Count = 0
        RETURN
      END
    --EndIf:    
  END
--EndIf: Both @VarId and @Var_Desc NULL
If @Pu_Id = -1 OR @Data_Type_Id = -1 
  RETURN 	  	 --ResultSet.Fields.Count = 0 indicates to Add-In "Variable specified not found"
--EndIf
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
--
--Deal with Original Product As Filter
--
If @Prod_Id Is NOT NULL 	  	  	  	  	 --Single Product
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @SingleProductNOEndAscend Else @SingleProductNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @SingleProductYesEndAscend Else @SingleProductYesEndDescend End
    --EndIf
  END  
Else If @Group_Id Is NOT NULL AND @Prop_Id is NULL 	 --Group Only
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupNOEndAscend Else @GroupNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupYesEndAscend Else @GroupYesEndDescend End
    --EndIf
  END  
Else If @Prop_Id Is NOT NULL AND @Group_Id is NULL 	 --Characteristic
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @CharacteristicNOEndAscend Else @CharacteristicNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @CharacteristicYesEndAscend Else @CharacteristicYesEndDescend End
    --EndIf
Else If @Prop_Id Is NOT NULL AND @Group_Id is not NULL 	 --Group And Property
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupAndPropertyNOEndAscend Else @GroupAndPropertyNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupAndPropertyYesEndAscend Else @GroupAndPropertyYesEndDescend End
    --EndIf
  END  
Else 	  	  	  	  	  	  	 --No Product Information 	  	  	  	  	  	 
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @NOProductNOEndAscend Else @NOProductNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @NOProductYesEndAscend Else @NOProductYesEndDescend End
    --EndIf
  END  
--EndIf
If @NeedProduct = 1 GOTO DO_INCLUDE_PRODUCT_CODE_SQL
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @QueryType = @NOProductNOEndAscend  	  	  	 --17
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
      ORDER BY  rs.Start_Time
    END
 if @QueryType = @NOProductNOEndDescend 	  	  	 --18
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @NOProductYesEndAscend 	  	 --19
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @NOProductYesEndDescend 	  	 --20
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @SingleProductNOEndAscend 	  	 --1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @SingleProductNOEndDescend 	  	 --2
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	   AND  rs.prod_id = @Prod_Id
     ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @SingleProductYesEndAscend 	  	 --3
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
  rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
 	 , Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @SingleProductYesEndDescend 	 --4
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @GroupNOEndAscend 	  	  	 --5
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id in ( SELECT  g.prod_id FROM product_group_data g WHERE product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @GroupNOEndDescend 	  	  	 --6
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @GroupYesEndAscend 	  	  	 --7
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @GroupYesEndDescend 	  	 --8
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @CharacteristicNOEndAscend 	  	 --9
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @CharacteristicNOEndDescend 	 --10
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @CharacteristicYesEndAscend 	 --11
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @CharacteristicYesEndDescend 	 --12
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @GroupAndPropertyNOEndAscend 	 --13
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN 
 	  	 ( SELECT  c.prod_id FROM pu_characteristics c JOIN product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @GroupAndPropertyNOEndDescend 	 --14
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN
 	  	 ( SELECT  c.prod_id 
 	  	     FROM  pu_characteristics c 
 	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time DESC
    END
Else If @QueryType = @GroupAndPropertyYesEndAscend 	 --15
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id in 
 	  	 ( SELECT  c.prod_id 
 	  	     FROM  pu_characteristics c
 	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time
    END
Else If @QueryType = @GroupAndPropertyYesEndDescend 	 --16
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, 
 	   rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id IN 
 	  	 ( SELECT  c.prod_id 
 	  	     FROM  pu_characteristics c
 	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time DESC
    END
--EndIf @QueryType
GOTO EXIT_PROCEDURE
DO_INCLUDE_PRODUCT_CODE_SQL:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @QueryType = @NOProductNOEndAscend       --17
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
      ORDER BY  rs.Start_Time
    END
  Else if @QueryType = @NOProductNOEndDescend     --18
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @NOProductYesEndAscend   --19
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @NOProductYesEndDescend    --20
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY  rs.Start_Time DESC
    End
  Else If @QueryType = @SingleProductNOEndAscend    --1
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time
    End
  Else If @QueryType = @SingleProductNOEndDescend   --2
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
          AND  rs.prod_id = @Prod_Id
           ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @SingleProductYesEndAscend   --3
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @SingleProductYesEndDescend  --4
      BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @GroupNOEndAscend      --5
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id in ( SELECT  g.prod_id FROM product_group_data g WHERE product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @GroupNOEndDescend     --6
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @GroupYesEndAscend     --7
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @GroupYesEndDescend    --8
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @CharacteristicNOEndAscend   --9
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @CharacteristicNOEndDescend  --10
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @CharacteristicYesEndAscend  --11
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @CharacteristicYesEndDescend --12
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @GroupAndPropertyNOEndAscend --13
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id IN
          ( SELECT  c.prod_id FROM pu_characteristics c JOIN product_group_data g ON c.prod_id = g.prod_id
             WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
          )
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @GroupAndPropertyNOEndDescend  --14
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time = @Start_Time
           AND  rs.prod_id IN
          ( SELECT  c.prod_id
              FROM  pu_characteristics c
              JOIN  product_group_data g ON c.prod_id = g.prod_id
             WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
          )
      ORDER BY  rs.Start_Time DESC
    END
  Else If @QueryType = @GroupAndPropertyYesEndAscend  --15
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id in
          ( SELECT  c.prod_id
              FROM  pu_characteristics c
              JOIN  product_group_data g ON c.prod_id = g.prod_id
             WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
          )
      ORDER BY  rs.Start_Time
    END
  Else If @QueryType = @GroupAndPropertyYesEndDescend --16
    BEGIN
        SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, p.Prod_Code, 
          rsd.Conf_Index
  ,rsd.Cpk
  ,rsd.In_Limit
  ,rsd.In_Warning
  ,rsd.Maximum
  ,rsd.Minimum
  ,rsd.Num_Values
  ,rsd.RSum_Id
  ,rsd.StDev
  , [Value] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(rsd.Value, '.', @DecimalSep) Else rsd.Value End
  ,rsd.Var_Id
  ,rsd.Cp
  ,rsd.Pp
  ,rsd.Ppk
, Data_Type_Id = @Data_Type_Id
          FROM  gb_rsum rs
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id AND rsd.var_id = @Var_Id
          JOIN  Products p ON p.Prod_Id = rs.Prod_Id
         WHERE  rs.pu_id = @Pu_Id
           AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND  rs.prod_id IN
          ( SELECT  c.prod_id
              FROM  pu_characteristics c
              JOIN  product_group_data g ON c.prod_id = g.prod_id
             WHERE  c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
          )
      ORDER BY  rs.Start_Time DESC
    END
  --EndIf @QueryType
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
