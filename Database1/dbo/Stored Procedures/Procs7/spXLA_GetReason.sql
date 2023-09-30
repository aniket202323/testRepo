Create Procedure dbo.spXLA_GetReason
@ReasonName varchar(100)
AS
Select Reason_ID = Event_Reason_Id
  From Event_Reasons
  Where Event_Reason_Name = @ReasonName
