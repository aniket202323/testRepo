


--------------------------------------------------------------------------------------------------
-- Stored Procedure: Splocal_CmnWFPLCSetRunningForMCT
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 31-May-2019	
-- Version 				: Version <1.0>
-- SP Type				: PPA Calculation
-- Caller				: Model 603 on storage location
-- Description			:	FO-03833
--							This SP takes the pallet PLC for MCT checked in prior the order gets active and it make them
--							Running, Consumed, genealogy and dimension updated
--							
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			31-May-2019		U.Lapierre				Original
-- 1.1			2023-07-25		L. Hudon				fix issue slowness with pedexecinput UDP, add identity
/*---------------------------------------------------------------------------------------------
Testing Code

-----------------------------------------------------------------------------------------------*/
/*
DECLARE @outputvalue VARCHAR(25)
EXEC Splocal_CmnWFPLCSetRunningForMCT
	@outputvalue OUTPUT,
	5783,
	'13-Jun-2019 16:01:03',
	'PE.Consumption',
	'1'
SELECT @outputvalue
*/
--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[Splocal_CmnWFPLCSetRunningForMCT]
	@outputvalue				VARCHAR(25) OUTPUT,
	@Puid						INT,
	@Timestamp					DATETIME,
	@userName					VARCHAR(50),
	@FlagDebugOnline			BIT

--WITH ENCRYPTION
AS
SET NOCOUNT ON;

DECLARE	
@DefaultUserId					INT,
@SPName							VARCHAR(50),
@ThisTime						DATETIME,


--Production event information
@StartTime						DATETIME,
@eventId						INT,
@ppid							INT,
@ExtInfo						VARCHAR(30),

--raw material Event information
@RMpuid							INT,
@RMeventId						INT,
@RMTimestamp					DATETIME,
@peiid							INT,
@RMProdId						INT,
@RMEventNum						VARCHAR(50),				
@RMSourceEvent					INT,					
@RMCommentId					INT,				
@RMEventSubTypeId				INT,			
@RMTestingStatus				INT,			
@RMStartTime					DATETIME,				
@RMCurrentTime					DATETIME,				
@RMConformance					INT,
@RMTestPctComplete				INT,		  
@RMSecondUserId					INT,
@RMApprovedUserId				INT, 
@RMApprovedReasonId				INT,
@RMUserReasonId					INT,
@RMUserSignoffId				INT,
@RMExtendedInfo					VARCHAR(30),


--PO information
@pathCode						VARCHAR(10),
@ProcessOrder					VARCHAR(12),
@PathId							INT,

@FormulationId					INT,
@ActivePPID						INT,
@ActiveFormulationId			INT,
@NextPPID						INT,
@NextFormulationId				INT,
@BOMProdId						INT,
@BomProdIdSub					INT,
@BOMFormulationItemId			INT,
@POStartTime					DATETIME,


--Checkin variables
@CheckInStatusId				INT,
@RunningStatusId				INT,
@ConsumedStatusID				INT,
@PalletTimestamp				DATETIME,
@Second							INT,
@EventNum						VARCHAR(50),
@SourceEvent					INT,
@CommentId						INT,
@EventSubTypeId					INT,
@TestingStatus					INT,
@CurrentTime					DATETIME,
@Conformance					INT,
@TestPctComplete				INT,
@SecondUserId					INT,
@ApprovedUserId					INT,
@ApprovedReasonId				INT,
@UserReasonId					INT,
@UserSignoffId					INT,
@ExtendedInfo					VARCHAR(100),
--Genealogy variables
@DimensionX						FLOAT,
@ChildEventId					INT,
@ComponentId					INT,
@DimensionY						FLOAT,
@DimensionZ						FLOAT,
@DimensionA						FLOAT,
@ParmStartTime					DATETIME,
@ParmTimeStamp					DATETIME,
@ParentComponentId				INT,
@ParmEntryOn					DATETIME,
@ParmExtendedInfo				VARCHAR(255),
@ReportAsConsumption			INT,
@SignatureId					INT	,
@ParmChildUnitId				INT,


--UDPs
@TableIdRMI						INT,
@FlgReportAsConsumptionId		INT,
@FlgReportAsConsumption			BIT,
@IsPLCMCTId						INT,
@tfOGId							INT,
@pnOriginGroup					VARCHAR(50),
--Consume event
@FinalDimension					FLOAT;



