/*
 * Get the value for the passed in calc input.  NOTE: This SP is not called for
 * all entities/attribute combinations.  If the CalcMgr already knows the value it
 * will use it.  (Eg. varId)
 *
SET NOCOUNT ON 
declare @P1 nVarChar(511)
set @P1=NULL
exec spServer_CalcMgrGetInputValue 6, 7, 13, 13, 155, 12, 'Jan 16 2006  7:39:09:000PM', 2617422, 1, 2, @P1 output, 0, 0
select @P1
GO  --154
 */
CREATE PROCEDURE dbo.spServer_CalcMgrGetInputValue
@EntityType int,
@AttribType int,
@Var_Id int, 	  	  	  	  	  	  	 -- Varid to get the value for (May not apply if entity type is not related to variables)
@puid int, 	  	  	  	  	  	  	  	 -- PUId of variable
@ResultVarId int, 	  	  	  	  	 -- Result variable it
@ResultVarPUId int, 	  	  	  	 -- PUId of result variable
@RunTime datetime, 	  	  	  	 -- Time to get the value for
@EventId int, 	  	  	  	  	  	  	 -- EventId to get the value for (May not apply if entity type is not related to events)
@Event_Type int, 	  	  	  	  	 -- Type of event
@EventSubType int, 
@Result nvarchar(25) OUTPUT,
@SkipGenealogy int = 0,  -- A weird flag so I can call this recursively for Genealogy Alias
@AllowMultipleResults int = 0 ,
@TriggeringVarEventId int = 0
AS 
declare @target as nVarChar(30)
declare @uuser as nVarChar(30)
declare @luser as nVarChar(30)
declare @ureject as nVarChar(30)
declare @lreject as nVarChar(30)
declare @uwarning as nVarChar(30)
declare @lwarning as nVarChar(30)
declare @uentry as nVarChar(30)
declare @lentry as nVarChar(30)
declare @ProdCode as nvarchar(500)
declare @ResultOn as datetime
declare @EndTime as datetime
declare @@AResultOn as datetime
declare @count as int
declare @VarEventType as int
declare @AppProdId as int
declare @OtherEventId as int
declare @SkipSpecs as int
declare @StartId as int
declare @ProdId as int
declare @NewResult as nvarchar(25)
declare @Dimension as float
/*
create table xxx (timestamp datetime,
EntityType int null,
AttribType int null,
Var_Id int null, 	  	  	  	 
puid int null, 	  	  	  	  	 
ResultVarId int null, 	 
ResultVarPUId int null,
RunTime datetime null,
EventId int null, 	  	 
Event_Type int null, 	 
EventSubType int null,
Result nvarchar(25) null) 
*/
/*
if (@ResultVarId is not null) and (@ResultVarId = 888)
begin
insert into xxx(timestamp,EntityType ,AttribType ,Var_Id , 	  	  	 puid , 	  	  	  	 ResultVarId , 	 ResultVarPUId ,RunTime ,EventId , 	  	 Event_Type , 	 EventSubType ,Result )  
values (getdate(),@EntityType,@AttribType,@Var_Id, 	  	  	  	 @puid, 	  	  	 @ResultVarId, 	 @ResultVarPUId,@RunTime,@EventId, 	  	 @Event_Type, 	 @EventSubType,NULL)
end
*/
select @SkipSpecs = 0
select @Result = NULL
if (@SkipGenealogy = 0 and (@EntityType = 6 or @EntityType = 8)) -- Genealogy.  Validate there is a "connection" before getting the value
begin
  Declare @CMResultEvents table (EventId int, EventUnit int, TimeStamp datetime, GenealogyLevel int NULL)
  /* 
  *  04/16/01 MKW - Reversed the order of the result variables with the input variables.  
  *  exec dbo.spServer_CalcMgrFillGenealogyTable @var_id,@puid,@resultVarId,@resultvarPUId,@RunTime,@RunTime
  */
  --exec dbo.spServer_CalcMgrFillGenealogyTable @resultvarPUId,@puid,@RunTime,@RunTime
  exec dbo.spServer_CalcMgrLoadGenealogyTable @resultvarPUId,@puid,@RunTime,@RunTime
  Insert Into @CMResultEvents (EventId, EventUnit, TimeStamp, GenealogyLevel)
    select EventId, EventUnit, TimeStamp, GenealogyLevel 
      From fnServer_CalcMgrResultEventsFromGeneCache (@resultvarPUId,@puid,@RunTime,@RunTime)
  select @count = Count(EventId) from @CMResultEvents
  if @count = 0  -- no "connection"
  begin
    Select @Result = ''
    return
  end
  /* 
  *  04/16/01 MKW - Added the following to output the result of CalcMgrFillGenealogy.  Have to use convert(,121) because
  *  MSSQL server's default date->string format results in the day and month being reversed by Proficy 
  *  (ie. 1/5/99 -> 5/1/99).
  */
  else
  begin
  	    	  if (@AllowMultipleResults = 1 and @EntityType = 6) -- Genealogy var.  Return a value for each connection
  	    	  begin
  	    	    	  Declare CMR_Cursor INSENSITIVE CURSOR For (select TimeStamp from @CMResultEvents ) 
  	    	    	  For Read Only
  	    	    	  Open CMR_Cursor  
  	    	    	  Fetch_Loop:
  	    	    	    Fetch Next From CMR_Cursor Into @@AResultOn
  	    	    	    If (@@Fetch_Status = 0)
  	    	    	    	  Begin
  	    	    	    	    	  exec spServer_CalcMgrGetInputValue @EntityType, @AttribType, @Var_Id, @puid, @ResultVarId, @ResultVarPUId, @@AResultOn, @EventId, @Event_Type, @EventSubType, @NewResult OUTPUT, 1, 0,@TriggeringVarEventId
  	    	    	    	    	  select @NewResult
  	    	    	    	    Goto Fetch_Loop
  	    	    	    	  End
  	    	    	  Close CMR_Cursor
  	    	    	  Deallocate CMR_Cursor
  	    	    	  return
  	    	  end
  	    	  else
  	    	  begin
  	      select @OtherEventId = EventId from @CMResultEvents  where EventUnit = @puid
    	    select @RunTime = max(TimeStamp) from @CMResultEvents
  	    	  end
  end
