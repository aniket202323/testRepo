CREATE PROCEDURE dbo.spRH_StatusTransitions 
@PU_Id int
AS
--TODO: Fix this based on changes to PrdExec_Trans
/*
Select From_Status, To_Status
  From PrdExec_Trans
  Where PU_Id = @PU_Id
*/
Select From_Status = From_ProdStatus_Id, To_Status = To_ProdStatus_Id
  From PrdExec_Trans 
  Where PU_Id = @PU_Id
