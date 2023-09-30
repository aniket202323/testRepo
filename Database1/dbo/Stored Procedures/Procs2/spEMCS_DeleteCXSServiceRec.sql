Create Procedure dbo.spEMCS_DeleteCXSServiceRec
@Desc nvarchar(50)
as
delete from CXS_Service where Service_Desc = @Desc
