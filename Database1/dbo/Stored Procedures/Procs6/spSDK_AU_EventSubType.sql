CREATE procedure [dbo].[spSDK_AU_EventSubType]
@AppUserId int,
@Id int OUTPUT,
@AckRequired bit ,
@ActionRequired bit ,
@ActionTree nvarchar(50) ,
@ActionTreeId int ,
@CauseRequired bit ,
@CauseTree nvarchar(50) ,
@CauseTreeId int ,
@CommentId int OUTPUT,
@CommentText text ,
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
@DimensionAEnabled tinyint ,
@DimensionAEngineeringUnit nvarchar(15) ,
@DimensionAEngineeringUnitId int ,
@DimensionAName nvarchar(50) ,
@DimensionXEngineeringUnit nvarchar(15) ,
@DimensionXEngineeringUnitId int ,
@DimensionXName nvarchar(50) ,
@DimensionYEnabled tinyint ,
@DimensionYEngineeringUnit nvarchar(15) ,
@DimensionYEngineeringUnitId int ,
@DimensionYName nvarchar(50) ,
@DimensionZEnabled tinyint ,
@DimensionZEngineeringUnit nvarchar(15) ,
@DimensionZEngineeringUnitId int ,
@DimensionZName nvarchar(50) ,
@ESignatureLevel varchar(200) ,
@ESignatureLevelId int ,
@EventControlledProduct bit ,
@EventMask varchar(120) ,
@EventSubType nvarchar(50) ,
@EventType nvarchar(50) ,
@EventTypeId tinyint ,
@ExtendedInfo varchar(255) ,
@IconId int 
AS
DECLARE @subComment VarChar(255)
DECLARE @CurrentComment Int
DECLARE @DurationRequired Int
DECLARE @IconDesc VarChar(50)
DECLARE @OldEventSubType VarChar(50)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
/* @EventControlledProduct  - not currently used*/
SET @subComment = SUBSTRING(@CommentText,1,255)
SELECT @IconDesc = Icon_Desc FROM Icons WHERE Icon_Id = @IconId
IF @Id Is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Event_Subtypes WHERE Event_Subtype_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Event Subtype not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT 	 @OldEventSubType = Event_Subtype_Desc,@CurrentComment = Comment_Id,
 	  	  	  	  	 @DurationRequired = Duration_Required  
 	  	 FROM Event_Subtypes a
 	  	 WHERE Event_Subtype_Id = @Id
 	 IF @OldEventSubType <> @EventSubType
 	 BEGIN
 	  	 UPDATE Event_Subtypes Set Event_Subtype_Desc = @EventSubType WHERE Event_Subtype_Id = @Id
 	 END
END
ELSE
BEGIN
 	 SELECT @Id = Event_Subtype_Id 
 	  	 FROM Event_Subtypes 
 	  	 WHERE Event_Subtype_Desc = @EventSubType
 	 IF @Id Is Not Null
 	 BEGIN
 	  	  	 SELECT 'Event Subtype already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportEventSubTypes 	 @EventType,@EventSubType,@EventMask,@DimensionXName,@DimensionXEngineeringUnit,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @DimensionYEnabled,@DimensionYName,@DimensionYEngineeringUnit,@DimensionZEnabled,@DimensionZName,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @DimensionZEngineeringUnit,@DimensionAEnabled,@DimensionAName,@DimensionAEngineeringUnit,@AckRequired,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @DurationRequired,@CauseRequired,@CauseTree,@DefaultCause1,@DefaultCause2,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @DefaultCause3,@DefaultCause4,@ActionRequired,@ActionTree,@DefaultAction1,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @DefaultAction2,@DefaultAction3,@DefaultAction4,@IconDesc,@subComment,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ESignatureLevel,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is NULL
BEGIN
 	 SELECT @Id =  Event_Subtype_Id  
 	  	  	 FROM Event_Subtypes 
 	  	  	 WHERE Event_Subtype_Desc = @EventSubType
END
Update Event_Subtypes Set Extended_Info = @ExtendedInfo Where Event_Subtype_Id = @Id
SET @CommentId = COALESCE(@CurrentComment,@CommentId)
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
    UPDATE Event_Subtypes SET Comment_Id = @CommentId WHERE Event_Subtype_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
