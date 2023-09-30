CREATE PROCEDURE dbo.spServer_DBMgrUpdActivities 
 	 @ActivityId 	  	    Int,
 	 @ActivityDesc 	  	    nVarChar(1000),
 	 @ActivityPriority 	    Int,
 	 @CommentId 	  	    Int,
 	 @Status 	  	  	    Int,
 	 @SheetId 	  	  	    Int,
 	 @StartTime 	  	    Datetime,
 	 @EndTime 	  	  	    Datetime,
 	 @ActivityTypeId 	    Int,
 	 @KeyIdInt 	  	  	    Int,
 	 @KeyIdDateTime 	  	    DateTime,  -- DateTime of event
 	 @Tag 	  	  	  	    VarChar(7000),
 	 @TDuration 	  	    Int,
 	 @Title 	  	  	    nVarChar(255),
 	 @PercentComplete 	    Float,
 	 @TransType 	  	    Int,
 	 @TransNum 	  	  	    Int, 
 	 @UserId 	  	  	    Int,
 	 @PUId 	  	  	    Int,
 	 @EntryOn 	  	  	    DateTime,
 	 @AutoComplete 	  	    Int,
 	 @ExecutionStartTime 	    DateTime,
 	 @ExtendedInfo 	  	    nVarChar(255),
 	 @ExternalLink 	  	    nVarChar(255),
 	 @TestsToComplete 	    Int,
 	 @Locked 	  	  	    TinyInt,
 	 @OverdueCommentId 	    Int,
 	 @SkipCommentId 	  	    Int,
 	 @ReturnResultSet 	    Int = 0,
 	 @EventSubTypeId 	    Int = NULL,
 	 @CompleteType 	  	    Int = NULL
AS 
/* ##### spServer_DBMgrUpdActivities #####
Description 	 : Updates Activity table with the values passed on for.
Creation Date 	 : NA
Created By 	 : NA
#### Update History ####
DATE 	  	  	  Modified By 	  	 UserStory/Defect No 	  	 Comments 	 
---- 	  	  	  ----------- 	  	 ------------------- 	  	 --------
2018/02/08 	  Prasad 	  	  	  	  	  	  	  	 Used Alias column while updating the sheet name/title name
2018/05/17 	  Krishna 	  	  	  US255748 	  	  	  	 Added activity auto complete previous activities
2018/05/18 	  Krishna 	  	  	  US255660 	  	  	  	 Added privilage to delete comments when comment id is -1
2018/05/25 	  Santhosh 	  	  	  DE76053 	  	  	  	 Added SheetId in condition to check for duplicates.
2018/05/30 	  Krishna 	  	  	  US259476 	  	  	  	 System complete activities implementation
2018/06/11 	  Krishna 	  	  	  US264401 	  	  	  	 Filling new Complete_Type column with necessary value
2019/04/19 	  Prasad 	  	  	  	  DE107516 	  	  	  	 for autocompletion put logic ISNULL(@TotalVariables,0) > 0
2019/05/19 	  Prasad 	  	  	  	  	  	  	  	  	 System completion is overwriting even after auto completion is done.
*/
DECLARE 
 	  	 @Id 	  	  	 Int,
 	  	 @DebugFlag 	 Int,
 	  	 @MyOwnTrans Int,
 	  	 @HasActivities 	 Int,
 	  	 @UseTitles Int,
 	  	 @CanLockActivity Int, 	  	 
 	  	 @NeedOverdueComment Int,
 	  	 @TargetDuration Int, 	  	 
 	  	 @ExecutionStartInMins Int,
 	  	 @Priority 	  	 Int,
 	  	 @End 	 Int, 
 	  	 @Start 	 Int,
 	  	 @Sheet_Desc nVarChar(255),
 	  	 @TotalVariables Int,
 	  	 @TotalCompletedVariables Int,
 	  	 @HasAvailableCells BIT,
 	  	 @Execution_Start_Time DateTime,
 	  	 @System_Complete_Duration_Time DateTime,
 	  	 @DisplayActivityTypeId INT
 	  	 ,@Activity_Alias nVarChar(100)--<Changes: Added Activity Alias Prasad>
DECLARE @LocalSheetId Int,
 	  	 @SheetDesc nVarChar(255),
 	  	 @SheetTitle 	 nVarChar(255),
 	  	 @AutoStart 	 int,
  	    	  @EventDesc nVarChar(1000),
 	  	 @NewActivityDesc nVarChar(255)
DECLARE @ActivityLoopStart Int
DECLARE @ActivityLoopEnd Int
DECLARE @SystemCompleteDuration INT
DECLARE  @NewActivities TABLE(Id Int Identity(1,1),ActivityId int, ActivityDesc nvarchar(1000),APriority Int,AStatus Int,PUId Int,
 	  	  	  	  	  	  	   TDuration Int,Title nvarchar(255),PercentComplete Float, TestsToComplete Int,SheetId Int,UsesTitle Int,AutoStart Int,AutoComplete Int, LockActivity Int, 
 	  	  	  	  	  	  	   ExecutionStartInMins Int, NeedOverdueComment Int,DisplayActivityTypeId INT)
DECLARE  @DeletedIds TABLE(Id Int Identity (1,1), ActivityId int, KeyId int, StartTime DateTime, ActivityType Int,PUId Int)
DECLARE  @variableCounts TABLE( numVariables Int, numComplete Int, hasAvailableCells BIT)
DECLARE  @ActivityIds TABLE (ActivityId int, KeyId int, KeyTime DateTime, StartTime DateTime, ActivityType Int,PUId Int)
DECLARE  @SheetTitles Table(Id Int Identity (1,1), UseTitle Int,SheetId Int,SheetDesc nVarChar(255),AutoStart Int,AutoComplete Int, LockActivity Int, 
 	  	  	  	  	  	  	 ExecutionStartInMins Int, NeedOverdueComment Int, ActivityAlias nVarChar(100),DisplayActivityTypeId INT)--<Changes: Added Activity Alias Prasad>
SET @ReturnResultSet = Coalesce(@ReturnResultSet,0)
SET @DebugFlag = 0
IF @DebugFlag = 1 
BEGIN 
 	 INSERT INTO Message_Log_Header (Timestamp) SELECT dbo.fnServer_CmnGetDate(getUTCdate()) 
 	 SELECT @ID = Scope_Identity() 
 	 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
 	 INSERT INTO Message_Log_Detail (Message_Log_Id, Message)
 	   Values(@ID, 'in spServer_DBMgrUpdActivities /TransNum: ' + Coalesce(convert(nvarchar(10),@TransNum),'Null') + 
 	  	  	  	  	  '  /TransType:' + Isnull(convert(nvarchar(25),@TransType),'Null') +
 	  	  	  	  	  '  /EndTime:' + Isnull(convert(nvarchar(25),@EndTime,120),'Null') +
 	  	  	  	  	  '  /KeyIdInt:' + Isnull(convert(nvarchar(25),@KeyIdInt),'Null') +
 	  	  	  	  	  '  /KeyIdDateTime:' + Isnull(convert(nvarchar(25),@KeyIdDateTime,120),'Null') +
 	  	  	  	  	  '  /PUId:' + Isnull(convert(nvarchar(25),@PUId),'Null') +
 	  	  	  	  	  '  /ActivityId:' + Isnull(convert(nvarchar(25),@ActivityId),'Null') +
 	  	  	  	  	  '  /EventSubTypeId:' + Isnull(convert(nvarchar(25),@EventSubTypeId),'Null') +
 	  	  	  	  	  '  /ActivityTypeId:' +Isnull(convert(nvarchar(25),@ActivityTypeId),'Null') +
 	  	  	  	  	  '  /SheetId:' +Isnull(convert(nvarchar(25),@SheetId),'Null'))
