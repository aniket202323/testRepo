
CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_GetAll]
	@Message VARCHAR(50) OUTPUT,
	@Kanban VARCHAR(25) OUTPUT,
	@GCASNumber VARCHAR(25) OUTPUT,
	@MaterialName VARCHAR(50) OUTPUT,
	@CriticalContainerCnt VARCHAR(25) OUTPUT,
	@MaxContainerCnt VARCHAR(25) OUTPUT,
	@RefillContainerCnt VARCHAR(25) OUTPUT,
	@WeightSetpoint VARCHAR(25) OUTPUT,
	@Quantity VARCHAR(25) OUTPUT,
	@Active VARCHAR(25) OUTPUT,
	@Event_Status VARCHAR(25) OUTPUT,
	@UOM VARCHAR(25) OUTPUT

AS

SET NOCOUNT ON;

DECLARE @PU_Id_Local TABLE (
		ID						INT IDENTITY(1,1),
		PU_Id					INT,
		Kanban					VARCHAR(25) ,
		Event_id				INT,
		GCASNumber				VARCHAR(25) ,
		MaterialName			VARCHAR(50) ,
		CriticalContainerCnt	VARCHAR(25) ,
		MaxContainerCnt			VARCHAR(25) ,
		RefillContainerCnt		VARCHAR(25) ,
		WeightSetpoint			VARCHAR(25) ,
		Inventory				VARCHAR(25) ,
		Active					VARCHAR(25) ,
		Event_Status			VARCHAR(25) ,
		UOM						VARCHAR(25)
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
	@CountPUId INT,
	@CurrentId INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

INSERT INTO @PU_Id_Local (PU_Id)
	SELECT pub.PU_ID 
	FROM Prod_Units_Base pub, Table_Fields tf, Tables t, Table_Fields_Values tfv
	WHERE t.TableName = 'Prod_Units'
	  AND t.TableId = tf.TableId
	  AND tf.Table_Field_Desc = 'Kanban'
	  AND tf.Table_Field_Id = tfv.Table_Field_Id
	  AND tf.TableId = tfv.TableId
	  AND tfv.KeyID = pub.PU_Id

SELECT @CountPUId = MAX(ID) 
	FROM @PU_Id_Local

SELECT @CurrentId = 0
WHILE (@CurrentId < @CountPUId)
BEGIN
	SET @CurrentId = @CurrentId + 1
	SELECT @Kanban = NULL, @Event_Id = NULL, @Event_Status = NULL, @Quantity = NULL, @GCASNumber = NULL, 
		@MaterialName = NULL, @CriticalContainerCnt = NULL,
		@MaxContainerCnt = NULL, @RefillContainerCnt = NULL, @WeightSetpoint = NULL, @Active = NULL
		
	SELECT @PU_Id = PU_id
		FROM @PU_Id_Local
		WHERE ID = @CurrentId
	SELECT @Kanban = PU_Desc
		FROM Prod_Units_Base
		WHERE PU_Id = @PU_Id
	SELECT @Event_Id = MAX(Event_Id)
		FROM Events
		WHERE PU_Id = @PU_Id
	SELECT @Event_Status = CASE WHEN Event_Status = 9 THEN 'INVENTORY' ELSE 'UNUSED' END
		FROM Events
		WHERE Event_Id = @Event_Id
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'Quantity' -- QUANTITY IS INVENTORY
	SELECT @Quantity = Result
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
		  AND Var_Desc = 'MaterialName'
	SELECT @MaterialName = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id						  
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'CriticalContainerCnt'
	SELECT @CriticalContainerCnt = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id									  								
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'MaxContainerCnt'
	SELECT @MaxContainerCnt = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id									  								
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'RefillContainerCnt'
	SELECT @RefillContainerCnt = Result
		FROM Tests
		WHERE Var_Id = @Var_Id
		  AND Event_Id = @Event_Id									  								
	SELECT @Var_Id = Var_Id 
		FROM Variables_Base
		WHERE PU_ID = @PU_Id
		  AND Var_Desc = 'WeightSetpoint'
	SELECT @WeightSetpoint = Result
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
	SELECT @Active = Value 
		FROM Table_Fields_Values tfv,Table_Fields tf, Tables t
		WHERE tfv.KeyId = @PU_Id
		  AND tfv.TableId = t.TableId
		  AND t.TableName = 'Prod_Units'
		  AND tfv.Table_Field_Id = tf.Table_Field_Id
		  AND tf.Table_Field_Desc = 'Kanban'
	UPDATE @PU_Id_Local SET Kanban = @Kanban,
							Event_id = @Event_Id, 
							GCASNumber = @GCASNumber, 
							MaterialName = @MaterialName, 
							CriticalContainerCnt = @CriticalContainerCnt, 
							MaxContainerCnt = @MaxContainerCnt, 
							RefillContainerCnt = @RefillContainerCnt, 
							WeightSetpoint = @WeightSetpoint, 
							Inventory = @Quantity, 
							Active = @Active, 
							Event_Status = @Event_Status,
							UOM = @UOM
		WHERE PU_Id = @PU_id


END
SET	@Message = 'OK'

SELECT * from @PU_Id_Local




END





