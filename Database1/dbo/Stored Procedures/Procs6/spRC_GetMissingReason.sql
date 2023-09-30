Create Procedure dbo.spRC_GetMissingReason
@Event_Reason_Id int,
@Event_Reason_Name nvarchar(100) OUTPUT
AS
select @Event_Reason_Name = Event_Reason_Name
   From Event_Reasons
   Where Event_Reason_Id = @Event_Reason_Id
