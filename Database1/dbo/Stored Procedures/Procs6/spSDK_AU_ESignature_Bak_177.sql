CREATE procedure [dbo].[spSDK_AU_ESignature_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@Approver nvarchar(30) ,
@ApproverCommentId int OUTPUT,
@ApproverCommentText text ,
@ApproverId int ,
@ApproverLocation varchar(200) ,
@ApproverReason varchar(100) ,
@ApproverReasonId int ,
@ApproverTime datetime ,
@Operator nvarchar(30) ,
@OperatorCommentId int OUTPUT,
@OperatorCommentText text ,
@OperatorId int ,
@OperatorLocation varchar(200) ,
@OperatorReason varchar(100) ,
@OperatorReasonId int ,
@OperatorTime datetime 
AS
DECLARE @OldOperatorCommentId Int
DECLARE @OldApproverCommentId Int
IF @Id Is NULL
BEGIN
 	 INSERT INTO ESignature(Perform_User_Id,Perform_Node,Perform_Time,Perform_Reason_Id,Perform_Comment_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  Verify_User_Id,Verify_Node,Verify_Time,Verify_Reason_Id,Verify_Comment_Id)
 	  	  	 VALUES(@OperatorId,@OperatorLocation,@OperatorTime,@OperatorReasonId,@OperatorCommentId,
 	  	  	  	  	  	 @ApproverId,@ApproverLocation,@ApproverTime,@ApproverReasonId,@ApproverCommentId)
 	 SET @Id = Scope_Identity()
END
ELSE
BEGIN
 	 SELECT 'Esignature records are not updateable'
 	 RETURN (-100)
END
SET @OperatorCommentId = Coalesce(@OldOperatorCommentId,@OperatorCommentId)
IF @OperatorCommentId IS NOT NULL AND @OperatorCommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @OperatorCommentId
 	 DELETE FROM Comments WHERE Comment_Id = @OperatorCommentId
 	 UPDATE ESignature SET Perform_Comment_Id = Null WHERE Signature_Id = @Id
 	 SET @OperatorCommentId = NULL
END
IF @OperatorCommentId IS NULL AND @OperatorCommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @OperatorCommentText,@OperatorCommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @OperatorCommentId = Scope_Identity()
    UPDATE ESignature SET Perform_Comment_Id = @OperatorCommentId WHERE Signature_Id = @Id
END
ELSE
IF @OperatorCommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @OperatorCommentText,Comment_Text = @OperatorCommentText WHERE Comment_Id = @OperatorCommentId
END
SET @ApproverCommentId = Coalesce(@OldApproverCommentId,@ApproverCommentId)
IF @ApproverCommentId IS NOT NULL AND @ApproverCommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @ApproverCommentId
 	 DELETE FROM Comments WHERE Comment_Id = @ApproverCommentId
 	 UPDATE ESignature SET Verify_Comment_Id = Null WHERE Signature_Id = @Id
 	 SET @ApproverCommentId = NULL
END
IF @ApproverCommentId IS NULL AND @ApproverCommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @ApproverCommentText,@ApproverCommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @ApproverCommentId = Scope_Identity()
    UPDATE ESignature SET Verify_Comment_Id = @ApproverCommentId WHERE Signature_Id = @Id
END
ELSE
IF @ApproverCommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @ApproverCommentText,Comment_Text = @ApproverCommentText WHERE Comment_Id = @ApproverCommentId
END
RETURN(1)
