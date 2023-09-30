--==============================================================================================================================================
--	Name:		 		splocal_WAMAS_PerformanceTesting
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--==============================================================================================================================================
--	DESCRIPTION: 

--	This stored procedure is used to test the performance of the process of creating request records, updating them, and deleting them. A timed
--	model will fire this stored procedure on a regular interval. For each time it is fired, the stored procedure will perform its basic
--	functions 30 times (setup as a while loop) in order to simulate the activity the system will be put through normally. The order of
--	operations are as follows: Create request record in Proficy --> Obtain RequestId for that record from WAMAS --> Insert the RequestId in the
--	Proficy table --> Request a Cancellation on the WAMAS side for that record --> Delete the record from the Proficy table. Each time the
--	stored procedure runs, records will be created and deleted meaning that only the history table will have evidence of records ever have being
--	inserted in the Open Request table.
--==============================================================================================================================================
--	EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--	Revision		Date		Who					What
--	========		====		===					====
--	1.0				10/6/2017	Austin Agatston		Initial Development
--==============================================================================================================================================
CREATE	PROCEDURE	[dbo].[splocal_WAMAS_PerformanceTesting]
	@op_ReturnCode		INT	=   NULL	OUTPUT,	-- For determining where in this SP the error occurred
	@op_InternalCode	INT	=	NULL	OUTPUT,	-- The error code returned by the SPs called by this one
	@p_ECId				INT	=	NULL,
	@op_StartTime		DATETIME	= NULL	OUTPUT,
	@op_EndTime			DATETIME	= NULL	OUTPUT
AS
SET NOCOUNT ON
--==============================================================================================================================================
--	DECLARE VARIABLES
--	The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@User						VARCHAR(25),
@UserId						INT,
@EditOpenRequestErrorCode	INT,
@OpenRequestWAMASCode		INT,
@OpenRequestErrorCode		INT,
@RequestId					VARCHAR(50),
@CancelRequestWAMASCode		INT,
@CancelRequestErrorCode		INT,
@LoopCount					INT,
@Line						VARCHAR(50),
@RandomInteger2				INT,
@Location					VARCHAR(10),
@RandomBigString1			VARCHAR(50),
@RandomBigString2			VARCHAR(50),
@PrimaryGCas				VARCHAR(50),
@GCas						VARCHAR(50),
@UOM						VARCHAR(50),
@RandomBigString6			VARCHAR(50),
@RequestTime				DATETIME,
@LastUpdateTime				DATETIME,
@EstimatedDeliveryTime		DATETIME
--==============================================================================================================================================
--	DECLARE CONSTANTS
--==============================================================================================================================================
DECLARE
@LOOP_MAX		INT,
@USER_PARAMETER	VARCHAR(50)

--==============================================================================================================================================
--	SET CONSTANTS
--==============================================================================================================================================
SET	@op_ReturnCode		= 0
SET	@op_InternalCode	= 0
SET	@LOOP_MAX			= 30
SET	@USER_PARAMETER		= 'PG_Parm_PerformanceUser'

-------------------------------------------------------------------------------------------------------------------------------------------- 
--	Set User and Starttime
-------------------------------------------------------------------------------------------------------------------------------------------- 
IF	@p_ECId IS NOT NULL
BEGIN
	SET	@User	=
					(
						SELECT CONVERT(VARCHAR(25),ecp.[Value])
						FROM	Event_Configuration_Properties ecp	WITH(NOLOCK)
						JOIN	ED_Field_Properties efp				WITH(NOLOCK)
								ON	efp.ED_Field_Prop_Id = ecp.ED_Field_Prop_Id

						WHERE	ecp.EC_Id = @p_ECId
						AND		efp.Field_Desc = @USER_PARAMETER
					)
END
ELSE
BEGIN
	SET	@User = 'Performance1'
END
			
SET	@UserId	=	(
					SELECT	[User_Id]
					FROM	dbo.Users WITH(NOLOCK)
					WHERE	Username = @User
				)	
--------------------------------------------------------------------------------------------------------------------------------------------
--	Set Open Request Constants
--------------------------------------------------------------------------------------------------------------------------------------------
IF	@User = 'Performance1'
BEGIN
	SET	@PrimaryGCas = '99009908'
END
ELSE 
BEGIN
	SET	@PrimaryGCas = '96595475'
END

SET	@Line					=	'POBH02LP0'	-- Line Id
SET	@Location				=	'OG'	-- LocationId
SET	@RandomBigString1		=	'4201802211044004822'	-- ULID
SET	@UOM					=	'EA'	-- UoM

--------------------------------------------------------------------------------------------------------------------------------------------
--	Initialize Start Time
--------------------------------------------------------------------------------------------------------------------------------------------
SET	@op_StartTime = GETDATE()


BEGIN TRY
--------------------------------------------------------------------------------------------------------------------------------------------
--	Initialize the loop and set the random variables that will be fed into the stored procedures
--------------------------------------------------------------------------------------------------------------------------------------------
	SET	@LoopCount	=	1
	WHILE	@LoopCount	<=	@LOOP_MAX
	BEGIN
		
		
		SET	@RandomInteger2			=	(ABS(Checksum(NewID()) % 10)+1)	-- Quantity
		SET	@RandomBigString2		=	SUBSTRING(CONVERT(VARCHAR(255), NEWID()),0,12)	
		SET	@RandomBigString6		=	SUBSTRING(CONVERT(VARCHAR(255), NEWID()),0,12)
		SET	@RequestTime			=	GETDATE()	-- Request Time
		SET	@LastUpdateTime			=	GETDATE()	-- Last Updated Time
		SET	@EstimatedDeliveryTime	=	GETDATE()	-- EstimatedDeliveryTime

--------------------------------------------------------------------------------------------------------------------------------------------
--	Create the record in Proficy without a RequestId -- Initial Record
--------------------------------------------------------------------------------------------------------------------------------------------
		EXECUTE	dbo.splocal_WAMAS_EditOpenRequest
			@op_ErrorCode				=	@EditOpenRequestErrorCode	OUTPUT,
			@p_TransactionType			=	1,
			@p_RequestId				=	NULL,
			@p_RequestTime				=	@RequestTime,			-- Cannot change
			@p_LocationId				=	@Location,		-- Cannot change
			@p_LineId					=	@Line,		-- Cannot change
			@p_ULID						=	@RandomBigString1,
			@p_ProcessOrder				=	'0',
			@p_VendorLotId				=	NULL,	
			@p_PrimaryGCas				=	@PrimaryGCas,		-- Cannot change
			@p_AlternateGCas			=	NULL,
			@p_GCas						=	@GCas,
			@p_Quantity					=	@RandomInteger2,
			@p_UoM						=	@UOM,
			@p_Status					=	'RequestMaterialPending',
			@p_EstimatedDeliveryTime	=	@EstimatedDeliveryTime,
			@p_LastUpdatedTime			=	@LastUpdateTime,			
			@p_UserId					=	@UserId

		IF	@EditOpenRequestErrorCode < 0
		BEGIN
			SET	@op_InternalCode	=	@EditOpenRequestErrorCode
			SET @op_ReturnCode	=	-1
			GOTO	ErrorFinish
		END

--------------------------------------------------------------------------------------------------------------------------------------------
--	Call the Open Request SP to obtain the RequestId for the initial record
--------------------------------------------------------------------------------------------------------------------------------------------

		EXECUTE	dbo.splocal_WAMAS_OpenRequest
			@op_WAMASReturnCode		=	@OpenRequestWAMASCode	OUTPUT,
			@op_ErrorCode			=	@OpenRequestErrorCode	OUTPUT,
			@op_RequestId			=	@RequestId				OUTPUT,
			@p_RequestTimestamp		=	@RequestTime,								--	Must be consistent with EditOpenRequest
			@p_LocationId			=	@Location,
			@p_LineId				=	@Line,
			@p_PrimaryGCas			=	@PrimaryGCas,
			@p_AlternateGCas		=	NULL,
			@p_Quantity				=	@RandomInteger2,
			@p_UoM					=	@UOM

		IF	@OpenRequestErrorCode < 0
		BEGIN
			SET	@op_InternalCode	=	@OpenRequestErrorCode
			SET @op_ReturnCode	=	-2
			GOTO	ErrorFinish
		END
	
