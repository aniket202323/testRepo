CREATE PROCEDURE dbo.[spXLA_AlarmSummary_Bak_177]
 	   @Var_Id 	  	 Integer
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Acknowledged 	  	 TinyInt = 0
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @ReasonLevel 	  	 Int
 	 , @Prod_Id 	  	 Int = NULL
 	 , @Group_Id 	  	 Int = NULL
 	 , @Prop_Id 	  	 Int = NULL
 	 , @Char_Id 	  	 Int = NULL
 	 , @ProductSpecified 	 TinyInt = 0
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @TotalDurations 	 Real
DECLARE @TotalOperating Real
DECLARE @QueryType 	 TinyInt
DECLARE @MasterUnit 	 Int
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @MasterUnit = v.PU_Id FROM Variables v WHERE v.Var_Id = @Var_Id
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
CREATE TABLE #MyReport (
 	   ReasonName 	  	 Varchar(100) 	 
 	 , NumberOfOccurences 	 Int  NULL
 	 , TotalReasonMinutes  	 Real NULL
 	 , AvgReasonMinutes  	 Real NULL
 	 , TotalAlarmMinutes 	 Real NULL
 	 , TotalOperatingMinutes Real NULL
)
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
  	   Start_Time 	 DateTime
 	 , End_Time 	 DateTime  	 NULL
 	 , Duration  	 Real  	  	 NULL
 	 , Reason_Name 	 Varchar(100)  	 NULL
 	 , SourcePU  	 Int  	  	 NULL
 	 , R1_Id 	  	 Int  	  	 NULL
 	 , R2_Id 	  	 Int  	  	 NULL
 	 , R3_Id 	  	 Int  	  	 NULL
 	 , R4_Id 	  	 Int  	  	 NULL
)
If @ProductSpecified = 0 GOTO PRODUCT_NOT_SPECIFIED
CREATE TABLE #Prod_Starts (PU_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
--Figure Out Query Type
If @Prod_Id Is NOT NULL SELECT @QueryType = 1   	  	  	  	  	 --Single Product
Else If @Group_Id Is NOT NULL AND @Prop_Id IS NULL SELECT @QueryType = 2   	 --Single Group
Else If @Prop_Id Is NOT NULL AND @Group_Id IS NULL SELECT @QueryType = 3   	 --Single Characteristic
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL SELECT @QueryType = 4   	 --Group and Property  
--Build Temp Product_Starts Table Our Time Duration and Product Info
If @QueryType = 1 	  	  	 --Single Product
  BEGIN
    IF @MasterUnit IS NULL
 	 BEGIN
 	     INSERT INTO #Prod_Starts
 	     SELECT  ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
 	       FROM  Production_Starts ps
 	      WHERE  Prod_Id = @Prod_Id 
 	        AND  ( 	  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	       OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
 	  	     )
 	 END
    ELSE     --@MasterUnit not null
 	 BEGIN
 	     INSERT INTO #Prod_Starts
 	     SELECT  ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
 	       FROM  Production_Starts ps
 	      WHERE  PU_Id = @MasterUnit 
 	        AND  PU_Id <> 0
 	        AND  Prod_Id = @Prod_Id 
 	        AND  ( 	  (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	       OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
 	  	     )
 	 END
    --ENDIF @MasterUnit
  END
Else 	  	  	  	  	 --We have product grouping info
  BEGIN
    CREATE TABLE #Products (Prod_Id Int)
    If @QueryType = 2  	  	  	 --Single Group
        Begin
           INSERT INTO #Products
           SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
        End
    Else If @QueryType = 3 	  	 --Single Characteristic
        Begin
           INSERT INTO #Products
           SELECT DISTINCT Prod_Id  FROM Pu_Characteristics  WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
        End
    Else 	  	  	  	 --Group & Property
        Begin
           INSERT INTO #Products
           SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
 	   INSERT INTO #Products
          SELECT DISTINCT Prod_Id  FROM Pu_Characteristics  WHERE Prop_Id = @Prop_Id  AND Char_Id = @Char_Id
        End
    --EndIf @QueryType =2 ...
    IF @MasterUnit IS NULL
 	 BEGIN
 	     INSERT INTO #Prod_Starts
 	     SELECT  ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
 	       FROM  Production_Starts ps
 	       JOIN  #Products p ON ps.Prod_Id = p.Prod_Id 
 	      WHERE (Start_Time BETWEEN @Start_Time AND @End_Time)
 	  	 OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	 OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
 	 END
    ELSE     --@MasterUnit not null
 	 BEGIN
 	     INSERT INTO #Prod_Starts
 	     SELECT  ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
 	       FROM  Production_Starts ps
 	       JOIN  #Products p ON ps.Prod_Id = p.Prod_Id 
 	      WHERE  PU_Id = @MasterUnit 
 	        AND  PU_Id <> 0
 	        AND  ( 	 (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	      OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
 	  	     )
 	 END
    --ENDIF @MasterUnit
    DROP TABLE #Products
  END
--   Insert Product-related Alarm Data Into Temp Table #TopNDR 
-- 
    BEGIN
 	 If @Acknowledged = 1 	 --Get only acknowledged Alarms
 	     INSERT INTO  #TopNDR (Start_Time, End_Time, Duration, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id)
 	          SELECT  A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4
 	            FROM  Alarms A
 	            JOIN  #Prod_Starts PS ON PS.Start_Time <= A.Start_Time AND (PS.End_Time > A.Start_Time OR PS.End_Time Is NULL)
 	            JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id 
 	           WHERE  A.Alarm_Type_Id = 1   --Variable-type alarm
 	  	     AND  A.Ack = 1
 	             AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	            OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	            OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	            OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	          )
 	 Else  	  	  	 --Any alarm data; @Acknowledement not required
 	     INSERT INTO  #TopNDR (Start_Time, End_Time, Duration, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id)
 	          SELECT  A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4
 	            FROM  Alarms A
 	            JOIN  #Prod_Starts PS ON PS.Start_Time <= A.Start_Time AND (PS.End_Time > A.Start_Time OR PS.End_Time Is NULL)
 	            JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id 
 	           WHERE  A.Alarm_Type_Id = 1   --Variable-type alarms
 	             AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	            OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	            OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	            OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	          )
 	 --EndIf @Acknowledged = 1
    END
