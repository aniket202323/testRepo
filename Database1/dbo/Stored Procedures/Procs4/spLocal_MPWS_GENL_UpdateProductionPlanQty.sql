 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_GENL_UpdateProductionPlanQty
	
	Date			Version		Build	Author  
	06-Oct-2016		001			001		Susan Lee (GE Digital)		Initial development
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_GENL_UpdateProductionPlanQty @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 390816, 24000.35
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_UpdateProductionPlanQty]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PP_Id			INT,
	@ForecastQty	FLOAT
	
AS
 
SET NOCOUNT ON;
 
DECLARE
	@ErrorSeverity	INT,
	@RetCode		INT,
	@UserId			INT = (SELECT TOP 1 User_Id FROM dbo.Users_Base WHERE Username = 'ComXClient');
		
SELECT
	@ErrorCode		= 0,
	@ErrorMessage	= 'Initialized';
	
BEGIN TRY
 
	BEGIN TRAN;
	
		EXEC @RetCode = dbo.spServer_DBMgrUpdProdPlan
			@PP_Id			OUTPUT,   --PPId
			2,							--TransType
			97,							--TransNum
			NULL,						--PathId
			NULL,						--CommentId
			NULL,						--ProdId
			NULL,						--ImpliedSequence
			NULL,						--PPStatusId
			NULL,						--PPTypeId
			NULL,						--SourcePPId
			@UserId,						--UserId
			NULL,						--ParentPPId
			NULL,						--ControlType
			NULL,						--ForecastStartTime
			NULL,						--ForecastEndTime
			NULL,						--EntryOn
			@ForecastQty,				--ForecastQuantity
			NULL,						--ProductionRate
			NULL,						--AdjustedQuantity
			NULL,						--BlockNumber
			NULL,						--ProcessOrde
			NULL,						--TransactionTime
			NULL,						--Misc1
			NULL,						--Misc2
			NULL,						--Misc3
			NULL,						--Misc4
			NULL,						--BOMFormulationId
			NULL,						--UserGeneral1
			NULL,						--UserGeneral2
			NULL,						--UserGeneral3
			NULL						--ExtendedInfo
 
		------------------------------------------------------------------------------
		--  Request real-time message publishing
		------------------------------------------------------------------------------
		INSERT	dbo.Local_MPWS_GENL_RealTimeMessages (EventId, ResultsetId, TransactionType, TransNum, InsertedDate, ErrorCode)
			VALUES (@PP_Id, 15, 2, 97, GETDATE(), 0)
			
	COMMIT TRAN;
	
	IF @RetCode > 0
	BEGIN
	
		SELECT 
			@ErrorCode		= 1,
			@ErrorMessage	= 'Success';
	END
	ELSE
	BEGIN
	
		SELECT 
			@ErrorCode		= @RetCode,
			@ErrorMessage	= 'ErrorCode is spServer call Return Code';
			
	END
		
END TRY
BEGIN CATCH
	
	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		
	SELECT
		@ErrorCode = ERROR_NUMBER(),
		@ErrorMessage = ERROR_MESSAGE(),
		@ErrorSeverity = ERROR_SEVERITY();
		
	RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
 
END CATCH;
	
 
 
