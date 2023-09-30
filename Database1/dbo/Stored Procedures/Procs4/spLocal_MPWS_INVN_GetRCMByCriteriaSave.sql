 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_INVN_GetRCMByCriteriaSave]
		@EventNumMask	VARCHAR(8000)	= NULL,
		@PUId			INT				= NULL,
		@ProdIdMask		VARCHAR(8000)	= NULL,	
		@StatusIdMask	VARCHAR(8000)	= NULL,	
		@LocationIdMask	VARCHAR(8000)	= NULL,
		@StartTime		DATETIME		= NULL,
		@EndTime		DATETIME		= NULL,
		@LUID			VARCHAR(8000)	= NULL,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
 
AS	
-------------------------------------------------------------------------------
-- Get PE info
/*
exec  spLocal_MPWS_INVN_GetRCMByCriteriaSave '1000000000000000003'
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@RowCountEV			INT,
        @RowCountLU			INT,
		@RowCountProd		INT,
		@RowCountStatus		INT,
		@RowCountLocation	INT
		
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PUId					INT									NULL,
	PUDesc					VARCHAR(255)						NULL,
	EventId					INT									NULL,
    EventNum				VARCHAR(255)						NULL,
	InitialDimX		   		FLOAT								NULL,
	FinalDimX				FLOAT								NULL,
	InitialDimA				FLOAT								NULL,
	FinalDimA				FLOAT								NULL,
	AppliedProdId			INT									NULL,
	AppliedProdCode			VARCHAR(255)						NULL,
	AppliedProdDesc			VARCHAR(255)						NULL,
	[TimeStamp]				DATETIME							NULL,
	StatusId				INT									NULL,
	StatusCode				VARCHAR(255)						NULL,
	LocationId				INT									NULL,
	LocationCode			VARCHAR(255)						NULL,
	QAStatusVarId			INT									NULL,
	QAStatus				VARCHAR(25)							NULL,
	SAPLot					VARCHAR(25)							NULL,
	SAPLotVarId				INT									NULL,
	RecFlag 				VARCHAR(25)							NULL,
	RecFlagVarId			INT									NULL,
	LUID					VARCHAR(25)							NULL
)
 
DECLARE @tLUId				Table
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	LUID				VARCHAR(25)							NULL
)
 
DECLARE	@tEventNum			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	EventNum				VARCHAR(25)							NULL
)
 
DECLARE	@tProdId			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ProdId					INT									NULL
)		
 
DECLARE	@tStatusId			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT									NULL
)		
 
DECLARE	@tLocationId		TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	LocationId				INT									NULL
)		
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  Parse strings into table variables
-------------------------------------------------------------------------------
INSERT	@tLUId (LUID)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@LUID,',')
SELECT	@RowCountLU			= @@ROWCOUNT
 
INSERT	@tEventNum (EventNum)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@EventNumMask,',')
SELECT	@RowCountEV			= @@ROWCOUNT
 
INSERT	@tProdId (ProdId)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@ProdIdMask,',')
SELECT	@RowCountProd		= @@ROWCOUNT		
		
INSERT	@tStatusId (StatusId)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@StatusIdMask,',')		
SELECT	@RowCountStatus		= @@ROWCOUNT		
 
INSERT	@tLocationId (LocationId)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@LocationIdMask,',')
SELECT	@RowCountLocation	= @@ROWCOUNT		
-------------------------------------------------------------------------------
-- Validate parameters
-------------------------------------------------------------------------------
IF		@RowCountEV = 0 AND @RowCountLU = 0
		AND	(ISDATE(@StartTime) <> 1
			OR	ISDATE(@EndTime) <> 1
			OR	@PUId IS NULL)
BEGIN
		SELECT	@ErrorCode = -2,
				@ErrorMessage = 'Invalid parameters. Either supply Event Num or Load Unit or valid Production Unit, Start Date and End Date'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-2, 'Invalid parameters. Either supply Event Num or Load Unit or valid Production Unit, Start Date and End Date')
		GOTO	ExitLabel		
END			
-------------------------------------------------------------------------------
-- Get Production event attributes
--
-- Supported combinations
/*
1:EventNum Mask
2:PU/ST/ET/Prod Mask/Status Mask/Location Mask
3:PU/ST/ET/Prod Mask/Status Mask
4:PU/ST/ET/Prod Mask/Location Mask
5:PU/ST/ET/Prod Mask
6:PU/ST/ET/Status Mask/Location Mask
7:PU/ST/ET/Status Mask
8:PU/ST/ET/Location Mask
9:LUID Mask
10:LUID Mask/Status Mask
*/
-------------------------------------------------------------------------------	
-- 1: Get events for the passed event ids (and ignore the other filters)
-------------------------------------------------------------------------------	
IF		@RowCountEV > 0
BEGIN
		INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
				FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
				StatusId, StatusCode, LocationId, LocationCode, LUID)
				SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
						ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
						EV.Applied_Product, NULL, NULL, EV.TimeStamp,
						EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
						FROM	@tEventNum T	
						JOIN	dbo.Events EV				WITH (NOLOCK)
						ON		T.EventNum					= EV.Event_Num
						JOIN	dbo.Event_Details ED		WITH (NOLOCK)
						ON		EV.Event_Id					= ED.Event_Id
						JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
						ON		EV.PU_Id					= PU.PU_Id
END
ELSE
  IF @RowCountLU>0 
 
	IF @RowCountStatus >0
	-------------------------------------------------------------------------------	
	-- 10: By LUID/STATUS
	-------------------------------------------------------------------------------	
    BEGIN
		INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
				FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
				StatusId, StatusCode, LocationId, LocationCode, LUID)
				SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
						ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
						EV.Applied_Product, NULL, NULL, EV.TimeStamp,
						EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
						FROM	@tLUId T	
						JOIN	dbo.Event_Details ED		WITH (NOLOCK)
						ON      T.LUID=ED.Alternate_Event_Num
						JOIN	dbo.Events EV				WITH (NOLOCK)
						ON		EV.Event_Id					= ED.Event_Id
						JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
						ON		EV.PU_Id					= PU.PU_Id
						JOIN    @tStatusId ST				
						ON		ST.StatusId = EV.Event_Status
						
    END
    ELSE
    -------------------------------------------------------------------------------	
	-- 9: By LUID
	-------------------------------------------------------------------------------	
    BEGIN
		INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
				FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
				StatusId, StatusCode, LocationId, LocationCode, LUID)
				SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
						ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
						EV.Applied_Product, NULL, NULL, EV.TimeStamp,
						EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
						FROM	@tLUId T	
						JOIN	dbo.Event_Details ED		WITH (NOLOCK)
						ON      T.LUID=ED.Alternate_Event_Num
						JOIN	dbo.Events EV				WITH (NOLOCK)
						ON		EV.Event_Id					= ED.Event_Id
						JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
						ON		EV.PU_Id					= PU.PU_Id
					
    END
