-- ECR #27198(mt/12-22-2003): Perfomance tuning; drop hinting from Waste_Event_Details in the join clause; add hinting to Events in the from clause
--
CREATE PROCEDURE dbo.spXLA_WasteSummary_NoProduct
 	   @Start_Time  	 DateTime
 	 , @End_Time  	 DateTime
 	 , @PU_Id  	 Int
 	 , @SelectSource 	 Int
 	 , @SelectR1  	 Int
 	 , @SelectR2  	 Int
 	 , @SelectR3  	 Int
 	 , @SelectR4  	 Int
 	 , @ReasonLevel  	 Int
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
DECLARE @TotalWaste  	 Real
DECLARE @TotalOperating Real
DECLARE @MasterUnit  	 Int
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @MasterUnit = @PU_Id 
CREATE TABLE #MyReport (
      ReasonName  	  	 Varchar(100)
    , NumberOfOccurances  	 Int NULL
    , TotalReasonUnits  	  	 Real NULL
    , AvgReasonUnits  	  	 Real NULL
    , TotalWasteUnits  	  	 Real NULL
    , TotalOperatingUnits  	 Real NULL
    )
-- Get All WED Records In Field I Care About
CREATE TABLE #TopNDR (
      TimeStamp  	 DateTime
    , Amount 	  	 Real NULL
    , Reason_Name  	 Varchar(100) NULL
    , SourcePU  	  	 Int NULL
    , R1_Id  	  	 Int NULL
    , R2_Id  	  	 Int NULL
    , R3_Id  	  	 Int NULL
    , R4_Id  	  	 Int NULL
    , Type_Id  	  	 Int NULL
    , Meas_Id  	  	 Int NULL
    )
-- Get All The Event Based Waste
INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
SELECT EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, WET_Id, WEMT_Id
  FROM Events EV 
  --{ ECR #27198(mt/12-22-2003)
  JOIN Waste_Event_Details D on D.Event_Id = EV.Event_Id
  --}
 WHERE EV.PU_Id = @PU_Id 
   AND EV.TimeStamp > @Start_Time 
   AND EV.TimeStamp <= @End_Time   
-- Get All The Time Based Waste
INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,WET_Id,WEMT_Id  
  FROM Waste_Event_Details D WITH (INDEX(WEvent_Details_IDX_PUIdTime)) 
 WHERE D.PU_Id = @PU_Id 
   AND D.TimeStamp > @Start_Time 
   AND D.TimeStamp <= @End_Time   
   AND D.Event_Id Is NULL 	 --mt/2-28-2002 bug fix.
-- Calculate Total Downtime
SELECT @TotalWaste = (SELECT Sum(Amount) FROM #TopNDR) 
--Go And Get Total Production For Time Period
SELECT @TotalOperating = 0
SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0 ) - @TotalOperating
--DELETE For Additional SELECTion Criteria
If @SelectSource Is NOT NULL 	 DELETE FROM #TopNDR Where SourcePU Is NULL OR SourcePU <> @SelectSource
If @SelectR1 Is NOT NULL 	 DELETE FROM #TopNDR Where R1_Id Is NULL OR R1_Id <> @SelectR1  
If @SelectR2 Is NOT NULL 	 DELETE FROM #TopNDR Where R2_Id Is NULL OR R2_Id <> @SelectR2
If @SelectR3 Is NOT NULL 	 DELETE FROM #TopNDR Where R3_Id Is NULL OR R3_Id <> @SelectR3
If @SelectR4 Is NOT NULL 	 DELETE FROM #TopNDR Where R4_Id Is NULL OR R4_Id <> @SelectR4
UPDATE #TopNDR 
  SET Reason_Name = 
      Case @ReasonLevel
         When 0 Then PU.PU_Desc
         When 1 Then R1.Event_Reason_Name
         When 2 Then R2.Event_Reason_Name
         When 3 Then R3.Event_Reason_Name
         When 4 Then R4.Event_Reason_Name
         When 5 Then T.WET_Name
         When 6 Then M.WEMT_Name
      End
  FROM #TopNDR 
  LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.PU_Id)
  LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
  LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
  LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
  LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
  LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
  LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
UPDATE #TopNDR SET Reason_Name = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified') Where Reason_Name Is NULL
-- Populate Temp Table With Reason ORdered By Top 20
INSERT INTO #MyReport (ReasonName,
                       NumberOfOccurances,
                       TotalReasonUnits,
                       AvgReasonUnits,
                       TotalWasteUnits,
                       TotalOperatingUnits)
  SELECT Reason_Name, COUNT(Amount), Total_Amount = SUM(Amount),  (SUM(Amount) / COUNT(Amount)), @TotalWaste, @TotalOperating
    FROM #TopNDR
GROUP BY Reason_Name
ORDER BY Total_Amount DESC
--SET NOCOUNT OFF  disabled 10-27-2004:mt ECR #28901 to comply with MSI Multilinugal design
SELECT * FROM #MyReport
DROP TABLE #TopNDR
DROP TABLE #MyReport
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
