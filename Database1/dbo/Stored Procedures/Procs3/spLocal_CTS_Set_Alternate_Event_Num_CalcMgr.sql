
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Reservations
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-08-12
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Set the alternate event num of a production_event (Licence plate)
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-8-12		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE spLocal_CTS_Set_Alternate_Event_Num_CalcMgr
	@Output output,
	993839,
	'20211102152551'



	SELECT @Output
	Select * from event_details where pu_id = 8455
	Select * from event_details where event_id  = 986440
		Select * from events where pu_id = 8455
*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Set_Alternate_Event_Num_CalcMgr]
	@output				VARCHAR(25) OUTPUT,
	@ThisEventId		INTEGER,
	@Serial				VARCHAR(25)


AS
BEGIN
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================
	-----------------------------------------------------------------------------------------------------------------------
	-- DECLARE VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@OnEventId									INTEGER,
	@ValidAEN									BIT,
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 10 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	@RS10UpdateType								INTEGER,
	@RS10UserId									INTEGER,
	@RS10TransactionType						INTEGER,
	@RS10TransactionNumber						INTEGER,
	@RS10EventId								INTEGER,
	@RS10UnitId									INTEGER,
 	@RS10PrimaryEventNumber						VARCHAR(50),
	@RS10AlternateEventNumber					VARCHAR(50),
	@RS10CommentId								INTEGER,
	@RS10EventSubTypeId							INTEGER,
	@RS10OriginalProduct						INTEGER,
	@RS10AppliedProduct							INTEGER,
	@RS10EventStatus							INTEGER,
	@RS10Timestamp								DATETIME,
	@RS10EntryOn								DATETIME,
	@RS10ProductionPlanSetupDetailId			INTEGER,
	@RS10OrderId								INTEGER,
	@RS10OrderLineId							INTEGER,
	@RS10ProductionPlanId						INTEGER,
	@RS10InitialDimensionX						FLOAT,
	@RS10InitialDimensionY						FLOAT,
	@RS10InitialDimensionZ						FLOAT,
	@RS10InitialDimensionA						FLOAT,
	@RS10FinalDimensionX						FLOAT,
	@RS10FinalDimensionY						FLOAT,
	@RS10FinalDimensionZ						FLOAT,
	@RS10FinalDimensionA						FLOAT,
	@RS10OrientationX							FLOAT,
	@RS10OrientationY							FLOAT,
	@RS10OrientationZ							FLOAT,
	@RS10OrientationA							FLOAT,
	@RS10ESignature								INTEGER
		
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 10 TABLE
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE @RS10 TABLE
	(
		RS10_Update_Type						INTEGER,
		RS10_User_Id							INTEGER,
		RS10_Transaction_Type					INTEGER,
		RS10_Transaction_Number					INTEGER,
		RS10_Event_Id							INTEGER,
		RS10_Unit_Id							INTEGER,
 		RS10_Primary_Event_Number				VARCHAR(50),
		RS10_Alternate_Event_Number				VARCHAR(50),
		RS10_Comment_Id							INTEGER,
		RS10_Event_Sub_Type_Id					INTEGER,
		RS10_Original_Product					INTEGER,
		RS10_Applied_Product					INTEGER,
		RS10_Event_Status						INTEGER,
		RS10_Timestamp							DATETIME,
		RS10_Entry_On							DATETIME,
		RS10_Production_Plan_Setup_Detail_Id	INTEGER,
		RS10_Order_Id							INTEGER,
		RS10_Order_Line_Id						INTEGER,
		RS10_Production_Plan_Id					INTEGER,
		RS10_Initial_Dimension_X				FLOAT,
		RS10_Initial_Dimension_Y				FLOAT,
		RS10_Initial_Dimension_Z				FLOAT,
		RS10_Initial_Dimension_A				FLOAT,
		RS10_Final_Dimension_X					FLOAT,
		RS10_Final_Dimension_Y					FLOAT,
		RS10_Final_Dimension_Z					FLOAT,
		RS10_Final_Dimension_A					FLOAT,
		RS10_Orientation_X						FLOAT,
		RS10_Orientation_Y						FLOAT,
		RS10_Orientation_Z						FLOAT,
		RS10_Orientation_A						FLOAT,
		RS10_ESignature							INTEGER
	)
 
	-----------------------------------------------------------------------------------------------------------------------
	-- SP BODY
	-----------------------------------------------------------------------------------------------------------------------

	SET @Output = 'Life Is good'

	-----------------------------------------------------------------------------------------------------------------------
 	-- GET EVENT DETAILS INFORMATION
	-----------------------------------------------------------------------------------------------------------------------
	SELECT		@RS10EventId =						E.event_id,
				@RS10UnitId	=						E.PU_id,
				@RS10PrimaryEventNumber =			E.Event_Num,
				@RS10AlternateEventNumber =			ED.Alternate_Event_Num,		
				@RS10CommentId =					ED.Comment_Id,
				@RS10EventSubTypeId =				E.Event_Subtype_Id,
				@RS10OriginalProduct =				PPS.Prod_Id,
				@RS10AppliedProduct =				E.Applied_Product,
				@RS10EventStatus =					E.Event_Status,
				@RS10Timestamp =					E.TimeStamp,
				@RS10EntryOn =						GETDATE(),
				@RS10ProductionPlanSetupDetailId =	ED.PP_Setup_Detail_Id,
				@RS10OrderId =						ED.Order_Id,
				@RS10OrderLineId =					ED.Order_Line_Id,
				@RS10ProductionPlanId =				ED.PP_ID,
				@RS10InitialDimensionX =			ED.Initial_Dimension_X,
				@RS10InitialDimensionY =			ED.Initial_Dimension_Y,
				@RS10InitialDimensionZ =			ED.Initial_Dimension_Z,
				@RS10InitialDimensionA =			ED.Initial_Dimension_A,
				@RS10FinalDimensionX =				ED.Final_Dimension_X,
				@RS10FinalDimensionY =				ED.Final_Dimension_Y,	
				@RS10FinalDimensionZ =				ED.Final_Dimension_X,
				@RS10FinalDimensionA =				ED.Final_Dimension_A,
				@RS10OrientationX =					ED.Orientation_X,
				@RS10OrientationY =					ED.Orientation_Y,
				@RS10OrientationZ =					ED.Orientation_Z,
				@RS10OrientationA =					ED.Orientation_A,
				@RS10ESignature =					ED.Signature_Id
	FROM		dbo.Events E WITH(NOLOCK) 
				LEFT JOIN dbo.event_Details ED WITH(NOLOCK) 
					ON ED.event_id = E.event_id
				LEFT JOIN dbo.production_starts PPS WITH(NOLOCK) 
					ON PPS.pu_id = E.pu_id 
					AND	E.Timestamp >= PPS.start_time 
					AND	(E.timestamp < PPS.end_time OR PPS.end_time IS NULL)
	WHERE		E.event_id = @ThisEventId							
 

 	-----------------------------------------------------------------------------------------------------------------------
	-- GET RESULT STE USER ID
 	-----------------------------------------------------------------------------------------------------------------------

	SELECT		@RS10UserId = user_id 
	FROM		dbo.users 
	WHERE		username = 'CTS'
 	

	
	IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @ThisEventId) 
	BEGIN 
 	-----------------------------------------------------------------------------------------------------------------------
	-- EVENT DETAILS DOES NOT EXIST					
 	-----------------------------------------------------------------------------------------------------------------------
		INSERT INTO @RS10
		(	RS10_Update_Type,
			RS10_User_Id,
			RS10_Transaction_Type,
			RS10_Transaction_Number,
			RS10_Event_Id,
			RS10_Unit_Id,
 			RS10_Primary_Event_Number,
			RS10_Alternate_Event_Number,
			RS10_Comment_Id,
			RS10_Event_Sub_Type_Id,
			RS10_Original_Product,
			RS10_Applied_Product,
			RS10_Event_Status,
			RS10_Timestamp,
			RS10_Entry_On,
			RS10_Production_Plan_Setup_Detail_Id,
			RS10_Order_Id,
			RS10_Order_Line_Id,
			RS10_Production_Plan_Id,
			RS10_Initial_Dimension_X,
			RS10_Initial_Dimension_Y,
			RS10_Initial_Dimension_Z,
			RS10_Initial_Dimension_A,
			RS10_Final_Dimension_X,
			RS10_Final_Dimension_Y,
			RS10_Final_Dimension_Z,
			RS10_Final_Dimension_A,
			RS10_Orientation_X,
			RS10_Orientation_Y,
			RS10_Orientation_Z,
			RS10_Orientation_A,
			RS10_ESignature
		)
		VALUES
		(	1,																-- Update_type	
			@RS10UserId,													-- User_Id	
			1,																-- RS10_Transaction_Type
			0,																-- RS10_Transaction_Number
			@RS10EventId,													-- RS10_Event_Id
			@RS10UnitId,													-- PU_ID
			@RS10PrimaryEventNumber,										-- Event_num																			
			@Serial,														-- AEN
			@RS10CommentId,													-- Comment_Id
			@RS10EventSubTypeId,											-- Event_Sub_Type_Id
			@RS10OriginalProduct,											-- Original_Product
			@RS10AppliedProduct,											-- Applied_Product
			@RS10EventStatus,												-- Event_Status
			@RS10Timestamp,													-- Timestamp
			@RS10EntryOn,													-- Entry_On
			@RS10ProductionPlanSetupDetailId,								-- Production_Plan_Setup_Detail_Id
			@RS10OrderId,													-- Order_Id
			@RS10OrderLineId,												-- Order_Line_Id
			@RS10ProductionPlanId,											-- Production_Plan_Id
			@RS10InitialDimensionX,											-- Initial_Dimension_X,
			@RS10InitialDimensionY,											-- Initial_Dimension_Y,
			@RS10InitialDimensionZ,											-- Initial_Dimension_Z,
			@RS10InitialDimensionA,											-- Initial_Dimension_A,
			@RS10FinalDimensionX,											-- Final_Dimension_X
			@RS10FinalDimensionY,											-- Final_Dimension_Y
			@RS10FinalDimensionZ,											-- Final_Dimension_Z
			@RS10FinalDimensionA,											-- Final_Dimension_A
			@RS10OrientationX,												-- Orientation_X
			@RS10OrientationY,												-- Orientation_A
			@RS10OrientationZ,												-- Orientation_A
			@RS10OrientationA,												-- Orientation_A
			@RS10ESignature													-- ESignature
		)
		SELECT	10,* FROM @RS10
		SET @Output = 'ED record created'
	END
	ELSE 
	BEGIN
 	-----------------------------------------------------------------------------------------------------------------------
	-- EVENT_DETAILS EXISTS
 	-----------------------------------------------------------------------------------------------------------------------
		
		IF (SELECT COUNT(1) FROM dbo.event_details WITH(NOLOCK) WHERE Alternate_Event_Num = @Serial AND event_id <> @ThisEventId) = 0
		BEGIN
 		-------------------------------------------------------------------------------------------------------------------
		-- VALIDATE IF THE AEN DOES NOT EXIST ANYWHERE ELSE OTHER THAN ON THE CURRENT EVENT
	 	-------------------------------------------------------------------------------------------------------------------
			INSERT INTO @RS10
			(	RS10_Update_Type,
				RS10_User_Id,
				RS10_Transaction_Type,
				RS10_Transaction_Number,
				RS10_Event_Id,
				RS10_Unit_Id,
 				RS10_Primary_Event_Number,
				RS10_Alternate_Event_Number,
				RS10_Comment_Id,
				RS10_Event_Sub_Type_Id,
				RS10_Original_Product,
				RS10_Applied_Product,
				RS10_Event_Status,
				RS10_Timestamp,
				RS10_Entry_On,
				RS10_Production_Plan_Setup_Detail_Id,
				RS10_Order_Id,
				RS10_Order_Line_Id,
				RS10_Production_Plan_Id,
				RS10_Initial_Dimension_X,
				RS10_Initial_Dimension_Y,
				RS10_Initial_Dimension_Z,
				RS10_Initial_Dimension_A,
				RS10_Final_Dimension_X,
				RS10_Final_Dimension_Y,
				RS10_Final_Dimension_Z,
				RS10_Final_Dimension_A,
				RS10_Orientation_X,
				RS10_Orientation_Y,
				RS10_Orientation_Z,
				RS10_Orientation_A,
				RS10_ESignature
			)
			VALUES
			(	1,																-- Update_type	
				@RS10UserId,													-- User_Id	
				2,																-- Transaction_Type
				0,																-- Transaction_Number
				@RS10EventId,													-- Event_Id
				@RS10UnitId,													-- PU_ID
				@RS10PrimaryEventNumber,										-- Event_num
				@Serial,														-- AEN	
				@RS10CommentId,													-- Comment_Id
				@RS10EventSubTypeId,											-- Event_Sub_Type_Id
				@RS10OriginalProduct,											-- Original_Product
				@RS10AppliedProduct,											-- Applied_Product
				@RS10EventStatus,												-- Event_Status
				@RS10Timestamp,													-- Timestamp
				@RS10EntryOn,													-- Entry_On
				@RS10ProductionPlanSetupDetailId,								-- Production_Plan_Setup_Detail_Id
				@RS10OrderId,													-- Order_Id
				@RS10OrderLineId,												-- Order_Line_Id
				@RS10ProductionPlanId,											-- Production_Plan_Id
				@RS10InitialDimensionX,											-- Initial_Dimension_X,
				@RS10InitialDimensionY,											-- Initial_Dimension_Y,
				@RS10InitialDimensionZ,											-- Initial_Dimension_Z,
				@RS10InitialDimensionA,											-- Initial_Dimension_A,
				@RS10FinalDimensionX,											-- Final_Dimension_X
				@RS10FinalDimensionY,											-- Final_Dimension_Y
				@RS10FinalDimensionZ,											-- Final_Dimension_Z
				@RS10FinalDimensionA,											-- Final_Dimension_A
				@RS10OrientationX,												-- Orientation_X
				@RS10OrientationY,												-- Orientation_A
				@RS10OrientationZ,												-- Orientation_A
				@RS10OrientationA,												-- Orientation_A
				@RS10ESignature													-- ESignature
			)
			SELECT	10,* FROM @RS10
			SET @Output = 'Update'
		END
		ELSE 
		BEGIN
 			-------------------------------------------------------------------------------------------------------------------
			-- AEN EXISTS ON OTHER EVENT
 			-------------------------------------------------------------------------------------------------------------------
			SET @Output = 'Serial exists on ' + (SELECT CAST(Event_id AS VARCHAR(50))FROM dbo.event_details WITH(NOLOCK) WHERE Alternate_Event_Num = @Serial AND event_id <> @ThisEventId)
		END
			
	END


END
--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================

GRANT EXECUTE ON [dbo].[spLocal_CTS_Set_Alternate_Event_Num_CalcMgr] TO ctsWebService
GRANT EXECUTE ON [dbo].[spLocal_CTS_Set_Alternate_Event_Num_CalcMgr] TO comxclient