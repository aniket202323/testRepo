
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Appliance_Actuals_CalcMgr
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-11-02-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Get appliance actual location information from PPA app
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-02		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE spLocal_CTS_Get_Actual_Location_CalcMgr
	@Output output,
	997931
	SELECT @Output

	SELECT * FROM EVENTS WHERE PU_ID = 8455
	Select * from event_details where pu_id = 8455
	Select * from event_details where event_id  = 986440

*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Get_Actual_Location_CalcMgr]
	@Output						VARCHAR(25) OUTPUT,
	@ThisEventId				INTEGER


AS
BEGIN
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================

	SET @Output = 'NOT OK'

	-----------------------------------------------------------------------------------------------------------------------
	-- DECLARE VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@AppliancePUId					INTEGER,
	@ApplianceTimestamp				DATETIME,
	@ActualTransitionTimestamp		DATETIME,
	@ActualTransitionEventId		INTEGER,
	@ActualTransitionStatusId		INTEGER,
	@ActualTransitionStatusDesc		VARCHAR(25),
	@ActualLocationPUId				INTEGER,
	@ActualLocationPUIdVarId		INTEGER,
	@ActualLocationPUDesc			INTEGER,
	@ActualLocationPUDescVarId		INTEGER,
	@ActualStatusDesc				VARCHAR(25),
	@ActualStatusDescVarId			INTEGER,
	@ActualCleanTypeVarId			INTEGER,
	@ActualProductId				INTEGER,
	@ActualProductIdVarId			INTEGER,
	@ActualProductDesc				VARCHAR(25),
	@ActualProductDescVarId			INTEGER,
	@ActualProcessOrderId			INTEGER,
	@ActualProcessOrderIdVarId		INTEGER,
	@ActualProcessOrderDesc			VARCHAR(25),
	@ActualProcessOrderDescVarId	INTEGER,
	@LocationProcessOrderId			INTEGER,
	@LocationProcessOrderIdVarId	INTEGER,
	@LocationProcessOrderDesc		VARCHAR(25),
	@LocationProcessOrderDescVarId	INTEGER,
	@LocationProductIdVarId			INTEGER,
	@LocationProductId				VARCHAR(25),
	@LocationProductDescVarId		INTEGER,
	@LocationProductDesc			VARCHAR(25),
	@RSUserId						INTEGER,
	@LocationEventIdVarId			INTEGER,
	@ApplianceEventIdVarId			INTEGER,
	@LocationEventId				INTEGER,
	@ApplianceEventId				INTEGER


	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 2 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@VUVarId				INTEGER,
	@VUPUId 				INTEGER,
	@VUUserId				INTEGER,
	@VUCanceled				INTEGER,
	@VUResult				VARCHAR(25),
	@VUResultOn				DATETIME,
	@VUTransactionType		INTEGER,
	@VUPostUpdate			INTEGER
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 2 TABLE
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE @RSVariables TABLE
	(
		VUVarId					INTEGER,
		VUPUId					INTEGER,
		VUUserId				INTEGER,
		VUCanceled				INTEGER,
		VUResult				VARCHAR(25),
		VUResultOn				DATETIME,
		VUTransactionType		INTEGER,
		VUPostUpdate			INTEGER,
		VUSecondUserId			INTEGER,
		VUTransNum				INTEGER,
		VUEventId				INTEGER,
		VUArrayId				INTEGER,
		VUCommentId				INTEGER,
		VUEsignature			INTEGER
	)

	DECLARE @App_Transitions TABLE
	(
	Location_id							INTEGER,
	Location_desc						VARCHAR(50),
	Location_Product_Id					INTEGER,
	Location_Product_code				VARCHAR(25),
	Location_Process_order_Id			INTEGER,
	Location_Process_order_desc			VARCHAR(50),
	Location_Process_order_status_Id	INTEGER,
	Location_Process_order_Status_desc	VARCHAR(50),
	Location_Process_Order_start_time	DATETIME,
	Location_Process_Order_End_time		DATETIME,
	Enter_time							DATETIME,
	Exit_time							DATETIME,
	Appliance_Product_Id				INTEGER,
	Appliance_Product_code				VARCHAR(25),
	Appliance_Process_order_Id			INTEGER,
	Appliance_Process_order_desc		VARCHAR(50),
	Mover_User_Id						INTEGER,
	Mover_Username						VARCHAR(100),
	Mover_User_AD						VARCHAR(100),
	Err_Warn							VARCHAR(500)
	)

	DECLARE @App_Transitions_Making TABLE
	(
	Location_id							INTEGER,
	Location_desc						VARCHAR(50),
	Location_Product_Id					INTEGER,
	Location_Product_code				VARCHAR(25),
	Location_Process_order_Id			INTEGER,
	Location_Process_order_desc			VARCHAR(50),
	Location_Process_order_status_Id	INTEGER,
	Location_Process_order_Status_desc	VARCHAR(50),
	Location_Process_Order_start_time	DATETIME,
	Location_Process_Order_End_time		DATETIME,
	Enter_time							DATETIME,
	Exit_time							DATETIME,
	Appliance_Product_Id				INTEGER,
	Appliance_Product_code				VARCHAR(25),
	Appliance_Process_order_Id			INTEGER,
	Appliance_Process_order_desc		VARCHAR(50),
	Mover_User_Id						INTEGER,
	Mover_Username						VARCHAR(100),
	Mover_User_AD						VARCHAR(100),
	Err_Warn							VARCHAR(500)
	)

	-----------------------------------------------------------------------------------------------------------------------
	-- GET VARIABLE TO UPDATE USING TEST_NAME
	-----------------------------------------------------------------------------------------------------------------------
	SET	@RSUserId =	(
					SELECT	user_id 
					FROM	dbo.users_base WITH(NOLOCK)
					WHERE	username = 'CTS'
					)
	SELECT	@AppliancePUId =		PU_ID,
			@ApplianceTimestamp =	timestamp
	FROM	dbo.events WITH(NOLOCK)
	WHERE	event_id = @ThisEventId
	


	SET @ActualLocationPUIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location id')

	SET @ActualLocationPUDescVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location desc')

	SET @ActualStatusDescVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Status desc')

	SET @ActualProductIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Product id')
	
	SET @ActualProductDescVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Product desc')

	SET @ActualCleanTypeVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Clean type')

	SET @ActualProcessOrderIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Process Order id')
	
	SET @ActualProcessOrderDescVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Process Order desc')

	SET @LocationProcessOrderIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location Process Order id')
	
	SET @LocationProcessOrderDescVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location Process Order desc')

	SET @LocationProductIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location Product id')
	
	SET @LocationProductDescVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location Product desc')

	SET @LocationEventIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Location event id')
	
	SET @ApplianceEventIdVarId =
		(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Event id')
	

	-----------------------------------------------------------------------------------------------------------------------
	-- WRITE IN TESTS RS2
	-----------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------
		-- GET CURRENT APPLIANCE INFO
		-----------------------------------------------------------------------------------------------------------------------
		

		SET @ActualLocationPUId =				(
											SELECT TOP 1	E.pu_id 
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @ActualTransitionTimestamp =				(
											SELECT TOP 1	E.timestamp
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @LocationEventId =				(
											SELECT TOP 1	E.event_id
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)

		SET @ActualProcessOrderId =		(
											SELECT TOP 1	ED.PP_ID 
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
															JOIN dbo.event_details ED WITH(NOLOCK)
																ON ED.event_id = E.event_id
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @LocationProcessOrderId =			(
											SELECT	PP_ID 
											FROM	dbo.production_plan_starts WITH(NOLOCK) 
											WHERE	PU_id = @ActualLocationPUId 
														AND @ActualTransitionTimestamp > Start_time
														AND (@ActualTransitionTimestamp < end_time OR end_time IS NULL)
											)
		SET @LocationProductId =			(
											SELECT	Prod_ID 
											FROM	dbo.production_plan WITH(NOLOCK) 
											WHERE	PP_Id = @LocationProcessOrderId
											)
		SET @LocationProductDesc =			(
											SELECT	Prod_Desc 
											FROM	dbo.Products_base WITH(NOLOCK) 
											WHERE	Prod_Id = @LocationProductId
											)


		SET @ActualTransitionEventId =		(
											SELECT TOP 1	E.event_id
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @ActualTransitionStatusId =	COALESCE((
											SELECT TOP 1	E.Event_Status
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											), (SELECT			ProdStatus_id 
													FROM			dbo.Production_status WITH(NOLOCK) 
													WHERE			ProdStatus_desc = 'Clean'))

		SET @ActualTransitionStatusDesc = COALESCE((
													SELECT			ProdStatus_desc 
													FROM			dbo.Production_status WITH(NOLOCK) 
													WHERE			ProdStatus_Id = @ActualTransitionStatusId
													),'Clean')



		-- LOCATION EVENT ID
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@LocationEventIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@LocationEventId,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)


		-- APPLIANCE EVENT ID
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ApplianceEventIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@ThisEventId,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)

	-- PU_ID

		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualLocationPUIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@ActualLocationPUId,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)



	-- PU_DESC

		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualLocationPUDescVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						(SELECT PU_Desc FROM dbo.prod_units_base WITH(NOLOCK) WHERE pu_id = @ActualLocationPUId),
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)

	

	-- LOCATION PROCESS ORDER ID
	
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@LocationProcessOrderIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@LocationProcessOrderId,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	

	-- LOCATION PROCESS ORDER DESC

		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@LocationProcessOrderDescVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						(SELECT Process_order FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @LocationProcessOrderId),
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
-- LOCATION PRODUCT ID
	
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@LocationProductIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@LocationProductId,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	

	-- LOCATION PRODUCT DESC

		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@LocationProductDescVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@LocationProductDesc,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)	


	-- APPLIANCE PROCESS ORDER ID
	
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualProcessOrderIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@ActualProcessOrderId,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	

	-- APPLIANCE PROCESS ORDER DESC
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualProcessOrderDescVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						(SELECT Process_order FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @ActualProcessOrderId),
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	

	-- APPLIANCE PRODUCT ID
	
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualProductIdVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						(SELECT Prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @ActualProcessOrderId),
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)

		SET @ActualProductDesc =	(	
									SELECT	Prod_Desc 
									FROM	dbo.products_base WITH(NOLOCK) 
									WHERE	Prod_Id = (SELECT Prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @ActualProcessOrderId)
									)
	

	-- APPLIANCE PRODUCT DESC
	
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualProductdescVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@ActualProductDesc,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	
	

	
	-- STATUS DESC
	--SELECT @ActualTransitionStatusDesc, @ActualTransitionStatusId
	

		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualStatusDescVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						@ActualTransitionStatusDesc,
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	
	-- CLEAN TYPE
		INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(	@ActualCleanTypeVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						(SELECT CAST(Clean_type AS VARCHAR(25)) FROM fnLocal_CTS_Appliance_Status(@ThisEventId,NULL)),
						@ApplianceTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
	
	IF (SELECT COUNT(1) FROM @RSVariables) > 0
		SELECT 2,* FROM @RSVariables
	SET @Output = 'OK'
END -- BODY

