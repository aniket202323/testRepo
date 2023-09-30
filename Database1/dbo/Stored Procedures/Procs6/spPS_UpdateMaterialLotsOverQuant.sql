
CREATE PROCEDURE [dbo].[spPS_UpdateMaterialLotsOverQuant]    
@EventId int,
@ExistingInitialQuantity float,
@NewInitialQuantity float,
@ExistingFinalQuantity float,
@NewFinalQuantity float,
@UserId int
  
  AS  
  DECLARE @DBInitialQuantity float = 0,
          @DBFinalQuantity float = 0

SELECT @DBInitialQuantity = initial_dimension_x, @DBFinalQuantity = final_dimension_x FROM Event_details
   	 WHERE event_id=@EventId;

   if(@DBInitialQuantity!=@ExistingInitialQuantity)
   BEGIN
	    SELECT Error = 'ExistingInitialQuantity is invalid not matched with InitialQuantity', 'EPS1114' as Code
	    RETURN 
   END
   
   if(@DBFinalQuantity!=@ExistingFinalQuantity)
   BEGIN
	     SELECT Error = 'ExistingFinalQuantity is invalid not matched with FinalQuantity', 'EPS1115' as Code
	    RETURN 
   END
       
   
BEGIN TRANSACTION   


 EXECUTE spServer_DBMgrUpdEventDet @UserId,
                                      @EventId,
                                      NULL,
                                      NULL,
                                      1,
                                      101,
                                      NULL,
                                      NULL,
                                      @NewInitialQuantity,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL 


EXECUTE spServer_DBMgrUpdEventDet @UserId,
                                      @EventId,
                                      NULL,
                                      NULL,
                                      1,
                                      105,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      @NewFinalQuantity,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL

COMMIT;

select e.event_Id as EventId,  
       ed.initial_dimension_x,  
       ed.final_dimension_x
  from events e  
  inner join event_details ed on e.event_id = ed.event_id  
  left join Production_Status ps on e.event_status=ps.ProdStatus_Id  
  left join Event_Configuration ec on ec.PU_ID =e.PU_ID and ec.ET_ID = 1  
  left join Event_Subtypes es on es.Event_Subtype_id=ec.Event_Subtype_Id  
  where e.event_id=@EventId;