END
/* Required Fields */
IF @UserId IS Null SET @UserId  = 1
/* End of Required Fields */
IF @SheetId is not null
BEGIN
     SELECT @DisplayActivityTypeId  = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 461
 	 SELECT @HasActivities = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 444
 	 SELECT @HasActivities = Coalesce(@HasActivities,0)
 	 IF @HasActivities = 0 RETURN(4)
END
SELECT @DisplayActivityTypeId = Coalesce(@DisplayActivityTypeId,0)
IF @EntryOn IS NULL
BEGIN
 	 SELECT  @EntryOn = dbo.fnServer_CmnGetDate(GetUTCDate()) 
END
IF @TransNum  Not IN (0,1,3) or @TransNum Is Null
BEGIN
  IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Bad Trans Num: Return(-100)' )
 	 Return(-100)
END
IF @TransType  Not IN (1,2,3) or @TransType Is Null
BEGIN
  IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Bad TransType: Return(-100)' )
 	 Return(-100)
END 
IF @ActivityTypeId  Not IN (1,2,3,4,5,7,8) or @ActivityTypeId Is Null
BEGIN
  IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Bad Activity Type Id: Return(-100)' )
 	 Return(-100)
END 
IF NOT EXISTS(SELECT  1 FROM Sheet_Variables WHERE Sheet_Id = @SheetId and Title_Var_Order_Id IS NOT NULL) and @SheetId is not null AND @DisplayActivityTypeId <> 1
BEGIN
    IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Variable: Return(-200)' )
    Return(-200)
END
IF @@Trancount = 0
 	 SELECT @MyOwnTrans = 1
ELSE
 	 SELECT @MyOwnTrans = 0
 	 
