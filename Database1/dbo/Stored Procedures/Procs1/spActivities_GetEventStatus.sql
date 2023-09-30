
CREATE PROCEDURE dbo.spActivities_GetEventStatus
@PUId				Int,
@CurrentStatusId	Int = null

 AS 

if @CurrentStatusId is null
	Begin
		Select StatusId = s.ProdStatus_Id, Status = s.ProdStatus_Desc
		  from PrdExec_Status pes
		  join Production_Status s on s.ProdStatus_Id = pes.Valid_Status
		  where pes.PU_Id = @PUId and pes.Is_Default_Status = 1
		  order by s.ProdStatus_Desc
	End
Else
	Begin
		Select StatusId = s.ProdStatus_Id, Status = s.ProdStatus_Desc
		  from PrdExec_Trans t
		  join Production_Status s on s.ProdStatus_Id = t.To_ProdStatus_Id
		  where t.PU_Id = @PUId and t.From_ProdStatus_Id = @CurrentStatusId
		  order by s.ProdStatus_Desc
	End