DROP TABLE #Prod_Starts
GOTO FINISH_UP_TEMP_TOPNDR_TABLE
--
--
--
--If Product Is Not Specified, We Use faster query: no join to production_starts
--
--
--
PRODUCT_NOT_SPECIFIED:
If @Acknowledged = 1 	 --Get only acknowledged Alarms data
    INSERT INTO  #TopNDR (Start_Time, End_Time, Duration, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id)
         SELECT  A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4
 	    FROM  Alarms A
 	    JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id 
 	   WHERE  A.Alarm_Type_Id = 1   --Variable
 	     AND  A.Ack = 1
 	     AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	    OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	    OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	    OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	  )
Else 	  	  	 --Any alarm data; @Acknowledement not required
    INSERT INTO  #TopNDR (Start_Time, End_Time, Duration, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id)
         SELECT  A.Start_Time, A.End_Time, A.Duration, A.Source_PU_Id, A.Cause1, A.Cause2, A.Cause3, A.Cause4
           FROM  Alarms A
 	    JOIN  Alarm_Template_Var_Data T ON T.ATD_Id = A.ATD_Id AND T.Var_Id = @Var_Id 
 	   WHERE  A.Alarm_Type_Id = 1   --Variable
 	     AND  (    (A.Start_Time >= @Start_Time AND A.Start_Time < @End_Time) 	  	  	    --Alarm starts Within timeRange
 	  	    OR (A.End_Time > @Start_Time AND A.End_Time <= @End_Time)  	  	  	    --Alarm ends within timeRange
 	  	    OR (A.Start_Time < @Start_Time AND A.End_Time > @End_Time AND A.End_Time Is NOT NULL) --Alarm starts before timeRange and ends after timeRange
 	  	    OR (A.Start_Time < @Start_Time AND A.End_Time Is NULL) 	  	  	  	    --Alarm starts before timeRange and hasn't ended yet
 	  	  )
