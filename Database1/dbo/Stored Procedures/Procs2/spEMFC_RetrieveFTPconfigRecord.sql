Create Procedure dbo.spEMFC_RetrieveFTPconfigRecord 
@ID int,
@User_Id int
AS
select * from FTP_Config where FC_Id = @ID
