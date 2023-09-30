CREATE PROCEDURE [dbo].[spS88R_SaveParameterSelections]
@AnalysisId int,
@Command int,
@Procedure nVarChar(50) = null,
@Operation nVarChar(50) = null,
@Phase nVarChar(50) = null,
@ParameterName nVarChar(50) = null
AS
IF @Command = 0 
  BEGIN
    -- Erase All with the AnalysisId
    DELETE FROM  batch_Parameter_selections WHERE Analysis_Id = @AnalysisId
    GOTO endPlace
  END
-- Insert into the dataBase
INSERT INTO batch_Parameter_selections
(Analysis_Id, Unit_Procedure, Operation, Phase,ParameterName)
VALUES
(@AnalysisId,@Procedure,@Operation,@Phase,@ParameterName)
endPlace:
