CREATE procedure [dbo].[spSDK_Esig_GetInfo_Bak_177]
 	 @ProductAId int,
 	 @ProductBId int,
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
declare @prodESigLevel int
if (@ProductBId is not null) -- this is a product change event
  begin
    Select @prodESigLevel = Max(Product_Change_ESignature_Level) from Products where Prod_Id in (@ProductAId, @ProductBId)
  end
else
  begin
    Select @prodESigLevel = Event_ESignature_Level from Products where Prod_Id = @ProductAId
  end
if (@prodESigLevel is null) or (@prodESigLevel = 0)
  return(1)
set @ESigLevel = @prodESigLevel
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
  end
Return(1)
