CREATE PROCEDURE dbo.spSDK_OutgoingWasteEvent
 	 @TransType 	  	  	  	 INT,
 	 @WId 	  	  	  	  	  	 INT,
 	 @PUId 	  	  	  	  	 INT,
 	 @EventId 	  	  	  	  	 INT,
 	 @Timestamp 	  	  	  	 DATETIME,
 	 @MeasureId 	  	  	  	 INT,
 	 @TypeId 	  	  	  	  	 INT,
 	 @SrcPUId 	  	  	  	  	 INT,
 	 @UserId 	  	  	  	  	 INT,
 	 @R1Id  	  	  	  	  	 INT,
 	 @R2Id 	  	  	  	  	 INT,
 	 @R3Id  	  	  	  	  	 INT,
 	 @R4Id  	  	  	  	  	 INT,
 	 @CauseCommentId 	  	  	 INT,
 	 @A1Id 	  	  	  	  	 INT,
 	 @A2Id 	  	  	  	  	 INT,
 	 @A3Id 	  	  	  	  	 INT,
 	 @A4Id 	  	  	  	  	 INT,
 	 @ActionCommentId 	  	  	 INT,
 	 @ResearchStatusId 	  	  	 INT,
 	 @ResearchUserId 	  	  	 INT,
 	 @LineName 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @UnitName  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @EventName 	  	  	  	 nvarchar(25) 	  	  	 OUTPUT,
 	 @Measurement 	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @WasteType 	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @SourceLineName 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @SourceUnitName 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Username 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Cause1 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Cause2 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Cause3 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Cause4 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Action1 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Action2 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Action3 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Action4 	  	  	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @ResearchStatus 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @ResearchUserName 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 -- 4.0 Additions
 	 @DepartmentName 	  	 nvarchar(50) = NULL 	 OUTPUT,
 	 @SourceDepartmentName 	 nvarchar(50) = NULL 	 OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Event Not Found
-- 3 - Unit Not Found
-- 4 - Line Not Found
-- 5 - Source Unit Not Found
-- 6 - Source Line Not Found
-- 7 - Event Status Not Found
DECLARE 	 @PLId 	  	  	 INT,
 	  	  	 @DeptId 	  	 INT,
 	  	  	 @CommentId 	 INT
--Lookup Event
SELECT 	 @EventName = NULL
SELECT 	 @EventName = Event_Num
 	 FROM 	 Events 
 	 WHERE Event_Id = @EventId
IF 	 @EventName IS NULL AND @EventId IS NOT NULL RETURN(2)
--Lookup Unit, Line
SELECT 	 @DepartmentName = NULL,
 	  	  	 @LineName = NULL,
 	  	  	 @UnitName = NULL 	  	  	 
SELECT 	 @DepartmentName = d.Dept_Desc,
 	  	  	 @LineName = pl.PL_Desc,
 	  	  	 @UnitName = pu.PU_Desc
 	 FROM 	 Prod_Units pu
 	 JOIN 	 Prod_Lines pl 	 ON 	  	 pu.PL_Id = pl.PL_Id
 	 JOIN 	 Departments d 	 ON 	  	 pl.Dept_Id = d.Dept_Id
 	 WHERE 	 PU_id = @PUId
IF @UnitName IS NULL RETURN(3)
IF @LineName IS NULL RETURN(4)
--Lookup Source Unit, Line
SELECT 	 @SourceDepartmentName = NULL,
 	  	  	 @SourceLineName = NULL,
 	  	  	 @SourceUnitName = NULL 	  	  	 
SELECT 	 @SourceDepartmentName = d.Dept_Desc,
 	  	  	 @SourceLineName = pl.PL_Desc,
 	  	  	 @SourceUnitName = pu.PU_Desc
 	 FROM 	 Prod_Units pu
 	 JOIN 	 Prod_Lines pl 	 ON 	  	 pu.PL_Id = pl.PL_Id
 	 JOIN 	 Departments d 	 ON 	  	 pl.Dept_Id = d.Dept_Id
 	 WHERE 	 PU_id = @SrcPUId
IF @SourceUnitName IS NULL RETURN(5)
IF @SourceLineName IS NULL RETURN(6)
--Look Up Other Stuff
SELECT 	 @Measurement = NULL
SELECT 	 @Measurement = WEMT_Name
 	 FROM 	 Waste_Event_Meas
 	 WHERE 	 WEMT_Id = @MeasureId
SELECT 	 @WasteType = NULL
SELECT 	 @WasteType = WET_Name
 	 FROM 	 Waste_Event_Type
 	 WHERE WET_Id = @TypeId
SELECT 	 @Username = NULL
SELECT 	 @UserName = Username
 	 FROM 	 Users
 	 WHERE 	 User_Id = @UserId
SELECT 	 @Cause1 = NULL
SELECT 	 @Cause1 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @R1Id
SELECT 	 @Cause2 = NULL
SELECT 	 @Cause2 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @R2Id
SELECT 	 @Cause3 = NULL
SELECT 	 @Cause3 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @R3Id
SELECT 	 @Cause4 = NULL
SELECT 	 @Cause4 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @R4Id
SELECT 	 @Action1 = NULL
SELECT 	 @Action1 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @A1Id
SELECT 	 @Action2 = NULL
SELECT 	 @Action2 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @A2Id
SELECT 	 @Action3 = NULL
SELECT 	 @Action3 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @A3Id
SELECT 	 @Action4 = NULL
SELECT 	 @Action4 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @A4Id
SELECT 	 @ResearchStatus = NULL
SELECT 	 @ResearchStatus = Research_Status_Desc
 	 FROM 	 Research_Status
 	 WHERE 	 Research_Status_Id = @ResearchStatusId
SELECT 	 @ResearchUserName = NULL
SELECT 	 @ResearchUserName = Username
 	 FROM 	 Users
 	 WHERE 	 User_Id = @ResearchUserId
RETURN(1)
