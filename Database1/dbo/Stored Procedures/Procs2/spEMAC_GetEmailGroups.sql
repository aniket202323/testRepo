Create Procedure dbo.spEMAC_GetEmailGroups
@User_Id int
AS
Declare @Insert_Id int
Select EG_Id, EG_Desc 
FROM Email_Groups
WHERE EG_Id <> 50
Order By EG_Desc
