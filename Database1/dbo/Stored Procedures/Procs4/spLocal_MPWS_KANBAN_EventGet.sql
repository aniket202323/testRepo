
CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_EventGet]
	@Message VARCHAR(50) OUTPUT,
	@GCASNumber VARCHAR(25) OUTPUT,
	@LocationCode VARCHAR(25) OUTPUT,
	@MaterialName VARCHAR(25) OUTPUT,
	@CriticalContainerCnt VARCHAR(25) OUTPUT,
	@MaxContainerCnt VARCHAR(25) OUTPUT,
	@RefillContainerCnt VARCHAR(25) OUTPUT,
	@WeightSetpoint VARCHAR(25) OUTPUT,
	@Quantity VARCHAR(25) OUTPUT,
	@UOM VARCHAR(25) OUTPUT,
	@KanbanID VARCHAR(25)

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
	WHERE PU_Desc = @KanbanID

IF (@PU_Id IS NULL)
	BEGIN
		SET @Message = 'Invalid Kanban'
	END
ELSE
	BEGIN
		SELECT @TableFieldId = Table_Field_Id, @TableID = tf.TableId
			FROM Table_Fields tf, Tables t
			WHERE t.TableName = 'Prod_Units'
			  AND t.TableId = tf.TableId
			  AND tf.Table_Field_Desc = 'Kanban'
		SELECT @Value = Value
			FROM Table_Fields_Values
			WHERE Table_Field_Id = @TableFieldId
			  AND TableId = @TableId
			  AND KeyID = @PU_Id
		IF (@Value IS NULL)
			BEGIN
				SET @Message = 'PU Property of Kanban not set'
			END
		ELSE
			BEGIN
				SELECT @IsKanban = Value 
					FROM Table_Fields_Values tfv,Table_Fields tf, Tables t
					WHERE tfv.KeyId = @PU_Id
					  AND tfv.TableId = t.TableId
					  AND t.TableName = 'Prod_Units'
					  AND tfv.Table_Field_Id = tf.Table_Field_Id
					  AND tf.Table_Field_Desc = 'Kanban'
				IF (@IsKanban < 1)
					BEGIN
						SET @Message = 'Kanban is inactive'
					END
				ELSE
					BEGIN
						SELECT @Event_Id = MAX(Event_Id)
						   FROM Events
						   WHERE PU_Id = @PU_Id
						     AND Event_Status = 9
						IF (@Event_Id IS NULL)
							BEGIN
								SET @Message = 'Kanban has no events with Inventory status'
							END
						ELSE
							BEGIN
								SET @Message = 'Okay'
								SELECT @Var_Id = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'Quantity'
								SELECT @Quantity = Result
									FROM Tests
									WHERE Var_Id = @Var_Id
									  AND Event_Id = @Event_Id
								SELECT @Var_Id = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'LocationCode'
								SELECT @LocationCode = Result
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
									  AND Var_Desc = 'GCASNumber'
								SELECT @GCASNumber = Result
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
							END
					END
			END
		
	END


END





