CREATE PROCEDURE dbo.[spXLARunData_Expand_Bak_177] 
 	   @Var_Id  	 Integer
 	 , @Start_Time 	 DateTime
 	 , @End_Time  	 DateTime
 	 , @Pu_Id  	 Integer
 	 , @Prod_Id  	 Integer
 	 , @Group_Id  	 Integer
 	 , @Prop_Id  	 Integer
 	 , @Char_Id  	 Integer
 	 , @TimeSort  	 SmallInt 
  	 , @InTimeZone 	 varchar(200) = null
AS
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
Declare @queryType tinyint
If @Prod_Id Is Not Null And @End_Time is Null
  SELECT @queryType = Case When @TimeSort = 1 then 1 Else 2 end
If @Prod_Id Is Not Null And @End_Time is Not Null
  SELECT @queryType = Case When @TimeSort = 1 then 3 Else 4 end
Else If @Group_Id Is Not Null And @Prop_Id Is Null And @End_Time is Null
  SELECT @queryType = Case When @TimeSort = 1 then 5 Else 6 End
Else If @Group_Id Is Not Null And @Prop_Id Is Null And @End_Time is Not Null
  SELECT @queryType = Case When @TimeSort = 1 then 7 Else 8 End
Else If @Group_Id Is Null and @Prop_Id Is Not Null And @End_Time is Null
  SELECT @queryType = Case When @TimeSort = 1 then 9 Else 10 End
Else If @Group_Id Is Null and @Prop_Id Is Not Null And @End_Time is Not Null
  SELECT @queryType = Case When @TimeSort = 1 then 11 Else 12 End
Else If @Group_Id Is Not Null and @Prop_Id Is Not Null And @End_Time is Null
  SELECT @queryType = Case When @TimeSort = 1 then 13 Else 14 End
Else If @Group_Id Is Not Null and @Prop_Id Is Not Null And @End_Time is Not Null
  SELECT @queryType = Case When @TimeSort = 1 then 15 Else 16 End
Else If @End_Time is Null
  SELECT @queryType = Case When @TimeSort = 1 then 17 Else 18 End
Else If @End_Time is Not Null
  SELECT @queryType = Case When @TimeSort = 1 then 19 Else 20 End
if @QueryType = 17 	  	 --  {[@ProdId,@GroupId,@PropId,@CharId] Null}, @End_Time Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
          LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
      ORDER BY  rs.Start_Time
    END
 if @QueryType = 18 	  	 --  {[@ProdId,@GroupId,@PropId,@CharId] Null}, @End_Time Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 19 	 --  {[@ProdId,@GroupId,@PropId,@CharId] Null}, @End_Time Not Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 20 	 --  {[@ProdId,@GroupId,@PropId,@CharId] Null}, @End_Time Not Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 1 	 -- @Prod_Id Is Not Null, @End_Time is Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 2 	 -- @Prod_Id Is Not Null, @End_Time is Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	   AND  rs.prod_id = @Prod_Id
     ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 3 	 -- @Prod_Id Not Null, @End_Time Not Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 4 	 -- @Prod_Id Not Null, @End_Time Not Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id = @Prod_Id
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 5 	 --  @Group_Id Not Null, @Prop_Id Null, @End_Time Null, @TimeSort =1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id in ( SELECT  g.prod_id FROM product_group_data g WHERE product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 6 	 --  @Group_Id Not Null, @Prop_Id Null, @End_Time Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 7 	 --  @Group_Id Not Null,@Prop_Id Null,@End_Time Not Null,@TimeSort = 1 
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 8 	 --  @Group_Id Not Null,@Prop_Id Null,@End_Time Not Null,@TimeSort <>1 
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 9 	 -- @Group_Id Null, @Prop_Id Not Null, @End_Time Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 10 	 -- @Group_Id Null, @Prop_Id Not Null, @End_Time Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 11 	 -- @Group_Id Null, @Prop_Id Not Null, @End_Time Not Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 12 	 -- @Group_Id Null, @Prop_Id Not Null, @End_Time Not Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY  rs.Start_Time DESC
    END
else if @QueryType = 13 	 -- @Group_Id Not Null, @Prop_Id Not Null, @End_Time Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN 
 	  	 ( SELECT  c.prod_id FROM pu_characteristics c JOIN product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id
 	  	      AND  c.char_id = @Char_Id
 	  	      AND  g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 14 	 -- @Group_Id Not Null, @Prop_Id Not Null, @End_Time Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
  	    AND  rs.Start_Time = @Start_Time
 	    AND  rs.prod_id IN
 	  	 ( SELECT  c.prod_id 
 	  	     FROM  pu_characteristics c 
 	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id
 	  	      AND  c.char_id = @Char_Id
 	  	      AND  g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time DESC
    END
 else if @QueryType = 15 	 -- @Group_Id Not Null, @Prop_Id Not Null, @End_Time Not Null, @TimeSort = 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id in 
 	  	 ( SELECT  c.prod_id 
 	  	     FROM  pu_characteristics c
 	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id
 	  	      AND  c.char_id = @Char_Id
 	  	      AND  g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time
    END
else if @QueryType = 16 	 -- @Group_Id Not Null, @Prop_Id Not Null, @End_Time Not Null, @TimeSort <> 1
    BEGIN
 	 SELECT  [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.Start_Time,@InTimeZone), [End_Time] = dbo.fnServer_CmnConvertFromDbTime(rs.End_Time,@InTimeZone), rs.prod_id, rsd.* 
 	   FROM  gb_rsum rs 
 	   LEFT OUTER JOIN  gb_rsum_data rsd ON rs.rsum_id = rsd.rsum_id 
 	    AND  rsd.var_id = @Var_Id
 	  WHERE  rs.pu_id = @Pu_Id
 	    AND  rs.Start_Time BETWEEN @Start_Time AND @End_Time
 	    AND  rs.prod_id IN 
 	  	 ( SELECT  c.prod_id 
 	  	     FROM  pu_characteristics c
 	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	    WHERE  c.prop_id = @Prop_Id
 	  	      AND  c.char_id = @Char_Id
 	  	      AND  g.product_grp_id = @Group_Id
 	  	 )
      ORDER BY  rs.Start_Time DESC
    END
--EndIf @QueryType
