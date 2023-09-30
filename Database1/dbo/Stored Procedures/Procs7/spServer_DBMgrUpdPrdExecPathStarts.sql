CREATE PROCEDURE dbo.spServer_DBMgrUpdPrdExecPathStarts
  @CurrentId        int          OUTPUT,
  @CurrentPU        int,
  @CurrentPath   int,
  @CurrentStart    datetime OUTPUT,
  @TransNum int,  	    	    	    	  -- NewParam
  @UserId int,  	    	    	    	    	  -- NewParam
  @Path_Code         nVarChar(100) Output,
  @CurrentEnd         datetime     OUTPUT,
  @ModifiedStart    datetime  OUTPUT,
  @ModifiedEnd  	      datetime  OUTPUT
AS 
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
  Declare @PrevPath int
  Declare @NextID int
  Declare @NextStart datetime
  Declare @NextEnd datetime
  Declare @NextPath int
  Declare @TestID int
  Declare @TestStart datetime
  Declare @TestEnd datetime
  Declare @TestPath int
  Declare @TestPU int
  Declare @TestConfirmed tinyint
  Declare @ChainTime datetime
  Declare @DeleteNeeded tinyint
  Declare @MyOwnTrans Int
  Declare @@TN_StartId int
  select @ModifiedStart  	  = NULL
  select @ModifiedEnd  	  = NULL
 	 If (@TransNum =1010) -- Transaction From WebUI
 	  	 SELECT @TransNum = 2
  If @TransNum Not IN (0,2)
    Return(3)
  If @@Trancount = 0
    Select @MyOwnTrans = 1
  Else
    Select @MyOwnTrans = 0
  --
  -- Find the new product code. Return an error if we don't find the product.
  --
  SELECT @Path_Code = NULL
  SELECT @Path_Code = Path_Code FROM PrdExec_Paths WHERE (Path_Id = @CurrentPath)
  IF @Path_Code IS NULL
    BEGIN
      SELECT @Return_Code = 5,@Path_Code = ''
      GOTO Return_Error
    END
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
             @TestPath = Path_Id
   	  	  From Prdexec_Path_Unit_Starts
        Where PEPUS_Id = @CurrentID
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
             Select @TestEnd = (Select Min(Start_Time) From Prdexec_Path_Unit_Starts Where PU_Id = @CurrentPU and Start_Time > @TestStart) 
             Select @TestStart = (Select Max(Start_Time) From Prdexec_Path_Unit_Starts Where PU_Id = @CurrentPU and Start_Time < @TestStart) 
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
      Select @TestID = PEPUS_Id,
             @TestStart = Start_Time,
             @TestEnd = End_Time,
             @TestPath = Path_Id
        From Prdexec_Path_Unit_Starts
        Where PU_Id = @CurrentPU and Start_Time = @CurrentStart              
      Select @ChainTime = @CurrentStart      
    End 
  -- If We Found An Existing Record, See If It Matches Exactly
  If (@TestID Is Not Null) and (@TestStart = @CurrentStart) and (@TestPath = @CurrentPath)
    Begin
      Select @CurrentEnd = @TestEnd
      Select @Return_Code = 3
      Goto Return_Success
    End
  -- If We Found An Existing Record, Set ID To Update
  If @TestID Is Not Null  Select @CurrentID = @TestID 
  -- Find Previous Record In Chain, Use Time From Logic Above
  Select @PrevID = Null
  Select @PrevPath = Null
  Select @PrevID = PEPUS_Id,
         @PrevStart = Start_Time,
         @PrevEnd = End_Time,
         @PrevPath = Path_Id
    From Prdexec_Path_Unit_Starts
    Where PU_Id = @CurrentPU and
          Start_Time = (Select Max(Start_Time) From Prdexec_Path_Unit_Starts Where PU_Id = @CurrentPU and Start_Time < @ChainTime) 
  If @PrevId Is Null 
    Begin
      Select @Return_Code = 9
      Goto Return_Error
    End
  -- Find Next Record in Chain, Use Time From Logic Above
  Select @NextID = Null
  Select @NextStart = Null
  Select @NextEnd = Null
  Select @NextPath = Null
  Select @NextID = PEPUS_Id,
         @NextStart = Start_Time,
         @NextEnd = End_Time,
         @NextPath = Path_Id
    From Prdexec_Path_Unit_Starts
    Where PU_Id = @CurrentPU and
          Start_Time = (Select Min(Start_Time) From Prdexec_Path_Unit_Starts Where PU_Id = @CurrentPU and Start_Time > @ChainTime) 
  Select @ModifiedStart = @PrevEnd
  Select @ModifiedEnd  	  = @NextStart
  -- If Previous Has Same Path As Current, Switch To Updating Previous
  If (@PrevID Is Not Null) and (@PrevPath = @CurrentPath) 
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
  If (@NextId Is Not Null) and (@CurrentPath = @NextPath)
    Begin
    	   select @ModifiedEnd = @NextStart
      Select @CurrentEnd = @NextEnd
      Delete From Prdexec_Path_Unit_Starts Where PEPUS_Id = @NextId    
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
      Update Prdexec_Path_Unit_Starts  
        Set End_Time = @CurrentStart
        Where PEPUS_Id = @PrevID
    End 
  -- If StartID Is Defined, Update, Otherwise Add
  If @CurrentID is Not Null
    Begin
     	  If @CurrentStart < @PrevEnd and @DeleteNeeded = 0
          Select @ModifiedStart = @CurrentStart
      	  If @CurrentStart > @PrevEnd and @DeleteNeeded = 0
          Select @ModifiedEnd = @CurrentStart
      Update Prdexec_Path_Unit_Starts  
        Set Start_Time = @CurrentStart,
            End_Time = @CurrentEnd,
            Path_Id = @CurrentPath,
            User_Id = @UserId
        Where PEPUS_Id = @CurrentID
        Select @Return_Code = 2
    End
  Else
    Begin
      Insert Into Prdexec_Path_Unit_Starts (PU_Id, Path_Id, Start_Time, End_Time, User_Id)
         Values(@CurrentPU, @CurrentPath, @CurrentStart, @CurrentEnd, @UserId)
      Select @CurrentID = (Select PEPUS_Id From Prdexec_Path_Unit_Starts Where PU_Id = @CurrentPU and Start_Time = @CurrentStart)
    	    Select @ModifiedStart = @CurrentStart
    	    Select @ModifiedEnd  	  = @CurrentEnd
      Select @Return_Code = 1
    End
  -- Delete All Records With Start Time Completely Inside Current For 'Delete Transaction'
  if @DeleteNeeded = 1 
    begin
      Declare TNPS_Cursor INSENSITIVE CURSOR
        For (Select PEPUS_Id From Prdexec_Path_Unit_Starts Where (PU_Id = @CurrentPU) and (Start_Time > @CurrentStart) and ((Start_Time < @CurrentEnd) or (@CurrentEnd Is Null)))
        Open TNPS_Cursor  
      TN_Fetch_Loop:
        Fetch Next From TNPS_Cursor Into @@TN_StartId
        If (@@Fetch_Status = 0)
          Begin
        	      Delete From Prdexec_Path_Unit_Starts Where PEPUS_Id = @@TN_StartId
            Goto TN_Fetch_Loop
          End
      Close TNPS_Cursor
      Deallocate TNPS_Cursor
    end
  --
  -- Successful return handler.
  --
  Return_Success:
  --
  -- Commit our transaction and return a successful return code.
  --
  IF @Return_Code <> 3 And @MyOwnTrans = 1 COMMIT TRANSACTION
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
  RETURN(@Return_Code)
