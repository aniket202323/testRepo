CREATE PROCEDURE dbo.spServer_DBMgrUpdGrade2
  @CurrentId        int          OUTPUT,
  @CurrentPU        int,
  @CurrentProduct   int,
  @Confirmed        int,
  @CurrentStart    datetime OUTPUT,
  @TransNum int,  	    	    	    	  -- NewParam
  @UserId int,  	    	    	    	    	  -- NewParam
  @CommentId int,  	    	    	    	  -- NewParam
  @EventSubTypeId int,  	    	    	    	  -- NewParam
  @CurrentEnd         datetime     OUTPUT,
  @Product_Code     nVarChar(50)  OUTPUT,
  @ReturnResultSet  int =1,
  @ModifiedStart    datetime  OUTPUT,
  @ModifiedEnd  	      datetime  OUTPUT,
  @SecondUserId int = NULL, -- NewParam
  @SignatureId int = NULL
AS 
Declare @Id Int,@DebugFlag Int
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
Select @DebugFlag = 0
SELECT @ReturnResultSet = ISNULL(@ReturnResultSet,1)
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spServer_DBMgrUpdGrade2 /TransNum: ' + Coalesce(convert(nvarchar(10),@TransNum),'Null') + 
 	 ' /PSId: ' + Coalesce(convert(nvarchar(10),@CurrentId),'Null') + 
 	 ' /PUId: ' + Coalesce(convert(nvarchar(10),@CurrentPU),'Null') + 
 	 ' /ProdId: ' + Coalesce(convert(nvarchar(10),@CurrentProduct),'Null') +
 	 ' /Start: ' + Isnull(convert(nVarChar(25),@CurrentStart,120),'Null') + 
 	 ' /UserId: ' + Coalesce(convert(nvarchar(10),@UserId),'Null') + 
 	 ' /CommentId: ' + Coalesce(convert(nvarchar(10),@CommentId),'Null') + 
 	 ' /ESubtypeId: ' + Coalesce(convert(nvarchar(10),@EventSubTypeId),'Null'))
  End
  --
  -- Return Values:
  --
  --   (1) Success: New record added.
  --   (2) Success: Existing record modified.
  --   (3) Success: No action taken.
  --   (4) Success: Record deleted..
  --   (5) Error:   Product not found.
  --   (6) Error:   Production start not found.
  --   (7) Error:   Production start time modified past end of window.
  --   (8) Error:   Production start time modified past beginning of window.
  --   (9) Error:   Production start not initialized.
  --
  -- Declare local variables.
  --
  Declare @Return_Code int
  Declare @PrevID int
  Declare @PrevStart datetime
  Declare @PrevEnd datetime
  Declare @PrevProduct int
  Declare @NextID int
  Declare @NextStart datetime
  Declare @NextEnd datetime
  Declare @NextProduct int
  Declare @TestID int
  Declare @TestStart datetime
  Declare @TestEnd datetime
  Declare @TestProduct int
  Declare @TestPU int
  Declare @TestConfirmed tinyint
  Declare @ChainTime datetime
  Declare @DeleteNeeded tinyint
  Declare @MyOwnTrans Int
  Declare @@TN_StartId int
 	 DECLARE @OldTime DateTime
  select @ModifiedStart  	  = NULL
  select @ModifiedEnd  	  = NULL
 	 If (@TransNum =1010) -- Transaction From WebUI
 	   SELECT @TransNum = 0
  IF EXISTS (SELECT 1 From Production_Starts where Pu_id = @CurrentPU AND Prod_Id = @CurrentProduct AND End_time is null)
  Begin
 	 SELECT @Return_Code = 3
 	  
 	 GOTO Return_Error
  End---DE165061/DE146174
  If @@Trancount = 0
    Select @MyOwnTrans = 1
  Else
    Select @MyOwnTrans = 0
  If @TransNum Not In(0,2,1000)
  BEGIN
 	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Bad TransNum Return(3)' )
     Return(3)
  END
 	 IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @CurrentId is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(3)
 	  	 SET @TestID  = NULL
 	  	 SELECT  @TestID = Start_Id FROM Production_Starts WHERE Start_Id = @CurrentId
 	  	 IF @TestID is Null RETURN(3)-- Not Found
 	  	  	 UPDATE Production_Starts SET Comment_id = @CommentId,User_Id  = @UserId  
 	  	  	  	 WHERE Start_Id = @CurrentID
 	  	 RETURN(2)
 	 END
  --
  -- Find the new product code. Return an error if we don't find the product.
  --
  SELECT @Product_Code = NULL
  SELECT @Product_Code = Prod_Code FROM Products WHERE (Prod_Id = @CurrentProduct)
  IF @Product_Code IS NULL
    BEGIN
      SELECT @Return_Code = 5,
             @Product_Code = ''
      GOTO Return_Error
    END
 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Start Path starts' )
