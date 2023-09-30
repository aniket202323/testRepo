CREATE PROCEDURE dbo.spBF_UpdateComment
        @OldCommentId Int Output,
        @commentText text
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	  BEGIN TRY
     BEGIN TRANSACTION
 	 DECLARE @VarCharcommentText nvarchar(max)
 	 DECLARE @NextCommmentId Int
 	 SET @VarCharcommentText =  Ltrim(rtrim(substring(@commentText,1,7000))) 
 	 IF @VarCharcommentText = '' SET @commentText = Null
 	 if @commentText is not null
 	 BEGIN
 	  	 IF @OldCommentId Is NUll
 	  	 BEGIN
 	  	  	 insert into Comments(comment,Modified_On,ShouldDelete,User_Id,NextComment_Id) values (@commentText,GETDATE(),0,dbo.cal_getUserId(),Null);
 	  	  	 set @OldCommentId = SCOPE_IDENTITY()
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 UPDATE Comments Set comment = @commentText WHERE Comment_Id = @OldCommentId
 	  	 END
 	 END
 	 if @commentText iS Null AND @OldCommentId Is Not Null
 	 BEGIN
 	  	 SELECT @NextCommmentId = coalesce(NextComment_Id,topofChain_Id) From Comments WHERE Comment_Id = @OldCommentId
 	  	 IF @NextCommmentId Is Null -- not chained okay to delete
 	  	 BEGIN
 	  	  	 DELETE FROM Comments where comment_Id = @OldCommentId
 	  	 END
 	  	 SET @OldCommentId = Null
 	 END
    COMMIT
  	 END TRY
 	 BEGIN CATCH
 	  	 IF @@TRANCOUNT > 0
      BEGIN
 	  	  	   ROLLBACK;
      END
 	 END CATCH
END
