--=====================================================================================================================
--	Name:		 		spLocal_PG_Batch_GetAllAvailableBatchUnits
--	Type:				Stored Procedure
--	Author:				Dan Hinchey
--	Date Created:		2010-09-09
--	Editor Tab Spacing: 4	
--=====================================================================================================================
--	DESCRIPTION:
--	
--	The purpose of this stored procedure is to return a list of Production Units that are configured as part of a Batch
--	History Interface.  The list of returned units is restricted to units that are configured as the production point
--	on an execution path.
--	
--=====================================================================================================================
--	EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who				What
--	========	====		===				====
--	1.0			2010-09-08	Dan Hinchey		Initial Development
--	1.1			2010-11-24	Dan Hinchey		Filter result set to only include units where IsProductionPoint is True
--=====================================================================================================================
--	EXEC Statement:
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE	@intErrorCode		INT,
			@vchErrorMessage	VARCHAR(1000)
	SELECT	@vchErrorMessage = NULL
	EXEC	@intErrorCode = dbo.spLocal_PG_Batch_GetAllAvailableBatchUnits
				@vchErrorMessage	OUTPUT	-- @op_vchErrorMessage
	SELECT	[Error Code]	=	@intErrorCode,
			[Error Message]	=	@vchErrorMessage
*/
--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_PG_Batch_GetAllAvailableBatchUnits](
	@op_vchErrorMessage		VARCHAR(1000) OUTPUT)	--	An Output Parameter which will return any 
AS
--=================================================================================================================
	--	DECLARE VARIABLES
	--	The following variables will be used as internal variables to this Stored Procedure.
	--=================================================================================================================
	--	INTEGER
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@intErrorCode		INT,
			@intPosition		INT
	-------------------------------------------------------------------------------------------------------------------
	--	VARCHAR
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@vchErrorMessage	VARCHAR(1000)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to return results
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblSelectedBatchUnits TABLE(
			RcdIdx				INT Identity(1,1),
			ArchiveDatabase		VARCHAR(100),
			ArchiveTable		VARCHAR(100),
			Department			VARCHAR(100),
			Line				VARCHAR(100),
			Unit				VARCHAR(100),
			PUId				INT)
	--=================================================================================================================
	--	Retrieve Batch History Interface configuration information.
	--=================================================================================================================
	INSERT	@tblSelectedBatchUnits(
			ArchiveDatabase,
			ArchiveTable,
			Department,
			Line,
			Unit,
			PUId)
	SELECT	ArchiveDatabase,
			ArchiveTable,
			Department,
			Line,
			Unit,
			PUId
	FROM	dbo.fnLocal_PG_Batch_GetInterfaceConfigData()
	WHERE	IsProductionPoint = 12000
	ORDER	BY
			ArchiveDatabase,
			ArchiveTable,
			Department,
			Line,
			Unit
	--=================================================================================================================
	--	Check For Invalid Production Units
	--=================================================================================================================
	IF	@@ROWCOUNT = 0
	BEGIN ;   
		SELECT	@vchErrorMessage = 'No Batch History Units configured.',
				@intErrorCode = 1
		GOTO ERRORFinish 
    END 
	--=================================================================================================================
	--	TRAP Errors
	--=================================================================================================================
	ERRORFinish:
	IF	@intErrorCode > 0
	BEGIN
		SELECT	@op_vchErrorMessage	= @vchErrorMessage
		RETURN	@intErrorCode
	END	
	--=================================================================================================================
	--	Return Results
	--=================================================================================================================
	SELECT	*
	FROM	@tblSelectedBatchUnits
	SELECT	@op_vchErrorMessage	= 'Success'
--=====================================================================================================================
--	Finished.
--=====================================================================================================================
RETURN @intErrorCode