end
-- Now get the real value
if (@EntityType = 2 or @EntityType = 3 or @EntityType = 6) -- This var or result var or genealogy
begin
  if (@AttribType = 1) -- VarId
    Select @Result = Convert(nVarChar(20),@Var_Id)
  else if (@AttribType = 2) -- EventId
    begin
      execute spServer_CalcMgrGetEventId  @PUId, @Event_Type, @EventSubType, @RunTime, @EventId OUTPUT
      Select @Result = Convert(nVarChar(20),@EventId)
  	  end
  else if (@AttribType = 5)  -- PUId
    Select @result=pu_id from variables_base where var_id = @var_id
  else if (@AttribType = 6)  -- Master PUId
    select @result=coalesce (p.Master_Unit, p.pu_id) from
    Variables_Base V 
    JOIN Prod_Units_Base P on p.PU_Id = v.PU_Id
    where v.var_id = @var_id
  Else If (@AttribType in (7,8,9)) -- This Value, Last Value, Next Value
 	  	 Begin
 	  	  	 Execute spServer_CalcMgrGetVarInputValue @AttribType,@Var_Id,@PUId, @ResultVarId, @ResultVarPUId,@RunTime, @EventId, @TriggeringVarEventId, @Event_Type,@EventSubType,@Result OUTPUT
 	  	 End
  else if ((@AttribType >= 10) and (@AttribType <= 18)) or (@AttribType = 33) or (@AttribType = 34) -- specs and ProdId & prod code
  begin
    select @UEntry=NULL
    select @UReject=NULL
    select @UWarning=NULL
    select @UUser=NULL
    select @LEntry=NULL
    select @LReject=NULL
    select @LWarning=NULL
    select @LUser=NULL
    select @target=NULL
  	   select @SkipSpecs = 0
  	   select @ProdId = NULL
  	   select @ProdCode=NULL
    select @VarEventType = NULL
    select @VarEventType=Event_Type from Variables_Base where var_id = @var_id
    if @VarEventType = 1 
     begin
       if @EventId is NULL or @EventId = 0
         execute dbo.spServer_CalcMgrGetEventId @puid, @Event_Type, @EventSubType, @RunTime, @EventId OUTPUT
       select @AppProdId=NULL
       select @AppProdId=Applied_Product from events where Event_Id = @EventId
       if @AppProdId is not null and @AppProdId <> 0
   	     	  select @ProdId = @AppProdId
     end
   if @ProdId is null
      select @ProdId = ps.Prod_id 
 	       FROM Variables_Base V
   	     JOIN Prod_Units_Base P on p.PU_Id = v.PU_Id
     	   join Production_Starts ps on ps.pu_id = COALESCE(Master_Unit, p.PU_Id) 
       	 where (v.var_id = @Var_id) and ((@RunTime >= ps.Start_Time) and ((@RunTime < ps.End_Time) or (ps.End_Time is NULL)))
    if (@AttribType >= 10) and (@AttribType <= 18)
      	  select @UEntry=U_Entry, @UReject=U_Reject, @UWarning=U_Warning, @UUser=U_User,
              @LEntry=L_Entry, @LReject=L_Reject, @LWarning=L_Warning, @LUser=L_User, @target = Target
 	       	  FROM var_specs
   	     	  where ((var_id=@var_id) and (Prod_Id = @ProdId) and ((@Runtime >= Effective_Date) and ((@Runtime < Expiration_Date) or (Expiration_Date is NULL))))
    if (@AttribType = 10) select @result = @target
    else if (@AttribType = 11) select @result = @UEntry
    else if (@AttribType = 12) select @result = @UReject
    else if (@AttribType = 13) select @result = @UWarning
    else if (@AttribType = 14) select @result = @UUser
    else if (@AttribType = 15) select @result = @LUser
    else if (@AttribType = 16) select @result = @LWarning
    else if (@AttribType = 17) select @result = @LReject
    else if (@AttribType = 18) select @result = @LEntry
    else if (@AttribType = 33) select @result = @ProdId
    else if (@AttribType = 34) 
 	  	  	 begin
 	     	   select @ProdCode=Prod_Code from products where Prod_Id = @ProdId
 	  	  	  	 select @result = @ProdCode
 	  	  	 end
  end
