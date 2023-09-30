CREATE procedure [dbo].[spSDK_AU_AlarmTemplate_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ActionRequired bit ,
@ActionTree varchar(100) ,
@ActionTreeId int ,
@AlarmPriority varchar(100) ,
@AlarmPriorityId int ,
@AlarmTemplate varchar(100) ,
@AlarmType varchar(100) ,
@AlarmTypeId int ,
@CauseRequired bit ,
@CauseTree varchar(100) ,
@CauseTreeId int ,
@CommentId int OUTPUT,
@CommentText text,
@CustomText varchar(100) ,
@DefaultAction1 varchar(100) ,
@DefaultAction1Id int ,
@DefaultAction2 varchar(100) ,
@DefaultAction2Id int ,
@DefaultAction3 varchar(100) ,
@DefaultAction3Id int ,
@DefaultAction4 varchar(100) ,
@DefaultAction4Id int ,
@DefaultCause1 varchar(100) ,
@DefaultCause1Id int ,
@DefaultCause2 varchar(100) ,
@DefaultCause2Id int ,
@DefaultCause3 varchar(100) ,
@DefaultCause3Id int ,
@DefaultCause4 varchar(100) ,
@DefaultCause4Id int ,
@DQCriteria tinyint ,
@DQTag varchar(100) ,
@DQValue varchar(100) ,
@DQVarId int ,
@ESignatureLevel varchar(100) ,
@ESignatureLevelId int ,
@EventReasonTreeDataId int ,
@LowerEntry bit ,
@LowerReject bit ,
@LowerUser bit ,
@LowerWarning bit ,
@SPName varchar(100) ,
@StringSpecificationSetting tinyint ,
@Target bit ,
@UpperEntry bit ,
@UpperReject bit ,
@UpperUser bit ,
@UpperWarning bit ,
@UseAT bit ,
@UseTrigger bit ,
@UseVar bit 
AS
DECLARE @DQPLDesc VarChar(50)
DECLARE @DQPUDesc VarChar(50)
DECLARE @DQVarDesc VarChar(50)
DECLARE @sComment VarChar(255)
DECLARE @OldAlarmDesc 	 VarChar(50)
DECLARe @CurrentCommentId Int
DECLARE @ReturnMessages TABLE(msg VarChar(100))
IF @Id Is NOT Null --Rename
BEGIN
 	 IF Not Exists(SELECT 1 FROM Alarm_Templates WHERE AT_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Alarm_Template not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldAlarmDesc = AT_Desc,@CurrentCommentId = Comment_Id   FROM Alarm_Templates WHERE AT_Id = @Id
 	 IF @OldAlarmDesc <> @AlarmTemplate
 	 BEGIN
 	  	 UPDATE Alarm_Templates SET AT_Desc = @AlarmTemplate 	 WHERE AT_Id = @Id
 	 END
 	 IF @CurrentCommentId Is NULL and @CommentId Is Not Null
 	 BEGIN
 	  	 UPDATE Alarm_Templates SET Comment_Id = @CommentId 	 WHERE AT_Id = @Id
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Alarm_Templates a WHERE AT_Desc = @AlarmTemplate)
 	 BEGIN
 	  	 SELECT 'Alarm_Template exists add not allowed'
 	  	 RETURN(-100)
 	 END
END
SELECT @DQPLDesc = c.PL_Desc,@DQPUDesc = b.PU_Desc,@DQVarDesc = a.Var_Desc
 	 from Variables_Base as a
 	 Join Prod_Units_Base b on b.PU_Id = a.PU_Id
 	 Join Prod_Lines_Base c on c.PL_Id = b.PL_Id
 	 WHERE a.Var_Id = @DQVarId
SET @sComment = substring(@CommentText,1,255)
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportAlarmTemplates 	 @AlarmTemplate,@CustomText,@UseVar,@UseAT,@UseTrigger,
 	  	 @DQPLDesc,@DQPUDesc,@DQVarDesc,@DQCriteria,@DQValue,
 	  	 @CauseRequired,@CauseTree,@DefaultCause1,@DefaultCause2,@DefaultCause3,
 	  	 @DefaultCause4,@ActionRequired,@ActionTree,@DefaultAction1,@DefaultAction2,
 	  	 @DefaultAction3,@DefaultAction4,@sComment,@AlarmType,@ESignatureLevel,
 	  	 @SPName,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = AT_Id FROM Alarm_Templates WHERE AT_Desc = @AlarmTemplate
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Alarm Template failed'
 	  	 RETURN(-100)
 	 END
END
UPDATE Alarm_Templates SET Lower_Entry = @LowerEntry,Lower_Reject = @LowerReject,Lower_User = @LowerUser,Lower_Warning = @LowerWarning,
 	  	  	  	  	  	 Target = @Target,Upper_Entry = @UpperEntry,Upper_Reject = @UpperReject,Upper_User = @UpperUser,Upper_Warning = @UpperWarning,
 	  	  	  	  	  	 AP_Id = @AlarmPriorityId,DQ_Tag = @DQTag,String_Specification_Setting = @StringSpecificationSetting
 	  	 WHERE AT_Id = @Id
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	 UPDATE Alarm_Templates SET Comment_Id = Null WHERE AT_Id = @Id
 	 SET @CommentId = NULL
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
