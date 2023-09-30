--=====================================================================================================================
--	Name:		 		spLocal_PG_Batch_GetAvailableBatches
--	Type:				Stored Procedure
--	Author:				Dan Hinchey
--	Date Created:		2010-09-08
--	Editor Tab Spacing: 4	
--=====================================================================================================================
--	DESCRIPTION:
--	
--	The purpose of this stored procedure is to retreive a list of available batches from a Batch History Archive table
--	for a given list of Production Units.  This SP is only design to retreive data from a single Arhive table.
--	
--	The SP returns a single result set consisting of a list of batches that are currently available in the Archive
--	Table.  One of the fields in the result set will consist of pairing of UniqueId and PUId which can be used to
--	construct a delimited list of batches which can be used as an input to several other spLocal_PG_Batch SP's.
--	
--	The SP uses the @p_vchDelimitedPUIdList input parameter to determine which Production Units should be analyzed.
--	The Delimited List must consist of a list of PUId's.
--	A valid list of PUId's can be created using the spLocal_PG_Batch_GetAvailableBatchUnits stored procedure.
--	
--=====================================================================================================================
--	EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who				What
--	========	====		===				====
--	1.0			2010-09-08	Dan Hinchey		Initial Development
--	1.1			2010-11-24	Dan Hinchey		Added a field to returned result set to hold the concatentated value of the
--											BatchId and UniqueId.  Ordered the result set by BatchId and UniqueId. 
--	1.2			2010-11-30	Dan Hinchey		Added PUDesc, and StartTime to returned result set.
--	1.3			2010-01-01	Dan Hinchey		Fixed logic that was not correctly populating BatchName and UniqueIdPUId.
--	1.4			2010-01-01	Dan Hinchey		Change sort order from BathcName to StartTime DESC
--=====================================================================================================================
--	EXEC Statement:
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE	@intErrorCode		INT,
			@vchErrorMessage	VARCHAR(1000)
	SELECT	@vchErrorMessage = NULL
	EXEC	@intErrorCode = dbo.spLocal_PG_Batch_GetAvailableBatches
				@vchErrorMessage	OUTPUT,	-- @op_vchErrorMessage
				'1957,1958,',				-- @p_vchDelimitedPUIdList
				','							-- @p_vchDelimiter
	SELECT	[Error Code]	=	@intErrorCode,
			[Error Message]	=	@vchErrorMessage
*/
--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_PG_Batch_GetAvailableBatches_test](
	@op_vchErrorMessage		VARCHAR(1000) OUTPUT,	--	An Output Parameter which will return any 
	@p_vchDelimitedPUIdList	VARCHAR(1000),
	@p_vchDelimiter			VARCHAR(1))