ELSE
 
 
 
	-------------------------------------------------------------------------------	
	-- Ignore event Id Mask and use the other filters
	-------------------------------------------------------------------------------	
	-- 2: By PU/ST/ET and Product, Status and Location
	-------------------------------------------------------------------------------	
		IF	@RowCountProd > 0
			IF	@RowCountStatus > 0
				IF	@RowCountLocation > 0
					INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
							FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
							StatusId, StatusCode, LocationId, LocationCode, LUID)
							SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
									ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
									EV.Applied_Product, NULL, NULL, EV.TimeStamp,
									EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
									FROM	dbo.Events EV				WITH (NOLOCK)
									JOIN	dbo.Event_Details ED		WITH (NOLOCK)
									ON		EV.Event_Id					= ED.Event_Id
									AND		EV.PU_Id					= @PUId
									AND		EV.[TimeStamp]				>= @StartTime
									AND		EV.[TimeStamp]				<= @EndTime
									JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
									ON		EV.PU_Id					= PU.PU_Id
									JOIN	@tProdId TP
									ON		TP.ProdId					= EV.Applied_Product
									JOIN	@tStatusId TS
									ON		TS.StatusId					= EV.Event_Status
									JOIN	@tLocationId TL
									ON		TL.LocationId				= ED.Location_Id
				ELSE
					-------------------------------------------------------------------------------	
					-- 3: By PU/ST/ET and Product, Status 
					-------------------------------------------------------------------------------					
					INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
							FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
							StatusId, StatusCode, LocationId, LocationCode, LUID)
							SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
									ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
									EV.Applied_Product, NULL, NULL, EV.TimeStamp,
									EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
									FROM	dbo.Events EV				WITH (NOLOCK)
									JOIN	dbo.Event_Details ED		WITH (NOLOCK)
									ON		EV.Event_Id					= ED.Event_Id
									AND		EV.PU_Id					= @PUId
									AND		EV.[TimeStamp]				>= @StartTime
									AND		EV.[TimeStamp]				<= @EndTime
									JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
									ON		EV.PU_Id					= PU.PU_Id
									JOIN	@tProdId TP
									ON		TP.ProdId					= EV.Applied_Product
									JOIN	@tStatusId TS
									ON		TS.StatusId					= EV.Event_Status
			ELSE
				IF	@RowCountLocation > 0
						-------------------------------------------------------------------------------	
						-- 4: By PU/ST/ET and Product and Location
						-------------------------------------------------------------------------------	
					INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
							FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
							StatusId, StatusCode, LocationId, LocationCode, LUID)
							SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
									ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
									EV.Applied_Product, NULL, NULL, EV.TimeStamp,
									EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
									FROM	dbo.Events EV				WITH (NOLOCK)
									JOIN	dbo.Event_Details ED		WITH (NOLOCK)
									ON		EV.Event_Id					= ED.Event_Id
									AND		EV.PU_Id					= @PUId
									AND		EV.[TimeStamp]				>= @StartTime
									AND		EV.[TimeStamp]				<= @EndTime
									JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
									ON		EV.PU_Id					= PU.PU_Id
									JOIN	@tProdId TP
									ON		TP.ProdId					= EV.Applied_Product
									JOIN	@tLocationId TL
									ON		TL.LocationId				= ED.Location_Id
				ELSE
						-------------------------------------------------------------------------------	
						-- 5: By PU/ST/ET and Product
						-------------------------------------------------------------------------------	
					INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
							FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
							StatusId, StatusCode, LocationId, LocationCode, LUID)
							SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
									ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
									EV.Applied_Product, NULL, NULL, EV.TimeStamp,
									EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
									FROM	dbo.Events EV				WITH (NOLOCK)
									JOIN	dbo.Event_Details ED		WITH (NOLOCK)
									ON		EV.Event_Id					= ED.Event_Id
									AND		EV.PU_Id					= @PUId
									AND		EV.[TimeStamp]				>= @StartTime
									AND		EV.[TimeStamp]				<= @EndTime
									JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
									ON		EV.PU_Id					= PU.PU_Id
									JOIN	@tProdId TP
									ON		TP.ProdId					= EV.Applied_Product
		ELSE
		IF	@RowCountStatus > 0
				IF	@RowCountLocation > 0
					-------------------------------------------------------------------------------	
					-- 6: By PU/ST/ET and Status and Location
					-------------------------------------------------------------------------------	
					INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
							FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
							StatusId, StatusCode, LocationId, LocationCode, LUID)
							SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
									ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
									EV.Applied_Product, NULL, NULL, EV.TimeStamp,
									EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
									FROM	dbo.Events EV				WITH (NOLOCK)
									JOIN	dbo.Event_Details ED		WITH (NOLOCK)
									ON		EV.Event_Id					= ED.Event_Id
									AND		EV.PU_Id					= @PUId
									AND		EV.[TimeStamp]				>= @StartTime
									AND		EV.[TimeStamp]				<= @EndTime
									JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
									ON		EV.PU_Id					= PU.PU_Id
									JOIN	@tStatusId TS
									ON		TS.StatusId					= EV.Event_Status
									JOIN	@tLocationId TL
									ON		TL.LocationId				= ED.Location_Id
				ELSE
					-------------------------------------------------------------------------------	
					-- 7: By PU/ST/ET and Status 
					-------------------------------------------------------------------------------	
					INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
							FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
							StatusId, StatusCode, LocationId, LocationCode, LUID)
							SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
									ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
									EV.Applied_Product, NULL, NULL, EV.TimeStamp,
									EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
									FROM	dbo.Events EV				WITH (NOLOCK)
									JOIN	dbo.Event_Details ED		WITH (NOLOCK)
									ON		EV.Event_Id					= ED.Event_Id
									AND		EV.PU_Id					= @PUId
									AND		EV.[TimeStamp]				>= @StartTime
									AND		EV.[TimeStamp]				<= @EndTime
									JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
									ON		EV.PU_Id					= PU.PU_Id
									JOIN	@tStatusId TS
									ON		TS.StatusId					= EV.Event_Status
		ELSE					
		IF	@RowCountLocation > 0
			-------------------------------------------------------------------------------	
			-- 8: By PU/ST/ET and Location
			-------------------------------------------------------------------------------	
			INSERT	@tOutput (PUId, PUDesc, EventId, EventNum, InitialDimX, FinalDimX, InitialDimA,
					FinalDimA, AppliedProdId, AppliedProdCode, AppliedProdDesc, [TimeStamp],
					StatusId, StatusCode, LocationId, LocationCode, LUID)
					SELECT	EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
							ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
							EV.Applied_Product, NULL, NULL, EV.TimeStamp,
							EV.Event_Status, NULL, ED.Location_Id, NULL, ED.Alternate_Event_Num
							FROM	dbo.Events EV				WITH (NOLOCK)
							JOIN	dbo.Event_Details ED		WITH (NOLOCK)
							ON		EV.Event_Id					= ED.Event_Id
							AND		EV.PU_Id					= @PUId
							AND		EV.[TimeStamp]				>= @StartTime
							AND		EV.[TimeStamp]				<= @EndTime
							JOIN	dbo.Prod_Units_Base PU			WITH (NOLOCK)
							ON		EV.PU_Id					= PU.PU_Id
							JOIN	@tLocationId TL
							ON		TL.LocationId				= ED.Location_Id
 
