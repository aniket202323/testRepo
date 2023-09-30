-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spServer_DBMgrUpdEventComp
-----------------------------------------------------------
CREATE PROCEDURE dbo.spServer_DBMgrUpdEventComp
@UserId int,
@EventId int Output,
@ComponentId int output,
@SrcEventId int output, 
@DimensionX Float Output,
@DimensionY Float Output,
@DimensionZ Float Output,
@DimensionA Float Output,
@TransNum int,
@TransType int,
@ChildUnitId int Output,
@Start_Coordinate_X  	  Float = Null Output,
@Start_Coordinate_Y  	  Float = Null Output,
@Start_Coordinate_Z  	  Float = Null Output,
@Start_Coordinate_A  	  Float = Null Output,
@Start_Time  	  DateTime  	   = Null,
@TimeStamp  	  DateTime  	   = Null,
@Parent_Component_Id Int = Null,
@Entry_On  	  DateTime  = Null Output,
@Extended_Info  	  nVarChar(255) = Null,
@PEI_Id 	  	  	  	  	 Int 	  	 = Null Output,
@ReportAsConsumption Int = Null,
@SignatureId Int = Null,
@ReturnResultSet 	 int = 0 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
 AS 
Declare
@ChildEventId int,
@ParentEventId int
SELECT @ChildEventId = 0,@ParentEventId =0
Declare @DebugFlag tinyint,
 	  	  	  	 @ID int,
 	  	  	  	 @ParentUnitId 	 Int,
 	  	  	  	 @ReturnCode 	  	 Int
DECLARE @originalContextInfo VARBINARY(128)
DECLARE @ContextInfo varbinary(128)
 	  	  	  	 
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_id = 100
--select @DebugFlag = 1
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdEventComp /UserId: ' + Coalesce(convert(nVarChar(4),@UserId),'Null') + ' /EventId: ' + Coalesce(convert(nvarchar(10),@EventId),'Null') + 
 	 ' /ComponentId: ' + Coalesce(convert(nvarchar(10),@ComponentId),'Null') + ' /SrcEventId: ' + Coalesce(convert(nvarchar(10),@SrcEventId),'Null') + 
 	 ' /DimensionX: ' + Coalesce(convert(nVarChar(25),@DimensionX),'Null') + ' /DimensionY: ' + Coalesce(convert(nVarChar(25),@DimensionY),'Null') + 
 	 ' /DimensionZ: ' + Coalesce(convert(nVarChar(25),@DimensionZ),'Null') + ' /DimensionA: ' + Coalesce(convert(nVarChar(25),@DimensionA),'Null') + 
 	 ' /TransNum: ' + Coalesce(convert(nVarChar(4),@TransNum),'Null') + ' /TransType: ' + Coalesce(convert(nvarchar(10),@TransType),'Null') + 
 	 ' /ChildUnitId: ' + Coalesce(convert(nvarchar(10),@ChildUnitId),'Null') + ' /Start_Coordinate_X: ' + Coalesce(convert(nvarchar(10),@Start_Coordinate_X),'Null') + 
 	 ' /Start_Coordinate_Y ' + Coalesce(convert(nvarchar(10),@Start_Coordinate_Y),'Null') + ' /Start_Coordinate_Z: ' + Coalesce(convert(nvarchar(10),@Start_Coordinate_Z),'Null') + 
 	 ' /Start_Coordinate_A ' + Coalesce(convert(nvarchar(10),@Start_Coordinate_A),'Null') + ' /Start_Time: ' + Coalesce(convert(nVarChar(25),@Start_Time),'Null') + 
 	 ' /TimeStamp: ' + Coalesce(convert(nVarChar(25),@TimeStamp),'Null') + ' /Parent_Component_Id: ' + Coalesce(convert(nvarchar(10),@Parent_Component_Id),'Null') + 
 	 ' /Entry_On: ' + Coalesce(convert(nVarChar(25),@Entry_On),'Null') + ' /Extended_Info: ' + Coalesce(convert(nVarChar(255),@Extended_Info),'Null') +
   	 ' /PEI_Id: ' + Coalesce(convert(nvarchar(10),@PEI_Id),'Null') + ' /ReportAsConsumption: ' + Coalesce(convert(nvarchar(10),@ReportAsConsumption),'Null'))
  End
Declare @OldTimestamp DateTime
DECLARE 	 @OldDimension 	 Float,
 	  	 @RecordChanged 	 Int 	 
