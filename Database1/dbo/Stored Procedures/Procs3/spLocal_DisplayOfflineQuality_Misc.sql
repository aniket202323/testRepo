


--=====================================================================================================================
-- 	Stored Procedure:	spLocal_DisplayOfflineQuality_Misc
-- 	Author:				Roberto del Cid
-- 	Date Created:		2007/02/09
-- 	Sp Type:			stored procedure
-- 	Editor Tab Sp:		4
-----------------------------------------------------------------------------------------------------------------------
--	DESCRITION: 
-- 	The purpose of this stored procedure is to support miscellaneous requirements of the LocalDisplayOfflineQuality.
--  It will return 3 result sets:
--	Miscellaneous information
-- 	Color Scheme
-- 	Labels
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- LocalDisplayOfflineQuality.aspx
-----------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS AND SUB-STORED PROCEDURES:
-- fnLocal_SSI_GetColorScheme
-----------------------------------------------------------------------------------------------------------------------
-- SP SECTIONS:
-- 1.	Declare Variables
-- 2.  	Initilize Values
-- 3.  	Validate sp parameters
-- 3.  	GET Site parameters
-- 4.  	GET Display Options
-- 5. 	GET Color Scheme
-- 6.	GET display labels
-- 7.  	ResultSet1	>>> Misc Info
-- 8.	ResultSet2	>>> Color Scheme
-- 9.	ResultSet3	>>> Display Labels
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2007-03-28	Roberto Del Cid		Initial Development
-- 1.1			2007-03-29	Renata Piedmont		Code Review
-- 1.2			2007-08-17  Roberto del Cid		Change Single Sample Label
-- 1.3 			2007-08-22	Roberto del Cid		Added EventSubtypeId to the result set 
-- 1.4 			2007-09-07	Renata Piedmont		Added code for prompt override
-- 1.5			2007-09-11	Roberto Del Cid		Added a new column in the result set for Label Print
-- 1.6			2008-04-12 	Roberto del Cid		Added code for LabOverVIew
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-- EXEC	dbo.spLocal_DisplayOfflineQuality_Misc
-- @p_intSheetId		= 100,
-- @p_intUserId			= 1
--=====================================================================================================================
CREATE	PROCEDURE dbo.spLocal_DisplayOfflineQuality_Misc
		@p_intSheetId	INT,
		@p_intUserId	INT
AS
SET NOCOUNT ON
--=====================================================================================================================
--	Variable Declaration
--=====================================================================================================================
-- INTEGERS
-----------------------------------------------------------------------------------------------------------------------
 DECLARE	@i								INT, --Counter
 			@intErrorCode					INT,
			@intSheetTypeId					INT,
			@intPagingRcdCount				INT,
			@intLockUnavailableCells		INT,
			@intFormulaCardPropertyId		INT,
			@intEventSubTypeId				INT,
	 		@intSpecSetting					INT,
	 		@intPromptNumber	 			INT,
	 		@intPromptNumberBaseValue		INT,	
	 		@intHdrCellX					INT,
	 		@intHdrCellY					INT,		
 			@intColorSchemeId				INT,
			@intLanguageId					INT,
			@intPrintLabel					INT
-----------------------------------------------------------------------------------------------------------------------
-- VARCHAR
-----------------------------------------------------------------------------------------------------------------------		
 DECLARE	@vchErrorMsg				VARCHAR(1000),
			@vchSheetName				VARCHAR(50),
			@vchEventSubTypeDesc		VARCHAR(50),
			@vchSiteName				VARCHAR(50),
	 		@vchPromptString			VARCHAR(100),
			@vchObjName					VARCHAR(100)	   
