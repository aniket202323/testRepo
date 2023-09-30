CREATE procedure [dbo].[spSDK_AU_Characteristic]
@AppUserId int,
@Id int OUTPUT,
@Characteristic nvarchar(50) ,
@CommentId int OUTPUT,
@CommentText text ,
@ExtendedInfo varchar(255) ,
@ExternalLink varchar(100) ,
@GroupId int ,
@ParentCharacteristic nvarchar(50) ,
@ParentCharacteristicId int ,
@ProductProperty nvarchar(50) ,
@ProductPropertyId int 
AS
/* @GroupId not currently supported */
DECLARE @ApprovedDate 	  	  	 DateTime,
 	  	  	  	 @CurrentComment 	  	 Int,
 	  	  	  	 @TransId 	  	  	  	  	 Int,
 	  	  	  	 @TransDesc 	  	  	  	 VarChar(50),
 	  	  	  	 @CurrentTransId 	  	 Int,
 	  	  	  	 @EffectiveDate 	  	 DateTime,
 	  	  	  	 @OldParentChar 	  	 Int,
 	  	  	  	 @NeedTrans 	  	  	  	 Int,
 	  	  	  	 @OldCharDesc 	  	  	 VarChar(50)
SET @NeedTrans = 0
 	  	  	  	 
IF @Id Is Not Null
BEGIN
 	 SELECT @OldParentChar = a.Derived_From_Parent,@OldCharDesc = a.Char_Desc,@CurrentComment = a.Comment_Id
 	  	 FROM Characteristics a
 	  	 WHERE Char_Id = @Id
 	 IF @OldCharDesc <> @Characteristic
 	  	 EXECUTE spEM_RenameChar @Id,@Characteristic,@AppUserId
END
ELSE
BEGIN
 	 EXECUTE spEM_CreateChar @Characteristic,@ProductPropertyId,@AppUserId,@Id OUTPUT
 	 SELECT @CurrentComment = Null  
END
EXECUTE spEM_PutExtLink @Id,'aq',@ExternalLink,@ExtendedInfo,Null,@AppUserId
IF @ParentCharacteristicId Is Not Null AND @OldParentChar is Null
BEGIN
 	 SET @NeedTrans = 1
END
IF @ParentCharacteristicId Is Not Null AND @OldParentChar is Not Null
BEGIN
 	 IF @ParentCharacteristicId <> @OldParentChar 
 	  	 SET @NeedTrans = 1
END
IF @ParentCharacteristicId Is Null AND @OldParentChar is Not Null
BEGIN
 	 SET @NeedTrans = 1
END
IF @NeedTrans = 1
BEGIN
 	 SELECT @EffectiveDate = dbo.fnServer_CmnGetDate(GetUtcDate())
 	 SELECT @EffectiveDate = DATEADD(Millisecond,-DatePart(Millisecond,@EffectiveDate),@EffectiveDate)
 	 
 	 IF NOT EXISTS(SELECT 1 FROM Transactions)
 	  	 Select @CurrentTransId = 1
 	 Else
 	  	 SELECT @CurrentTransId = IDENT_CURRENT('Transactions') + 1
 	 
 	 SELECT @TransDesc = '<' + Convert(VarChar(10),@CurrentTransId) + '>' + 'SDK-Specs' 
 	 EXECUTE spEM_CreateTransaction  @TransDesc,Null,1,Null,@AppUserId,@TransId OUTPUT
 	 EXECUTE spEM_PutTransCharLinks @TransId,@Id,@ParentCharacteristicId,@AppUserId
 	 EXECUTE spEM_ApproveTrans @TransId,@AppUserId,1,Null,@ApprovedDate,@EffectiveDate Output
END
SET @CommentId = COALESCE(@CurrentComment,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'aq',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'aq',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
