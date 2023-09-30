CREATE PROCEDURE dbo.[spXLASearchProductionStarts_AP_Bak_177]
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @MasterUnitID  	 Integer
 	 , @MasterName  	  	 varchar(50)
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @NeedProductCode 	 TinyInt 	  	 --1 = include product code in ResultSet; 0 = exclude
 	 , @AppliedProductFilter 	 TinyInt 	  	 --1= filter by Applied Product is set; 0 = No, Filter By Original Product
 	 , @TimeSort  	  	 Tinyint = NULL 	 --1 Ascending; Otherwise, Descending
 	 , @InTimeZone 	 varchar(200) = null
AS
 	 --Needed for Product Info Query ...
DECLARE @QueryType  	  	 TinyInt  -- Determine "Type" of SQL for Filtering By Product (Applied Or Original)
DECLARE @OneProductFilter 	 TinyInt  --51
DECLARE @GroupFilter 	  	 TinyInt  --52
DECLARE @CharacteristicFilter 	 TinyInt  --53
DECLARE @GroupAndPropertyFilter 	 TinyInt  --54
DECLARE @NoProductFilter 	 TinyInt  --55
 	 --Needed for Cursor ...
DECLARE @Prev_Ps_Start_Time     DateTime
DECLARE @Prev_Ps_End_Time       DateTime
DECLARE @Previous_End_Time 	 DateTime
DECLARE @Previous_Pu_Id 	  	 Int
DECLARE @Previous_Prod_Id  	 Int
DECLARE @Previous_ApProd_Id 	 Int
DECLARE @Original_Found 	         Int
DECLARE @Sum_Original_Found 	 Int
DECLARE @AP_Found 	  	 Int
DECLARE @Sum_AP_Found 	  	 Int
DECLARE @Saved_Start_Time 	 DateTime
DECLARE @Fetch_Count            Int
DECLARE @@Ps_Start_Time         DateTime
DECLARE @@Ps_End_Time           DateTime
DECLARE @@Start_Time            	 DateTime
DECLARE @@End_Time              	 DateTime
DECLARE @@Pu_Id                 	 Int
DECLARE @@Prod_Id 	  	 Int
DECLARE @@Applied_Prod_Id 	 Int
--Figure Out Product-Related Query Types
/* NOTE: We DO NOT handle all possible null combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
   Proficy Add-In blocks out illegal combinations, and allows only these combination:
     - Property AND Characteristic 
     - Group Only
     - Group, Propery, AND Characteristic
     - Product Only
     - No Product Information At All 
*/
SELECT @OneProductFilter 	 = 51
SELECT @GroupFilter 	  	 = 52
SELECT @CharacteristicFilter 	 = 53
SELECT @GroupAndPropertyFilter  	 = 54
SELECT @NoProductFilter 	  	 = 55
If @TimeSort IS NULL    SELECT @TimeSort = 1  --Ascending, DEFAULT
If @Start_Time Is NULL SELECT @Start_Time = '1-jan-1971'
If @End_Time Is NULL   SELECT @End_Time = dateadd(day,7,getdate())
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
If @MasterName Is NOT NULL
  SELECT @MasterUnitID = Case When Master_Unit Is NULL Then Pu_Id Else Master_Unit End From Prod_Units Where PU_Desc = @MasterName  
Else If @MasterUnitID Is NOT NULL
  SELECT @MasterUnitID = Case When Master_Unit Is NULL Then Pu_Id Else Master_Unit End From Prod_Units Where Pu_Id = @MasterUnitID  
