 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_SetWODispensedQty
		
	This sp returns header info for spLocal_MPWS_PLAN_SetWODispensedQty
	
	Date			Version		Build	Author  
	02-08-18		001			001		Andrew Drake (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_SetWODispensedQty]
	@Message VARCHAR(50) OUTPUT,
	@WorkOrder VARCHAR(25),
	@DispensedQty INT
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
	@Timestamp DATETIME,
	@Var_Id INT,
	@DispensedQtyCurrent INT,
	@DispenseNum INT,
	@Status VARCHAR(25)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @PU_Id = PU_Id
		FROM Prod_Units_Base
		WHERE Prod_Units_Base.PU_Desc = 'KB-WO'
	
	SELECT @Event_Id = Event_Id
		FROM Events
		WHERE Events.PU_Id = @PU_Id
		  AND Events.Event_Num = @WorkOrder
		  --AND Production_Status.ProdStatus_Desc in ('Planned','Released','Dispensing')

	SELECT @DispensedQtyCurrent = NULL, @Status = NULL, @DispenseNum = NULL
		
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
			AND Var_Desc = 'DispenseNum'
	SELECT @DispenseNum = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
			AND Event_Id = @Event_Id	
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
			AND Var_Desc = 'DispensedQty'
	SELECT @DispensedQtyCurrent = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
			AND Event_Id = @Event_Id						  

	IF (@DispensedQtyCurrent = 0 AND @DispensedQty <= @DispenseNum)
		-- UPDATE DISPENSED QUANTITY AND CHANGE STATUS TO DISPENSING
		BEGIN
			SELECT @Var_Id = Var_Id FROM Variables_Base WHERE PU_ID = @PU_Id AND Var_Desc = 'DispensedQty'							
			UPDATE Tests SET Result = @DispensedQty	WHERE Var_Id = @Var_Id AND Event_Id = @Event_Id
			UPDATE Events SET Event_Status = (SELECT ProdStatus_Id FROM Production_Status WHERE UPPER(ProdStatus_Desc) = 'DISPENSING') WHERE Events.Event_Num = @WorkOrder
			SET	@Message = 'OK'
		END
	ELSE IF (@DispenseNum <= @DispensedQty)
		-- UPDATE DISPENSED QUANTITY AND CHANGE STATUS TO DISPENSED
		BEGIN
			SELECT @Var_Id = Var_Id FROM Variables_Base WHERE PU_ID = @PU_Id AND Var_Desc = 'DispensedQty'							
			UPDATE Tests SET Result = @DispensedQty	WHERE Var_Id = @Var_Id AND Event_Id = @Event_Id
			UPDATE Events SET Event_Status = (SELECT ProdStatus_Id FROM Production_Status WHERE UPPER(ProdStatus_Desc) = 'DISPENSED') WHERE Events.Event_Num = @WorkOrder
			--Reset Dispense Station now that WO is complete
			SELECT @Var_Id = Var_Id FROM Variables_Base WHERE PU_ID = @PU_Id AND Var_Desc = 'DispenseStation'							
			UPDATE Tests SET Result = '' WHERE Var_Id = @Var_Id AND Event_Id = @Event_Id
			SET	@Message = 'OK'
		END
	ELSE IF (@DispensedQty < @DispenseNum AND @DispensedQty > 0)
		-- UPDATE DISPENSED QUANITTY
		BEGIN
			SELECT @Var_Id = Var_Id FROM Variables_Base WHERE PU_ID = @PU_Id AND Var_Desc = 'DispensedQty'							
			UPDATE Tests SET Result = @DispensedQty	WHERE Var_Id = @Var_Id AND Event_Id = @Event_Id
			SET	@Message = 'OK'
		END
	ELSE
		SET @Message = 'Dispensed Quantity Exceeds Target WO Dispense'

	Select @Message AS Message
			
END