IF @TransType = 1 -- For Addition of a New Activity
BEGIN
 	 IF EXISTS(SELECT 1 FROM Activities WHERE KeyId = @KeyIdDateTime
                                         AND KeyId1 = @KeyIdInt
                                         AND Activity_Type_Id = @ActivityTypeId
 	  	  	  	  	  	  	  	  	  	  AND Sheet_Id = @SheetId)
    BEGIN
        IF @DebugFlag = 1
            BEGIN
                INSERT INTO Message_Log_Detail( Message_Log_Id,
                                                Message )
                VALUES(@ID, 'Activities Already Exist at current time')
            END
        RETURN(-200)
    END
 	 IF @ActivityTypeId = 1 -- Sheet Column (Time based Activity)
 	 BEGIN
 	  	 IF NOT EXISTS(SELECT 1 FROM sheets Where Sheet_Id = @KeyIdInt)
 	  	 BEGIN
 	  	   IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Sheet: Return(-200)' )
 	       Return(-200)
 	  	 END
 	  	 SELECT @PUId = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 446
 	  	 IF @PUId Is Null
 	  	 BEGIN
 	  	   IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Unit: Return(-200)' )
 	       Return(-200)
 	  	 END
 	  	 SELECT @UseTitles = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 445
 	  	 SELECT @UseTitles = Coalesce(@UseTitles,0)
 	  	 SELECT @AutoStart  = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 451
 	  	 SELECT @AutoStart = Coalesce(@AutoStart,0)
 	  	 SELECT @AutoComplete  = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 452
 	  	 SELECT @AutoComplete = Coalesce(@AutoComplete,0)
 	  	 SELECT @CanLockActivity  = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 455
 	  	 SELECT @CanLockActivity = Coalesce(@CanLockActivity,1)
 	  	 SELECT @ExecutionStartInMins = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 450
 	  	 SELECT @ExecutionStartInMins = Coalesce(@ExecutionStartInMins,0)
 	  	 SELECT @NeedOverdueComment  = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 453
 	  	 SELECT @NeedOverdueComment = Coalesce(@NeedOverdueComment,0)
 	  	 --<Changes: Added Activity Alias Prasad>
 	  	 SELECT @Activity_Alias  = Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 457
 	  	 --SELECT @Activity_Alias = Coalesce(@Activity_Alias,'') 	 
 	  	 --</Changes: Added Activity Alias Prasad>
 	  	 IF NOT EXISTS(SELECT  1 FROM Sheet_Variables WHERE Sheet_Id = @SheetId) AND @DisplayActivityTypeId <> 1
 	  	 BEGIN
 	  	  	 IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Variable: Return(-200)' )
 	  	  	 Return(-200)
 	  	 END
 	  	   --<Changes: Added activity auto complete @Krishna>
 	  	   EXEC spServer_DBMgrAutoCompleteActivities @PUId, @SheetId, @ActivityTypeId, @KeyIdDateTime
 	  	   --<Changes: Added activity auto complete @Krishna>
 	  	 IF @UseTitles = 1 --Use the Activity Aliases or the tiltle specified at sheet_Variables level else use the sheet description
 	  	 BEGIN
 	  	  	 ;WITH CTE_Sheets AS (SELECT Sheet_Id, Sheet_Desc FROM Sheets Where Sheet_Id = @SheetId)
 	  	  	 ,CTE_SheetVariables_Min AS (SELECT MIN(ISNULL(Activity_Order,0)) Min_Activity_Order FROM Sheet_Variables SV1 where Var_Id IS NULL AND EXISTS(SELECT 1 FROM CTE_Sheets Where SV1.Sheet_Id = Sheet_Id))
 	  	  	 ,CTE_SheetVariables_SUM AS (SELECT SUM(ISNULL(Activity_Order,0)) Sum_Activity_Order FROM Sheet_Variables SV1 where Var_Id IS NULL AND EXISTS(SELECT 1 FROM CTE_Sheets Where SV1.Sheet_Id = Sheet_Id))
 	  	  	 INSERT INTO @NewActivities(ActivityDesc,APriority,AStatus,PUId,TDuration,
 	  	  	  	  	  	  	  	  	  	 Title,SheetId,UsesTitle,AutoStart,AutoComplete,LockActivity,ExecutionStartInMins,NeedOverdueComment,DisplayActivityTypeId)
 	  	  	  	 SELECT  '[' +  
 	  	  	  	 --ISNULL(a.Activity_Alias,b.Sheet_Desc)  
 	  	  	  	 CASE WHEN ISNULL(SV.Activity_Alias,'') <> '' THEN SV.Activity_Alias ELSE CASE WHEN ISNULL(SV.Title,'') <> ''  THEN SV.Title ELSE  S.Sheet_Desc END END
 	  	  	  	 + ']',Coalesce(Activity_Order,1),
 	  	  	  	 --US434132 changes
 	  	  	  	 CASE WHEN (SELECT Sum_Activity_Order FROM CTE_SheetVariables_SUM) = 0 THEN 1 ELSE Case when (ISNULL(activity_order,0) = (SELECT Min_Activity_Order From CTE_SheetVariables_Min)) AND (SELECT Sum_Activity_Order FROM CTE_SheetVariables_SUM) > 0  then 1 else 6 END END
 	  	  	  	 ,@PUId ,Coalesce(Target_Duration,0),--<Changes: Added Activity Alias Prasad>
 	  	  	  	  	  	 SV.Title, @SheetId,@UseTitles,@AutoStart,@AutoComplete, @CanLockActivity, @ExecutionStartInMins, @NeedOverdueComment,@DisplayActivityTypeId
 	  	  	  	 FROM CTE_Sheets S
 	  	  	  	 LEFT JOIN Sheet_Variables SV on SV.Sheet_Id = S.Sheet_Id
 	  	  	  	 WHERE 
 	  	  	  	 (SV.Sheet_Id IS NOT NULL AND (SV.Title Is Not Null OR (SV.Title Is NULL AND SV.Title_Var_Order_Id = 0)))
 	  	  	  	 OR (SV.Sheet_Id IS NULL AND @DisplayActivityTypeId = 1)
 	  	 END
 	  	 ELSE -- Use the  Activity Alias  at sheet level if present else use sheet description
 	  	 BEGIN
 	  	  	 SELECT @Priority =  Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 447
 	  	  	 SELECT @Priority = coalesce(@Priority,1)
 	  	  	 SELECT @TargetDuration =  Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 448
 	  	  	 SELECT @TargetDuration = Coalesce(@TargetDuration,0)
 	  	  	 ;WITH CTE_Sheets AS (SELECT Sheet_Id, Sheet_Desc FROM Sheets Where Sheet_Id = @SheetId)
 	  	  	 INSERT INTO @NewActivities(ActivityDesc,APriority,AStatus,PUId,TDuration,SheetId,UsesTitle,AutoStart,AutoComplete,LockActivity, ExecutionStartInMins,NeedOverdueComment,DisplayActivityTypeId)
 	  	  	  	 SELECT  '[' +  
 	  	  	  	 --ISNULL(@Activity_Alias,b.Sheet_Desc) 
 	  	  	  	 CASE WHEN ISNULL(@Activity_Alias,'') <> '' THEN SUBSTRING(@Activity_Alias,1,98) -- Taking substring so that ActiityDesc does't overflow
 	  	  	  	  	  	 ELSE b.Sheet_Desc END
 	  	  	  	 + ']',@Priority,1,@PUId,@TargetDuration,@SheetId,@UseTitles,@AutoStart,@AutoComplete,@CanLockActivity, @ExecutionStartInMins, @NeedOverdueComment, @DisplayActivityTypeId--<Changes: Added Activity Alias Prasad>
 	  	  	  	 FROM CTE_Sheets b 
 	  	  	  	 WHERE EXISTS (Select 1 From Sheet_Variables Where Sheet_Id = @SheetId) OR @DisplayActivityTypeId = 1
 	  	 END
 	 END
  	  ELSE IF @ActivityTypeId IN ( 2,3,4,5,7,8) --Production Event
 	 BEGIN
 	  	 IF @ActivityTypeId = 2
 	  	 BEGIN
 	  	  	 IF NOT EXISTS(SELECT 1 FROM Events Where Event_Id = @KeyIdInt)
 	  	  	 BEGIN
 	  	  	   IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Event: Return(-200)' )
 	  	  	   Return(-200)
 	  	  	 END
 	  	  	 INSERT INTO @SheetTitles(SheetId,UseTitle,SheetDesc,AutoStart,AutoComplete,LockActivity,ExecutionStartInMins,NeedOverdueComment, ActivityAlias,DisplayActivityTypeId)
 	  	  	  	 SELECT a.Sheet_Id,Convert(Int,coalesce(c.Value,0)),a.Sheet_Desc,Convert(Int,coalesce(d.Value,0)),Convert(Int,coalesce(e.Value,0)),Convert(Int,coalesce(f.Value,1)),
 	  	  	  	        Convert(Int,coalesce(g.Value,0)), Convert(Int,coalesce(h.Value,0)), CASE WHEN i.Value = null THEN null ELSE SUBSTRING(i.Value,1,100) END, Convert(Int,coalesce(j.Value,0))
 	  	  	  	  	 FROM Sheets a
 	  	  	  	  	 Join Sheet_Display_Options b ON  b.Sheet_Id = a.Sheet_Id  And b.Display_Option_Id = 444 and b.Value = '1' 
 	  	  	  	  	 Left Join Sheet_Display_Options c ON  c.Sheet_Id = a.Sheet_Id  And c.Display_Option_Id = 445
 	  	  	  	  	 Left Join Sheet_Display_Options d ON  d.Sheet_Id = a.Sheet_Id  And d.Display_Option_Id = 451
 	  	  	  	  	 Left Join Sheet_Display_Options e ON  e.Sheet_Id = a.Sheet_Id  And e.Display_Option_Id = 452
 	  	  	  	  	 Left Join Sheet_Display_Options f ON  f.Sheet_Id = a.Sheet_Id  And f.Display_Option_Id = 455
 	  	  	  	  	 Left Join Sheet_Display_Options g ON  g.Sheet_Id = a.Sheet_Id  And g.Display_Option_Id = 450 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
 	  	  	  	  	 Left Join Sheet_Display_Options h ON  h.Sheet_Id = a.Sheet_Id  And h.Display_Option_Id = 453
 	  	  	  	  	 Left Join Sheet_Display_Options i ON  i.Sheet_Id = a.Sheet_Id  And i.Display_Option_Id = 457
 	  	  	  	  	 Left Join Sheet_Display_Options j ON  j.Sheet_Id = a.Sheet_Id  And j.Display_Option_Id = 461
 	  	  	  	  	 WHERE  Master_Unit = @PUId and a.Sheet_Type = 2 And a.Is_Active = 1
 	  	  	 SELECT @EventDesc = coalesce(Lot_Identifier, Event_Num) 
 	  	  	  	 FROM [Events] e
 	  	  	  	 WHERE  e.Event_Id = @KeyIdInt
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	  IF @ActivityTypeId = 4
 	  	  	  Begin
 	  	  	  	  IF NOT EXISTS (Select 1 From Sheet_Columns Where Result_On = @KeyIdDateTime And Sheet_Id = @SheetId ) 
 	  	  	  	  BEGIN
 	  	  	  	  	 IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Production Change Event: Return(-200)' )
  	    	    	  	  	 Return(-200)
 	  	  	  	  END
 	  	  	  End
 	  	  	  ELse IF @ActivityTypeId = 5
 	  	  	  BEGIN
 	  	  	  	 IF NOT EXISTS (Select 1 From Sheet_Columns Where Result_On = @KeyIdDateTime And Sheet_Id = @SheetId ) 
 	  	  	  	  BEGIN
 	  	  	  	  	 IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Process Order: Return(-200)' )
  	    	    	  	  	 Return(-200)
 	  	  	  	  END
 	  	  	  END
 	  	  	  ELse IF @ActivityTypeId = 7
 	  	  	  BEGIN
 	  	  	  	 IF NOT EXISTS (Select 1 From Sheet_Columns Where Result_On = @KeyIdDateTime And Sheet_Id = @SheetId ) 
 	  	  	  	  BEGIN
 	  	  	  	  	 IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Product Time: Return(-200)' )
  	    	    	  	  	 Return(-200)
 	  	  	  	  END
 	  	  	  END
 	  	  	   ELse IF @ActivityTypeId = 8
 	  	  	  BEGIN
 	  	  	  	 IF NOT EXISTS (Select 1 From Sheet_Columns Where Result_On = @KeyIdDateTime And Sheet_Id = @SheetId ) 
 	  	  	  	  BEGIN
 	  	  	  	  	 IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Process Order Time: Return(-200)' )
  	    	    	  	  	 Return(-200)
 	  	  	  	  END
 	  	  	  END
 	  	  	  ELSE
 	  	  	  Begin
 	  	  	  	  IF NOT EXISTS(SELECT 1 FROM User_Defined_Events a Where a.UDE_Id  = @KeyIdInt)
  	    	    	  	  BEGIN
  	    	    	  	    IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No User Defined Events: Return(-200)' )
  	    	    	  	    Return(-200)
  	    	    	  	  END
 	  	  	  End
 	  	  	  INSERT INTO @SheetTitles(SheetId,UseTitle,SheetDesc,AutoStart,AutoComplete,LockActivity,ExecutionStartInMins,NeedOverdueComment, ActivityAlias, DisplayActivityTypeId)
  	    	    	    	  SELECT a.Sheet_Id,Convert(Int,coalesce(c.Value,0)),a.Sheet_Desc,Convert(Int,coalesce(d.Value,0)),Convert(Int,coalesce(e.Value,0)),Convert(Int,coalesce(f.Value,1)),
  	    	    	    	      Convert(Int,coalesce(g.Value,0)), Convert(Int,coalesce(h.Value,0)), CASE WHEN i.Value = null THEN null ELSE SUBSTRING(i.Value,1,100) END, Convert(Int,coalesce(j.Value,0))
  	    	    	    	    	  FROM Sheets a
  	    	    	    	    	  Join Sheet_Display_Options b ON  b.Sheet_Id = a.Sheet_Id  And b.Display_Option_Id = 444 and b.Value = '1' 
  	    	    	    	    	  Left Join Sheet_Display_Options c ON  c.Sheet_Id = a.Sheet_Id  And c.Display_Option_Id = 445
  	    	    	    	    	  Left Join Sheet_Display_Options d ON  d.Sheet_Id = a.Sheet_Id  And d.Display_Option_Id = 451
  	    	    	    	    	  Left Join Sheet_Display_Options e ON  e.Sheet_Id = a.Sheet_Id  And e.Display_Option_Id = 452
  	    	    	    	    	  Left Join Sheet_Display_Options f ON  f.Sheet_Id = a.Sheet_Id  And f.Display_Option_Id = 455
  	    	    	    	    	  Left Join Sheet_Display_Options g ON  g.Sheet_Id = a.Sheet_Id  And g.Display_Option_Id = 450  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  
  	    	    	    	    	  Left Join Sheet_Display_Options h ON  h.Sheet_Id = a.Sheet_Id  And h.Display_Option_Id = 453
  	    	    	    	    	  Left Join Sheet_Display_Options i ON  i.Sheet_Id = a.Sheet_Id  And i.Display_Option_Id = 457
  	    	    	    	    	  Left Join Sheet_Display_Options j ON  j.Sheet_Id = a.Sheet_Id  And j.Display_Option_Id = 461
  	    	    	    	    	  WHERE  
 	  	  	  	  	  	 a.Sheet_Id = @SheetId And a.Is_Active = 1 and 
 	  	  	  	  	  	 (
 	  	  	  	  	  	  	 (a.Sheet_Type = 23 anD @ActivityTypeId = 4) 
 	  	  	  	  	  	  	 OR 
 	  	  	  	  	  	  	 (a.Sheet_Type = 21 anD @ActivityTypeId = 5)
 	  	  	  	  	  	  	 OR
 	  	  	  	  	  	  	 (a.Sheet_Type = 16 anD @ActivityTypeId = 7)
 	  	  	  	  	  	  	 OR
 	  	  	  	  	  	  	 (a.Sheet_Type = 22 anD @ActivityTypeId = 8)
 	  	  	  	  	  	 )
 	  	  	 
  	    	    	  INSERT INTO @SheetTitles(SheetId,UseTitle,SheetDesc,AutoStart,AutoComplete,LockActivity,ExecutionStartInMins,NeedOverdueComment, ActivityAlias, DisplayActivityTypeId)
  	    	    	    	  SELECT a.Sheet_Id,Convert(Int,coalesce(c.Value,0)),a.Sheet_Desc,Convert(Int,coalesce(d.Value,0)),Convert(Int,coalesce(e.Value,0)),Convert(Int,coalesce(f.Value,1)),
  	    	    	    	      Convert(Int,coalesce(g.Value,0)), Convert(Int,coalesce(h.Value,0)), CASE WHEN i.Value = null THEN null ELSE SUBSTRING(i.Value,1,100) END, Convert(Int,coalesce(j.Value,0))
  	    	    	    	    	  FROM Sheets a
  	    	    	    	    	  Join Sheet_Display_Options b ON  b.Sheet_Id = a.Sheet_Id  And b.Display_Option_Id = 444 and b.Value = '1' 
  	    	    	    	    	  Left Join Sheet_Display_Options c ON  c.Sheet_Id = a.Sheet_Id  And c.Display_Option_Id = 445
  	    	    	    	    	  Left Join Sheet_Display_Options d ON  d.Sheet_Id = a.Sheet_Id  And d.Display_Option_Id = 451
  	    	    	    	    	  Left Join Sheet_Display_Options e ON  e.Sheet_Id = a.Sheet_Id  And e.Display_Option_Id = 452
  	    	    	    	    	  Left Join Sheet_Display_Options f ON  f.Sheet_Id = a.Sheet_Id  And f.Display_Option_Id = 455
  	    	    	    	    	  Left Join Sheet_Display_Options g ON  g.Sheet_Id = a.Sheet_Id  And g.Display_Option_Id = 450  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  
  	    	    	    	    	  Left Join Sheet_Display_Options h ON  h.Sheet_Id = a.Sheet_Id  And h.Display_Option_Id = 453
  	    	    	    	    	  Left Join Sheet_Display_Options i ON  i.Sheet_Id = a.Sheet_Id  And i.Display_Option_Id = 457
  	    	    	    	    	  Left Join Sheet_Display_Options j ON  j.Sheet_Id = a.Sheet_Id  And j.Display_Option_Id = 461
  	    	    	    	    	  WHERE  
 	  	  	  	  	  	 Master_Unit = @PUId and a.Sheet_Type = 25 and a.Event_Subtype_Id = @EventSubTypeId 
  	    	    	    	    	  And a.Is_Active = 1 anD @ActivityTypeId <> 4
 	  	  	 SELECT @EventDesc = coalesce(Friendly_Desc, UDE_Desc) 
 	  	  	  	 FROM User_Defined_Events e
 	  	  	  	 WHERE  e.UDE_Id  = @KeyIdInt
 	  	  	 SELECT @EventDesc = '' Where @ActivityTypeId in( 4,5) 
 	  	 END
 	  	 --If no Sheet is setup to Create Activities, return
 	  	 IF NOT EXISTS (Select * from @SheetTitles)
 	  	 BEGIN
 	  	  	 RETURN(4)
 	  	 END
 	  	 
                DECLARE @ActivityDescPreFixLenth INT = 995-LEN(ISNULL(@EventDesc,'')) --Length of first part of ActivityDesc, 1000 - lengthOf EventDesc(max 50) -5 (length of spl chars '[ - ]')
 	  	 SET @Start = 1
 	  	 SELECT @End = Max(Id) From @SheetTitles 
 	  	 WHILE @Start <= @End
 	  	 BEGIN
 	  	  	 SELECT  @SheetId = SheetId,
 	  	  	  	  	  	  @UseTitles = UseTitle,
 	  	  	  	  	  	  @Sheet_Desc = SheetDesc,
 	  	  	  	  	  	  @AutoStart = AutoStart,
 	  	  	  	  	  	  @AutoComplete = AutoComplete,
 	  	  	  	  	  	  @CanLockActivity = LockActivity,
 	  	  	  	  	  	  @ExecutionStartInMins = ExecutionStartInMins,
 	  	  	  	  	  	  @NeedOverdueComment = NeedOverdueComment,
 	  	  	  	  	  	  @Activity_Alias = ActivityAlias,--<Changes: Added Activity Alias Prasad>
 	  	  	  	  	  	  @DisplayActivityTypeId = DisplayActivityTypeId
 	  	  	 FROM @SheetTitles 
 	  	  	 WHERE Id = @Start
 	  	  	 
 	  	  	  --<Changes: Added activity auto complete @Krishna>
 	  	  	  EXEC spServer_DBMgrAutoCompleteActivities @PUId, @SheetId, @ActivityTypeId, @KeyIdDateTime
 	  	  	  --<Changes: Added activity auto complete @Krishna>
 	  	  	 IF @UseTitles = 1
 	  	  	 BEGIN
 	  	  	 WITH CTE_Sheets AS (SELECT Sheet_Id, Sheet_Desc FROM Sheets Where Sheet_Id = @SheetId)
 	  	  	 ,CTE_SheetVariables_Min AS (SELECT MIN(ISNULL(Activity_Order,0)) Min_Activity_Order FROM Sheet_Variables SV1 where Var_Id IS NULL AND EXISTS(SELECT 1 FROM CTE_Sheets Where SV1.Sheet_Id = Sheet_Id))
 	  	  	 ,CTE_SheetVariables_SUM AS (SELECT SUM(ISNULL(Activity_Order,0)) Sum_Activity_Order FROM Sheet_Variables SV1 where Var_Id IS NULL AND EXISTS(SELECT 1 FROM CTE_Sheets Where SV1.Sheet_Id = Sheet_Id))
 	  	  	  	 INSERT INTO @NewActivities(ActivityDesc,APriority,AStatus,PUId,TDuration,Title,SheetId,UsesTitle,AutoStart,AutoComplete,LockActivity,ExecutionStartInMins,NeedOverdueComment,DisplayActivityTypeId)
 	  	  	  	  	 SELECT  
 	  	  	  	  	 --'[' + ISNULL(isnull(sv.Activity_Alias,sv.Title),@Sheet_Desc) + ' - ' + @EventDesc  + ']',
 	  	  	  	  	 '[' + 
 	  	  	  	  	  	 case when isnull(sv.Activity_Alias,'') <>'' then sv.Activity_Alias -- max length will be 20 
 	  	  	  	  	  	  	 else CASE WHEN ISNULL(sv.Title ,'') <> '' THEN SUBSTRING(sv.Title, 1, @ActivityDescPreFixLenth) -- sv.Title length can grow to 50
 	  	  	  	  	  	  	  	  	   ELSE SUBSTRING(@Sheet_Desc, 1, @ActivityDescPreFixLenth) --@SheetDesc can have till 50 chars 
 	  	  	  	  	  	  	  	  	   END END + 
 	  	  	  	  	 Case when @ActivityTypeId in (4,5) Then '' ELSE 	 ' - ' END
 	  	  	  	  	  + @EventDesc  + ']',
 	  	  	  	  	 
 	  	  	  	  	 Coalesce(Activity_Order,1),CASE WHEN (SELECT Sum_Activity_Order FROM CTE_SheetVariables_SUM) = 0 THEN 1 ELSE Case when (ISNULL(activity_order,0) = (SELECT Min_Activity_Order From CTE_SheetVariables_Min)) AND (SELECT Sum_Activity_Order FROM CTE_SheetVariables_SUM) > 0  then 1 else 6 END END,@PUId,--<Changes: Added Activity Alias Prasad>
 	  	  	  	  	  	 Coalesce(Target_Duration,0),sv.Title,@SheetId,@UseTitles,@AutoStart,@AutoComplete,@CanLockActivity, @ExecutionStartInMins, @NeedOverdueComment, @DisplayActivityTypeId
 	  	  	  	  	 FROM CTE_Sheets S 
 	  	  	  	  	 LEFT JOIN Sheet_Variables sv ON SV.Sheet_Id = S.Sheet_Id
 	  	  	  	  	 WHERE (SV.Sheet_Id IS NOT NULL AND (SV.Title Is Not Null OR (SV.Title Is NULL AND SV.Title_Var_Order_Id = 0)))
 	  	  	  	  	 OR (SV.Sheet_Id IS NULL AND @DisplayActivityTypeId=1)
 	  	  	  	  	 
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 SELECT @Priority =  Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 447
 	  	  	  	 SELECT @Priority = coalesce(@Priority,1)
 	  	  	  	 SELECT @TargetDuration =  Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId And Display_Option_Id = 448
 	  	  	  	 SELECT @TargetDuration = Coalesce(@TargetDuration,0)
 	  	  	  	 INSERT INTO @NewActivities(ActivityDesc,APriority,AStatus,PUId,TDuration,SheetId,UsesTitle,AutoStart,AutoComplete,LockActivity,ExecutionStartInMins, NeedOverdueComment,DisplayActivityTypeId)
 	  	  	  	  	 SELECT  '[' +  SUBSTRING(ISNULL(@Activity_Alias,@Sheet_Desc), 1, @ActivityDescPreFixLenth) + Case when @ActivityTypeId in (4,5) Then '' ELSE 	 ' - ' END + @EventDesc  + ']',@Priority,1,@PUId,@TargetDuration,--<Changes: Added Activity Alias Prasad>
 	  	  	  	  	  	  	 @SheetId,@UseTitles,@AutoStart,@AutoComplete,@CanLockActivity,@ExecutionStartInMins,@NeedOverdueComment,@DisplayActivityTypeId
 	  	  	  	  	 Where Exists (Select 1 From Sheet_Variables Where Sheet_Id = @SheetId) OR @DisplayActivityTypeId = 1
 	  	  	 END
 	  	  	 SET @Start = @Start + 1
 	  	 END
 	 END
 	 
 	 SET @ActivityLoopStart = 1
 	 SELECT  @ActivityLoopEnd = Max(Id) FROM @NewActivities
 	 WHILE @ActivityLoopStart <= @ActivityLoopEnd
 	 BEGIN
 	 --Clearing the variable values since this is a loop
 	     SELECT @ExecutionStartInMins = NULL,
 	  	  @SystemCompleteDuration = NULL,
 	  	  @Execution_Start_Time = NULL,
 	  	  @System_Complete_Duration_Time = NULL,
 	  	  @StartTime = NULL,
 	  	  @DisplayActivityTypeId = NULL;
 	  	 SELECT @LocalSheetId = SheetId,
 	  	  	    @UseTitles = UsesTitle,
 	  	  	    @AutoStart = AutoStart,
 	  	  	    @AutoComplete = AutoComplete,
 	  	  	    @Title = Title,
 	  	  	    @DisplayActivityTypeId = DisplayActivityTypeId
 	  	 FROM @NewActivities
 	  	 WHERE ID = @ActivityLoopStart
 	  	 SELECT @SheetDesc = Sheet_Desc + ' - ' FROM Sheets WHERE Sheet_Id = @LocalSheetId
 	  	 SET @SheetTitle = Replace(@Title,@SheetDesc,'')
 	  	 --<Changes: System complete activities @Krishna>
 	  	 IF(@UseTitles = 1)
 	  	 BEGIN
 	  	  	 SELECT @ExecutionStartInMins = Execution_Start_Duration, @SystemCompleteDuration = AutoComplete_Duration from Sheet_Variables Where Sheet_Id = @LocalSheetId  and Title = @Title
 	  	 END 
 	  	 ELSE
 	  	 BEGIN
 	  	     SELECT @ExecutionStartInMins = Value FROM Sheet_Display_Options WHERE Sheet_Id = @LocalSheetId And Display_Option_Id = 450
 	  	     SELECT @SystemCompleteDuration = Value from Sheet_Display_Options WHERE Sheet_Id= @LocalSheetId AND Display_Option_Id = 460
 	  	 END
 	  	 SET @SystemCompleteDuration = ISNULL(@SystemCompleteDuration, 0)
 	  	 SET @ExecutionStartInMins = ISNULL(@ExecutionStartInMins, 0)
 	  	 SET @Execution_Start_Time = DATEADD(minute,@ExecutionStartInMins,  @KeyIdDateTime)
 	  	 IF @SystemCompleteDuration > 0
 	  	   BEGIN
 	  	  	  SET @TDuration = ISNULL((SELECT TDuration FROM @NewActivities WHERE Id = @ActivityLoopStart), 0)
 	  	  	  SET @SystemCompleteDuration = CASE WHEN @SystemCompleteDuration > @TDuration THEN @SystemCompleteDuration ELSE @TDuration END
 	  	  	  SET @System_Complete_Duration_Time = DATEADD(minute, @SystemCompleteDuration, @Execution_Start_Time)
 	  	   END
 	  	   --<Changes: System complete activities @Krishna>
 	  	 IF @AutoStart = 1
 	  	  	 SET @StartTime =  @KeyIdDateTime 	  	  	 
 	  	 ELSE 
 	  	  	 SET @StartTime =  Null
 	  	 SELECT @TotalVariables = TotalTests
 	  	  	 FROM dbo.fnCMN_ActivitiesCompleteTests(null,@LocalSheetId,@SheetTitle,@UseTitles)
 	  	 INSERT INTO Activities(Activity_Desc,Activity_Priority,Activity_Status,PU_Id,Start_Time,
 	  	  	  	  	  	  	 Activity_Type_Id,KeyId1,KeyId,Target_Duration,Title,
 	  	  	  	  	  	  	 UserId,EntryOn,PercentComplete,Tests_To_Complete,Sheet_Id,Auto_Complete,Lock_Activity_Security, Execution_Start_Time, Overdue_Comment_Security,System_Complete_Duration_time,Display_Activity_Type_Id)
 	  	 SELECT ActivityDesc,APriority,AStatus,PUId,@StartTime,
 	  	  	  	 @ActivityTypeId,@KeyIdInt,@KeyIdDateTime,TDuration,Title,
 	  	  	  	 @UserId,@EntryOn,0,@TotalVariables,SheetId,@AutoComplete,@CanLockActivity,@Execution_Start_Time, @NeedOverdueComment, @System_Complete_Duration_Time,@DisplayActivityTypeId
 	  	  	 FROM @NewActivities A 
 	  	  	 WHERE ID = @ActivityLoopStart
 	  	  	 AND
 	  	  	  	 NOT EXISTS (SELECT 1 FROM Activities Where Activity_Type_Id =@ActivityTypeId AND PU_Id =A.PUID AND KeyId1 = @KeyIdInt AND KeyId = @KeyIdDateTime AND isnull(Title,'') = isnull(A.Title,'') AND SHEET_ID = @LocalSheetId)
 	  	  	  	 --Added SheetId column in the condition 
 	  	  	  	 --This condition is to avoid duplicates
 	  	   SET @ActivityId = SCOPE_IDENTITY()
 	  	   INSERT INTO @ActivityIds( ActivityId )
 	  	   VALUES(@ActivityId)
 	  	   --<Changes: System complete activities @Krishna>
 	  	   IF @SystemCompleteDuration > 0
 	  	  	  BEGIN
 	  	  	  	 INSERT INTO Pending_SystemCompleteActivities( Activity_Id, System_Complete_Duration_time, Activity_Type_Id)
 	  	  	  	 VALUES(@ActivityId, @System_Complete_Duration_Time,@ActivityTypeId)
 	  	  	  END
 	  	   --<Changes: System complete activities @Krishna>
 	  	 SET @ActivityLoopStart = @ActivityLoopStart + 1
 	 END
 	  IF @ActivityTypeId IN(7,8)
  	    	  BEGIN
  	    	  update a
  	    	    	    	    	  set --Activity_Desc = '[' + s.Sheet_Desc + ' - ' + @EventDesc  + ']',
  	    	     	      	      	   Activity_Desc =  s.Sheet_Desc + '_' + CONVERT(VARCHAR(50),a.Execution_Start_Time,20)
  	    	    	    	    	  from Activities a
  	    	    	    	    	  join Sheets s on s.sheet_id = a.sheet_id
  	    	    	    	    	  where a.Activity_Type_Id = @ActivityTypeId and a.KeyId1 = @KeyIdInt and a.Activity_Id=@ActivityId
  	    	  END
