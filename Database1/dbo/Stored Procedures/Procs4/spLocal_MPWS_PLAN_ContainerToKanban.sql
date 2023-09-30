 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_ContainerToKanban
		
	This sp returns header info for [spLocal_MPWS_PLAN_ContainerToKanban]
	
	Date			Version		Build	Author  
	02-21-2018		001			001		Andrew Drake (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_ContainerToKanban]
	@Message VARCHAR(50) OUTPUT,
	@Container VARCHAR(25),
	@Kanban VARCHAR(25)
AS

SET NOCOUNT ON;

DECLARE @ConPU_Id INT,
		@KanPU_id INT,
		@ConEvent_Id INT,
		@KanEvent_Id INT,
		@ConKanbanLoc VARCHAR(25),
		@ConProdDesc VARCHAR(50),
		@ConProdShort VARCHAR(25),
		@KanProdDesc VARCHAR(25),
		@ConWeight FLOAT,
		@KanQtyChar VARCHAR(25),
		@User_Id VARCHAR(25),
		@VarId INT,
		@ConVarId INT,
		@TableFieldId INT,
		@TableID INT,
		@Value VARCHAR(25),
		@IsKanban INT,
		@MaxContainerCnt VARCHAR(25),
		@Quantity VARCHAR(25),
		@EntryOn DATETIME,
		@ConTimestamp DATETIME,
		@KanTimestamp DATETIME,
		@ConTestId BIGINT,
		@KanTestId BIGINT,
		@ConComment_Id INT,
		@KanComment_Id INT,
		@ConArray_Id INT,
		@KanArray_Id INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @User_Id = User_Id
	FROM Users_Base 
	WHERE UserName = 'KanbanXface'

SELECT @ConEvent_Id = e.Event_Id, @ConPU_Id = e.PU_Id, @ConProdDesc = p.Prod_Desc, @ConProdShort = SUBSTRING(p.Prod_Desc, 1, 25),  @ConWeight = Final_Dimension_X 
	FROM dbo.Event_Details ed
		JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
		JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
		JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pu.PL_Id
		JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
		LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
			AND t.Var_Id = v.Var_Id
		JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
		JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Desc = t.Result
		CROSS APPLY dbo.Engineering_Unit euKG	
	WHERE v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
		AND e.Event_Num = @Container

IF (@ConEvent_Id IS NULL)
	BEGIN
		SET @Message = 'Error: Invalid Container'
	END
