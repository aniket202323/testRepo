CREATE PROCEDURE  [dbo].[spLocal_CmnWFSendMSG3]
@PUId							int,
@EventId						int,
@RTCISSiteClass					varchar(255),
@ReturnMaterialMessageEnabled	int
		

AS

SET NOCOUNT ON 
-------------------------------------------------------------------------------
-- TASK 1 Declare variables
-------------------------------------------------------------------------------


DECLARE	@UserId					int,			
		@RowCount				varchar(2),
		@FileName				varchar(50),
		@EventStatus			varchar(25),
		@PUDesc					varchar (50),
		@PathId					int,
		@ORACLESQL				varchar (4000),
		@SysDate				varchar (255),
		@BuildPath				varchar (255),
		@UploadPath				varchar (255),
		@TemplateName			varchar (255),
		@Quantity				int,
		@PrinterNumber			int,
		@FileExtension			varchar (255),
		@InstanceNumber			int,
		@StatusToFire			varchar (255),
		@SPName					varchar (255),
		@StatusToFireId			int,
		@MSG3ItmCode			varchar (255),
		@MSG3coddat				varchar (255),
		@MSG3expdat				varchar (255),
		--@MSG3casqty				float,
		@MSG3casqty				decimal(10,3),		--UL 1.12
		@MSG3prdord				varchar (255),	
		@ULPALL					varchar(255),
		@SchedPointPUId			int,
		@SchedPointPUDesc		varchar (255),
		@SchedPointPLDesc		varchar (255),		
		@LabelPrintActive		varchar(255),
		@LabelField1			varchar(255),
		@PLDesc					varchar(255),
		@PrinterName			varchar(255),
		@MSG3CtlUser			varchar (255),
		@RTCISServerName		varchar(255),
		@RTCISTableName			varchar(255),
		@MSG3MsgInt				varchar(255),
		@MSG3MsgTyp				varchar(255),
		@MSG3MachId				varchar(255),	
		@MSG3TrxCod				varchar(255),	
		@MSG3ErrCod				varchar(255),
		@MSG3FromLoc			varchar(255),
		@MSG3SubSite			varchar(255),
		@MSG3ItmCls				varchar(255),
		@MSG3TestMode			varchar(10),
		@MSG3HostId				varchar(255),
		@1LevelDebug			int,
		@EventNumber			varchar(50),
		@OutputValue			varchar(25)	,
		@Nbr					int,
		@HighTen				int,
		@digit					int,
		@SumCheckDigit			int,
		@CheckDigit				varchar(1)
-------------------------------------------------------------------------------
-- Temporary table for RTCIS MSG3
-------------------------------------------------------------------------------
DECLARE	@tRTCISOutput	TABLE (
		MSGTYP 		varchar(255)	NULL,
 		MSGINT		varchar(255)	NULL, 
 		TRXCOD		varchar(255)	NULL, 			
		SUBSIT		varchar(255)	NULL,
 		FROM_LOC	varchar(255)	NULL,
 		TO_LOC		varchar(250)	NULL,
 		ITMCLS		varchar(250)	NULL,
 		ITMCOD		varchar(255)	NULL,
 		CODDAT		varchar(255)	NULL,
 		PRODAT		varchar(255)	NULL,
 		EXPDAT		varchar(255)	NULL,
 		CASQTY		varchar(255)	NULL,
 		ULPALL		varchar(255)	NULL,
 		ULIDCD		varchar(255)	NULL,
 		UL_STACOD	varchar(255)	NULL,
 		PRDORD		varchar(255)	NULL,
 		BYPCOD		varchar(255)	NULL,
 		SLDFLG		varchar(255)	NULL,
 		DELVCD		varchar(255)	NULL,
 		MACHID		varchar(255)	NULL,
 		TEAMID		varchar(255)	NULL,
 		TRNOVR		varchar(255)	NULL,
 		FRTBCK		varchar(255)	NULL,
 		PRTLBL		varchar(255)	NULL,
 		HOST_ID		varchar(255)	NULL,
 		HOST_REC  	varchar(255)	NULL,                              
		MSTAMP		varchar(255)	NULL,                 
		ERRCOD		varchar(255)	NULL,
		ERRDSC		varchar(255)	NULL,                                   
		CTRL_DATE	varchar(255)	NULL,              
		CTRL_USER	varchar(255)	NULL, 
		BASE_ULIDCD	varchar(255)	NULL,          
		TO_ULIDCD 	varchar(255)	NULL,           
		CTLGRP		varchar(255)	NULL	
 		)


			
