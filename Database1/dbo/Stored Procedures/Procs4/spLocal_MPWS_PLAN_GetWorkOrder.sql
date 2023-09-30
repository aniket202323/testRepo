 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_GetWorkOrder
		
	This sp returns header info for spLocal_MPWS_PLAN_GetWorkOrder
	
	Date			Version		Build	Author  
	02-10-18		001			001		Don Reinert (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetWorkOrder]
	@Message VARCHAR(50) OUTPUT,
	@MaterialName VARCHAR(25) OUTPUT,
	@GCASNumber VARCHAR(25) OUTPUT,
	@DispenseNum VARCHAR(25) OUTPUT,
	@TargetQty VARCHAR(25) OUTPUT,
	@UpperLimit VARCHAR(25) OUTPUT,
	@LowerLimit VARCHAR(25) OUTPUT,
	@UOM VARCHAR(25) OUTPUT,
	@DispensedQty VARCHAR(25) OUTPUT,
	@Status VARCHAR(25) OUTPUT,
	@DispenseStation VARCHAR(25) OUTPUT,
	@WorkOrder VARCHAR(25)

AS

DECLARE
	@PU_Id INT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@IsKanban INT,
	@RecordCount INT,
	@Event_Id INT,
	@Timestamp DATETIME,
	@Var_Id INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @PU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE Prod_Units_Base.PU_Desc = 'KB-WO'

SELECT @Event_Id = Event_Id,  @Status = ProdStatus_Desc
	FROM Events, Production_Status
	WHERE Events.PU_Id = @PU_Id
	  AND Event_Num = @WorkOrder
	  AND Events.Event_Status = Production_Status.ProdStatus_Id

	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'MaterialName'
	SELECT @MaterialName = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'GCASNumber'
	SELECT @GCASNumber = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id		
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
		  AND Var_Desc = 'TargetQty'
	SELECT @TargetQty = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id									  								
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'UpperLimit'
	SELECT @UpperLimit = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id									  								
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'LowerLimit'
	SELECT @LowerLimit = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id	
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'UOM'
	SELECT @UOM = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id	
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'DispensedQty'
	SELECT @DispensedQty = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id	
		  SELECT @Var_Id = Var_Id 
	FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'DispenseStation'
	SELECT @DispenseStation = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id			  
		  

SET	@Message = 'OK'

END

