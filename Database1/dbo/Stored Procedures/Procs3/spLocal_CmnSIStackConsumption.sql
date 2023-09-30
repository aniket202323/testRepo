
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre
-- Date created			: 29-Jun-2017
-- Version 				: 1.1
-- SP Type				: Call by another SP
-- Caller				: Stor proc trigger by Model 603 (UPACK Tags)
-- Description			: Calculate the consumption and set genealogy when tray is dumped.
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		29-Jun-2017		Ugo Lapierre		Initial Release
-- 1.1		23-Aug-2017		U.Lapierre			Avoid Alternate event num to be lost when event_details updated with spserver
-- 1.2		22-Jan-2018		L.Hudon				if ppId is null because the po is closed on consummed on the last po on the stack
-- 1.3		15-Mar-2018		L.Hudon				make sure the ppid is good
-- 1.4		2018-09-13		Julien B. Ethier	Use PE_WMS_System UDP
-- 1.5		2019-10-31		U.Lapierre			Use spserver to push event to running because the return store proc uses it.  during reload, they go faster than this one which results in consumed status before running.
-- 1.6		2019-11-14		U.lapierre			INC4620097  fix critical incident in Tabler with Table fields
-- 1.7		2023-07-25		L. Hudon			fix issue slowness with pedexecinput UDP, add identity
--================================================================================================
CREATE PROCEDURE [dbo].[spLocal_CmnSIStackConsumption]
	@ECID							INT,	
	@Timestamp						DATETIME,
	@ULID							VARCHAR(50),
	@Quantity						FLOAT,
	@UpackStatus					INT,
	@UserId							INT,
	@FlagDebugOnline				BIT





-- ManualDebug
/*

Declare	@OutputValue	nVARCHAR(25)
Exec spLocal_CmnSIStackConsumption


	
SELECT @OutputValue as OutputValue


*/


AS
SET NOCOUNT ON;

DECLARE 
	@SPNAME							VARCHAR(255),

	--Stack Info
	@StackPuId						INT,
	@StackEventId					INT,
	@StackTimeStamp					DATETIME,
	@StackProdId					INT,
	@stackOG						VARCHAR(10),
	@StackInitialDim				FLOAT,
	@StackStatus					INT,
	@StackPPID						INT,
	@StackFinalDimBefore			FLOAT,

	--Production unit Info
	@ProdPuid						INT,
	@prodEventId					INT,
	@PEIId							INT,
	@CountPEI						INT,
	@WMSSystem						VARCHAR(50),
	@ConsumptionType				INT,

	--Process order info
	@ppid							INT,
	@ppStartTime					DATETIME,
	@ppEndTime						DATETIME,

	--Genealogy info
	@ComponentId					INT,
	@QtyToConsume					FLOAT,
	@ParmChildUnitId				INT,
	@ParmEntryOn					DATETIME,
	@ReportAsConsumption			BIT,
	@ActualFinDim					FLOAT,
	--Update event info
	@RunningStatusId				INT,
	@ConsumedStatusId				INT,
	@ParmEventNum					VARCHAR(50),
	@ParmInitialDimX				FLOAT,
	@ParmInitialDimY				FLOAT,
	@ParmInitialDimZ				FLOAT,
	@ParmInitialDimA				FLOAT,
	@ParmFinalDimY					FLOAT,
	@ParmFinalDimZ					FLOAT,
	@ParmFinalDimA					FLOAT,
	@ParmOrientX					FLOAT,
	@ParmOrientY					FLOAT,
	@ParmOrientZ					FLOAT,
	@ParmOrderId					INT,
	@ParmOrderLineId				INT,
	@ParmPPSetupId					INT,
	@ParmShipmentId					INT,
	@ParmCommentId					INT,
	@ParmAlternateEventNum			VARCHAR(50),
	@ParmConformance				INT,
	@ParmTestPctComplete			FLOAT,		  
	@ParmSecondUserId				INT,
	@ParmApprovedUserId				INT, 
	@ParmApprovedReasonId			INT,
	@ParmUserReasonId				INT,
	@ParmUserSignoffId				INT,
	@ParmExtendedInfo				VARCHAR(200),
	@ParmTestingStatus				INT,
	@ActiveStatus					INT,
	@PathID							INT,
	--V1.5
	@dbeTransactionType		INT,
	@dbeTransNum			INT,
	@dbeConfirmed			INT,
	@dbeEventSubtypeId		INT,
	@dbeUserId				INT,
	@dbeTestingStatus		INT,
	@dbeStartTime			DATETIME,
	@dbeReturnResultSet		INT,
	@dbeConformance			INT,
	@dbeTestPctComplete		INT,
	@dbeSecondUserId		INT,
	@dbeEntryOn				DATETIME,
	@dbeApproverUserId      INT,
	@dbeApproverReasonId    INT,
	@dbeUserReasonId        INT,
	@dbeUserSignoffId       INT,
	@dbeExtendedInfo        VARCHAR(255),
	@dbeCommentId           INT,
	@dbeUpdateType          INT,
	@dbeSourceEvent			INT,
	@dbeSendEventPost		INT,
	@EventSubTypeID			INT,
	@Second					INT,
	@SC						INT,
	@ProdID					INT,
	@EventNum				VARCHAR(50),
	@TableID				INT,
	@tfIdOG					INT,
	@tfidWMSSystem			INT,
	@tfidConsumptionType	INT,
	@tfidReportAsConsumption INT;
------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			Id							INT	IDENTITY,--v1.7
			PUID						INT,
			PEIID						INT,
			OG							VARCHAR(50),
			ConsumptionType				INT,
			WMSSystem					VARCHAR(50),
			ReportAsConsumption			BIT
			);



DECLARE @tblEventComponentUpds TABLE (	-- ResultSetType = 11
			Pre					INT NULL,
			UserId				INT NULL,
			TransactionType		INT NULL,
			TransactionNumber	INT NULL,
			ComponentId			INT NULL,
			EventId				INT NULL,
			SrcEventId			INT NULL,
			DimX				DECIMAL(18,6) NULL,
			DimY				FLOAT NULL,
			DimZ				FLOAT NULL,
			DimA				FLOAT NULL,
			StartCoordinateX	FLOAT NULL, 
			StartCoordinateY	FLOAT NULL, 
			StartCoordinateZ	FLOAT NULL, 
			StartCoordinateA	FLOAT NULL,
			StartTime			DATETIME NULL, 
			TimeStamp			DATETIME NULL, 
			PPComponentId		INT NULL, 
			EntryOn				DATETIME NULL, 
			ExtendedInfo		VARCHAR(255) NULL,
			PEIId				INT,
			ReportAsConsumption	INT,
			ChildunitId			INT,
			ESignatureId		INT
);

DECLARE @tblEventUpds TABLE(		-- ResultSetType = 1
			Id					INT Primary Key Identity,
			TransactionType		INT NULL,
			EventId				INT NULL,
			EventNum			VARCHAR(50) NULL,
			PUId				INT NULL,
			TimeStamp			DATETIME NULL,
 			AppliedProduct		INT NULL,
			SourceEvent			INT NULL,
			EventStatus			INT NULL,
			Confirmed			INT NULL,
			UserId				INT NULL,
			PostUpdate			INT NULL,
			Conformance			INT NULL,
			TestPctComplete		INT NULL,
			StartTime			DATETIME NULL,
			TransNum			INT NULL,
			TestingStatus		INT NULL,
			CommentId			INT NULL,
			EventSubTypeId		INT NULL,
			EntryOn				DATETIME NULL,
			ApprovedUserId		INT,
			SecondUserId		INT,
			ApprovedReasonId	INT,
			UserReasonId			INT,
			UserSignOffId		INT,
			ExtendedInfo		VARCHAR(255)
);


--------------------------------------------------------------
--Beginning of code
-------------------------------------------------------------
SET @SPNAME  = 'spLocal_CmnSIStackConsumption';

IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1000 - SP started',
				@EcId
			);

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1010 SP inputs - ' +
				' @ULID = ' + @ULID + 
				' / @Timestamp = ' + CONVERT(VARCHAR(30),@Timestamp,20) + 
				' / @Quantity = ' + CONVERT(VARCHAR(30),@Quantity) + 
				' / @UpackStatus = ' + CONVERT(VARCHAR(30),@UpackStatus) + 
				' / @UserId = ' + CONVERT(VARCHAR(30),@UserId)			
				,
				@EcId
			);
END;



SELECT @ParmEntryOn  =GETDATE();

SET @ActiveStatus = (SELECT PP_Status_ID FROM dbo.Production_Plan_Statuses WITH(NOLOCK) WHERE PP_Status_Desc ='Active');
----------------------------------------------------------------
--Get Current Stack Information
---------------------------------------------------------------
--Get Pu_id
SET @StackPuId =	(	SELECT pu_id FROM dbo.event_configuration WITH(NOLOCK)	WHERE ec_id = @EcId	);

--Get Stack event id
SET @StackEventId = (	SELECT TOP 1 event_id
						FROM dbo.events e					WITH(NOLOCK)
						JOIN dbo.production_status ps		WITH(NOLOCK)	ON e.event_status = ps.prodStatus_id
						WHERE	e.pu_id = @StackPuId
							AND	e.event_num LIKE @ULID + '%'
							AND ((ps.count_for_inventory = 0 AND ps.count_for_production=0) OR (ps.count_for_inventory = 1 AND ps.count_for_production=1))
						);


IF @StackEventId IS NOT NULL
BEGIN

	--Event related info
	SELECT	@StackTimeStamp		= e.timestamp,
			@StackProdId		= e.applied_product,
			@StackStatus		= e.event_status,
			@StackInitialDim	= ed.initial_dimension_x,
			@ActualFinDim		= ed.final_dimension_x,
			@Stackppid			= ed.pp_id
	FROM dbo.events e			WITH(NOLOCK)
	JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
	WHERE e.event_id = @StackEventId;

	--Get OG
	SELECT @StackOG = CONVERT(VARCHAR(50),pmdmc.value)
	FROM dbo.Products_Aspect_MaterialDefinition	a				WITH(NOLOCK)	
	JOIN dbo.Property_MaterialDefinition_MaterialClass pmdmc	WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionid
																				AND pmdmc.Name = 'Origin Group'
	WHERE a.prod_id = @StackProdId;



	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1100 - ' +
					' @StackEventId = ' + CONVERT(VARCHAR(30),@StackEventId) + 
					' / @StackProdId = ' + CONVERT(VARCHAR(30),@StackProdId) + 
					' / @StackStatus = ' + CONVERT(VARCHAR(30),@StackStatus) + 
					' / @StackInitialDim = ' + CONVERT(VARCHAR(30),@StackInitialDim) + 
					' / @Stackppid = ' + CONVERT(VARCHAR(30),COALESCE(@Stackppid,0)) + 
					' / @StackOG = ' + @StackOG					
					,
					@EcId
				);
	END;

	--get the actual final dim fo the Stack
	SET @StackFinalDimBefore = (SELECT dbo.fnLocal_CmnCalcFinalDimX(@StackEventId));

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1110 - ' +
					' @StackFinalDimBefore = ' + CONVERT(VARCHAR(30),@StackFinalDimBefore) 
					,
					@EcId
				);
	END;

END
ELSE
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1195 Error - Do not find event id for stack'			
				,
				@EcId
			);
	RETURN;
END;





--Get table fields ids
SET @TableID	= (	SELECT TableID 	FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'PRDExec_Inputs'	);


SET @tfIdOG					= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'Origin Group'			AND TableID = @TableID	);
SET @tfidWMSSystem			= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'PE_WMS_System'		AND TableID = @TableID	);
SET @tfidConsumptionType	= (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'ConsumptionType'		AND TableID = @TableID	);
SET @tfidReportAsConsumption = (SELECT Table_Field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = 'ReportAsConsumption'	AND TableID = @TableID	);



----------------------------------------------------------------
--Get event information on the consuming unit
---------------------------------------------------------------
--retrieve the consuming unit using the prdexec_input_source

--Get the RMI properties for the 
INSERT @PRDExecInputs (
						PUID,
						PEIID,
						OG,
						WMSSystem,
						ConsumptionType,
						ReportAsConsumption
						)
SELECT pei.PU_Id, pei.PEI_Id, tfv.Value, tfv2.value, tfv3.value, tfv4.value
FROM dbo.PrdExec_Inputs pei			WITH(NOLOCK)
JOIN dbo.prdExec_Input_sources peis	WITH(NOLOCK)	ON peis.pei_id = pei.pei_id
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv2	WITH(NOLOCK)	ON tfv2.KeyId= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv3	WITH(NOLOCK)	ON tfv3.KeyId= pei.PEI_Id
JOIN dbo.Table_Fields_Values tfv4	WITH(NOLOCK)	ON tfv4.KeyId= pei.PEI_Id
WHERE peis.pu_id = @StackPuId 
	AND tfv.Table_Field_id = @tfIdOG
	AND tfv2.Table_Field_id = @tfidWMSSystem
	AND tfv3.Table_Field_id = @tfidConsumptionType
	AND tfv4.Table_Field_id = @tfidReportAsConsumption;


SET @PathID = (SELECT TOP 1 Path_ID  FROM dbo.PrdExec_Path_Inputs WHERE PEI_ID IN(SELECT PEIID FROM @PRDExecInputs));

--Remove pei of different OG
DELETE @PRDExecInputs WHERE OG <> @StackOG;

--Count number of entry
SET @CountPEI = (SELECT COUNT(peiid) FROM @PRDExecInputs);


--Exit A
IF @CountPEI = 0
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1215 Error - no valid prdExec_inputs found for the OG'			
				,
				@EcId
			);
	RETURN;
END;


--Exit B
IF @CountPEI > 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1225 Error - More than ONE prdExec_inputs is matching'			
				,
				@EcId
			);
	RETURN;
END;





--Validation of the SIManaged and the consumption type.  We expect TRUE and 4.  Otherwise, no consumption.
SELECT	@ConsumptionType = COnsumptionType,
		@WMSSystem = WMSSystem,
		@prodpuid = puid,
		@ReportAsConsumption = ReportAsConsumption
FROM @PRDExecInputs WHERE OG = @StackOG;



IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1230 RMIs - ' +
				' / @ConsumptionType = ' + CONVERT(VARCHAR(30),@ConsumptionType) + 
				' / @WMSSystem = ' + @WMSSystem + 
				' / pu_id of the production unit = ' + CONVERT(VARCHAR(30),@prodpuid)			
				,
				@EcId
			);
END;

--Exit C
IF @ConsumptionType <> 4 OR UPPER(@WMSSystem) <> 'WAMAS'
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1235 Error - Invalid consumption type or SI_Managed value'			
				,
				@EcId
			);
	RETURN;
END;


--Check if we need to work with the current event
IF NOT EXISTS (SELECT event_id FROM dbo.events WITH(NOLOCK) WHERE pu_id = @ProdPuid AND timestamp > @Timestamp )
BEGIN
	--It means it must be the last event_id
	SET	@prodEventId	= (SELECT TOP 1 event_id FROM dbo.events WITH(NOLOCK) WHERE pu_id = @ProdPuid ORDER BY Timestamp DESC);
END
ELSE
BEGIN
	SET	@prodEventId	=  (SELECT e.event_id
							FROM	dbo.events e			WITH(NOLOCK)
							WHERE	e.pu_id = @ProdPuid
								AND	e.start_time < @timestamp
								AND e.timestamp >= @Timestamp	);
END;


--Exit D
IF @prodEventId IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1245 Error - No consuming event_id found'			
				,
				@EcId
			);
	RETURN;
END;

--Get pp_ID
SET @ppid = (SELECT pp_id FROM dbo.event_details WHERE event_id = @prodEventId);



IF @ppid IS NULL   --1.2
	SET @ppid = @StackPPID;

IF @ppid IS NULL   --1.2
	SET  @ppid= (SELECT TOP 1 PP_ID FROM dbo.Production_plan p WITH(NOLOCK) WHERE Path_ID =@PathID  AND pp_STATUS_ID = @ActiveStatus ORDER BY p.Actual_Start_Time DESC );


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1250 production event - ' +
				' / @prodEventId = ' + CONVERT(VARCHAR(30),COALESCE(@prodEventId,'')) + 
				' /@ppid = ' + CONVERT(VARCHAR(30),COALESCE(@ppid,''))
				,
				@EcId
			);
END;




----------------------------------------------------------------
--Make genealogy
---------------------------------------------------------------
--Get Quantity to consumed
SET @QtyToConsume = (SELECT @StackFinalDimBefore - @Quantity);

IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1300 Genealogy - ' +
				' / @QtyToConsume = ' + CONVERT(VARCHAR(30),@QtyToConsume) 
				,
				@EcId
			);
END;


IF @QtyToConsume !=0
BEGIN

	--Execute the SPServer to have genealogy done right away
	-- A new event_component entry for each genealogy consumption instead of update
	EXEC spServer_DBMgrUpdEventComp
	@UserId					,
	@prodEventId			, 
	@ComponentId	OUTPUT	, 
	@StackEventId			, 
	@QtyToConsume			,
	NULL					,
	NULL					,
	NULL					,
	0						,	-- TranNum
	1						,	-- TransType
	@ParmChildUnitId		OUTPUT,				
	NULL					,
	NULL					,
	NULL					,
	NULL					,
	NULL					,	-- StartTime
	@TimeStamp				,	-- TimeStamp
	NULL					, 
	@ParmEntryOn	OUTPUT	, 
	NULL					,	-- ExtendedInfo
	@PEIId			OUTPUT	,
	@ReportAsConsumption;	

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1310 SP server for genealogy Sent'
					,
					@EcId
				);
	END;

	--Send genealogy link in a post result SET
	INSERT	@tblEventComponentUpds (Pre, UserId, TransactionType,		
	TransactionNumber, ComponentId, EventId, SrcEventId, 
	DimX,DimY, DimZ, DimA, 
	StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
	StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
	PEIId, ReportAsConsumption, ESignatureId )

	SELECT	0, @UserId, 1,
	0, Component_Id, Event_Id, Source_Event_Id, 
	@QtyToConsume,Dimension_Y, Dimension_Z, Dimension_A, 
	Start_Coordinate_X,Start_Coordinate_Y, Start_Coordinate_Z, Start_Coordinate_A, 
	Start_Time, @TimeStamp, Parent_Component_Id, Entry_On, Extended_Info,
	PEI_Id, Report_As_Consumption, Signature_Id 
	FROM	dbo.Event_Components WITH(NOLOCK)
	WHERE	Component_Id = @ComponentId	;
END;




----------------------------------------------------------------
--Update production event status
--We may have to Update from Delivered to Running Or Running to Consumed
---------------------------------------------------------------

--get constants
SELECT 	@RunningStatusId = prodStatus_id FROM production_status WHERE prodStatus_desc = 'Running';
IF  @RunningStatusId IS NULL
	SET @RunningStatusId = 4;

SELECT 	@ConsumedStatusId = prodStatus_id FROM production_status WHERE prodStatus_desc = 'Consumed';
IF  @ConsumedStatusId IS NULL
	SET @ConsumedStatusId = 8;


--Case delivered to Running
IF (SELECT COUNT(prodStatus_ID) FROM  dbo.production_Status 
			WHERE prodStatus_id = @StackStatus AND count_for_inventory = 0 AND count_for_production=0) > 0  --Means delivered
			AND (@UpackStatus = 1 	)																		--In progress 
			AND @QtyToConsume > 0																			--There are consumption do do
BEGIN
	--Set event to running

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1410 Status needs to be set Running'
					,
					@EcId
				);
	END;

	SET @StackStatus = @RunningStatusId;