-----------------------------------------------------------------------------------------------------------------------
-- TEMPORARY TABLES
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-- Table to get the display configuration
-----------------------------------------------------------------------------------------------------------------------
DECLARE @tblDisplayConfiguration	TABLE		(
		OptionIdx					INT	Identity(1,1),
		DisplayTemplateId			INT			,
		DisplayInstanceId			INT			,
		DisplayOptionId				INT			,
		DisplayOptionDesc			VARCHAR(50)	,
		DisplayOptionDefault		VARCHAR(100),
		DisplayOptionValue			VARCHAR(100))
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 1
-- Returns miscellaneous information back to the display
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblMiscInfo	TABLE	(
		RcdIdx					INT IDENTITY (1,1),
		PagingRcdCount			INT,
		LockUnavailableCells	INT,
		SpecSetting				INT,
		SiteName				VARCHAR(50),
		EventSubtypeId			INT,
		PrintLabelOption		INT,
		ErrorCode				INT	DEFAULT 0,
		ErrorMsg				VARCHAR(1000))
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 2
-- Table stores color scheme result set
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblColorScheme 	TABLE (
		RcdId				INT UNIQUE IDENTITY, -- 0
		CSFieldId			INT,
		CSFieldDesc			VARCHAR(50),
		CSColor				INT)
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 3
-- Table stores labels
-----------------------------------------------------------------------------------------------------------------------
DECLARE @tblLabels 			TABLE (
		RcdIdx				INT IDENTITY (1,1),
		PromptNumber		INT,
		PromptString		VARCHAR(100),
		ObjName				VARCHAR(100),
		HdrCellX			INT,
		HdrCellY			INT)	
--=====================================================================================================================
-- INITIALIZE SP VARIABLES
--=====================================================================================================================
SELECT	@intErrorCode 	= 0,
		@vchErrorMsg 	= ''
-----------------------------------------------------------------------------------------------------------------------
-- @MiscInfo table
-----------------------------------------------------------------------------------------------------------------------
INSERT INTO	@tblMiscInfo (	
			ErrorCode	,
			ErrorMsg	)
VALUES	(	@intErrorCode,
			@vchErrorMsg)
--=====================================================================================================================
-- VALIDATE SP PARAMETERS
--=====================================================================================================================
-- VALIDATE Sheet Id
-----------------------------------------------------------------------------------------------------------------------
SELECT	@p_intSheetId = COALESCE(@p_intSheetId, 0)
IF	NOT EXISTS	(	SELECT	Sheet_Id
					FROM	dbo.Sheets	WITH (NOLOCK)
					WHERE	Sheet_Id = @p_intSheetId)
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 		= 'ERROR: Sheet_Id = ' + CONVERT(VARCHAR(25), @p_intSheetId) + ' doest not exist in the database. CALL IT!'
	GOTO	FINISHError
END
ELSE
BEGIN
	SELECT	@vchSheetName = Sheet_Desc
	FROM	dbo.Sheets
	WHERE	Sheet_Id = @p_intSheetId
END
--=====================================================================================================================
-- GET Site Parameters
--=====================================================================================================================
-- SPECIFICATIONS
-- Return Site Specifications result Set
-- Check Parameter: SpecificationSetting in dbo.Site_Parameters table
-- Business Rule:
-- IF @intSpecSetting = 1 then spec limit analysis is >
-- Else spec limit analysis is >=
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intSpecSetting = COALESCE(Value, 1) 
FROM	dbo.Site_Parameters	WITH (NOLOCK)
WHERE 	Parm_Id = 13
	AND	(HostName = ''
	OR	HostName IS NULL)
-----------------------------------------------------------------------------------------------------------------------
-- ADD to miscellaneous information
-----------------------------------------------------------------------------------------------------------------------	
UPDATE	@tblMiscInfo 
SET	SpecSetting = @intSpecSetting
WHERE	RcdIdx = 1
-----------------------------------------------------------------------------------------------------------------------	
-- Site Name
-----------------------------------------------------------------------------------------------------------------------	
SELECT	@vchSiteName = COALESCE(s.Value, 'Site Name')
FROM	dbo.Site_Parameters s	WITH (NOLOCK)
	JOIN dbo.Parameters	p		WITH (NOLOCK)
								ON p.Parm_Id = s.Parm_Id
WHERE p.Parm_Name = 'SiteName'	
-----------------------------------------------------------------------------------------------------------------------
-- ADD to miscellaneous information
-----------------------------------------------------------------------------------------------------------------------	
UPDATE	@tblMiscInfo 
SET	SiteName = @vchSiteName
WHERE	RcdIdx = 1
--=====================================================================================================================
-- GET Sheet display options
--=====================================================================================================================
-- GET sheet type
-----------------------------------------------------------------------------------------------------------------------	
SELECT 	@intSheetTypeId = Sheet_Type
FROM	dbo.Sheets	WITH (NOLOCK)
WHERE	Sheet_Id = @p_intSheetId
-----------------------------------------------------------------------------------------------------------------------	
-- GET sheet default display options
-----------------------------------------------------------------------------------------------------------------------	
INSERT INTO	@tblDisplayConfiguration (
			DisplayTemplateId            ,
			DisplayOptionId              ,
		    DisplayOptionDesc            ,               
	        DisplayOptionDefault         )
SELECT stdo.Sheet_Type_Id,
	   stdo.Display_Option_Id,
       do.Display_Option_Desc,
       stdo.Display_Option_Default
FROM	dbo.Sheet_Type_Display_Options	stdo
	JOIN	dbo.Display_Options 		do	WITH (NOLOCK) 
           									ON do.Display_Option_Id = stdo.Display_Option_Id
WHERE	stdo.Sheet_Type_Id = @intSheetTypeId
-----------------------------------------------------------------------------------------------------------------------	
-- GET sheet user defined display options
-----------------------------------------------------------------------------------------------------------------------	
UPDATE	@tblDisplayConfiguration
SET		DisplayInstanceId    =	Sheet_Id,
		DisplayOptionValue   =  Value
FROM    @tblDisplayConfiguration 		dc
    JOIN    dbo.Sheet_Display_Options   sdo	WITH (NOLOCK) 
											ON dc.DisplayOptionId = sdo.Display_Option_Id
WHERE	sdo.Sheet_id = @p_intSheetId
-----------------------------------------------------------------------------------------------------------------------
-- GET Color Scheme from display configuration
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intColorSchemeId =  COALESCE(DisplayOptionValue, DisplayOptionDefault, 1)
FROM	@tblDisplayConfiguration
WHERE	DisplayOptionDesc = 'Color Scheme'
-----------------------------------------------------------------------------------------------------------------------
-- GET Paging record count from display configuration
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intPagingRcdCount =  CONVERT(INTEGER, COALESCE(DisplayOptionValue, DisplayOptionDefault))
FROM	@tblDisplayConfiguration
WHERE	DisplayOptionDesc = 'PagingRcdCount'
-----------------------------------------------------------------------------------------------------------------------
-- ADD Paging record count to miscellaneous information
-- Default to 50
-----------------------------------------------------------------------------------------------------------------------
UPDATE	@tblMiscInfo 
SET	PagingRcdCount = COALESCE(@intPagingRcdCount, 50)
WHERE	RcdIdx = 1
-----------------------------------------------------------------------------------------------------------------------
--	GET LockUnavailableCells display option
-- 	Business Rule:
--	If False, then a User can edit any 'AutoLog' data source variable that he/she has Read/Write or higher privilege. 
--	If True, then a User can only edit 'AutoLog' data source variables that he/she has Read/Write or higher privilege, 
--	when that variable has a value in the Tests database. Essentially, he/she can only edit variables that have a 
--	Test Frequency requirement.  If a User has Administrator privilege, then the Display Option is irrelevant. 
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intLockUnavailableCells =  COALESCE(DisplayOptionValue, DisplayOptionDefault, 0)
FROM	@tblDisplayConfiguration
WHERE	DisplayOptionDesc = 'LockUnavailableCells'
-----------------------------------------------------------------------------------------------------------------------
-- ADD LockUnavailableCells to miscellaneous information
-- Default to 0
-----------------------------------------------------------------------------------------------------------------------
UPDATE	@tblMiscInfo 
SET	LockUnavailableCells = COALESCE(@intLockUnavailableCells, 0)
WHERE	RcdIdx = 1
-----------------------------------------------------------------------------------------------------------------------
--	GET EventSubTypeDesc display option
-- 	Business Rule:
--	The event subtype is used to indentify the user defined events that belong to the sample number selected by the user
-- 	In this section of code we only validate if the Event SubType Desc is valid.
--	spLocal_DisplayOfflineQuality_SingleSample will obtain the Event SubType Id and use it in its logic
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@vchEventSubTypeDesc =  COALESCE(DisplayOptionValue, DisplayOptionDefault, '')
FROM	@tblDisplayConfiguration 		
WHERE	DisplayOptionDesc = 'EventSubTypeDesc'
-----------------------------------------------------------------------------------------------------------------------
-- GET Print Label Parameter
-- This parameter indicates when the print Label is activated in the display
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intPrintLabel =  COALESCE(DisplayOptionValue, DisplayOptionDefault, 0)
FROM	@tblDisplayConfiguration 		
WHERE	DisplayOptionDesc = 'PrintLabel'
-----------------------------------------------------------------------------------------------------------------------
UPDATE	@tblMiscInfo 
SET	PrintLabelOption = @intPrintLabel
WHERE	RcdIdx = 1
-----------------------------------------------------------------------------------------------------------------------
-- VALIDATE event Subtype Desc
-----------------------------------------------------------------------------------------------------------------------
-- Check for a NULL Value for EventSubTypeDesc
-----------------------------------------------------------------------------------------------------------------------
IF	LEN(@vchEventSubTypeDesc) = 0
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 		= 'ERROR: EventSubTypeDesc IS NULL Check Sheet Configuration for Sheet = ' + @vchSheetName 
	GOTO	FINISHError