--EndIf
--Define "query type" which can be used with AppliedProduct Or OriginalProduct filter
If @Prod_Id is not NULL 	  	  	  	  	 SELECT @QueryType = @OneProductFilter 	  	 --51
Else If @Group_Id Is NOT NULL AND @Prop_Id is NULL 	 SELECT @QueryType = @GroupFilter 	  	 --52
Else If @Prop_Id Is NOT NULL AND @Group_Id is NULL 	 SELECT @QueryType = @CharacteristicFilter 	 --53
Else If @Prop_Id Is NOT NULL AND @Group_Id is not NULL 	 SELECT @QueryType = @GroupAndPropertyFilter 	 --54
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductFilter 	  	 --55 
--EndIf
CREATE TABLE #prod_starts (pu_id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #products (Prod_Id Int)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
If @AppliedProductFilter = 1 GOTO DO_APPLIED_PRODUCT_FILTER_STUFF
If @NeedProductCode = 0      GOTO RETRIEVE_ORIG_PRODUCT_FILTER_WITHOUT_PRODUCT_CODE
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Build Temp Production_Starts Table ......
If @QueryType = @NoProductFilter 	 --5  	  	  	 
  BEGIN
    If @MasterUnitID Is NULL
      BEGIN
        If @TimeSort = 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE Start_Time BETWEEN @Start_Time AND @End_Time
                  OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                  OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ORDER BY ps.Start_Time ASC
          END
        Else --@TimeSort <> 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                  OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ORDER BY ps.Start_Time DESC
          END
        --EndIf @TimeSort
      END
    Else -- @Master NOT NULL
      BEGIN
        If @TimeSort = 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE ps.Pu_Id = @MasterUnitID 
                 AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                       --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                       OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                     )
            ORDER BY ps.Start_Time ASC
          END
        Else --@TimeSort <> 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE ps.Pu_Id = @MasterUnitID 
                 AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                        --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                       OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                     )
            ORDER BY ps.Start_Time DESC
          END
        --EndIf @TimeSort
 	 END
    --EndIf @MasterUnitID 
  END
Else If @QueryType = @OneProductFilter 	  	 --1
  BEGIN
    If @MasterUnitID Is NULL
      BEGIN
        If @TimeSort = 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE ps.Prod_Id = @Prod_Id 
                 AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                        --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                       OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                     )
            ORDER BY ps.Start_Time ASC
          END
        Else --@TimeSort <> 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE ps.Prod_Id = @Prod_Id 
                 AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                        --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                       OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                     )
            ORDER BY ps.Start_Time DESC
          END
        --EndIf @TimeSort
      END
    Else --@MasterUnitID NOT NULL
      BEGIN
        If @TimeSort = 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE ps.Pu_Id = @MasterUnitID 
                 AND ps.Prod_Id = @Prod_Id 
                 AND (    (Start_Time BETWEEN @Start_Time AND @End_Time)
                       OR (End_Time > @Start_Time AND End_Time < @End_Time)
                       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
                     )
            ORDER BY ps.Start_Time ASC
          END
        Else --@TimeSort <> 1
          BEGIN
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.Prod_Code
                FROM production_starts ps
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                JOIN products p on p.Prod_Id = ps.Prod_Id 
               WHERE ps.Pu_Id = @MasterUnitID 
                 AND ps.Prod_Id = @Prod_Id 
                 AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                       OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                     )
            ORDER BY ps.Start_Time DESC
          END
 	 --EndIf @TimeSort 	 
 	 END 
    --EndIf @MasterUnitID...
  END
