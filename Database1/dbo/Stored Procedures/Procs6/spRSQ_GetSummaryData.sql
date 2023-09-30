Create Procedure dbo.spRSQ_GetSummaryData
@RId int
AS
Select * From GB_RSum_Data Where RSum_Id = @RId
