

/*Step B Creation Of SP*/
CREATE   PROCEDURE [dbo].[spLocal_BDAT_EvaluateBatchDates_test]

--=====================================================================================================================
--	Name:		 		spLocal_BDAT_EvaluateBatchDates_test
--	Type:				Stored Procedure
--	Author:				Pratik Patil
--	Date Created:		2023-09-20
--	Editor Tab Spacing: 4
--=====================================================================================================================
--	DESCRIPTION:
--	
--	The purpose of this strored procedure is to check the Start and End Date/Time. If the timestamps are more than 7 days then it will show the
--	Messages
--	Three result sets will be returned by this SP.
--	
--	Result Set 1 (Batch Summary):
--		Returns summary data for each batch.
--	Result Set 2 :
--		Returns valid message on evaluation of dates of the batch.
--
--	The SP uses the @p_vchDelimitedBatchList input parameter to determine which batches should be analyzed.
--	The Delimited Batch List must consist of a matched ID pairing consisting of a valid UniqueId and PUId pair.
--	A valid list of paired ID's can be created using the spLocal_PG_Batch_GetAvailableBatches stored procedure.
--	
--=====================================================================================================================
--	EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who				What
--	========	====		===				====
--	1.0			2023-09-20  Pratik Patil		Initial Development

--=====================================================================================================================
--	EXEC Statement:
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE	@intErrorCode		INT,
			@vchErrorMessage	VARCHAR(1000)
	SELECT	@vchErrorMessage = NULL
	EXEC	@intErrorCode = dbo.spLocal_BDAT_EvaluateBatchDates_test
				@vchErrorMessage	OUTPUT,	-- @op_vchErrorMessage
				'784:1959,786:1960',		-- @p_vchDelimitedBatchList
				','							-- @p_vchDelimiter
	SELECT	[Error Code]	=	@intErrorCode,
			[Error Message]	=	@vchErrorMessage
*/
--=====================================================================================================================

	@op_vchErrorMessage			VARCHAR(1000) OUTPUT,	--	An Output Parameter which will return any 
	@p_vchDelimitedBatchList	VARCHAR(1000),
	@p_vchDelimiter				VARCHAR(1)
