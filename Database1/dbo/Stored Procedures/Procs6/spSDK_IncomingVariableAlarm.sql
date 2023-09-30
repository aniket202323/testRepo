CREATE PROCEDURE dbo.spSDK_IncomingVariableAlarm
 	 -- Input Parameters
 	 @WriteDirect 	  	  	  	 BIT,
 	 @ClientUpdateOnly 	  	  	 BIT,
 	 @TransactionType 	  	  	 INT,
 	 @TransNum 	  	  	  	  	 INT,
 	 @VariableAlarmId 	  	  	 INT,
 	 @AlarmName 	  	  	  	  	 nvarchar(50),
 	 @AlarmType 	  	  	  	  	 INT,
 	 @TemplateName 	  	  	  	 nvarchar(50),
 	 @SPCRuleName 	  	  	  	 nvarchar(50),
 	 @APId 	  	  	  	  	  	  	 INT,
 	 @DepartmentName 	  	  	 nvarchar(50),
 	 @LineName 	  	  	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	  	 nvarchar(50), 
 	 @VariableName 	  	  	  	 nvarchar(50),
 	 @StartTime 	  	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	  	  	 DATETIME,
 	 @StartValue 	  	  	  	  	 nvarchar(50),
 	 @EndValue 	  	  	  	  	 nvarchar(50),
 	 @MinValue 	  	  	  	  	 nvarchar(50),
 	 @MaxValue 	  	  	  	  	 nvarchar(50),
 	 @Cause1 	  	  	  	  	  	 nvarchar(50),
 	 @Cause2 	  	  	  	  	  	 nvarchar(50),
 	 @Cause3 	  	  	  	  	  	 nvarchar(50),
 	 @Cause4 	  	  	  	  	  	 nvarchar(50),
 	 @Action1 	  	  	  	  	  	 nvarchar(50),
 	 @Action2 	  	  	  	  	  	 nvarchar(50),
 	 @Action3 	  	  	  	  	  	 nvarchar(50),
 	 @Action4 	  	  	  	  	  	 nvarchar(50),
 	 @ResearchOpenDate 	  	  	 DATETIME,
 	 @ResearchCloseDate 	  	 DATETIME,
 	 @ResearchStatus 	  	  	 nvarchar(50),
 	 @ResearchUserName 	  	  	 nvarchar(50),
 	 @Ack 	  	  	  	  	  	  	 BIT,
 	 @AckBy 	  	  	  	  	  	 nvarchar(50),
 	 @AckOn 	  	  	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	  	  	 INT
AS
DECLARE 	 @RC 	  	  	  	  	  	  	 INT,
 	  	  	 @ErrMsg 	  	  	  	  	  	 nvarchar(255),
 	  	  	 @PLId 	  	  	  	  	  	  	 INT,
 	  	  	 @PUId 	  	  	  	  	  	  	 INT,
 	  	  	 @AckById 	  	  	  	  	  	 INT,
 	  	  	 @Cause1Id 	  	  	  	  	 INT,
 	  	  	 @Cause2Id 	  	  	  	  	 INT,
 	  	  	 @Cause3Id 	  	  	  	  	 INT,
 	  	  	 @Cause4Id 	  	  	  	  	 INT,
 	  	  	 @Action1Id 	  	  	  	  	 INT,
 	  	  	 @Action2Id 	  	  	  	  	 INT,
 	  	  	 @Action3Id 	  	  	  	  	 INT,
 	  	  	 @Action4Id 	  	  	  	  	 INT,
 	  	  	 @CauseCommentId 	  	  	 INT,
 	  	  	 @ActionCommentId 	  	  	 INT,
 	  	  	 @ResearchCommentId 	  	 INT,
 	  	  	 @ResearchStatusId 	  	  	 INT,
 	  	  	 @ResearchUserId 	  	  	 INT,
 	  	  	 @ATId 	  	  	  	  	  	  	 INT,
 	  	  	 @ATDId 	  	  	  	  	  	 INT,
 	  	  	 @AlarmTypeId 	  	  	  	 INT,
 	  	  	 @VarId 	  	  	  	  	  	 INT,
 	  	  	 @TemplateVarCommentId 	 INT,
 	  	  	 @VarCommentId 	  	  	  	 INT,
 	  	  	 @Cutoff 	  	  	  	  	  	 INT
