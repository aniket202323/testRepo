CREATE PROCEDURE [dbo].[spS88R_LoadBatchTrendOptions]
  @Analysis_Id INT
AS
SELECT [Name], [Description], Group_Id, Saved_By,
       Saved_On, Source, Version, Parameters
FROM batch_analysis s
WHERE Analysis_Id = @Analysis_Id
