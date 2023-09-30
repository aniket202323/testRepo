 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_EventGet
		
	This sp returns header info for spLocal_MPWS_KANBAN_CheckInventory
	
	Date			Version		Build	Author  
	02-22-18		001			001		Don Reinert (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_CheckInventory]
	@Message VARCHAR(100) OUTPUT,
	@KanbanID VARCHAR(25)

AS

DECLARE @Kanban_Local TABLE (
		ID						INT IDENTITY(1,1),
		PU_Id					INT,
		Kanban					VARCHAR(25) ,
		Event_id				INT,
		GCASNumber				VARCHAR(25) ,
		LocationCode			VARCHAR(25) ,
		MaterialName			VARCHAR(25) ,
		CriticalContainerCnt	FLOAT ,
		MaxContainerCnt			FLOAT ,
		RefillContainerCnt		FLOAT ,
		WeightSetpoint			VARCHAR(25) ,
		Quantity				FLOAT ,
		Active					VARCHAR(25) ,
		Event_Status			VARCHAR(25)
)

DECLARE @Summary_Local TABLE (
		ID						INT IDENTITY(1,1),
		GCASNumber				VARCHAR(25) ,
		MaterialName			VARCHAR(25) ,
		CriticalContainerCnt	FLOAT ,
		MaxContainerCnt			FLOAT ,
		RefillContainerCnt		FLOAT ,
		WeightSetpoint			FLOAT ,
		Quantity				FLOAT,
		OpenWO					FLOAT,
		OpenDC					FLOAT
)

DECLARE @WO_Local TABLE (
		ID						INT IDENTITY(1,1),
		Event_Id				INT,
		WorkOrder				VARCHAR(25) ,
		MaterialName			VARCHAR(25) ,
		GCASNumber				VARCHAR(25) ,
		DispenseNum				FLOAT ,
		TargetQty				FLOAT ,
		UpperLimit				FLOAT ,
		LowerLimit				FLOAT ,
		UOM						VARCHAR(25) ,
		DispensedQty			FLOAT ,
		Status					VARCHAR(25) 
)

DECLARE @Container_Local TABLE (
		ID						INT IDENTITY(1,1),
		PU_Id					INT,
		Event_Id				INT,
		Container				VARCHAR(50) ,
		Weight					FLOAT ,
		UOM						VARCHAR(25) ,
		Prod_Desc				VARCHAR(25) ,
		Prod_Code				VARCHAR(25),
		Method					VARCHAR(25)
)

DECLARE
	@Kanban VARCHAR(25),
	@PU_Id INT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@IsKanban INT,
	@RecordCount INT,
	@Event_Id INT,
	@Timestamp DATETIME,
	@Var_Id INT,
	@CriticalContainerCnt VARCHAR(25),
	@CriticalContainerCntFloat FLOAT,
	@MaxContainerCnt VARCHAR(25),
	@MaxContainerCntFloat FLOAT,
	@Quantity VARCHAR(25),
	@QuantityFloat FLOAT,
	@NeedWO INT,
	@GCASNumber VARCHAR(25),
	@MaterialName VARCHAR(25),
	@WeightSetpoint VARCHAR(25),
	@WeightSetpointFloat FLOAT,
	@DispenseNum INT,
	@DispenseNumFloat FLOAT,
	@UpperLimit FLOAT,
	@LowerLimit FLOAT,
	@UOM VARCHAR(25),
	@Status VARCHAR(25),
	@CountPUId INT,
	@CurrentPUId INT,
	@CountWO INT,
	@CurrentWO INT,
	@CountDC INT,
	@CurrentDC INT,
	@LocationCode VARCHAR(25),
	@RefillContainerCnt VARCHAR(25),
	@RefillContainerCntFloat FLOAT,
	@Active VARCHAR(25),
	@Event_Status VARCHAR(25),
	@KanbanMaterialName VARCHAR(25),
	@KanbanWeightSetpoint FLOAT,
	@KanbanGCASNumber VARCHAR(25),
	@WorkOrder VARCHAR(25),
	@TargetQty VARCHAR(25),
	@TargetQtyFloat FLOAT,
	@DispensedQty VARCHAR(25),
	@DispensedQtyFloat FLOAT,
	@OpenWO FLOAT,
	@OpenDC FLOAT,
	@Method VARCHAR(25)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT @PU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE PU_Desc = @KanbanID