END
-----------------------------------------------------------------------------------------------------------------------
-- Check for an invalid Value for EventSubTypeDesc
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intEventSubTypeId = COALESCE(es.Event_Subtype_Id, 0)
FROM	dbo.Event_SubTypes es
WHERE	Event_SubType_Desc = @vchEventSubTypeDesc
-----------------------------------------------------------------------------------------------------------------------
IF	(@intEventSubTypeId = 0)					
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 	= 'ERROR: EventSubTypeDesc = ' + @vchEventSubTypeDesc + ' does not exist in the database.' 
	GOTO	FINISHError
END
-----------------------------------------------------------------------------------------------------------------------
-- Insert Event Subtype Id
-----------------------------------------------------------------------------------------------------------------------
UPDATE	@tblMiscInfo 
SET	EventSubtypeId = COALESCE(@intEventSubTypeId, 0)
WHERE	RcdIdx = 1
--=====================================================================================================================
-- COLOR SCHEME
-- This section of code is executed when @p_vchOutputType = 'ColorScheme' 
-- it returns 2 result sets, "Miscellaneous Information" and "Color Scheme Details"
-- The color scheme for the display is obtained from display options of the sheet associated with the display
-- The sheet template is "OQ Lab Data Entry"
-- Business Rule:
-- The @p_vchSheetName is NULL the code will default to CS_Id = 1 which is the default color scheme
-- The color schemes of interest to the display are:
-- Autolog cell background
-- Autolog cell foreground (Text)
-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
--	Call a function (fnLocal_SSI_GetColorScheme) and return the Color Scheme result set
-------------------------------------------------------------------------------------------------------------------
INSERT INTO	@tblColorScheme (
			CSFieldId,
			CSFieldDesc,
			CSColor)
SELECT 	CSFieldId, 
		CSFieldDesc, 
		CSColor