If @Entry_On is null
  	  Select @Entry_On = dbo.fnServer_CmnGetDate(getUTCdate())
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
If @TransNum Not in (0,2,3,4) and Not (@TransNum Between 100 and 107)
 	 Begin
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@TransNum <> 0) and (@TransNum <> 2) and (@TransNum <> 3) and (@TransNum <> 4) and Not (@TransNum Between 100 and 107)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(-100)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 RAISERROR('Unknown transaction num detected:  %lu', 11, -1, @TransNum)
 	  	 RETURN(-100)
 	 End
If @EventId Is Not Null and @SrcEventId is Not Null
  Begin
   Select @ChildUnitId = PU_Id from Events where Event_Id  = @EventId
   Select @ParentUnitId = PU_Id from Events where Event_Id  = @SrcEventId
 	 End
Else If  (@ComponentId is Not Null)
  Begin
 	  	 Select @ChildUnitId = e.PU_Id,@ParentUnitId = e1.PU_Id
 	  	  	 From Event_Components ec
 	  	  	 Join events e on e.event_Id = ec.Event_Id
 	  	  	 Join events e1 on e1.Event_Id = ec.Source_Event_Id
 	  	  where Component_Id = @ComponentId
 	 End
Else
 	 Begin
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@EventId or @SrcEventId Is NULL and @ComponentId is Null)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(-100)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 RAISERROR('can not determine event component record', 11, -1)
 	  	 RETURN(-100)
 	 End
IF @ChildUnitId IS NULL
BEGIN
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@EventId was not Found')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(-100)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 RAISERROR('can not find event id for event component record', 11, -1)
 	  	 RETURN(-100)
END
IF @ParentUnitId IS NULL
BEGIN
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SrcEventId was not Found')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(-100)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 RAISERROR('can not find source event id for event component record', 11, -1)
 	  	 RETURN(-100)
END
If @PEI_Id Is Null --Try to look it up
  Begin
  	    	  If (Select Count(PEIS_Id)
  	    	    	    	  From PrdExec_Input_Sources pis
        Join PrdExec_Inputs p  On pis.PEI_Id = p.PEI_Id And p.PU_Id = @ChildUnitId and pis.PU_Id = @ParentUnitId) = 1 
  	    	    	  Begin
            Select @PEI_Id = p.PEI_Id
             From PrdExec_Input_Sources pis
             Join PrdExec_Inputs p On pis.PEI_Id = p.PEI_Id And p.PU_Id =  @ChildUnitId And pis.PU_Id = @ParentUnitId
  	    	    	  End
  	    	  If @PEI_Id is null
  	    	    	  Begin
  	    	      	  If (Select count(Distinct PEI_Id)
  	    	     	    	    	  From PrdExec_Input_Event_History
  	    	    	    	    	  Where (PEIP_Id = 1) And (Event_Id = @SrcEventId)) = 1
  	    	    	        Select @PEI_Id = PEI_Id
  	    	     	    	    	  From PrdExec_Input_Event_History
        	    	  Where (PEIP_Id = 1) And (Event_Id = @SrcEventId)
  	    	  End
  	  End
If (@TransType = 1) And (@TransNum = 0) And (@ComponentId Is NULL) And (@EventId Is Not NULL) And (@SrcEventId Is Not NULL)
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- When adding a record: defaults timestamp  without ms
 	 -- AJ: 25-Nov-2004
 	 -------------------------------------------------------------------------------
 	 If @TimeStamp Is Null
 	 BEGIN
 	  	 Select @TimeStamp = dbo.fnServer_CmnGetDate(getUTCdate())
 	  	 Select @TimeStamp = DateAdd(millisecond, -DatePart(millisecond,@TimeStamp),@TimeStamp)
 	 END
 	 /* Do Not allow multiple event:source events:TimeStamp  */
 	 If @PEI_Id Is Null
 	  	 Select @ComponentId = Component_Id From  Event_Components Where Event_Id = @EventId and Source_Event_Id = @SrcEventId and  Timestamp = @TimeStamp and  PEI_Id Is Null
 	 Else
 	  	 Select @ComponentId = Component_Id From  Event_Components Where Event_Id = @EventId and Source_Event_Id = @SrcEventId and  Timestamp = @TimeStamp and  PEI_Id = @PEI_Id
 	 If @ComponentId is Null 
 	 BEGIN
  	    	  Insert Into Event_Components(Event_Id,Source_Event_Id,Dimension_X,Dimension_Y,Dimension_Z,Dimension_A,Extended_Info,Timestamp,User_id,Entry_On,
  	    	    	  Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Coordinate_A,Start_Time,Parent_Component_Id,PEI_Id,Report_As_Consumption,Signature_Id)
  	    	     Values (@EventId,@SrcEventId,@DimensionX,@DimensionY,@DimensionZ,@DimensionA,@Extended_Info,@Timestamp,@Userid,@Entry_On,
  	    	    	  @Start_Coordinate_X,@Start_Coordinate_Y,@Start_Coordinate_Z,@Start_Coordinate_A,@Start_Time,@Parent_Component_Id,@PEI_Id,isnull(@ReportAsConsumption,1),@SignatureId)
  	    	  Select @ComponentId = Scope_Identity()
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(Insert Event_Components)')
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(1)')
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 SET @ReturnCode = 1
      	 GOTO SendPost
 	 END
  	 ELSE
 	 BEGIN
 	  	 Select @TransType = 2
 	 END
