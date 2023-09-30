--=====================================================================================================================
--	Name:		 		spLocal_PG_Batch_GetBatchArchiveData_Phase2_Test_Phase2_Test
--	Type:				Stored Procedure
--	Author:				Dan Hinchey
--	Date Created:		2010-09-08
--	Editor Tab Spacing: 4
--=====================================================================================================================
--	DESCRIPTION:
--	
--	The purpose of this strored procedure is to retreive summary data from a Batch History Archive table for individual
--	Batches.  This SP is only design to retreive data from a single Arhive table.
--	
--	The SP will analyse the retreived data and generate error messages for records that to not adhere to the P&G Batch
--	History Interface requirements.
--	
--	Three result sets will be returned by this SP.
--	
--	Result Set 1 (Batch Summary):
--		Returns summary data for each batch.
--	
--	Result Set 2 (Organize S88 Batch Parameters):
--		Returns data for parameters used by Organize S88 Calculation.
--	
--	Result Set 3 (Create Event Component Batch Parameters):
--		Returns data for parameters used by Create Event Component Calculation.
--	
--	Result Set 4 (Test Conformance Batch Parameters):
--		Returns data for parameters used for Test Conformance.
--	
--	Result Set 5 (Error messages):
--		Returns error messages for Batch Archive data issues.
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
--	1.0			2010-09-08	Dan Hinchey		Initial Development
--	1.1			2010-11-24	Dan Hinchey		Added missing column to Organize S88 Result Set.
--											Added Error Severity and Section info to returned error message.
--											Modified some messages.
--	1.2			2010-11-29	Dan Hinchey		Added more error messages.
--	1.3			2010-11-30	Dan Hinchey		Corrected spelling in error messages.
--	1.4			2010-12-08	Dan Hinchey		Added filtering logic when no Test Conformance Parameters are configured.
--=====================================================================================================================
--	EXEC Statement:
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE	@intErrorCode		INT,
			@vchErrorMessage	VARCHAR(1000)
	SELECT	@vchErrorMessage = NULL
	EXEC	@intErrorCode = dbo.spLocal_PG_Batch_GetBatchArchiveData_Phase2_Test
				@vchErrorMessage	OUTPUT,	-- @op_vchErrorMessage
				'784:1959,786:1960',		-- @p_vchDelimitedBatchList
				','							-- @p_vchDelimiter
	SELECT	[Error Code]	=	@intErrorCode,
			[Error Message]	=	@vchErrorMessage
*/
--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_PG_Batch_GetBatchArchiveData_Phase2_Test](
	@op_vchErrorMessage			VARCHAR(1000) OUTPUT,	--	An Output Parameter which will return any 
	@p_vchDelimitedBatchList	VARCHAR(1000),
	@p_vchDelimiter				VARCHAR(1))
