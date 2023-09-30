CREATE PROCEDURE dbo.spServer_EMgrTransition1004
@PU_Id int,
@TransitionTime datetime,
@Stagged_Status int,
@Running_Status int,
@Complete_Status int
 AS
Declare
  @Stagged_Event_Id int,
  @Stagged_Source_Event int,
  @Stagged_Event_Num nVarChar(25),
  @Stagged_TimeStamp Datetime,
  @Stagged_AppProd int,
  @Stagged_Confirmed int,
  @Stagged_Event_Status int,
  @Running_Event_Id int,
  @Running_Source_Event int,
  @Running_Event_Num nVarChar(25),
  @Running_TimeStamp Datetime,
  @Running_AppProd int,
  @Running_Confirmed int,
  @Running_Event_Status int,
  @NewEvent_Num nVarChar(25),
  @NewTimeStamp Datetime,
  @Result int,
  @Id int,
  @ErrMsg nVarChar(255)
Select @ErrMsg = '1004 Msg: (Server) SPID - [' + Convert(nVarChar(10),@@SPID) + ']  PUId - [' + Convert(nVarChar(5),@PU_Id) + ']  TimeStamp - [' + Convert(nVarChar(30), @TransitionTime, 120) + '] Start '
--Execute spServer_CmnSendEmail 1,@ErrMsg,''
Select @ErrMsg = '1004 Msg: (Server) SPID - [' + Convert(nVarChar(10),@@SPID) + ']  PUId - [' + Convert(nVarChar(5),@PU_Id) + ']  TimeStamp - [' + Convert(nVarChar(30), @TransitionTime, 120) + '] '
Select @Id = 1
Declare @EventUpdates Table(Id int, Transaction_Type int, Event_Id int, Event_Num nvarchar(25) COLLATE DATABASE_DEFAULT, PU_Id int, TimeStamp Datetime, Applied_Product int Null, Source_Event int Null, Event_Status int Null, Confirmed int Null)
Select @Stagged_Event_Id = NULL
Select @Stagged_Event_Id = Event_Id,@Stagged_Confirmed = Confirmed,@Stagged_Source_Event = Source_Event,@Stagged_Event_Num = Event_Num,@Stagged_TimeStamp = TimeStamp,@Stagged_AppProd = Applied_Product, @Stagged_Event_Status = Event_Status
  From Events
  Where (PU_Id = @PU_Id) And (TimeStamp = (Select TimeStamp = Max(TimeStamp) From Events Where (PU_Id = @PU_Id) And ((Event_Status = 3) Or (Event_Status = 1))))
Select @Running_Event_Id = NULL
Select @Running_Event_Id = Event_Id,@Running_Confirmed = Confirmed,@Running_Source_Event = Source_Event,@Running_Event_Num = Event_Num,@Running_TimeStamp = TimeStamp,@Running_AppProd = Applied_Product, @Running_Event_Status = Event_Status
  From Events
  Where (PU_Id = @PU_Id) And (TimeStamp = (Select TimeStamp = Max(TimeStamp) From Events Where (PU_Id = @PU_Id) And ((Event_Status = 4) Or (Event_Status = 2))))
