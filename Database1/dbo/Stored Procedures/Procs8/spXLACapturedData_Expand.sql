CREATE PROCEDURE dbo.spXLACapturedData_Expand
 	   @Var_Id 	 Integer
 	 , @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
 	 , @Pu_Id 	 Integer
 	 , @Prod_Id 	 Integer
 	 , @Group_Id 	 Integer
 	 , @Prop_Id 	 Integer
 	 , @Char_Id 	 Integer
 	 , @TimeSort 	 smallint 
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz
IF @Pu_Id Is NUll
 	 SELECT @Pu_Id = PU_Id From Variables Where Var_Id = @Var_Id 
/*
  **************************************************************
  ***** New Stored Procedure (Dynamic SQL removed) tested *****
  ****  9-14-99 (MT) To be determined when to use.        ***** 
  **************************************************************
*/
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
DECLARE @queryType tinyint
If @Prod_Id Is NOT NULL AND @End_Time is NULL 	  	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 1 Else 2 end
Else If @Prod_Id Is NOT NULL AND @End_Time is NOT NULL 	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 3 Else 4 end
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL AND @End_Time is NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 5 Else 6 End
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL AND @End_Time is NOT NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 7 Else 8 End
Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL AND @End_Time is NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 9 Else 10 End
Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL AND @End_Time is NOT NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 11 Else 12 End
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL AND @End_Time is NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 13 Else 14 End
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL AND @End_Time is NOT NULL 	 SELECT @queryType = Case When @TimeSort = 1 then 15 Else 16 End
Else If @End_Time is NULL 	  	  	  	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 17 Else 18 End
Else If @End_Time is NOT NULL 	  	  	  	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 19 Else 20 End
If @QueryType = 17 	  	 --No product Info, @End_Time NULL, @TimeSort = 1
    BEGIN
 	 SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
 	   FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	    AND 	 dsd.var_id = @Var_Id
 	  WHERE 	 ds.pu_id = @Pu_Id
 	    AND 	 TimeStamp = @Start_Time
      ORDER BY 	 TimeStamp
    END
Else If @QueryType = 18 	  	 --No product Info, @End_Time NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 19 	  	 --No product Info, @End_Time NOT NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 20 	  	 --No product Info, @End_Time NOT NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	  	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 1 	  	 -- @Prod_Id Is NOT NULL, @End_Time is NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id = @Prod_Id
 	        ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 2 	  	 -- @Prod_Id Is NOT NULL, @End_Time is NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id = @Prod_Id
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 3 	  	 -- @Prod_Id NOT NULL, @End_Time NOT NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id = @Prod_Id
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 4 	  	 -- @Prod_Id NOT NULL, @End_Time NOT NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id = @Prod_Id
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 5 	  	 --  @Group_Id NOT NULL, @Prop_Id NULL, @End_Time NULL, @TimeSort =1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id in 
 	  	 ( Select prod_id
 	  	    FROM 	 product_group_data 
 	  	   WHERE 	 product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 6 	  	 --  @Group_Id NOT NULL, @Prop_Id NULL, @End_Time NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	  	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id in 
 	  	  	 ( Select prod_id
 	  	    FROM 	 product_group_data 
 	  	   WHERE 	 product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 7 	  	 --  @Group_Id NOT NULL,@Prop_Id NULL,@End_Time NOT NULL,@TimeSort = 1 
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id in 
 	  	 ( Select prod_id
 	  	    FROM 	 product_group_data 
 	  	   WHERE 	 product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 8 	  	 --  @Group_Id NOT NULL,@Prop_Id NULL,@End_Time NOT NULL,@TimeSort <>1 
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id in 
 	  	 ( Select prod_id
 	  	    FROM 	 product_group_data 
 	  	   WHERE 	 product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 9 	  	 -- @Group_Id NULL, @Prop_Id NOT NULL, @End_Time NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id IN 
 	  	 ( SELECT  prod_id 
 	  	     FROM  pu_characteristics 
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	 )
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 10 	  	 -- @Group_Id NULL, @Prop_Id NOT NULL, @End_Time NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id IN 
 	  	 ( SELECT  prod_id 
 	  	     FROM  pu_characteristics 
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	 )
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 11 	  	 -- @Group_Id NULL, @Prop_Id NOT NULL, @End_Time NOT NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id IN
 	  	 ( SELECT  prod_id 
 	  	     FROM  pu_characteristics 
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	 )
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 12 	  	 -- @Group_Id NULL, @Prop_Id NOT NULL, @End_Time NOT NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id IN
 	  	 ( SELECT  prod_id 
 	  	  	     FROM  pu_characteristics 
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	 )
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 13 	  	 -- @Group_Id NOT NULL, @Prop_Id NOT NULL, @End_Time NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	  	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id IN 
 	  	  	 ( SELECT  C.prod_id
 	  	  	     FROM  pu_characteristics C 
 	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	      AND  product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 14 	  	 -- @Group_Id NOT NULL, @Prop_Id NOT NULL, @End_Time NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
 	   	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	  	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp = @Start_Time
 	     AND 	 prod_id IN 
 	  	 ( SELECT  C.prod_id
 	  	     FROM  pu_characteristics C 
 	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	      AND  product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp DESC
    END
Else If @QueryType = 15 	  	 -- @Group_Id NOT NULL, @Prop_Id NOT NULL, @End_Time NOT NULL, @TimeSort = 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
  	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id IN 
 	  	 ( SELECT  C.prod_id
 	  	     FROM  pu_characteristics C 
 	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	      AND  product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp
    END
Else If @QueryType = 16 	  	 -- @Group_Id NOT NULL, @Prop_Id NOT NULL, @End_Time NOT NULL, @TimeSort <> 1
    BEGIN
 	  SELECT 	 [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.* 
 	   	    FROM 	 gb_dset ds  WITH (index(dset_by_pu)) 
 	 LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id 
 	     AND 	 dsd.var_id = @Var_Id
 	   WHERE 	 ds.pu_id = @Pu_Id
 	     AND 	 TimeStamp BETWEEN @Start_Time AND @End_Time
 	     AND 	 prod_id IN 
 	  	 ( SELECT  C.prod_id
 	  	     FROM  pu_characteristics C 
 	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	    WHERE  prop_id = @Prop_Id
 	  	      AND  char_id = @Char_Id
 	  	      AND  product_grp_id = @Group_Id
 	  	 )
       ORDER BY 	 TimeStamp DESC
    END
--EndIf