Declare @PathId 	 Int,@IsSchedCtl Int,@STime DateTime,@ETime DateTime,@PCode nVarChar(100),@MStart DateTime,@MEnd DateTime
  select distinct Path_Id Into #Paths from prdexec_path_products where Prod_Id = @CurrentProduct
  If (Select  Count(*) From prdexec_path_units Where PU_Id = @CurrentPU and Path_Id in (select Path_Id from #Paths)) = 1
 	 Begin
 	   Select  @PathId =  Path_Id From prdexec_path_units Where PU_Id = @CurrentPU and  Path_Id in (select Path_Id from #Paths)
 	   Select @IsSchedCtl = Is_Schedule_Controlled from prdexec_paths where Path_Id = @PathId
 	   If @IsSchedCtl = 0
 	  	 Begin
 	  	   Select @Stime =@CurrentStart ,@Etime = @CurrentEnd
 	  	   Execute spServer_DBMgrUpdPrdExecPathStarts  Null,@CurrentPU,@PathId,@STime Output,0,8,@PCode Output, @ETime OUTPUT,  @MStart  OUTPUT,  @MEnd  OUTPUT
 	  	 End
  	 End
 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'End Path starts' )
  --
  -- For some input variables, we allow zero to represent NULL. Convert these
  -- values to NULL.
  --
  SELECT @CurrentId = CASE @CurrentId WHEN 0 THEN NULL ELSE @CurrentId END
  Select @TestID = Null
  Select @TestPU = Null
  Select @DeleteNeeded = 0
  If @CurrentID Is Not Null
    -- If ID Is Specified, See If We Can Find It By Id
    Begin
      Select @TestPU = PU_Id,
             @TestStart = Start_Time,
             @TestEnd = End_Time,
             @TestProduct = Prod_Id,
             @TestConfirmed = Confirmed
        From Production_Starts
        Where Start_Id = @CurrentID
        -- Make Sure We Found It And The Unit Did Not Change
        If (@TestPU Is Null) or (@TestPU <> @CurrentPU) 
          Begin
            Select @Return_Code = 6
            Goto Return_Error
          End
        -- Make Sure We Didn't Move TimeStamp Outside Current Window
        If @CurrentStart <> @TestStart 
          Begin
             Select @ChainTime = @TestStart       
             Select @TestEnd = (Select Min(Start_Time) From Production_Starts Where PU_Id = @CurrentPU and Start_Time > @TestStart) 
             Select @TestStart = (Select Max(Start_Time) From Production_Starts Where PU_Id = @CurrentPU and Start_Time < @TestStart) 
             If @CurrentStart <= @TestStart
               Begin
                 Select @Return_Code = 8
                 Goto Return_Error
               End
             If (@TestEnd Is Not Null) And (@CurrentStart >= @TestEnd)
               Begin
                 Select @Return_Code = 7
                 Goto Return_Error
               End
          End
        Else
          Begin
             Select @ChainTime = @CurrentStart      
          End
        -- Lets Move Forward With The Update
        Select @TestID = @CurrentID
    End
   Else
    -- If ID Is Not Specified, See If We Can Find It By Time
    Begin
      Select @TestID = Start_Id,
             @TestStart = Start_Time,
             @TestEnd = End_Time,
             @TestProduct = Prod_Id,
             @TestConfirmed = Confirmed
        From Production_Starts
        Where PU_Id = @CurrentPU and Start_Time = @CurrentStart              
      Select @ChainTime = @CurrentStart      
    End 
  -- If We Found An Existing Record, See If It Matches Exactly
  If (@TestID Is Not Null) and (@TestStart = @CurrentStart) and (@TestProduct = @CurrentProduct) and (@TestConfirmed <> 0) 
    Begin
      Select @CurrentEnd = @TestEnd
      Select @Return_Code = 3
      Goto Return_Success
    End
  -- If We Found An Existing Record, Set ID To Update
  If @TestID Is Not Null  Select @CurrentID = @TestID 
  -- Find Previous Record In Chain, Use Time From Logic Above
  Select @PrevID = Null
  Select @PrevProduct = Null
  Select @PrevID = Start_Id,
         @PrevStart = Start_Time,
         @PrevEnd = End_Time,
         @PrevProduct = Prod_Id
    From Production_Starts
    Where PU_Id = @CurrentPU and
          Start_Time = (Select Max(Start_Time) From Production_Starts Where PU_Id = @CurrentPU and Start_Time < @ChainTime) 
  If @PrevId Is Null 
    Begin
      Select @Return_Code = 9
      Goto Return_Error
    End
  -- Find Next Record in Chain, Use Time From Logic Above
  Select @NextID = Null
  Select @NextStart = Null
  Select @NextEnd = Null
  Select @NextProduct = Null
  Select @NextID = Start_Id,
         @NextStart = Start_Time,
         @NextEnd = End_Time,
         @NextProduct = Prod_Id
    From Production_Starts
    Where PU_Id = @CurrentPU and
          Start_Time = (Select Min(Start_Time) From Production_Starts Where PU_Id = @CurrentPU and Start_Time > @ChainTime) 
  Select @ModifiedStart = @PrevEnd
  Select @ModifiedEnd  	  = @NextStart
  -- If Previous Has Same Grade As Current, Switch To Updating Previous
  If (@PrevID Is Not Null) and (@PrevProduct = @CurrentProduct) 
    Begin
       Select @CurrentID = @PrevID
       Select @CurrentStart = @PrevStart
  	     select @ModifiedStart = @PrevEnd
       Select @DeleteNeeded = 1
    End
  -- Set End Time To Next Start
  Select @CurrentEnd = @NextStart
  If @MyOwnTrans = 1 
  BEGIN
    BEGIN TRANSACTION
    DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
  END
  -- If Next Has Same Grade As Current, Set End Time To Next End and Delete Next
  If (@NextId Is Not Null) and (@CurrentProduct = @NextProduct)
    Begin
      -- Code Below Added By Tom Nettell 6/5/00
      SELECT @OldTime = Start_Time FROM  Production_Starts WHERE Start_Id = @NextId
      IF @OldTime Is not null
 	  	  	  	 Execute spServer_DBMgrCleanupProdTime  @OldTime,NULL,@ReturnResultSet,@CurrentPU,@UserId
      -- Code Above Added By Tom Nettell 6/5/00
    	    select @ModifiedEnd = @NextStart
      Select @CurrentEnd = @NextEnd
      Delete From Production_Starts Where Start_Id = @NextId    
    End
  -- As Long As Current Is Not Previous, Update The End Time Of Previous
  If (@CurrentID Is Null) or (@CurrentID <> @PrevId)
    Begin
  	    If @CurrentStart < @ModifiedStart
  	    	  Begin
  	       Select @ModifiedEnd = @ModifiedStart
  	       Select @ModifiedStart = @CurrentStart
  	    	  End
  	    If @CurrentStart > @ModifiedStart
  	    	  Begin
  	       Select @ModifiedEnd = @CurrentStart
  	    	  End
      Update Production_Starts  
        Set End_Time = @CurrentStart, Signature_Id = @SignatureId
        Where Start_Id = @PrevID
    End 
  -- If StartID Is Defined, Update, Otherwise Add
  If @CurrentID is Not Null
    Begin
      	  If @CurrentStart < @PrevEnd and @DeleteNeeded = 0
          Select @ModifiedStart = @CurrentStart
      	  If @CurrentStart > @PrevEnd and @DeleteNeeded = 0
          Select @ModifiedEnd = @CurrentStart
      	  If @TransNum = 0
      	    Begin
        	    	  Select  @SecondUserId  	  = Coalesce(@SecondUserId,Second_User_Id),
                         @SignatureId = Coalesce(@SignatureId,Signature_Id)
        	    	   From Production_Starts
        	    	   Where (Start_Id = @CurrentID)
        	    End
 	  	  	 DECLARE @CheckStartTime DateTime,@CheckEndTime DateTime,@CheckProdId Int
 	  	  	 DECLARE @CheckSecondUserId Int, @CheckUserId Int,@CheckSignatureId Int
 	  	  	 DECLARE @CheckConfirmed Int, @SkipUpdate Int
 	  	  	 SELECT  @CheckStartTime = Start_Time, @CheckEndTime = End_Time, @CheckProdId = Prod_Id,
 	  	  	  	  	  	  	  @CheckSecondUserId  = Second_User_Id, @CheckUserId = User_Id, @CheckSignatureId = Signature_Id
 	  	  	  	 FROM Production_Starts
 	  	  	  	 WHERE  Start_Id = @CurrentID
 	  	  	 SET @SkipUpdate = 1
 	  	  	 IF @CheckStartTime != @CurrentStart SET @SkipUpdate = 0
 	  	  	 IF @CheckProdId != @CurrentProduct SET @SkipUpdate = 0
 	  	  	 IF @CheckUserId != @UserId SET @SkipUpdate = 0
 	  	  	 IF @CheckConfirmed != 1 SET @SkipUpdate = 0
 	  	  	 IF @CurrentEnd IS Not Null AND @CheckEndTime IS Not Null
 	  	  	 BEGIN 	  	 
 	  	  	  	 IF @CheckEndTime != @CurrentEnd SET @SkipUpdate = 0
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN 	 
 	  	  	  	 IF @CurrentEnd Is Null  
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @CheckEndTime Is Not NULL SET @SkipUpdate = 0
 	  	  	  	 END 	 
 	  	  	  	 IF @CheckEndTime Is Null  
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @CurrentEnd Is Not NULL SET @SkipUpdate = 0
 	  	  	  	 END 	 
 	  	  	 END
 	  	  	 IF @CheckSecondUserId IS Not Null AND @SecondUserId IS Not Null
 	  	  	 BEGIN 	  	 
 	  	  	  	 IF @CheckSecondUserId != @SecondUserId SET @SkipUpdate = 0
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN 	 
 	  	  	  	 IF @SecondUserId Is Null  
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @CheckSecondUserId Is Not NULL SET @SkipUpdate = 0
 	  	  	  	 END 	 
 	  	  	  	 IF @CheckSecondUserId Is Null  
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @SecondUserId Is Not NULL SET @SkipUpdate = 0
 	  	  	  	 END 	 
 	  	  	 END
 	  	  	 IF @SignatureId IS Not Null AND @CheckSignatureId IS Not Null
 	  	  	 BEGIN 	  	 
 	  	  	  	 IF @CheckSignatureId != @SignatureId SET @SkipUpdate = 0
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN 	 
 	  	  	  	 IF @SignatureId Is Null  
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @CheckSignatureId Is Not NULL SET @SkipUpdate = 0
 	  	  	  	 END 	 
 	  	  	  	 IF @CheckSignatureId Is Null  
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @SignatureId Is Not NULL SET @SkipUpdate = 0
 	  	  	  	 END 	 
 	  	  	 END
 	  	  	 IF @SkipUpdate = 0
 	  	  	 BEGIN
      SELECT @OldTime = Start_Time FROM  Production_Starts WHERE Start_Id = @CurrentID
      IF @OldTime Is not null and @CurrentStart is not null
      BEGIN
 	  	  	  	 IF @OldTime <> @CurrentStart
 	  	  	  	    Execute spServer_DBMgrCleanupProdTime  @OldTime,@CurrentStart,@ReturnResultSet,@CurrentPU,@UserId
 	  	  	 END
 	  	  	  	 Update Production_Starts  
 	  	  	  	  	 Set Start_Time = @CurrentStart,
 	  	  	  	  	  	  	 End_Time = @CurrentEnd,
 	  	  	  	  	  	  	 Prod_Id = @CurrentProduct,
 	  	  	  	  	  	  	 Confirmed = 1,
 	  	  	  	  	  	  	 Second_User_Id = @SecondUserId,
 	  	  	  	  	  	  	 User_Id = @UserId,
 	  	  	  	  	  	  	 Signature_Id = @SignatureId
 	  	  	  	  	 Where Start_Id = @CurrentID
 	  	  	  	 END
        Select @Return_Code = 2
    End
  Else
    Begin
      Insert Into Production_Starts (PU_Id, Prod_Id, Start_Time, End_Time, Confirmed, User_Id, Second_User_Id, Signature_Id,Comment_Id)
         Values(@CurrentPU, @CurrentProduct, @CurrentStart, @CurrentEnd, 1, @UserId, @SecondUserId, @SignatureId,@CommentId)
      Select @CurrentID = (Select Start_Id From Production_Starts Where PU_Id = @CurrentPU and Start_Time = @CurrentStart)
    	    Select @ModifiedStart = @CurrentStart
    	    Select @ModifiedEnd  	  = @CurrentEnd
      Select @Return_Code = 1
    End
  -- Delete All Records With Start Time Completely Inside Current For 'Delete Transaction'
  if @DeleteNeeded = 1 
    begin
      -- Code Below Added By Tom Nettell 6/5/00
      Declare TNPS_Cursor INSENSITIVE CURSOR
        For (Select Start_Id From Production_Starts Where (PU_Id = @CurrentPU) and (Start_Time > @CurrentStart) and ((Start_Time < @CurrentEnd) or (@CurrentEnd Is Null)))
        Open TNPS_Cursor  
      TN_Fetch_Loop:
        Fetch Next From TNPS_Cursor Into @@TN_StartId
        If (@@Fetch_Status = 0)
          Begin
 	  	  	  	  	  	  	 SELECT @OldTime = Start_Time FROM  Production_Starts WHERE Start_Id = @@TN_StartId
 	  	  	  	       IF @OldTime Is not null
 	  	  	  	  	  	  	  	 Execute spServer_DBMgrCleanupProdTime @OldTime,Null,@ReturnResultSet,@CurrentPU,@UserId
        	      Delete From Production_Starts Where Start_Id = @@TN_StartId
            Goto TN_Fetch_Loop
          End
      Close TNPS_Cursor
      Deallocate TNPS_Cursor
      -- Code Above Added By Tom Nettell 6/5/00
    end
  --
  -- Successful return handler.
  --
  Return_Success:
  --
  -- Commit our transaction and return a successful return code.
  --
  IF @Return_Code <> 3 And @MyOwnTrans = 1 COMMIT TRANSACTION
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return[' + Convert(nvarchar(10),@Return_Code) + ']' )
  RETURN(@Return_Code)
  --
  -- Error return handler.
  --
  Return_Error:
  --
  Select @CurrentEnd = NULL
  --
  --
  --
  IF @CurrentId IS NULL SELECT @CurrentId = 0
  --
  -- Return an unsuccessful return code.
  --
 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return[' + Convert(nvarchar(10),@Return_Code) + ']' )
 RETURN(@Return_Code)