DECLARE @PRDExecInputs TABLE 
(	
	Id							INT	IDENTITY,--v1.1
	PUID						INT,
	PEIID						INT,
	OG							VARCHAR(50),
	IsPLCMCT					BIT,
	ReportAsConsumption			BIT
					);


DECLARE @SourceUnits	TABLE (
	PUID						INT,
	OG							VARCHAR(30)
	);


DECLARE @BOM			TABLE (
ProdId							INT,
ProdIdAlt						INT,
OG								VARCHAR(50),
puid							INT );


DECLARE @CheckInEvents	TABLE (
eventId							INT,
puid							INT,
ProdId							INT,
InitialDimx						FLOAT,
FinalDimX						FLOAT,
Timestamp						DATETIME,
OG								VARCHAR(30)
);

-------------------------------------------------------------------------------
-- 2. Obtain the PUId from the event manager
-------------------------------------------------------------------------------
SET @SPNAME  = 'Splocal_CmnWFPLCSetRunningForMCT';


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1000 - SP started'	,
				@puid
			);
END;



-------------------------------------------------------------------------------
-- Validate the User
-------------------------------------------------------------------------------

SET @DefaultUserId = NULL;
SELECT @DefaultUserId = User_Id
FROM dbo.Users WITH(NOLOCK)
WHERE Username = @UserName;

IF @DefaultUserId IS NULL
	SET @DefaultUserId = (	SELECT  User_Id
							FROM dbo.Users WITH(NOLOCK)
							WHERE Username ='System.PE');



IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'1050 - @UserId = ' + CONVERT(VARCHAR(30),@DefaultUserId) +
			' @username = ' + @UserName,
			@puid
		);
END;


-------------------------------------------------------------------------------
-- Get the path id & pp_id
-------------------------------------------------------------------------------
SELECT	@eventid	= e.event_id 	,
		@StartTime	= e.start_time	,
		@PPID		= ed.pp_id		, 
		@ExtInfo	= COALESCE(e.Extended_info,'')			
FROM dbo.events e			WITH(NOLOCK)
JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
WHERE e.pu_id = @PuId AND e.timestamp = @timestamp;


-- check to see if the calc already ran for that unit.
IF CHARINDEX('/PLCMCT',@ExtInfo, 0) > 0
BEGIN
	SELECT @OutputValue = 'Done';
	GOTO ErrCode ;
END
ELSE
BEGIN
	IF LEN(@ExtInfo)>1
		SET @ExtInfo = @ExtInfo + '/PLCMCT';
	ELSE
		SET @ExtInfo = '/PLCMCT';
	
	--Mark this event as managed to insure it does do it again
	UPDATE events SET extended_info = @ExtInfo WHERE event_id = @eventid;

END;



IF @ppid IS NULL
BEGIN
	SELECT @OutputValue = 'Done';
	GOTO ErrCode ;
END;

SET @ActivePPID = (	SELECT pp_id 
					FROM dbo.production_plan_starts WITH(NOLOCK) 
					WHERE pu_id = @ppid
						AND start_time < @timestamp
						AND (end_time IS NULL OR end_time >= @timestamp	)	);

IF @ActivePPID != @ppid
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'1055 - Invalid PPID, not matching production_plan_starts ' + 
			' pps ppid: ' + CONVERT(VARCHAR(30),COALESCE(@ActivePPID,0)) ,
			@puid
		);


	SELECT @OutputValue = 'Done';
	GOTO ErrCode ;
END;



SET @pathId = (SELECT path_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @ppid);

IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'1100 - ' +
			' pathId = ' + CONVERT(VARCHAR(30),COALESCE(@pathId,0)) +
			' ppid = ' + CONVERT(VARCHAR(30),COALESCE(@ppid,0)) ,
			@puid
		);
END;

IF @ppid IS NULL
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1105 - Invalid process order or path code' +
				' pathId = ' + CONVERT(VARCHAR(30),COALESCE(@pathId,0)) +
				' ppid = ' + CONVERT(VARCHAR(30),COALESCE(@ppid,0)) ,
				@puid
			);
	END;
	GOTO ErrCode;

END	;

SET @FormulationId = (SELECT BOM_Formulation_ID FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @ppid);

--------------------------------------------------------------------------------
--Get pei_id and production unit pu_id
--------------------------------------------------------------------------------