--------------------------------------------------------------------------------------------------------------------------------------------
--	Update the initial record and insert the RequestId. It is important that the RequestTime, LocationId, LineId, and PrimaryGCas
--	do not change from the initial record (used to find the record to update)
--------------------------------------------------------------------------------------------------------------------------------------------
	
		EXECUTE	dbo.splocal_WAMAS_EditOpenRequest
			@op_ErrorCode				=	@EditOpenRequestErrorCode	OUTPUT,
			@p_TransactionType			=	2,
			@p_RequestId				=	@RequestId,
			@p_RequestTime				=	@RequestTime,			-- Cannot change
			@p_LocationId				=	@Location,		-- Cannot change
			@p_LineId					=	@Line,		-- Cannot change
			@p_ULID						=	@RandomBigString1,
			@p_VendorLotId				=	NULL,
			@p_ProcessOrder				=	'0',
			@p_PrimaryGCas				=	@PrimaryGCas,		-- Cannot change
			@p_AlternateGCas			=	NULL,
			@p_GCas						=	@GCas,
			@p_Quantity					=	@RandomInteger2,
			@p_UoM						=	@UOM,
			@p_Status					=	'RequestMaterialPending',		
			@p_EstimatedDeliveryTime	=	@EstimatedDeliveryTime,		
			@p_LastUpdatedTime			=	@LastUpdateTime,
			@p_UserId					=	@UserId
	
		IF	@EditOpenRequestErrorCode < 0
		BEGIN
			SET	@op_InternalCode	=	@EditOpenRequestErrorCode
			SET @op_ReturnCode	=	-3
			GOTO	ErrorFinish
		END	

--------------------------------------------------------------------------------------------------------------------------------------------
--	Cancel the Request on WAMAS side
--------------------------------------------------------------------------------------------------------------------------------------------

		EXECUTE	dbo.splocal_WAMAS_RequestCancellation
			@op_WAMASReturnCode		= @CancelRequestWAMASCode	OUTPUT,
			@op_ErrorCode 			= @CancelRequestErrorCode	OUTPUT,																
			@p_RequestId			= @RequestId,
			@p_RequestTime			= @RequestTime,
			@p_LocationId			= @Location,
			@p_LineId				= @Line,
			@p_PrimaryGCas			= @PrimaryGCas,
			@p_AlternateGCas		= NULL,
			@p_Quantity				= @RandomInteger2,
			@p_UoM					= @UOM,
			@p_UserId				= @UserId

		IF	@CancelRequestErrorCode < 0
		BEGIN
			SET	@op_InternalCode	=	@CancelRequestErrorCode
			SET @op_ReturnCode	=	-4
			GOTO	ErrorFinish
		END	

--------------------------------------------------------------------------------------------------------------------------------------------
--	Remove the record from the Proficy database (open request table)
--------------------------------------------------------------------------------------------------------------------------------------------

		EXECUTE	dbo.splocal_WAMAS_EditOpenRequest
			@op_ErrorCode				=	@EditOpenRequestErrorCode	OUTPUT,
			@p_TransactionType			=	3,
			@p_RequestId				=	@RequestId,
			@p_RequestTime				=	@RequestTime,			-- Cannot change
			@p_LocationId				=	@Location,		-- Cannot change
			@p_LineId					=	@Line,		-- Cannot change
			@p_ULID						=	@RandomBigString1,
			@p_VendorLotId				=	NULL,
			@p_ProcessOrder				=	'0',
			@p_PrimaryGCas				=	@PrimaryGCas,		-- Cannot change
			@p_AlternateGCas			=	NULL,
			@p_GCas						=	@GCas,
			@p_Quantity					=	@RandomInteger2,
			@p_UoM						=	@UOM,
			@p_Status					=	'Cancelled',
			@p_EstimatedDeliveryTime	=	@EstimatedDeliveryTime,
			@p_LastUpdatedTime			=	@LastUpdateTime,
			@p_UserId					=	@UserId
	
		IF	@EditOpenRequestErrorCode < 0
		BEGIN
			SET	@op_InternalCode	=	@EditOpenRequestErrorCode
			SET @op_ReturnCode	=	-5
			GOTO	ErrorFinish
		END	

		SET	@LoopCount = @LoopCount + 1
	END
END TRY
--==============================================================================================================================================
--	Log critcal error messages raised in the main body of logic.
--==============================================================================================================================================
BEGIN CATCH
	
	SET @op_ReturnCode	=	-999
END CATCH
--==============================================================================================================================================
--	Set return code and error message output values
--==============================================================================================================================================
ERRORFinish:
SET	@op_EndTime = GETDATE()
--==============================================================================================================================================
--	Finish
--==============================================================================================================================================
SET NOCOUNT OFF
