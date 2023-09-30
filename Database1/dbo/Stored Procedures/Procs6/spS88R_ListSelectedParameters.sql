CREATE procedure [dbo].[spS88R_ListSelectedParameters]
@AnalysisId int
AS
select * from batch_parameter_selections WHERE Analysis_Id = @AnalysisId