ELSE
	BEGIN
		SELECT @ConVarId = Var_Id 
			FROM Variables_Base
			WHERE PU_ID = @ConPU_Id
				AND Test_Name = 'MPWS_DISP_KANBAN_LOC' 
		SELECT @ConKanbanLoc = Result,
				@ConTestId = Test_Id,
				@ConComment_Id = Comment_Id,
				@ConArray_Id = Array_id
			FROM Tests
			WHERE Var_Id = @ConVarId
		  AND Event_Id = @ConEvent_Id		
		IF (@ConKanbanLoc IS NOT NULL)
			BEGIN
				SELECT @Message = 'Error: Container already assigned to Kanban '
			END
		ELSE
			BEGIN
				SELECT @KanPU_Id = PU_Id
					FROM Prod_Units_Base
					WHERE PU_Desc = @Kanban
				IF (@KanPU_Id IS NULL)
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
							  AND KeyID = @KanPU_Id
						IF (@Value IS NULL)
							BEGIN
								SET @Message = 'Error: PU Property of Kanban not set'
							END
						ELSE
							BEGIN
								SELECT @IsKanban = Value 
									FROM Table_Fields_Values tfv,Table_Fields tf, Tables t
									WHERE tfv.KeyId = @KanPU_Id
									  AND tfv.TableId = t.TableId
									  AND t.TableName = 'Prod_Units'
									  AND tfv.Table_Field_Id = tf.Table_Field_Id
									  AND tf.Table_Field_Desc = 'Kanban'
								IF (@IsKanban < 1)
									BEGIN
										SET @Message = 'Error: Kanban is inactive'
									END
								ELSE
									BEGIN
										SELECT @KanEvent_Id = MAX(Event_Id)
										   FROM Events
										   WHERE PU_Id = @KanPU_Id
											 AND Event_Status = 9
										IF (@KanEvent_Id IS NULL)
											BEGIN
												SET @Message = 'Error: Kanban has no events with Inventory status'
											END
										ELSE
											BEGIN
												SELECT @VarId = Var_Id 
													FROM Variables_Base
													WHERE PU_ID = @KanPU_Id
													  AND Var_Desc = 'MaterialName'
												SELECT @KanProdDesc = Result
													FROM Tests
													WHERE Var_Id = @VarId
													  AND Event_Id = @KanEvent_Id
												IF (@ConProdShort <> @KanProdDesc)
													BEGIN
														SET @Message = 'Material Mismatch'
													END
												ELSE
													BEGIN
														SELECT @VarId = Var_Id 
															FROM Variables_Base
															WHERE PU_ID = @KanPU_Id
															  AND Var_Desc = 'MaxContainerCnt'
														SELECT @MaxContainerCnt = Result
															FROM Tests
															WHERE Var_Id = @VarId
															  AND Event_Id = @KanEvent_Id				
														SELECT @VarId = Var_Id 
															FROM Variables_Base
															WHERE PU_ID = @KanPU_Id
															  AND Var_Desc = 'Quantity'
														SELECT @Quantity = Result,
																@KanTestId = Test_Id,
																@KanComment_Id = Comment_Id,
																@KanArray_Id = Array_id
															FROM Tests
															WHERE Var_Id = @VarId
															  AND Event_Id = @KanEvent_Id 														  
														--SET @KanQuantity = Convert(FLOAT, @MaxContainerCnt) - Convert(FLOAT, @Quantity)
														--IF (@KanQuantity < @ConWeight)
														IF (Convert(int,@Quantity) >= Convert(int,@MaxContainerCnt)) 
															BEGIN
																SET @Message = 'Container Count Exceeds Kanban availability ' + CONVERT(varchar(10), @Quantity) + ' ' + CONVERT(varchar(10), @MaxContainerCnt)
															END
														ELSE
															BEGIN
																SELECT @KanTimestamp = Timestamp
																	FROM Events
																	WHERE Event_id = @KanEvent_Id
																SET @EntryOn = GETDATE()

																IF (@Quantity IS NULL)
																	SET @KanQtyChar = '1'
																ELSE
																	SET @KanQtyChar = CONVERT(VARCHAR(25),CONVERT(FLOAT, @Quantity) + 1)

																EXECUTE dbo.spServer_DBMgrUpdTest2
																	@Var_Id = @VarId,
																	@User_Id = @User_Id,
																	@Canceled = 0,
																	@New_Result = @KanQtyChar,
																	@Result_On = @KanTimestamp,
																	@TransNum = 2,					--NOT USED, must be 0 or 2
																	@CommentId = @KanComment_Id,
																	@ArrayId = @KanArray_Id,
																	@EventId = @KanEvent_Id OUTPUT,
																	@PU_Id = @KanPU_Id OUTPUT,
																	@Test_Id = @KanTestId OUTPUT,
																	@Entry_On = @EntryOn OUTPUT,
																	@SecondUserId = NULL,
																	@HasHistory = NULL,
																	@SignatureId = NULL
																SELECT @ConTimestamp = Timestamp
																	FROM Events
																	WHERE Event_id = @ConEvent_Id
																EXECUTE dbo.spServer_DBMgrUpdTest2
																	@Var_Id = @ConVarId,
																	@User_Id = @User_Id,
																	@Canceled = 0,
																	@New_Result = @Kanban,
																	@Result_On = @ConTimestamp,
																	@TransNum = 2,					--NOT USED, must be 0 or 2
																	@CommentId = @ConComment_Id,
																	@ArrayId = @ConArray_Id,
																	@EventId = @ConEvent_Id OUTPUT,
																	@PU_Id = @ConPU_Id OUTPUT,
																	@Test_Id = @ConTestId OUTPUT,
																	@Entry_On = @EntryOn OUTPUT,
																	@SecondUserId = NULL,
																	@HasHistory = NULL,
																	@SignatureId = NULL
																SET	@Message = @Container + ' added to ' + @Kanban
															END
													END
											END
									END
							END
					END
			END
	END
	Select @Message as Message
END
