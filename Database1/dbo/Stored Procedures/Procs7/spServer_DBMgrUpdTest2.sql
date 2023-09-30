CREATE PROCEDURE dbo.spServer_DBMgrUpdTest2
  @Var_Id   	   int,
  @User_Id       int,
  @Canceled      int,
  @New_Result  	   nVarChar(25),
  @Result_On  	   datetime,
  @TransNum int,  	    	    	  -- NewParam
  @CommentId int,  	    	    	  -- NewParam
  @ArrayId int,  	    	    	    	  -- NewParam
  @EventId int OUTPUT,  	    	  -- NewParam
  @PU_Id  	   int  	        OUTPUT,
  @Test_Id  	   BigInt       OUTPUT,
  @Entry_On 	 datetime 	    OUTPUT,
  @SecondUserId int = NULL, -- NewParam
  @HasHistory 	  int = Null OUTPUT,
  @SignatureId   int = NULL,
  @Locked 	  	  TinyInt = Null
AS 
declare @DsId int
Declare @testValue nVarChar(25)
Declare @DebugFlag Int
 	  	 ,@ID Int
--Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
--Select @DebugFlag = 1 
If @DebugFlag = 1 
BEGIN 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spServer_DBMgrUpdTest2  /VarId: ' + Isnull(convert(nvarchar(10),@Var_Id),'Null') + 
 	 ' /UserId: ' + Isnull(convert(nvarchar(10),@User_Id),'Null') + 
 	 ' /Canceled: ' + Isnull(convert(nvarchar(10),@Canceled),'Null') + 
 	 ' /Result ' + Isnull(convert(nvarchar(10),@New_Result),'Null') + 
 	 ' /ResultOn: ' + Isnull(convert(nVarChar(25),@Result_On,120),'Null') + 
 	 ' /TransNum: ' + Isnull(convert(nvarchar(10),@TransNum),'Null') + 
 	 ' /CommentId: ' + Isnull(convert(nvarchar(10),@CommentId),'Null') + 
 	 ' /ArrayId: ' + Isnull(convert(nvarchar(10),@ArrayId),'Null') + 
 	 ' /EventId: ' + Isnull(convert(nvarchar(10),@EventId),'Null') + 
   	 ' /PUId: ' + Isnull(convert(nvarchar(10),@PU_Id),'Null') + 
 	 ' /TestId: ' + Isnull(convert(nVarChar(20),@Test_Id),'Null') + 
 	 ' /EntryOn: ' + Isnull(convert(nVarChar(25),@Entry_On,120),'Null') +
 	 ' /SecondUserId: ' + Isnull(convert(nvarchar(10),@SecondUserId),'Null') + 
 	 ' /HasHistory: ' + Isnull(convert(nvarchar(10),@HasHistory),'Null') + 
 	 ' /Locked: ' + Isnull(convert(nvarchar(10),@Locked),'Null') + 
 	 ' /SignatureId: ' + Isnull(convert(nvarchar(10),@SignatureId),'Null'))
 END
  -- TransNum
  --   0 = Coalesce all input values with values from database before updating
  --   2 = Update database using only input values to this stored procedure
 	 -- 	  4 = Approve for ProfSDK
 	 -- 	  5 = UnApprove for ProfSDK
  --   1000 = Comment Update
  If @CommentId = 0
    Select @CommentId = Null
  If (@TransNum =1010) -- Transaction From WebUI
 	   SELECT @TransNum = 2
  If @TransNum Not In ( 0,2,4,5,1000)
    Return(3)
  SET @Canceled = Coalesce(@Canceled,0)
  SET @Locked = Coalesce(@Locked,0)
  --
  -- Declare local variables.
  --
  DECLARE @Old_Entry_On 	  	 datetime,
          @Old_Canceled 	  	 bit,
          @Old_Result 	  	 nVarChar(25),
          @Old_User_Id 	  	 int,
          @Target_Test_Id 	 BigInt,
          @New_Canceled 	  	 bit, 
          @EventType 	  	 int, 
          @MasterUnit 	  	 int,
 	  	   @ForceOverride 	 Int,
 	  	   @OrphanDataCheck 	  	 Int,
 	  	   @PEIID 	  	  	 Int,
 	  	   @SubtypeId 	  	 Int,
 	  	   @ValidateTestData 	 Int,
 	  	   @OldLocked 	  	 TinyInt,
 	  	   @EventStatus 	  	 Int,
 	  	   @CurrentEventLocked 	 Int,
 	  	   @VidActive 	  	 Int,
 	  	   @MyOwnTrans 	  	 Int