END
ELSE IF @TransType = 2 -- For Updation on an Activity
BEGIN
 	 IF (@ActivityId is not null)
 	 BEGIN -- Only one activity to update
 	  	 IF @TransNum = 0
 	  	 BEGIN
 	  	  	 SELECT @ActivityDesc = ISNULL(@ActivityDesc,Activity_Desc),
 	  	  	  	 @ActivityPriority = ISNULL(@ActivityPriority,Activity_Priority),
 	  	  	  	 @Status = ISNULL(@Status,Activity_Status),
 	  	  	  	 @StartTime = ISNULL(@StartTime,Start_Time),
 	  	  	  	 @EndTime = ISNULL(@EndTime,End_Time),
 	  	  	  	 @TargetDuration = ISNULL(@TargetDuration,Target_Duration),
 	  	  	  	 @Tag  = ISNULL(@Tag,tag),
 	  	  	  	 @UserId = ISNULL(@UserId,UserId),
 	  	  	  	 @PercentComplete = ISNULL(@PercentComplete,PercentComplete),
 	  	  	  	 @TestsToComplete = ISNULL(@TestsToComplete,Tests_To_Complete),
 	  	  	  	 @ExecutionStartTime = ISNULL(@ExecutionStartTime,Execution_Start_Time),
 	  	  	  	 @ExternalLink = ISNULL(@ExternalLink,External_Link),
 	  	  	  	 @ExtendedInfo = ISNULL(@ExtendedInfo,Extended_Info),
 	  	  	  --<Changes: Added privilage to delete comments when comment id is -1 @Krishna>
 	  	  	  	 @OverdueCommentId = CASE @OverdueCommentId WHEN -1 THEN NULL ELSE ISNULL(@OverdueCommentId,Overdue_Comment_Id) END,
 	  	  	  	 @SkipCommentId = CASE @SkipCommentId WHEN -1 THEN NULL ELSE ISNULL(@SkipCommentId,Skip_Comment_Id) END,
 	  	  	  	 @CommentId = CASE @CommentId WHEN -1 THEN NULL ELSE ISNULL(@CommentId,Comment_Id) END,
 	  	  	  	 --@OverdueCommentId = ISNULL(@OverdueCommentId,Overdue_Comment_Id),
 	  	  	  	 --@SkipCommentId = ISNULL(@SkipCommentId,Skip_Comment_Id),
 	  	  	  	 --@CommentId = ISNULL(@CommentId,Comment_Id),
 	  	    	  --<Changes: Added privilage to delete comments when comment id is -1 @Krishna>
 	  	  	  	 @Locked = ISNULL(@Locked,Locked),
 	  	  	  --<Changes: Filling new Complete_Type column with necessary value @Krishna>
 	  	  	  	 @CompleteType = CASE @Status WHEN 3 THEN COALESCE(@CompleteType ,Complete_Type, 0) ELSE NULL END
 	  	  	  --<Changes: Filling new Complete_Type column with necessary value @Krishna>
 	  	  	 FROM Activities
 	  	  	 WHERE Activity_Id = @ActivityId
 	  	 
 	  	 -- Release
 	  	 IF @Status = 5
 	  	 BEGIN
 	  	  	  SET @UserId = NULL;
 	  	  	  -- Reset the activity status to In Progress
 	  	  	  SET @Status = 2
 	  	    END
 	  	   UPDATE Activities
 	  	  	  SET Activity_Desc = @ActivityDesc,
 	  	  	  	 Activity_Priority = @ActivityPriority,
 	  	  	  	 Activity_Status = @Status,
 	  	  	  	 Start_Time = @StartTime,
 	  	  	  	 End_Time = @EndTime,
 	  	  	  	 Target_Duration = @TargetDuration,
 	  	  	  	 UserId = @UserId,
 	  	  	  	 EntryOn = @EntryOn,
 	  	  	  	 PercentComplete = @PercentComplete,
 	  	  	  	 Tests_To_Complete = @TestsToComplete,
 	  	  	  	 Tag = @Tag,
 	  	  	  	 Execution_Start_Time = @ExecutionStartTime,
 	  	  	  	 External_Link = @ExternalLink,
 	  	  	  	 Extended_Info =  @ExtendedInfo,
 	  	  	  	 Overdue_Comment_Id = @OverdueCommentId, 
 	  	  	  	 Skip_Comment_Id  = @SkipCommentId,
 	  	  	  	 Comment_Id = @CommentId,
 	  	  	  	 Locked = @Locked,
 	  	  	  	 --<Changes: Filling new Complete_Type column with necessary value @Krishna>
 	  	  	  	 Complete_Type = @CompleteType
 	  	  	  	 --<Changes: Filling new Complete_Type column with necessary value @Krishna>
 	  	  	  WHERE Activity_Id = @ActivityId
 	  	   INSERT INTO @ActivityIds(ActivityId) SELECT @ActivityId
 	  	 END
 	 END
  	  ELSE IF @ActivityDesc is null and @ActivityTypeId IN ( 2,3,4) and @KeyIdInt is not null
 	 BEGIN -- Support updating the Activity Desc and start_time for event based activities
 	  	 Set @EventDesc = '';
 	  	 IF @ActivityTypeId = 2
 	  	 BEGIN
 	  	  	 IF NOT EXISTS(SELECT 1 FROM Events Where Event_Id = @KeyIdInt)
 	  	  	 BEGIN
 	  	  	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Event: Return(-200)' )
 	  	  	  	 Return(-200)
 	  	  	 END
 	  	  	 SELECT @EventDesc = coalesce(Lot_Identifier, Event_Num), @KeyIdDateTime = TimeStamp
 	  	  	  	 FROM [Events] e
 	  	  	  	 WHERE  e.Event_Id = @KeyIdInt
 	  	  	 ;With s as (Select Event_Num,row_number() over (Order by Entry_On desc)rownum from Event_History Where Event_Id= @KeyIdInt)
 	  	  	 select @ActivityDesc = Event_Num From s Where rownum = 2 -- need to revisit this code to improve
 	  	 END
 	  	 ELSE IF @ActivityTypeId = 4
 	  	 BEGIN 
 	  	  	 IF NOT EXISTS (Select 1 From Sheet_Columns Where Result_On = @KeyIdDateTime And Sheet_Id = @SheetId ) 
 	  	  	 BEGIN
 	  	  	  	 IF @DebugFlag = 1 INSERT INTO Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Production Change Event: Return(-200)' )
  	    	    	  	 Return(-200)
 	  	  	 END
 	  	  	 SELECT @EventDesc = ''
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 IF NOT EXISTS(SELECT 1 FROM User_Defined_Events a Where a.UDE_Id  = @KeyIdInt)
 	  	  	 BEGIN
 	  	  	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No User Defined Events: Return(-200)' )
 	  	  	  	 Return(-200)
 	  	  	 END
 	  	  	 SELECT @EventDesc = coalesce(Friendly_Desc, UDE_Desc), @KeyIdDateTime = End_Time
 	  	  	  	 FROM User_Defined_Events e
 	  	  	  	 WHERE  e.UDE_Id  = @KeyIdInt
 	  	  	 ;With s as (Select UDE_Desc,row_number() over (Order by Modified_On desc)rownum from User_Defined_Event_History Where UDE_Id= @KeyIdInt)
  	    	    	  select @ActivityDesc = SUBSTRING(UDE_Desc,1,1000) From s Where rownum = 2 -- need to revisit this code to improve -- need to revisit this code to improve
 	  	 END
 	  	 update a
 	  	  	 set --Activity_Desc = '[' + s.Sheet_Desc + ' - ' + @EventDesc  + ']',
  	    	    	  Activity_Desc = SUBSTRING(Case When @ActivityDesc IS NOT NULL THEN Replace(Activity_Desc,@ActivityDesc,@EventDesc) ELSE Activity_Desc END,1,1000),
 	  	  	 KeyId = @KeyIdDateTime
 	  	  	 from Activities a
 	  	  	 join Sheets s on s.sheet_id = a.sheet_id
 	  	  	 where a.Activity_Type_Id = @ActivityTypeId and a.KeyId1 = @KeyIdInt AND @ActivityTypeId not IN (7,8)
 	  	  	 
  	    	  
 	  	 INSERT INTO @ActivityIds(ActivityId)
 	  	  	 SELECT Activity_Id
 	  	  	 from Activities a
 	  	  	 Where a.Activity_Type_Id = @ActivityTypeId and a.KeyId1 = @KeyIdInt
 	 END
 	 --<Changes: System complete activities @Krishna>
 	    DELETE Pending_SystemCompleteActivities
 	    FROM Pending_SystemCompleteActivities P
            JOIN(SELECT Activity_Id FROM Activities WHERE Activity_Id IN(SELECT ActivityId FROM @ActivityIds)
                                                         AND Activity_Status IN(3, 4)) A ON A.Activity_Id = P.Activity_Id
 	    --<Changes: System complete activities @Krishna>