SET @TableIdRMI					=	(	SELECT tableId FROM dbo.tables WITH(NOLOCK) WHERE tablename = 'PrdEXEC_Inputs' );
SET @FlgReportAsConsumptionId	=	(	SELECT table_field_Id FROM dbo.table_fields WITH(NOLOCK) WHERE tableid = @TableIdRMI AND table_field_desc = 'ReportAsConsumption' );
SET @IsPLCMCTId					=	(	SELECT table_field_Id FROM dbo.table_fields WITH(NOLOCK) WHERE tableid = @TableIdRMI AND table_field_desc = 'PE_PLCOrderingForMCT' );
SET @tfOGId						=	(	SELECT table_field_Id FROM dbo.table_fields WITH(NOLOCK) WHERE tableid = @TableIdRMI AND table_field_desc = 'Origin Group' );


INSERT @PRDExecInputs (
						PUID,
						PEIID,
						OG,
						IsPLCMCT,
						ReportAsConsumption
						)
SELECT	@puid,
		pei.PEI_Id, 
		CONVERT(VARCHAR(30),tfv.Value), 
		CONVERT(BIT,tfv2.value),
		CONVERT(BIT,tfv3.value)
FROM dbo.PrdExec_Inputs pei				
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)		ON tfv.KeyId = pei.PEI_Id	AND tfv.Table_Field_Id  = @tfOGId						AND tfv.tableid = @TableIdRMI
JOIN dbo.Table_Fields_Values tfv2		WITH(NOLOCK)		ON tfv2.KeyId= pei.PEI_Id	AND tfv2.Table_Field_Id = @IsPLCMCTId					AND tfv2.tableid = @TableIdRMI
JOIN dbo.Table_Fields_Values tfv3		WITH(NOLOCK)		ON tfv3.KeyId= pei.PEI_Id	AND tfv3.Table_Field_Id = @FlgReportAsConsumptionId		AND tfv3.tableid = @TableIdRMI
WHERE pei.pu_id = @puid;

--Remove all OG not PLC ordering for MCT

DELETE @PRDExecInputs
WHERE IsPLCMCT = 0
	OR IsPLCMCT IS NULL;


INSERT @SourceUnits (PUID, OG)
SELECT	peis.pu_id,
		pei.OG
FROM @PRDExecInputs pei
JOIN dbo.prdExec_input_sources peis WITH(NOLOCK) ON pei.peiid = peis.pei_id;


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	SELECT	@SPNAME,
			GETDATE(),
			'1200 - all unist and OG' +
			' pu_id = ' + CONVERT(VARCHAR(30),COALESCE(puid,0)) +
			' OG = ' + COALESCE(OG,'OUPS') ,
			@puid
	FROM @SourceUnits ;
		
END;

--Exit if no PLCforMCT OG
IF (SELECT COUNT(1) FROM @PRDExecInputs WHERE IsPLCMCT = 1)=0
BEGIN
	SELECT @OutputValue = 'Done';
	GOTO ErrCode ;
END;

--------------------------------------------------------------------------------
--Get BOM items for the MCT material
--------------------------------------------------------------------------------
SET @pnOriginGroup = 'Origin Group';


INSERT @BOM (
	prodId,
	prodIdAlt,
	OG,
	puid)
SELECT	bomfi.prod_id,
		boms.prod_Id,
		CONVERT(VARCHAR(30),pmdmc.value),
		bomfi.pu_id
FROM dbo.bill_of_material_formulation_item bomfi				WITH(NOLOCK)
LEFT JOIN dbo.Bill_Of_Material_Substitution boms				WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON bomfi.prod_id = a.prod_id
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = a.Origin1MaterialDefinitionId
																					AND pmdmc.Name = @pnOriginGroup
WHERE bomfi.BOM_formulation_id = @FormulationId
	AND bomfi.pu_id IN (SELECT puid FROM @SourceUnits);




--Get only valid OG
DELETE @BOM
WHERE OG NOT IN (SELECT OG FROM @PRDExecInputs);


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'1300 - Got BOM' ,
			@puid
		);
END;


--------------------------------------------------------------------------------
--Find all pallets that are in BOM and checked In
--------------------------------------------------------------------------------