Declare @Sampling_Interval smallint,@TestFreq int,@ProdId int
 	  	   
SET @HasHistory = 0
SET @CurrentEventLocked = 0
If @@Trancount = 0
  Select @MyOwnTrans = 1
Else
  Select @MyOwnTrans = 0
DECLARE @X nVarChar(25)
  SELECT @X = '[' + LTRIM(@New_Result) + ']'
  IF @X = '[]' SELECT @New_Result = NULL
  Select @New_Result = 
    CASE LTRIM(@New_Result) 
      WHEN NULL THEN NULL 
      WHEN '' THEN NULL 
      ELSE @New_Result END
  SELECT @New_Canceled = CASE @Canceled WHEN 0 THEN 0 ELSE 1 END 
  --
  -- Get our new entry on date/time.
  --
  SELECT @Entry_On = dbo.fnServer_CmnGetDate(getUTCdate())
  --
  -- Find the production unit for this variable.
  -- Return an error if we cannot find it.
  --
  SELECT @PU_Id = NULL, @EventType = NULL, @MasterUnit = NULL
  SELECT @ForceOverride = 0
  SELECT 	 @PU_Id = v.PU_Id, 
 	  	  	 @EventType = v.Event_Type, 
 	  	  	 @MasterUnit = COALESCE( Master_Unit,p.PU_Id),
 	  	  	 @ForceOverride = Case When Event_Dimension Is Null Then 0 Else 1 End,
 	  	  	 @OrphanDataCheck = Perform_Event_Lookup,
 	  	  	 @PEIID = pei_Id,
 	  	  	 @SubtypeId = Event_Subtype_Id,
 	  	  	 @ValidateTestData = ValidateTestData
 	  	  	 ,@DsId = Ds_Id
 	  	  	 ,@Sampling_Interval = Sampling_Interval
    FROM Variables_base v
    JOIN Prod_Units_base p on p.PU_Id = v.PU_Id
    JOIN Event_Types e ON e.ET_Id = v.Event_Type
    WHERE Var_Id = @Var_id
 	 
 	 SELECT @ProdId = Prod_Id FROM Production_Starts WHERE PU_Id = @PU_Id
                                                      AND Start_Time <= @Result_On
                                                      AND (End_Time IS NULL
                                                           OR End_Time > @Result_On)
   	   
 	 Select @TestFreq = Test_Freq from Var_specs where var_Id = @Var_id And Prod_Id = @ProdId   
 	  	  	  	  	  	  	  	  	  	  	  	  AND Effective_Date <= @Result_On
 	  	  	  	  	  	  	  	  	  	  	  	  AND (Expiration_Date IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  OR Expiration_Date > @Result_On)
  IF (@PU_Id = -100 and @EventType not in(31,32)) -- It's a unitless variable (Unitless for segment/work Resonse handled below)
  BEGIN
 	 SELECT @PU_Id = NULL, @MasterUnit = NULL
 	 IF (@EventId is null)
 	  	 Return(3)
 	 IF @EventType In (1,26) /* Production Event */
 	 BEGIN
 	  	 SELECT @PU_Id = a.PU_Id, @MasterUnit = COALESCE(p.Master_Unit,p.PU_Id)
 	  	 FROM Events a
 	     JOIN Prod_Units_base p on p.PU_Id = a.PU_Id
 	  	 WHERE a.Event_Id = @EventId
 	 END
 	 ELSE IF @EventType = 2 /* Downtime Event */
 	 BEGIN
 	  	 SELECT @PU_Id = a.PU_Id, @MasterUnit = COALESCE(p.Master_Unit,p.PU_Id)
 	  	 FROM Timed_Event_Details a
 	     JOIN Prod_Units_base p on p.PU_Id = a.PU_Id
 	  	 WHERE a.TEDet_Id = @EventId
 	 END
 	 ELSE IF @EventType = 3 /* Waste Event */
 	 BEGIN
 	  	 SELECT @PU_Id = a.PU_Id, @MasterUnit = COALESCE(p.Master_Unit,p.PU_Id)
 	  	 FROM Waste_Event_Details a
 	     JOIN Prod_Units_base p on p.PU_Id = a.PU_Id
 	  	 WHERE a.WED_Id = @EventId
 	 END
 	 ELSE IF @EventType in(4,5) /* Product Change */
 	 BEGIN
 	  	 SELECT @PU_Id = a.PU_Id, @MasterUnit = COALESCE(p.Master_Unit,p.PU_Id)
 	  	 FROM Production_Starts a
 	     JOIN Prod_Units_base p on p.PU_Id = a.PU_Id
 	  	 WHERE a.Start_Id = @EventId
 	 END
 	 ELSE IF @EventType = 14 /* UDE  */
 	 BEGIN
 	  	 SELECT @PU_Id = a.PU_Id, @MasterUnit = COALESCE(p.Master_Unit,p.PU_Id)
 	  	 FROM User_Defined_Events a
 	     JOIN Prod_Units_base p on p.PU_Id = a.PU_Id
 	  	 WHERE a.UDE_Id = @EventId
 	 END 
 	 ELSE IF @EventType In (19,28) /* Process Order */
 	 BEGIN
 	  	 SELECT @PU_Id = a.PU_Id, @MasterUnit = COALESCE(p.Master_Unit,p.PU_Id)
 	  	 FROM Production_Plan_Starts a
 	     JOIN Prod_Units_base p on p.PU_Id = a.PU_Id
 	  	 WHERE a.PP_Start_Id = @EventId
 	 END
  END
  IF @PU_Id IS NULL RETURN(1)
  SELECT @ValidateTestData = Coalesce(@ValidateTestData,0)