END
ELSE IF @TransType = 3 -- For Deletion of an Activity
BEGIN
 	 IF @ActivityTypeId = 1 
 	 BEGIN 
 	  	 INSERT INTO @ActivityIds(ActivityId, KeyId, KeyTime, StartTime, ActivityType,PUId)
 	  	 SELECT Activity_Id, KeyId1, KeyId, Start_Time, Activity_Type_Id,PU_Id 
 	  	  	 FROM Activities
 	  	  	 WHERE KeyId1 = @KeyIdInt AND  KeyId  = @KeyIdDateTime AND Activity_Type_Id = @ActivityTypeId
 	 END
 	 ELSE IF @ActivityTypeId In (2,3)
 	 BEGIN 
 	  	 INSERT INTO @ActivityIds(ActivityId, KeyId, KeyTime,  StartTime, ActivityType,PUId)
 	  	  	 SELECT Activity_Id, KeyId1, KeyId, Start_Time, Activity_Type_Id,PU_Id
 	  	  	 FROM Activities
 	  	  	 WHERE KeyId1 = @KeyIdInt AND Activity_Type_Id = @ActivityTypeId
 	 END
 	 IF @ActivityTypeId In (4) 
 	 Begin
 	  	 INSERT INTO @ActivityIds(ActivityId, KeyId, KeyTime, StartTime, ActivityType,PUId)
 	  	 SELECT Activity_Id, KeyId1, KeyId, Start_Time, Activity_Type_Id,PU_Id 
 	  	  	 FROM Activities
 	  	  	 WHERE KeyId1 = @KeyIdInt AND  KeyId  = @KeyIdDateTime AND Activity_Type_Id = @ActivityTypeId
 	 End
 	 --<Changes: System complete activities @Krishna>
 	 DELETE Pending_SystemCompleteActivities FROM Pending_SystemCompleteActivities P
                                             JOIN @ActivityIds A ON A.ActivityId = P.Activity_Id
 	 --<Changes: System complete activities @Krishna>
 	 DELETE Activities
 	  	 FROM Activities a
 	  	 JOIN @ActivityIds  b ON a.Activity_Id = b.ActivityId 
