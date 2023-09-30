CREATE PROCEDURE dbo.spXLALastRunInfo_Expand 
 	   @PU_Id  	 integer
 	 , @Prod_Id  	 integer
 	 , @Group_Id  	 integer
 	 , @Prop_Id  	 integer
 	 , @Char_Id  	 integer
 	 , @InTimeZone 	 varchar(200) = null
 AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
/*
 	 ----------------------------------------------------------------
 	  	 New Stored Procedure (Dynamic SQL removed) tested 
 	  	 9-14-99 (MT) To be determined when to use.        
 	 ----------------------------------------------------------------
*/
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
DECLARE @queryType tinyint
If @Prod_Id Is Not Null  	  	  	  	 SELECT @queryType = 1
Else If @Group_Id Is Not Null and @Prop_Id Is Null  	 SELECT @queryType = 2
Else If @Group_Id Is Null and @Prop_Id Is Not Null  	 SELECT @queryType = 3
Else If @Group_Id Is Not Null and @Prop_Id Is Not Null 	 SELECT @queryType = 4
Else  	  	  	  	  	  	  	 SELECT @queryType = 5
DECLARE @MaxEndtime DateTime
If @QueryType = 5 	  	 --  {[@ProdId, @GroupId, @PropId, @CharId] are Null}
BEGIN
 	 SELECT @MaxEndtime = MAX(End_Time) FROM gb_rsum WHERE Pu_Id = @PU_Id
END
Else If @QueryType = 1 	 -- @Prod_Id Is Not Null
BEGIN
 	 SELECT @MaxEndtime =  MAX(End_Time) FROM gb_rsum WHERE Pu_Id = @PU_Id AND Prod_Id = @Prod_Id 
END
Else If @QueryType = 2 	 --  @Group_Id Not Null, @Prop_Id Null
BEGIN
 	 SELECT @MaxEndtime =  MAX(End_Time) 
 	  	     FROM  gb_rsum 
 	  	    WHERE  Pu_Id = @PU_Id
 	  	      AND  Prod_Id IN ( SELECT g.Prod_Id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
END
Else If @QueryType = 3 	 -- @Group_Id Null, @Prop_Id Not Null
BEGIN
 	 SELECT @MaxEndtime =  MAX(End_Time) 
 	  	     FROM  gb_rsum 
 	  	    WHERE  Pu_Id = @PU_Id
 	  	      AND  Prod_Id IN ( SELECT c.Prod_Id FROM pu_characteristics c WHERE c.Prop_Id = @Prop_Id AND c.char_id = @Char_Id )
END
Else If @QueryType = 4 	 -- @Group_Id Not Null, @Prop_Id Not Null
BEGIN
 	 SELECT @MaxEndtime =  MAX(End_Time) 
 	  	 FROM  gb_rsum 
 	  	 WHERE  Pu_Id = @PU_Id
 	  	      AND  Prod_Id IN 
 	  	  	  	 ( SELECT  c.Prod_Id
 	  	  	  	     FROM  pu_characteristics c 
 	  	  	  	     JOIN  product_group_data g on c.Prod_Id = g.Prod_Id
 	  	  	  	    WHERE  c.Prop_Id = @Prop_Id
 	  	  	  	      AND  c.char_id = @Char_Id
 	  	  	  	      AND  g.product_grp_id = @Group_Id
 	  	  	  	 )
END
SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
  FROM  gb_rsum
 WHERE  Pu_Id = @PU_Id
   AND  End_Time = @MaxEndtime
