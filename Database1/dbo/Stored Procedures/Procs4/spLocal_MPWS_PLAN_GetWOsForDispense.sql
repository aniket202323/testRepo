 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_GetAll
		
	This sp returns header info for [spLocal_MPWS_PLAN_GetWOsForDispense]
	
	Date			Version		Build	Author  
	02-08-18		001			001		Andrew Drake (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetWOsForDispense]
	@Message VARCHAR(50) OUTPUT,
	@WorkOrder VARCHAR(25) OUTPUT,
	@MaterialName VARCHAR(25) OUTPUT,
	@GCASNumber VARCHAR(25) OUTPUT,
	@DispenseNum VARCHAR(25) OUTPUT,
	@TargetQty VARCHAR(25) OUTPUT,
	@UpperLimit VARCHAR(25) OUTPUT,
	@LowerLimit VARCHAR(25) OUTPUT,
	@UOM VARCHAR(25) OUTPUT,
	@DispensedQty VARCHAR(25) OUTPUT,
	@Status VARCHAR(25) OUTPUT,
	@DispenseStation VARCHAR(25) OUTPUT
AS

SET NOCOUNT ON;

DECLARE @WO_Local TABLE (
		ID						INT IDENTITY(1,1),
		Event_Id				INT,
		WorkOrder				VARCHAR(25) ,
		MaterialName			VARCHAR(25) ,
		GCASNumber				VARCHAR(25) ,
		DispenseNum				VARCHAR(25) ,
		TargetQty				VARCHAR(25) ,
		UpperLimit				VARCHAR(25) ,
		LowerLimit				VARCHAR(25) ,
		UOM						VARCHAR(25) ,
		DispensedQty			VARCHAR(25) ,
		Status					VARCHAR(25) ,
		DispenseStation		VARCHAR(25)
)

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
	@CountWO INT,
	@CurrentWO INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT @PU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE Prod_Units_Base.PU_Desc = 'KB-WO'

INSERT INTO @WO_Local (Event_Id, WorkOrder, Status)
	SELECT Event_Id, Event_Num, ProdStatus_Desc
	FROM Events, Production_Status
	WHERE Events.PU_Id = @PU_Id
	  AND Events.Event_Status = Production_Status.ProdStatus_Id
	  AND Production_Status.ProdStatus_Desc in ('Released','Dispensing')

SELECT @CountWO = MAX(ID) 
	FROM @WO_Local

SELECT @CurrentWO = 0
WHILE (@CurrentWO <= @CountWO)
BEGIN
	SET @CurrentWO = @CurrentWO + 1
	SELECT @WorkOrder = NULL, @MaterialName = NULL, @GCASNumber = NULL,
		@DispenseNum = NULL, @TargetQty = NULL, @UpperLimit = NULL, @LowerLimit = NULL, @Status = NULL, @UOM = NULL, @DispensedQty = NULL, @DispenseStation = NULL
		
	SELECT @Event_Id = Event_Id
		FROM @WO_Local
		WHERE ID = @CurrentWO

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

	UPDATE @WO_Local SET MaterialName = @MaterialName,
							GCASNumber = @GCASNumber, 
							DispenseNum = @DispenseNum, 
							TargetQty = @TargetQty, 
							UpperLimit = @UpperLimit, 
							LowerLimit = @LowerLimit,
							UOM = @UOM,
							DispensedQty = @DispensedQty,
							DispenseStation = @DispenseStation
		WHERE Event_Id = @Event_Id


END
SET	@Message = 'OK'

SELECT WorkOrder, MaterialName, GCASNumber, DispenseNum, TargetQty, UpperLimit, LowerLimit, UOM, DispensedQty, Status, DispenseStation from @WO_Local


SET	@Message = 'OK'

END

