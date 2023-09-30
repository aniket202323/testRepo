CREATE PROCEDURE dbo.spServer_DBMgrUpdProdPlanStartsFromPlan
 	 @PPId  	 int,
 	 @PathId int, 
 	 @UserId int,
 	 @ControlType 	 Int,
 	 @PPStatusId 	  	 Int,
 	 @DoPPStartsResultSet int = 0  
AS
Declare @PPSetupId  	  	 Int,
 	  	 @MyPUId   	  	 Int,
 	  	 @MyPPStartId  	 Int,
 	  	 @MyStartTime 	 DateTime,
 	  	 @MyPPId 	  	  	 Int,
 	  	 @MyCommentId 	 Int,
 	  	 @Myppsetupid 	 Int,
 	  	 @Now 	  	  	 DateTime,
 	  	 @Sql  	  	  	 nVarChar(1000),
 	  	 @ScheduleControl  Int,
 	  	 @DebugFlag 	  	 Int,
 	  	 @ID 	  	  	  	 Int,
 	  	 @ProductionPlanEntryOn 	 DateTime,
 	  	 @DBMgrUpdProdPlanStarts int
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdProdPlanStartsFromPlan /PPId: ' + Isnull(convert(nvarchar(10),@PPId),'Null') + ' /PathId: ' + Isnull(convert(nVarChar(4),@PathId),'Null') + 
     	 ' /UserId: ' +  Isnull(convert(nVarChar(4),@UserId),'Null') + ' /ControlType ' +  Isnull(convert(nVarChar(4),@ControlType),'Null') + 
 	  	 ' /PPStatusId: ' +  Isnull(convert(nVarChar(25),@PPStatusId),'Null') +  	 ' /DoPPStartsResultSet: ' + convert(nVarChar(4),@DoPPStartsResultSet))
  End
If @ControlType Is Null 
 	 Return
Select @ProductionPlanEntryOn = Null
Select @ProductionPlanEntryOn = Entry_On from production_Plan where PP_Id = @PPId
Select @ScheduleControl =  Is_Schedule_Controlled From PrdExec_Paths Where Path_Id = @PathId
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Select @Now = Coalesce(@ProductionPlanEntryOn,@Now)
/* Close out open starts */
Select @Sql = 'Declare ppscursor cursor Global For select distinct pu_Id,PP_Start_Id,Start_Time,PP_Id,Comment_Id,pp_setup_id From Production_Plan_Starts  Where End_Time is null and pu_Id in (select pu_Id From PrdExec_Path_Units where Path_Id = ' +  Convert(nvarchar(10),@PathId) 
IF @PPStatusId = 3 or  @ControlType = 1  
 	  	 Select @Sql = @Sql + ' and Is_Schedule_Point = 1)'
ELSE -- This is a close @PPStatusId <> 3
 	  	 Select @Sql = @Sql + ') and PP_Id  = ' + Convert(nvarchar(10),@PPId) 
Execute(@Sql)
/*
Declare ppscursor cursor for 
 	 Select distinct pu_Id,PP_Start_Id,Start_Time,PP_Id,Comment_Id,pp_setup_id
  	  	 From Production_Plan_Starts Where End_Time is null and pu_Id in (select pu_Id From PrdExec_Path_Units where Path_Id = @PathId)
*/
  open ppscursor
ppscursorLoop:
  Fetch Next from ppscursor into @MyPUId,@MyPPStartId,@MyStartTime,@MyPPId,@MyCommentId,@Myppsetupid
  If @@Fetch_Status = 0
 	 Begin
 	  	 If @DoPPStartsResultSet > 0
 	  	  	 Insert Into #PPStartsResultSet(Result,PreDB,TransType,TransNum ,PUId ,PPStartId ,StartTime,EndTime,PPId ,CommentId ,PPSetupId ,UserId )
 	  	  	  	 Values(17,0,2,0,@MyPUId,@MyPPStartId,@MyStartTime,@Now,@MyPPId,@MyCommentId,@Myppsetupid,@UserId)
 	  	 Execute @DBMgrUpdProdPlanStarts = spServer_DBMgrUpdProdPlanStarts @MyPPStartId,2,0,@MyPUId, @MyStartTime, @Now,@MyPPId,@MyCommentId ,@Myppsetupid ,@UserId -- Do not do grade change for close
 	  	 if @DBMgrUpdProdPlanStarts <= -1000
 	  	  	 Begin
 	  	  	   Close ppscursor
 	  	  	   Deallocate ppscursor
 	  	  	  	 return @DBMgrUpdProdPlanStarts
 	  	  	 End
 	  	 Goto ppscursorLoop
 	 End
  Close ppscursor
  Deallocate ppscursor
  Select @Myppsetupid = PP_Setup_Id
 	 From Production_Setup
 	 Where Parent_PP_Setup_Id in (Select PP_Setup_Id From Production_Setup Where PP_Id = (Select Parent_PP_Id From Production_Plan Where PP_Id = @PPId))
/* Insert New Starts starts */
If @PPStatusId = 3
  Begin
 	 Select @Sql = 'Declare ppscursor1 cursor Global For select distinct pu_Id From PrdExec_Path_Units where Path_Id = ' + Convert(nvarchar(10),@PathId)
 	 If @ControlType = 2 or @ControlType = 1
 	   Select @Sql = @Sql + ' and Is_Schedule_Point = 1'
 	 Execute(@Sql)
 	   open ppscursor1
 	 ppscursorLoop1:
 	   Fetch Next from ppscursor1 into @MyPUId
 	  	 If @@Fetch_Status = 0
 	  	   Begin
 	  	  	 Select @MyPPStartId = Null
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'call DBMgrUpdProdPlanStarts')
 	  	  	 Execute @DBMgrUpdProdPlanStarts = spServer_DBMgrUpdProdPlanStarts @MyPPStartId Output,1,0,@MyPUId, @Now, Null,@PPId,Null ,@Myppsetupid ,@UserId, @ScheduleControl
 	  	  	 if @DBMgrUpdProdPlanStarts <= -1000
 	  	  	  	 Begin
 	  	  	  	   Close ppscursor1
 	  	  	  	   Deallocate ppscursor1
 	  	  	  	  	 return @DBMgrUpdProdPlanStarts
 	  	  	  	 End
 	  	  	 If @DoPPStartsResultSet > 0
 	  	  	  	 Insert Into #PPStartsResultSet(Result,PreDB,TransType,TransNum ,PUId ,PPStartId ,StartTime,EndTime,PPId ,CommentId ,PPSetupId ,UserId )
 	  	  	  	  	 Values( 17,0,1,0,@MyPUId,@MyPPStartId,@Now,Null,@PPId,Null,@Myppsetupid,@UserId)
 	  	  	 goto ppscursorLoop1
 	  	   End
 	   Close ppscursor1
 	   Deallocate ppscursor1
  End
If @DebugFlag = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