--V1.5
SELECT
		@dbeTransactionType                = 2,
		@dbeTransNum                       = 0,	
		@EventNum						   = Event_Num,
		@dbeConfirmed                      = Confirmed,
		@dbeUserId                         = @UserID,  
		@dbeEventSubtypeId                 = Event_Subtype_Id,
		@dbeTestingStatus                  = Testing_Status,
		@dbeStartTime                      = Start_Time,	
		@Timestamp							= Timestamp,		
		@dbeReturnResultSet                = 0,
		@dbeConformance                    = Conformance,
		@dbeTestPctComplete                = Testing_Prct_Complete,
		@dbeSecondUserId                   = Second_User_Id,
		@dbeApproverUserId                 = Approver_User_Id,
		@dbeApproverReasonId               = Approver_Reason_Id,
		@dbeUserReasonId                   = User_Reason_Id,
		@dbeUserSignoffId                  = User_Signoff_Id,
		@dbeExtendedInfo                   = Extended_Info,
		@dbeCommentId                      = Comment_Id,
		@ProdID							   = applied_product,
		@dbeUpdateType                     = 0         -- 0 Pre Update.  Database Manager writes to db and sends to client
														-- 1 Post Update - Client Update 

FROM	dbo.Events WITH(NOLOCK)
WHERE	Event_Id = @StackEventId;
				


EXECUTE		@SC = dbo.spServer_DBMgrUpdEvent
			@StackEventId OUTPUT,
			@EventNum,
			@StackPUID,
			@Timestamp,
			@ProdID,
			@dbeSourceEvent,
			@StackStatus,
			@dbeTransactionType,
			@dbeTransNum,
			@dbeUserId,
			@dbeCommentId,
			@dbeEventSubtypeId,
			@dbeTestingStatus,
			@dbeStartTime,
			@dbeEntryOn             OUTPUT,
			@dbeReturnResultSet,
			@dbeConformance         OUTPUT,
			@dbeTestPctComplete     OUTPUT,
			@dbeSecondUserId,
			@dbeApproverUserId,
			@dbeApproverReasonId,
			@dbeUserReasonId,
			@dbeUserSignoffId,
			@dbeExtendedInfo,
			@dbeSendEventPost;

--end of V1.5




	INSERT	@tblEventUpds (TransactionType, EventId, EventNum, PUId, TimeStamp,       
	AppliedProduct, SourceEvent, EventStatus, Confirmed, UserId, PostUpdate,
	Conformance, TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
	EventSubTypeId, EntryOn,
	ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo)
	SELECT	2, Event_Id, Event_Num, PU_Id, TimeStamp,
			Applied_Product, Source_Event, @StackStatus, Confirmed, @UserId, 1,
			Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
			Comment_Id, Event_SubType_Id, Entry_On,
			Approver_User_Id, Second_User_Id, Approver_Reason_Id, User_Reason_Id, User_SignOff_Id, Extended_Info
	FROM	dbo.Events WITH(NOLOCK)
	WHERE	Event_Id = @StackEventId;




END;


--Case Running to Consumed
--IF (SELECT COUNT(prodStatus_ID) FROM  dbo.production_Status WHERE prodStatus_id = @StackStatus AND count_for_inventory = 1 AND count_for_production=1) > 0  --Means Running
--	AND (@UpackStatus = 1	or 	@UpackStatus = 4)		--In progress or Empty return
--	AND @quantity = 0									--There are consumption do do
--BEGIN
--	--Set event to Consumed

--	IF @FlagDebugOnline = 1
--	BEGIN
--		INSERT local_debug (CallingSP,timestamp, message, msg)
--		VALUES (	@SPNAME,
--					GETDATE(),
--					'1450 Status needs to be set Consumed'
--					,
--					@EcId
--				)
--	END

--	SET @StackStatus = @ConsumedStatusId

