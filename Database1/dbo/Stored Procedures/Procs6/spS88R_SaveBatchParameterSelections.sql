CREATE PROCEDURE [dbo].[spS88R_SaveBatchParameterSelections]
@AnalysisId int,
@Command int,
@Procedure nVarChar(50) = null,
@ParameterName nVarChar(50) = null, 
@VarId INT = null
AS
IF @Command = 0 
  BEGIN
    -- Erase All with the AnalysisId
    DELETE FROM  Batch_Unit_Parameter_Selections WHERE Analysis_Id = @AnalysisId
    GOTO endPlace
  END
-- Insert into the dataBase
INSERT INTO Batch_Unit_Parameter_Selections
(Analysis_Id, Unit_Procedure, ParameterName, Var_Id)
VALUES
(@AnalysisId,@Procedure,@ParameterName, @VarId)
endPlace:
