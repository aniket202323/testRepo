-- spXLA_DowntimeSummary_NoProduct_NPT: ECR #25307: mt/3-26-2003: added Uptime 
--
-- ECR #30478: mt/8-8-2005 -- sync summary number of occurrences with row counts in downtime details; keep rows with null SourcePU if master unit matches input PU_Id
--
Create Procedure dbo.[spXLA_DowntimeSummary_NoProduct_NPT_Bak_177]
 	   @STime 	 datetime
 	 , @ETime 	 datetime
 	 , @PU_Id 	 int 	  	 --Add-In's "Line" is masterUnit here
 	 , @SelectSource int 	  	 --Slave Units PU_Id in Timed_Event_
 	 , @SelectR1 	 int
 	 , @SelectR2 	 int
 	 , @SelectR3 	 int
 	 , @SelectR4 	 int
 	 , @ReasonLevel 	 int
 	 , @Username Varchar(50)= Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @STime = dbo.fnServer_CmnConvertToDBTime(@STime,@InTimeZone)
SELECT @ETime = dbo.fnServer_CmnConvertToDBTime(@ETime,@InTimeZone)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
Declare @TotalPLT 	 real
Declare @TotalOperating real
declare @QueryType 	 tinyint
declare @MasterUnit 	 int
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else Select @MasterUnit = @PU_Id
CREATE TABLE #MyReport (
 	   ReasonName 	  	 varchar(100) 	 --MSI/MT/6-25-2001 length change; from 30 to 100
 	 , NumberOfOccurances 	 int  NULL
 	 , TotalReasonMinutes  	 real NULL
 	 , AvgReasonMinutes  	 real NULL
 	 , TotalDowntimeMinutes 	 real NULL
        , AvgUptimeMinutes      Real NULL 	 --mt/3-26-2003
        , TotalUptimeMinutes    Real NULL 	 --mt/3-26-2003
 	 , TotalOperatingMinutes real NULL
)
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
  	   Start_Time 	 datetime
 	 , End_Time 	 datetime NULL
 	 , Duration  	 real NULL
        , Uptime        real NULL              --mt/3-26-2003
 	 , Reason_Name 	 varchar(100) NULL
 	 , SourcePU  	 int NULL
 	 , MasterUnit 	 Int NULL
 	 , R1_Id 	  	 int NULL
 	 , R2_Id 	  	 int NULL
 	 , R3_Id 	  	 int NULL
 	 , R4_Id 	  	 int NULL
 	 , Fault_Id 	 int NULL
 	 , Status_Id 	 int NULL
)
--   ---------------------------------------
--   Insert Data Into Temp Table #TopNDR
--   ---------------------------------------
If @PU_Id IS NULL
    BEGIN
 	 INSERT INTO #TopNDR (Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	 SELECT  D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
 	       , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, TEFault_Id, TEStatus_Id  
 	  FROM  Timed_Event_Details D
 	  JOIN  Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	 WHERE  (D.Start_Time >= @STime AND D.Start_Time < @ETime)
 	    OR  (D.End_Time > @STime AND D.End_Time <= @ETime) 
 	    OR  (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	    OR  (D.Start_Time < @STime AND D.End_Time Is Null) 	  	     
    END
Else   --@PU_Id not null
    BEGIN
 	 INSERT INTO #TopNDR (Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	 SELECT  D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
 	       , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, TEFault_Id, TEStatus_Id  
 	  FROM  Timed_Event_Details D
 	  JOIN  Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	 WHERE  (D.PU_Id = @PU_Id) 
 	   AND  (    (D.Start_Time >= @STime AND D.Start_Time < @ETime) 
 	          OR (D.End_Time > @STime AND D.End_Time <= @ETime) 
 	  	  OR (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	  	  OR (D.Start_Time < @STime AND D.End_Time Is Null)
 	        )
    END
--EndIf @PU_Id
--Clean up zero PU_Id (comes from 
DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
UPDATE #TopNDR 	 SET start_time = @STime WHERE start_time < @STime
UPDATE #TopNDR  SET end_time = @ETime  WHERE end_time > @ETime OR end_time is null
UPDATE #TopNDR  SET duration = datediff(ss, start_time, end_time) / 60.0
-----------------------------------------------------
--NPT Logic Started
-----------------------------------------------------
-- A New temp table to maintain UPTIME 
DECLARE @NPTCount int
SET @NPTCount = 0
  UPDATE #TopNDR  SET start_time = @STime WHERE start_time < @STime
  UPDATE #TopNDR  SET end_time = @ETime  WHERE end_time > @ETime OR end_time is null
  UPDATE #TopNDR  SET Duration = DATEDIFF(ss, start_time, end_time) / 60.0
----------------------------------------
 	 -------NPT-------
----------------------------------------
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
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,StarTTime,EndTime)/60.0
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TopNDR SET Start_Time = n.Endtime
FROM #TopNDR  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND End_time > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TopNDR SET End_Time = n.Starttime FROM 	 #TopNDR 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND End_Time < n.Endtime AND End_Time > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TopNDR SET Start_Time = End_Time,
 	  	  	  	  	 @NPTCount = @NPTCount + 1
FROM 	 #TopNDR  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (End_time BETWEEN n.StartTime AND n.EndTime))
Update #TopNDR Set Duration =DateDiff(ss,Start_Time,End_Time)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TopNDR  SET Duration = (Datediff(ss,Start_Time,End_Time) - DateDiff(ss,n.StartTime,n.EndTime))/60.0
FROM #TopNDR  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND End_Time) AND (n.Endtime BETWEEN Start_Time AND End_Time))
------------------------------------------
-- Calculate Total Downtime
SELECT @TotalPLT = (SELECT SUM(duration) FROM #TopNDR) 
--Adjust For Scheduled Down If Necessary 
SELECT @TotalOperating = 0
SELECT @TotalOperating = (datediff(ss, @STime, @ETime) / 60.0) - @TotalOperating
-- Delete (filter out) based on additional selection criteria
If @SelectSource Is Not Null 	  	  	 --@SelectSource = AddIn's Location 
    BEGIN
 	 If @SelectSource = -1 	  	  	 --MSi/MT/4-11-2001: AddIn's "None" keyword; Want to retain null location, delete others
 	     BEGIN Delete From #TopNDR Where SourcePU Is NOT Null
 	     END
 	 Else
 	     --BEGIN Delete From #TopNDR Where SourcePU Is Null Or SourcePU <> @SelectSource                      -- ECR #30478: mt/8-8-2005
 	     --END                                                                                                -- ECR #30478: mt/8-8-2005
 	     Delete From #TopNDR Where ( SourcePU Is Null AND MasterUnit <> @PU_Id ) Or SourcePU <> @SelectSource -- ECR #30478: mt/8-8-2005
 	 --EndIf
    END
If @SelectR1 Is Not Null
  Delete From #TopNDR Where R1_Id Is Null Or R1_Id <> @SelectR1  
If @SelectR2 Is Not Null
  Delete From #TopNDR Where R2_Id Is Null Or R2_Id <> @SelectR2
If @SelectR3 Is Not Null
  Delete From #TopNDR Where R3_Id Is Null Or R3_Id <> @SelectR3
If @SelectR4 Is Not Null
  Delete From #TopNDR Where R4_Id Is Null Or R4_Id <> @SelectR4
If @MasterUnit Is NULL
    BEGIN
 	 UPDATE #TopNDR 
 	 SET Reason_Name = Case @ReasonLevel
 	  	  	  	 When 0 Then PU.PU_Desc 	  	  	 --Location (Slave Unit)
 	  	  	  	 When 1 Then R1.Event_Reason_Name
 	  	  	  	 When 2 Then R2.Event_Reason_Name
 	  	  	  	 When 3 Then R3.Event_Reason_Name
 	  	  	  	 When 4 Then R4.Event_Reason_Name
 	  	  	  	 When 5 Then F.TEFault_Name
 	  	  	  	 When 6 Then S.TEStatus_Name
 	  	  	  	 When -1 Then PU2.PU_Desc 	  	 --Line (Master Unit)
 	  	  	   End
 	 From #TopNDR 
 	 LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.PU_Id) 	 --SourcePU's contain master and slave
 	 LEFT OUTER JOIN Prod_Units PU2 ON (#TopNDR.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
 	 LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
 	 LEFT OUTER JOIN Timed_Event_Fault F on (#TopNDR.Fault_Id = F.TEFault_Id)
 	 LEFT OUTER JOIN Timed_Event_Status S on (#TopNDR.Status_Id = S.TEStatus_Id)
    END
Else    --@masterUnit not null
    BEGIN
 	 UPDATE #TopNDR 
 	 SET Reason_Name = Case @ReasonLevel
 	  	  	  	 When 0 Then PU.PU_Desc 	  	  	 --Location (Slave PU_Id)
 	  	  	  	 When 1 Then R1.Event_Reason_Name
 	  	  	  	 When 2 Then R2.Event_Reason_Name
 	  	  	  	 When 3 Then R3.Event_Reason_Name
 	  	  	  	 When 4 Then R4.Event_Reason_Name
 	  	  	  	 When 5 Then F.TEFault_Name
 	  	  	  	 When 6 Then S.TEStatus_Name
 	  	  	   End
 	 From #TopNDR 
 	 LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.PU_Id) 	 --SourcePU's contain master and slave
 	 LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
 	 LEFT OUTER JOIN Timed_Event_Fault F on (#TopNDR.Fault_Id = F.TEFault_Id)
 	 LEFT OUTER JOIN Timed_Event_Status S on (#TopNDR.Status_Id = S.TEStatus_Id)
    END
--EndIf @MasterUnit
UPDATE #TopNDR 	 SET Reason_Name = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified') Where Reason_Name Is Null
-- Populate Temp Table With Reason Ordered By Top 20
INSERT INTO #MyReport (ReasonName
                     , NumberOfOccurances
                     , TotalReasonMinutes
                     , AvgReasonMinutes
                     , TotalDowntimeMinutes
                     , AvgUptimeMinutes       --mt/3-26-2003
                     , TotalUptimeMinutes     --mt/3-26-2003
                     , TotalOperatingMinutes)
  SELECT  Reason_Name
        , count(duration)
        , Total_Duration = sum(Duration)
        , (sum(Duration) / count(Duration))
        , @TotalPLT
        , (@TotalOperating-@TotalPLT)  / COUNT(Duration)     --mt/3-26-2003
        , (@TotalOperating-@TotalPLT)        --mt/3-26-2003, -- ECR #25108 : Arjun/2-2-2010 
        , @TotalOperating
    FROM  #TopNDR
GROUP BY  Reason_Name
ORDER BY  Total_Duration DESC
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
SELECT * FROM #MyReport order by TotalReasonMinutes desc
DROP TABLE #TopNDR
DROP TABLE #MyReport
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