Else 	  	  	  	  	 --Some product grouping exist
  BEGIN
    If @QueryType = @GroupFilter 	  	 --52
      BEGIN
         INSERT INTO #products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @CharacteristicFilter 	 --53
      BEGIN
         INSERT INTO #products
         SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	 --Group and Property
      BEGIN
         INSERT INTO #products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
         INSERT INTO #products
         SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    --EndIf  @QueryType ..
    If @MasterUnitID Is NULL
      BEGIN
        If @TimeSort = 1 
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.Prod_Code
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products pt on pt.Prod_Id = ps.Prod_Id 
            WHERE (Start_Time BETWEEN @Start_Time AND @End_Time)
               OR (End_Time > @Start_Time AND End_Time < @End_Time) 
 	        OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ORDER BY ps.Start_Time ASC 
        Else --@TimeSort <> 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.Prod_Code
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products pt on pt.Prod_Id = ps.Prod_Id 
            WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	        --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (End_Time > @Start_Time AND End_Time < @End_Time) 
 	        OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ORDER BY ps.Start_Time DESC 
         --EndIf @TimeSort
      END
    Else --@MasterUnitID NOT NULL
      BEGIN
        If @TimeSort = 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.Prod_Code
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products pt on pt.Prod_Id = ps.Prod_Id 
            WHERE ps.Pu_Id = @MasterUnitID 
 	       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	     --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                    OR (End_Time > @Start_Time AND End_Time < @End_Time) 
 	  	     OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                  ) 
            ORDER BY ps.Start_Time ASC 
        Else --@TimeSort <> 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.Prod_Code
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products pt on pt.Prod_Id = ps.Prod_Id 
            WHERE ps.Pu_Id = @MasterUnitID 
 	       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	     --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                    OR (End_Time > @Start_Time AND End_Time < @End_Time) 
 	  	     OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_Time & End_time condition checked ; MSi/MT/3-21-2001
                  ) 
            ORDER BY ps.Start_Time DESC 
 	 --EndIf
      END
    --EndIf @Master ..  
    --DROP TABLE #products
  END