SELECT 	 @RC = 0,
 	  	  	 @ErrMsg = ''
SELECT 	 @PLId 	  	  	  	  	  	  	 = NULL,
 	  	  	 @PUId 	  	  	  	  	  	  	 = NULL,
 	  	  	 @ATId 	  	  	  	  	  	  	 = NULL,
 	  	  	 @ATDId 	  	  	  	  	  	 = NULL,
 	  	  	 @AlarmTypeId 	  	  	  	 = NULL,
 	  	  	 @VarId 	  	  	  	  	  	 = NULL,
 	  	  	 @Cutoff 	  	  	  	  	  	 = NULL,
 	  	  	 @Cause1Id 	  	  	  	  	 = NULL,
 	  	  	 @Cause2Id 	  	  	  	  	 = NULL,
 	  	  	 @Cause3Id 	  	  	  	  	 = NULL,
 	  	  	 @Cause4Id 	  	  	  	  	 = NULL,
 	  	  	 @Action1Id 	  	  	  	  	 = NULL,
 	  	  	 @Action2Id 	  	  	  	  	 = NULL,
 	  	  	 @Action3Id 	  	  	  	  	 = NULL,
 	  	  	 @Action4Id 	  	  	  	  	 = NULL,
 	  	  	 @ResearchStatusId  	  	 = NULL,
 	  	  	 @ResearchUserId  	  	  	 = NULL,
 	  	  	 @AckById  	  	  	  	  	 = NULL,
 	  	  	 @TemplateVarCommentId  	 = NULL,
 	  	  	 @VarCommentId  	  	  	  	 = NULL,
 	  	  	 @CauseCommentId 	  	  	 = NULL,
 	  	  	 @ActionCommentId 	  	  	 = NULL,
 	  	  	 @ResearchCommentId 	  	 = NULL
--Confirm TEDetId
IF @TransactionType IN (2,3) OR @ClientUpdateOnly = 1
BEGIN
 	 IF (SELECT COUNT(*) FROM Alarms WHERE Alarm_Id = @VariableAlarmId) = 0
 	 BEGIN
 	  	 SELECT 	 @RC = 1,
 	  	  	  	  	 @ErrMsg = 'Variable Alarm Not Found'
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @PUId 	  	  	  	  	  	  	 = a.Source_PU_Id,
 	  	  	  	  	 @ATId 	  	  	  	  	  	  	 = atemp.AT_Id,
 	  	  	  	  	 @ATDId 	  	  	  	  	  	 = atd.ATD_Id,
 	  	  	  	  	 @AlarmTypeId 	  	  	  	 = atemp.Alarm_Type_Id,
 	  	  	  	  	 @VarId 	  	  	  	  	  	 = v.Var_Id,
 	  	  	  	  	 @Cutoff 	  	  	  	  	  	 = a.Cutoff,
 	  	  	  	  	 @Cause1Id 	  	  	  	  	 = a.Cause1,
 	  	  	  	  	 @Cause2Id 	  	  	  	  	 = a.Cause2,
 	  	  	  	  	 @Cause3Id 	  	  	  	  	 = a.Cause3,
 	  	  	  	  	 @Cause4Id 	  	  	  	  	 = a.Cause4,
 	  	  	  	  	 @Action1Id 	  	  	  	  	 = a.Action1,
 	  	  	  	  	 @Action2Id 	  	  	  	  	 = a.Action2,
 	  	  	  	  	 @Action3Id 	  	  	  	  	 = a.Action3,
 	  	  	  	  	 @Action4Id 	  	  	  	  	 = a.Action4,
 	  	  	  	  	 @ResearchStatusId 	  	  	 = a.Research_Status_Id,
 	  	  	  	  	 @ResearchUserId 	  	  	 = a.Research_User_Id,
 	  	  	  	  	 @AckById 	  	  	  	  	  	 = a.Ack_By,
 	  	  	  	  	 @TemplateVarCommentId 	 = atd.Comment_Id,
 	  	  	  	  	 @VarCommentId 	  	  	  	 = v.Comment_Id,
 	  	  	  	  	 @CauseCommentId 	  	  	 = a.Cause_Comment_Id,
 	  	  	  	  	 @ActionCommentId 	  	  	 = a.Action_Comment_Id,
 	  	  	  	  	 @ResearchCommentId 	  	 = a.Research_Comment_Id
 	  	  	 FROM 	 Alarms a
 	  	  	 JOIN 	 Alarm_Template_Var_Data atd 	 ON 	 atd.ATD_Id = a.ATD_Id
 	  	  	 JOIN 	 Alarm_Templates atemp 	  	  	 ON atemp.AT_Id = atd.AT_Id
 	  	  	 JOIN 	 Variables v 	  	  	  	  	  	  	 ON v.Var_Id = atd.Var_Id
 	  	  	 WHERE 	 Alarm_Id = @VariableAlarmId
 	 END
