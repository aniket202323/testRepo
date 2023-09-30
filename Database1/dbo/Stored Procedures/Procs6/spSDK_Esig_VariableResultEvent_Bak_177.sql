CREATE procedure [dbo].[spSDK_Esig_VariableResultEvent_Bak_177]
 	 @VariableId int,
 	 @EventId int,
 	 @ResultOn datetime,
 	 @ESigLevel int output,
 	 @MaxLoginAttempts int output,
 	 @InactivityPeriod int output,
 	 @RequireAuthentication bit output,
 	 @UserDefaultReasonId int output,
 	 @ApproverDefaultReasonId int output
AS
set @ESigLevel = 0
set @MaxLoginAttempts = 3
set @InactivityPeriod = null
set @RequireAuthentication = 1
set @UserDefaultReasonId = null
set @ApproverDefaultReasonId = null
if (@VariableId is null) or (@VariableId <= 0)
 	 return(1)
if (@ResultOn is null)
 	 return(1)
declare @PUId int
declare @EventType int
declare @VarESigLevel int
declare @SpecESigLevel int
declare @ProdId int
declare @ProdBId int
declare @S95Id uniqueidentifier
Select @EventType = Event_Type, @PUId = PU_Id, @VarESigLevel = Esignature_Level from Variables_Base as Variables where Var_Id = @VariableId
if (@EventId is not null)
  begin
    if (@EventType = 1) -- Production
      Select @PUId = PU_Id, @ProdBId = Applied_Product from Events where Event_Id = @EventId
    if (@EventType = 2) -- Downtime
      Select @PUId = PU_Id from Timed_Event_Details where TEDet_Id = @EventId
    if (@EventType = 3) -- Waste
      Select @PUId = PU_Id from Waste_Event_Details where WED_Id = @EventId
    if (@EventType = 4) or (@EventType = 5) -- Product Change or Product/Time
      Select @PUId = PU_Id, @ProdId = Prod_Id from Production_Starts where Start_Id = @EventId
    if (@EventType = 14) -- User-Defined Event
      Select @PUId = PU_Id from User_Defined_Events where UDE_Id = @EventId
    if (@EventType = 31) -- Segment Response
      begin
        Select @S95Id = S95_Guid from S95_Event where Event_Id = @EventId
        select @PUId = dbo.fnServer_CmnGetSegRespUnit(@S95Id)
      end
    if (@EventType = 32) -- Work Response
      begin
        Select @S95Id = S95_Guid from S95_Event where Event_Id = @EventId
        select @PUId = dbo.fnServer_CmnGetWorkRespUnit(@S95Id)
      end
    if (@EventType = 19) or (@EventType = 28) -- Process Order or Process Order/Time
      Select @PUId = pps.PU_Id, @ProdId = pp.Prod_Id
        from Production_Plan_Starts pps
        join Production_Plan pp on pp.PP_Id = pps.PP_Id 
        where pps.PP_Start_Id = @EventId
    if (@EventType = 10) -- Genealogy
      Select @PUId = e.PU_Id, @ProdBId = e.Applied_Product
        from Event_Components ec
        join Events e on e.Event_Id = ec.Event_Id
        where ec.Component_Id = @EventId
  end
if (@ProdId is null) and (@PUId is not null)
  Select @ProdId = Prod_Id from Production_Starts where PU_Id = @PUId and Start_Time <= @ResultOn and (End_Time is null or End_Time > @ResultOn)
if (@ProdBId is not null)
  Set @ProdId = @ProdBId
if (@ProdId is null)
  return(1)
select @SpecESigLevel = ESignature_Level from Var_Specs where Var_Id = @VariableId and Prod_Id = @ProdId
if (@SpecESigLevel is not null)
  Set @ESigLevel = @SpecESigLevel
else if (@VarESigLevel is not null)
  Set @ESigLevel = @VarESigLevel
if (@ESigLevel is null) or (@ESigLevel = 0)
  return(1)
if (@ESigLevel = 1)
  begin
    select @InactivityPeriod = Value from Site_Parameters where parm_id = 70
    select @RequireAuthentication = Value from Site_Parameters where parm_id = 74
  end
select @MaxLoginAttempts = Value from Site_Parameters where parm_id = 1
select @UserDefaultReasonId = Value from Site_Parameters where parm_id = 441
if (@ESigLevel = 2)
  begin
    select @ApproverDefaultReasonId = Value from Site_Parameters where parm_id = 439
    declare @GroupId int
    select @GroupId = Group_Id from Variables_Base as Variables where Var_Id = @VariableId
  end
select * from dbo.fnSDK_Esig_GetItemLists(@ESigLevel, @GroupId)
Return(1)
