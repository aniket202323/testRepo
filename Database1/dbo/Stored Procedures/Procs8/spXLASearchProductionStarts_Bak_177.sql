Create Procedure dbo.[spXLASearchProductionStarts_Bak_177]
 	   @StartTime datetime
 	 , @EndTime datetime
 	 , @MasterUnit int
 	 , @MasterUnitName varchar(50)
 	 , @prodid integer
 	 , @groupid integer
 	 , @propid integer
 	 , @charid integer
 	 , @torder tinyint = NULL
 	 , @InTimeZone 	 varchar(200) = null
AS
declare @QueryType tinyint
If @StartTime Is Null SELECT @StartTime = '1-jan-1971'
If @EndTime Is Null   SELECT @EndTime = dateadd(day,7,getdate())
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
If @MasterUnitName Is Not Null
  SELECT @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End From Prod_Units Where PU_Desc = @MasterUnitName  
Else If @MasterUnit Is Not Null
  SELECT @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End From Prod_Units Where PU_Id = @MasterUnit  
--Figure Out Query Type
If @prodid is not null
  SELECT @QueryType = 1   	  	 --Single Product
Else If @groupid is not null AND @propid is null 
  SELECT @QueryType = 2   	  	 --Single Group
Else If @propid is not null AND @groupid is null
  SELECT @QueryType = 3   	  	 --Single Characteristic
Else If @propid is not null AND @groupid is not null
  SELECT @QueryType = 4   	  	 --Group and Property  
Else
  SELECT @QueryType = 5 	  	  	 --Any products