AS
--=================================================================================================================
	--	DECLARE VARIABLES
	--	The following variables will be used as internal variables to this Stored Procedure.
	--=================================================================================================================
	--	INTEGER
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@intErrorCode			INT,
			@intPosition			INT,
			@intCounter				INT,
			@intMaxRecords			INT,
			@intIsProductionPoint	INT,
			@intPUId				INT
	-------------------------------------------------------------------------------------------------------------------
	--	VARCHAR
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@vchErrorMessage		VARCHAR(1000),
			@vchSQLString			NVARCHAR(3000),
			@vchBatchDB				VARCHAR(100),
			@vchBatchDBTable		VARCHAR(100),
			@vchEndOfBatchString	VARCHAR(50),
			@vchProductCodeString	VARCHAR(50),
			@vchS88Area				VARCHAR(100),
			@vchS88Cell				VARCHAR(100),
			@vchS88Unit				VARCHAR(100)
	--=================================================================================================================
	--	Declare local tables
	--=================================================================================================================
	--	Table used to parse Path Names
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblBatchUnits	TABLE(
			RcdIdx	INT IDENTITY(1,1),
			PUId	INT)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to return results
	-------------------------------------------------------------------------------------------------------------------
	CREATE	TABLE #tblAvailableBatches(
			RcdIdx				INT Identity(1,1),
			BatchId				VARCHAR(255),
			UniqueId			VARCHAR(12),
			BatchName			VARCHAR(268),
			PUId				INT,
			UniqueIdPUId		VARCHAR(50),
			PUDesc				VARCHAR(50),
			StartTime			DATETIME)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to get configuration data for the selected units
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblSelectedBatchUnits TABLE(
			RcdIdx				INT Identity(1,1),
			PUId				INT,
			S88Area				VARCHAR(100),
			S88Cell				VARCHAR(100),
			S88Unit				VARCHAR(100),
			ArchiveDatabase		VARCHAR(100),
			ArchiveTable		VARCHAR(100),
			EndOfBatchString	VARCHAR(100),
			ProductCodeString	VARCHAR(100),
			IsProductionPoint	BIT)
	--=================================================================================================================
	--	INITIALIZE VARIABLES and VARIABLE CONSTANTS
	--	Use this section to initialize variables and set valuse for any variable constants.
	--=================================================================================================================
	SELECT	@intErrorCode						= 0,
			@vchErrorMessage					= ''
	--=================================================================================================================
	--	VALIDATE INPUT PARAMETERS
	--=================================================================================================================
	IF	@p_vchDelimitedPUIdList IS NULL
	OR	@p_vchDelimitedPUIdList = ''
	BEGIN
		SELECT 	@intErrorCode = 1,
				@vchErrorMessage = 'Input parameter "@p_vchDelimitedPUIdList" is empty.'
		GOTO ERRORFinish
	END
	IF	@p_vchDelimiter IS NULL
	OR	@p_vchDelimiter = ''
	BEGIN
		SELECT 	@intErrorCode = 2,
				@vchErrorMessage = 'Input parameter "@p_vchDelimiter" is empty.'
		GOTO ERRORFinish
	END
	IF	LEN(@p_vchDelimiter) > 1
	BEGIN
		SELECT 	@intErrorCode = 3,
				@vchErrorMessage	= 'Input parameter @p_vchDelimiter = '
									+ @p_vchDelimiter + '. Should only be a single character.'
		GOTO ERRORFinish
	END
	IF	@p_vchDelimitedPUIdList = @p_vchDelimiter
	BEGIN
		SELECT 	@intErrorCode = 4,
				@vchErrorMessage	= 'Both the @p_vchDelimitedPUIdList and @p_vchDelimiter '
									+ ' input paramters have the same value.'
		GOTO ERRORFinish
	END
	--=================================================================================================================
	--	BEGIN LOGIC
	--=================================================================================================================
	--	Remove leading delimiter if it exists.
	-------------------------------------------------------------------------------------------------------------------
	IF	(SELECT CHARINDEX(@p_vchDelimiter, @p_vchDelimitedPUIdList)) = 1
	BEGIN
		SELECT	@p_vchDelimitedPUIdList = SUBSTRING(@p_vchDelimitedPUIdList, 2, LEN(@p_vchDelimitedPUIdList))
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Append trailing delimiter if it is missing.
	-------------------------------------------------------------------------------------------------------------------
	IF	(SELECT	CHARINDEX(@p_vchDelimiter,
			SUBSTRING(@p_vchDelimitedPUIdList, LEN(@p_vchDelimitedPUIdList), LEN(@p_vchDelimitedPUIdList)))) = 0
	BEGIN
		SELECT	@p_vchDelimitedPUIdList = @p_vchDelimitedPUIdList + @p_vchDelimiter
	END
	--=================================================================================================================
	--	Parse string.
	--=================================================================================================================
	WHILE	@p_vchDelimitedPUIdList <> ''
	BEGIN
		SELECT @intPosition = CHARINDEX(@p_vchDelimiter, @p_vchDelimitedPUIdList) - 1
		---------------------------------------------------------------------------------------------------------------
		--	Following IF statement is used to ignore consecutive delimiters within the string.
		---------------------------------------------------------------------------------------------------------------
		IF	(SELECT	CHARINDEX(@p_vchDelimiter,
				SUBSTRING(@p_vchDelimitedPUIdList, @intPosition, LEN(@p_vchDelimitedPUIdList)))) <> 1
		BEGIN
			INSERT @tblBatchUnits(PUId)
			SELECT SUBSTRING(@p_vchDelimitedPUIdList, 1, @intPosition)
		END
		SELECT @p_vchDelimitedPUIdList = SUBSTRING(@p_vchDelimitedPUIdList, @intPosition + 2, LEN(@p_vchDelimitedPUIdList))
	END
	--=================================================================================================================
	--	Get Production Unit Batch Attributes
	--=================================================================================================================
	INSERT	@tblSelectedBatchUnits(
			PUId,
			S88Area,
			S88Cell,
			S88Unit,
			ArchiveDatabase,
			ArchiveTable,
			EndOfBatchString,
			ProductCodeString,
			IsProductionPoint)
	SELECT	icd.PUId,
			S88Area,
			S88Cell,
			S88Unit,
			ArchiveDatabase,
			ArchiveTable,
			EndOfBatchString,
			ProductCodeString,
			IsProductionPoint
	FROM	@tblBatchUnits									bu
		JOIN	dbo.fnLocal_PG_Batch_GetInterfaceConfigData()	icd
															ON	bu.PUId = icd.PUId
	--=================================================================================================================
	--	Check For Invalid Production Units
	--=================================================================================================================
	IF	EXISTS(
		SELECT	bu.PUId
		FROM	@tblBatchUnits				bu
			LEFT
			JOIN	@tblSelectedBatchUnits	sbu
											ON	bu.PUId = sbu.PUId
		WHERE	sbu.PUId IS NULL)
	BEGIN
		SELECT	@vchErrorMessage = @vchErrorMessage + CONVERT(VARCHAR(10), bu.PUId) + ', ',
				@intErrorCode = 5
		FROM	@tblBatchUnits				bu
			LEFT
			JOIN	@tblSelectedBatchUnits	sbu
											ON	bu.PUId = sbu.PUId
		WHERE	sbu.PUId IS NULL
		SELECT	@vchErrorMessage	= 'PUId(s) '
									+ LEFT(@vchErrorMessage, LEN(@vchErrorMessage)-1)
									+ ' not configured for Batch History'
		GOTO ERRORFinish
	END
	--=================================================================================================================
	--	Check For Multiple Interfaces
	--=================================================================================================================
	IF	(SELECT	COUNT(DISTINCT ArchiveDatabase + ArchiveTable)
		FROM	@tblSelectedBatchUnits) > 1
	BEGIN
		SELECT	@vchErrorMessage =	'Please limit the selction of Units to the same ' +
									'Batch History Database and Archive Table.',
				@intErrorCode = 6
		GOTO ERRORFinish
	END
	--=================================================================================================================
	--	Get Interface attributes
	--=================================================================================================================
	SELECT	TOP 1
			@vchBatchDB				= ArchiveDatabase,
			@vchBatchDBTable		= ArchiveTable,
			@vchEndOfBatchString	= EndOfBatchString,
			@vchProductCodeString	= ProductCodeString
	FROM	@tblSelectedBatchUnits
	--=================================================================================================================
	--	Set loop counters
	--=================================================================================================================
	SELECT	@intCounter		= 1,
			@intMaxRecords	= MAX(RcdIdx)
	FROM	@tblSelectedBatchUnits
	--=================================================================================================================
	--	Get Available batches for selected units
	--=================================================================================================================
	WHILE	@intCounter <= @intMaxRecords
	BEGIN
		SELECT	@vchSQLString			= NULL,
				@vchS88Area				= NULL,
				@vchS88Cell				= NULL,
				@vchS88Unit				= NULL,
				@intIsProductionPoint	= NULL,
				@intPUId				= NULL
		SELECT	@vchS88Area				= S88Area,
				@vchS88Cell				= S88Cell,
				@vchS88Unit				= S88Unit,
				@intIsProductionPoint	= IsProductionPoint,
				@intPUId				= PUId
		FROM	@tblSelectedBatchUnits
		WHERE	RcdIdx = @intCounter
		IF	@intIsProductionPoint >= 1
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Build SQL String
			-----------------------------------------------------------------------------------------------------------
			SELECT	@vchSQLString =
			'SELECT	DISTINCT
					BatchId,
					UniqueId, ' + CONVERT(VARCHAR(10), @intPUId) + ', ' + '
					MIN(lclTime)
			FROM	' + @vchBatchDB + '.dbo.' + @vchBatchDBTable + ' WITH (NOLOCK) 
			WHERE	Area = ''' + @vchS88Area + ''' 
				AND	ProcCell = ''' + @vchS88Cell + ''' 
				AND	Unit = ''' + @vchS88Unit + ''' 
				GROUP BY BatchId, UniqueId'

				PRINT @vchSQLString;
			-----------------------------------------------------------------------------------------------------------
			--	Execute SQL String
			-----------------------------------------------------------------------------------------------------------
			INSERT	#tblAvailableBatches(
					BatchId,
					UniqueID,
					PUId,
					StartTime)
			EXECUTE SP_EXECUTESQL @vchSQLString
		END
		---------------------------------------------------------------------------------------------------------------
		--	Increment counter
		---------------------------------------------------------------------------------------------------------------
		SELECT @intCounter = @intCounter + 1
	END
	--=================================================================================================================
	--	Update Identifier and get Unit Description
	--=================================================================================================================
	UPDATE	ab
	SET	PUDesc	= PU_Desc
	FROM	#tblAvailableBatches	ab
		JOIN	dbo.Prod_Units		pu	WITH (NOLOCK)
									ON	ab.PUId = pu.PU_Id
	-------------------------------------------------------------------------------------------------------------------
	--	Populate remaining columns and update Start Time
	-------------------------------------------------------------------------------------------------------------------
	UPDATE	#tblAvailableBatches
	SET	StartTime = CASE
						WHEN	DATEDIFF(yyyy, GETDATE(), StartTime) > 9
						THEN	DATEADD(yyyy, -10, StartTime)
						ELSE	StartTime
					END,
		UniqueIdPUId	= UniqueId + ':' + CONVERT(VARCHAR(50), PUId),
		BatchName		= BatchId + ':' + UniqueId
	--=================================================================================================================
	--	Check for no results
	--=================================================================================================================
	IF	(SELECT	COUNT(BatchId)
		FROM	#tblAvailableBatches) = 0
	BEGIN
		SELECT	@vchErrorMessage =	'No Batches found for selected Units.',
				@intErrorCode = 7
		GOTO ERRORFinish
	END
	--=================================================================================================================
	--	TRAP Errors
	--=================================================================================================================
	ERRORFinish:
	IF	@intErrorCode > 0
	BEGIN
		SELECT	@op_vchErrorMessage	= @vchErrorMessage
		DROP TABLE #tblAvailableBatches
		RETURN	@intErrorCode
	END	
	--=================================================================================================================
	--	Return Results
	--=================================================================================================================
	SELECT	@op_vchErrorMessage	= 'Success'
	SELECT	*
	FROM	#tblAvailableBatches
	ORDER BY StartTime DESC
	DROP TABLE #tblAvailableBatches
--=====================================================================================================================
--	Finished.
--=====================================================================================================================
RETURN @intErrorCode