Select @Stagged_TimeStamp = DateAdd(Hour,12,dbo.fnServer_CmnGetDate(GetUTCDate()))
Execute spServer_CmnNoSecTime @Stagged_TimeStamp OUTPUT
If @Stagged_Event_Id Is Null
  Begin
    Select @Stagged_Confirmed = Null
    Select @Stagged_AppProd = Null
    Select @Stagged_Source_Event = Null
    Select @Stagged_Event_Num = 'TA' + Convert(nVarChar(10),@PU_Id)  + Convert(nVarchar(17),@Stagged_TimeStamp,109) + convert(nVarChar(10), datepart(minute,dbo.fnServer_CmnGetDate(GetUTCDate()))) +  convert(nVarChar(10), datepart(second,dbo.fnServer_CmnGetDate(GetUTCDate()))) 
    --Select @Stagged_Event_Num = 'Tmp-' + Convert(nVarChar(10),@PU_Id) + '-' + Convert(nVarChar(30),DatePart(Year,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Month,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Day,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Hour,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Minute,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Second,@Stagged_TimeStamp))
    Execute @Result = spServer_DBMgrUpdEvent @Stagged_Event_Id OUTPUT,@Stagged_Event_Num,@PU_Id,@Stagged_TimeStamp,NULL,NULL,1,1,0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Result <> 1)
      Begin
 	 Select @ErrMsg = @ErrMsg + 'A'
        Goto Failed
      End
    Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
      Values(@Id,1,@Stagged_Event_Id,@Stagged_Event_Num,@PU_Id,@Stagged_TimeStamp,NULL,NULL,1,NULL)
    Select @Id = @Id + 1
  End
Else
  Begin
    Execute @Result = spServer_DBMgrUpdEvent @Stagged_Event_Id,@Stagged_Event_Num,@PU_Id,@Stagged_TimeStamp,@Stagged_AppProd,@Stagged_Source_Event,@Stagged_Event_Status,2,0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Result <> 2)
      Begin
 	 Select @ErrMsg = @ErrMsg + 'B'
        Goto Failed
      End
    Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
      Values(@Id,2,@Stagged_Event_Id,@Stagged_Event_Num,@PU_Id,@Stagged_TimeStamp,@Stagged_AppProd,@Stagged_Source_Event,@Stagged_Event_Status,@Stagged_Confirmed)
    Select @Id = @Id + 1
  End
Select @Running_TimeStamp = DateAdd(Hour,6,dbo.fnServer_CmnGetDate(GetUTCDate()))
Execute spServer_CmnNoSecTime @Running_TimeStamp OUTPUT
If @Running_Event_Id Is Null
  Begin
    Select @Running_Confirmed = Null
    Select @Running_AppProd = Null
    Select @Running_Source_Event = Null
    Select @Running_Event_Num = 'TC' + Convert(nVarChar(10),@PU_Id) +  Convert(nVarchar(17),@Running_TimeStamp,109)  + convert(nVarChar(10), datepart(minute,dbo.fnServer_CmnGetDate(GetUTCDate()))) +  convert(nVarChar(10), datepart(second,dbo.fnServer_CmnGetDate(GetUTCDate()))) 
    --Select @Running_Event_Num = 'Tmp-' + Convert(nVarChar(10),@PU_Id) + '-' + Convert(nVarChar(30),DatePart(Year,@Running_TimeStamp)) + Convert(nVarChar(30),DatePart(Month,@Running_TimeStamp)) + Convert(nVarChar(30),DatePart(Day,@Running_TimeStamp)) + Convert(nVarChar(30),DatePart(Hour,@Running_TimeStamp)) + Convert(nVarChar(30),DatePart(Minute,@Running_TimeStamp)) + Convert(nVarChar(30),DatePart(Second,@Running_TimeStamp))
    Execute @Result = spServer_DBMgrUpdEvent @Running_Event_Id OUTPUT,@Running_Event_Num,@PU_Id,@Running_TimeStamp,NULL,NULL,2,1,0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Result <> 1)
      Begin
 	 Select @ErrMsg = @ErrMsg + 'C'
        Goto Failed
      End
    Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
      Values(@Id,1,@Running_Event_Id,@Running_Event_Num,@PU_Id,@Running_TimeStamp,NULL,NULL,2,NULL)
    Select @Id = @Id + 1
  End
Else
  Begin
    Execute @Result = spServer_DBMgrUpdEvent @Running_Event_Id,@Running_Event_Num,@PU_Id,@Running_TimeStamp,@Running_AppProd,@Running_Source_Event,@Running_Event_Status,2,0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Result <> 2)
      Begin
 	 Select @ErrMsg = @ErrMsg + 'D'
        Goto Failed
      End
    Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
      Values(@Id,2,@Running_Event_Id,@Running_Event_Num,@PU_Id,@Running_TimeStamp,@Running_AppProd,@Running_Source_Event,@Running_Event_Status,@Running_Confirmed)
    Select @Id = @Id + 1
  End
