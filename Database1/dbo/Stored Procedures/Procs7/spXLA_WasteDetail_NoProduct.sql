-- ECR #29673: mt/5-3-2005 -- added Amount as an additional sort criteria in return result set 
CREATE PROCEDURE dbo.spXLA_WasteDetail_NoProduct
 	   @Start_Time  	 DateTime
 	 , @End_Time  	 DateTime
 	 , @PU_Id  	 Int
 	 , @SelectSource 	 Int
 	 , @SelectR1  	 Int
 	 , @SelectR2  	 Int
 	 , @SelectR3  	 Int
 	 , @SelectR4  	 Int
 	 , @TimeSort  	 TinyInt = NULL
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @MasterUnit Int
DECLARE @Unspecified varchar(50)
SELECT @MasterUnit = @PU_Id
-- Get All WED Records In Field I Care About
CREATE TABLE #TopNDR (
      Detail_Id  	 Int
    , TimeStamp 	  	 DateTime
    , Amount  	  	 real NULL
    , Reason_Name  	 Varchar(100) NULL
    , SourcePU  	  	 Int NULL
    , R1_Id  	  	 Int NULL
    , R2_Id  	  	 Int NULL
    , R3_Id  	  	 Int NULL
    , R4_Id  	  	 Int NULL
    , Type_Id  	  	 Int NULL
    , Meas_Id  	  	 Int NULL
    , First_Comment_Id  	 Int NULL
    , Last_Comment_Id  	 Int NULL
    , EventBased  	 TinyInt NULL
    , EventNumber  	 Varchar(50) NULL     
)
-- Get All The Event Based Waste
INSERT INTO #TopNDR (Detail_Id, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, EventBased, EventNumber)
SELECT D.WED_Id, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num 
  FROM Events EV 
  JOIN Waste_Event_Details D ON D.Event_Id = EV.Event_Id
 WHERE EV.PU_Id = @PU_Id 
   AND EV.TimeStamp > @Start_Time 
   AND EV.TimeStamp <= @End_Time   
-- Get All The Time Based Waste
INSERT INTO #TopNDR (Detail_Id, TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, EventBased)
SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.WET_Id, D.WEMT_Id, 0  
  FROM Waste_Event_Details D 
 WHERE D.PU_Id = @PU_Id 
   AND D.TimeStamp > @Start_Time 
   AND D.TimeStamp <= @End_Time 
   AND D.Event_Id Is NULL  
--DELETE For Additional Selection Criteria
If @SelectSource Is Not NULL 	 DELETE FROM #TopNDR Where SourcePU Is NULL Or SourcePU <> @SelectSource
If @SelectR1 Is Not NULL 	 DELETE FROM #TopNDR Where R1_Id Is NULL Or R1_Id <> @SelectR1  
If @SelectR2 Is Not NULL 	 DELETE FROM #TopNDR Where R2_Id Is NULL Or R2_Id <> @SelectR2
If @SelectR3 Is Not NULL 	 DELETE FROM #TopNDR Where R3_Id Is NULL Or R3_Id <> @SelectR3
If @SelectR4 Is Not NULL 	 DELETE FROM #TopNDR Where R4_Id Is NULL Or R4_Id <> @SelectR4
--Get First And Last Comment
CREATE TABLE #Comments (Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
--Get First And Last Comment
Insert Into #Comments
  SELECT D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
    FROM #TopNDR D, Waste_n_Timed_Comments C
   Where C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 3
Group By D.Detail_Id   
Update #TopNDR 
  Set First_Comment_Id = FirstComment
    , Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
                         FROM #TopNDR D, #Comments C WHERE D.Detail_Id = C.Detail_Id 
DROP TABLE #Comments
--Return Data And Join Results
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @TimeSort = 1 
  SELECT  [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone
 	 , Amount
 	 , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
 	 , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
 	 , Event_Number = Case 
                   When #TopNDR.EventBased = 0 Then dbo.fnDBTranslate(N'0', 31333, 'Not Applicable')
                   When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                   Else #TopNDR.EventNumber 
                 End
 	 , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
 	 , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
 	 , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
 	 , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
 	 , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
 	 , First_Comment_Id
 	 , Last_Comment_Id  
    FROM #TopNDR
    LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.PU_Id)
    LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
    --ORDER BY TimeStamp ASC                                                     --ECR #29673
    ORDER BY TimeStamp ASC, Amount ASC                                           --ECR #29673
Else
  SELECT  [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone
 	 , Amount
 	 , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
 	 , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
 	 , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
 	 , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
 	 , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
 	 , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
 	 , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
 	 , First_Comment_Id
 	 , Last_Comment_Id
    FROM #TopNDR
    LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.PU_Id)
    LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
    --ORDER BY TimeStamp DESC                                                     --ECR #29673
    ORDER BY TimeStamp DESC, Amount DESC                                          --ECR #29673
DROP TABLE #TopNDR
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
