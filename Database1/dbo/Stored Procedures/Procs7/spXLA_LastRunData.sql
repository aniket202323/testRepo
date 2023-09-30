--spXLA_LastRunData is modified from spXLALastRunData_New. ECR #25128: mt/3-9-2003: Changes include handling of duplicate Var_Desc
--
CREATE PROCEDURE dbo.spXLA_LastRunData  
 	   @Var_Id  	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @NeedProductCode 	 TinyInt 	  	 -- 1 = Want Original(and Applied) Products in ResultSet; 0 = don't want
 	 , @DecimalSep 	  	 varchar(1)= NULL 	 --Added: TFS 24548
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
DECLARE @Pu_Id  	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Needed for internal use
DECLARE @CountOf_Variables      Integer
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Define querty types
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
If @DecimalSep Is NULL SELECT @DecimalSep = '.' 
--Get Variable Information first
SELECT @Data_Type_Id = -1
SELECT @Pu_Id = -1
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	  	 --NO variable SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --We have Var_Id
  BEGIN
    SELECT @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE Var_Id = @Var_Id 
    SELECT @CountOf_Variables = @@ROWCOUNT
    If @CountOf_Variables = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	  	 --variable SPECIFIED NOT FOUND
        RETURN
      END
    --EndIf:Var not found
  END
Else --We have Var_Desc
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id FROM variables v WHERE Var_Desc = @Var_Desc
    SELECT @CountOf_Variables = @@ROWCOUNT
    If @CountOf_Variables <> 1
      BEGIN
        If @CountOf_Variables = 0
          SELECT [ReturnStatus] = -30 	  	 --variable SPECIFIED NOT FOUND
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	  	 --DUPLICATE FOUND for this Var_Desc
        --EndIf
        RETURN
      END
    --EndIf:count <> 1
  END
--EndIf: Both @Var_Id & @Var_Desc NULL
If @Pu_Id = -1 OR @Data_Type_Id = -1
  RETURN                      --RecordSet.Fields.Count = 0 indicates "Variable specified NOT found"
--EndIf
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
If @Prod_Id Is NOT NULL  	  	  	  	 SELECT @QueryType = @SingleProduct 	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL  	 SELECT @QueryType = @Group 	         --2
Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL  	 SELECT @QueryType = @Characteristic 	 --3
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else  	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
If @NeedProductCode = 1 GOTO DO_ORIGINAL_PRODUCT_WITH_PRODUCT_CODE
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
    , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
    , rs.Prod_Id, 
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
      FROM gb_rsum rs 
      JOIN gb_rsum_data rsd on rsd.rsum_id = rs.rsum_id 
     WHERE rs.Pu_Id = @Pu_Id 
       AND rsd.Var_Id = @Var_Id
       AND rs.Start_Time = ( SELECT MAX(Start_Time) FROM gb_rsum WHERE Pu_Id = @Pu_Id )
    END
Else If @QueryType = @SingleProduct 	 --1
  BEGIN
    SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
    , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
    , rs.Prod_Id, 
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
      JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
     WHERE  rs.Pu_Id =  @Pu_Id 
       AND  rsd.Var_Id =  @Var_Id 
       AND  rs.Start_Time = ( SELECT MAX(Start_Time) FROM gb_rsum WHERE Pu_Id =  @Pu_Id AND Prod_Id =  @Prod_Id )
  END