END
If (@TransType = 2)  And (@ComponentId Is Not NULL)
BEGIN
 	 IF (@TransNum BETWEEN 100 AND 107) OR (@TransNum = 3)  --(@TransNum BETWEEN 100 AND 107) for Dimension sync
 	 BEGIN
 	  	 If @TransNum = 3 --Common Dialog update
 	  	 BEGIN
  	    	    	  Update Event_Components Set Dimension_X = @DimensionX,
 	  	  	  	 Dimension_Y = @DimensionY,
 	  	  	  	 Dimension_Z = @DimensionZ,
 	  	  	  	 Dimension_A = @DimensionA,
 	  	  	  	 Timestamp = @Timestamp,
 	  	  	  	 Start_Coordinate_X = @Start_Coordinate_X,
 	  	  	  	 Start_Coordinate_Y = @Start_Coordinate_Y,
 	  	  	  	 Start_Coordinate_Z = @Start_Coordinate_Z,
 	  	  	  	 Start_Coordinate_A = @Start_Coordinate_A,
 	  	  	  	 Start_Time = @Start_Time,
 	  	  	  	 Entry_On = @Entry_On,
 	  	  	  	 User_Id = @UserId,
 	  	  	  	 Signature_Id = @SignatureId
 	  	  	  	 Where (Component_Id = @ComponentId)
 	  	 END
 	  	 If @TransNum = 100 
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Dimension_A = @DimensionA, Entry_On = @Entry_On, User_Id = @UserId
  	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 101
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Dimension_X = @DimensionX, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 102
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Dimension_Y = @DimensionY, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 103
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Dimension_Z = @DimensionZ, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 104
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Start_Coordinate_A = @Start_Coordinate_A, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 105
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Start_Coordinate_X = @Start_Coordinate_X, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 106/* Make Sure the dimension has changed */
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Start_Coordinate_Y = @Start_Coordinate_Y, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
 	  	 If @TransNum = 107/* Make Sure the dimension has changed */
 	  	 BEGIN
 	  	  	 UPDATE Event_Components Set Start_Coordinate_Z = @Start_Coordinate_Z, Entry_On = @Entry_On, User_Id = @UserId
 	  	  	 WHERE Component_Id = @ComponentId
 	  	 END
  	    	 SELECT @DimensionX = Dimension_X,
 	  	  	  	 @DimensionY = Dimension_Y,
 	  	  	  	 @DimensionZ = Dimension_Z,
 	  	  	  	 @DimensionA = Dimension_A,
 	  	  	  	 @Start_Coordinate_X = Start_Coordinate_X,
 	  	  	  	 @Start_Coordinate_Y = Start_Coordinate_Y,
 	  	  	  	 @Start_Coordinate_Z =Start_Coordinate_Z,
 	  	  	  	 @Start_Coordinate_A = Start_Coordinate_A,
 	  	  	  	 @EventId = Event_Id,
 	  	  	  	 @SrcEventId = Source_Event_Id,
 	  	  	  	 @PEI_Id = PEI_Id
  	    	  From Event_Components Where (Component_Id = @ComponentId)
 	  	 SET @ReturnCode = 2
      	 GOTO SendPost
 	 END
 	 SELECT @OldTimestamp = Timestamp From Event_Components Where (Component_Id = @ComponentId)
  	  If (@TransNum = 0)
  	  BEGIN
  	    	  Select @DimensionX = Coalesce(@DimensionX,Dimension_X),
 	  	  	  	 @DimensionY = Coalesce(@DimensionY,Dimension_Y),
 	  	  	  	 @DimensionZ = Coalesce(@DimensionZ,Dimension_Z),
 	  	  	  	 @DimensionA = Coalesce(@DimensionA,Dimension_A),
 	  	  	  	 @Extended_Info = Coalesce(@Extended_Info,Extended_Info),
 	  	  	  	 @Timestamp = Coalesce(@Timestamp,Timestamp),
 	  	  	  	 @Start_Coordinate_X = Coalesce(@Start_Coordinate_X,Start_Coordinate_X),
 	  	  	  	 @Start_Coordinate_Y = Coalesce(@Start_Coordinate_Y,Start_Coordinate_Y),
 	  	  	  	 @Start_Coordinate_Z = Coalesce(@Start_Coordinate_Z,Start_Coordinate_Z),
 	  	  	  	 @Start_Coordinate_A = Coalesce(@Start_Coordinate_A,Start_Coordinate_A),
 	  	  	  	 @Parent_Component_Id = Coalesce(@Parent_Component_Id,Parent_Component_Id),
 	  	  	  	 @Start_Time = Coalesce(@Start_Time,Start_Time),
 	  	  	  	 @PEI_Id = Coalesce(@PEI_Id,PEI_Id),
 	  	  	  	 @ReportAsConsumption = Coalesce(@ReportAsConsumption,Report_As_Consumption,1)
  	    	  From Event_Components Where (Component_Id = @ComponentId)
  	 END 
    If (@TransNum = 2) or (@TransNum = 0) or (@TransNum = 4)
  	    	  Begin
  	    	      if (@TransNum = 4)
  	    	  	 BEGIN
  	    	  	   Select @DimensionX = Dimension_X,
  	    	  	      @DimensionY = Dimension_Y,
  	    	  	      @DimensionZ = Dimension_Z, 
  	    	  	      @DimensionA = Dimension_A,
 	  	  	      @Start_Coordinate_X = Start_Coordinate_X,
 	  	  	      @Start_Coordinate_Y = Start_Coordinate_Y,
 	  	  	      @Start_Coordinate_Z = Start_Coordinate_Z,
 	  	  	      @Start_Coordinate_A = Start_Coordinate_A
 	  	  	    From Event_Components
 	  	  	     Where (Component_Id = @ComponentId)
  	    	  	 END
 	  	  	 --DE102236 -.NET SDK PAGenealogyEvent Update is not working
 	  	  	 select  @ParentEventId = Source_Event_Id,
 	  	  	  	  @ChildEventId = Event_Id from Event_Components  
 	  	  	  	  WHERE Component_Id = @ComponentId
 	  	  
 	  	  	  	  
 	  	  	  	 if ((ISNULL(@EventId,0) != ISNULL(@ChildEventId,0)) or (@SrcEventId != @ParentEventId)) AND @TransType = 2
 	  	  	  	 Begin
 	  	  	  	  	 RAISERROR('can not update Child_Parent EventId', 11, -1)
 	  	  	  	  	 RETURN(-100)
 	  	  	  	 End
 	  	  	 
 	  	  	  If @Timestamp is null
 	  	  	    	    	  Select @Timestamp = Timestamp From Event_Components Where (Component_Id = @ComponentId)
  	    	    	  If @OldTimestamp is not null
  	    	    	   Begin
  	    	    	    If @Timestamp is null
 	  	  	  	 BEGIN
  	    	    	    	  Execute spServer_DBMgrCleanupEventComponentTime @ComponentId,null,@ReturnResultSet,@UserId
 	  	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'spServer_DBMgrCleanupEventComponentTime')
 	  	  	  	 END
  	    	    	    Else
  	    	    	    	  If @OldTimestamp <> @Timestamp 
 	  	  	  	  BEGIN 
  	    	    	    	     Execute spServer_DBMgrCleanupEventComponentTime @ComponentId,@Timestamp,@ReturnResultSet,@UserId
 	  	  	  	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'spServer_DBMgrCleanupEventComponentTime')
  	    	    	   End
 	    	    	   End
  	    	    	  Update Event_Components Set Dimension_X = @DimensionX,
 	  	  	  	 Dimension_Y = @DimensionY,
 	  	  	  	 Dimension_Z = @DimensionZ,
 	  	  	  	 Dimension_A = @DimensionA,
 	  	  	  	 Extended_Info = @Extended_Info,
 	  	  	  	 Timestamp = @Timestamp,
 	  	  	  	 Start_Coordinate_X = @Start_Coordinate_X,
 	  	  	  	 Start_Coordinate_Y = @Start_Coordinate_Y,
 	  	  	  	 Start_Coordinate_Z = @Start_Coordinate_Z,
 	  	  	  	 Start_Coordinate_A = @Start_Coordinate_A,
 	  	  	  	 Parent_Component_Id = @Parent_Component_Id,
 	  	  	  	 PEI_Id = @PEI_Id,
 	  	  	  	 Report_As_Consumption = Isnull(@ReportAsConsumption,1),
 	  	  	  	 Start_Time = @Start_Time,
 	  	  	  	 Entry_On = @Entry_On,
 	  	  	  	 User_Id = @UserId,
 	  	  	  	 Signature_Id = @SignatureId
 	  	  	  	 Where (Component_Id = @ComponentId)
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(Update Event_Components)')
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(2)')
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	 SET @ReturnCode = 2
 	  	  	 GOTO SendPost
  	    	  End
  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(4)')
 	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
  	 RAISERROR('can not determine trans num for update', 11, -1)
 	 RETURN(-100)
