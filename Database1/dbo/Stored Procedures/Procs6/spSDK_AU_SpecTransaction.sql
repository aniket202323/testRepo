CREATE procedure [dbo].[spSDK_AU_SpecTransaction]
@AppUserId int,
@ApprovedBy varchar(100) ,
@ApprovedById int ,
@ApprovedOn datetime ,
@CommentId int OUTPUT,
@CommentText text ,
@CreationDate datetime ,
@EffectiveDate datetime ,
@SpecTransaction varchar(100) ,
@SpecTransactionGroup varchar(100) ,
@SpecTransactionGroupId int ,
@Id int OUTPUT
AS
DECLARE @OldCommentId Int
DECLARE @OldtransDesc VarChar(100)
DECLARE @OldtransGroupId Int
DECLARE @IsApproved Int
IF @Id Is Null
BEGIN
 	 SELECT @Id = Trans_id From Transactions WHERE Trans_Desc = @SpecTransaction
 	 IF @Id Is Not Null
 	 BEGIN
 	  	 SELECT 'Add Failed - A transaction with same name already exists'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateTransaction @SpecTransaction,null,1,null,@AppUserId,@Id Output
END
ELSE
BEGIN
 	 IF NOT EXISTS(Select 1 from Transactions WHERE Trans_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Update Failed - Transaction not found'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldCommentId = Comment_Id,@OldtransDesc = Trans_Desc ,@OldtransGroupId = Transaction_Grp_Id,
 	  	  	  	 @IsApproved = case WHEN Approved_By Is Null then 0 Else 1 end
 	  	 FROM Transactions WHERE Trans_Id = @Id
 	 IF @OldtransDesc <> @SpecTransaction
 	  	 EXECUTE spEM_RenameTrans @id,@SpecTransaction,@AppUserId
 	 IF @OldtransGroupId <> @SpecTransactionGroupId and @IsApproved = 1
 	  	 EXECUTE spEM_ChangeApprovedGroup @id,@SpecTransactionGroupId,@AppUserId
END
SET @CommentId = COALESCE(@OldCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
  UPDATE Transactions SET Comment_Id = null WHERE Trans_Id = @Id
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Transactions SET Comment_Id = @CommentId WHERE Trans_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