END
--Lookup Unit
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PL_Id = @PLId AND
 	  	  	 PU_Desc = @UnitName
SELECT 	 @VarId = Var_Id
 	 FROM 	 Variables
 	 WHERE 	 Var_Desc = @VariableName
SELECT 	 @ATId = AT_Id
 	 FROM 	 Alarm_Templates
 	 WHERE 	 AT_Desc = @TemplateName
SELECT 	 @ATDId = ATD_Id
 	 FROM 	 Alarm_Template_Var_Data
 	 WHERE 	 AT_Id = @ATId
 	 AND 	 Var_Id = @VarId
SELECT 	 @Cause1Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause1
SELECT 	 @Cause2Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause2
SELECT 	 @Cause3Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause3
SELECT 	 @Cause4Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause4
SELECT 	 @Action1Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action1
SELECT 	 @Action2Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action2
SELECT 	 @Action3Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action3
SELECT 	 @Action4Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action4
SELECT 	 @ResearchStatusId = Research_Status_Id
 	 FROM 	 Research_Status
 	 WHERE 	 Research_Status_Desc = @ResearchStatus
SELECT 	 @ResearchUserId = User_Id
 	 FROM 	 Users
 	 WHERE UserName = @ResearchUserName
SELECT 	 @AckById = User_Id
 	 FROM 	 Users
 	 WHERE UserName = @AckBy
SELECT 	 @TemplateVarCommentId = Comment_Id
 	 FROM 	 Alarm_Template_Var_Data
 	 WHERE 	 ATD_Id = @ATDId
SELECT 	 @VarCommentId = Comment_Id
 	 FROM 	 Variables
 	 WHERE 	 Var_Id = @VarId
IF @WriteDirect = 1
BEGIN
 	 SELECT 	 @RC = 1,
 	  	  	  	 @ErrMsg = 'WriteDirect is not Supported for This Message Type.'
END
IF @PUId IS NULL
BEGIN
 	 SELECT 	 @RC = 2,
 	  	  	  	 @ErrMsg = 'Unit Specified Not Found'
END ELSE
IF @VarId IS NULL
BEGIN
 	 SELECT 	 @RC = 3,
 	  	  	  	 @ErrMsg = 'Variable Specified Not Found'
END ELSE
IF @ATId IS NULL
BEGIN
 	 SELECT 	 @RC = 4,
 	  	  	  	 @ErrMsg = 'Unable to determine Alarm Template'
END ELSE
IF @AlarmTypeId IS NULL
BEGIN
 	 SELECT 	 @RC = 5,
 	  	  	  	 @ErrMsg = 'Unable to determine Alarm Type'