FROM	dbo.fnLocal_SSI_GetColorScheme(@intColorSchemeId)
WHERE CsCatId IN(1, 2)  		 		
--=====================================================================================================================
-- LABELS
-- Return Site Labels Result Set
-- TODO for later -- obtain labels using prompt number from dbo.Laguage_Data
-- NOTE: when we change the code to retreive the labels from the database then we have to 
-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------	
-- Retrieve label Information
-------------------------------------------------------------------------------------------------------------------	
-------------------------------------------------------------------------------------------------------------------	
--GET User Language
-------------------------------------------------------------------------------------------------------------------	
SELECT	@intLanguageId =  COALESCE(Value, 0)
FROM	dbo.User_Parameters     WITH(NOLOCK) 
WHERE	User_Id = @p_intUserId  
	AND Parm_Id = 8 
-------------------------------------------------------------------------------------------------------------------	
-- Insert Labels
-- a.	GET all the prompts for English where Prompt_String is not NULL, this will retrieve all the prompts numbers
-- 		that are configured for the display
-- b.	GET the prompts for the language of the user
-- c.	GET the prompt overrride
-- d.	If all else fails the C# has default values for any Prompts that ends up with a NULL value
-------------------------------------------------------------------------------------------------------------------
-- a.	GET all the prompts for English where Prompt_String is not NULL, this will retrieve all the prompts numbers
-- 		that are configured for the display
-------------------------------------------------------------------------------------------------------------------
INSERT 	INTO @tblLabels (
			PromptString)
SELECT 	Prompt_String 
FROM 	dbo.Language_Data WITH(NOLOCK)
WHERE 	Prompt_Number BETWEEN 99828001 AND 99829000
	AND Language_Id = 0
	AND Prompt_String IS NOT NULL
-------------------------------------------------------------------------------------------------------------------
-- b.	GET the prompts for the language of the user
-------------------------------------------------------------------------------------------------------------------
IF	@intLanguageId > 0
BEGIN
	UPDATE	@tblLabels
		SET PromptString = Prompt_String 
	FROM 	@tblLabels	l
		JOIN	dbo.Language_Data ld	WITH(NOLOCK)
										ON	l.PromptNumber = ld.Prompt_Number
		AND Language_Id = @intLanguageId
		AND	ld.Prompt_String IS NOT NULL
END
-------------------------------------------------------------------------------------------------------------------
-- c.	GET the prompt overrride
-------------------------------------------------------------------------------------------------------------------
UPDATE	@tblLabels
	SET PromptString = Prompt_String 
FROM 	@tblLabels	l
	JOIN	dbo.Language_Data ld	WITH(NOLOCK)
									ON	l.PromptNumber = ld.Prompt_Number
	AND Language_Id = -1
	AND	ld.Prompt_String IS NOT NULL
-------------------------------------------------------------------------------------------------------------------
SELECT 	@i = 0,
		@intPromptNumberBaseValue = 0
