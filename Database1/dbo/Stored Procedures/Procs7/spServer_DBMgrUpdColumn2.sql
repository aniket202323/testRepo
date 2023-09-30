CREATE PROCEDURE dbo.spServer_DBMgrUpdColumn2
  @Sheet_Id int,
  @Is_Delete int,
  @Result_On datetime,
  @TransNum int,  	    	  -- NewParam
  @UserId int,  	    	    	  -- NewParam
  @CommentId int,  	  -- NewParam
  @ApproverUserId int = NULL, -- NewParam
  @ApproverReasonId int = NULL, -- NewParam
  @UserReasonId int = NULL, -- NewParam
  @UserSignoffId int = NULL, -- NewParam
  @SignatureId int = NULL, -- NewParam
  @ReturnResultSet int = 2
AS 
 	 SET @ReturnResultSet = Coalesce(@ReturnResultSet,2)
  -- Declare local variables.
 -- DECLARE @PreRelease Int
 -- SELECT @PreRelease = CONVERT(Int, COALESCE(Value, '0')) 
 	 --FROM Site_Parameters 
 	 --WHERE Parm_Id = 608
 -- SELECT @PreRelease = Coalesce(@PreRelease,0)
  DECLARE @Id int
 	 If (@TransNum =1010) -- Transaction From WebUI
 	   SELECT @TransNum = 2
  If @TransNum Not IN (0,2,5) 
    Return(1)
DECLARE @MYId Int,@Sheet_Type_Id int,@Activity_Type_Id Int
Declare @Message nVarChar(1000),@pu_Id Int
SELECT @MYId = Sheet_Id,@Sheet_Type_Id = Sheet_Type,@pu_Id= case When @Sheet_Type_Id in (21,23,16,22) then Master_Unit Else NULL end FROM Sheets WHERE Sheet_Id = @Sheet_Id
SET @Activity_Type_Id = CASE WHEN @Sheet_Type_Id =23 THEN 4 ELSE CASE WHEN @Sheet_Type_Id =21 THEN 5 ELSE 
CASE WHEN @Sheet_Type_Id =16 THEN 7 ELSE CASE WHEN @Sheet_Type_Id =22 THEN 8 ELSE 1 END END END END
IF @MYId IS NULL
BEGIN
 	 Select @Message =  'Invalid Sheet ID [' + isnull(convert(nvarchar(10),@Sheet_Id),'Null') + '] Not Found'
 	 RAISERROR(@Message, 11, -1)
 	 RETURN(-100)
END
  -- Make sure that we do not already have a column on the sheet at the specified time.
  SELECT @Id = NULL 
  SELECT @Id = Sheet_Id 
     FROM Sheet_Columns
     WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @Result_On)
  IF @Is_Delete <> 0
    Begin
      If @Id IS NULL RETURN(2)
      -- Delete the sheet column.
      DELETE FROM Sheet_Columns 
        WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @Result_On)
 	   --Delete associated activies
 	   --IF @PreRelease = 1
 	   --BEGIN
  	    	  EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  @Sheet_Id,null,Null,@Activity_Type_Id,@Sheet_Id,
  	    	    	    	    	    	    	    	    	    	    	  @Result_On,  	  Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  3,0,@UserId, @pu_Id,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,@ReturnResultSet
  	   --END
      RETURN(1)
    End
  -- Update the sheet column.
  IF @Id IS NOT NULL
    Begin
      	  If @TransNum = 0
      	    Begin
        	    	  Select  @Sheet_Id = Coalesce(@Sheet_Id,Sheet_Id),
        	    	    	  @Result_On = Coalesce(@Result_On,Result_On),
       	    	    	  @ApproverUserId = Case When @TransNum <> 5 Then ISNULL(@ApproverUserId, Approver_User_Id) Else @ApproverUserId End,
        	    	    	  @ApproverReasonId = Case When @TransNum <> 5 Then ISNULL(@ApproverReasonId, Approver_Reason_Id) Else @ApproverReasonId End,
       	    	    	  @UserReasonId = Case When @TransNum <> 5 Then ISNULL(@UserReasonId, User_Reason_Id) Else @UserReasonId End,
                 @SignatureId = Coalesce(@SignatureId,Signature_Id),
       	    	    	  @UserSignoffId = Case When @TransNum <> 5 Then ISNULL(@UserSignoffId, User_Signoff_Id) Else @UserSignoffId End,
 	  	  	  	  @CommentId = Coalesce(@CommentId,Comment_id)
        	    	   From Sheet_Columns
        	    	   WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @Result_On)
      	    End
      UPDATE Sheet_Columns 
        SET Approver_User_Id = @ApproverUserId, 
            Approver_Reason_Id = @ApproverReasonId, 
            User_Reason_Id = @UserReasonId, 
            User_Signoff_Id = @UserSignoffId,
            Signature_Id = @SignatureId,
 	  	  	 Comment_Id = @CommentId 	  	  	  	  	  	    
        WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @Result_On)
      RETURN(1)
    End
  -- Add the sheet column.
  INSERT INTO Sheet_Columns(Sheet_Id, Result_On, Approver_User_Id, Approver_Reason_Id, User_Reason_Id, User_Signoff_Id, Signature_Id, Comment_Id) VALUES 
                          (@Sheet_Id, @Result_On, @ApproverUserId, @ApproverReasonId, @UserReasonId, @UserSignoffId, @SignatureId, @CommentId)
 	 --IF @PreRelease = 1
 	 --BEGIN
  	    	  EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  @Sheet_Id,null,Null,@Activity_Type_Id,@Sheet_Id,
  	    	    	    	    	    	    	    	    	    	    	  @Result_On,  	  Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  1,0,@UserId, @pu_Id,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet
 	 --END
  RETURN(1)