SET @CheckInStatusId		=	(	SELECT prodStatus_ID FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'Checked In');
SET @RunningStatusId		=	(	SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Running' )	;
SET @ConsumedStatusID		=	(	SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Consumed' );	

INSERT  @CheckInEvents	 (
eventId							,
puid							,
ProdId							,
InitialDimx						,
FinalDimX						,
Timestamp						,
OG			
)
SELECT	DISTINCT
		e.event_id, 
		e.pu_id,
		e.applied_product,
		ed.initial_dimension_x,
		ed.final_dimension_x,
		e.timestamp,
		b.og
FROM dbo.events e			WITH(NOLOCK)
JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
JOIN @BOM b									ON (e.applied_product = b.prodId OR e.applied_product = b.prodIdAlt)
JOIN @SourceUnits su						ON su.puid = e.pu_id
WHERE e.event_status = @CheckInStatusId;


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	SELECT	@SPNAME,
			GETDATE(),
			'1400 - list of RM events' + 
			'Nbr of events to set running : ' + CONVERT(VARCHAR(3),COUNT(1))  ,
			@puid
	FROM @CheckInEvents;		
END;

--------------------------------------------------------------------------------
--The pallet can be set running, genealogy done, then consumed.
--Use the SP server to modify the pallets.
-------------------------------------------------------------------------------
SET @RMeventId = (SELECT MIN(eventid) FROM @CheckInEvents);
WHILE @RMeventId IS NOT NULL
BEGIN
	--Retrieve event info
	SELECT 		@RMEventNum				= event_num,				
				@RMPUId					= pu_id,	
				@RMtimestamp			= timestamp,				
				@RMprodId				= applied_product,					
				@RMSourceEvent			= source_event,				
				@RMCommentId			= comment_id,				
				@RMEventSubTypeId		= event_subtype_id,			
				@RMTestingStatus		= testing_status,			
				@RMStartTime			= start_time,				
		  		@RMConformance			= conformance,
		  		@RMTestPctComplete		= Testing_Prct_Complete,		  
				@RMSecondUserId			= Second_User_Id,
		  		@RMApprovedUserId		= Approver_User_Id, 
		  		@RMApprovedReasonId		= Approver_Reason_Id,
		  		@RMUserReasonId			= User_Reason_Id,
		  		@RMUserSignoffId		= User_Signoff_Id,
		  		@RMExtendedInfo			= Extended_Info
	FROM dbo.events WITH(NOLOCK)
	WHERE event_id = @RMeventId;


	SELECT @RMCurrentTime = GETDATE();
	--make the event running
	EXEC	spServer_DBMgrUpdEvent
				@RMeventId OUTPUT,			--@ParamEventId		INT OUTPUT,
				@RMEventNum,				--@ParamEventNum	VARCHAR(25),
				@RMPUId,					--@ParamPUId		INT,
				@RMtimestamp,				--@ParamTimeStamp	DATETIME,
				@RMprodId,					--@ParamAppliedProduct	INT,
				@RMSourceEvent,				--@ParamSourceEvent	INT,
				@RunningStatusID,			--@ParamEventStatus	INT,
				2,							--@ParamTransactionType	INT,
				0,							--@ParamTransNum	INT,
				@DefaultUserId,				--@ParamUserId		INT,
				@RMCommentId,				--@ParamCommentId	INT,
				@RMEventSubTypeId,			--@ParamEventSubTypeId	INT,
				@RMTestingStatus,			--@ParamTestingStatus	INT,
				@RMStartTime,				--@ParamPropStartTime	DATETIME,
				@RMCurrentTime,				--@ParamPropEntryOn	DATETIME,
				0,							--@ParamReturnResultSet	INT		
		  		@RMConformance OUTPUT,
		  		@RMTestPctComplete OUTPUT,		  
				@RMSecondUserId,
		  		@RMApprovedUserId, 
		  		@RMApprovedReasonId,
		  		@RMUserReasonId,
		  		@RMUserSignoffId,
		  		@RMExtendedInfo,
				0;

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1500 - Status set to Running for event :' + CONVERT(VARCHAR(30),@RMeventId) ,
				@puid
			);
	END;


	--Make a genealogy link with the event on the production equipement
	SELECT  @FlgReportAsConsumption = 	COALESCE(ReportAsConsumption,1),
			@PEIId					=	pei.peiid
			FROM @PRDExecInputs pei
			JOIN @CheckInEvents cie	ON pei.OG = cie.OG
			WHERE cie.eventid = @RMeventId;
			

	SELECT @DimensionX = FinalDimX
	FROM @CheckInEvents
	WHERE eventid = @RMeventId;

	SET @ComponentId = NULL;
	--Establish genealogy for the full amount of the raw material container, if not already done
	IF NOT EXISTS(SELECT component_id FROM dbo.event_components WITH(NOLOCK) WHERE source_event_id = @RMEventId)
	BEGIN
		EXEC spServer_DBMgrUpdEventComp
		@DefaultUserId			,
		@EventId			, 
		@ComponentId	OUTPUT	, 
		@RMEventId				, 
		@DimensionX				,
		@DimensionY				,
		@DimensionZ				,
		@DimensionA				,
		0						,		-- TranNum
		1						,		-- TransType
		@Puid 	,				
		NULL					,
		NULL					,
		NULL					,
		NULL					,
		@RMTimeStamp				,		-- StartTime
		@RMTimeStamp				,		-- TimeStamp
		NULL					, 
		@CurrentTime	OUTPUT	, 
		NULL					,		-- ExtendedInfo
		@PEIId				,
		@FlgReportAsConsumption	;
	

		IF @FlagDebugOnline = 1
		BEGIN
			INSERT local_debug (CallingSP,timestamp, message, msg)
			VALUES (	@SPNAME,
					GETDATE(),
					'1530 - Genealogy done ' +
					' Source event :' + CONVERT(VARCHAR(30),@RMeventId) + 
					' Child event :' + CONVERT(VARCHAR(30),@eventId) + 
					' Qty : ' + CONVERT(VARCHAR(30),@DimensionX) ,
					@puid
				);
		END;
	END;

	--Make the event consumed
	SELECT @RMCurrentTime = GETDATE();
	--make the event running
	EXEC	spServer_DBMgrUpdEvent
				@RMeventId OUTPUT,			--@ParamEventId		INT OUTPUT,
				@RMEventNum,				--@ParamEventNum	VARCHAR(25),
				@RMPUId,					--@ParamPUId		INT,
				@RMtimestamp,				--@ParamTimeStamp	DATETIME,
				@RMprodId,					--@ParamAppliedProduct	INT,
				@RMSourceEvent,				--@ParamSourceEvent	INT,
				@ConsumedStatusID,			--@ParamEventStatus	INT,
				2,							--@ParamTransactionType	INT,
				0,							--@ParamTransNum	INT,
				@DefaultUserId,				--@ParamUserId		INT,
				@RMCommentId,				--@ParamCommentId	INT,
				@RMEventSubTypeId,			--@ParamEventSubTypeId	INT,
				@RMTestingStatus,			--@ParamTestingStatus	INT,
				@RMStartTime,				--@ParamPropStartTime	DATETIME,
				@RMCurrentTime,				--@ParamPropEntryOn	DATETIME,
				0,							--@ParamReturnResultSet	INT		
		  		@RMConformance OUTPUT,
		  		@RMTestPctComplete OUTPUT,		  
				@RMSecondUserId,
		  		@RMApprovedUserId, 
		  		@RMApprovedReasonId,
		  		@RMUserReasonId,
		  		@RMUserSignoffId,
		  		@RMExtendedInfo,
				0;


	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1550 - Event is consumed ' +
				' Source event :' + CONVERT(VARCHAR(30),@RMeventId) ,
				@puid
			);
	END;

	---------------------------------------------------------------------------
	--UPDATE event details
	---------------------------------------------------------------------------
	SELECT @RMCurrentTime = GETDATE();

	SELECT	
		10,
		1,
		@defaultUserId,
		2,
		0,
		@RMEventId,
		PU_Id,
		NULL,
		alternate_event_num,
		Comment_Id,
		NULL,
		NULL,
		NULL,
		NULL,
		@rmTimestamp,
		@CurrentTime,
		PP_Setup_Id,
		Shipment_id,
		Order_Id,
		Order_Line_Id,
		@PPID,
		Initial_Dimension_X,
		Initial_Dimension_Y,
		Initial_Dimension_Z,
		Initial_Dimension_A,
		0,
		Final_Dimension_Y,
		Final_Dimension_Z,
		Final_Dimension_A,
		Orientation_X,
		Orientation_Y,
		Orientation_Z,
		NULL
		FROM [dbo].[Event_Details]
		WHERE Event_Id = @RMEventId;

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1570 - Event details is updated ' +
				' Source event :' + CONVERT(VARCHAR(30),@RMeventId) ,
				@puid
			);
	END;

	--Consider here to push event result in post mode...


	--Next raw material event checked In
	SET @RMeventId = (SELECT MIN(eventid) FROM @CheckInEvents WHERE eventid > @RMeventId);
END

SELECT @outputValue = 'Done';

ErrCode:

IF @FlagDebugOnline = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'9999' +

				' Finished',
				@puid
				);
END;


SET NOcount OFF;

RETURN