WHILE @i < 94
BEGIN
	-- Initilize counter
	SELECT @i = @i + 1 
	-- get label and prompt number
	SELECT	@intPromptNumber  	= @intPromptNumberBaseValue + @i,					
			
			@vchObjName 		= CASE @i	WHEN 1 	THEN 'lblSampleId'
											WHEN 2 	THEN 'lblProductionUnit'
											WHEN 3 	THEN 'lblProductDesc'
											WHEN 4 	THEN 'lblSampleStage'
											WHEN 5 	THEN 'lblSampleQuality'
											WHEN 6 	THEN 'lblTestingProgress'
											WHEN 7 	THEN 'lblConformance'
											WHEN 8 	THEN 'lblOutOfLimits'
											WHEN 9 	THEN 'lblOutOfTarget'
											WHEN 10 THEN 'lblSampleTime'
											WHEN 11 THEN 'lblColectedBy'
											WHEN 12 THEN 'lblProductionTime'
											WHEN 13 THEN 'lblLotId'
											WHEN 14 THEN 'lblItemId'
											WHEN 15 THEN 'lblProcessOrder'
											WHEN 16 THEN 'lblResource'
											WHEN 17 THEN 'lblProductCode'
											WHEN 18 THEN 'lblFormulaCard'
											WHEN 19 THEN 'rdbSingleSample'
											WHEN 20 THEN 'rdbMultiSample'
											WHEN 21 THEN 'btnNewSample'																							
											WHEN 22 THEN 'btnSubmit'
											WHEN 23 THEN 'fpSpread1'
											WHEN 24 THEN 'fpSpread1'
											WHEN 25 THEN 'fpSpread1'
											WHEN 26 THEN 'fpSpread1'
											WHEN 27 THEN 'fpSpread1'
											WHEN 28 THEN 'fpSpread1'
											WHEN 29 THEN 'fpSpread1'
											WHEN 30 THEN 'lblSampleHeader'
											WHEN 31 THEN 'lblSampleDetail'
											WHEN 32 THEN 'lblTestSimpleSampleMode'
											WHEN 33 THEN 'lblProductPicture'
											WHEN 34 THEN 'lblUEL'
											WHEN 35 THEN 'lblURL'
											WHEN 36 THEN 'lblUWL'
											WHEN 37 THEN 'lblUUL'
											WHEN 38 THEN 'lblTarget'
											WHEN 39 THEN 'lblLUL'
											WHEN 40 THEN 'lblLWL'	
											WHEN 41 THEN 'lblLRL'
											WHEN 42 THEN 'lblLEL'
											WHEN 43 THEN 'cmtUEL'
											WHEN 44 THEN 'cmtURL'
											WHEN 45 THEN 'cmtUWL'
											WHEN 46 THEN 'cmtUUL'
											WHEN 47 THEN 'cmtTarget'
											WHEN 48 THEN 'cmtLUL'
											WHEN 49 THEN 'cmtLWL'		
											WHEN 50 THEN 'cmtLRL'
											WHEN 51 THEN 'cmtLEL'
											WHEN 52 THEN 'lblUserName'
											WHEN 53 THEN 'hpSignOut'	
											WHEN 54 THEN 'lblNewSampleDay'												
											WHEN 55 THEN 'lblNewSampleMonth'
											WHEN 56 THEN 'lblNewSampleYear'
											WHEN 57 THEN 'lblNewSampleHour'
											WHEN 58 THEN 'lblNewSampleMinute'
											WHEN 59 THEN 'lblNewSampleSecond'
											WHEN 60 THEN 'lblSampleTime2'
											WHEN 61 THEN 'lblNewSampleDepartment'
											WHEN 62 THEN 'lblNewSampleProductionLine'
											WHEN 63 THEN 'lblNewSampleProductionUnit'
											WHEN 64 THEN 'lblNewSampleSampleNumber'
											WHEN 65 THEN 'lblNewSampleStatusWindow'
											WHEN 66 THEN 'btnNewSampleInsertSample'											
											WHEN 67 THEN 'varReject'
											WHEN 68 THEN 'varUser'
											WHEN 69 THEN 'varTarget'
											WHEN 70 THEN 'varWarning'
											WHEN 71 THEN 'btnPrintLabel'
											WHEN 72 THEN 'btnRePrintLabel'
											WHEN 73 THEN 'fpLabOverView'
											WHEN 74 THEN 'fpLabOverView'
											WHEN 75 THEN 'fpLabOverView'
											WHEN 76 THEN 'fpLabOverView'
											WHEN 77 THEN 'fpLabOverView'
											WHEN 78 THEN 'fpLabOverView'
											WHEN 79 THEN 'fpLabOverView'
											WHEN 80 THEN 'fpLabOverView'
											WHEN 81 THEN 'fpLabOverView'
											WHEN 82 THEN 'fpLabOverView'
											WHEN 83 THEN 'fpLabOverView'
											WHEN 84 THEN 'fpLabOverView'
											WHEN 85 THEN 'fpLabOverView'
											WHEN 86 THEN 'fpLabOverView'
											WHEN 87 THEN 'fpLabOverView'
											WHEN 88 THEN 'fpLabOverView'
											WHEN 89 THEN 'fpLabOverView'
											WHEN 90 THEN 'fpLabOverView'
											WHEN 91 THEN 'fpLabOverView'
											WHEN 92 THEN 'fpLabOverView'
											WHEN 93 THEN 'fpLabOverView'
											WHEN 94 THEN 'fpLabOverView'
										END,	
			@intHdrCellX 			= CASE @intPromptNumber
											WHEN 23 THEN 6
											WHEN 24 THEN 10
											WHEN 25 THEN 16	
											WHEN 26 THEN 28
											WHEN 27 THEN 21
											WHEN 28 THEN 36
											WHEN 29 THEN 40	
											WHEN 73 THEN 1	
											WHEN 74 THEN 2	
											WHEN 75 THEN 3	
											WHEN 76 THEN 4	
											WHEN 77 THEN 5	
											WHEN 78 THEN 6	
											WHEN 79 THEN 7
											WHEN 80 THEN 8
											WHEN 81 THEN 9
											WHEN 82 THEN 10
											WHEN 83 THEN 11
											WHEN 84 THEN 12
											WHEN 85 THEN 13
											WHEN 86 THEN 14
											WHEN 87 THEN 15
											WHEN 88 THEN 16
											WHEN 89 THEN 17
											WHEN 90 THEN 18
											WHEN 91 THEN 19
											WHEN 92 THEN 20
											WHEN 93 THEN 21
											WHEN 94 THEN 22
											ELSE NULL	
										  END,
			@intHdrCellY 			= CASE @intPromptNumber
											WHEN 23 THEN 0
											WHEN 24 THEN 0	
											WHEN 25 THEN 0
											WHEN 26 THEN 0
											WHEN 27 THEN 0
											WHEN 28 THEN 0
											WHEN 29 THEN 0	
											WHEN 73 THEN 0
											WHEN 74 THEN 0
											WHEN 75 THEN 0
											WHEN 76 THEN 0
											WHEN 77 THEN 0
											WHEN 78 THEN 0
											WHEN 79 THEN 0
											WHEN 80 THEN 0
											WHEN 81 THEN 0
											WHEN 82 THEN 0
											WHEN 83 THEN 0
											WHEN 84 THEN 0
											WHEN 85 THEN 0
											WHEN 86 THEN 0
											WHEN 87 THEN 0
											WHEN 88 THEN 0
											WHEN 89 THEN 0
											WHEN 90 THEN 0
											WHEN 91 THEN 0
											WHEN 92 THEN 0
											WHEN 93 THEN 0
											WHEN 94 THEN 0
											ELSE NULL
										END				
	-------------------------------------------------------------------------------------------------------------------	
	UPDATE 	@tblLabels 
	SET 	PromptNumber = @intPromptNumber, 			
			ObjName = @vchObjName,
			HdrCellX = @intHdrCellX,		
			HdrCellY =@intHdrCellY		
	WHERE 	RcdIdx = @i				
END		-- END WHILE		
--=====================================================================================================================		
-- RETURN Result Sets
--=====================================================================================================================			
FINISHError:
IF	@intErrorCode > 0
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	-- This error message is returned to the display and trapped by the C# code.
	-- The error message is currently displayed as an alert to inform the user something has failed with the sp
	-------------------------------------------------------------------------------------------------------------------
	UPDATE	@tblMiscInfo 
	SET	ErrorCode = @intErrorCode,
		ErrorMsg = @vchErrorMsg
	WHERE	RcdIdx = 1
	-------------------------------------------------------------------------------------------------------------------
	-- RETURN Result set
	-------------------------------------------------------------------------------------------------------------------	
	SELECT	*	FROM @tblMiscInfo
END
ELSE
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	-- RS1: Miscellaneous result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM @tblMiscInfo
	-------------------------------------------------------------------------------------------------------------------
	-- RS2: Color Scheme result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM	@tblColorScheme
	-------------------------------------------------------------------------------------------------------------------
	-- RS3: Labels Result Set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM	@tblLabels
END
--=====================================================================================================================		
-- END SP
--=====================================================================================================================		
SET NOCOUNT OFF
RETURN


