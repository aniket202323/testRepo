CREATE PROCEDURE [dbo].[sps88r_SaveBatchList]
@AnalysisId int,
@Command int,
@BatchEventId int = 0,
@EventId int = 0,
@UnitId Int = 0,
@Selected bit = 0 ,
@Checked bit = 0
AS
IF @Command = 0 
  BEGIN
    -- Erase All with the AnalysisId
    DELETE FROM  batch_results_selections WHERE Analysis_Id = @AnalysisId
    GOTO endPlace
  END
ELSE
  BEGIN
    -- Insert into the dataBase    
    INSERT INTO Batch_Results_Selections 
    (Analysis_Id, Batch_Event_Id, Event_Id, PU_Id,Selected, Checked)
    VALUES
    (@AnalysisId, @BatchEventId, @EventId, @UnitId, @Selected, @Checked)
  END
endPlace:
