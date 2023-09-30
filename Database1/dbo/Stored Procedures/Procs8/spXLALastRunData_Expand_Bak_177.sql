CREATE PROCEDURE dbo.[spXLALastRunData_Expand_Bak_177]  
 	   @Pu_Id  	 integer
 	 , @Var_Id  	 integer
 	 , @Prod_Id  	 integer
 	 , @Group_Id  	 integer
 	 , @Prop_Id  	 integer
 	 , @Char_Id  	 integer
 	 , @InTimeZone 	 varchar(200) = null
 AS
/*
Joe: 5/25/1010:
NOTE: this does not have the decimal seperator logic in it!! not sure this proc is called. 
Comment from XLA code: 
  'GBGetLastRunData is outdated in current version of Plant Applications Add-In. It remains here for use
  'in some existing reports. LastRunData Dialog will not call this function. mt/1-2-2002
  '
*/
--  DECLARE @tmpSQL1 varchar(255)
--  DECLARE @tmpSQL2 varchar(255)
--  DECLARE @tmpSQL3 varchar(255)
-- INITIALIZE to empty strings so as to prevent "concatenation with NULL" problem
-- MSi/MT/2-28-2001 
--  SELECT @tmpSQL1 = ''
--  SELECT @tmpSQL2 = ''
--  SELECT @tmpSQL3 = ''
 	 ----------------------------------------------------------------
-- 	  	 New Stored Procedure (Dynamic SQL removed) tested 
-- 	  	 9-14-99 (MT) To be determined when to use.        
 	 ----------------------------------------------------------------
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
DECLARE @QueryType TinyInt
If @Prod_Id Is NOT NULL  	  	  	  	 SELECT @QueryType = 1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL  	 SELECT @QueryType = 2
Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL  	 SELECT @QueryType = 3
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL 	 SELECT @QueryType = 4
Else  	  	  	  	  	  	  	 SELECT @QueryType = 5
If @QueryType = 5 	  	  	  	  	 -- ProdId, GroupId, PropId are null
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone)
 	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone)
 	  	  	 , rs.Prod_Id
 	  	  	 , rsd.*  	 
 	   FROM  gb_rsum rs 
 	   JOIN  gb_rsum_data rsd on rsd.rsum_id = rs.rsum_id 
 	  WHERE  rs.Pu_Id = @Pu_Id 
 	    AND  rsd.Var_Id = @Var_Id
 	    AND  rs.Start_Time = ( SELECT max(Start_Time) FROM gb_rsum WHERE Pu_Id = @Pu_Id )
    END
Else If @QueryType = 1 	  	  	  	 -- @Prod_Id Is NOT NULL
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone)
 	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone)
 	  	  	 , rs.Prod_Id
 	  	  	 , rsd.* 
 	   FROM  gb_rsum rs
 	   JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
 	  WHERE  rs.Pu_Id =  @Pu_Id 
 	    AND  rsd.Var_Id =  @Var_Id 
 	    AND  rs.Start_Time = ( SELECT MAX(Start_Time) FROM gb_rsum WHERE Pu_Id =  @Pu_Id AND Prod_Id =  @Prod_Id )
    END
Else If @QueryType = 2 	  	  	  	 -- @Group_Id Is NOT NULL AND @Prop_Id Is NULL
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone)
 	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone)
 	 , rs.Prod_Id, rsd.*
 	   FROM  gb_rsum rs 
 	   JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
 	  WHERE  rs.Pu_Id = @Pu_Id
 	    AND  rsd.Var_Id = @Var_Id
 	    AND  rs.Start_Time = 
 	  	 (  SELECT  MAX(Start_Time) 
 	  	      FROM  gb_rsum
 	  	     WHERE  Pu_Id = @Pu_Id
 	  	       AND  Prod_Id IN ( SELECT g.Prod_Id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
 	  	 )
    END
Else If @QueryType = 3 	  	  	  	 -- @Group_Id Is NULL AND @Prop_Id Is NOT NULL
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone),
 	  [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone),
 	   rs.Prod_Id, rsd.*
 	   FROM  gb_rsum rs 
 	   JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
 	  Where  rs.Pu_Id = @Pu_Id
 	    AND  rsd.Var_Id = @Var_Id
 	    AND  rs.Start_Time = 
 	  	 ( SELECT  max(Start_Time) 
 	  	     FROM  gb_rsum 
 	  	    WHERE  Pu_Id = @Pu_Id
 	  	      AND  Prod_Id IN ( SELECT c.Prod_Id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
 	  	 )
    END
Else If @QueryType = 4 	  	  	  	 -- @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone)
 	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone)
 	 , rs.Prod_Id, rsd.*
 	   FROM  gb_rsum rs 
 	   JOIN  gb_rsum_data rsd ON rsd.rsum_id = rs.rsum_id 
 	  WHERE  rs.Pu_Id = @Pu_Id 
 	    AND  rsd.Var_Id = @Var_Id
 	    AND  rs.Start_Time = 
 	  	 ( SELECT  MAX(Start_Time) 
 	  	     FROM  gb_rsum 
 	  	    WHERE  Pu_Id =  @Pu_Id
 	  	      AND  Prod_Id in 
 	  	  	   ( SELECT  C.Prod_Id
 	  	  	       FROM  pu_characteristics C 
 	  	  	       JOIN  product_group_data G ON C.Prod_Id = G.Prod_Id
 	  	  	      WHERE  prop_id = @Prop_Id
 	  	  	        AND  char_id = @Char_Id
 	  	  	        AND  product_grp_id = @Group_Id
 	  	    	   )
 	  	 )
    END
--EndIf
