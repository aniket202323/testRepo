CREATE procedure [dbo].[sps88R_BatchSubUnits]
  @MainBatchUnit int
  AS 
Select Distinct pu.pu_Id,pu.PU_Desc 
From PrdExec_Input_Sources pis
JOIN PrdExec_Inputs pei on pei.PEI_Id = pis.PEI_Id
Join Prod_Units pu on pu.PU_Id = pei.pu_Id
Join Event_Configuration ec on ec.PU_Id = pei.PU_Id and ET_Id = 1 and ec.ED_Model_Id = 100
Where pis.PU_Id = @MainBatchUnit