IF @EventType in(31,32)
BEGIN
    SET @OrphanDataCheck = 0
END
IF @EventType in(31,32) and @EventId Is Null -- EventId Is Requires for segment/work Resonse
BEGIN
     RETURN(3)
END
If @MyOwnTrans = 1 
BEGIN
 	 BEGIN TRANSACTION
END
/* orphaned data check */
IF (@EventId IS NULL or @OrphanDataCheck = 1) and @ValidateTestData = 1
BEGIN
 	 SET @EventId = NULL
 	 IF @EventType In (1,26) /* Production Event */
 	 BEGIN
 	  	 SELECT @EventId = Event_Id 
 	  	 FROM Events 
 	  	 WHERE Timestamp = @Result_On and PU_Id = @MasterUnit
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1 and @EventType <> 26
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END
 	 ELSE IF @EventType = 2 /* Downtime Event */
 	 BEGIN
 	  	 SELECT @EventId = TEDet_Id  
 	  	 FROM Timed_Event_Details  
 	  	 WHERE End_Time  = @Result_On and PU_Id = @MasterUnit
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END
 	 ELSE IF @EventType = 3 /* Waste Event */
 	 BEGIN
 	  	 SELECT @EventId = MIN(WED_Id) 
 	  	 FROM Waste_Event_Details  
 	  	 WHERE Timestamp = @Result_On and PU_Id = @MasterUnit
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END
 	 ELSE IF @EventType in(4,5) /* Product Change */
 	 BEGIN
 	  	 SELECT @EventId = MIN(Start_Id )
 	  	 FROM Production_Starts   
 	  	 WHERE DateAdd(second,-1,End_Time)  = @Result_On and PU_Id = @MasterUnit
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1 and @EventType not in (4,5)
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END
 	 ELSE IF @EventType = 17 /* Genealogy  */
 	 BEGIN
 	  	 SELECT @EventId = MIN(Component_Id  ) 
 	  	 FROM Event_Components    
 	  	 WHERE TimeStamp  = @Result_On and PEI_Id  = @PEIID 
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END  
 	 ELSE IF @EventType = 14 /* UDE  */
 	 BEGIN
 	  	 SELECT @EventId = MIN(a.UDE_Id) 
 	  	 FROM User_Defined_Events a
 	  	 Where a.End_Time  = @Result_On  and a.Event_Subtype_Id = @SubtypeId and PU_Id = @MasterUnit
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END 
 	 ELSE IF @EventType In (19,28) /* Process Order */
 	 BEGIN
 	  	 SELECT @EventId = MIN(a.PP_Start_Id ) 
 	  	  	 FROM Production_Plan_Starts a
 	  	  	 Where a.End_Time  = @Result_On  and a.PU_Id  = @PU_Id 
 	  	 IF @EventId Is NULL and @OrphanDataCheck = 1 and @EventType <> 28
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RETURN(3)
 	  	 END
 	 END