AS
SET NOCOUNT ON

	--=================================================================================================================
	--	DECLARE VARIABLES
	--	The following variables will be used as internal variables to this Stored Procedure.
	--=================================================================================================================
	--	INTEGER,DATETIME
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@intErrorCode			INT,
			@intPosition			INT,
			@intCounter				INT,
			@intMaxRecords			INT,
			@intPUId				INT,
			@intIsProductionPoint	INT,
			@StartDate				Datetime,
			@EndDate				Datetime
	-------------------------------------------------------------------------------------------------------------------
	--	VARCHAR
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@vchErrorMessage		VARCHAR(1000),
			@vchSQLString			NVARCHAR(3000),
			@vchDatabaseName		VARCHAR(255),
			@vchArchiveTableName	VARCHAR(255),
			@vchProductCodeString	VARCHAR(255),
			@vchEndOfBatchString	VARCHAR(255),
			@vchBatchId				VARCHAR(255),
			@vchUniqueId			VARCHAR(12),
			@vchAAProcessOrderDesc	VARCHAR(50),
			@vchBatchSizeDesc		VARCHAR(50),
			@vchBatchEndDesc		VARCHAR(50),
			--@vchProdCode			VARCHAR(50),
			--@vchQuantityValue		VARCHAR(50),
			--@vchSourceLocation		VARCHAR(50),
			--@vchSourceLotId			VARCHAR(50),
			--@vchBatchUoM			VARCHAR(50),
			--@vchSAPReportValue		VARCHAR(50),
			--@vchFilterValue			VARCHAR(50),
			--@vchStartHeelPhase		VARCHAR(50),
			--@vchTestConfString		VARCHAR(1000),
			@consFilterValue		VARCHAR(10),
			--@returnMessage			VARCHAR(1000),
			@Message				VARCHAR(1000)
	--=================================================================================================================
	--	Declare local tables
	--=================================================================================================================
	--	Table used to parse batch list
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblSelectedBatches	TABLE(
			RcdIdx			INT IDENTITY(1,1),
			UniqueIdPUId	VARCHAR(300),
			UniqueId		VARCHAR(12),
			PUId			INT)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to create a list of Batch Units.
	-------------------------------------------------------------------------------------------------------------------
	CREATE	TABLE #tblSelectedBatchUnits(
			RcdIdx				INT Identity(1,1),
			UniqueId			VARCHAR(12),
			S88Area				VARCHAR(100),
			S88Cell				VARCHAR(100),
			S88Unit				VARCHAR(100),
			PUId				INT,
			IsProductionPoint	INT)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to return data
	-------------------------------------------------------------------------------------------------------------------
	CREATE	TABLE #tblBatchHeader(
			RcdIdx					INT Identity(1,1),
			BatchId					VARCHAR(255),
			UniqueId				VARCHAR(12),
			RecordCount				INT,
			RecipeLayers			INT,
			BatchStartTime			DATETIME,
			BatchEndTime			DATETIME,
			Processed				BIT DEFAULT 0,
			EndOfBatch				BIT DEFAULT 0,
			HeaderErrorSeverity		INT DEFAULT 0,
			S88ErrorSeverity		INT DEFAULT 0,
			EventCompErrorSeverity	INT DEFAULT 0,
			TestConfErrorSeverity	INT DEFAULT 0)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to organize data for the Batch Parameters
	-------------------------------------------------------------------------------------------------------------------
	CREATE	TABLE #tblBatchParameters(
			RcdIdx				INT Identity(1,1),
			PUId				INT,
			UniqueId			VARCHAR(12),
			Phase				VARCHAR(100),
			ParmTime			DATETIME,
			ParmType			VARCHAR(25),
			ParmName			VARCHAR(100),
			ParmValue			VARCHAR(100))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to return data
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblBatchParameters TABLE(
			RcdIdx				INT Identity(1,1),
			PUId				INT,
			UniqueId			VARCHAR(12),
			Phase				VARCHAR(100),
			ParmTime			DATETIME,
			ParmType			VARCHAR(25),
			ProductCode			VARCHAR(100),
			ProcessOrder		VARCHAR(100),
			BatchSize			VARCHAR(100),
			BatchEnd			VARCHAR(100),
			BatchReport			VARCHAR(100))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to retrieve Organize S88 Configuration attributes
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblOrganizeS88Configuration TABLE(
			RcdIdx				INT Identity(1,1),
			UniqueId			VARCHAR(12),
			PUId				INT,
			ParmProcessOrder	VARCHAR(25),
			ParmBatchSize		VARCHAR(25),
			ParmBatchEnd		VARCHAR(25),
			ParmBatchReport		VARCHAR(25))
	

	

	--=================================================================================================================
	--	INITIALIZE VARIABLES and VARIABLE CONSTANTS
	--	Use this section to initialize variables and set valuse for any variable constants.
	--=================================================================================================================
	SELECT	@intErrorCode			= 0,
			@vchErrorMessage		= '',
			@consFilterValue		= '-9999'
	
	--=================================================================================================================
	--	VALIDATE INPUT PARAMETERS
	--=================================================================================================================
	IF	@p_vchDelimitedBatchList IS NULL
	OR	@p_vchDelimitedBatchList = ''
	BEGIN
		SELECT 	@intErrorCode = 1,
				@vchErrorMessage = 'Input parameter "@p_vchDelimitedBatchList" is empty.'
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
	IF	@p_vchDelimitedBatchList = @p_vchDelimiter
	BEGIN
		SELECT 	@intErrorCode = 4,
				@vchErrorMessage	= 'Both the @p_vchDelimitedBatchList and @p_vchDelimiter '
									+ ' input paramters have the same value.'
		GOTO ERRORFinish
	END
	--=================================================================================================================
	--	BEGIN LOGIC
	--=================================================================================================================
	--	Remove leading delimiter if it exists.
	-------------------------------------------------------------------------------------------------------------------
	IF	(SELECT CHARINDEX(@p_vchDelimiter, @p_vchDelimitedBatchList)) = 1
	BEGIN
		SELECT	@p_vchDelimitedBatchList = SUBSTRING(@p_vchDelimitedBatchList, 2, LEN(@p_vchDelimitedBatchList))
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Append trailing delimiter if it is missing.
	-------------------------------------------------------------------------------------------------------------------
	IF	(SELECT	CHARINDEX(@p_vchDelimiter,
			SUBSTRING(@p_vchDelimitedBatchList, LEN(@p_vchDelimitedBatchList), LEN(@p_vchDelimitedBatchList)))) = 0
	BEGIN
		SELECT	@p_vchDelimitedBatchList = @p_vchDelimitedBatchList + @p_vchDelimiter
	END
	--=================================================================================================================
	--	Parse string.
	--=================================================================================================================
	WHILE	@p_vchDelimitedBatchList <> ''
	BEGIN
		SELECT @intPosition = CHARINDEX(@p_vchDelimiter, @p_vchDelimitedBatchList) - 1
		---------------------------------------------------------------------------------------------------------------
		--	Following IF statement is used to ignore consecutive delimiters within the string.
		---------------------------------------------------------------------------------------------------------------
		IF	(SELECT	CHARINDEX(@p_vchDelimiter,
				SUBSTRING(@p_vchDelimitedBatchList, @intPosition, LEN(@p_vchDelimitedBatchList)))) <> 1
		BEGIN
			INSERT @tblSelectedBatches(UniqueIdPUId)
			SELECT SUBSTRING(@p_vchDelimitedBatchList, 1, @intPosition)
		END
		SELECT @p_vchDelimitedBatchList = SUBSTRING(@p_vchDelimitedBatchList, @intPosition + 2, LEN(@p_vchDelimitedBatchList))
	END
	--=================================================================================================================
	--	Parse BatchId and UniqueId from Batch List
	--=================================================================================================================
	UPDATE	@tblSelectedBatches
		SET	UniqueId	= LEFT(UniqueIdPUId, CHARINDEX(':', UniqueIdPUId) - 1),
			PUId		= SUBSTRING(UniqueIdPUId, CHARINDEX(':', UniqueIdPUId) + 1, 300)
	--=================================================================================================================
	--	Initialize loop counters
	--=================================================================================================================
	SELECT	@intCounter		= 1,
			@intMaxRecords	= MAX(RcdIdx)
	FROM	@tblSelectedBatches
	--=================================================================================================================
	--	Get Batch Header data for each of the selected batches.
	--=================================================================================================================
	WHILE	@intCounter <= @intMaxRecords
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Initialize loop variables
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSQLString	= NULL,
				@vchUniqueId	= NULL
		---------------------------------------------------------------------------------------------------------------
		--	Get values for specific batch
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchUniqueId			= UniqueId,
				@vchDatabaseName		= ArchiveDatabase,
				@vchArchiveTableName	= ArchiveTable,
				@vchEndOfBatchString	= EndOfBatchString,
				@vchProductCodeString	= ProductCodeString,
				@intPUId				= sb.PUId
		FROM	@tblSelectedBatches								sb
			JOIN	dbo.fnLocal_PG_Batch_GetInterfaceConfigData()	icd
																ON	sb.PUId = icd.PUId
		WHERE	sb.RcdIdx = @intCounter
		---------------------------------------------------------------------------------------------------------------
		--	Build SQL String
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSQLString =
		'SELECT	DISTINCT
				BatchId,
				UniqueId,
				COUNT(BatchId),
				MAX((LEN(recipe) - LEN(REPLACE(recipe, ''\'', ''''))) + 1),
				MIN(lclTime),
				MAX(lclTime),
				CASE
					WHEN MIN(lclTime) > GETDATE()
					THEN 1
					ELSE 0
				END 
		FROM	' + @vchDatabaseName + '.dbo.' + @vchArchiveTableName + ' WITH (NOLOCK) 
		WHERE	UniqueId = ''' + @vchUniqueId + '''
		GROUP	BY BatchId, UniqueId 
		ORDER	BY	UniqueId'
		---------------------------------------------------------------------------------------------------------------
		--	Execute SQL String
		---------------------------------------------------------------------------------------------------------------
		INSERT	#tblBatchHeader(
				BatchId,
				UniqueId,
				RecordCount,
				RecipeLayers,
				BatchStartTime,
				BatchEndTime,
				Processed)
		EXECUTE SP_EXECUTESQL @vchSQLString
		---------------------------------------------------------------------------------------------------------------
		--	Build SQL String
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSQLString =
		'SELECT	DISTINCT
				UniqueId,
				Area,
				ProcCell,
				Unit, ' + CONVERT(VARCHAR(10), @intPUId) + ' 
		FROM	' + @vchDatabaseName + '.dbo.' + @vchArchiveTableName + ' bhd WITH (NOLOCK)
		WHERE	UniqueId = ''' + @vchUniqueId + '''
			AND	Unit IS NOT NULL
			AND	Unit <> ''''
			AND	ProcCell IS NOT NULL
			AND	ProcCell <> '''''
		---------------------------------------------------------------------------------------------------------------
		--	Execute SQL String
		---------------------------------------------------------------------------------------------------------------
		INSERT	#tblSelectedBatchUnits(
				UniqueId,
				S88Area,
				S88Cell,
				S88Unit,
				PUId)
		EXECUTE SP_EXECUTESQL @vchSQLString
		---------------------------------------------------------------------------------------------------------------
		--	Increment counter
		---------------------------------------------------------------------------------------------------------------
		SELECT @intCounter = @intCounter + 1
	END
	--=================================================================================================================
	--	Set the "End of Batch" flag for each batch
	--=================================================================================================================
	SELECT	@vchSQLString = NULL
	SELECT	@vchSQLString =
	'UPDATE	bhd
		SET	EndOfBatch = 1 
	FROM	#tblBatchHeader	bhd 
		JOIN	' + @vchDatabaseName + '.dbo.' + @vchArchiveTableName + '	bh WITH (NOLOCK) 
											ON	bhd.UniqueId = bh.UniqueId 
											AND	bhd.BatchId = bh.BatchId 
	WHERE	Event	= ''System Message'' 
		AND	PValue	= ''' + @vchEndOfBatchString + ''''
	EXECUTE SP_EXECUTESQL @vchSQLString
	--=================================================================================================================
	--	
	--=================================================================================================================
	UPDATE	sbu
		SET	IsProductionPoint = icd.IsProductionPoint,
			PUId = icd.PUId
	FROM	#tblSelectedBatchUnits							sbu
		JOIN	dbo.fnLocal_PG_Batch_GetInterfaceConfigData()	icd
															ON	sbu.S88Area = icd.S88Area
															AND	sbu.S88Cell = icd.S88Cell
															AND	sbu.S88Unit = icd.S88Unit
	--=================================================================================================================
	--	Get the Organize S88 Configuration attributes
	--=================================================================================================================
	INSERT	@tblOrganizeS88Configuration(
			UniqueId,
			PUId,
			ParmProcessOrder,
			ParmBatchSize,
			ParmBatchEnd,
			ParmBatchReport)
	SELECT	DISTINCT
			sbu.UniqueId,
			cd.PUId,
			cd.ParmProcessOrder,
			cd.ParmBatchSize,
			cd.ParmBatchEnd,
			cd.ParmBatchReport
	FROM	#tblSelectedBatchUnits								sbu
		JOIN	dbo.fnLocal_PG_Batch_GetOrganizeS88ConfigData()	cd
																ON	sbu.PUId = cd.PUId
	WHERE	sbu.IsProductionPoint = 1

	--=================================================================================================================
	--	Initialize loop counters
	--=================================================================================================================
	SELECT	@intCounter		= 1,
			@intMaxRecords	= MAX(RcdIdx)
	FROM	@tblOrganizeS88Configuration
	--=================================================================================================================
	--	Get Organize S88 Batch parameter data for each of the selected batches.
	--=================================================================================================================
	WHILE	@intCounter <= @intMaxRecords
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Initialize loop variables
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSQLString			= NULL,
				@vchUniqueId			= NULL,
				@vchAAProcessOrderDesc	= NULL,
				@vchBatchSizeDesc		= NULL,
				@vchBatchEndDesc		= NULL,
				@intPUId				= NULL
		---------------------------------------------------------------------------------------------------------------
		--	Get values for specific batch
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchUniqueId			= UniqueId,
				@vchAAProcessOrderDesc	= ParmProcessOrder,
				@vchBatchSizeDesc		= ParmBatchSize,
				@vchBatchEndDesc		= ParmBatchEnd,
				@intPUId				= PUId
		FROM	@tblOrganizeS88Configuration
		WHERE	RcdIdx = @intCounter
		---------------------------------------------------------------------------------------------------------------
		--	Build SQL String
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSQLString =
		'SELECT	' + CONVERT(VARCHAR(10), @intPUId) + ',
				UniqueId,
				Phase,
				lclTime,
				Descript,
				CASE (LEN(recipe) - LEN(REPLACE(recipe, ''\'', ''''))) + 1
					WHEN 4 THEN ''Phase''
					WHEN 3 THEN ''Unit Procedure''
					WHEN 2 THEN ''Operation''
					WHEN 1 THEN ''Batch''
				END,
				PValue 
		FROM	' + @vchDatabaseName + '.dbo.' + @vchArchiveTableName + ' bhd WITH (NOLOCK)
		WHERE	UniqueId = ''' + @vchUniqueId + '''
			AND	(Descript		= ''' + @vchAAProcessOrderDesc + '''
			OR	Descript		= ''' + @vchBatchSizeDesc + '''
			OR	Descript		= ''' + @vchBatchEndDesc + '''
			OR	Descript		= ''' + @vchProductCodeString + ''')'
		---------------------------------------------------------------------------------------------------------------
		--	Execute SQL String
		---------------------------------------------------------------------------------------------------------------
		INSERT #tblBatchParameters(
			PUId,
			UniqueId,
			Phase,
			ParmTime,
			ParmName,
			ParmType,
			ParmValue)
		EXECUTE SP_EXECUTESQL @vchSQLString
		
		---------------------------------------------------------------------------------------------------------------
		--	Increment counter
		---------------------------------------------------------------------------------------------------------------
		SELECT @intCounter = @intCounter + 1
	END

	--=================================================================================================================
	--	Create sequence of events summary for Organize S88 Batch data.
	--=================================================================================================================
	INSERT	@tblBatchParameters(
			PUId,
			UniqueId,
			Phase,
			ParmTime,
			ParmType,
			ProductCode,
			ProcessOrder,
			BatchSize,
			BatchEnd,
			BatchReport)
	SELECT	bp.PUId,
			bp.UniqueId,
			Phase,
			ParmTime,
			ParmType,
			CASE WHEN ParmName = @vchProductCodeString	THEN ParmValue ELSE NULL END,
			CASE WHEN ParmName = ParmProcessOrder		THEN ParmValue ELSE NULL END,
			CASE WHEN ParmName = ParmBatchSize			THEN ParmValue ELSE NULL END,
			CASE WHEN ParmName = ParmBatchEnd			THEN ParmValue ELSE NULL END,
			CASE WHEN ParmName = ParmBatchEnd			THEN ParmBatchReport ELSE NULL END
	FROM	#tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	ORDER BY bp.UniqueId, ParmTime
	
	--=================================================================================================================
	--	Update timestamps.	Removes 10 years from date because Batch History Interface modifes date to indicate the
	--	batch record was processed.
	--=================================================================================================================
	UPDATE	#tblBatchHeader
			SET	BatchStartTime = DATEADD(yyyy, -10, BatchStartTime)
	WHERE	DATEDIFF(yyyy, GETDATE(), BatchStartTime) > 9
	UPDATE	#tblBatchHeader
			SET	BatchEndTime = DATEADD(yyyy, -10, BatchEndTime)
	WHERE	DATEDIFF(yyyy, GETDATE(), BatchEndTime) > 9
	UPDATE	@tblBatchParameters
			SET	ParmTime = DATEADD(yyyy, -10, ParmTime)
	WHERE	DATEDIFF(yyyy, GETDATE(), ParmTime) > 9

	--=================================================================================================================
	--	TRAP Errors
	--=================================================================================================================
	ERRORFinish:
	IF	@intErrorCode > 0
	BEGIN
		SELECT	@op_vchErrorMessage	= @vchErrorMessage
		DROP TABLE #tblBatchHeader
		DROP TABLE #tblSelectedBatchUnits
		DROP TABLE #tblBatchParameters
		RETURN	@intErrorCode
	END	
	--=================================================================================================================
	--	Return Results
	--=================================================================================================================
	--	Result Set 1 (Batch Summary):
	--		Returns summary data for each batch.
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@op_vchErrorMessage	= 'Success'
	SELECT	Department + '\' + Line + '\' + Unit AS Unit,
			BatchId + ':' + bu.UniqueId AS Batch,
			RecordCount,
			RecipeLayers,
			BatchStartTime,
			BatchEndTime,
			EndOfBatch,
			Processed,
			bu.UniqueId
	FROM	#tblBatchHeader									bu
		JOIN	#tblSelectedBatchUnits						sbu
															ON	bu.UniqueId = sbu.UniqueId
															AND	IsProductionPoint = 1
		JOIN	fnLocal_PG_Batch_GetInterfaceConfigData()	icd
															ON	sbu.PUId = icd.PUId
	ORDER BY bu.UniqueId
	-------------------------------------------------------------------------------------------------------------------
	--	Result Set 2:
	--		Returns Message upon date checks of Batch.
	-------------------------------------------------------------------------------------------------------------------
	SELECT @StartDate = ParmTime FROM @tblBatchParameters WHERE ParmType = 'Batch'
	SELECT @EndDate = ParmTime FROM @tblBatchParameters WHERE BatchEnd = 'BATCH_END'
	SELECT @Message = 'The Batch is having Start Date and End Date within 7 days'

	SELECT @StartDate as Startdate, @EndDate as EndDate
	IF @StartDate IS NULL or  @EndDate IS NULL
	BEGIN
		SET @Message = 'Check for error messages'
	END

	IF DATEDIFF(day,@StartDate,GETDATE()) >  7
	BEGIN
		SET @Message = 'The Batch is having Start Date more than last 7 Days'
	END

	IF DATEDIFF(day,@EndDate,GETDATE()) > 7
	BEGIN	
		SET @Message += ' and The Batch is having End Date more than last 7 Days'
	END

	IF DATEDIFF(day,@StartDate,GETDATE()) > 7 and DATEDIFF(day,@EndDate,GETDATE()) >  7
	BEGIN
		SET @Message = 'The Batch is having Start Date and End Date more than last 7 Days'
	END
	
	SELECT @Message AS DateCheck

	-------------------------------------------------------------------------------------------------------------------
	--	Drop temp tables
	-------------------------------------------------------------------------------------------------------------------
	DROP TABLE #tblBatchHeader
	DROP TABLE #tblSelectedBatchUnits
	DROP TABLE #tblBatchParameters
--=====================================================================================================================
--	Finished.
--=====================================================================================================================
RETURN @intErrorCode
