 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_GetAll
		
	This sp returns header info for spLocal_MPWS_PLAN_SetWOStatus
	
	Date			Version		Build	Author  
	02-08-18		001			001		Andrew Drake (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_SetWOStatus]
	@Message VARCHAR(50) OUTPUT,
	@WorkOrder VARCHAR(25),
	@Status VARCHAR(25)
AS

SET NOCOUNT ON;

DECLARE
	@PU_Id INT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@IsKanban INT,
	@RecordCount INT,
	@Event_Id INT,
	@Var_Id INT

SELECT @PU_Id = PU_Id
		FROM Prod_Units_Base
		WHERE Prod_Units_Base.PU_Desc = 'KB-WO'
	
	SELECT @Event_Id = Event_Id
		FROM Events
		WHERE Events.PU_Id = @PU_Id
		  AND Events.Event_Num = @WorkOrder

	IF (SELECT ProdStatus_Desc FROM Production_Status JOIN Events ON Events.Event_Status = Production_Status.ProdStatus_Id WHERE Events.Event_Num = @WorkOrder) = 'CANCELED'
	BEGIN
		Set @Message = 'Status is already Canceled'
	END
	ELSE IF (@Status LIKE 'DISPENSING' OR @Status LIKE 'DISPENSED' OR @Status LIKE 'PENDING' OR @Status LIKE 'RELEASED' OR @Status LIKE 'CANCELED' OR @Status LIKE 'CANCELLED')
	BEGIN
		UPDATE Events SET Event_Status = (SELECT ProdStatus_Id FROM Production_Status WHERE ProdStatus_Desc = @STATUS) WHERE Events.Event_Num = @WorkOrder
		SET @Message = @Workorder + ' status set to ' + @Status
	END
	ELSE
	BEGIN
		SET @Message = 'Status not valid'
	END

	Select @Message AS Message
	
