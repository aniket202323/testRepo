CREATE PROCEDURE dbo.spSDK_QueryActiveProductionEvents
 	 @LineMask 	 nvarchar(50) = NULL,
 	 @UnitMask 	 nvarchar(50) = NULL,
 	 @Timestamp 	 DATETIME  	 = NULL,
 	 @UserId 	  	 INT  	  	  	 = NULL 	 
AS
SET NOCOUNT ON
DECLARE @EventsTable 	 Table (Id Int IDENTITY (1,1),PUId Int,dtTime DateTime)
DECLARE @MaxCount 	  	 INT
DECLARE @CurrentPUID 	 INT
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
IF @Timestamp IS NULL
BEGIN
 	 SELECT 	 @Timestamp = dbo.fnServer_CmnGetDate(getUTCdate())
END
INSERT  INTO @EventsTable(PUId)
 	  	 SELECT 	 Distinct pu.PU_Id
 	  	  	  	  	  	 FROM 	  	  	 Prod_Lines pl
 	  	  	  	  	  	 JOIN 	  	  	 Prod_Units pu 	  	 ON  	 pl.PL_Id = pu.PL_Id 	 AND 	 pl.PL_Desc LIKE @LineMask AND 	 pu.PU_Desc LIKE @UnitMask AND 	 pu.PU_Id > 0 
 	  	  	  	  	  	 LEFT JOIN 	 User_Security pls 	 ON 	  	 pl.Group_Id = pls.Group_Id AND 	 pls.User_Id = @UserId
 	  	  	  	  	  	 LEFT JOIN 	 User_Security pus 	 ON  	 pu.Group_Id = pus.Group_Id AND 	 pus.User_Id = @UserId 	  	  	  	 
 	  	  	  	  	  	 WHERE COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
SELECT @MaxCount = @@RowCount
WHILE @MaxCount > 0
BEGIN
 	 SELECT @CurrentPUID = PUId FROM @EventsTable WHERE Id = @MaxCount
 	 UPDATE @EventsTable set dtTime = (SELECT MAX(Timestamp) 
 	  	 FROM EVENTS 
 	  	 WHERE PU_ID = @CurrentPUID)
 	 WHERE Id = @MaxCount
 	 SELECT @MaxCount = @MaxCount -1
END
DELETE FROM @EventsTable WHERE dtTime Is NULL
--Mask For Name Has Been Specified
SELECT 	 ProductionEventId = e.Event_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 EventName = e.Event_Num, 
 	  	  	 EventType = es.Event_Subtype_Desc,
 	  	  	 EventStatus = ps.ProdStatus_Desc, 
 	  	  	 TestingStatus = 'Unknown',
 	  	  	 OriginalProduct = p.Prod_Code, 
 	  	  	 AppliedProduct = ap.Prod_Code, 
 	  	  	 ProcessOrder = pp.Process_Order,
 	  	  	 StartTime = dbo.fnCmn_GetEventStartTime(e.Event_Id) , 
 	  	  	 EndTime = e.TimeStamp, 
 	  	  	 InitialDimensionX = ed.Initial_Dimension_X, 
 	  	  	 InitialDimensionY = ed.Initial_Dimension_Y, 
 	  	  	 InitialDimensionZ = ed.Initial_Dimension_Z,
 	  	  	 InitialDimensionA = ed.Initial_Dimension_A,
 	  	  	 FinalDimensionX = ed.Final_Dimension_X, 
 	  	  	 FinalDimensionY = ed.Final_Dimension_Y, 
 	  	  	 FinalDimensionZ = ed.Final_Dimension_Z,
 	  	  	 FinalDimensionA = ed.Final_Dimension_A,
 	  	  	 CommentId = e.Comment_Id,
 	  	  	 ExtendedInfo = e.Extended_Info,
 	  	  	 SignatureId = e.Signature_Id
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	  	  	 ON  	 d.Dept_Id = pl.Dept_Id
 	 JOIN 	  	  	 Prod_Units pu 	  	  	  	  	 ON  	 pl.PL_Id = pu.PL_Id
 	 JOIN 	  	  	 Events e  	  	  	  	  	  	 ON  	 pu.PU_Id = e.PU_Id
 	 JOIN 	  	  	 Event_Configuration ec 	  	  	 ON  	 e.PU_Id = ec.PU_Id 	 AND 	 ec.ET_Id = 1
 	 JOIN 	  	  	 Event_SubTypes es 	  	  	  	 ON  	 ec.Event_SubType_Id = es.Event_SubType_Id
 	 JOIN 	  	  	 Production_Status ps 	  	  	 ON  	 ps.ProdStatus_Id = e.Event_Status
 	 JOIN  	  	  	 Production_Starts s 	  	  	  	 ON  	 s.PU_Id = e.PU_Id AND 	 s.Start_Time <= e.TimeStamp AND 	 (s.End_Time > e.TimeStamp OR s.End_Time IS NULL)
 	 JOIN 	  	  	 Products p 	   	  	  	  	  	 ON  	 s.Prod_Id = p.Prod_Id
 	 LEFT JOIN 	 Products ap  	  	  	  	  	  	 ON  	 e.Applied_Product = ap.Prod_Id
 	 LEFT JOIN 	 Production_Plan_Starts pps 	  	  	 ON  	 pps.PU_Id = e.pu_id 	 AND 	 pps.Start_Time <= e.TimeStamp AND  	 (pps.End_Time > e.TimeStamp OR pps.End_Time IS NULL)
 	 LEFT JOIN  	 Production_Plan pp 	  	  	  	  	 ON  	 pps.PP_Id = pp.PP_Id
 	 LEFT JOIN 	 Event_Details ed 	  	  	  	  	 ON  	 ed.Event_Id = e.Event_Id
 	 JOIN @EventsTable me  	  	  	  	  	  	  	 ON  me.PUId = pu.PU_Id AND me.dtTime = e.Timestamp
RETURN(0)
