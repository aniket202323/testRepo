Create Procedure dbo.spEMFC_GetFTPPostActions 
@User_Id int
AS
select FPA_Id,FPA_Desc from FTP_Post_Actions
