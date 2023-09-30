CREATE PROCEDURE [dbo].[spRIS_UpdateProductionEventQuantity]
  @EventId                              int,
  @quantity                             float
  
AS


DECLARE @EventStatusId int

BEGIN TRANSACTION
------------------------------------------------------------------------------------------------------------------------------
-- Fast validations - Stuff that doesn't hit the DB
------------------------------------------------------------------------------------------------------------------------------
if (@EventId is null)
Begin;
      select Error = 'Must provide a Event Id.'
         Rollback Transaction 
         RETURN @@ERROR
End;

if(@quantity is null) 
Begin;
         select Error = 'Must provide a quantity.'
         Rollback Transaction 
         RETURN @@ERROR
End;

if(@quantity <= 0) 
Begin;
         select Error = 'Quantity should be a positive value.'
         Rollback Transaction 
         RETURN @@ERROR
End;

if not exists (select event_id from events where event_id=@EventId)
Begin;
      select Error = 'Event Id does not exists.'         
         Rollback Transaction
         RETURN @@ERROR
End;

------------------------------------------------------------------------------------------------------------------------------
-- Event Status Lookup
-- Note: Update only when the status is "unassigned"
------------------------------------------------------------------------------------------------------------------------------
SELECT @EventStatusId = event_status from events E
JOIN  production_status PS ON PS.prodStatus_Id  = E.Event_Status
where event_id=@EventId and ProdStatus_Desc In ('unassigned')

if(@EventStatusId is NULL)
Begin
             select Error = 'Invalid Event Status.'     
         Rollback Transaction
         RETURN @@ERROR
End;


------------------------------------------------------------------------------------------------------------------------------
-- Update initial_dimension_x && final_dimension_x of the event  
------------------------------------------------------------------------------------------------------------------------------


update event_Details set initial_dimension_x = @quantity, final_dimension_x = @quantity where event_id = @EventId 


COMMIT transaction



SELECT E.event_id, E.Event_Num, ED.Initial_Dimension_X, ED.Final_Dimension_X
from Events E
JOIN Event_Details ED on ED.Event_id = E.Event_id
WHERE E.Event_id = @EventId