--EndIf @QueryType = 5
GOTO EXIT_PROCEDURE
-- RETRIEVE ORIGINAL PRODUCT WITHOUT PRODUCT CODE ** RETRIEVE ORIGINAL PRODUCT WITHOUT PRODUCT CODE ** RETRIEVE ORIGINAL PRODUCT WITHOUT PRODUCT CODE ** 
-- RETRIEVE ORIGINAL PRODUCT WITHOUT PRODUCT CODE ** RETRIEVE ORIGINAL PRODUCT WITHOUT PRODUCT CODE ** RETRIEVE ORIGINAL PRODUCT WITHOUT PRODUCT CODE ** 
RETRIEVE_ORIG_PRODUCT_FILTER_WITHOUT_PRODUCT_CODE:
  If @QueryType = @NoProductFilter 	 --5  	  	  	 
    BEGIN
      If @MasterUnitID Is NULL
        BEGIN
          If @TimeSort = 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
                    --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                    OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                    OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
              ORDER BY ps.Start_Time ASC
            END
          Else --@TimeSort <> 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
                    --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                    OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                    OR (End_Time > @Start_Time AND End_Time < @End_Time) 
 	       ORDER BY ps.Start_Time DESC
            END
 	     --EndIf @TimeSort
        END
      Else -- @Master NOT NULL
        BEGIN
          If @TimeSort = 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE ps.Pu_Id = @MasterUnitID 
                   AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                         --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                         OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                         OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                       )
              ORDER BY ps.Start_Time ASC
            END
          Else --@TimeSort <> 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE ps.Pu_Id = @MasterUnitID 
                   AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                        --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                        OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                        OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                       )
              ORDER BY ps.Start_Time DESC
            END
          --EndIf @TimeSort
        END
      --EndIf @MasterUnitID 
    END --No product filter
  Else If @QueryType = @OneProductFilter 	  	 --1
    BEGIN
      If @MasterUnitID Is NULL
 	 BEGIN
          If @TimeSort = 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE ps.Prod_Id = @Prod_Id 
                   AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                         OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                         OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                       )
              ORDER BY ps.Start_Time ASC
            END
          Else --@TimeSort <> 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE ps.Prod_Id = @Prod_Id 
                   AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                         OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                         OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                       )
              ORDER BY ps.Start_Time DESC
            END
          --EndIf @TimeSort
 	 END
      Else --@MasterUnitID NOT NULL
        BEGIN
          If @TimeSort = 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE ps.Pu_Id = @MasterUnitID 
                   AND ps.Prod_Id = @Prod_Id 
                   AND (    (Start_Time BETWEEN @Start_Time AND @End_Time)
                         OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                         OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                       )
              ORDER BY ps.Start_Time ASC
            END
          Else --@TimeSort <> 1
            BEGIN
                SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                  FROM production_starts ps
                  JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
                 WHERE ps.Pu_Id = @MasterUnitID 
                   AND ps.Prod_Id = @Prod_Id 
                   AND (    (Start_Time BETWEEN @Start_Time AND @End_Time)
                         OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                         OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
                       )
              ORDER BY ps.Start_Time DESC
            END
          --EndIf @TimeSort 	 
 	 END 
      --EndIf @MasterUnitID...
    END --One product
  Else 	  	  	  	  	 --Some product grouping exist
    BEGIN
      --CREATE TABLE #products (Prod_Id int)
      If @QueryType = @GroupFilter 	  	 --52
        BEGIN
           INSERT INTO #products
           SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
        END
      Else If @QueryType = @CharacteristicFilter 	 --53
        BEGIN
           INSERT INTO #products
           SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
        END
      Else 	  	  	  	 --Group and Property
        BEGIN
           INSERT INTO #products
           SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
           INSERT INTO #products
           SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
        END
      --EndIf  @QueryType ..
      If @MasterUnitID Is NULL
        BEGIN
          If @TimeSort = 1 
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                FROM production_starts ps
                JOIN #products p on ps.Prod_Id = p.Prod_Id 
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
               WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time > @Start_Time AND End_Time < @End_Time)
                  OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
            ORDER BY ps.Start_Time ASC 
          Else --@TimeSort <> 1
              SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
                FROM production_starts ps
                JOIN #products p on ps.Prod_Id = p.Prod_Id 
                JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
               WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time > @Start_Time AND End_Time < @End_Time)
                  OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
            ORDER BY ps.Start_Time DESC 
          --EndIf @TimeSort
        END
    Else --@MasterUnitID NOT NULL
      BEGIN
        If @TimeSort = 1
            SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
              FROM production_starts ps
              JOIN #products p on ps.Prod_Id = p.Prod_Id 
              JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
             WHERE ps.Pu_Id = @MasterUnitID 
               AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                     --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                     OR (End_Time > @Start_Time AND End_Time < @End_Time)
                     OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
 	   	       --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                   ) 
          ORDER BY ps.Start_Time ASC 
        Else --@TimeSort <> 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone)
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            WHERE ps.Pu_Id = @MasterUnitID 
 	       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	     --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                    OR (End_Time > @Start_Time AND End_Time < @End_Time)
 	  	     OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
 	   	       --Start_Time & End_time condition checked ; MSi/MT/3-21-2001
                  ) 
            ORDER BY ps.Start_Time DESC 
 	 --EndIf
      END
    --EndIf @Master ..  
    --DROP TABLE #products
    END --Some Product collection
  --EndIf @QueryType = 5
  GOTO EXIT_PROCEDURE
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_APPLIED_PRODUCT_FILTER_STUFF:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Grab all of the "Specified" Applied Products, put them into Temp Table #Products
  BEGIN      
    If @QueryType = @GroupFilter
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @CharacteristicFilter
      BEGIN
         INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else If @QueryType = @GroupAndPropertyFilter 	  	 
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
 	  INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE Prop_Id = @Prop_Id AND char_id = @Char_Id
      END
    Else -- must be @OneProductFilter
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id = @Prod_Id
      END
    --EndIf
  END
  --Grab All "Original Products" information that we care in the Specified Time Range
  BEGIN
    If @MasterUnitID Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.pu_id, ps.Prod_Id,ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (   ps.Start_Time BETWEEN @Start_Time AND @End_Time 
                  --OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
                  OR (End_Time > @Start_Time AND End_Time < @End_Time)
 	  	   OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time is NULL) )
                 )
       END
    Else --@MasterUnitID NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
            SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
              FROM production_starts ps
             WHERE ps.Pu_Id = @MasterUnitID 
 	        AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
                     --OR ps.End_Time BETWEEN @Start_Time AND @End_Time
                     OR (End_Time > @Start_Time AND End_Time < @End_Time)
                     OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time is NULL) )
                   )
      END
    --EndIf
  END
  --RETRIEVE RESULTSET BASED ON WHETHER OR NOT "Applied Products" information is asked for.
  --NOTE: Definition of "Applied Products" from Events Table.  
  --      When Applied_Product is NULL, we take that the original product is applied product.
  --      When Applied_Product is not NULL, only applied products that match search criteria count as applied product.
  --NOTE2: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --     a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --     Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
  --     the Events table. This update is time/disk-space consuming, thus, available upon request only.
  --Make TEMP TABLE: Split ANY PRODUCT In #Prod_Starts into individual events.
  INSERT INTO #Applied_Products ( Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id )
      SELECT e.Pu_Id, ps.Start_Time, ps.End_Time, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product 
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
--        JOIN Events e ON ps.Start_Time <= e.Start_Time AND (ps.End_Time >= e.TimeStamp OR ps.End_Time Is NULL)
         AND ps.Pu_Id = e.Pu_Id 
    ORDER BY e.Pu_Id, ps.Start_Time, e.Start_Time, ps.Prod_Id
  -- Use Cursor to track the individual events in #Applied_Products 
  DECLARE TCursor INSENSITIVE CURSOR 
    FOR ( SELECT Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id FROM #Applied_Products )
    FOR READ ONLY
  --END Declare
OPEN_CURSOR_FOR_PROCESSING:
  -- Initialize local variables ......
  SELECT @Saved_Start_Time   = ''
  SELECT @Prev_Ps_Start_Time = ''
  SELECT @Prev_Ps_End_Time   = ''
  SELECT @Previous_Pu_Id     = -1
  SELECT @Previous_End_Time  = ''
  SELECT @Previous_Prod_Id   = -1
  SELECT @Previous_ApProd_Id = -1
  SELECT @Original_Found     = -1
  SELECT @Sum_Original_Found = 0
  SELECT @AP_Found 	      = -1
  SELECT @Sum_AP_Found       = 0
  SELECT @Fetch_Count        = 0
  SELECT @@Ps_Start_Time     = ''
  SELECT @@Ps_End_Time       = ''
  SELECT @@Start_Time        = ''
  SELECT @@End_Time          = ''
  SELECT @@Pu_Id             = -1
  SELECT @@Prod_Id           = -1
  SELECT @@Applied_Prod_Id   = -1
  OPEN TCursor
  --Tracking Product Events by counting successive applied events
  --(a) First loop: Save start time, store fetched variables in the "Previous" local variables
  --(a) Within same ID: 
  --    Switching occurs when Ps_Start_Time --> Ps_End_Time change.
  --    Switching occurs when previous running applied event(s) turn original, or previous running original event(s) 
  --    turn applied. When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
  --(b) When product ID switch occurs: 
  --    Switching occurs when previous running original event(s) turn original, or previous running original event(s) turn
  --    applied, or previous running applied event(s) turn original, or previous running applied event(s) turn applied.
  --    When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
TOP_OF_FETCH_LOOP:
  FETCH NEXT FROM TCursor INTO @@Pu_Id, @@Ps_Start_Time, @@Ps_End_Time, @@Start_Time, @@End_Time, @@Prod_Id, @@Applied_Prod_Id
  If (@@Fetch_Status = 0)
    BEGIN
      -- ********************************************************************************************
      -- FIRST FETCH: 
      If @Previous_Prod_Id = -1 	  	  	                 
        -- The very first fetch, collect row information and save start time
        BEGIN  
          --SELECT @Saved_Start_Time   = @@Start_Time
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
          SELECT @AP_Found           = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found     = 1 - @AP_Found
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of a product uses start time from Production_Starts
          If @AP_Found = 1 --First reeel as applied product
            BEGIN
              If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Applied_Prod_Id)
                BEGIN
                  UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                  SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                END
              --EndIf EXISTS
            END
          Else --1st Reel is original product
            BEGIN
             If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Prod_Id)
               BEGIN
                 UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                 SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
               END
             --EndIf EXISTS
            END
          --EndIf @AP_Found.
        END
      -- ********************************************************************************************
      -- PRODUCT ID SWITCHED OR PRODUCTION CHANGE OCCURS (SAME ID BUT DIFF START & END TIMES) 
         -- It is the time to 
         -- (a) process last events of previous product. Use Ps_End_Time for last reel)
         -- (b) Update start time for first reel (event) with Ps_Start_Time.
         --
      Else If @Previous_Prod_Id <> @@Prod_Id 
          OR ( @Previous_Prod_Id = @@Prod_Id AND @Prev_Ps_Start_Time <> @@Ps_Start_Time AND (@Prev_Ps_End_Time <> @@Ps_End_Time OR @Prev_Ps_End_Time Is NULL Or @@Ps_End_Time Is NULL) )
        BEGIN                    
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          --Update Previous Running Events ...
          If @AP_Found = 1  --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0  --Running original turns applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1  
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS    
                END
              Else --(@Sum_AP_Found >0): Running applied turns applied at new ID
                BEGIN
                  --Update last row of running applied (if Applied_Prod_Id matches filter)
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time                     
                      SELECT @Sum_AP_Found = 0 --reset applied running count
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found =0
            END
          Else  --@AP_Found = 0: Original fetched
            BEGIN
              If @Sum_AP_Found > 0  --Running applied switches to original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                END
              Else --(@Sum_AP_Found = 0): Running original turns original at ID switch
                BEGIN
                  --Update last row in running original events
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time        
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Reset counters (for original product only tracking)
          SELECT @Fetch_Count        = 0
          SELECT @Sum_Original_Found = 0
              --Collect relevant info for this ID ....
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of product uses start time from Production_Starts
          SELECT @Saved_Start_Time = Ps_Start_Time  FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
        END
      -- ********************************************************************************************
      -- RUNNING PRODUCT -- SAME PRODUCT FETCHED; Has this event been applied?
      Else If @Previous_Prod_Id = @@Prod_Id              
        BEGIN  
          --Get applied/original status
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          If @AP_Found = 1 --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0 --Running original switches to applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Saved_Start_Time = @@Start_Time --Save start_time
                END
              --EndIf:@Sum_AP_Found =0
            END     
          Else  --(@AP_Found = 0): fetched event is original
            BEGIN
              If @Sum_AP_Found > 0  --Running applied turns original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf                      
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                  SELECT @Saved_Start_Time = @@Start_Time  --Save current original event's Start_Time
                END
              --Else --(@Sum_AP_Found = 0): Running original turns original turns original
                     --(do nothing, just continue accumulate running events)
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Collect information of current fetched
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
        END
      --EndIf:@Previous_Prod_Id = -1( Main block )
      GOTO TOP_OF_FETCH_LOOP
    END
  --EndIf (@@Fetch_Status = 0)
  -- ****************************************************************
  --HANDLE END OF LOOP UPDATE: ( single event also included here )
    If @AP_Found = 1  --Last fetch was applied
      BEGIN
        --Handle previously 100% running applied
        If @Fetch_Count = @Sum_AP_Found 
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END        
        Else --Not 100% running applied
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
               UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
        --EndIf @Fetch_Count
      END
    Else --Last fetch was original (@AP_Found =0)
      BEGIN
        --Handle previously 100% Running original events, use times from production_Starts table
        If @Fetch_Count = @Sum_Original_Found
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END     
        Else --not 100% running original event; use times from Events table
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
          END
        --EndIf:@Fetch_Count = @Sum_Original_Found
      END
    --EndIf:@Sum_AP_Found =1
  CLOSE TCursor
  DEALLOCATE TCursor
  -- DELETE UNMARKED ROWS .....
  DELETE FROM #Applied_Products WHERE Keep_Event Is NULL
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @NeedProductCode = 0 GOTO RETRIEVE_APPLIED_PRODUCT_FILTER_WITHOUT_PRODUCT_CODE
  -- Retrieve ResordSet
  If @TimeSort = 1 --Asc
    BEGIN
        SELECT Production_Unit = pu.Pu_Desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ap.Start_Time,@InTimeZone), End_Time = dbo.fnServer_CmnConvertFromDbTime(ap.End_Time,@InTimeZone), p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
          FROM #Applied_Products ap
          JOIN Prod_Units pu ON pu.Pu_Id = ap.Pu_Id
          JOIN Products p ON p.Prod_Id = ap.Prod_Id
          LEFT JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         WHERE ap.Start_Time BETWEEN @Start_Time AND @End_Time
            OR ap.End_Time BETWEEN @Start_Time AND @End_Time
            OR (ap.Start_Time >= @Start_Time AND (ap.End_Time > @End_Time OR ap.End_Time Is NULL))
      ORDER BY ap.Start_Time ASC
    END
  Else --@TimeSort <> 1 Desc
    BEGIN
       --Select only rows that fall within specified time range  
        SELECT Production_Unit = pu.Pu_Desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ap.Start_Time,@InTimeZone), End_Time = dbo.fnServer_CmnConvertFromDbTime(ap.End_Time,@InTimeZone), p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
          FROM #Applied_Products ap
          JOIN Prod_Units pu ON pu.Pu_Id = ap.Pu_Id
          JOIN Products p ON p.Prod_Id = ap.Prod_Id
          LEFT JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         WHERE ap.Start_Time BETWEEN @Start_Time AND @End_Time
            OR ap.End_Time BETWEEN @Start_Time AND @End_Time
            OR (ap.Start_Time >= @Start_Time AND (ap.End_Time > @End_Time OR ap.End_Time Is NULL))
      ORDER BY ap.Start_Time DESC
    END
  --EndIf @TimeSort ...
  GOTO EXIT_PROCEDURE
