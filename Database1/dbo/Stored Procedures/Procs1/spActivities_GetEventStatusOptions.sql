
CREATE PROCEDURE dbo.spActivities_GetEventStatusOptions
@PUId				Int

 AS

BEGIN
		Select StatusId = s.ProdStatus_Id, Status = s.ProdStatus_Desc
		  from PrdExec_Status pes
		  join Production_Status s on s.ProdStatus_Id = pes.Valid_Status
		  where pes.PU_Id = @PUId ORDER BY s.ProdStatus_Desc
		  
END

