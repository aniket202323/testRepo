CREATE procedure [dbo].[spSDK_Esig_ProductChangeEvent]
 	 @ProductionUnitId int,
 	 @TimeStamp datetime,
 	 @ProductId int,
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
if (@ProductionUnitId is null) or (@ProductionUnitId <= 0)
 	 return(1)
if (@TimeStamp is null)
 	 return(1)
declare @ProdId int
Select @ProdId = Prod_Id from Production_Starts where PU_Id = @ProductionUnitId and Start_Time <= @TimeStamp and (End_Time is null or End_Time > @TimeStamp)
if (@ProdId is null)
  return(1)
exec spSDK_Esig_GetInfo @ProdId, @ProductId, @ESigLevel output, @MaxLoginAttempts output, @InactivityPeriod output, @RequireAuthentication output, @UserDefaultReasonId output, @ApproverDefaultReasonId output
if (@ESigLevel = 2)
  begin
    declare @GroupId int
    select @GroupId = Group_Id from Prod_Units_Base where PU_Id = @ProductionUnitId
  end
select * from dbo.fnSDK_Esig_GetItemLists(@ESigLevel, @GroupId)
Return(1)