END
IF @RC = 0
BEGIN
 	 SELECT 	 ResultSetType 	  	  	  	  	 = 6, 	 -- Alarm
 	  	  	  	 PreDB 	  	  	  	  	  	  	  	 = CASE @ClientUpdateOnly 
 	  	  	  	  	  	  	  	  	  	  	  	  	      WHEN 1 THEN 0 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	   WHEN 0 THEN 1 
 	  	  	  	  	  	  	  	  	  	  	  	  	   END,
 	  	  	  	 TransNum 	  	  	  	  	  	  	 = @TransNum,
 	  	  	  	 AlarmId 	  	  	  	  	  	  	 = @VariableAlarmId,
 	  	  	  	 ATDId 	  	  	  	  	  	  	  	 = @ATDId,
 	  	  	  	 StartTime 	  	  	  	  	  	 = @StartTime,
 	  	  	  	 EndTime 	  	  	  	  	  	  	 = @EndTime,
 	  	  	  	 Duration 	  	  	  	  	  	  	 = DATEDIFF(SECOND, @StartTime, @EndTime) / 60,
 	  	  	  	 Ack 	  	  	  	  	  	  	  	 = @Ack,
 	  	  	  	 AckOn 	  	  	  	  	  	  	  	 = @AckOn,
 	  	  	  	 AckBy 	  	  	  	  	  	  	  	 = @AckBy,
 	  	  	  	 StartResult 	  	  	  	  	  	 = @StartValue,
 	  	  	  	 EndResult 	  	  	  	  	  	 = @EndValue,
 	  	  	  	 MinResult 	  	  	  	  	  	 = @MinValue,
 	  	  	  	 MaxResult 	  	  	  	  	  	 = @MaxValue,
 	  	  	  	 Cause1 	  	  	  	  	  	  	 = @Cause1Id,
 	  	  	  	 Cause2 	  	  	  	  	  	  	 = @Cause2Id,
 	  	  	  	 Cause3 	  	  	  	  	  	  	 = @Cause3Id,
 	  	  	  	 Cause4 	  	  	  	  	  	  	 = @Cause4Id,
 	  	  	  	 CauseCommentId 	  	  	  	  	 = @CauseCommentId,
 	  	  	  	 Action1 	  	  	  	  	  	  	 = @Action1Id,
 	  	  	  	 Action2 	  	  	  	  	  	  	 = @Action2Id,
 	  	  	  	 Action3 	  	  	  	  	  	  	 = @Action3Id,
 	  	  	  	 Action4 	  	  	  	  	  	  	 = @Action4Id,
 	  	  	  	 ActionCommentId 	  	  	  	 = @ActionCommentId,
 	  	  	  	 ResearchUserId 	  	  	  	  	 = @ResearchUserId,
 	  	  	  	 ResearchStatusId 	  	  	  	 = @ResearchStatusId,
 	  	  	  	 ResearchOpenDate 	  	  	  	 = @ResearchOpenDate,
 	  	  	  	 ResearchCloseDate 	  	  	  	 = @ResearchCloseDate,
 	  	  	  	 ResearchCommentId 	  	  	  	 = @ResearchCommentId,
 	  	  	  	 SourcePUId 	  	  	  	  	  	 = @PUId,
 	  	  	  	 AlarmTypeId 	  	  	  	  	  	 = @AlarmTypeId,
 	  	  	  	 KeyId 	  	  	  	  	  	  	  	 = @VarId,
 	  	  	  	 AlarmDesc 	  	  	  	  	  	 = @AlarmName,
 	  	  	  	 TransType 	  	  	  	  	  	 = @TransactionType,
 	  	  	  	 TemplateVariableCommentId 	 = @TemplateVarCommentId,
 	  	  	  	 APId 	  	  	  	  	  	  	  	 = @APId,
 	  	  	  	 ATId 	  	  	  	  	  	  	  	 = @ATId,
 	  	  	  	 VarCommentId 	  	  	  	  	 = @VarCommentId,
 	  	  	  	 Cutoff 	  	  	  	  	  	  	 = @Cutoff
END 
-- RETURN BACK SUCCESS CODE AND ERROR MESSAGES
SELECT 	 ResultSet 	 = -999, 
 	  	  	 ReturnCode 	 = @RC, 
 	  	  	 ErrorMsg 	  	 = @ErrMsg
RETURN
