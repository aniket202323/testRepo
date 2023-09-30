-- ECR #30478: mt/8-8-2005 -- sync summary number of occurrences with row counts in downtime details; keep rows with null SourcePU if master unit matches input PU_Id
--
--
Create Procedure dbo.spXLA_DowntimeSummary
 	   @STime 	 datetime
 	 , @ETime 	 datetime
 	 , @PU_Id 	 int 	  	 --Add-In's "Line" is masterUnit here
 	 , @SelectSource int 	  	 --Slave Units PU_Id in Timed_Event_
 	 , @SelectR1 	 int
 	 , @SelectR2 	 int
 	 , @SelectR3 	 int
 	 , @SelectR4 	 int
 	 , @ReasonLevel 	 int
 	 , @ProdId 	 int
 	 , @GroupId 	 int
 	 , @PropId 	 int
 	 , @CharId 	 int
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @STime = @STime at time zone @InTimeZone at time zone @DBTz 
SELECT @ETime = @etime at time zone @InTimeZone at time zone @DBTz 
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
--Select @MasterUnit = @PU_Id
create table #prod_starts (PU_Id int, prod_id int, start_time datetime, end_time datetime NULL)
--Figure Out Query Type
if @prodid is not null
  select @QueryType = 1   	  	 --Single Product
else if @groupid is not null and @propid is null 
  select @QueryType = 2   	  	 --Single Group
else if @propid is not null and @groupid is null
  select @QueryType = 3   	  	 --Single Characteristic
else if @propid is not null and @groupid is not null
  select @QueryType = 4   	  	 --Group and Property  
else
  select @QueryType = 5 	  	  	 --No product information;  all null in (@ProdId, @GroupId, @PropId, @CharId)