END
IF  (@TransNum = 3)
BEGIN
 	 
 	 INSERT INTO @variableCounts(numVariables,numComplete,hasAvailableCells)
 	  	 SELECT TotalTests,CompleteTests,HasAvailableCells
 	  	  	 FROM dbo.fnCMN_ActivitiesCompleteTests(@ActivityId,Null,Null,Null) 
 	 SELECT @TotalVariables = numVariables,@TotalCompletedVariables = numComplete, @HasAvailableCells = hasAvailableCells FROM @variableCounts
 	 SET @TestsToComplete = COALESCE(@TotalVariables - @TotalCompletedVariables,0)
 	 SET @PercentComplete = CASE WHEN @TotalVariables = 0 THEN 0
 	  	  	  	  	  	  	 ELSE ROUND(cast(@TotalCompletedVariables as float) / cast(@TotalVariables as float),2) * 100
 	  	  	  	  	  	  	 END
 	 UPDATE Activities
 	  	 SET PercentComplete = @PercentComplete,
 	  	  	  Tests_To_Complete = @TestsToComplete,
 	  	  	  HasAvailableCells = @HasAvailableCells
 	  	 -- WHERE Activity_Id = @ActivityId and ( PercentComplete != @PercentComplete or Tests_To_Complete != @TestsToComplete or HasAvailableCells != @HasAvailableCells)
 	  	 WHERE Activity_Id = @ActivityId and (ISNULL(PercentComplete, 0) != ISNULL(@PercentComplete, 0) or ISNULL(Tests_To_Complete, 0) != ISNULL(@TestsToComplete, 0) or ISNULL(HasAvailableCells, 0) != ISNULL(@HasAvailableCells, 0))
 	 INSERT INTO @ActivityIds(ActivityId) SELECT @ActivityId
 	 IF @TotalCompletedVariables = @TotalVariables AND ISNULL(@TotalVariables,0) > 0
 	 BEGIN
 	  	 UPDATE Activities
 	  	  	 SET Activity_Status  = 3, Complete_Type = 1, End_Time = DateAdd(millisecond,-DatePart(millisecond,@EntryOn),@EntryOn)
 	  	  	 WHERE Activity_Id = @ActivityId and Auto_Complete = 1
 	 END
