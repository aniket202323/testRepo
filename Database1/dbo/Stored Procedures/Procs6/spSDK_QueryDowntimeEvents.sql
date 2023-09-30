CREATE PROCEDURE dbo.spSDK_QueryDowntimeEvents
 	 @LineMask  	  	  	 nvarchar(50) = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) = NULL,
 	 @StartTime 	  	  	 DATETIME = NULL,
 	 @EndTime 	  	  	  	 DATETIME = NULL,
 	 @UserId 	  	  	  	 INT = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
IF @EndTime IS NULL
BEGIN
 	 IF @StartTime IS NULL
 	 BEGIN
 	  	 SELECT @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
 	 END ELSE
 	 BEGIN
 	  	 SELECT @EndTime = DATEADD(DAY, 1, @StartTime)
 	 END
END
IF @StartTime IS NULL
BEGIN
 	 SELECT @StartTime = DATEADD(DAY, -1, @EndTime)
END
SELECT 	 DowntimeEventId = TEDet_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 StartTime = ted.Start_Time, 
 	  	  	 EndTime = ted.End_Time,
 	  	  	 Duration = DATEDIFF(SECOND, ted.Start_Time, ted.End_Time) / 60.0,
 	  	  	 Fault = TEFault_Name,
 	  	  	 Cause1 = rl1.Event_Reason_Name, Cause2 = rl2.Event_Reason_Name,
 	  	  	 Cause3 = rl3.Event_Reason_Name, Cause4 = rl4.Event_Reason_Name,
 	  	  	 CauseCommentId = ted.Cause_Comment_Id,
 	  	  	 Action1 = al1.Event_Reason_Name, Action2 = al2.Event_Reason_Name,
 	  	  	 Action3 = al3.Event_Reason_Name, Action4 = al4.Event_Reason_Name,
 	  	  	 ActionCommentId = ted.Action_Comment_Id,
 	  	  	 ResearchOpenDate = ted.Research_Open_Date, 
 	  	  	 ResearchCloseDate = ted.Research_Close_Date,
 	  	  	 ResearchStatus = rs.Research_Status_Desc, 
 	  	  	 ResearchUser = ru.UserName,
 	  	  	 ResearchCommentId = ted.Research_Comment_Id,
 	  	  	 SourceDepartmentName = sd.Dept_Desc,
 	  	  	 SourceLineName = spl.PL_Desc, 
 	  	  	 SourceUnitName = spu.PU_Desc, 
 	  	  	 UserName = u.UserName,
 	  	  	 DowntimeStatusName = tes.TEStatus_Name,
                        SignatureId = ted.Signature_Id
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl  	  	  	  	 ON  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units pu  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	 LEFT JOIN 	  	  	 Timed_Event_Details ted ON 	  	 ted.PU_Id = pu.PU_Id
 	 LEFT JOIN 	  	  	 Prod_Units spu  	  	  	 ON 	  	 ted.Source_PU_Id = spu.PU_Id
 	 LEFT JOIN 	  	  	 Prod_Lines spl  	  	  	 ON 	  	 spu.PL_Id = spl.PL_Id
 	 LEFT JOIN 	  	  	 Departments sd 	  	  	  	 ON 	  	 spl.Dept_Id = sd.Dept_Id
 	 JOIN 	  	  	 Users u  	  	  	  	  	  	 ON 	  	 ted.User_Id = u.User_id
 	 LEFT JOIN 	 Timed_Event_Fault tef 	 ON 	  	 ted.TEFault_Id = tef.TEFault_Id
 	 LEFT JOIN 	 Event_Reasons rl1  	  	 ON 	  	 ted.Reason_Level1 = rl1.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons rl2  	  	 ON 	  	 ted.Reason_Level2 = rl2.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons rl3 	  	  	 ON 	  	 ted.Reason_Level3 = rl3.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons rl4 	  	  	 ON 	  	 ted.Reason_Level4 = rl4.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons al1 	  	  	 ON 	  	 ted.Action_Level1 = al1.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons al2 	  	  	 ON 	  	 ted.Action_Level2 = al2.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons al3 	  	  	 ON 	  	 ted.Action_Level3 = al3.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons al4 	  	  	 ON 	  	 ted.Action_Level4 = al4.Event_Reason_Id
 	 LEFT JOIN 	 Research_Status rs 	  	 ON 	  	 ted.Research_Status_Id = rs.Research_Status_Id
 	 LEFT JOIN 	 Users ru 	  	  	  	  	  	 ON 	  	 ted.Research_User_Id = ru.User_Id
 	 LEFT JOIN 	 Timed_Event_Status tes 	 ON 	  	 ted.PU_Id = tes.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ted.TEStatus_Id = tes.TEStatus_Id
 	 LEFT JOIN 	 User_Security pls 	  	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 WHERE Start_Time < @EndTime
 	 AND 	 (End_Time > @StartTime OR End_Time IS NULL)
 	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 ORDER BY Start_Time ASC