END
IF @EventType In (1,26)
BEGIN
 	 IF @EventId Is Not Null 
 	 BEGIN
 	  	 SELECT @EventStatus = Event_Status FROM Events WHERE Event_Id  = @EventId
 	  	 IF  @EventStatus Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @CurrentEventLocked = COALESCE(a.LockData,0)
 	  	  	  	 FROM Production_Status a
 	  	  	  	 WHERE a.ProdStatus_Id = @EventStatus
 	  	 END
 	 END
END
IF @EventType =  14
BEGIN
 	 IF @EventId Is Not Null
 	 BEGIN
 	  	 SELECT @EventStatus = Event_Status FROM User_Defined_Events WHERE UDE_Id = @EventId
 	  	 IF @EventStatus Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @CurrentEventLocked = COALESCE(a.LockData,0)
 	  	  	  	 FROM Production_Status a
 	  	  	  	 WHERE a.ProdStatus_Id = @EventStatus
 	  	 END
 	 END
END
IF @DebugFlag = 1
BEGIN  
 	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	  	 SELECT @ID, '@EventType:' + Isnull(CONVERT(nvarchar(10),@EventType) ,'Null')
 	  	  	  	 + '@EventStatus:' + Isnull(CONVERT(nvarchar(10),@EventStatus),'Null')
 	  	  	  	 + '@EventId:' + Isnull(CONVERT(nvarchar(10),@EventId),'Null')
 	  	  	  	 
END
IF @CurrentEventLocked = 1
BEGIN
 	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    IF @DebugFlag = 1
    BEGIN  
 	  	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	  	  	 SELECT @ID, 'END:Event Record is Locked' 
    END
 	 RETURN(-200)
END
IF @TransNum = 1000 /* Update Comment*/
BEGIN
 	 IF @Test_Id is Null or @User_Id Is Null -- Check required fields
 	  	  	  	  	  	 RETURN(3)
 	 SET @Target_Test_Id  = NULL
 	 SELECT  @Target_Test_Id = Test_Id,
 	  	  	 @OldLocked = Coalesce(Locked,0)
 	  FROM Tests 
 	  WHERE Test_Id = @Test_Id
 	 IF @Target_Test_Id is Null RETURN(3)-- Not Found
 	 IF @OldLocked = 1
 	 BEGIN 
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 IF @DebugFlag = 1
 	  	 BEGIN  
 	  	  	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	  	  	  	 SELECT @ID, 'END:Record is Locked' 
 	  	 END 	 
 	  	 RETURN(-200)
 	 END
 	 UPDATE Tests SET Comment_id = @CommentId,Entry_On =@Entry_On,Entry_By = @User_Id  
 	  	   WHERE Test_Id = @Test_Id
 	 RETURN(2)
