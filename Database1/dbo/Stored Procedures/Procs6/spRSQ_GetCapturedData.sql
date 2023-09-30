Create Procedure dbo.spRSQ_GetCapturedData
@CId int
AS
Select * From GB_DSet_Data Where DSet_Id = @CId
