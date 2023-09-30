CREATE PROCEDURE [dbo].[spPS_ScrapProductionEvent]
  @EventId					int,
  @EventStatusId			int,
  @Amount					float,
  @ReasonLevel1				int,
  @ReasonLevel2				int,
  @ReasonLevel3				int,
  @ReasonLevel4				int,
  @Username					nVarchar(30),
  @FailIfInvalidReason		bit
AS

Declare
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
  @ReasonLevel4Bad			bit = 0,
  @TimeStamp				Datetime,
  @PUId						int,
  @FinalDimX				float
  

Set @SourcePUId = @PUId

BEGIN TRANSACTION
------------------------------------------------------------------------------------------------------------------------------
-- Fast validations - Stuff that doesn't hit the DB
------------------------------------------------------------------------------------------------------------------------------
if (@EventId is null)
Begin;
      select Error = 'Must provide a Event Id.'
	  Rollback Transaction 
	  RETURN @@ERROR
End;

if not exists (select event_id from events where event_id=@EventId)
Begin;
      select Error = 'Event Id does not exists.'
	  
	  Rollback Transaction
	  RETURN @@ERROR
End;

if (@EventStatusId is null)
Begin;
	select Error = 'Must provide a Event status Id.'
	  Rollback Transaction
	  RETURN @@ERROR
End;

if (@Amount is null or Not (@Amount > 0))
Begin;
select Error = 'Must provide a valid amount > 0.'
	  Rollback Transaction 
	  RETURN @@ERROR
End;

if (@ReasonLevel1 =0)
begin 
set @ReasonLevel1=null;
end

if (@ReasonLevel2 =0)
begin 
set @ReasonLevel2=null;
end

if (@ReasonLevel3 =0)
begin 
set @ReasonLevel3=null;
end

if (@ReasonLevel4 =0)
begin 
set @ReasonLevel4=null;
end

if (((@ReasonLevel4 is not null) and (@ReasonLevel3 is null)) or
    ((@ReasonLevel3 is not null) and (@ReasonLevel2 is null)) or
    ((@ReasonLevel2 is not null) and (@ReasonLevel1 is null)))
Begin;
select Error = 'Missing Reason Level.'
	  Rollback Transaction
	  RETURN @@ERROR
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
	select Error =@Message
	  Rollback Transaction
	  RETURN @@ERROR
End;

if (@FailIfInvalidReason = 1 and @ReasonLevel2Bad = 1)
Begin;
	Set @Message = N'Invalid Reason Level 2 (' + Convert(NVarchar(10), @ReasonLevel2) + N')';
	select Error =@Message
	  Rollback Transaction
	  RETURN @@ERROR
End;

if (@FailIfInvalidReason = 1 and @ReasonLevel3Bad = 1)
Begin;
	Set @Message = N'Invalid Reason Level 3 (' + Convert(NVarchar(10), @ReasonLevel3) + N')';
	select Error =@Message
	  Rollback Transaction
	  RETURN @@ERROR
End;

if (@FailIfInvalidReason = 1 and @ReasonLevel4Bad = 1)
Begin;
	Set @Message = N'Invalid Reason Level 4 (' + Convert(NVarchar(10), @ReasonLevel4) + N')';
	select Error =@Message
	  Rollback Transaction
	  RETURN @@ERROR
End;

if (@ReasonLevel1Bad = 1 or @ReasonLevel2Bad = 1 or @ReasonLevel3Bad = 1 or @ReasonLevel4Bad = 1)
Begin
	Set @ReasonLevel1 = null
	Set @ReasonLevel2 = null
	Set @ReasonLevel3 = null
	Set @ReasonLevel4 = null
End

------------------------------------------------------------------------------------------------------------------------------
-- Prod Event Lookup
------------------------------------------------------------------------------------------------------------------------------
Select @PUId = pu_id, @TimeStamp = timestamp from Events where event_id = @EventId

------------------------------------------------------------------------------------------------------------------------------
-- Event Status Id Lookup
------------------------------------------------------------------------------------------------------------------------------

if not exists (Select prodStatus_Id from production_status where prodStatus_Id =  @EventStatusId)
Begin;
	Set @Message = N'Event Status  doesn''t exist';
	select Error =@Message
	  Rollback Transaction 
	  RETURN @@ERROR
	 End;

------------------------------------------------------------------------------------------------------------------------------
-- User Lookup
------------------------------------------------------------------------------------------------------------------------------
Select @UserId = User_Id from Users_Base where Username = @Username
if (@UserId is null)
Begin;
	Set @Message = N'User (' + @Username + N') doesn''t exist';
	select Error =@Message
	  Rollback Transaction
	  RETURN @@ERROR
End;

------------------------------------------------------------------------------------------------------------------------------
-- Waste Event Type & Measure Lookup
------------------------------------------------------------------------------------------------------------------------------
Select @WETId = WET_ID from Waste_Event_Type where WET_Name like 'NCM-Waste'
if (@WETId is null)
Begin;
select Error ='Unable to find Waste Event Type (NCM-Waste) to assign waste'
	  Rollback Transaction 
	  RETURN @@ERROR
End;

------------------------------------------------------------------------------------------------------------------------------
-- Final Dimension Lookup
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
Select @FinalDimX = Final_Dimension_X from event_Details where event_id = @EventId
if(@FinalDimX < @Amount)
Begin;
	Set @Message = N'Dont have enough quantity to scrap';
	select Error =@Message
	  Rollback Transaction 
	  RETURN @@ERROR
End;




-- Act
-- 1. Update PE status		2. Decrement Final Dimension X of a production event.  3. Create Waste Event
------------------------------------------------------------------------------------------------------------------------------
execute dbo.spServer_DBMgrUpdEvent	@EventId,	Null,	@PUID,	@TimeStamp,	Null,  Null,  @EventStatusId, 2, 0, @UserId,  
										null,	null,  null,  null,  null,  null,  null,  null,  null,  null,  null,  null,  
										null,  null,  null,  null  

UPDATE EVENT_DETAILS SET Final_Dimension_X = (Final_Dimension_X - @Amount) WHERE EVENT_Id = @EventId

SELECT @Timestamp = dbo.fnServer_CmnConvertToDbTime(@Timestamp,'UTC');
Exec dbo.spServer_DBMgrUpdWasteEvent	@WEDId OUTPUT, @PUId, @SourcePUId, @Timestamp, @WETId, null,
										@ReasonLevel1, @ReasonLevel2, @ReasonLevel3, @ReasonLevel4,  @EventId,
										@Amount,  Null,  Null,  @TransactionType,  @TransNum,  @UserId,
										Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
										Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
										Null, Null, Null, Null, Null, Null, @ReturnResultSets

COMMIT transaction
Select @WEDId as wasteEventId