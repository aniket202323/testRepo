CREATE PROCEDURE dbo.spServer_DBMgrUpdPrdExecPathUnitStarts
@PEPUSId int OUTPUT,
@TransType int,
@TransNum int,
@PUId int,
@PathId int,
@StartTime datetime,
@EndTime datetime,
@CommentId int
AS
  --
  -- Transaction Types
  -- 1 - Insert
  -- 2 - Update
  -- 3 - Delete
  --
  -- Return Values:
  --
  --   (-100)  Error.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
  --
Declare @XLock BIT,
  @Check int,
 	 @MyOwnTrans 	  	  	 Int
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
If (@TransNum is NULL)
  select @TransNum = 2
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
If @TransNum NOT IN (0,2,1000)
  Return(-100)
IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @PEPUSId is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @Check  = NULL
 	  	 SELECT  @Check = PEPUS_Id  FROM PrdExec_Path_Unit_Starts WHERE PEPUS_Id  = @PEPUSId
 	  	 IF @Check is Null RETURN(4)-- Not Found
 	  	 UPDATE PrdExec_Path_Unit_Starts SET Comment_id = @CommentId
 	  	  	  	 WHERE PEPUS_Id  = @PEPUSId
 	  	 RETURN(2)
 	 END
Select @Check = NULL
If @TransType = 1
  Begin
    -- Begin a new transaction.
    --
    If @MyOwnTrans = 1 
      BEGIN
        BEGIN TRANSACTION
        SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
      END
    Insert Into PrdExec_Path_Unit_Starts (
      PU_Id,
      Path_Id,
      Start_Time,
      End_Time,
      Comment_Id)
    Values (
      @PUId,
      @PathId,
      @StartTime,
      @EndTime,
      @CommentId)
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
       	 return (-100)
      End
    else 
      Begin
        If @MyOwnTrans = 1 COMMIT TRANSACTION
       	 return (1)
      End
  End
Else If @TransType = 2
  Begin
    -- Begin a new transaction.
    --
   	 If @TransNum = 0
   	   Begin
     	  	 Select @PUId = Coalesce(@PUId,PU_Id),
     	  	  	 @PathId = Coalesce(@PathId,Path_Id),
     	  	  	 @StartTime = Coalesce(@StartTime,Start_Time),
     	  	  	 @EndTime = Coalesce(@EndTime,End_Time),
     	  	  	 @CommentId = Coalesce(@CommentId,Comment_Id)
     	  	  From PrdExec_Path_Unit_Starts
     	  	  Where (PEPUS_Id = @PEPUSId)
   	   End
    If @MyOwnTrans = 1 
      BEGIN
        BEGIN TRANSACTION
        SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
      END
    Update PrdExec_Path_Unit_Starts 
      Set PU_Id = @PUId,
      Path_Id = @PathId,
      Start_Time = @StartTime,
      End_Time = @EndTime,
      Comment_Id = @CommentId
    Where PEPUS_Id = @PEPUSId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        return (-100)
      End
    else 
      Begin
        If @MyOwnTrans = 1 COMMIT TRANSACTION
        	 return (2)
      End
  End
Else If @TransType = 3
  Begin
    -- Begin a new transaction.
    --
    If @MyOwnTrans = 1 
      BEGIN
        BEGIN TRANSACTION
        SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
      END
    --These qualifiers should be handled by the client code but double-check here
    Select @Check = Comment_Id From PrdExec_Path_Unit_Starts Where PEPUS_Id = @PEPUSId
    If (@Check Is Not Null)
      Begin
        Update Comments 
          Set ShouldDelete = 1, 
              Comment = '',
              Comment_Text = ''
          Where Comment_Id = @Check
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            return (-100)
          End
      End
    Delete From PrdExec_Path_Unit_Starts Where PEPUS_Id = @PEPUSId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error deleting Setup')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
       	 return (-100)
      End
    If @MyOwnTrans = 1 COMMIT TRANSACTION
    return (3)
  End
--If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
If @@Trancount > 0 
  BEGIN
    If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    return(-100)
  END
return(4)
