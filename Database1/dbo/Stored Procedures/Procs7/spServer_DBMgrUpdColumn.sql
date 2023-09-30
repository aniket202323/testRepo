CREATE PROCEDURE dbo.spServer_DBMgrUpdColumn
  @Sheet_Id int,
  @Is_Delete int,
  @Result_Year int,
  @Result_Month int,
  @Result_Day int,
  @Result_Hour int,
  @Result_Minute int,
  @Result_Second int,
  @TransNum int, 	  	 -- NewParam
  @UserId int, 	  	  	 -- NewParam
  @CommentId int, 	 -- NewParam
  @ApproverUserId int = NULL, -- NewParam
  @ApproverReasonId int = NULL, -- NewParam
  @UserReasonId int = NULL, -- NewParam
  @UserSignoffId int = NULL, -- NewParam
  @ESignatureId int = NULL
 AS
  -- Declare local variables.
  DECLARE @Result_On datetime,
          @Rc int
  --
  -- Encode the result date/time.
  --
  EXECUTE spServer_DBMgrEncodeDateTime  @Result_Year,@Result_Month,@Result_Day,@Result_Hour,@Result_Minute,@Result_Second,@Result_On      OUTPUT
  Execute @Rc = spServer_DBMgrUpdColumn2  @Sheet_Id ,@Is_Delete , @Result_On ,@TransNum ,@UserId,
  	  	  	  	  	  	  	  	  	  	   @CommentId,@ApproverUserId, @ApproverReasonId, @UserReasonId, @UserSignoffId, @ESignatureId
  RETURN(@Rc)
