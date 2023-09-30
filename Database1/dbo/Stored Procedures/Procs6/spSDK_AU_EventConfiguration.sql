CREATE procedure [dbo].[spSDK_AU_EventConfiguration]
 	  	 @AppUserId int,
 	  	 @Id int OUTPUT,
 	  	 @CommentId int OUTPUT,
 	  	 @CommentText text ,
 	  	 @Debug bit ,
 	  	 @Department varchar(200) ,
 	  	 @DepartmentId int ,
 	  	 @ESignatureLevel varchar(200) ,
 	  	 @ESignatureLevelId int ,
 	  	 @EventConfigurationName varchar(50) ,
 	  	 @EventSubType nvarchar(50) ,
 	  	 @EventSubTypeId int ,
 	  	 @EventType nvarchar(50) ,
 	  	 @EventTypeId tinyint ,
 	  	 @Exclusions varchar(255) ,
 	  	 @ExtendedInfo varchar(255) ,
 	  	 @ExternalTimeZone varchar(100) ,
 	  	 @IsCalculationActive tinyint ,
 	  	 @MaxRunTime int ,
 	  	 @Model varchar(255) ,
 	  	 @ModelGroup int ,
 	  	 @ModelId int ,
 	  	 @ModelIsActive tinyint ,
 	  	 @ModelNumber int,
 	  	 @PathInput varchar(100) ,
 	  	 @PathInputId int ,
 	  	 @Priority int ,
 	  	 @ProductionLine nvarchar(50) ,
 	  	 @ProductionLineId int ,
 	  	 @ProductionUnit nvarchar(50) ,
 	  	 @ProductionUnitId int ,
 	  	 @RetentionLimit int 
AS
DECLARE @PartComment VarChar(255)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @CurrentCommentId 	 Int
DECLARE @OldEventConfigurationName VarChar(50)
DECLARE @OldModelId Int
DECLARE @MoveEndTimeInterval 	 varchar(10)
DECLARE @Pre63Server bit
EXEC dbo.spSupport_VerifyDB_PDBVersion  '00013.00000.00960.00000' , @Pre63Server OUTPUT
SET @MoveEndTimeInterval = Null
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
/* @IsCalculationActive  - Not set internal use only*/
If (@EventConfigurationName Is NULL) or (@EventConfigurationName = '')
 	 Begin
 	  	 SELECT 'EventConfigurationName is required'
 	  	 RETURN(-100)
 	 End
 	 
If (@ModelIsActive Is NULL)
 	 Select @ModelIsActive = 0
 	 
if (@PathInput Is NULL)
 	 Select @PathInput = Input_Name From PrdExec_Inputs Where PEI_Id = @PathInputId
If (@ModelNumber Is NULL)
 	 Select @ModelNumber = Model_Num from ED_Models Where ED_Model_Id = @ModelId
IF @Id Is Null
BEGIN
 	 SELECT @Id = EC_Id 
 	  	 FROM Event_Configuration a 
 	  	 Join ed_Models ed on ed.ED_Model_Id =  a.ED_Model_Id
 	  	 WHERE PU_Id = @ProductionUnitId and (a.EC_Desc  = @EventConfigurationName or (a.EC_Desc Is Null and ed.Model_Desc = @EventConfigurationName))
 	 IF @Id Is Not Null
 	 BEGIN
 	  	  	 SELECT 'Event Configuration already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
 	 SET @PartComment = SUBSTRING(@CommentText,1,255)
IF @Pre63Server = 1 
BEGIN 	 
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportEvents @ProductionLine,@ProductionUnit,@EventType,@EventSubType,@EventConfigurationName,@ExtendedInfo,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @Exclusions,@PartComment,@PathInput,@ModelNumber,@ESignatureLevel,@AppUserId
END
ELSE
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportEvents @ProductionLine,@ProductionUnit,@EventType,@EventSubType,@EventConfigurationName,@ExtendedInfo,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @Exclusions,@PartComment,@PathInput,@ModelNumber,@ESignatureLevel,@ExternalTimeZone,@MaxRunTime,@MoveEndTimeInterval,@AppUserId
END 	 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 
 	 SELECT @Id = EC_Id,@CurrentCommentId = a.Comment_Id 
 	  	 FROM Event_Configuration a 
 	  	 Join ed_Models ed on ed.ED_Model_Id =  a.ED_Model_Id
 	  	 WHERE PU_Id = @ProductionUnitId and (a.EC_Desc  = @EventConfigurationName or (a.EC_Desc Is Null and ed.Model_Desc = @EventConfigurationName))
 	 IF @Id Is Null
 	 BEGIN
 	  	 SELECT 'Unable to create new model'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN 
 	 SELECT @CurrentCommentId = Comment_Id,@OldEventConfigurationName = EC_Desc,@OldModelId = ED_Model_Id
 	  	 FROM Event_Configuration
 	  	 WHERE ec_Id = @Id
 	 IF @OldModelId Is Null
 	 BEGIN
 	  	 SELECT 'Event Configuration not found for update'
 	  	 RETURN(-100)
 	 END
 	 IF @OldModelId <> @ModelId
 	 BEGIN
 	  	 SELECT 'Cannot change Model Id - delete and readd instead'
 	  	 RETURN(-100)
 	 END
 	 IF @OldEventConfigurationName <> @EventConfigurationName
 	  	 EXECUTE spEMDT_UpdateEventCfg @Id,@EventConfigurationName,@AppUserId
 	 EXECUTE spEMEC_UpdEventConfigAdvanced @Id, @ExtendedInfo,@Exclusions,@AppUserId
 	 If @EventTypeId IN (2,3) 
 	  	 Execute spEMEC_GetCurrDetESigLevel @Id,2,@ESignatureLevelId,@AppUserId
END
UPDATE Event_Configuration SET PEI_ID = @PathInputId,External_Time_Zone = @ExternalTimeZone,Max_Run_Time = @MaxRunTime,Model_Group = @ModelGroup,
 	 Priority = @Priority,Retention_Limit = @RetentionLimit
 	 WHERE Ec_Id  = @Id
EXECUTE spEMEC_UpdateIsActive @Id,@ModelIsActive,@AppUserId
SET @CommentId = COALESCE(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Event_Configuration SET Comment_Id = @CommentId WHERE EC_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
