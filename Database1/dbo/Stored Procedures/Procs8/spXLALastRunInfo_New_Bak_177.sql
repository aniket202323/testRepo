--spXLALastRunInfo_New (mt/1-3-2002) is modified from spXLALastRunInfo_Expand. Changes are:
--  (1) Production Unit can take ID or Description. 
--  (2) Production Unit is verified in SP, which returns no resultset, ResultSet.Fields.Count = 0 if
--      input production unit information is invalid.
--  (3) Prodcuct Code, if asked for, is included in the resultSet.
--
CREATE PROCEDURE dbo.[spXLALastRunInfo_New_Bak_177] 
 	   @Pu_Id  	  	 Integer
 	 , @Pu_Desc 	  	 Varchar(50) = NULL
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @NeedProductCode 	 TinyInt 	  	 --0=don't need; 1=need it
 	 , @InTimeZone 	 varchar(200) = null
AS
DECLARE @ProductionUnitRowCount 	 Integer,
 	  	 @MaxEndTime 	 DateTime
--Verify Production Unit Information first
SELECT @ProductionUnitRowCount 	 = 0
If @Pu_Desc Is NOT NULL
  BEGIN  
    SELECT @Pu_Id = Pu_Id FROM Prod_Units WHERE Pu_Desc = @Pu_Desc
    SELECT @ProductionUnitRowCount = @@ROWCOUNT
  END
Else
  BEGIN
    SELECT @Pu_Desc = Pu_Desc FROM Prod_Units WHERE Pu_Id = @Pu_Id
    SELECT @ProductionUnitRowCount = @@ROWCOUNT
  END
--EndIf
If @ProductionUnitRowCount = 0 RETURN 	 --RecordSet's field count = 0 to indicate "Production Unit Specified NOT Found"
--EndIf
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
DECLARE @queryType 	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
If @Prod_Id Is Not Null  	  	  	  	 SELECT @queryType = @SingleProduct
Else If @Group_Id Is Not Null and @Prop_Id Is Null  	 SELECT @queryType = @Group
Else If @Group_Id Is Null and @Prop_Id Is Not Null  	 SELECT @queryType = @Characteristic
Else If @Group_Id Is Not Null and @Prop_Id Is Not Null 	 SELECT @queryType = @GroupAndProperty
Else  	  	  	  	  	  	  	 SELECT @queryType = @NoProductSpecified
--EndIf
If @queryType = @NoProductSpecified 	 --5
BEGIN
  SELECT @MaxEndTime =  MAX(End_Time) 
  FROM gb_rsum WHERE Pu_Id = @PU_Id 
END
Else If @queryType = @SingleProduct 	 --1
BEGIN
  SELECT @MaxEndTime =  MAX(End_Time) 
  FROM gb_rsum WHERE Pu_Id = @PU_Id AND Prod_Id = @Prod_Id
END
Else If @queryType = @Group 	  	 --2
BEGIN
  SELECT @MaxEndTime =  MAX(End_Time) 
  FROM gb_rsum 
  WHERE Pu_Id = @PU_Id
     AND Prod_Id IN ( SELECT g.Prod_Id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
END
Else If @queryType = @Characteristic 	 --3
BEGIN
   SELECT @MaxEndTime =  MAX(End_Time) 
   FROM gb_rsum 
   WHERE Pu_Id = @PU_Id
     AND Prod_Id IN ( SELECT c.Prod_Id FROM pu_characteristics c WHERE c.Prop_Id = @Prop_Id AND c.char_id = @Char_Id )
END
Else If @queryType = @GroupAndProperty 	 --4
BEGIN
   SELECT @MaxEndTime = MAX(End_Time) 
    FROM gb_rsum 
    WHERE Pu_Id = @PU_Id
          AND Prod_Id IN 
         ( SELECT c.Prod_Id
             FROM pu_characteristics c 
             JOIN product_group_data g on c.Prod_Id = g.Prod_Id
            WHERE c.Prop_Id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
          )
END
If @NeedProductCode = 0 
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	   FROM  gb_rsum
 	 WHERE Pu_Id = @PU_Id AND End_Time = @MaxEndTime
ELSE
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone),
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone) 
 	   FROM  gb_rsum rs
      JOIN Products p ON p.Prod_Id = rs.Prod_Id
 	 WHERE rs.Pu_Id = @PU_Id AND rs.End_Time = @MaxEndTime