end
else if (@EntityType = 4 or @EntityType = 8) -- This event or genealogy event
begin
  if (@EntityType = 8) 
  begin
    select @EventId = @OtherEventId
  end
  if (@AttribType = 2) -- EventId
    Select @Result = @EventId
  else if (@AttribType = 21) -- Event Num
  begin
    If (@Event_Type = 1) -- Turnups
      Select @Result=Event_Num From Events  Where (Event_Id = @EventId)
  end
  else if (@AttribType in (22,23,24,25,29,30,31,32)) -- Dimensions
 	 begin
 	  	 if (@AttribType = 22) -- DimensionX
 	  	  	 Select @Dimension=Initial_Dimension_X from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 23) -- DimensionY
 	  	  	 Select @Dimension=Initial_Dimension_Y from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 24) -- DimensionZ
 	  	  	 Select @Dimension=Initial_Dimension_Z from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 25) -- DimensionA
 	  	  	 Select @Dimension=Initial_Dimension_A from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 29) -- Final DimensionX
 	  	  	 Select @Dimension=Final_Dimension_X from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 30) -- Final DimensionY
 	  	  	 Select @Dimension=Final_Dimension_Y from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 31) -- Final DimensionZ
 	  	  	 Select @Dimension=Final_Dimension_Z from event_Details where (Event_Id=@EventId)
 	  	 else if (@AttribType = 32) -- Final DimensionA
 	  	  	 Select @Dimension=Final_Dimension_A from event_Details where (Event_Id=@EventId)
 	  	 -- SQL's normal convert only allows 6 significant digits.  Force in some more.
 	  	 if (@Dimension is not null and @Dimension > 1e-10)
 	  	  	 select @Result = convert(nVarChar(100), convert(Decimal(38,16), @Dimension))
 	  	 else
 	  	  	 select @Result = convert(nVarChar(100), @Dimension)
 	 end
  else if (@AttribType = 26) -- Status
  begin
    If (@Event_Type = 1) -- Turnups
      Select @Result=Event_Status From Events  Where (Event_Id = @EventId)
    else If (@Event_Type = 2) -- Delay
      Select @Result=TEStatus_Id from timed_event_Details where (TEDet_Id=@EventId)
  end
  else if (@AttribType in (5,6,19,20,33,34)) 
  begin
 	   if (@AttribType = 5) or (@AttribType = 6)  -- PUId or Master PUId
 	  	  	 begin
 	  	  	  	 If (@EventId Is Not NULL) And (@EventId <> 0)
 	  	  	  	  	 Execute @Result = spServer_CmnGetEventPUId @EventId, @Event_Type
 	  	  	 end
 	  	 if (@Event_Type = 1)
 	  	  	 begin
 	  	  	  	 if (@AttribType = 33) -- ProdId
 	  	  	  	  	 begin
  	    	  	  	  	 select @EndTime=Timestamp, @PUId = pu_id from events where event_id = @EventId
  	    	  	  	  	 exec spServer_CmnGetRunningGrade @PUId, @EndTime, 1, @result OUTPUT, @StartId OUTPUT
 	  	  	  	  	 end
 	  	  	  	 else if (@AttribType = 34) -- ProdCode
  	  	  	  	  	 begin
  	    	  	  	  	 select @EndTime=Timestamp, @PUId = pu_id from events where event_id = @EventId
  	    	  	  	  	 exec spServer_CmnGetRunningGrade @PUId, @EndTime, 1, @ProdId OUTPUT, @StartId OUTPUT
  	    	  	  	  	 select @Result=Prod_Code from products where Prod_Id = @ProdId
  	  	  	  	  	 end
 	  	  	 end
 	 end
end
/*
if (@ResultVarId is not null) and (@ResultVarId = 888)
begin
insert into xxx(timestamp,EventId ,Result )  
values (getdate(),@EventId,@result)
end
*/
If @Result Is Null
  Select @Result = ''