If ((@Stagged_Event_Id Is Not Null) And (@Running_Event_Id Is Not Null)) And ((@Stagged_Source_Event Is Not Null) Or (@Running_Source_Event Is Not Null))
  Begin
    If (@Running_Source_Event Is Not Null)
      Begin
        Execute @Result = spServer_DBMgrUpdEvent @Running_Event_Id,@Running_Event_Num,@PU_Id,@TransitionTime,@Running_AppProd,@Running_Source_Event,@Complete_Status,2,0,NULL,NULL,NULL,NULL,NULL,NULL,0
        If (@Result <> 2)
          Begin
 	     Select @ErrMsg = @ErrMsg + 'E'
            Goto Failed
          End
        Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
 	   Values(@Id,2,@Running_Event_Id,@Running_Event_Num,@PU_Id,@TransitionTime,@Running_AppProd,@Running_Source_Event,@Complete_Status,@Running_Confirmed)
        Select @Id = @Id + 1
        Select @NewTimeStamp = DateAdd(Hour,6,dbo.fnServer_CmnGetDate(GetUTCDate()))
        Execute spServer_CmnNoSecTime @NewTimeStamp OUTPUT
 	 If (@Stagged_Source_Event Is Null)
          Select @Running_Event_Status = 2
        Else
          Select @Running_Event_Status = 4
        Execute @Result = spServer_DBMgrUpdEvent @Stagged_Event_Id,@Stagged_Event_Num,@PU_Id,@NewTimeStamp,@Stagged_AppProd,@Stagged_Source_Event,@Running_Event_Status,2,0,NULL,NULL,NULL,NULL,NULL,NULL,0
        If (@Result <> 2)
          Begin
 	     Select @ErrMsg = @ErrMsg + 'F'
            Goto Failed
          End
        Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
 	   Values(@Id,2,@Stagged_Event_Id,@Stagged_Event_Num,@PU_Id,@NewTimeStamp,@Stagged_AppProd,@Stagged_Source_Event,@Running_Event_Status,@Stagged_Confirmed)
        Select @Id = @Id + 1
        Select @Stagged_Event_Id = Null
        Select @Stagged_TimeStamp = DateAdd(Hour,12,dbo.fnServer_CmnGetDate(GetUTCDate()))
        Execute spServer_CmnNoSecTime @Stagged_TimeStamp OUTPUT
        --Select @Stagged_Event_Num = 'Tmp-' + Convert(nVarChar(10),@PU_Id) + '-' + Convert(nVarChar(30),DatePart(Year,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Month,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Day,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Hour,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Minute,@Stagged_TimeStamp)) + Convert(nVarChar(30),DatePart(Second,@Stagged_TimeStamp))
        Select @Stagged_Event_Num = 'TC' + Convert(nVarChar(10),@PU_Id)  + Convert(nVarchar(17),@Stagged_TimeStamp,109) + convert(nVarChar(10), datepart(minute,dbo.fnServer_CmnGetDate(GetUTCDate()))) +  convert(nVarChar(10), datepart(second,dbo.fnServer_CmnGetDate(GetUTCDate()))) 
        Execute @Result = spServer_DBMgrUpdEvent @Stagged_Event_Id OUTPUT,@Stagged_Event_Num,@PU_Id,@Stagged_TimeStamp,NULL,NULL,1,1,0,NULL,NULL,NULL,NULL,NULL,NULL,0
        If (@Result <> 1)
          Begin
 	     Select @ErrMsg = @ErrMsg + 'G'
            Goto Failed
          End
        Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
 	   Values(@Id,2,@Stagged_Event_Id,@Stagged_Event_Num,@PU_Id,@Stagged_TimeStamp,NULL,NULL,1,NULL)
        Select @Id = @Id + 1
      End
    Else
      Begin
        Select @NewTimeStamp = DateAdd(Hour,12,dbo.fnServer_CmnGetDate(GetUTCDate()))
        Execute spServer_CmnNoSecTime @NewTimeStamp OUTPUT
        --Select @NewEvent_Num = 'Tmp-' + Convert(nVarChar(10),@PU_Id) + '-' + Convert(nVarChar(30),DatePart(Year,@NewTimeStamp)) + Convert(nVarChar(30),DatePart(Month,@NewTimeStamp)) + Convert(nVarChar(30),DatePart(Day,@NewTimeStamp)) + Convert(nVarChar(30),DatePart(Hour,@NewTimeStamp)) + Convert(nVarChar(30),DatePart(Minute,@NewTimeStamp)) + Convert(nVarChar(30),DatePart(Second,@NewTimeStamp))
        Select @NewEvent_Num = 'TD' + Convert(nVarChar(10),@PU_Id) + Convert(nVarchar(17),@NewTimeStamp,109) + convert(nVarChar(10), datepart(minute,dbo.fnServer_CmnGetDate(GetUTCDate()))) +  convert(nVarChar(10), datepart(second,dbo.fnServer_CmnGetDate(GetUTCDate()))) 
        Execute @Result = spServer_DBMgrUpdEvent @Stagged_Event_Id,@NewEvent_Num,@PU_Id,@NewTimeStamp,@Stagged_AppProd,NULL,1,2,0,NULL,NULL,NULL,NULL,NULL,NULL,0
        If (@Result <> 2)
          Begin
 	     Select @ErrMsg = @ErrMsg + 'H'
            Goto Failed
          End
        Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
 	   Values(@Id,2,@Stagged_Event_Id,@NewEvent_Num,@PU_Id,@NewTimeStamp,@Stagged_AppProd,NULL,1,@Stagged_Confirmed)
        Select @Id = @Id + 1
        Select @NewTimeStamp = DateAdd(Hour,6,dbo.fnServer_CmnGetDate(GetUTCDate()))
        Execute spServer_CmnNoSecTime @NewTimeStamp OUTPUT
        Execute @Result = spServer_DBMgrUpdEvent @Running_Event_Id,@Stagged_Event_Num,@PU_Id,@NewTimeStamp,@Stagged_AppProd,@Stagged_Source_Event,4,2,0,NULL,NULL,NULL,NULL,NULL,NULL,0
        If (@Result <> 2)
          Begin
 	     Select @ErrMsg = @ErrMsg + 'I'
            Goto Failed
          End
        Insert Into @EventUpdates(Id,Transaction_Type,Event_Id,Event_Num,PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed)
 	   Values(@Id,2,@Running_Event_Id,@Stagged_Event_Num,@PU_Id,@NewTimeStamp,@Running_AppProd,@Stagged_Source_Event,4,@Running_Confirmed)
        Select @Id = @Id + 1
      End
  End
Select @ErrMsg = @ErrMsg + 'Success'
Failed:
--Execute spServer_CmnSendEmail 1,@ErrMsg,''
Select TransType = Transaction_Type, 
       EventId = Event_Id, 
       EventNum = Event_Num, 
       PUId = PU_Id, 
       EvtYear = DatePart(Year,TimeStamp), 
       EvtMonth = DatePart(Month,TimeStamp), 
       EvtDay = DatePart(Day,TimeStamp), 
       EvtHour = DatePart(Hour,TimeStamp), 
       EvtMin = DatePart(Minute,TimeStamp), 
       EvtSec = DatePart(Second,TimeStamp), 
       Applied_Product = COALESCE(Applied_Product,0), 
       Source_Event = COALESCE(Source_Event,0), 
       Event_Status = COALESCE(Event_Status,0),
       Confirmed = COALESCE(Confirmed,0)
  From @EventUpdates
  Order By Id
