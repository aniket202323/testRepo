CREATE procedure [dbo].[spSDK_AU_ProductionSetupDetail]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@DimensionA real ,
@DimensionX real ,
@DimensionY real ,
@DimensionZ real ,
@ElementNumber int ,
@ElementStatusId tinyint ,
@ExtendedInfo varchar(255) ,
@CustomerOrderLineId int ,
@PathCode varchar(200) ,
@PathId int ,
@ProcessOrder varchar(200) ,
@ProductCode nvarchar(25) ,
@ProductId int ,
@ProductionPlanId int ,
@ProductionSetupId int ,
@UserGeneral1 varchar(255) ,
@UserGeneral2 varchar(255) ,
@UserGeneral3 varchar(255) 
AS
DECLARE @subComment VarChar(255)
DECLARE @CurrentComment Int
DECLARE @PPStatus Varchar(100)
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @PatternCode varchar(100)
Select @PatternCode = NULL
Select @PatternCode = Pattern_Code from Production_Setup Where PP_Setup_Id = @ProductionSetupId
If (@ProcessOrder Is NULL)
 	 Select @ProcessOrder = Process_Order From Production_Plan Where PP_Id = @ProductionPlanId
If (@PathCode Is NULL)
 	 Select @PathCode = Path_Code from Prdexec_Paths Where Path_Id = @PathId
 	 
SELECT @PPStatus = a.PP_Status_Desc
FROM Production_Plan_Statuses a
WHERE a.PP_Status_Id = @ElementStatusId
Select @subComment = SUBSTRING(@CommentText,1,255)
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportProcessOrderPattern 	  	 @PathCode,@ProcessOrder,@PatternCode,@ElementNumber,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductCode,@PPStatus,@DimensionA,@DimensionX,@DimensionY,@DimensionZ,@ExtendedInfo,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @UserGeneral1,@UserGeneral2,@UserGeneral3,@subComment,@AppUserId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @CurrentComment = Comment_Id,@Id = a.PP_Setup_Detail_Id  
 	  	 FROM Production_Setup_Detail  a
 	  	 WHERE PP_Setup_Id = @ProductionSetupId and Element_Number = @ElementNumber
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'failed to create setup detail'
 	  	 RETURN(-100)
 	 END
END
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
    UPDATE Production_Setup_Detail SET Comment_Id = @CommentId WHERE PP_Setup_Detail_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
