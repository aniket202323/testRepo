
CREATE PROCEDURE dbo.spPS_UpdWorkOrderEventComponents
@ComponentId int,
@BOMItemId int,
@SegmentId int,
@WorkOrderId int,
@WOComponentId int = null OUTPUT

  AS
BEGIN 

	INSERT INTO WorkOrder_Event_Components(Component_Id,BOM_Item_Id,Segment_Id,Work_Order_Id)
			select @ComponentId,@BOMItemId,@SegmentId,@WorkOrderId
			Where not exists (select 1 from WorkOrder_Event_Components where Component_Id = @ComponentId and BOM_Item_Id = @BOMItemId)

			Select @WOComponentId = Scope_Identity()

			IF @WOComponentId Is Null
			BEGIN
				SELECT  Error = 'ERROR: Valid Inputs Required to insert record in WorkOrder_Event_Components'
				RETURN
			END
END
