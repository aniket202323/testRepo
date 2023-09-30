CREATE PROCEDURE dbo.spSDK_OutgoingVariableAlarm
 	 @VarId 	  	  	  	  	 INT,
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
 	 @ATSRDId 	  	  	  	  	 INT,
 	 @ATId 	  	  	  	  	  	 INT,
 	 @AlarmTypeId 	  	  	 INT,
 	 @DeptName 	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @LineName 	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @UnitName  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @VariableName 	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause1 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause2 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause3 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Cause4 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action1 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action2 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action3 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @Action4 	  	  	  	  	 nvarchar(50) 	 OUTPUT,
 	 @ResearchStatus 	  	 nvarchar(50) 	 OUTPUT,
 	 @ResearchUserName 	  	 nvarchar(50) 	 OUTPUT,
 	 @SPCRuleName 	  	  	 nvarchar(50) 	 OUTPUT,
 	 @TemplateName 	  	  	 nvarchar(50) 	 OUTPUT,
 	 @AlarmType 	  	  	  	 nvarchar(50) 	 OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Unit Not Found
-- 2 - Reason Not Found
--Lookup Dept, Line, Unit
SELECT 	 @DeptName 	  	 = NULL,
 	  	  	 @LineName 	  	 = NULL,
 	  	  	 @UnitName 	  	 = NULL,
 	  	  	 @VariableName 	 = NULL
SELECT 	 @DeptName 	  	 = d.Dept_Desc,
 	  	  	 @LineName 	  	 = pl.PL_Desc,
 	  	  	 @UnitName 	  	 = pu.PU_Desc,
 	  	  	 @VariableName 	 = v.Var_Desc
 	 FROM 	 Variables v
 	 JOIN 	 Prod_Units pu 	 ON 	 pu.PU_Id = v.PU_Id
 	 JOIN 	 Prod_Lines pl 	 ON pl.PL_Id = pu.PL_Id
 	 JOIN 	 Departments d 	 ON 	 d.Dept_Id = pl.Dept_Id
 	 WHERE 	 Var_Id = @VarId
IF @VariableName IS NULL RETURN(1)
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
SELECT 	 @AlarmType = NULL
SELECT 	 @AlarmType = Alarm_Type_Desc
 	 FROM 	 Alarm_Types
 	 WHERE 	 Alarm_Type_Id = @AlarmTypeId
SELECT 	 @TemplateName = NULL
SELECT 	 @TemplateName = AT_Desc
 	 FROM 	 Alarm_Templates
 	 WHERE 	 AT_Id = @ATId
SELECT 	 @SPCRuleName = NULL
SELECT 	 @SPCRuleName = asr.Alarm_SPC_Rule_Desc
 	 FROM 	 Alarm_Template_SPC_Rule_Data atsrd
 	 JOIN 	 Alarm_SPC_Rules asr 	  	  	  	  	  	  	 ON 	 asr.Alarm_SPC_Rule_Id = atsrd.Alarm_SPC_Rule_Id
RETURN(0)