set @1LevelDebug = 1 -- 1.14	
SELECT @OutputValue = 'Success'
SET @SPName = 'spLocal_CmnWFSendMSG3'
SELECT @SysDate = CONVERT(varchar(50), GETDATE(),120)
-------------------------------------------------------------------------------
-- TASK 2 Verify SP Inputs
-------------------------------------------------------------------------------
IF len(IsNull(@RTCISSiteClass,''))<=0
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'RTCISSiteClass is Invalid'
				)
	END
	SELECT @OutputValue = 'RTCISSiteClass?'
	GOTO ExitResult
END

IF len(IsNull(@PUId,''))<=0
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'PUID is invalid'
				)
	END
	SELECT @OutputValue = '@PUId?'
	GOTO ExitResult
END

IF	@1LevelDebug = 1 --write to the local_debug table
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName,
			'Inputs Validated'
			)
END

-------------------------------------------------------------------------------
-- TASK 3 Initalize Variables
-------------------------------------------------------------------------------

SELECT	@PUDesc = pu.PU_DESC, 
		@PLDesc = pl.PL_Desc
FROM	dbo.PROD_UNITS pu WITH(NOLOCK)
JOIN	dbo.PROD_LINES pl WITH(NOLOCK) on pu.PL_ID = pl.PL_ID 
WHERE	pu.PU_ID = @PUId

SELECT	@PathId  = pp.PATH_ID
FROM	dbo.EVENT_DETAILS ed WITH(NOLOCK)
JOIN	dbo.PRODUCTION_PLAN pp WITH(NOLOCK) on ed.PP_ID = pp.PP_ID
WHERE	ed.EVENT_ID = @EventId



IF	@1LevelDebug = 1 
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'PUDesc:' + @PUDesc
			)
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'PLDesc:' + @PLDesc
			)
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'PathId:' + Convert(varchar(25),IsNull(@PathId,-1))
			)
END

IF IsNUll(@PathId,-1)<=0 
BEGIN
	SELECT	@OutputValue = 'PathId?'
	GOTO ExitResult
END
	

-------------------------------------------------------------------------------
-- TASK 4 Get and Verify RTCIS Site Class Properties
-------------------------------------------------------------------------------
IF	@1LevelDebug = 1 
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName,
			'Get RTCIS Site Class Properties'
			)
END


SELECT	@MSG3TestMode = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 TestMode'	AND		
		pee.Class  = @RTCISSiteClass

SELECT	@MSG3CtlUser = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 ctrl_user'	AND		
		pee.Class  = @RTCISSiteClass

SELECT	@RTCISServerName = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.RTCISServerName'	AND		
		pee.Class  = @RTCISSiteClass	

SELECT	@RTCISTableName = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.RTCIS Table Name'	AND		
		pee.Class  = @RTCISSiteClass	

SELECT	@MSG3MsgInt = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 msgint'	AND		
		pee.Class  = @RTCISSiteClass	

SELECT	@MSG3MsgTyp = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 msgtyp' AND		
		pee.Class  = @RTCISSiteClass	


SELECT	@MSG3MachId = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 Machid' AND		
		pee.Class  = @RTCISSiteClass	

SELECT	@MSG3TrxCod = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 trxcod'	AND		
		pee.Class  = @RTCISSiteClass	

SELECT	@MSG3ErrCod = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 errcod'	AND		
		pee.Class  = @RTCISSiteClass


SELECT	@MSG3HostId = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 Host_ID'	AND		
		pee.Class  = @RTCISSiteClass		
		

SELECT	@MSG3ItmCls = convert(varchar(255),IsNull(pee.Value,''))	
FROM	dbo.EQUIPMENT e	WITH(NOLOCK)
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (e.EquipmentId = pee.EquipmentId)
WHERE	e.type = 'site' AND		
		convert(varchar(255),pee.Name) = 'PE:RTCIS Site.MSG3 ITMCLS'	AND		
		pee.Class  = @RTCISSiteClass				