Else If @QueryType = @Group 	  	 --2
  BEGIN
    SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
    , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
    , rs.Prod_Id, 
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
      JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
     WHERE  rs.Pu_Id = @Pu_Id
       AND  rsd.Var_Id = @Var_Id
       AND  rs.Start_Time = 
            (  SELECT MAX(Start_Time) 
                 FROM gb_rsum
                WHERE Pu_Id = @Pu_Id
                  AND Prod_Id IN ( SELECT g.Prod_Id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
            )
    END
Else If @QueryType = @GroupAndProperty 	 --3
  BEGIN
    SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
    , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
    , rs.Prod_Id, 
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
      JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
     Where  rs.Pu_Id = @Pu_Id
       AND  rsd.Var_Id = @Var_Id
       AND  rs.Start_Time = 
            ( SELECT MAX(Start_Time) 
                FROM gb_rsum 
               WHERE Pu_Id = @Pu_Id
                 AND Prod_Id IN ( SELECT c.Prod_Id 
                                    FROM pu_characteristics c 
                                   WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id 
                                )
            )
  END
Else If @QueryType = @Characteristic 	 --4
  BEGIN
    SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
    , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
    , rs.Prod_Id, 
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
      JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
     WHERE  rs.Pu_Id = @Pu_Id 
       AND  rsd.Var_Id = @Var_Id
       AND  rs.Start_Time = 
            ( SELECT MAX(Start_Time) 
                FROM gb_rsum 
               WHERE Pu_Id =  @Pu_Id
                 AND Prod_Id IN ( SELECT C.Prod_Id 
                                    FROM pu_characteristics C JOIN product_group_data G ON C.Prod_Id = G.Prod_Id
                                   WHERE  prop_id = @Prop_Id AND  char_id = @Char_Id AND product_grp_id = @Group_Id
                                )
            )
    END
--EndIf @QueryType
GOTO EXIT_PROCEDURE
DO_ORIGINAL_PRODUCT_WITH_PRODUCT_CODE:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @QueryType = @NoProductSpecified   --5
    BEGIN
      SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone,
       [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone, 
       rs.Prod_Id,
        p.Prod_Code, 
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
        FROM gb_rsum rs
        JOIN gb_rsum_data rsd on rsd.rsum_id = rs.rsum_id
        JOIN Products p ON p.Prod_Id = rs.Prod_Id
       WHERE rs.Pu_Id = @Pu_Id
         AND rsd.Var_Id = @Var_Id
         AND rs.Start_Time = ( SELECT MAX(Start_Time) FROM gb_rsum WHERE Pu_Id = @Pu_Id )
      END
  Else If @QueryType = @SingleProduct    	 --1
    BEGIN
      SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
      , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
      , rs.Prod_Id
      , p.Prod_Code, 
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
        JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id
        JOIN Products p ON p.Prod_Id = rs.Prod_Id
       WHERE  rs.Pu_Id =  @Pu_Id
         AND  rsd.Var_Id =  @Var_Id
         AND  rs.Start_Time = ( SELECT MAX(Start_Time) FROM gb_rsum WHERE Pu_Id =  @Pu_Id AND Prod_Id =  @Prod_Id )
    END
  Else If @QueryType = @Group    	  	 --2
    BEGIN
      SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
      , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
      , rs.Prod_Id
      , p.Prod_Code, 
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
        JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id
        JOIN Products p ON p.Prod_Id = rs.Prod_Id
       WHERE  rs.Pu_Id = @Pu_Id
         AND  rsd.Var_Id = @Var_Id
         AND  rs.Start_Time =
              (  SELECT MAX(Start_Time)
                   FROM gb_rsum
                  WHERE Pu_Id = @Pu_Id
                    AND Prod_Id IN ( SELECT g.Prod_Id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
              )
      END
  Else If @QueryType = @GroupAndProperty 	 --3
    BEGIN
      SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
      , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
      , rs.Prod_Id
      , p.Prod_Code, 
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
        JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id
        JOIN Products p ON p.Prod_Id = rs.Prod_Id
       WHERE  rs.Pu_Id = @Pu_Id
         AND  rsd.Var_Id = @Var_Id
         AND  rs.Start_Time =
              ( SELECT MAX(Start_Time)
                  FROM gb_rsum
                 WHERE Pu_Id = @Pu_Id
                   AND Prod_Id IN ( SELECT c.Prod_Id
                                      FROM pu_characteristics c
                                     WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id
                                  )
              )
    END
  Else If @QueryType = @Characteristic     	 --4
    BEGIN
      SELECT [Start_Time] = rs.Start_Time at time zone @DBTz at time zone @InTimeZone
      , [End_Time] = rs.End_Time at time zone @DBTz at time zone @InTimeZone
      , rs.Prod_Id
      , p.Prod_Code, 
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
        JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id
        JOIN Products p ON p.Prod_Id = rs.Prod_Id
       WHERE  rs.Pu_Id = @Pu_Id
         AND  rsd.Var_Id = @Var_Id
         AND  rs.Start_Time =
              ( SELECT MAX(Start_Time)
                  FROM gb_rsum
                 WHERE Pu_Id =  @Pu_Id
                   AND Prod_Id IN ( SELECT C.Prod_Id
                                      FROM pu_characteristics C JOIN product_group_data G ON C.Prod_Id = G.Prod_Id
                                     WHERE  prop_id = @Prop_Id AND  char_id = @Char_Id AND product_grp_id = @Group_Id
                                  )
              )
      END
  --EndIf @QueryType
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