--	INSERT	@tblEventUpds (TransactionType, EventId, EventNum, PUId, TimeStamp,       
--	AppliedProduct, SourceEvent, EventStatus, Confirmed, UserId, PostUpdate,
--	Conformance, TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
--	EventSubTypeId, EntryOn,
--	ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo)
--	SELECT	2, Event_Id, Event_Num, PU_Id, TimeStamp,
--			Applied_Product, Source_Event, @StackStatus, Confirmed, @UserId, 0,
--			Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
--			Comment_Id, Event_SubType_Id, Entry_On,
--			Approver_User_Id, Second_User_Id, Approver_Reason_Id, User_Reason_Id, User_SignOff_Id, Extended_Info
--	FROM	dbo.Events WITH(NOLOCK)
--	WHERE	Event_Id = @StackEventId
--END




----------------------------------------------------------------
--Update production event detail final dim X

---------------------------------------------------------------
IF @Stackppid IS NULL
	SET @Stackppid = 0;
IF @ActualFinDim<>@Quantity OR @Stackppid!=@ppid  
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'150 Update event details'
					,
					@EcId
				);
	END;

	--V1.1  get alternate event num info to avoid erase it
	SELECT @ParmAlternateEventNum	= [Alternate_Event_Num],
			@ParmOrderId			=[Order_Id],
			@ParmOrderLineId		=[Order_Line_Id],			-- Order Line Id
			@ParmPPSetupId			=[PP_Setup_Id],
			@ParmCommentId			=[Comment_Id]
	 FROM dbo.event_details WITH(NOLOCK)
	 WHERE event_id = @StackEventId;



	EXECUTE spServer_DBMgrUpdEventDet 
		@UserId,    				-- UserId
		@StackEventId,    			-- EventId 
		@StackPUID,    				-- PUId
		NULL,   					-- Primary Event Num 
		2,    						-- Transaction Type 
		Null,    					-- Trans Num
		@ParmAlternateEventNum,     -- Alternate event num
		NULL,   					-- Status 
		@StackInitialDim,			-- Initial DimX
		NULL,						-- Initial DimY
		NULL,						-- Initial DimZ
		NULL,						-- Initial DimA
		@Quantity,   				-- Final DimX
		NULL,   					-- Final DimY
		NULL,   					-- Final DimZ
		NULL,   						-- Final DimA
		NULL,    					-- OrientationX 
		NULL,     					-- OrientationY 
		NULL,     					-- OrientationZ 
		Null,      					-- Original Product
		Null,     					-- Applied Product
		@ParmOrderId,    			-- Order Id
		@ParmOrderLineId,			-- Order Line Id
		@PPId,     					-- PP Id
		@ParmPPSetupId,				-- PP Setup Id
		@ParmShipmentId,			-- Shipment Id
		@ParmCommentId,				-- Comment Id
		@parmEntryon,    			-- Entry On
		NULL,   					-- TimeStamp
		NULL    	;				-- Event Type
END;






--------------------------------------------------------------------------------------
--Push result Set
--------------------------------------------------------------------------------------
IF (SELECT COUNT(1) FROM @tblEventUpds) > 0 OR
	(SELECT COUNT(1) FROM @tblEventComponentUpds) > 0
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1600 Push result sets'
					,
					@EcId
				);
	END;


	SELECT	1 ResultType, Id, TransactionType, EventId, EventNum, PUId,
			convert(VARCHAR(25), TimeStamp, 120) TimeStamp, AppliedProduct,
			SourceEvent, EventStatus, Confirmed, UserId, PostUpdate, Conformance,
			TestPctComplete, StartTime, TransNum, TestingStatus, CommentId,
			EventSubTypeId, EntryOn,
			ApprovedUserId, SecondUserId, ApprovedReasonId, UserReasonId, UserSignOffId, ExtendedInfo
	FROM	@tblEventUpds;

	SELECT	11 ResultType, Pre, UserId, TransactionType, TransactionNumber,
			ComponentId, EventId, SrcEventId, DimX, DimY, DimZ, DimA,
			StartCoordinateX, StartCoordinateY, StartCoordinateZ, StartCoordinateA,
			StartTime, TimeStamp, PPComponentId, EntryOn, ExtendedInfo,
			PEIId, ReportAsConsumption, ChildUnitId, ESignatureId 
	FROM	@tblEventComponentUpds;
END;

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'9999 SP FINISHED'
					,
					@EcId
				);
	END;