IF	@1LevelDebug = 1 --write to the local_debug table
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3CtlUser: ' + IsNUll(@MSG3CtlUser, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3TestMode: ' + IsNUll(@MSG3TestMode, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'RTCISServerName: ' + IsNUll(@RTCISServerName, 'NULL')
			)
	
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3MsgInt: ' + IsNUll(@MSG3MsgInt, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3MsgTyp: ' + IsNUll(@MSG3MsgTyp, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3MachId: ' + IsNUll(@MSG3MachId, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3TrxCod: ' + IsNUll(@MSG3TrxCod, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3ErrCod: ' + IsNUll(@MSG3ErrCod, 'NULL')
			)
	
END

IF (len(IsNull(@MSG3CtlUser,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3CtlUser is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3CtlUser?'
	GOTO ExitResult
END

IF (len(IsNull(@RTCISServerName,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'RTCISServerName is Invalid'
				)
	END
	SELECT @OutputValue = 'RTCISServerName?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3MsgInt,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3MsgInt is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3MsgInt?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3MsgTyp,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3MsgTyp is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3MsgTyp?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3MachId,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3MachId is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3MachId?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3TrxCod,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3TrxCod is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3TrxCod?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3HostId,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3HostId is Invalid'
				)
	END
	SELECT @OutputValue = '@MSG3HostId?'
	GOTO ExitResult
END

IF ( (len(IsNull(@MSG3ItmCls,''))<=0) OR ( (upper(IsNull(@MSG3ItmCls,''))!= 'F')AND (upper(IsNull(@MSG3ItmCls,''))!= 'P') ))
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3ItmCls is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3ItmCls?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3ErrCod,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3ErrCod is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3ErrCod?'
	GOTO ExitResult
END

IF	@1LevelDebug = 1 --write to the local_debug table
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName,
			'RTCIS Site Class Properties Validated'
			)
END


 -----------------------------------------------------------------------------
 -- TASK 5 get the from location for RTCIS										--
 -----------------------------------------------------------------------------
SELECT @MSG3FromLoc = convert(varchar(255),IsNull(pee.Value,0))	
FROM dbo.Equipment eu							WITH(NOLOCK)	
JOIN dbo.PAEquipment_Aspect_SOAEquipment a	WITH(NOLOCK)	ON eu.EquipmentId = a.Origin1EquipmentId
JOIN dbo.prod_Units pu						WITH(NOLOCK)	ON a.pu_id = pu.pu_id
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (eu.EquipmentId = pee.EquipmentId)
																			
WHERE a.pu_id = @PUID
AND convert(varchar(255),pee.Name) = 'FRM_LOCATN'


 -----------------------------------------------------------------------------
 --  get the from location for subsite										--
 -----------------------------------------------------------------------------
SELECT	@MSG3SubSite = convert(varchar(255),IsNull(pee.Value,0))	
FROM dbo.Equipment eu							WITH(NOLOCK)	
JOIN dbo.PAEquipment_Aspect_SOAEquipment a	WITH(NOLOCK)	ON eu.EquipmentId = a.Origin1EquipmentId
JOIN dbo.prod_Units pu						WITH(NOLOCK)	ON a.pu_id = pu.pu_id
JOIN	dbo.PROPERTY_EQUIPMENT_EQUIPMENTCLASS pee	WITH(NOLOCK) ON (eu.EquipmentId = pee.EquipmentId)														
WHERE a.pu_id = @PUID
AND convert(varchar(255),pee.Name) = 'subsite'
		

IF	@1LevelDebug = 1 --write to the local_debug table
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3FromLoc: ' + IsNUll(@MSG3FromLoc, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'MSG3SubSite: ' + IsNUll(@MSG3SubSite, 'NULL')
			)	
END

IF (len(IsNull(@MSG3FromLoc,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3FromLoc is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3FromLoc?'
	GOTO ExitResult
END

IF (len(IsNull(@MSG3SubSite,''))<=0)
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3SubSite is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3SubSite?'
	GOTO ExitResult
END

IF	@1LevelDebug = 1 --write to the local_debug table
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName,
			'SegmentStart Class Properties Validated'
			)
END


------------------------------------------------------------------------------------------------
-- TASK 6 Get and Verify MSG3 Message Fields
------------------------------------------------------------------------------------------------

SELECT		@MSG3ItmCode = NULL
SELECT		@MSG3ItmCode = coalesce(p.PROD_CODE, p.PROD_DESC)
FROM		dbo.Events e WITH (NOLOCK)
LEFT JOIN	dbo.PRODUCTS p WITH (NOLOCK) on e.APPLIED_PRODUCT = p.PROD_ID
WHERE		e.PU_ID = @PUId AND e.EVENT_ID = @EventId

IF	@1LevelDebug = 1 
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'@MSG3ItmCode: ' + IsNUll(@MSG3ItmCode, 'NULL')
			)
END

IF len(IsNull(@MSG3ItmCode,''))<=0
BEGIN
	SELECT @OutputValue = 'MSG3ItmCode?'
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3ItmCode is Invalid'
				)
	END
	GOTO ExitResult
END



SELECT	@MSG3coddat = NULL,
		@MSG3expdat = NULL,
		@MSG3casqty = NULL,
		@MSG3prdord = NULL
		
SELECT		@MSG3expdat = pp.USER_GENERAL_2,
			@MSG3casqty  =ed.final_dimension_x,
			@MSG3prdord = pp.PROCESS_ORDER,
			@EventNumber =  substring(Event_Num, 1,19)
		
FROM		dbo.Events	e WITH(NOLOCK)
JOIN		dbo.EVENT_DETAILS ed (NOLOCK)  ON e.Event_ID = ed.Event_ID
LEFT JOIN	dbo.production_plan pp on ed.pp_id = pp.pp_id
WHERE		ed.EVENT_ID = @EventId

SET @SumCheckDigit = 0
SET @Nbr =3
while @Nbr <=19
BEGIN
	SET @digit = substring(@EventNumber,@Nbr,1)
	
	IF  @Nbr % 2 = 0
	BEGIN
		SET @SumCheckDigit =  @SumCheckDigit + (@digit * 1)
	END
	ELSE
	BEGIN
		SET @SumCheckDigit =  @SumCheckDigit +(@digit * 3)
	END
	SET @Nbr = @Nbr +1
END
			
-- find the highest multiple of 10
If  (@SumCheckDigit % 10) <> 0
BEGIN
	select @HighTen = @SumCheckDigit + (10 - (@SumCheckDigit % 10) )
END
ELSE
BEGIN
	SELECT @HighTen =@SumCheckDigit
END 

----Subtract sum from the next highest multiple of ten = Check digit
SELECT @CheckDigit = @HighTen- @SumCheckDigit 

---- add the SSCC Check Digit
SET @EventNumber = @EventNumber + cast(@CheckDigit as varchar(1))


SET @MSG3coddat = (SELECT		substring (event_num,1,(charindex('_',Event_Num))-1)
					FROM		[dbo].[Event_Components] ec WITH(NOLOCK)
					JOIN		[dbo].[Events] e WITH(NOLOCK) ON ec.Source_Event_Id = e.Event_Id
					WHERE		ec.Event_Id =@EventID)

IF	@1LevelDebug = 1 
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'@MSG3coddat: ' + IsNUll(@MSG3coddat, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'@MSG3expdat: ' + IsNUll(@MSG3expdat, 'NULL')
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'@MSG3casqty: ' + convert(varchar(255),IsNUll(@MSG3casqty, -1))
			)
			
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'@MSG3prdord: ' + IsNUll(@MSG3prdord, 'NULL')
			)
END

IF len(IsNull(@MSG3coddat,''))<=0
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3coddat is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3coddat?'
	GOTO ExitResult
END


IF IsNull(@MSG3casqty,-1)<=0
BEGIN
	IF	@1LevelDebug = 1 --write to the local_debug table
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'MSG3casqty is Invalid'
				)
	END
	SELECT @OutputValue = 'MSG3casqty?'
	GOTO ExitResult
END

--IF len(IsNull(@MSG3prdord,''))<=0
--BEGIN
--	IF	@1LevelDebug = 1 --write to the local_debug table
--	BEGIN
--		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
--		VALUES (GETDATE(), 
--				@SPName, 
--				'MSG3prdord is Invalid'
--				)
--	END
--	SELECT @OutputValue = 'MSG3prdord?'
--	GOTO ExitResult
--END


IF	@1LevelDebug = 1 
BEGIN
	INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
	VALUES (GETDATE(), 
			@SPName, 
			'Done with Validation'
			)
END


SET @ULPALL = 'NONE'
------------------------------------------------------------------------------------------------
-- TASK 7 Construct and Execute Insert Statement on the Linked ORACLE RTCIS Server
------------------------------------------------------------------------------------------------
	INSERT	@tRTCISOutput (	
			MSGTYP,
 			MSGINT, 
 			TRXCOD, 			
			SUBSIT,
 			FROM_LOC,
 			TO_LOC,
 			ITMCLS,
 			ITMCOD,
 			CODDAT,
 			PRODAT,
 			EXPDAT,
 			CASQTY,
 			ULPALL,
 			ULIDCD,
 			UL_STACOD,
 			PRDORD,
 			BYPCOD,
 			SLDFLG,
 			DELVCD,
 			MACHID,
 			TEAMID,
 			TRNOVR,
 			FRTBCK,
 			PRTLBL,
 			HOST_ID,
 			HOST_REC,                              
			MSTAMP,                 
			ERRCOD,
			ERRDSC,                                   
			CTRL_DATE,              
			CTRL_USER, 
			BASE_ULIDCD,          
			TO_ULIDCD,           
			CTLGRP)
	Values (isnull(@MSG3MsgTyp,''),--MSGTYP
			isnull(@MSG3MsgInt,''),--MSGINT
			isnull(@MSG3TrxCod,''),--TRXCOD
			isnull(@MSG3SubSite,''),--SUBSIT
			isnull(@MSG3FromLoc,''),--FROM_LOC
			NULL,--TO_LOC
			isnull(@MSG3ItmCls,''),--ITMCLS
			isnull(@MSG3ItmCode,''),--ITMCOD !!!! retrieve from the applied product
			isnull(@MSG3coddat,''),--CODDAT
			NULL,--PRODAT !!! optional
			isnull(@MSG3expdat,''),--EXPDAT
			isnull(@MSG3casqty,''),--CASQTY
			isnull(@ULPALL,''),--ULPALL Optional for Time being
			isnull(@EventNumber,''),--ULIDCD
			NULL,--UL_STACOD Not Reqiered
			isnull(@MSG3prdord,''),--PRDORD
			NULL,--BYPCOD Optional 
			NULL,--SLDFLG Optional
			NULL,--DELVCD
			isnull(@MSG3MachId,''),--MACHID
			NULL,--TEAMID Not Used
			NULL,--TRNOVR Not Used
			NULL,--FRTBCK Not Used
			NULL,--PRTLBL Not Used
			isnull(@MSG3HostId,''),--HOST_ID
			NULL,--HOST_REC Optional for now
			isnull(@SysDate,''),--MSTAMP
			isnull(@MSG3ErrCod,''),--ERRCOD
			NULL,--ERRDSC
			isnull(@SysDate,''),--CTRL_DATE
			isnull(@MSG3CtlUser,''),--CTRL_USER
			NULL,--BASE_ULIDCD Optional
			NULL,--TO_ULIDCD
			NULL--CTLGRP
			)


--1.10  remove expdat because sometime we send 0 and is not good, maybe we need to put back in place
--	expdat,
--	''''+ isnull(@MSG3expdat,'')		+''''+', ' + 
		
	SELECT	@ORACLESQL = 
			'INSERT OPENQUERY( "' + @RTCISServerName + '", ' +
			'''SELECT msgtyp, 
			msgint, 
			trxcod, 
			subsit, 
			from_loc,
			itmcls,
			itmcod,
			coddat, 		
			ulpall,
			casqty,
			ulidcd,
			machid,
			host_id,
			mstamp,
			errcod,
			ctrl_date,
			ctrl_user
			FROM ' + @RTCISServerName + '.HSTINB''' +')' + 
			' VALUES(' + 
			''''+ isnull(@MSG3MsgTyp,'')		+'''' +', ' + 
			''''+ isnull(@MSG3MsgInt,'')		+''''+', ' + 
			''''+ isnull(@MSG3TrxCod,'')		+'''' +', ' +  
			''''+ isnull(@MSG3SubSite,'')		+'''' +', ' + 
			''''+ isnull(@MSG3FromLoc,'')		+''''+', ' + 
			''''+ isnull(@MSG3ItmCls,'')		+''''+', ' + 
			''''+ isnull(@MSG3ItmCode,'')		+''''+', ' + 
			''''+ isnull(@MSG3coddat,'')		+''''+', ' + 		
			''''+ isnull(@ULPALL,'')		+''''+', ' + 
			convert(varchar(255),isnull(@MSG3casqty,'')) +', ' + 
			''''+ isnull(@EventNumber,'')+''''	+', ' + 
			''''+ isnull(@MSG3MachId,'')+''''	+', ' + 
			''''+ isnull(@MSG3HostId,'')+''''	+', ' + 
			''''+ isnull(@SysDate,'') +''''	+', ' + 
			''''+ isnull(@MSG3ErrCod,'') +''''	+', ' + 
			''''+ isnull(@SysDate,'') +''''		+', ' + 
			''''+ isnull(@MSG3CtlUser,'')		+'''' +')'
	
			
	IF	@1LevelDebug = 1 
	BEGIN
		INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
		VALUES (GETDATE(), 
				@SPName, 
				'ORACLE SQL: ' + Isnull(@ORACLESQL, 'NULL')
				)
	END

	IF @ReturnMaterialMessageEnabled = 1
		BEGIN
			IF	@1LevelDebug = 1 
			BEGIN
				INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
				VALUES (GETDATE(), 
						@SPName, 
						'ReturnMaterialMessageEnabled Parameter set to: ' + convert(varchar(4),@ReturnMaterialMessageEnabled) +'; Will send MSG3 Massage to RTCIS')
			END

			IF @MSG3TestMode = 0 
			BEGIN
				EXECUTE (@ORACLESQL)
			

				IF	@1LevelDebug = 1 
				BEGIN
					INSERT INTO Local_Debug (timestamp, CallingSP, Message) 
					VALUES (GETDATE(), 
							@SPName, 
							'ORACLE SQL Executed'
							)
				END
			END
			
	END
	INSERT		[dbo].[Local_tblMSG3](
						[MSGTYP],
						[MSGINT], 
						[TRXCOD], 			
						[SUBSIT],
						[FROM_LOC],
						[TO_LOC],
						[ITMCLS],
						[ITMCOD],
 						[CODDAT],
 						[PRODAT],
 						[EXPDAT],
 						[CASQTY],
 						[ULPALL],
 						[ULIDCD],
 						[UL_STACOD],
 						[PRDORD],
 						[BYPCOD],
 						[SLDFLG],
 						[DELVCD],
 						[MACHID],
 						[TEAMID],
 						[TRNOVR],
 						[FRTBCK],
 						[PRTLBL],
 						[HOST_ID],
 						[HOST_REC],                              
						[MSTAMP],                 
						[ERRCOD],
						[ERRDSC],                                   
						[CTRL_DATE],              
						[CTRL_USER], 
						[BASE_ULIDCD],          
						[TO_ULIDCD],           
						[CTLGRP],
						[ENTRY_ON])
	
			SELECT		MSGTYP,
 						MSGINT, 
 						TRXCOD, 			
						SUBSIT,
 						FROM_LOC,
 						TO_LOC,
 						ITMCLS,
 						ITMCOD,
 						CODDAT,
 						PRODAT,
 						EXPDAT,
 						CASQTY,
 						ULPALL,
 						ULIDCD,
 						UL_STACOD,
 						PRDORD,
 						BYPCOD,
 						SLDFLG,
 						DELVCD,
 						MACHID,
 						TEAMID,
 						TRNOVR,
 						FRTBCK,
 						PRTLBL,
 						HOST_ID,
 						HOST_REC,                              
						MSTAMP,                 
						ERRCOD,
						ERRDSC,                                   
						CTRL_DATE,              
						CTRL_USER, 
						BASE_ULIDCD,          
						TO_ULIDCD,           
						CTLGRP,
						GETDATE()
			FROM		@tRTCISOutput
				

ExitResult:
SELECT @OutputValue as 'Output'


SET NOCOUNT OFF