If @QueryType = 5  	  	  	 --Any products
  BEGIN
    If @MasterUnit Is Null
 	 BEGIN
 	     If @torder = 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE (start_time BETWEEN @starttime AND @endtime) 
 	  	         or (end_time BETWEEN @starttime AND @endtime) 
 	  	         or (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	   	            --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	           ORDER BY ps.start_time ASC
 	         END
 	     Else --@torder <> 1
 	         BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE (start_time BETWEEN @starttime AND @endtime) 
 	  	         or (end_time BETWEEN @starttime AND @endtime) 
 	  	         or (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	   	  	    --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	           ORDER BY ps.start_time DESC
 	         END
 	     --EndIf @torder
 	 END
    Else -- @Master NOT null
 	 BEGIN
 	     If @torder = 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE ps.pu_id = @MasterUnit 
 	  	        AND (    (start_time BETWEEN @starttime AND @endtime) 
 	  	  	      OR (end_time BETWEEN @starttime AND @endtime) 
 	  	  	      OR (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	  	  	         --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	  	  	    )
 	  	   ORDER BY ps.Start_Time ASC
 	  	 END
 	     Else --@torder <> 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE ps.pu_id = @MasterUnit 
 	  	        AND (    (start_time BETWEEN @starttime AND @endtime) 
 	  	  	      OR (end_time BETWEEN @starttime AND @endtime) 
 	  	  	      OR (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	  	  	         --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	  	  	    )
 	  	   ORDER BY ps.Start_Time DESC
 	  	 END
 	     --EndIf @torder
 	 END
    --EndIf @MasterUnit 
  END
Else If @QueryType = 1 	  	  	 --Single Product
  BEGIN
    If @MasterUnit Is Null
 	 BEGIN
 	     If @torder = 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE ps.prod_id = @prodid 
 	  	        AND (    (start_time BETWEEN @starttime AND @endtime) 
 	  	  	      or (end_time BETWEEN @starttime AND @endtime) 
 	  	  	      or (start_time <= @starttime AND (end_time > @endtime or end_time is null))
 	  	  	     --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	  	  	    )
 	  	   ORDER BY ps.Start_Time ASC
 	  	 END
 	     Else --@torder <> 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE ps.prod_id = @prodid 
 	  	        AND (    (start_time BETWEEN @starttime AND @endtime) 
 	  	  	      or (end_time BETWEEN @starttime AND @endtime) 
 	  	  	      or (start_time <= @starttime AND (end_time > @endtime or end_time is null))
 	  	  	     --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	  	  	    )
 	  	   ORDER BY ps.Start_Time DESC
 	  	 END
 	     --EndIf @torder
 	 END
    Else --@MasterUnit NOT null
 	 BEGIN
 	     If @torder = 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE ps.pu_id = @MasterUnit 
 	  	        AND ps.prod_id = @prodid 
 	  	        AND (    (start_time BETWEEN @starttime AND @endtime)
 	  	              or (end_time BETWEEN @starttime AND @endtime) 
 	  	  	      or (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	  	  	          --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	  	            )
 	           ORDER BY ps.Start_Time ASC
 	  	 END
 	     Else --@torder <> 1
 	  	 BEGIN
 	  	     SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), p.prod_code
 	  	       FROM production_starts ps
 	  	       JOIN prod_units pu on pu.pu_id = ps.pu_id
 	  	       JOIN products p on p.prod_id = ps.prod_id 
 	  	      WHERE ps.pu_id = @MasterUnit 
 	  	        AND ps.prod_id = @prodid 
 	  	        AND (    (start_time BETWEEN @starttime AND @endtime)
 	  	              or (end_time BETWEEN @starttime AND @endtime) 
 	  	  	      or (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	  	  	          --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	  	            )
 	           ORDER BY ps.Start_Time DESC
 	  	 END
 	     --EndIf @torder 	 
 	 END 
    --EndIf @MasterUnit...
  END
Else 	  	  	  	  	 --Some product grouping exist
  BEGIN
    CREATE TABLE #products (prod_id int)
    If @QueryType = 2 	  	  	 --Single Characteristic
      BEGIN
         INSERT INTO #products
         SELECT prod_id FROM product_group_data WHERE product_grp_id = @groupid
      END
    Else If @QueryType = 3 	  	 --Single Characteristic
      BEGIN
         INSERT INTO #products
         SELECT DISTINCT prod_id FROM pu_characteristics WHERE prop_id = @propid AND char_id = @charid
      END
    Else 	  	  	  	 --Group and Property
      BEGIN
         INSERT INTO #products
         SELECT prod_id FROM product_group_data WHERE product_grp_id = @groupid
         INSERT INTO #products
         SELECT DISTINCT prod_id FROM pu_characteristics WHERE prop_id = @propid AND char_id = @charid
      END
    --EndIf  @QueryType ..
    If @MasterUnit Is Null
      BEGIN
        If @torder = 1 
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.prod_code
            FROM production_starts ps
            JOIN #products p on ps.prod_id = p.prod_id 
            JOIN prod_units pu on pu.pu_id = ps.pu_id
            JOIN products pt on pt.prod_id = ps.prod_id 
            WHERE (start_time BETWEEN @starttime AND @endtime) 
 	        OR (end_time BETWEEN @starttime AND @endtime) 
 	        OR (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	   	  --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ORDER BY ps.start_time ASC 
        Else --@torder <> 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.prod_code
            FROM production_starts ps
            JOIN #products p on ps.prod_id = p.prod_id 
            JOIN prod_units pu on pu.pu_id = ps.pu_id
            JOIN products pt on pt.prod_id = ps.prod_id 
            WHERE (start_time BETWEEN @starttime AND @endtime) 
 	        OR (end_time BETWEEN @starttime AND @endtime) 
 	        OR (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	   	  --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ORDER BY ps.start_time DESC 
         --EndIf @torder
      END
    Else --@MasterUnit NOT Null
      BEGIN
        If @torder = 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.prod_code
            FROM production_starts ps
            JOIN #products p on ps.prod_id = p.prod_id 
            JOIN prod_units pu on pu.pu_id = ps.pu_id
            JOIN products pt on pt.prod_id = ps.prod_id 
            WHERE ps.pu_id = @MasterUnit 
 	       AND (    (start_time BETWEEN @starttime AND @endtime) 
 	  	     OR (end_time BETWEEN @starttime AND @endtime) 
 	  	     OR (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	   	       --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                  ) 
            ORDER BY ps.start_time ASC 
        Else --@torder <> 1
          SELECT Production_Unit = pu.pu_desc,Start_Time = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,@InTimeZone),End_Time = dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,@InTimeZone), pt.prod_code
            FROM production_starts ps
            JOIN #products p on ps.prod_id = p.prod_id 
            JOIN prod_units pu on pu.pu_id = ps.pu_id
            JOIN products pt on pt.prod_id = ps.prod_id 
            WHERE ps.pu_id = @MasterUnit 
 	       AND (    (start_time BETWEEN @starttime AND @endtime) 
 	  	     OR (end_time BETWEEN @starttime AND @endtime) 
 	  	     OR (start_time <= @starttime AND (end_time > @endtime OR end_time is null))
 	   	       --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                  ) 
            ORDER BY ps.start_time DESC 
 	 --EndIf
      END
    --EndIf @Master ..  
    DROP TABLE #products
  END
--EndIf @QueryType = 5
