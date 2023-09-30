CREATE PROCEDURE dbo.[spXLARunInfo_Expand_Bak_177] 
 	   @Start_Time  	 datetime
 	 , @End_Time  	 datetime
 	 , @Pu_Id  	 integer
 	 , @Prod_Id  	 integer
 	 , @Group_Id  	 integer
 	 , @Prop_Id  	 integer
 	 , @Char_Id  	 integer
 	 , @TimeSort  	 smallint 
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
DECLARE @QueryType TinyInt
If @Prod_Id Is NOT NULL AND @End_Time is NULL 	  	  	  	  	  	 SELECT @QueryType = Case when @TimeSort = 1 then 1 Else 2 End
Else If @Prod_Id Is NOT NULL AND @End_Time is Not NULL  	  	  	  	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 3 Else 4 End  
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL AND @End_Time is NULL 	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 5 Else 6 End
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL AND @End_Time is Not NULL 	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 7 Else 8 End
Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL AND @End_Time is NULL  	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 9 Else 10 End
Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL AND @End_Time is Not NULL  	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 11 Else 12 End
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL AND @End_Time is NULL  	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 13 Else 14 End
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL AND @End_Time is Not NULL  	 SELECT @QueryType = Case When @TimeSort = 1 Then 15 Else 16 End
Else If @End_Time is NULL  	  	  	  	  	  	  	  	 SELECT @QueryType = Case When @TimeSort = 1 then 17 Else 18 End
Else If @End_Time is Not NULL  	  	  	  	  	  	  	  	 SELECT @QueryType = Case When @TimeSort = 1 Then 19 Else 20 End
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	  	  	  	  	  	 -- @Group_Id, @Prod_Id, @Prop_Id, @Char_Id are null
If @QueryType = 17 	  	  	  	  	 -- @End_Time null, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id AND  Start_Time = @Start_Time
 	 ORDER BY  Start_Time 	 
    END
Else If @QueryType = 18 	  	  	  	  	 -- @End_Time null, Desc
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id AND  Start_Time = @Start_Time
 	 ORDER BY  Start_Time DESC
    END
Else If @QueryType = 19 	  	  	  	  	 -- @End_Time Not NULL, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time 
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 20 	  	  	  	  	 -- @End_Time Not NULL, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time
 	 ORDER BY  Start_Time DESC  
    END
 	  	  	  	  	  	  	 -- @Prod_Id Is Not NULL 	 
Else If @QueryType = 1 	  	  	  	  	 -- @End_Time null, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id AND Start_Time = @Start_Time AND prod_id = @Prod_Id
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 2 	  	  	  	  	 -- @End_Time null, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id AND Start_Time = @Start_Time AND prod_id = @Prod_Id
 	 ORDER BY  Start_Time DESC
   END
Else If @QueryType = 3 	  	  	  	  	 -- @End_Time Not NULL, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time AND prod_id = @Prod_Id
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 4 	  	  	  	  	 -- @End_Time Not NULL, Descending
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time AND prod_id = @Prod_Id
 	 ORDER BY  Start_Time DESC
    END
 	  	  	  	  	  	 
Else If @QueryType = 5 	  	  	  	 -- @Group_Id Is NOT NULL AND @Prop_Id Is NULL
 	  	  	  	  	  	 --@End_Time null, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  Start_Time = @Start_Time
 	      AND  prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 6 	  	  	  	 -- @End_Time null, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  Start_Time = @Start_Time
 	      AND  prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
 	 ORDER BY  Start_Time DESC
    END
Else If @QueryType = 7 	  	  	  	 -- @End_Time Not NULL, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      AND  prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 8 	  	  	  	 -- @End_Time Not NULL, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      AND  prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
 	 ORDER BY  Start_Time DESC
    END
 	  	  	  	  	  	 -- @Group_Id Is NULL AND @Prop_Id Is Not NULL
Else If @QueryType = 9 	  	  	  	 -- @End_Time NULL, Ascend 	 
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  Start_Time = @Start_Time
 	      AND  prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 10 	  	  	  	 -- @End_Time NULL, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  Start_Time = @Start_Time
 	      AND  prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
 	 ORDER BY  Start_Time DESC
    END
Else If @QueryType = 11 	  	  	  	 -- @End_Time Not NULL, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      AND  prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 12 	  	  	  	 -- @End_Time Not NULL, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      AND  prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
 	 ORDER BY  Start_Time DESC
    END
 	  	  	  	  	 -- @Group_Id Is NULL AND @Prop_Id Is Not NULL
Else If @QueryType = 13 	  	  	  	 -- @End_Time NULL, Ascend 	 
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  Start_Time = @Start_Time
 	      AND  prod_id IN 
 	  	  	 ( SELECT  c.prod_id
 	  	  	     FROM  pu_characteristics c 
 	  	  	     JOIN  product_group_data g ON c.prod_id = g.prod_id
 	  	  	    WHERE  c.prop_id = @Prop_Id
 	  	  	      AND  c.char_id = @Char_Id
 	  	  	      AND  g.product_grp_id = @Group_Id
 	  	  	 )
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 14 	  	  	  	 -- @End_Time NULL, Descend
     BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  Start_Time = @Start_Time
 	      AND  prod_id IN 
 	  	  	 ( SELECT  C.prod_id
 	  	  	     FROM  pu_characteristics C 
 	  	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	  	    WHERE  C.prop_id = @Prop_Id
 	  	  	      AND  C.char_id = @Char_Id
 	  	  	      AND  G.product_grp_id = @Group_Id
 	  	  	 )
 	 ORDER BY  Start_Time DESC
    END
Else If @QueryType = 15 	  	  	  	 -- @End_Time Not NULL, Ascend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      AND  prod_id IN 
 	  	  	 ( SELECT  C.prod_id
 	  	  	     FROM  pu_characteristics C 
 	  	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	  	    WHERE  C.prop_id = @Prop_Id
 	  	  	      AND  C.char_id = @Char_Id
 	  	  	      AND  G.product_grp_id = @Group_Id
 	  	  	 )
 	 ORDER BY  Start_Time
    END
Else If @QueryType = 16 	  	  	  	 -- @End_Time Not NULL, Descend
    BEGIN
 	   SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,@InTimeZone),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone) 
 	     FROM  gb_rsum 
 	    WHERE  pu_id = @Pu_Id
 	      AND  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      AND  prod_id IN 
 	  	  	 ( SELECT  C.prod_id
 	  	  	     FROM  pu_characteristics C 
 	  	  	     JOIN  product_group_data G ON C.prod_id = G.prod_id
 	  	  	    WHERE  C.prop_id = @Prop_Id
 	  	  	      AND  C.char_id = @Char_Id
 	  	  	      AND  G.product_grp_id = @Group_Id
 	  	  	 )
 	 ORDER BY  Start_Time DESC
    END
--EndIf @QueryType ...
