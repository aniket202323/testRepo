CREATE PROCEDURE dbo.spXLA_DowntimeDetail_NoProduct
 	   @Start_Time 	 datetime
 	 , @End_Time 	 datetime
 	 , @PU_Id 	 int 	  	  	 --Add-In;sLine (which is MasterUnit)
 	 , @SelectSource 	 int 	  	  	 -- 	  	  	  slave units
 	 , @SelectR1 	 int
 	 , @SelectR2 	 int
 	 , @SelectR3 	 int
 	 , @SelectR4 	 int
 	 , @TimeSort 	 tinyint = NULL
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
DECLARE @MasterUnit  	 int
DECLARE @Line 	  	 Varchar(50)
DECLARE @Unspecified varchar(50)
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @PU_Id
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
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
 	 , First_Comment_Id 	 int NULL
 	 , Last_Comment_Id  	 int NULL
)
-- Get All The Detail Records We Care About
-- Insert Data Into #TopNDR Temp Table
If @MasterUnit Is NULL
   BEGIN
 	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	 SELECT  D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, TEFault_Id, TEStatus_Id
          FROM  Timed_Event_Details D
 	   JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
         WHERE (D.Start_Time >= @Start_Time AND D.Start_Time < @End_Time) 
 	     OR (D.End_Time > @Start_Time AND D.End_Time <= @End_Time) 
 	     OR (D.Start_Time < @Start_Time AND D.End_Time > @End_Time AND D.End_Time Is Not Null) 
 	     OR (D.Start_Time < @Start_Time AND D.End_Time Is Null) 	        
    END
Else    --@MasterUnit not null
   BEGIN
 	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id)
 	 SELECT  D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, TEFault_Id, TEStatus_Id
          FROM  Timed_Event_Details D
 	   JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.PU_Id = @MasterUnit 
           AND (    (D.Start_Time >= @Start_Time AND D.Start_Time < @End_Time) 
 	          OR (D.End_Time > @Start_Time AND D.End_Time <= @End_Time)
 	          OR (D.Start_Time < @Start_Time AND D.End_Time > @End_Time AND D.End_Time Is Not Null) 
 	          OR (D.Start_Time < @Start_Time AND D.End_Time Is Null)
 	        )
    END
--EndIf @PU_Id
-- Clean up unwanted PU_Id = 0 (marked for unused/obsolete)
DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
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
--EndIf
If @SelectR1 Is Not Null 	 DELETE FROM #TopNDR WHERE R1_Id Is Null Or R1_Id <> @SelectR1  
If @SelectR2 Is Not Null 	 DELETE FROM #TopNDR WHERE R2_Id Is Null Or R2_Id <> @SelectR2
If @SelectR3 Is Not Null 	 DELETE FROM #TopNDR WHERE R3_Id Is Null Or R3_Id <> @SelectR3
If @SelectR4 Is Not Null 	 DELETE FROM #TopNDR WHERE R4_Id Is Null Or R4_Id <> @SelectR4
-- Take Care Of Record Start And End Times 
UPDATE #TopNDR SET start_time = @Start_Time WHERE start_time < @Start_Time
UPDATE #TopNDR SET end_time = @End_Time WHERE end_time > @End_Time OR end_time is null
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
-- --------------------------------------------------
-- RETURN DATA
-- --------------------------------------------------
If @MasterUnit Is NOT NULL SELECT @Line = PU_Desc FROM Prod_Units WHERE PU_Id = @MasterUnit
 	 --(If "Line" (master unit) is specified, we'll need its description)
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @TimeSort = 1
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
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
 	   LEFT OUTER JOIN  Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
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
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
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
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
 	   LEFT OUTER JOIN  Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
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
 	  	   , D.First_Comment_Id
 	  	   , D.Last_Comment_Id
 	       FROM  #TopNDR D
 	   LEFT OUTER JOIN  Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
 	   LEFT OUTER JOIN  Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
 	   LEFT OUTER JOIN  Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
 	   LEFT OUTER JOIN  Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
 	   LEFT OUTER JOIN  Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
 	   ORDER BY  D.Start_Time DESC
 	 END
    --EndIf @MasterUnit
 --EndIf ToOrder...
DROP TABLE #TopNDR
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