IF		@@ROWCOUNT	> 0
		SELECT	@ErrorCode = 1	,
				@ErrorMessage = 'Success'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (1, 'Success')
ELSE
		SELECT	@ErrorCode = -1	,
				@ErrorMessage = 'Production Events Not Found '		
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'Production Events Not Found ')
-------------------------------------------------------------------------------					
-- Get common attributes
-------------------------------------------------------------------------------					
UPDATE	T
		SET	T.AppliedProdCode		= P.Prod_Code,
			T.AppliedProdDesc		= P.Prod_Desc
			FROM	@tOutput T
			JOIN	dbo.Products_Base P					WITH (NOLOCK)
			ON		T.AppliedProdId = P.Prod_Id				
 
UPDATE	T
		SET	T.LocationCode			= L.Location_Code
			FROM	@tOutput T
			JOIN	dbo.Unit_Locations L			WITH (NOLOCK)
			ON		T.LocationId	= L.Location_Id
		
UPDATE	T
		SET	T.StatusCode			= PS.ProdStatus_Desc
			FROM	@tOutput T
			JOIN	dbo.Production_Status PS		WITH (NOLOCK)
			ON		T.StatusId		= PS.ProdStatus_Id
			
 
UPDATE	T
		SET T.QAStatusVarId			= V.Var_Id
			FROM	@tOutput T
			JOIN	dbo.Variables_Base V					WITH (NOLOCK)
			ON		T.PUId	= V.PU_Id
			AND		V.Test_Name		= 'MPWS_INVN_QA_STATUS' 			
			
UPDATE	T
		SET T.SAPLotVarId			= V.Var_Id
			FROM	@tOutput T
			JOIN	dbo.Variables_Base V					WITH (NOLOCK)
			ON		T.PUId			= V.PU_Id
			AND		V.Test_Name		= 'MPWS_INVN_SAP_LOT' 
			
UPDATE	T
		SET T.RecFlagVarId		= V.Var_Id
			FROM	@tOutput T
			JOIN	dbo.Variables_Base V					WITH (NOLOCK)
			ON		T.PUId			= V.PU_Id
			AND		V.Test_Name		= 'MPWS_INVN_REC_FLAG' 
			
			
UPDATE	O
		SET	O.QAStatus				= T.Result
			FROM	@tOutput O
			JOIN	dbo.Tests T						WITH (NOLOCK)
			ON		T.Var_Id		= O.QAStatusVarId
			AND		T.Result_On		= O.TimeStamp
			
UPDATE	O
		SET	O.SAPLot				= T.Result
			FROM	@tOutput O
			JOIN	dbo.Tests T						WITH (NOLOCK)
			ON		T.Var_Id		= O.SAPLotVarId
			AND		T.Result_On		= O.TimeStamp
			
UPDATE	O
		SET	O.RecFlag				= T.Result
			FROM	@tOutput O
			JOIN	dbo.Tests T						WITH (NOLOCK)
			ON		T.Var_Id		= O.RecFlagVarId
			AND		T.Result_On		= O.TimeStamp
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
ExitLabel:
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	Id						Id,
		PUId					PUId,
		PUDesc					PUDesc,
		EventId					EventId,
		EventNum				EventNum,
		CAST(InitialDimX AS DECIMAL(10,3)) as InitialDimX,
		CAST(FinalDimX AS DECIMAL(10,3)) as	FinalDimX,
		CAST(InitialDimA AS DECIMAL(10,3)) as InitialDimA,
		CAST(FinalDimA AS DECIMAL(10,3)) as FinalDimA,
		AppliedProdId			AppliedProdId,
		AppliedProdCode			AppliedProdCode,
		AppliedProdDesc			AppliedProdDesc,
		[TimeStamp]				[TimeStamp],
		StatusId				StatusId,
		StatusCode				StatusCode,
		LocationId				LocationId,
		LocationCode			LocationCode,
		QAStatus				QAStatus,
		SAPLot					SAPLot,
		RecFlag					RecFlag,
		LUID					LUID
		FROM	@tOutput
		ORDER
		BY		Id
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_INVN_GetRCMByCriteriaSave] TO [public]
 
 
 
 
 
 
 
 
 
