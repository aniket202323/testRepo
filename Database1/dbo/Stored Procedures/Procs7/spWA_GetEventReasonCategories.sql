CREATE procedure [dbo].[spWA_GetEventReasonCategories]
AS
Select ERC_Id 'Id', ERC_Desc 'Description'
From Event_Reason_Catagories
Where ERC_Id <> 100 --Exclude reserved space