END
Else If  (@TransType = 3) And (@TransNum = 0) And (@EventId Is Not NULL) And (@SrcEventId Is Not NULL) and (@ComponentId is Null)
  Begin
  	  If @Timestamp Is null
 	  	  	 Begin
 	  	  	  If (select count(*) from Event_Components where Event_Id = @EventId and Source_Event_Id = @SrcEventId) = 1 
 	  	  	   Begin
 	  	  	  	 SET @originalContextInfo = Context_Info()
 	  	  	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	  	  	 SET Context_Info @ContextInfo 
      	  	   	  	 Delete From  Event_Components where Event_Id = @EventId and Source_Event_Id = @SrcEventId
 	  	  	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
 	  	  	   End
 	  	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(Delete Event_Components 1)')
 	  	  	 End
  	  Else
  	    Begin
  	    	  Select @ComponentId = Component_Id From  Event_Components where Event_Id = @EventId and Source_Event_Id = @SrcEventId and Timestamp = @Timestamp
  	    	  Execute spServer_DBMgrCleanupEventComponentTime @ComponentId,null,@ReturnResultSet,@UserId
 	  	  SET @originalContextInfo = Context_Info()
 	  	  SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	   	  SET Context_Info @ContextInfo 
      	   	  Delete From  Event_Components where  Component_Id = @ComponentId
 	   	  IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
   	  	  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(Delete Event_Components 2)')
  	    End
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(3)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 RETURN(3)
  End