AS
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
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
			@intPUId				INT,
			@intIsProductionPoint	INT
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
			@vchProdCode			VARCHAR(50),
			@vchQuantityValue		VARCHAR(50),
			@vchSourceLocation		VARCHAR(50),
			@vchSourceLotId			VARCHAR(50),
			@vchBatchUoM			VARCHAR(50),
			@vchSAPReportValue		VARCHAR(50),
			@vchFilterValue			VARCHAR(50),
			@vchStartHeelPhase		VARCHAR(50),
			@vchTestConfString		VARCHAR(1000),
			@consFilterValue		VARCHAR(10),
			@returnMessage			VARCHAR(1000)
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
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to return error messages
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblBatchArchiveDataErrors TABLE(
			RcdIdx				INT Identity(1,1),
			UniqueId			VARCHAR(12),
			ErrorMessage		VARCHAR(255),
			ErrorSeverity		INT,
			ErrorSectionId		INT)
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to retrieve Organize S88 Configuration attributes
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblCreateECConfiguration TABLE(
			RcdIdx				INT Identity(1,1),
			UniqueId			VARCHAR(12),
			PUId				INT,
			ParmProdCode		VARCHAR(25),
			ParmQuantityValue	VARCHAR(25),
			ParmSourceLocation	VARCHAR(25),
			ParmSourceLotId		VARCHAR(25),
			ParmBatchUoM		VARCHAR(25),
			ParmSAPReportValue	VARCHAR(25),
			ParmFilterValue		VARCHAR(25),
			ParmStartHeelPhase	VARCHAR(25))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to organize data for the Batch Parameters
	-------------------------------------------------------------------------------------------------------------------
	CREATE	TABLE #tblBatchECParameters(
			RcdIdx				INT Identity(1,1),
			PUId				INT,
			UniqueId			VARCHAR(12),
			Phase				VARCHAR(100),
			ParmTime			DATETIME,
			ParmType			VARCHAR(25),
			ParmName			VARCHAR(100),
			ParmValue			VARCHAR(100),
			S88Area				VARCHAR(100),
			S88Cell				VARCHAR(100),
			S88Unit				VARCHAR(100),
			Recipe				VARCHAR(1000))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to return data
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblBatchECParameters TABLE(
			RcdIdx				INT Identity(1,1),
			PUId				INT,
			UniqueId			VARCHAR(12),
			Phase				VARCHAR(100),
			ParmTime			DATETIME,
			ParmType			VARCHAR(25),
			ProductCode			VARCHAR(100),
			NetWeight			VARCHAR(100),
			SourceLocation		VARCHAR(100),
			SourceLotId			VARCHAR(100),
			BatchUoM			VARCHAR(100),
			SAPReport			VARCHAR(100),
			FilterValue			VARCHAR(100),
			StartHeelPhase		VARCHAR(100))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to organize data for the Batch Parameters
	-------------------------------------------------------------------------------------------------------------------
	CREATE	TABLE #tblBatchTestConfParameters(
			RcdIdx				INT Identity(1,1),
			PUId				INT,
			UniqueId			VARCHAR(12),
			Phase				VARCHAR(100),
			ParmTime			DATETIME,
			ParmType			VARCHAR(25),
			ParmName			VARCHAR(100),
			ParmValue			VARCHAR(100))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to define Error Severity Descriptions
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblErrorSeverity TABLE(
			ErrorSeverityId		INT,
			ErrorSeverityDesc	VARCHAR(10))
	-------------------------------------------------------------------------------------------------------------------
	--	Table used to define Result Set Sections
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@tblErrorSections TABLE(
			ErrorSectionId		INT,
			ErrorSectionDesc	VARCHAR(25))
	--=================================================================================================================
	--	INITIALIZE VARIABLES and VARIABLE CONSTANTS
	--	Use this section to initialize variables and set valuse for any variable constants.
	--=================================================================================================================
	SELECT	@intErrorCode			= 0,
			@vchErrorMessage		= '',
			@consFilterValue		= '-9999'
	-------------------------------------------------------------------------------------------------------------------
	--	Define Error Severity Descriptions
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblErrorSeverity(ErrorSeverityId, ErrorSeverityDesc) VALUES(1, 'Critical')
	INSERT	@tblErrorSeverity(ErrorSeverityId, ErrorSeverityDesc) VALUES(2, 'Warning')
	-------------------------------------------------------------------------------------------------------------------
	--	Define Error Section Descriptions
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblErrorSections(ErrorSectionId, ErrorSectionDesc) VALUES(1, 'Summary')
	INSERT	@tblErrorSections(ErrorSectionId, ErrorSectionDesc) VALUES(2, 'Organize S88')
	INSERT	@tblErrorSections(ErrorSectionId, ErrorSectionDesc) VALUES(3, 'Create Consumption')
	INSERT	@tblErrorSections(ErrorSectionId, ErrorSectionDesc) VALUES(4, 'Test Conformance')
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
	--	Get the Create Event Components Configuration attributes
	--=================================================================================================================
	
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
		--	Build SQL String
		---------------------------------------------------------------------------------------------------------------
		
			-----------------------------------------------------------------------------------------------------------
			--	Execute SQL String
			-----------------------------------------------------------------------------------------------------------
			
		---------------------------------------------------------------------------------------------------------------
		--	Increment counter
		---------------------------------------------------------------------------------------------------------------
		SELECT @intCounter = @intCounter + 1
	END
	--=================================================================================================================
	--	Set values of -9999 to NULL
	--=================================================================================================================
	
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
	--	Initialize loop counters
	--=================================================================================================================
	
		---------------------------------------------------------------------------------------------------------------
		--	Increment counter
		---------------------------------------------------------------------------------------------------------------
	
	--=================================================================================================================
	--	Get PUId for units used in Batch
	--=================================================================================================================

	--=================================================================================================================
	--	Set values of -9999 to NULL
	--=================================================================================================================

	--=================================================================================================================
	--	Create sequence of events summary for Create Event Components Batch Data
	--=================================================================================================================

	--=================================================================================================================
	--	Evaluate Batch Header errors
	--=================================================================================================================
	--	Check for "End of Batch" System Message
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	UniqueId,
			'"End of Batch" System Message not reported by Batch System.  Batch not processed by interface.',
			1,
			1
	FROM	#tblBatchHeader
	WHERE	EndOfBatch = 0
	-------------------------------------------------------------------------------------------------------------------
	--	Evaluate if all four S88 layers were used
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	UniqueId,
			'Recipe did not consist of all four S88 Layers (i.e. Batch/Operation/Unit Procedure/Phase).  Batch discarded.',
			1,
			1
	FROM	#tblBatchHeader
	WHERE	RecipeLayers < 4
	-------------------------------------------------------------------------------------------------------------------
	--	Evaluate if Batch has been processed by the interface
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	UniqueId,
			'Batch not processed by interface yet.  Monitor and if this persists there may be an issue with the interface.',
			1,
			1
	FROM	#tblBatchHeader
	WHERE	EndOfBatch <> 0
		AND	Processed = 0
		AND	RecipeLayers = 4
	-------------------------------------------------------------------------------------------------------------------
	--	Evaluate if the same Batch was executed multiple times
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bh.UniqueId,
			'The "' + bh.BatchId + '" Batch was processed ' + CONVERT(VARCHAR(3), UniqueIdCount) + ' times',
			2,
			1
	FROM	(SELECT	BatchId,
					COUNT(UniqueId) AS UniqueIdCount
			FROM	#tblBatchHeader
			GROUP	BY BatchId) sq
		JOIN	#tblBatchHeader	bh
								ON	sq.BatchId = bh.BatchId
	WHERE	UniqueIdCount > 1
	-------------------------------------------------------------------------------------------------------------------
	--	Evaluate if this batch relates to an SAP request
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	UniqueId,
			'BatchId is not an SAP requested Batch.  Batch may be processed by interface but will not be reported to SAP.',
			2,
			1
	FROM	#tblBatchHeader				bh
		LEFT
		JOIN	dbo.Production_Setup	ps	WITH (NOLOCK)
										ON	bh.BatchId = ps.Pattern_Code 
	WHERE	ps.Pattern_Code IS NULL
	--=================================================================================================================
	--	Evaluate Organize S88 errors
	--=================================================================================================================
	--	Check for Product Code parameter
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The "' + @vchProductCodeString + '" parameter is missing.',
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId
	HAVING	COUNT(ProductCode) = 0
	-------------------------------------------------------------------------------------------------------------------
	--	Check for Process Order parameter
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The "' + ParmProcessOrder + '" parameter is missing.',
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId, ParmProcessOrder
	HAVING	COUNT(ProcessOrder) = 0
	-------------------------------------------------------------------------------------------------------------------
	--	Check for Batch Size parameter
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The "' + ParmBatchSize + '" parameter is missing.',
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId, ParmBatchSize
	HAVING	COUNT(BatchSize) = 0
	-------------------------------------------------------------------------------------------------------------------
	--	Check for Batch End parameter
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The "' + ParmBatchEnd + '" parameter is missing.',
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId, ParmBatchEnd
	HAVING	COUNT(BatchEnd) = 0
	-------------------------------------------------------------------------------------------------------------------
	--	Check to see if Batch End parameter was reported as a Phase parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			bp.UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			CASE ParmType
				WHEN 'Batch'
				THEN 'The "' + ParmBatchEnd
						+ '" parameter must be a "Phase" parameter and not a "' + ParmType + '" parameter.'
				WHEN 'Unit Procedure'
				THEN 'The "' + ParmBatchEnd
						+ '" parameter must be a "Phase" parameter and not a "' + ParmType + '" parameter.'
				WHEN 'Operation'
				THEN 'The "' + ParmBatchEnd
						+ '" parameter must be a "Phase" parameter and not an "' + ParmType + '" parameter.'
			END,
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	WHERE	BatchEnd IS NOT NULL
		AND	ParmType <> 'Phase'
	-------------------------------------------------------------------------------------------------------------------
	--	Check for multiple occurances of the Batch End parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'There are ' + CONVERT(VARCHAR(3), COUNT(BatchEnd))
				+ ' occurences of the "' + ParmBatchEnd + '" parameter.',
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId, ParmBatchEnd
	HAVING	COUNT(BatchEnd) > 1
	-------------------------------------------------------------------------------------------------------------------
	--	Check for multiple occurances of the Product Code parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'There are ' + CONVERT(VARCHAR(3), COUNT(ProductCode))
				+ ' occurences of the "' + @vchProductCodeString + '" parameter.',
			2,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId
	HAVING	COUNT(ProductCode) > 1
	-------------------------------------------------------------------------------------------------------------------
	--	Check for multiple occurances of the Process Order parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'There are ' + CONVERT(VARCHAR(3), COUNT(ProcessOrder))
				+ ' occurences of the "' + ParmProcessOrder + '" parameter.',
			2,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId, ParmProcessOrder
	HAVING	COUNT(ProcessOrder) > 1
	-------------------------------------------------------------------------------------------------------------------
	--	Check for multiple occurances of the Batch Size parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'There are ' + CONVERT(VARCHAR(3), COUNT(BatchSize))
				+ ' occurences of the "' + ParmBatchSize + '" parameter.',
			2,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	GROUP	BY bp.UniqueId, ParmBatchSize
	HAVING	COUNT(BatchSize) > 1
	-------------------------------------------------------------------------------------------------------------------
	--	Check to ensure the Batch End parameter was reported during the Batch Report Phase.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The "' + ParmBatchEnd + '" parameter was not reported during the "' + BatchReport + '" phase.',
			1,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
	WHERE	BatchEnd IS NOT NULL
		AND	ParmType = 'Phase'
		AND	CHARINDEX(BatchReport, Phase) = 0
	-------------------------------------------------------------------------------------------------------------------
	--	Validate the value of the Process Order parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The value of "' + ParmProcessOrder + '" in Phase "' + Phase + '" is "' + ProcessOrder + '". This is not a valid Process Order.',
			2,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
		LEFT
		JOIN	dbo.Production_Plan				pp	WITH (NOLOCK)
												ON	bp.ProcessOrder = pp.Process_Order
	WHERE	ProcessOrder IS NOT NULL
		AND	Process_Order IS NULL
	-------------------------------------------------------------------------------------------------------------------
	--	Check for a single valid value of the Process Order parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bh.UniqueId,
			'There are no valid values for the "' + ParmProcessOrder + '" parameter.',
			1,
			2
	FROM	#tblBatchHeader			bh
		LEFT
		JOIN	@tblBatchParameters	bp
												ON	bh.UniqueId = bp.UniqueId
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
		LEFT
		JOIN	dbo.Production_Plan				pp	WITH (NOLOCK)
												ON	bp.ProcessOrder = pp.Process_Order
	GROUP	BY bh.UniqueId, ParmProcessOrder
	HAVING	COUNT(PP_Id) < 1
	ORDER BY bh.UniqueId, ParmProcessOrder
	-------------------------------------------------------------------------------------------------------------------
	--	Validate the value of the product Code parameter.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bp.UniqueId,
			'The value of "' + @vchProductCodeString + '" is "' + bp1.ProductCode +
			 '" which does not match the Process Order (' + Process_Order + ') product of "' + Prod_Code + '".',
			2,
			2
	FROM	@tblBatchParameters					bp
		JOIN	@tblOrganizeS88Configuration	osc
												ON	bp.PUId = osc.PUId
												AND	bp.UniqueId = osc.UniqueId
		JOIN	dbo.Production_Plan				pp	WITH (NOLOCK)
												ON	bp.ProcessOrder = pp.Process_Order
		JOIN	dbo.Products						p	WITH (NOLOCK)
												ON	pp.Prod_Id = p.Prod_Id
		JOIN	@tblBatchParameters				bp1
												ON	bp.UniqueId = bp1.UniqueId
												AND	bp1.ProductCode IS NOT NULL
	WHERE	bp.ProcessOrder IS NOT NULL
		AND	bp1.ProductCode <> Prod_Code
	-------------------------------------------------------------------------------------------------------------------
	--	Validate the Product Code belongs to the Process Order
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	DISTINCT
			bp.UniqueId,
			'The "' + ParmBatchEnd + '" parameter was not reported at the end of the Batch.',
			1,
			2
	FROM	@tblBatchParameters						bp
		JOIN	@tblOrganizeS88Configuration		osc
													ON	bp.PUId = osc.PUId
													AND	bp.UniqueId = osc.UniqueId
		JOIN	(SELECT	UniqueId,
						MAX(ParmTime) AS ParmTime
				FROM	@tblBatchParameters
				GROUP	BY UniqueId)				sq
													ON	bp.UniqueId = sq.UniqueId
	WHERE	BatchEnd IS NOT NULL
		AND	bp.ParmTime < sq.ParmTime
	-------------------------------------------------------------------------------------------------------------------
	--	Check for batches with no Organize S88 parameters.
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblBatchArchiveDataErrors(
			UniqueId,
			ErrorMessage,
			ErrorSeverity,
			ErrorSectionId)
	SELECT	bh.UniqueId,
			'There are no Organize S88 parameters reported for this Batch.',
			1,
			2
	FROM	#tblBatchHeader			bh
		LEFT
		JOIN	@tblBatchParameters	bp
												ON	bh.UniqueId = bp.UniqueId
	WHERE	bp.UniqueId IS NULL											
	--=================================================================================================================
	--	Evaluate Create Event Component errors
	--=================================================================================================================
	--	Check to see if material consumption parameters were reported as a Phase parameter.
	-------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------------------------
	--	Check for materials not flagged to report to SAP.
	-------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------------------------
	--	Check for missing Product Code.
	-------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------------------------
	--	Check for missing Net Weight.
	-------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------------------------
	--	Check for missing Source Location.
	-------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------------------------
	--	Check for missing Lot Id.
	-------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------------------------------------------------------
	--	Check for batches with no consumption parameters.
	-------------------------------------------------------------------------------------------------------------------
										
	--=================================================================================================================
	--	Evaluate Test Conformance errors
	--=================================================================================================================
	--	Check for parameters reported with no value.

	-------------------------------------------------------------------------------------------------------------------
	--	Check for parameters reported multiple times.
	-------------------------------------------------------------------------------------------------------------------
	
	-------------------------------------------------------------------------------------------------------------------
	--	Check for parameters reported against the wrong phase.
	-------------------------------------------------------------------------------------------------------------------
	
	-------------------------------------------------------------------------------------------------------------------
	--	Check for batches with no test conformance parameters.
	-------------------------------------------------------------------------------------------------------------------
	
	-------------------------------------------------------------------------------------------------------------------
	--	Update Create Event Component Error Severity
	-------------------------------------------------------------------------------------------------------------------
	UPDATE	bh
		SET	EventCompErrorSeverity = sq.Error
	FROM	#tblBatchHeader						bh
	JOIN	(SELECT	UniqueId,
					MIN(ErrorSeverity) AS Error
			FROM	@tblBatchArchiveDataErrors
			WHERE	ErrorSectionId = 3
			GROUP	BY UniqueId)				sq
												ON	bh.UniqueId = sq.UniqueId
	-------------------------------------------------------------------------------------------------------------------
	--	Update Test COnformance Error Severity
	-------------------------------------------------------------------------------------------------------------------
	UPDATE	bh
		SET	TestConfErrorSeverity = sq.Error
	FROM	#tblBatchHeader						bh
	JOIN	(SELECT	UniqueId,
					MIN(ErrorSeverity) AS Error
			FROM	@tblBatchArchiveDataErrors
			WHERE	ErrorSectionId = 4
			GROUP	BY UniqueId)				sq
												ON	bh.UniqueId = sq.UniqueId
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
	UPDATE	@tblBatchECParameters
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
	--	Result Set 2 (Organize S88 Batch Parameters):
	--		Returns data for parameters used by Organize S88 Calculation.
	-------------------------------------------------------------------------------------------------------------------
	--SELECT	ParmType,
	--		ParmTime,
	--		COALESCE(Phase, 'NULL')			AS Phase,
	--		COALESCE(ProcessOrder, 'NULL')	AS ProcessOrder,
	--		COALESCE(ProductCode, 'NULL')	AS ProductCode,
	--		COALESCE(BatchSize, 'NULL')		AS BatchSize,
	--		COALESCE(BatchEnd, 'NULL')		AS BatchEnd,
	--		COALESCE(BatchReport, 'NULL')	AS BatchReport,
	--		UniqueId
	--FROM @tblBatchParameters
	--ORDER BY UniqueId	
	Declare @Message VARCHAR(1000),
			@StartDate Datetime,
			@EndDate Datetime

	Select @StartDate = ParmTime from @tblBatchParameters where ParmType = 'Batch'
	Select @EndDate = ParmTime from @tblBatchParameters where BatchEnd = 'BATCH_END'
	--Select @StartDate as Startime, @EndDate as Endtime
	--Select DATEDIFF(day,@StartDate,GETDATE()) as Starttimediff
	--Select DATEDIFF(day,@EndDate,GETDATE()) as EndtimeDiff
	Select @Message = 'The start and end time of batch are within last 7 days'
	 
	IF DATEDIFF(day,@StartDate,GETDATE()) >  2
	BEGIN
		
		SET @Message = 'The Batch is having Start Date more than last 7 Days'
	END

	IF DATEDIFF(day,@EndDate,GETDATE()) > 2
	BEGIN	
		
		SET @Message += ' and The Batch is having End Date more than last 7 Days'
	END

	IF DATEDIFF(day,@StartDate,GETDATE()) > 2 and DATEDIFF(day,@EndDate,GETDATE()) >  2
	BEGIN
		print 'The Batch is having Start Date and End Date more than last 7 Days'
		SET @Message = 'The Batch is having Start Date and End Date more than last 7 Days'
	END
	

	Select @Message as DateCheck

	-------------------------------------------------------------------------------------------------------------------
	--	Result Set 5 (Error messages):
	--		Returns error messages for Batch Archive data issues.
	-------------------------------------------------------------------------------------------------------------------
	
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
