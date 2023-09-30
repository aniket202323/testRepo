CREATE PROCEDURE [dbo].[spPS_GetMaterialLotTraceability]
@materialLotId		Int  = Null
AS
     BEGIN
			select e.event_Id,
			       CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as event_num,
			       e.pu_id,
			       ed.initial_dimension_x,
			       ed.final_dimension_x,
			       e.event_status,
				    0 as totalRecords,
			       ed.pp_id
				from events e
					inner join event_details ed on e.event_id=ed.event_id
					where
					e.event_id=@materialLotId
END
	