If @QueryType = 5 	  	  	 --No product Information
  BEGIN
    If @MasterUnit IS NULL
 	 BEGIN
 	     INSERT INTO #prod_starts
 	     SELECT ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
 	       FROM production_starts ps
 	      WHERE start_time BETWEEN @STime AND @ETime
 	  	 OR (end_time BETWEEN @STime AND @ETime)
 	  	 OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	 --Change start_time > to @STime >= @ETime ; Msi/Mt/3-14-2001
 	 END
    Else
 	 BEGIN
 	     INSERT INTO #prod_starts
 	     SELECT ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
 	       FROM production_starts ps
 	      WHERE PU_Id = @MasterUnit 
 	        AND PU_Id <> 0
 	        AND (    (start_time BETWEEN @STime AND @ETime)
 	  	      OR (end_time BETWEEN @STime AND @ETime)  
 	  	      OR  (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	      --Change start_time < @STime to start_time <= @STime ; Msi/Mt/3-14-2001
 	  	    )
 	 END
  END
Else If @QueryType = 1 	  	  	 --Single Product
  BEGIN
    IF @MasterUnit IS NULL
 	 BEGIN
 	     INSERT INTO #prod_starts
 	     SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
 	       FROM  production_starts ps
 	      WHERE  prod_id = @prodid 
 	        AND  ( 	  (start_time BETWEEN @STime AND @ETime) 
 	  	       OR (end_time BETWEEN @STime AND @ETime) 
 	  	       OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	  	 --Change start_time < @STime to start_time <= @STime ; Msi/Mt/3-14-2001
 	  	     )
 	 END
    ELSE     --@MasterUnit not null
 	 BEGIN
 	     INSERT INTO #prod_starts
 	     SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
 	       FROM  production_starts ps
 	      WHERE  PU_Id = @MasterUnit 
 	        AND  PU_Id <> 0
 	        AND  prod_id = @prodid 
 	        AND  ( 	  (start_time BETWEEN @STime AND @ETime) 
 	  	       OR (end_time BETWEEN @STime AND @ETime) 
 	  	       OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	  	 --Change start_time < @STime to start_time <= @STime ; Msi/Mt/3-14-2001
 	  	     )
 	 END
    --ENDIF @MasterUnit
  END
Else 	  	  	  	  	 --We have product grouping info
  BEGIN
    create table #products (prod_id int)
    If @QueryType = 2  	  	  	 --Single Group
        Begin
           INSERT INTO #products
           SELECT prod_id FROM product_group_data WHERE product_grp_id = @groupid
        End
    Else if @QueryType = 3 	  	 --Single Characteristic
        Begin
           INSERT INTO #products
           SELECT DISTINCT prod_id  FROM pu_characteristics  WHERE prop_id = @propid AND char_id = @charid
        End
    Else 	  	  	  	 --Group & Property
        Begin
           INSERT INTO #products
           SELECT prod_id FROM product_group_data WHERE product_grp_id = @groupid
 	   INSERT INTO #products
          SELECT DISTINCT prod_id  FROM pu_characteristics  WHERE prop_id = @propid  AND char_id = @charid
        End
    --EndIf @QueryType =2 ...
    IF @MasterUnit IS NULL
 	 BEGIN
 	     INSERT INTO #prod_starts
 	     SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
 	       FROM  production_starts ps
 	       JOIN  #products p ON ps.prod_id = p.prod_id 
 	      WHERE (start_time BETWEEN @STime AND @ETime)
 	  	 OR (end_time BETWEEN @STime AND @ETime) 
 	  	 OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	  	 --Change start_time < @STime to start_time <= @STime ; Msi/Mt/3-14-2001
 	 END
    ELSE     --@MasterUnit not null
 	 BEGIN
 	     INSERT INTO #prod_starts
 	     SELECT  ps.PU_Id, ps.prod_id, ps.start_time, ps.end_time
 	       FROM  production_starts ps
 	       JOIN  #products p ON ps.prod_id = p.prod_id 
 	      WHERE  PU_Id = @MasterUnit 
 	        AND  PU_Id <> 0
 	        AND  ( 	 (start_time BETWEEN @STime AND @ETime) 
 	  	      OR (end_time BETWEEN @STime AND @ETime) 
 	  	      OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	  	 --Change start_time < @STime to start_time <= @STime ; Msi/Mt/3-14-2001
 	  	     )
 	 END
    --ENDIF @MasterUnit
    DROP TABLE #products
  END
Create Table #MyReport (
 	   ReasonName 	  	 varchar(100) 	 --MSI/MT/6-25-2001 length change; from 30 to 100
 	 , NumberOfOccurances 	 int  NULL
 	 , TotalReasonMinutes  	 real NULL
 	 , AvgReasonMinutes  	 real NULL
 	 , TotalDowntimeMinutes 	 real NULL
 	 , TotalOperatingMinutes real NULL
)
-- Get All TED Records In Field I Care About
create table #TopNDR (
  	   Start_Time 	 datetime
 	 , End_Time 	 datetime NULL
 	 , Duration  	 real NULL
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
If @QueryType <> 5 	 --(Has some product information)
  BEGIN
    If @PU_Id IS NULL
 	 BEGIN
 	     INSERT INTO #TopNDR (Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	     SELECT    D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
 	  	     , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, TEFault_Id, TEStatus_Id  
 	       FROM  Timed_Event_Details D
 	       --change start_time conditions : MSi/MT/3-14-2001
 	       --Join #Prod_Starts PS On D.Start_Time >= PS.Start_Time and ((D.Start_Time < PS.End_Time) or (PS.End_Time Is NULL))
 	       JOIN  #Prod_Starts PS ON PS.Start_Time <= D.Start_Time AND (PS.End_Time > D.Start_Time OR PS.End_Time Is NULL)
 	       JOIN  Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	      WHERE  (D.Start_Time >= @STime AND D.Start_Time < @ETime) 
 	  	 OR  (D.End_Time > @STime AND D.End_Time <= @ETime) 
 	  	 OR  (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	  	 OR  (D.Start_Time < @STime AND D.End_Time Is Null) 	  	     
 	 END
    Else  --@PU_Id not null
 	 BEGIN
 	     INSERT INTO #TopNDR (Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	     SELECT    D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
 	  	     , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, TEFault_Id, TEStatus_Id  
 	       FROM  Timed_Event_Details D
 	       --change start_time conditions : MSi/MT/3-14-2001
 	       --Join #Prod_Starts PS On D.Start_Time >= PS.Start_Time and ((D.Start_Time < PS.End_Time) or (PS.End_Time Is NULL))
 	  	 
 	       JOIN  #Prod_Starts PS ON PS.Start_Time <= D.Start_Time AND (PS.End_Time > D.Start_Time OR PS.End_Time Is NULL)
 	       JOIN  Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	      WHERE  (D.PU_Id = @PU_Id) 
 	        AND  (    (D.Start_Time >= @STime AND D.Start_Time < @ETime) 
 	  	       OR (D.End_Time > @STime AND D.End_Time <= @ETime) 
 	  	       OR (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	  	       OR (D.Start_Time < @STime AND D.End_Time Is Null)
 	  	     )
 	 END
    --EndIf @PU_Id
  END
Else   --@QueryType = 5 	 (NO Product Information)
  BEGIN
    If @PU_Id IS NULL
 	 BEGIN
 	     INSERT INTO #TopNDR (Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	     SELECT  D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
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
 	     INSERT INTO #TopNDR (Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	     SELECT  D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
 	  	   , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, TEFault_Id, TEStatus_Id  
 	       FROM  Timed_Event_Details D
 	       JOIN  Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	      WHERE  (D.PU_Id = @PU_Id) 
 	        AND  ( 	  (D.Start_Time >= @STime AND D.Start_Time < @ETime) 
 	  	       OR (D.End_Time > @STime AND D.End_Time <= @ETime) 
 	  	       OR (D.Start_Time < @STime AND D.End_Time > @ETime AND D.End_Time Is Not Null) 
 	  	       OR (D.Start_Time < @STime AND D.End_Time Is Null)
 	  	     )
 	 END
    --EndIf @PU_Id
  END
--EndIf @@QueryType [Insert Data Into temp table #TopNDR]
DROP TABLE #Prod_Starts
--Clean up zero PU_Id (comes from 
DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
UPDATE #TopNDR 	 SET start_time = @STime WHERE start_time < @STime
UPDATE #TopNDR  SET end_time = @ETime  WHERE end_time > @ETime OR end_time is null
UPDATE #TopNDR  SET duration = datediff(ss, start_time, end_time) / 60.0
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
 	     --BEGIN Delete From #TopNDR Where SourcePU Is Null Or SourcePU <> @SelectSource                         -- ECR #30478: mt/8-8-2005
 	     --END                                                                                                   -- ECR #30478: mt/8-8-2005
 	     Delete From #TopNDR Where ( SourcePU Is Null AND MasterUnit <> @PU_Id ) Or SourcePU <> @SelectSource    -- ECR #30478: mt/8-8-2005
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
INSERT INTO #MyReport (ReasonName,
                       NumberOfOccurances,
                       TotalReasonMinutes,
                       AvgReasonMinutes,
                       TotalDowntimeMinutes,
                       TotalOperatingMinutes)
  SELECT  Reason_Name, count(duration), Total_Duration = sum(Duration),  (sum(Duration) / count(Duration)), @TotalPLT, @TotalOperating
    FROM  #TopNDR
GROUP BY  Reason_Name
ORDER BY  Total_Duration DESC
SELECT * FROM #MyReport ORDER BY TotalReasonMinutes DESC
DROP TABLE #TopNDR
DROP TABLE #MyReport
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
