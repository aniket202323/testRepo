Create Procedure dbo.spWA_GetComments
@WEDId int
AS
Select Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id 
From Waste_Event_Details D  WITH (NOLOCK)
Where D.WED_Id = @WEDId
