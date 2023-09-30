CREATE PROCEDURE WorkOrder.spWO_CreateDiscreteWasteEvent
      @WasteEventId				int Output,
      @PUId						int,
      @EventNum					nvarchar(50),
      @TimeStamp				Datetime,
      @Amount					float,
      @ReasonLevel1				int,
      @ReasonLevel2				int,
      @ReasonLevel3				int,
      @ReasonLevel4				int,
      @Username					nvarchar(30),
      @FailIfInvalidReason		bit
    AS

    Declare
      @EventId					int = null,
      @UserId					int = null,
      @SourcePUId				int,
      @WETId					int = null,
      @WEMTId					int = null,
      @TransactionType			int = 1,
      @TransNum					int = 0,
      @WEDId					int,
      @ReturnResultSets			Int = 2, -- This tells it to write any result sets to the Pending Result Sets Table. DBMgr will process them and send the messages for us.
      @Message					NVarChar(2048),
      @ReasonLevel1Bad			bit = 0,
      @ReasonLevel2Bad			bit = 0,
      @ReasonLevel3Bad			bit = 0,
      @ReasonLevel4Bad			bit = 0

    Set @SourcePUId = @PUId


    ------------------------------------------------------------------------------------------------------------------------------
    -- Fast validations - Stuff that doesn't hit the DB
    ------------------------------------------------------------------------------------------------------------------------------
    if (@TimeStamp is null)
    Begin;
    	THROW 50001, N'Must provide a valid time', 1;
    End;

    if (@Amount is null or Not (@Amount > 0))
    Begin;
    	THROW 50002, N'Must provide a valid amount > 0', 1;
    End;

    if (((@ReasonLevel4 is not null) and (@ReasonLevel3 is null)) or
        ((@ReasonLevel3 is not null) and (@ReasonLevel2 is null)) or
        ((@ReasonLevel2 is not null) and (@ReasonLevel1 is null)))
    Begin;
    	THROW 50003, N'Missing Reason Level', 1;
    End;

    ------------------------------------------------------------------------------------------------------------------------------
    -- Reason Id validations
    ------------------------------------------------------------------------------------------------------------------------------
    if ((@ReasonLevel1 is not null) and (not exists(select * from Event_Reasons where Event_Reason_Id = @ReasonLevel1)))
    	Set @ReasonLevel1Bad = 1
    if ((@ReasonLevel2 is not null) and (not exists(select * from Event_Reasons where Event_Reason_Id = @ReasonLevel2)))
    	Set @ReasonLevel2Bad = 1
    if ((@ReasonLevel3 is not null) and (not exists(select * from Event_Reasons where Event_Reason_Id = @ReasonLevel3)))
    	Set @ReasonLevel3Bad = 1
    if ((@ReasonLevel4 is not null) and (not exists(select * from Event_Reasons where Event_Reason_Id = @ReasonLevel4)))
    	Set @ReasonLevel4Bad = 1

    if (@FailIfInvalidReason = 1 and @ReasonLevel1Bad = 1)
    Begin;
    	Set @Message = N'Invalid Reason Level 1 (' + Convert(NVarchar(10), @ReasonLevel1) + N')';
    	THROW 50004, @Message, 1;
    End;

    if (@FailIfInvalidReason = 1 and @ReasonLevel2Bad = 1)
    Begin;
    	Set @Message = N'Invalid Reason Level 2 (' + Convert(NVarchar(10), @ReasonLevel2) + N')';
    	THROW 50005, @Message, 1;
    End;

    if (@FailIfInvalidReason = 1 and @ReasonLevel3Bad = 1)
    Begin;
    	Set @Message = N'Invalid Reason Level 3 (' + Convert(NVarchar(10), @ReasonLevel3) + N')';
    	THROW 50006, @Message, 1;
    End;

    if (@FailIfInvalidReason = 1 and @ReasonLevel4Bad = 1)
    Begin;
    	Set @Message = N'Invalid Reason Level 4 (' + Convert(NVarchar(10), @ReasonLevel4) + N')';
    	THROW 50007, @Message, 1;
    End;

    if (@ReasonLevel1Bad = 1 or @ReasonLevel2Bad = 1 or @ReasonLevel3Bad = 1 or @ReasonLevel4Bad = 1)
    Begin
    	Set @ReasonLevel1 = null
    	Set @ReasonLevel2 = null
    	Set @ReasonLevel3 = null
    	Set @ReasonLevel4 = null
    End

    ------------------------------------------------------------------------------------------------------------------------------
    -- Prod Unit validation
    ------------------------------------------------------------------------------------------------------------------------------
    if (Not Exists(Select * from Prod_Units_Base where PU_Id = @PUId))
    Begin;
    	Set @Message = N'Production Unit (' + Convert(NVarchar(10), @PUId) + N') doesn''t exist';
    	THROW 50008, @Message, 1;
    End;

    ------------------------------------------------------------------------------------------------------------------------------
    -- Prod Event Lookup
    ------------------------------------------------------------------------------------------------------------------------------
    Select @EventId = Event_Id from Events where Event_Num = @EventNum and PU_Id = @PUId
    if (@EventId is null)
    Begin;
    	Set @Message = N'Production Event (' + @EventNum + N') doesn''t exist on Unit (' + Convert(NVarchar(10), @PUId) + N')';
    	THROW 50009, @Message, 1;
    End;

    ------------------------------------------------------------------------------------------------------------------------------
    -- User Lookup
    ------------------------------------------------------------------------------------------------------------------------------
    Select @UserId = User_Id from Users_Base where Username = @Username
    if (@UserId is null)
    Begin;
    	Set @Message = N'User (' + @Username + N') doesn''t exist';
    	THROW 50010, @Message, 1;
    End;

    ------------------------------------------------------------------------------------------------------------------------------
    -- Waste Event Type & Measure Lookup
    ------------------------------------------------------------------------------------------------------------------------------
    Select @WETId = WET_ID from Waste_Event_Type where WET_Name like 'NCM-Waste'
    if (@WETId is null)
    Begin;
    	THROW 50011, N'Unable to find Waste Event Type (NCM-Waste) to assign waste', 1;
    End;

    Select @WEMTId = WEMT_Id from Waste_Event_Meas where WEMT_Name like 'Lot' and PU_Id = @PUId
    if (@WEMTId is null)
    Begin;
    	Set @Message = N'Unable to find Waste Event Measure (Lot) on Unit (' + Convert(nvarchar(10), @PUId) + ')';
    	THROW 50012, @Message, 1;
    End;


    ------------------------------------------------------------------------------------------------------------------------------
    -- Act
    ------------------------------------------------------------------------------------------------------------------------------
    SELECT @Timestamp = dbo.fnServer_CmnConvertToDbTime(@Timestamp,'UTC');

    Exec dbo.spServer_DBMgrUpdWasteEvent	@WEDId OUTPUT, @PUId, @SourcePUId, @Timestamp, @WETId, @WEMTId,
    										@ReasonLevel1, @ReasonLevel2, @ReasonLevel3, @ReasonLevel4,  @EventId,
    										@Amount,  Null,  Null,  @TransactionType,  @TransNum,  @UserId,
    										Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
    										Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
    										Null, Null, Null, Null, Null, Null, @ReturnResultSets

    Select @WasteEventId = @WEDId