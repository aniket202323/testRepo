
CREATE PROCEDURE [dbo].[spPS_UpdateMaterialLots]  
@UserId int,    
@LotIdentifier nvarchar(100),  
@StatusId int,  
@EventId int             
  
  AS  
DECLARE @TimeStamp DateTime , 
@event_id int
   
BEGIN TRANSACTION   
  
SELECT @TimeStamp = CURRENT_TIMESTAMP; 
DECLARE @UnitId int

set @event_id=@EventId

--Get UnitId 
SELECT @UnitId = pu_id from events where event_id = @EventId

SELECT
		@EventId = event_id
	FROM Events
	WHERE event_num =@LotIdentifier and PU_ID=@UnitId;

if @EventId IS NULL
BEGIN
    -- Rollback the transaction
    ROLLBACK
    -- Raise an error and return
    RAISERROR ('Error in update events table.', 16, 1)
    RETURN
END

--validate status Id
if not exists (select prodstatus_id from production_status where prodstatus_id=@StatusId)
BEGIN
	 ROLLBACK
    -- Raise an error and return
	select Error = 'Status Id is not exist.'
	  RETURN @@ERROR
END

if @EventId <> @event_id 
	BEGIN
	 ROLLBACK
    -- Raise an error and return
	select Error = 'Lot identifier already exist with unit.'
	  RETURN @@ERROR
END


-- Temporary table to store result set.
CREATE  TABLE #resultSet
(
	RSType int,
	VarId int,
	PUId int,
	UserId int,
	Canceled int,
	Result nVarchar(50),
	ResultOn datetime,
	TransType int,
	PostDB int,
	SecondUserId int,
	TransNum int,
	EventId int,
	ArrayId int,
	CommentId int, 
	EsigId int,
	EntryOn datetime,
	TestId int,
	ShouldArchive bit,
	HasHistory bit,
	IsLocked bit
)



INSERT into #resultSet
execute spServer_DBMgrUpdEvent  
@EventId,  
@LotIdentifier,  
@UnitId,  
@TimeStamp,  
null,  
null,  
@StatusId,  
2,  
0,  
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



IF @EventId IS NOT NULL
BEGIN
    UPDATE events
    SET lot_identifier = @LotIdentifier
    WHERE event_id = @EventId;
END

IF @@ERROR <> 0
BEGIN
    -- Rollback the transaction
    ROLLBACK
    -- Raise an error and return
    RAISERROR ('Error in update events table.', 16, 1)
    RETURN @@ERROR
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

