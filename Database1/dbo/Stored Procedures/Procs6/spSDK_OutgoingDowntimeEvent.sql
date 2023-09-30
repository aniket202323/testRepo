CREATE PROCEDURE dbo.spSDK_OutgoingDowntimeEvent
 	 @TransType 	  	  	  	 INT,
 	 @TId 	  	  	  	  	  	 INT,
 	 @PUId 	  	  	  	  	  	 INT,
 	 @SrcPUId 	  	  	  	  	 INT,
 	 @StartTime 	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	  	 DATETIME,
 	 @Duration 	  	  	  	 FLOAT,
 	 @FaultId 	  	  	  	  	 INT, 	 
 	 @R1Id  	  	  	  	  	 INT,
 	 @R2Id 	  	  	  	  	  	 INT,
 	 @R3Id  	  	  	  	  	 INT,
 	 @R4Id  	  	  	  	  	 INT,
 	 @CauseCommentId 	  	 INT,
 	 @A1Id 	  	  	  	  	  	 INT,
 	 @A2Id 	  	  	  	  	  	 INT,
 	 @A3Id 	  	  	  	  	  	 INT,
 	 @A4Id 	  	  	  	  	  	 INT,
 	 @ActionCommentId 	  	 INT,
 	 @StatusId 	  	  	  	 INT,
 	 @ResearchStatusId 	  	 INT,
 	 @ResearchUserId 	  	 INT,
 	 @ResearchCommentId 	 INT,
 	 @UserId 	  	  	  	  	 INT,
 	 @DowntimeStatusId 	  	 INT,
 	 @LineName 	  	  	  	 nvarchar(50)  OUTPUT,
 	 @UnitName  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @SourceLineName 	  	 nvarchar(50)  OUTPUT,
 	 @SourceUnitName 	  	 nvarchar(50)  OUTPUT,
 	 @FaultName 	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Cause1 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Cause2 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Cause3 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Cause4 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Action1 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Action2 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Action3 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @Action4 	  	  	  	  	 nvarchar(50)  OUTPUT,
 	 @ResearchStatus 	  	 nvarchar(50)  OUTPUT,
 	 @ResearchUserName 	  	 nvarchar(50)  OUTPUT,
 	 @Username 	  	  	  	 nvarchar(50)  OUTPUT,
 	 @DowntimeStatusName 	 nvarchar(50) 	  OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Unit Not Found
-- 2 - Line Not Found
-- 3 - Source Unit Not Found
-- 4 - Source Line Not Found
DECLARE 	 @PLId 	  	  	 INT
--Lookup Unit, Line
SELECT 	 @UnitName = NULL
SELECT 	 @UnitName = PU_Desc, 
 	  	  	 @PLId = PL_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PU_id = @PUId
IF @UnitName IS NULL RETURN(1)
SELECT 	 @LineName = NULL
SELECT 	 @LineName = PL_Desc 
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Id = @PLId
IF @LineName IS NULL RETURN(2)
--Lookup Source Unit, Line
SELECT 	 @SourceUnitName = NULL
SELECT 	 @SourceUnitName = PU_Desc
 	 FROM 	 Prod_Units 
 	 WHERE 	 PU_id = @SrcPUId
IF @SourceUnitName IS NULL RETURN(3)
SELECT 	 @SourceLineName = NULL
SELECT 	 @SourceLineName = PL_Desc 
 	 FROM 	 Prod_Lines pl JOIN
 	  	  	 Prod_Units pu ON (pl.PL_Id = pu.PL_Id)
 	 WHERE 	 pu.PU_Id = @SrcPUId
IF @SourceLineName IS NULL RETURN(4)
--Look Up Other Stuff
SELECT 	 @FaultName = NULL
SELECT 	 @FaultName = TEFault_Name
 	 FROM 	 Timed_Event_Fault
 	 WHERE 	 TEFault_Id = @FaultId
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
SET 	  	 @DowntimeStatusName = NULL
SELECT 	 @DowntimeStatusName = TEStatus_Name
 	 FROM 	 Timed_Event_Status
 	 WHERE 	 TEStatus_Id = @DowntimeStatusId
RETURN(0)