--EndIf @Acknowledged = 1
--
--
--
FINISH_UP_TEMP_TOPNDR_TABLE:
--
--
--
--Clean up zero PU_Id
DELETE FROM #TopNDR WHERE SourcePU = 0
--We have inserted into #TopNDR alarms that may have started and ended beyond user-requested time range.
--To only report Alarms for the specified time range; need to change start_time and End_Time
UPDATE #TopNDR 	 SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
UPDATE #TopNDR  SET End_Time = @End_Time  WHERE End_Time > @End_Time OR End_Time IS NULL
UPDATE #TopNDR  SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
-- Calculate Total Alarm Duration
SELECT @TotalDurations = (SELECT SUM(Duration) FROM #TopNDR) 
--Adjust For Scheduled Alarm 
SELECT @TotalOperating = 0
SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
--Deleted rows with Null Reason IDs or unmatched reason IDs, keeping only the "Selected Reason" 
If @SelectR1 Is NOT NULL DELETE FROM #TopNDR Where R1_Id Is NULL Or R1_Id <> @SelectR1  
If @SelectR2 Is NOT NULL DELETE FROM #TopNDR Where R2_Id Is NULL Or R2_Id <> @SelectR2
If @SelectR3 Is NOT NULL DELETE FROM #TopNDR Where R3_Id Is NULL Or R3_Id <> @SelectR3
If @SelectR4 Is NOT NULL DELETE FROM #TopNDR Where R4_Id Is NULL Or R4_Id <> @SelectR4
--Fill in TopNDR with Reason Names
          UPDATE #TopNDR 
             SET Reason_Name = Case @ReasonLevel
    	  	  	  	 When 0 Then PU.PU_Desc
 	  	  	  	 When 1 Then R1.Event_Reason_Name
 	  	  	  	 When 2 Then R2.Event_Reason_Name
 	  	  	  	 When 3 Then R3.Event_Reason_Name
 	  	  	  	 When 4 Then R4.Event_Reason_Name
 	  	       	        End
           FROM #TopNDR t
 	    JOIN Prod_Units PU ON PU.Pu_Id = t.SourcePU
LEFT OUTER JOIN Event_Reasons R1 on (t.R1_Id = R1.Event_Reason_Id)
LEFT OUTER JOIN Event_Reasons R2 on (t.R2_Id = R2.Event_Reason_Id)
LEFT OUTER JOIN Event_Reasons R3 on (t.R3_Id = R3.Event_Reason_Id)
LEFT OUTER JOIN Event_Reasons R4 on (t.R4_Id = R4.Event_Reason_Id)
--If there still are 'Null' reason names, replace it with "Unspecified"
UPDATE #TopNDR 	 SET Reason_Name = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified') Where Reason_Name Is NULL
-- Populate Temp Table With Reason Ordered By
INSERT INTO #MyReport (ReasonName, NumberOfOccurences, TotalReasonMinutes, AvgReasonMinutes, TotalAlarmMinutes, TotalOperatingMinutes)
     SELECT  Reason_Name, COUNT(Duration), Total_Duration = SUM(Duration),  (SUM(Duration) / COUNT(Duration)), @TotalDurations, @TotalOperating
       FROM  #TopNDR
   GROUP BY  Reason_Name
   ORDER BY  Total_Duration DESC
SET NOCOUNT OFF
SELECT * FROM #MyReport
DROP TABLE #TopNDR
DROP TABLE #MyReport
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
