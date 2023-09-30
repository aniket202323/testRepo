CREATE PROCEDURE [dbo].[spS88R_SaveProcedureSelections]
@AnalysisId int,
@Command int,
@Procedure nVarChar(50) = null,
@Operation nVarChar(50) = null,
@Phase nVarChar(50) = null
AS
IF @Command = 0 
  BEGIN
    -- Erase All with the AnalysisId
    DELETE FROM  batch_procedure_selections WHERE Analysis_Id = @AnalysisId
    GOTO endPlace
  END
-- Insert into the dataBase
INSERT INTO batch_procedure_selections
(Analysis_Id, Unit_Procedure, Operation, Phase)
VALUES
(@AnalysisId,@Procedure,@Operation,@Phase)
endPlace:
