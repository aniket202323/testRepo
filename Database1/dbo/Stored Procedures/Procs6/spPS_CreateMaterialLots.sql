
CREATE PROCEDURE [dbo].[spPS_CreateMaterialLots]
@UserId int,
@ProdutId int,
@UnitId int,
@LotIdentifier nvarchar(100),
@StatusId int,
@InitialQuantity float           

  AS
DECLARE @EventId Int,
        @TimeStamp DateTime,
        @CountStatus int
        
select @CountStatus = count(*) from production_status where ProdStatus_Id=@StatusId
IF @CountStatus = 0
	  SELECT Error = 'Status id not exists.','EPS1111' as Code
	  
      
SELECT @TimeStamp = CURRENT_TIMESTAMP;

BEGIN TRANSACTION 

execute spServer_DBMgrUpdEvent
null,
@LotIdentifier,
@UnitId,
@TimeStamp,
@ProdutId,
null,
@StatusId,
1,
null,
@UserId,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null
   
SELECT
		@EventId = event_id
	FROM Events
	WHERE event_num =@LotIdentifier and PU_ID=@UnitId;
if @EventId IS NULL
BEGIN
    -- Rollback the transaction
    ROLLBACK
    -- Raise an error and return
    RAISERROR ('Error in update event_details table.', 16, 1)
    RETURN
END
	IF @EventId IS NOT NULL
BEGIN
    UPDATE events
    SET lot_identifier = @LotIdentifier
    WHERE event_id = @EventId;
END
BEGIN
insert into event_details(event_id,pu_id,initial_dimension_x,final_dimension_x) values (@EventId,@UnitId,@InitialQuantity,@InitialQuantity);
END

IF @@ERROR <> 0
BEGIN
    -- Rollback the transaction
    ROLLBACK
    -- Raise an error and return
    RAISERROR ('Error in update event_details table.', 16, 1)
    RETURN
END

COMMIT;

select e.event_Id,
			    e.applied_product,
			    CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as event_num,
			    e.pu_id,
			    ed.initial_dimension_x,
			    ed.final_dimension_x,
			    e.event_status,
			    0 as totalRecords,
			    CAST(CASE WHEN (ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1 and ed.final_dimension_x > 0) THEN 1 ELSE 0 END AS BIT) availableForConsumption,
			    es.Dimension_X_Eng_Unit_Id,
			    ed.pp_id				 
		from events e
		inner join event_details ed on e.event_id = ed.event_id
		left join Production_Status ps on e.event_status=ps.ProdStatus_Id
		left join Event_Configuration ec on ec.PU_ID =e.PU_ID and ec.ET_ID = 1
		left join Event_Subtypes es on es.Event_Subtype_id=ec.Event_Subtype_Id
		where e.event_id=@EventId;

