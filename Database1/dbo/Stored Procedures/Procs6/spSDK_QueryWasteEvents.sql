CREATE PROCEDURE dbo.spSDK_QueryWasteEvents
 	 @LineMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @WasteType 	  	  	 nvarchar(50) 	 = NULL,
 	 @EventMask 	  	  	 nvarchar(50) 	 = NULL,
 	 @StartTime 	  	  	 DATETIME = NULL,
 	 @EndTime 	  	  	 DATETIME = NULL,
 	 @UserId 	  	  	  	 INT 	 = NULL
AS
SELECT 	 @LineMask = 	  	 REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = 	  	 REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = 	  	 REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = 	  	 REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @WasteType = 	 REPLACE(COALESCE(@WasteType, '*'), '*', '%')
SELECT 	 @WasteType = 	 REPLACE(REPLACE(@WasteType, '?', '_'), '[', '[[]')
SELECT 	 @EventMask = 	 REPLACE(COALESCE(@EventMask, '*'), '*', '%')
SELECT 	 @EventMask = 	 REPLACE(REPLACE(@EventMask, '?', '_'), '[', '[[]')
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
 	 IF @EventMask = '%'
 	 BEGIN
 	  	 SELECT @StartTime = DATEADD(DAY, -1, @EndTime)
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @StartTime = MIN(COALESCE(Start_Time, Timestamp))
 	  	  	 FROM 	 Prod_Lines pl 	 JOIN 
 	  	  	  	  	 Prod_Units pu 	 ON (pu.PU_Id = PL.PL_Id AND
 	  	  	  	  	  	  	  	  	  	  	  pl.PL_Desc LIKE @LineMask AND
 	  	  	  	  	  	  	  	  	  	  	  pu.PU_Desc LIKE @UnitMask) JOIN
 	  	  	  	  	 Events e  	  	 ON (pu.PU_Id = e.PU_Id)
 	  	  	 WHERE 	 Event_Num LIKE 	 @EventMask
 	 END
END
SELECT 	 WasteEventId = WED_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 WasteType = wet.WET_Name, 
 	  	  	 WasteFault = wef.WEFault_Name,
 	  	  	 SourceLineName = spl.PL_Desc, 
 	  	  	 SourceUnitName = spu.PU_Desc, 
 	  	  	 EventName = Event_Num, 
 	  	  	 Timestamp = wed.Timestamp, 
 	  	  	 Measurement = wem.WEMT_Name, 
 	  	  	 Amount = wed.Amount,
  	  	  	 Cause1 = rl1.Event_Reason_Name, Cause2 = rl2.Event_Reason_Name,
 	  	  	 Cause3 = rl3.Event_Reason_Name, Cause4 = rl4.Event_Reason_Name,
 	  	  	 CauseCommentId = wed.Cause_Comment_Id,
 	  	  	 Action1 = al1.Event_Reason_Name, Action2 = al2.Event_Reason_Name,
 	  	  	 Action3 = al3.Event_Reason_Name, Action4 = al4.Event_Reason_Name,
 	  	  	 ActionCommentId = wed.Action_Comment_Id,
 	  	  	 ResearchOpenDate = wed.Research_Open_Date, 
 	  	  	 ResearchCloseDate = wed.Research_Close_Date,
 	  	  	 ResearchStatus = rs.Research_Status_Desc, ResearchUser = ru.UserName,
 	  	  	 ResearchCommentId = wed.Research_Comment_Id,
 	  	  	 UserGeneral1 = wed.User_General_1,
 	  	  	 UserGeneral2 = wed.User_General_2,
 	  	  	 UserGeneral3 = wed.User_General_3,
 	  	  	 UserGeneral4 = wed.User_General_4,
 	  	  	 UserGeneral5 = wed.User_General_5,
            SignatureId = wed.Signature_Id
 	 FROM 	  	 Departments d
 	 JOIN 	  	 Prod_Lines pl  	  	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	 Prod_Units pu 	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	 JOIN 	  	 Waste_Event_Details wed 	  	 ON 	  	 pu.PU_Id = wed.PU_Id
 	 LEFT JOIN 	 Waste_Event_Type wet 	  	 ON 	  	 wed.WET_Id = wet.WET_Id
 	 LEFT JOIN 	 Waste_Event_Meas wem 	  	 ON 	  	 wed.WEMT_Id = wem.WEMT_Id 	 
 	 LEFT JOIN   Waste_Event_Fault wef 	  	 ON 	  	 wef.WEFault_Id = wed.WEFault_Id 	  	  	  	  	  	  	  	 
 	 LEFT JOIN 	 Prod_Units spu 	  	  	  	 ON 	  	 wed.Source_PU_Id = spu.PU_Id 	  	  	  	  	  	  	 
 	 LEFT JOIN 	 Prod_Lines spl 	  	  	  	 ON 	  	 spu.PL_Id = spl.PL_Id 	  	  	  	  	  	  	  	  	 
 	 JOIN 	  	 Users u 	  	  	  	  	  	 ON 	  	 wed.User_Id = u.User_id 	  	  	  	  	  	  	  	  	 
 	 LEFT JOIN 	 Events e 	  	  	  	  	 ON 	  	 wed.Event_Id = e.Event_Id 	  	  	  	  	  	  	  	 
 	 LEFT JOIN 	 Event_Reasons rl1 	  	  	 ON 	  	 wed.Reason_Level1 = rl1.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Event_Reasons rl2 	  	  	 ON 	  	 wed.Reason_Level2 = rl2.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Event_Reasons rl3 	  	  	 ON 	  	 wed.Reason_Level3 = rl3.Event_Reason_Id
 	 LEFT JOIN 	 Event_Reasons rl4 	  	  	 ON 	  	 wed.Reason_Level4 = rl4.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Event_Reasons al1 	  	  	 ON 	  	 wed.Action_Level1 = al1.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Event_Reasons al2 	  	  	 ON 	  	 wed.Action_Level2 = al2.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Event_Reasons al3 	  	  	 ON 	  	 wed.Action_Level3 = al3.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Event_Reasons al4 	  	  	 ON 	  	 wed.Action_Level4 = al4.Event_Reason_Id 	  	  	 
 	 LEFT JOIN 	 Research_Status rs 	  	  	 ON 	  	 wed.Research_Status_Id = rs.Research_Status_Id 	 
 	 LEFT JOIN 	 Users ru 	  	  	  	  	 ON 	  	 wed.Research_User_Id = ru.User_Id  	  	  	  	  	 
 	 LEFT JOIN 	 User_Security pls 	  	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId 	  	  	  	  	  	  	  	  	 
 	 LEFT JOIN 	 User_Security pus 	  	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 WHERE 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 AND 	 wed.Timestamp >= @StartTime
 	 AND 	 wed.Timestamp <= @EndTime
 	 AND 	 COALESCE(wet.WET_Name, '') LIKE @WasteType
 	 AND 	 COALESCE(e.Event_Num, '') LIKE @EventMask
 	 ORDER BY COALESCE(wed.Timestamp, e.Timestamp)
