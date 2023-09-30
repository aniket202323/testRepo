Create Procedure dbo.spXLA_DowntimeDetail_NPT
 	   @STime 	 datetime
 	 , @ETime 	 datetime
 	 , @PU_Id 	 int 	  	  	 --Add-In;sLine (which is MasterUnit)
 	 , @SelectSource 	 int 	  	  	 -- 	  	  	  slave units
 	 , @SelectR1 	 int
 	 , @SelectR2 	 int
 	 , @SelectR3 	 int
 	 , @SelectR4 	 int
 	 , @ProdId 	 int 
 	 , @GroupId 	 int
 	 , @PropId 	 int
 	 , @CharId 	 int
 	 , @TOrder 	 tinyint = NULL
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @STime = @STime at time zone @InTimeZone at time zone @DBTz 
SELECT @ETime = @etime at time zone @InTimeZone at time zone @DBTz 
DECLARE @QueryType  	 tinyint
DECLARE @MasterUnit  	 int
DECLARE @Line 	  	 Varchar(50)
DECLARE @Unspecified varchar(50)
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @PU_Id
CREATE TABLE #prod_starts (PU_Id int, prod_id int, start_time datetime, end_time datetime NULL)
--
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
--Figure Out Query Type
if @prodid is not null
  SELECT @QueryType = 1   	  	 --Single Product
Else If @groupid is not null AND @propid is null 
  SELECT @QueryType = 2   	  	 --Single Group
Else If @propid is not null AND @groupid is null
  SELECT @QueryType = 3   	  	 --Single Characteristic
Else If @propid is not null AND @groupid is not null
  SELECT @QueryType = 4   	  	 --Group and Property  
else
  SELECT @QueryType = 5 	  	  	 --No product grouping
