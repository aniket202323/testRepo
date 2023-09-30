Create Procedure dbo.spEMFC_GetFTPTransTypes
@User_Id int
AS
select FTT_Id,FTT_Desc from FTP_Transfer_Types
