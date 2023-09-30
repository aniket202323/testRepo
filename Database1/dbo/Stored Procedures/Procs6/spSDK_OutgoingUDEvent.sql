CREATE PROCEDURE dbo.spSDK_OutgoingUDEvent
 	 @PUId 	  	  	  	  	  	 INT,
 	 @C1Id  	  	  	  	  	 INT,
 	 @C2Id 	  	  	  	  	  	 INT,
 	 @C3Id  	  	  	  	  	 INT,
 	 @C4Id  	  	  	  	  	 INT,
 	 @A1Id 	  	  	  	  	  	 INT,
 	 @A2Id 	  	  	  	  	  	 INT,
 	 @A3Id 	  	  	  	  	  	 INT,
 	 @A4Id 	  	  	  	  	  	 INT,
 	 @ResearchStatusId 	  	 INT,
 	 @ResearchUserId 	  	 INT,
 	 @DeptName 	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @LineName 	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @UnitName  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause1 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause2 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause3 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause4 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action1 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action2 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action3 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action4 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @ResearchStatus 	  	 nvarchar(50) 	 OUTPUT,
 	 @ResearchUserName 	  	 nvarchar(50) 	 OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Unit Not Found
-- 2 - Reason Not Found
--Lookup Dept, Line, Unit
SELECT 	 @DeptName = NULL,
 	  	  	 @LineName = NULL,
 	  	  	 @UnitName = NULL
SELECT 	 @DeptName = d.Dept_Desc,
 	  	  	 @LineName = pl.PL_Desc,
 	  	  	 @UnitName = pu.PU_Desc
 	 FROM 	 Prod_Units pu
 	 JOIN 	 Prod_Lines pl 	 ON pl.PL_Id = pu.PL_Id
 	 JOIN 	 Departments d 	 ON 	 d.Dept_Id = pl.Dept_Id
 	 WHERE 	 PU_id = @PUId
IF @UnitName IS NULL RETURN(1)
SELECT 	 @Cause1 = NULL
SELECT 	 @Cause1 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @C1Id
SELECT 	 @Cause2 = NULL
SELECT 	 @Cause2 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @C2Id
SELECT 	 @Cause3 = NULL
SELECT 	 @Cause3 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @C3Id
SELECT 	 @Cause4 = NULL
SELECT 	 @Cause4 = Event_Reason_Name
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Id = @C4Id
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
RETURN(0)