Else If  (@TransType = 3) And (@TransNum = 0) and (@ComponentId is Not Null)
  Begin
 	  	 SELECT  @EventId = Event_Id, @SrcEventId = Source_Event_Id FROM Event_Components where Component_Id = @ComponentId
 	  	 Execute spServer_DBMgrCleanupEventComponentTime @ComponentId,null,@ReturnResultSet,@UserId
 	  	 SET @originalContextInfo = Context_Info()
 	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	   	 SET Context_Info @ContextInfo 	 
 	  	 Delete From Event_Components where Component_Id = @ComponentId
 	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(Delete Event_Components 3)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(3)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 RETURN(3)
  End
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(4)')
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
RAISERROR('invalid transnum /transtype ', 11, -1)
RETURN(-100)
SendPost:
IF @ReturnResultSet = 1
BEGIN
 	 --Send Post event resultset
 	 Select 11, 0, User_Id,@TransType,@TransNum,
 	  	  	 a.Component_Id,a.Event_Id,a.Source_Event_Id,a.Dimension_X,a.Dimension_Y,
 	  	  	 a.Dimension_Z,a.Dimension_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,
 	  	  	 a.Start_Coordinate_A,a.Start_Time,a.Timestamp,a.Parent_Component_Id,a.Entry_On,
 	  	  	 a.Extended_Info,a.PEI_Id
           From Event_Components a 
 	 Where Component_Id = @ComponentId
END
IF @ReturnResultSet = 2
BEGIN
 	 --Send Post event resultset
 	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	 SELECT 0, (
 	  	 Select RSTId=11, PreDB=0, User_Id,@TransType,@TransNum,
 	  	  	  	 a.Component_Id,a.Event_Id,a.Source_Event_Id,a.Dimension_X,a.Dimension_Y,
 	  	  	  	 a.Dimension_Z,a.Dimension_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,
 	  	  	  	 a.Start_Coordinate_A,a.Start_Time,a.Timestamp,a.Parent_Component_Id,a.Entry_On,
 	  	  	  	 a.Extended_Info,a.PEI_Id
 	  	    From Event_Components a 
 	  	 Where Component_Id = @ComponentId
 	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
END
RETURN  (@ReturnCode)
