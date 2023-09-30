CREATE PROCEDURE [dbo].[spASP_appEventAnalysisUnitInfo]
  @UnitId INT
AS
SELECT PU_Desc
FROM Prod_Units
WHERE PU_Id = @UnitId