END
-- If  @User_Id not in (14,6) --Only Override Values from Database Manager
-- 	 Select @ForceOverride = 0
  --
  -- Try to find an existing test record for this variable at this time.
  --
  -- NOTE: CommentId Needs to be updated if it did not exist before or was changed.  There is currently
 	 -- 	  	  	  	 no logic to delete a comment - must be done outside of this sp
  DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
  SELECT @Old_Entry_On       = NULL
  SET @OldLocked = 0
  IF @EventType in (31,32)
 	   SELECT @Target_Test_Id     = Test_Id,
 	  	  	  @Old_Entry_On       = Entry_On,
 	  	  	  @Old_Canceled       = Canceled,
 	  	  	  @Old_Result         = Result,
 	  	  	  @Old_User_Id        = Entry_By,
 	  	  	  @OldLocked 	  	  	  = isnull(locked,0),
 	  	  	  @CommentId  	  	  = isNull(@CommentId,Comment_Id)
 	  	  	  ,@testValue = Result
 	  	 FROM Tests
 	  	 WHERE (Var_Id = @Var_Id) and Event_Id = @EventId 
 	 ELSE
  	   SELECT @Target_Test_Id     = Test_Id,
 	  	  	  @Old_Entry_On       = Entry_On,
 	  	  	  @Old_Canceled       = Canceled,
 	  	  	  @Old_Result         = Result,
 	  	  	  @Old_User_Id        = Entry_By,
 	  	  	  @OldLocked 	  	  	  = isnull(locked,0),
 	  	  	  @CommentId  	  	  = isNull(@CommentId,Comment_Id)
 	  	  	  ,@testValue = Result
 	  	 FROM Tests
 	  	 WHERE (Var_Id = @Var_Id) AND (Result_On = @Result_On)
 --
  -- Take action based upon weither we found the test or not.
  --
  IF @Old_Entry_On IS NULL
    BEGIN
      -- 
      -- For now, if the event type is <> 1, null out the event id
      -- If event id not supplied, and event type = 1 then look up the prod event
      IF @ValidateTestData = 0
        SELECT @EventId = NULL
      --ELSE IF @EventId IS NULL 
      --  SELECT @EventId = Event_Id 
      --    FROM Events 
      --    WHERE Timestamp = @Result_On and PU_Id = @MasterUnit
      -- We can't find an existing test record. Add the new test record.
      --
 	   Declare @IsVarMandatory Bit
 	   --It is mandatory if user is stubber only and test freq/samppling interval is set
 	   SELECT @IsVarMandatory = CASE WHEN @User_Id = /*(3,4,5,6,14,26)*/5 AND (@Sampling_Interval > 0 OR @TestFreq > 0) Then 1 Else 0 End
 	   
 	   select @VidActive = is_Active from Variables_Base where Var_Id = @Var_Id
 	   IF @VidActive = 0 AND @DsId In (2,16)
 	   BEGIN
 	  	  If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  RETURN
 	    END 	   
      INSERT Tests(Var_Id, Result_On, Canceled, Result, Entry_On, Entry_By,Comment_Id, Second_User_Id, Event_Id,Array_Id,Signature_Id,Locked,IsVarMandatory)
        VALUES(@Var_Id, @Result_On, @New_Canceled, @New_Result, @Entry_On, @User_Id,@CommentId, @SecondUserId, @EventId,@ArrayId,@SignatureId,@Locked,@IsVarMandatory)
      --
      -- Get the test id. Return an error if we failed to create the test.
      --
      SELECT @Target_Test_Id = NULL
 	   IF @EventType in (31,32)
 	  	   SELECT @Target_Test_Id = Test_Id
 	  	  	 FROM Tests
 	  	  	 WHERE (Var_Id = @Var_Id) AND (Event_Id = @EventId)
 	   ELSE
 	  	   SELECT @Target_Test_Id = Test_Id
 	  	  	 FROM Tests
 	  	  	 WHERE (Var_Id = @Var_Id) AND (Result_On = @Result_On)
      IF @Target_Test_Id IS NULL
      BEGIN
 	  	   If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	   RETURN(2)
      END
      --
    END
  ELSE
    BEGIN
      --
      -- We found an existing test. 
      --
      -- If Update Is Create Test, Return With No Change  
      -- 
      IF (@Test_Id = 0) and (@New_Result IS NULL) and (@User_Id Not In (4,7,8))
      BEGIN
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
        RETURN(3)
      END
 	   IF @OldLocked = 1
 	   BEGIN 
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 IF @DebugFlag = 1
 	  	 BEGIN  
 	  	  	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	  	  	  	 SELECT @ID, 'END:Record is Locked' 
 	  	 END 	 
 	  	 RETURN(-200)
 	   END
     IF (@User_Id = 5)
      BEGIN
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 RETURN(3)
 	   END
      -- 
      -- If This Is A Server User And Current User Is Not A Server User And Old Value Is Not Null, Return With No Change
      --
 	  -- Allow Override if this is a database manager update (14) and the variable type is event dimension)
 	  --
      IF ((@User_Id <= 50) and (@User_Id <> 1)) and ((@Old_User_Id > 50) or (@Old_User_Id = 1)) and (@Old_Result Is Not Null) and (@ForceOverride = 0)
      BEGIN
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 RETURN(3)   
      END
      --
      --
      -- If Result Did Not Change Then Return With No Change
      -- 
 	 IF (@TransNum <> 4) and (@TransNum <> 5)
 	 BEGIN
   	  	 IF (((@Old_Result = @New_Result) or ((@Old_Result is Null) and (@New_Result is Null))) and (@Old_User_Id = @User_Id)) and (@Old_Canceled = @New_Canceled)
   	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
   	  	  	 SELECT @Test_Id = @Target_Test_Id
   	  	  	 RETURN(3)
   	  	 END
 	 END
      --
      -- Start a new transaction.
      --    
      --
      -- 8/22/02 - Joe - Old AutoLog client will always send a 0 so can't ever delete a test (i.e. Result is NULL)
      --   also existing Test resultsets will be sending 0 for trans num. 
      --
      -- Update the test record.
      --
      If @TransNum = 0
        Begin
           Select @SignatureId = Coalesce(@SignatureId,Signature_Id)
           From Tests
           Where (Test_Id = @Target_Test_Id)
        End
 	 If @Old_User_Id <> 5 SET @HasHistory = 1
 	 If @HasHistory = 0 and EXISTS(Select 1 from Test_History where test_id = @Target_Test_Id and Entry_By <> 5)
 	  	 SET @HasHistory = 1
      -- NOTE: EventId cannot be updated because we can't think of a situation where you would want to do this. 
      -- NOTE: CommentId Needs to be updated if it did not exist before or was changed.  There is currently
 	  	  	 -- 	  	  	  	 no logic to delete a comment - must be done outside of this sp
 	 IF @EventType in (31,32)
      UPDATE Tests
        SET Canceled       = @New_Canceled,
            Entry_On       = @Entry_On,
            Result         = @New_Result,
            Entry_By       = @User_Id,
            Second_User_Id = @SecondUserId,
 	  	  	 Array_Id 	    = @ArrayId,
 	  	  	 Comment_Id 	    = @CommentId,
            Signature_Id   = @SignatureId,
 	  	  	 Result_On = @Result_On,
 	  	  	 Locked = @Locked
        WHERE Test_Id = @Target_Test_Id
 	 ELSE
      UPDATE Tests
        SET Canceled       = @New_Canceled,
            Entry_On       = @Entry_On,
            Result         = @New_Result,
            Entry_By       = @User_Id,
            Second_User_Id = @SecondUserId,
 	  	  	 Array_Id 	    = @ArrayId,
 	  	  	 Comment_Id 	    = @CommentId,
            Signature_Id   = @SignatureId,
  	  	  	 Locked = @Locked
       WHERE Test_Id = @Target_Test_Id
      --
      -- Commit our transaction.
      --
 	 END
  --
  --
  -- Fill in remaining output variables.
  --
  SELECT @Test_Id = @Target_Test_Id
  --
  -- if @New_Result IS NOT NULL --And @DsId = 2 --Commenting this part as we are allowing user to edit other types of variables
  -- Begin
 	 EXEC spServer_DBMgrUpdActivitiesForTest @Test_Id
  -- End
  -- Return success.
  --
  If @MyOwnTrans = 1 COMMIT TRANSACTION
 	 IF @DebugFlag = 1
 	 BEGIN  
 	  	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	  	  	 SELECT @ID, 'END:Update Test' 
    END
 RETURN(0)