RETRIEVE_APPLIED_PRODUCT_FILTER_WITHOUT_PRODUCT_CODE:
  -- Retrieve ResordSet
  If @TimeSort = 1 --Asc
    BEGIN
       --Select only rows that fall within specified time range  
        SELECT Production_Unit = pu.Pu_Desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ap.Start_Time,@InTimeZone), End_Time = dbo.fnServer_CmnConvertFromDbTime(ap.End_Time,@InTimeZone)
          FROM #Applied_Products ap
          JOIN Prod_Units pu ON pu.Pu_Id = ap.Pu_Id
         WHERE ap.Start_Time BETWEEN @Start_Time AND @End_Time
            OR ap.End_Time BETWEEN @Start_Time AND @End_Time
            OR (ap.Start_Time >= @Start_Time AND (ap.End_Time > @End_Time OR ap.End_Time Is NULL))
      ORDER BY ap.Start_Time ASC
    END
  Else --@TimeSort <> 1 Desc
    BEGIN
       --Select only rows that fall within specified time range  
        SELECT Production_Unit = pu.Pu_Desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ap.Start_Time,@InTimeZone), End_Time = dbo.fnServer_CmnConvertFromDbTime(ap.End_Time,@InTimeZone)
          FROM #Applied_Products ap
          JOIN Prod_Units pu ON pu.Pu_Id = ap.Pu_Id
         WHERE ap.Start_Time BETWEEN @Start_Time AND @End_Time
            OR ap.End_Time BETWEEN @Start_Time AND @End_Time
            OR (ap.Start_Time >= @Start_Time AND (ap.End_Time > @End_Time OR ap.End_Time Is NULL))
      ORDER BY ap.Start_Time DESC
    END
  --EndIf @TimeSort ...
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
  DROP TABLE #prod_starts 
  DROP TABLE #products 
  DROP TABLE #Applied_Products