--  ------------------------------------
--  Fill out product-related temp table 
--  ------------------------------------
If @QueryType = 5  	  	  	 --No product grouping
  BEGIN
    If @MasterUnit Is NULL
 	 BEGIN
            INSERT INTO #prod_starts
            SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
              FROM  production_starts ps
 	      WHERE  (start_time BETWEEN @STime AND @ETime) 
 	  	 OR  (end_time BETWEEN @STime AND @ETime) 
 	  	 OR  (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	  	 --change start_time & end_time conditions ; MSi/MT/3-14-2001 	  	     
 	 END
    Else    --@MasterUnit not null
 	 BEGIN
            INSERT INTO #prod_starts
            SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
              FROM  production_starts ps
             WHERE  (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
 	        AND  (    (start_time BETWEEN @STime AND @ETime) 
 	  	       OR (end_time BETWEEN @STime AND @ETime) 
 	  	       OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	  	 --change start_time & end_time conditions ; MSi/MT/3-14-2001
 	  	     )
 	 END
    --EndIf @MasterUnit
  END
Else If @QueryType = 1 	  	  	 --Single Product
  BEGIN
    If @MasterUnit Is NULL
 	 BEGIN
            INSERT INTO #prod_starts
            SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
              FROM  production_starts ps
 	      WHERE  prod_id = @prodid 
 	        AND  ( 	  (start_time BETWEEN @STime AND @ETime) 
 	  	       OR (end_time BETWEEN @STime AND @ETime) 
 	  	       OR (start_time <= @STime AND ((end_time > @ETime) OR (end_time is null)))
 	  	  	 --change start_time & end_time conditions ; MSi/MT/3-14-2001
                    )
 	 END
    Else     --@MasterUnit not null
 	 BEGIN
            INSERT INTO #prod_starts
            SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
              FROM  production_starts ps
             WHERE  (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
 	        AND  prod_id = @prodid 
 	        AND  ( 	  (start_time BETWEEN @STime AND @ETime) 
 	  	       OR (end_time BETWEEN @STime AND @ETime) 
 	  	       OR (start_time <= @STime AND ((end_time > @ETime) OR (end_time is null)))
 	  	  	 --change start_time & end_time conditions ; MSi/MT/3-14-2001
                    )
 	 END
    --EndIf @MasterUnit
  END
Else 	  	  	  	  	 --Product Group of sort
  BEGIN
    CREATE TABLE #products (prod_id int)
    if @QueryType = 2  	  	  	 --Single Product Group
      BEGIN
         INSERT INTO #products
         SELECT prod_id  FROM product_group_data  WHERE product_grp_id = @groupid
      END
    Else If @QueryType = 3 	  	 --Single Characteristic
      BEGIN
         INSERT INTO #products
         SELECT DISTINCT prod_id  FROM pu_characteristics WHERE prop_id = @propid AND char_id = @charid
      END
    Else 	  	  	  	 --Group and Property  
      BEGIN
         INSERT INTO #products
         SELECT prod_id  FROM product_group_data WHERE product_grp_id = @groupid
         INSERT INTO #products
         SELECT DISTINCT prod_id FROM pu_characteristics  WHERE prop_id = @propid AND char_id = @charid
      END
    If @MasterUnit Is NULL
 	 BEGIN
          INSERT INTO #prod_starts
          SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
            FROM  production_starts ps
            JOIN  #products p ON ps.prod_id = p.prod_id 
 	    WHERE  (start_time BETWEEN @STime AND @ETime) 
 	       OR  (end_time BETWEEN @STime AND @ETime) 
 	       OR  (start_time <= @STime AND ((end_time > @ETime) OR (end_time is null)))
 	  	  	 --change Star_time & end_time  ; MSi/MT/3-14-2001                  
 	 END
    Else     --@MasterUnit not null
 	 BEGIN
          INSERT INTO #prod_starts
          SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
            FROM  production_starts ps
            JOIN  #products p ON ps.prod_id = p.prod_id 
           WHERE  (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
 	      AND  (    (start_time BETWEEN @STime AND @ETime) 
 	  	     OR (end_time BETWEEN @STime AND @ETime) 
 	  	     OR (start_time <= @STime AND ((end_time > @ETime) OR (end_time is null)))
 	  	  	 --change Star_time & end_time  ; MSi/MT/3-14-2001                  
                  )
 	 END
    --EndIf @MasterUnit is null
    DROP TABLE #products
  END
--EndIf =5 Fill Out Product-Related Temp Tables
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
 	   Detail_Id 	  	 int
 	 , Start_Time 	  	 datetime
 	 , End_Time 	  	 datetime NULL
  	 , Duration 	  	 real NULL
 	 , SourcePU 	  	 int NULL
 	 , MasterUnit 	  	 Int NULL
 	 , R1_Id 	  	  	 int NULL
 	 , R2_Id 	  	  	 int NULL
 	 , R3_Id  	  	 int NULL
 	 , R4_Id  	  	 int NULL
 	 , Fault_Id  	  	 int NULL
 	 , Status_Id  	  	 int NULL
 	 , Prod_Id  	  	 int NULL
 	 , First_Comment_Id 	 int NULL
 	 , Last_Comment_Id  	 int NULL
 	 , NPT tinyint 	 NULL
)
-- Get All The Detail Records We Care About
-- Insert Data Into #TopNDR Temp Table
If @MasterUnit Is NULL
   BEGIN
 	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id, Prod_Id)
 	 SELECT  D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, TEFault_Id, TEStatus_Id, PS.Prod_Id
          FROM  Timed_Event_Details D
 	   --change condition format of star_time & end_time format ; MSi/MT/3-14-2001
          --JOIN #Prod_Starts PS on D.Start_Time >= PS.Start_Time AND ((D.Start_Time < PS.End_Time) OR (PS.End_Time Is Null))   	  	 */
          JOIN #Prod_Starts PS ON PS.PU_Id = D.Source_PU_Id AND (PS.Start_Time <= D.Start_Time AND (PS.End_Time > D.Start_Time OR PS.End_Time Is Null))
 	   JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
         WHERE (D.Start_Time >= @STime AND D.Start_Time < @ETime) 
 	     OR (D.End_Time > @STime AND D.End_Time <= @ETime) 
 	     OR (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	     OR (D.Start_Time < @STime AND D.End_Time Is Null) 	        
    END
Else    --@MasterUnit not null
   BEGIN
 	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id, Prod_Id)
 	 SELECT  D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, TEFault_Id, TEStatus_Id, PS.Prod_Id
          FROM  Timed_Event_Details D
 	   --change condition format of star_time & end_time format ; MSi/MT/3-14-2001
          --JOIN #Prod_Starts PS on D.Start_Time >= PS.Start_Time AND ((D.Start_Time < PS.End_Time) OR (PS.End_Time Is Null))   	  	 */
          JOIN #Prod_Starts PS ON (PS.Start_Time <= D.Start_Time AND (PS.End_Time > D.Start_Time OR PS.End_Time Is Null))
 	   JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.PU_Id = @MasterUnit 
           AND (    (D.Start_Time >= @STime AND D.Start_Time < @ETime) 
 	          OR (D.End_Time > @STime AND D.End_Time <= @ETime)
 	          OR (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	          OR (D.Start_Time < @STime AND D.End_Time Is Null)
 	        )
    END
--EndIf @PU_Id
-- Clean up unwanted PU_Id = 0 (marked for unused/obsolete)
DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
DROP TABLE #Prod_Starts
--Delete For Additional Selection Criteria
If @SelectSource Is Not Null 	  	  	 --@SelectSource = AddIn's locations
    BEGIN 	 
 	 If @SelectSource = -1 	  	  	 --MSi/MT/4/11/01:AddIn's "None" location=>to retain only null locations, delete others
 	     DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
 	 Else
 	     --DELETE FROM #TopNDR WHERE SourcePU Is Null Or SourcePU <> @SelectSource
 	     DELETE FROM #TopNDR WHERE (SourcePU Is NULL AND MasterUnit <> @PU_Id) OR SourcePU <> @SelectSource
 	 --EndIf
    END
If @SelectR1 Is Not Null
  DELETE FROM #TopNDR WHERE R1_Id Is Null Or R1_Id <> @SelectR1  
If @SelectR2 Is Not Null
  DELETE FROM #TopNDR WHERE R2_Id Is Null Or R2_Id <> @SelectR2
If @SelectR3 Is Not Null
  DELETE FROM #TopNDR WHERE R3_Id Is Null Or R3_Id <> @SelectR3
If @SelectR4 Is Not Null
  DELETE FROM #TopNDR WHERE R4_Id Is Null Or R4_Id <> @SelectR4
-- Take Care Of Record Start And End Times 
UPDATE #TopNDR SET start_time = @STime WHERE start_time < @STime
UPDATE #TopNDR SET end_time = @ETime WHERE end_time > @ETime OR end_time is null
UPDATE #TopNDR SET duration = datediff(ss, start_time, end_time) / 60.0
CREATE TABLE #Comments (Detail_Id Int, FirstComment int NULL, LastComment int NULL)
--Get First And Last Comment
INSERT INTO #Comments
  SELECT  D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
    FROM  #TopNDR D, Waste_n_Timed_Comments C
   WHERE  C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 2
GROUP BY  D.Detail_Id   
UPDATE #TopNDR 
    SET  First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else Null End) 
   FROM  #TopNDR D, #Comments C 
  WHERE  D.Detail_Id = C.Detail_Id 
DROP TABLE #Comments
---------------------------------------------------------------------------------------    
/*
 	  	 Non Productive Time
 	  	 
*/
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @STime THEN @STime
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @ETime THEN @ETime
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @ETime
                  AND np.End_Time > @STime
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TopNDR SET Start_Time = n.Endtime,
 	  	  	  	  	 NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND End_time > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TopNDR SET End_Time = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #TopNDR 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND End_Time < n.Endtime AND End_Time > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TopNDR SET Start_Time = End_Time,
 	  	  	  	  	 NPT = 1
FROM 	 #TopNDR  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (End_time BETWEEN n.StartTime AND n.EndTime))
Update #TopNDR Set Duration =DateDiff(ss,Start_Time,End_Time)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TopNDR  SET NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND End_Time) AND (n.Endtime BETWEEN Start_Time AND End_Time))
-- --------------------------------------------------  
-- --------------------------------------------------
-- RETURN DATA
-- --------------------------------------------------
If @MasterUnit Is NOT NULL SELECT @Line = PU_Desc FROM Prod_Units WHERE PU_Id = @MasterUnit
 	 --(If "Line" (master unit) is specified, we'll need its description)
If @TOrder = 1
    If @MasterUnit Is NULL
 	 BEGIN
 	     SELECT  [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , D.Duration
 	  	   , Line 	 = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	  	 -- [When Master Unit is SourcePu we will report it as a location]
 	  	   , Location 	 = Case When D.SourcePU Is Null Then @Unspecified Else PU.PU_Desc End
 	  	   , Reason1 	 = Case When D.R1_Id Is Null Then @Unspecified Else R1.Event_Reason_Name End
 	  	   , Reason2 	 = Case When D.R2_Id Is Null Then @Unspecified Else R2.Event_Reason_Name End
 	  	   , Reason3 	 = Case When D.R3_Id Is Null Then @Unspecified Else R3.Event_Reason_Name End
 	  	   , Reason4 	 = Case When D.R4_Id Is Null Then @Unspecified Else R4.Event_Reason_Name End
 	  	   , Fault 	 = Case When D.Fault_Id Is Null Then @Unspecified Else F.TEFault_Name End
 	  	   , Status 	 = Case When D.Status_Id Is Null Then @Unspecified Else S.TEStatus_Name End
 	  	   , P.Prod_Code
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	       JOIN  Products P on P.Prod_Id = D.Prod_Id
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
 	   LEFT OUTER JOIN  Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
 	   WHERE D.NPT IS NULL 	 
 	   ORDER BY  D.Start_Time ASC
 	 END
    Else    --@MasterUnit specified; don't need line
 	 BEGIN
 	     SELECT  [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , D.Duration
 	  	   , Line = @Line
 	  	  	 -- [When Master Unit is SourcePu we will report it as a location]
 	  	   , Location = Case When D.SourcePU Is Null Then @Unspecified Else PU.PU_Desc End
 	  	   , Reason1 =  Case When D.R1_Id Is Null Then @Unspecified Else R1.Event_Reason_Name End
 	  	   , Reason2 =  Case When D.R2_Id Is Null Then @Unspecified Else R2.Event_Reason_Name End
 	  	   , Reason3 =  Case When D.R3_Id Is Null Then @Unspecified Else R3.Event_Reason_Name End
 	  	   , Reason4 =  Case When D.R4_Id Is Null Then @Unspecified Else R4.Event_Reason_Name End
 	  	   , Fault =  Case When D.Fault_Id Is Null Then @Unspecified Else F.TEFault_Name End
 	  	   , Status =  Case When D.Status_Id Is Null Then @Unspecified Else S.TEStatus_Name End
 	  	   , P.Prod_Code
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	       JOIN  Products P on P.Prod_Id = D.Prod_Id
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
 	   WHERE D.NPT IS NULL 	 
 	   ORDER BY  D.Start_Time ASC
 	 END
    --EndIf @MasterUnit
Else   -- Descending
    If @MasterUnit Is NULL
 	 BEGIN
 	     SELECT  [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , D.Duration
 	  	   , Line 	 = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	  	 -- [When Master Unit is SourcePu we will report it as a location]
 	  	   , Location 	 = Case When D.SourcePU Is Null Then @Unspecified Else PU.PU_Desc End
 	  	   , Reason1 	 = Case When D.R1_Id Is Null Then @Unspecified Else R1.Event_Reason_Name End
 	  	   , Reason2 	 = Case When D.R2_Id Is Null Then @Unspecified Else R2.Event_Reason_Name End
 	  	   , Reason3 	 = Case When D.R3_Id Is Null Then @Unspecified Else R3.Event_Reason_Name End
 	  	   , Reason4 	 = Case When D.R4_Id Is Null Then @Unspecified Else R4.Event_Reason_Name End
 	  	   , Fault 	 = Case When D.Fault_Id Is Null Then @Unspecified Else F.TEFault_Name End
 	  	   , Status 	 = Case When D.Status_Id Is Null Then @Unspecified Else S.TEStatus_Name End
 	  	   , P.Prod_Code
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	       JOIN  Products P on P.Prod_Id = D.Prod_Id
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
 	   LEFT OUTER JOIN  Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
 	   WHERE D.NPT IS NULL 	 
 	   ORDER BY  D.Start_Time DESC
 	 END
    Else    --@MasterUnit specified
 	 BEGIN
 	     SELECT  [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
 	  	   , D.Duration
 	  	   , Line = @Line
 	  	  	 -- [When Master Unit is SourcePu we will report it as a location]
 	  	   , Location = Case When D.SourcePU Is Null Then @Unspecified Else PU.PU_Desc End
 	  	   , Reason1 =  Case When D.R1_Id Is Null Then @Unspecified Else R1.Event_Reason_Name End
 	  	   , Reason2 =  Case When D.R2_Id Is Null Then @Unspecified Else R2.Event_Reason_Name End
 	  	   , Reason3 =  Case When D.R3_Id Is Null Then @Unspecified Else R3.Event_Reason_Name End
 	  	   , Reason4 =  Case When D.R4_Id Is Null Then @Unspecified Else R4.Event_Reason_Name End
 	  	   , Fault =  Case When D.Fault_Id Is Null Then @Unspecified Else F.TEFault_Name End
 	  	   , Status =  Case When D.Status_Id Is Null Then @Unspecified Else S.TEStatus_Name End
 	  	   , P.Prod_Code
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	       JOIN  Products P on P.Prod_Id = D.Prod_Id
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
 	   WHERE D.NPT IS NULL 	 
 	   ORDER BY  D.Start_Time DESC
 	 END
    --EndIf @MasterUnit
 --EndIf ToOrder...
DROP TABLE #TopNDR
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
