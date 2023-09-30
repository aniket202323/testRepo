

CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_Activate]
	@Message VARCHAR(25) OUTPUT,
	@KanbanID VARCHAR(25),
	@Activate INT

AS

DECLARE
	@Event_Id INT,
	@PU_Id INT,
	@Quantity VARCHAR(25),
	@QtyFloat FLOAT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@VarId INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF (@Activate > 0)
	BEGIN
		SET @Activate = 1
	END
ELSE
	BEGIN
		SET @Activate = 0
	END

SELECT @PU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE PU_Desc = @KanbanID

IF (@PU_Id IS NULL)
	BEGIN
		SET @Message = 'Error: Invalid Kanban'
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
				SET @Message = 'Error: PU Property of Kanban not set'
			END
		ELSE
			BEGIN
				SET @Message = 'Ok'
			END
		SELECT @Event_Id = MAX(Event_Id)
			FROM Events
			WHERE PU_Id = @PU_Id
				AND Event_Status = 9
		IF (@Event_Id IS NULL)
			BEGIN
				SET @Message = 'Error: Kanban has no events with Inventory status'
			END
		ELSE
			BEGIN
				SELECT @VarId = Var_Id 
					FROM Variables_Base
					WHERE PU_ID = @PU_Id
						AND Var_Desc = 'Quantity'
				SELECT @Quantity = Result, @QtyFloat = CONVERT(FLOAT, Result)
					FROM Tests
					WHERE Var_Id = @VarId
						AND Event_Id = @Event_Id 		
				IF (@QtyFloat IS NOT NULL and @QtyFloat	<> 0)
					BEGIN 
						SET @Message = 'Error: Kanban not empty'
					END		
				ELSE	
					BEGIN		
					UPDATE Table_Fields_Values SET Value = @Activate
						WHERE Table_Field_Id = @TableFieldId
						  AND TableId = @TableId
						  AND KeyID = @PU_Id
						  IF (@Activate = 1)
						  SET @Message = @KanbanID + ' Kanban Activated'
						  ELSE
						  SET @Message = @KanbanID + ' Kanban Inactivated'
					END
			END
	END

	Select @Message As Message

END