END
IF EXISTS(SELECT 1 FROM Activities where Activity_Id = @ActivityId AND Activity_Status IN (3,4))
BEGIN
 	 DELETE FROM Pending_SystemCompleteActivities WHERE Activity_Id = @ActivityId
END
IF @ReturnResultSet in (1,2) and EXISTS(Select 1 FROM @ActivityIds a
 	  	  	  	 LEFT JOIN Activities b ON b.Activity_Id  = a. ActivityId)
BEGIN
 	 --Code to restrict putting update message for same ActivityId
 	 IF @TransType = 2 and 1=0
 	 Begin
 	 
 	 Delete a from Pending_Resultsets a join @ActivityIds b on
a.Rs_Value.exist(N'(/rows/row/ActivityId[text() = sql:column("b.ActivityId")])')=1
and a.Rs_Value.exist(N'(/rows/row/TransType[text() =sql:variable("@TransType")])')=1
 	 -- ;WITH TmpPendingResultSet AS 
 	 -- (
 	  	 -- Select 
 	  	  	 -- CAST(ISNULL(LTRIM(RTRIM(REPLACE(CAST(RS_Value.query('data(/rows[1]/row[1]/TransType)') as nVarChar(max)),' ',''))),0) as  Int) TransType
 	  	  	 -- ,CAST(ISNULL(LTRIM(RTRIM(REPLACE(CAST(RS_Value.query('data(/rows[1]/row[1]/ActivityId)') as nVarChar(max)),' ',''))),0) as  Int)  ActivityId
 	  	  	 -- ,RS_Id
 	  	 -- from 
 	  	  	 -- Pending_Resultsets
 	 -- )
 	 -- Delete Pr 
 	 -- from 
 	  	 -- Pending_Resultsets Pr
 	  	 -- Join TmpPendingResultSet T on T.RS_Id = Pr.RS_Id And T.TransType = 2
 	  	 -- JOIN @ActivityIds A ON  T.ActivityId = A.ActivityId 
 	  	 
 	  	 
 	 End
 	 --Code to restrict putting update message for same ActivityId
 	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	 /*
 	 SELECT 0, (SELECT ResultSetType = 4,
 	  	  	  	  	 TopicId = 300,
 	  	  	  	  	 MessageKey = Coalesce(a.PUId, b.PU_Id), -- Message Key
 	  	  	  	  	 PUId =  Coalesce(a.PUId, b.PU_Id), -- Also put it in the topic result set
 	  	  	  	  	 EventType= Coalesce(a.ActivityType,b.Activity_Type_Id) ,
 	  	  	  	  	 KeyId=Coalesce(a.KeyId,b.KeyId1),
 	  	  	  	  	 KeyTime=Coalesce(a.KeyTime,b.KeyId),
 	  	  	  	  	 ActivityId= a.ActivityId,
 	  	  	  	  	 ActivityDesc = b.Activity_Desc ,
 	  	  	  	  	 APriority = b.Activity_Priority ,
 	  	  	  	  	 AStatus = b.Activity_Status ,
 	  	  	  	  	 StartTime= dbo.fnServer_CmnConvertFromDbTime(Coalesce(a.StartTime,b.Start_Time) ,'UTC'),
 	  	  	  	  	 EndTime = dbo.fnServer_CmnConvertFromDbTime(b.End_Time ,'UTC'),
 	  	  	  	  	 TDuration = b.Target_Duration,
 	  	  	  	  	 Title = b.Title,
 	  	  	  	  	 UserId=b.UserId,
 	  	  	  	  	 EntryOn= dbo.fnServer_CmnConvertFromDbTime(b.EntryOn,'UTC'),
 	  	  	  	  	 TransType=@TransType,
 	  	  	  	  	 PercentComplete = b.PercentComplete,
 	  	  	  	  	 Tag = b.Tag ,
 	  	  	  	  	 ExecutionStartTime = b.Execution_Start_Time,
 	  	  	  	  	 AutoComplete = b.Auto_Complete,
 	  	  	  	  	 ExtendedInfo = b.Extended_Info,
 	  	  	  	  	 ExternalLink = b.External_Link,
 	  	  	  	  	 TestsToComplete = b.Tests_To_Complete,
 	  	  	  	  	 Locked = b.Locked,
 	  	  	  	  	 CommentId = b.Comment_Id, 
 	  	  	  	  	 OverdueCommentId = b.Overdue_Comment_Id,
 	  	  	  	  	 SkipCommentId = b.Skip_Comment_Id,
 	  	  	  	  	 SheetId = b.Sheet_Id,
 	  	  	  	  	 TransNum = @TransNum,
 	  	  	  	  	 LockActivity = b.Lock_Activity_Security,
 	  	  	  	  	 NeedOverdueComment = b.Overdue_Comment_Security
 	  	  	  	 FROM @ActivityIds a
 	  	  	  	 LEFT JOIN Activities b ON b.Activity_Id  = a. ActivityId for xml path ('row'), ROOT('rows')), 
 	  	 @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	 */
 	  	 SELECT 0, (SELECT ResultSetType = 4,
 	  	  	  	  	 TopicId = 300,
 	  	  	  	  	 MessageKey = Coalesce(a.PUId, b.PU_Id), -- Message Key
 	  	  	  	  	 PUId =  Coalesce(a.PUId, b.PU_Id), -- Also put it in the topic result set
 	  	  	  	  	 EventType= Coalesce(a.ActivityType,b.Activity_Type_Id) ,
 	  	  	  	  	 KeyId=Coalesce(a.KeyId,b.KeyId1),
 	  	  	  	  	 KeyTime=Coalesce(a.KeyTime,b.KeyId),
 	  	  	  	  	 ActivityId= a.ActivityId,
 	  	  	  	  	 ActivityDesc = b.Activity_Desc ,
 	  	  	  	  	 APriority = b.Activity_Priority ,
 	  	  	  	  	 AStatus = b.Activity_Status ,
 	  	  	  	  	 StartTime= dbo.fnServer_CmnConvertFromDbTime(Coalesce(a.StartTime,b.Start_Time) ,'UTC'),
 	  	  	  	  	 EndTime = dbo.fnServer_CmnConvertFromDbTime(b.End_Time ,'UTC'),
 	  	  	  	  	 TDuration = b.Target_Duration,
 	  	  	  	  	 Title = b.Title,
 	  	  	  	  	 UserId=b.UserId,
 	  	  	  	  	 EntryOn= dbo.fnServer_CmnConvertFromDbTime(b.EntryOn,'UTC'),
 	  	  	  	  	 TransType=@TransType,
 	  	  	  	  	 PercentComplete = b.PercentComplete,
 	  	  	  	  	 Tag = b.Tag ,
 	  	  	  	  	 ExecutionStartTime = b.Execution_Start_Time,
 	  	  	  	  	 AutoComplete = b.Auto_Complete,
 	  	  	  	  	 ExtendedInfo = b.Extended_Info,
 	  	  	  	  	 ExternalLink = b.External_Link,
 	  	  	  	  	 TestsToComplete = b.Tests_To_Complete,
 	  	  	  	  	 Locked = b.Locked,
 	  	  	  	  	 CommentId = b.Comment_Id, 
 	  	  	  	  	 OverdueCommentId = b.Overdue_Comment_Id,
 	  	  	  	  	 SkipCommentId = b.Skip_Comment_Id,
 	  	  	  	  	 SheetId = b.Sheet_Id,
 	  	  	  	  	 TransNum = @TransNum,
 	  	  	  	  	 LockActivity = b.Lock_Activity_Security,
 	  	  	  	  	 NeedOverdueComment = b.Overdue_Comment_Security 
 	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , TYPE),@UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	  	  	 FROM @ActivityIds a
 	  	  	  	 LEFT JOIN Activities b ON b.Activity_Id  = a.ActivityId
 	  	 
END
RETURN(1)