DECLARE @NotificationTime AS DATETIME 
SET @NotificationTime = GetDate()
DECLARE @ErrorCode AS INT
DECLARE @ErrorMessage AS varchar(225)

IF (@PU_Id IS NULL)
	BEGIN
		SET @Message = 'Invalid Kanban'
		EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', 'Cannot check Kanban Inventory: Invalid Kanban', @NotificationTime, 'Error'
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
				EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', 'Cannot check Kanban Inventory: Kanban in SOA not properly configured', @NotificationTime, 'Error'
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
						EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', 'Cannot check Kanban Inventory: Kanban is Inactive', @NotificationTime, 'Error'
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
								EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', 'Cannot check Kanban Inventory: Kanban is not configured', @NotificationTime, 'Error'
							END
						ELSE
							BEGIN
								SELECT @Var_Id = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'Quantity'
								SELECT @Quantity = Result, @QuantityFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
									FROM Tests
									WHERE Var_Id = @Var_Id
									  AND Event_Id = @Event_Id	
								SELECT @Var_Id = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'CriticalContainerCnt'
								SELECT @CriticalContainerCnt = Result, @CriticalContainerCntFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
									FROM Tests
									WHERE Var_Id = @Var_Id
									  AND Event_Id = @Event_Id									  		  								
								SELECT @Var_Id = Var_Id 
									FROM Variables_Base
									WHERE PU_ID = @PU_Id
									  AND Var_Desc = 'MaxContainerCnt'
								SELECT @MaxContainerCnt = Result, @MaxContainerCntFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
									FROM Tests
									WHERE Var_Id = @Var_Id
									  AND Event_Id = @Event_Id
								
								IF (@RefillContainerCntFloat <= @QuantityFloat)
									BEGIN
										SET @Message = 'Kanban '+ @KanbanID +' Qty of ' + @Quantity + ' Above Refill of ' + @RefillContainerCnt
										--EXEC spLocal_MPWS_GENL_CreateNotification 'Planning', @Message, @NotificationTime, 'Message'
									END	
								IF (@CriticalContainerCntFloat <= @QuantityFloat)
									BEGIN
										SET @Message = 'Kanban '+ @KanbanID +' Qty of ' + @Quantity + ' Below Refill of ' + @RefillContainerCnt
										EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', @Message, @NotificationTime, 'Message'
									END					  								
								ELSE
									BEGIN	
										SELECT @Var_Id = Var_Id 
											FROM Variables_Base
											WHERE PU_ID = @PU_Id
											  AND Var_Desc = 'MaterialName'
										SELECT @MaterialName = Result, @KanbanMaterialName = Result
											FROM Tests
											WHERE Var_Id = @Var_Id
											  AND Event_Id = @Event_Id
										SELECT @Var_Id = Var_Id 
											FROM Variables_Base
											WHERE PU_ID = @PU_Id
											  AND Var_Desc = 'GCASNumber'
										SELECT @GCASNumber = Result, @KanbanGCASNumber = Result
											FROM Tests
											WHERE Var_Id = @Var_Id
											  AND Event_Id = @Event_Id
										SELECT @Var_Id = Var_Id 
											FROM Variables_Base
											WHERE PU_ID = @PU_Id
											  AND Var_Desc = 'WeightSetpoint'
										SELECT @WeightSetpoint = Result, @WeightSetpointFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END, @KanbanWeightSetpoint = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
											FROM Tests
											WHERE Var_Id = @Var_Id
											  AND Event_Id = @Event_Id		
										-- Now get all kanbans so we can accumulate by Material and SetPoint
										INSERT INTO @Kanban_Local (PU_Id)
											SELECT pub.PU_ID 
											FROM Prod_Units_Base pub, Table_Fields tf, Tables t, Table_Fields_Values tfv
											WHERE t.TableName = 'Prod_Units'
												AND t.TableId = tf.TableId
												AND tf.Table_Field_Desc = 'Kanban'
												AND tf.Table_Field_Id = tfv.Table_Field_Id
												AND tf.TableId = tfv.TableId
												AND tfv.KeyID = pub.PU_Id

										SELECT @CountPUId = MAX(ID) 
											FROM @Kanban_Local

										SELECT @CurrentPUId = 0
										WHILE (@CurrentPUId < @CountPUId)
											BEGIN
												SET @CurrentPUId = @CurrentPUId + 1
												SELECT @Kanban = NULL, @Event_Id = NULL, @Event_Status = NULL, @QuantityFloat = NULL, @GCASNumber = NULL, 
													@LocationCode = NULL, @MaterialName = NULL, @CriticalContainerCntFloat = NULL,
													@MaxContainerCntFloat = NULL, @RefillContainerCntFloat = NULL, @WeightSetpointFloat = NULL, @Active = NULL
		
												SELECT @PU_Id = PU_id
													FROM @Kanban_Local
													WHERE ID = @CurrentPUId
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
														AND Var_Desc = 'Quantity'
												SELECT @QuantityFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
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
												SELECT @CriticalContainerCntFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
													FROM Tests
													WHERE Var_Id = @Var_Id
														AND Event_Id = @Event_Id									  								
												SELECT @Var_Id = Var_Id 
													FROM Variables_Base
													WHERE PU_ID = @PU_Id
														AND Var_Desc = 'MaxContainerCnt'
												SELECT @MaxContainerCntFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
													FROM Tests
													WHERE Var_Id = @Var_Id
														AND Event_Id = @Event_Id									  								
												SELECT @Var_Id = Var_Id 
													FROM Variables_Base
													WHERE PU_ID = @PU_Id
														AND Var_Desc = 'RefillContainerCnt'
												SELECT @RefillContainerCntFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
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
												SELECT @Active = Value 
													FROM Table_Fields_Values tfv,Table_Fields tf, Tables t
													WHERE tfv.KeyId = @PU_Id
														AND tfv.TableId = t.TableId
														AND t.TableName = 'Prod_Units'
														AND tfv.Table_Field_Id = tf.Table_Field_Id
														AND tf.Table_Field_Desc = 'Kanban'
												UPDATE @Kanban_Local SET Kanban = @Kanban,
																		Event_id = @Event_Id, 
																		GCASNumber = @GCASNumber, 
																		LocationCode = @LocationCode, 
																		MaterialName = @MaterialName, 
																		CriticalContainerCnt = @CriticalContainerCntFloat, 
																		MaxContainerCnt = @MaxContainerCntFloat, 
																		RefillContainerCnt = @RefillContainerCntFloat, 
																		WeightSetpoint = @WeightSetpoint, 
																		Quantity = @QuantityFloat, 
																		Active = @Active, 
																		Event_Status = @Event_Status
													WHERE PU_Id = @PU_id
											END
										-- Now get summary by Materials and Set Point
										INSERT INTO @Summary_Local (GCASNumber, MaterialName, CriticalContainerCnt, MaxContainerCnt, RefillContainerCnt, WeightSetpoint, Quantity)
											SELECT GCASNumber, MaterialName, SUM(CriticalContainerCnt), SUM(MaxContainerCnt), SUM(RefillContainerCnt), CONVERT(FLOAT, WeightSetpoint), SUM(Quantity)
												FROM @Kanban_Local
												WHERE MaterialName = @KanbanMaterialName
													AND WeightSetpoint = CONVERT(VARCHAR(25),@KanbanWeightSetpoint)
													AND GCASNumber = @KanbanGCASNumber
													AND Event_Status = 'INVENTORY'
													AND Active = '1'
													AND Kanban <> 'KB-1B'
												GROUP BY GCASNumber, MaterialName, WeightSetpoint
										-- Now get open Work Orders 
										SELECT @PU_Id = PU_Id
											FROM Prod_Units_Base
											WHERE Prod_Units_Base.PU_Desc = 'KB-WO'

										INSERT INTO @WO_Local (Event_Id, WorkOrder, Status)
											SELECT Event_Id, Event_Num, ProdStatus_Desc
											FROM Events, Production_Status
											WHERE Events.PU_Id = @PU_Id
												AND Events.Event_Status = Production_Status.ProdStatus_Id
												AND Production_Status.ProdStatus_Desc in ('Pending','Released','Dispensing')

										SELECT @CountWO = MAX(ID) 
											FROM @WO_Local

										SELECT @CurrentWO = 0
										WHILE (@CurrentWO <= @CountWO)
											BEGIN
												SET @CurrentWO = @CurrentWO + 1
												SELECT @WorkOrder = NULL, @MaterialName = NULL, @GCASNumber = NULL,
													@DispenseNum = NULL, @TargetQty = NULL, @UpperLimit = NULL, @LowerLimit = NULL, @Status = NULL, @UOM = NULL, @DispensedQty = NULL
		
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
												SELECT @DispenseNum = Result, @DispenseNumFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
													FROM Tests
													WHERE Var_Id = @Var_Id
														AND Event_Id = @Event_Id						  
												SELECT @Var_Id = Var_Id 
													FROM Variables_Base
													WHERE PU_ID = @PU_Id
														AND Var_Desc = 'TargetQty'
												SELECT @TargetQty = Result, @TargetQtyFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
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
												SELECT @DispensedQty = Result, @DispensedQtyFloat = CASE WHEN Result IS NULL THEN 0 ELSE CONVERT(FLOAT,Result) END
													FROM Tests
													WHERE Var_Id = @Var_Id
														AND Event_Id = @Event_Id									  								

												UPDATE @WO_Local SET MaterialName = @MaterialName,
																		GCASNumber = @GCASNumber, 
																		DispenseNum = @DispenseNumFloat, 
																		TargetQty = @TargetQtyFloat, 
																		UpperLimit = @UpperLimit, 
																		LowerLimit = @LowerLimit,
																		UOM = @UOM,
																		DispensedQty = @DispensedQtyFloat
													WHERE Event_Id = @Event_Id
											END
										SELECT @OpenWO = SUM(DispenseNum - DispensedQty)
											FROM @WO_Local
											WHERE MaterialName = @KanbanMaterialName
											  AND GCASNumber = @KanbanGCASNumber
											  AND TargetQty = @KanbanWeightSetpoint
										UPDATE @Summary_Local SET OpenWO = @OpenWO
										-- Now find open Dispensed Containers that have not been moved to a Kanban
										INSERT INTO @Container_Local (pu_iD, Event_Id, Container, Prod_Desc, Prod_Code)
											SELECT e.PU_Id, e.Event_Id, e.Event_Num, SUBSTRING(p.Prod_Desc, 1, 25), p.Prod_Code
											FROM dbo.Event_Details ed
												JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
												JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
												JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pu.PL_Id
												JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
												LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
													AND t.Var_Id = v.Var_Id
												JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
												JOIN dbo.Production_Plan pp ON ed.PP_Id = pp.PP_Id
												JOIN dbo.Production_Status ps ON e.Event_Status = ps.ProdStatus_Id
											WHERE v.Test_Name = 'MPWS_DISP_KANBAN_LOC'
											  AND ps.ProdStatus_Desc in ('Dispensed')
											  AND t.Result IS NULL
										SELECT @CountDC = MAX(ID) 
										FROM @Container_Local

										SELECT @CurrentDC = 0
										WHILE (@CurrentDC < @CountDC)
											BEGIN
												SET @CurrentDC = @CurrentDC + 1
												SELECT @Method = NULL
												SELECT @PU_Id = PU_id, @Event_Id = Event_id
													FROM @Container_Local
													WHERE ID = @CurrentDC
												SELECT @Var_Id = Var_Id 
													FROM Variables_Base
													WHERE PU_ID = @PU_Id
													  AND Test_Name = 'MPWS_DISP_DISPENSE_METHOD'
												SELECT @Method = Result
													FROM Tests
													WHERE Var_Id = @Var_Id
													  AND Event_Id = @Event_Id						
												UPDATE @Container_Local SET Method = @Method
													WHERE PU_Id = @PU_id
													  AND Event_Id = @Event_Id
											END
											SELECT @OpenDC = Count(*)
												FROM @Container_Local
												WHERE Prod_Desc = @KanbanMaterialName
													AND Weight <= @KanbanWeightSetpoint * 1.5 
													AND Weight >= @KanbanWeightSetpoint * .95
													AND Prod_Code = @KanbanGCASNumber
													AND Method = 'BYWO'
											UPDATE @Summary_Local SET OpenDC = @OpenDC
											SELECT @GCASNumber = GCASNumber, @MaterialName = MaterialName, 	@CriticalContainerCntFloat = CriticalContainerCnt, 
													@MaxContainerCntFloat = MaxContainerCnt,
													@RefillContainerCntFloat = RefillContainerCnt, 
													@WeightSetpointFloat = WeightSetpoint, 
													@QuantityFloat = CASE WHEN Quantity IS NULL THEN 0 ELSE Quantity END, 
													@OpenWO = CASE WHEN OpenWO IS NULL THEN 0 ELSE OpenWO END, 
													@OpenDC = CASE WHEN OpenDC IS NULL THEN 0 ELSE OpenDC END
												FROM @Summary_Local
											SET @DispenseNum = CONVERT(INT, @MaxContainerCntFloat - @QuantityFloat - @OpenWO - @OpenDC + .499)
											--SET @Message = CONVERT(varchar(5),@MaxContainerCntFloat) + ' ' + CONVERT(varchar(5),@QuantityFloat) + ' ' + CONVERT(varchar(5),@OpenWO) + ' ' + CONVERT(varchar(5),@OpenDC) + ' '
											IF (@DispenseNum > 0)
												BEGIN
													SET @UpperLimit = @WeightSetpointFloat * 1.05
													SET @LowerLimit = @WeightSetpointFloat * 0.95
													SET @UOM = 'KG'
													SET @Status = 'Pending'
													EXECUTE dbo.spLocal_MPWS_PLAN_CreateWorkOrder @message OUTPUT, @MaterialName, @GCASNumber, @DispenseNum, @WeightSetpointFloat, @UpperLimit, @LowerLimit, @UOM, 0, @Status, ''
													SET @Message = 'Work Order Created for Quantity ' + Convert(varchar(5),@DispenseNum) + ' For ' + @KanbanID
													EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', @Message, @NotificationTime, 'Message'
												END
											ELSE
											--SET @Message = CONVERT(varchar(5),@MaxContainerCntFloat) + ' - ' + CONVERT(varchar(5),@QuantityFloat) + ' - ' + CONVERT(varchar(5),@OpenWO) + ' - ' + CONVERT(varchar(5),@OpenDC) + ' '
												--SET @Message = 'WO not created. Enough in other WOs and DCs'
												BEGIN
													SET @Message = 'Kanban '+ @KanbanID +' Below Critical Count, but enough other WOs or DCs to refill. No WO created.'
													EXEC spLocal_MPWS_GENL_CreateNotification @ErrorCode, @ErrorMessage, 'Planning', @Message, @NotificationTime, 'Message'
												END
									END
							END
					END
			END
		
	END

	--select * from @Summary_Local
END





