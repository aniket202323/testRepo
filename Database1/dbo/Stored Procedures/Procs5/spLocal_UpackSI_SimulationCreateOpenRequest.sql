CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationCreateOpenRequest]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@TrigerVarid				int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationCreateOpenRequest
	@OutputValue				OUTPUT,
	'2018-01-12 9:15',				
	31032

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(30),
		@UserId						int,
		@userName					varchar(50),
		@Now						datetime,
		@puid						int,
		@ppid						int,
		@processOrder				varchar(12),
		@PUIDConsumer				int,
		@OG							varchar(30),
		@ProdCode					varchar(30),
		@cnSiWMS					varchar(30),
		@pnLocation					varchar(30),
		@LOCATION					varchar(30),
		@triggerValue				bit,
		@pnLineID					varchar(50),
		@LineID						varchar(25),
		@RequestID					varchar(25)

------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)



SET @SPNAME = 'spLocal_UpackSI_SimulationCreateOpenRequest'
SELECT @Now = GETDATE()

-------------------------------------------------------------------------------------------
--Get User
-------------------------------------------------------------------------------------------
SELECT  @userId			=	entry_by,
		@triggerValue	=	Result
FROM dbo.tests WITH(NOLOCK) 
WHERE	var_id = @TrigerVarid 
	AND result_on = @thistime


IF @triggerValue <> 1
BEGIN
	SELECT	@OutputValue =  'trigger not checked'
	Return
END


SET @userName	= (SELECT username FROM dbo.users_base WITH(NOLOCK) where user_id = @userId)


-------------------------------------------------------------------------------------------
--Get pu_id
-------------------------------------------------------------------------------------------
SET @puid = (SELECT pu_id FROM dbo.variables WITH(NOLOCK) WHERE var_id = @TrigerVarid)




----------------------------------------------------------------------------------------------
--1) create an open request
----------------------------------------------------------------------------------------------


--Get the Active order oe the Initiate\ready order
SELECT	@PUIDConsumer	=	pei.pu_id,
		@OG				=	tfv.value
FROM dbo.PrdExec_Inputs pei			WITH(NOLOCK)
JOIN dbo.prdExec_Input_sources peis	WITH(NOLOCK)	ON peis.pei_id = pei.pei_id
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON tfv.KeyId= pei.PEI_Id
JOIN dbo.Table_Fields	tf			WITH(NOLOCK)	ON tfv.Table_Field_Id = tf.Table_Field_Id AND tf.TableId = 35
WHERE peis.pu_id = @puid 
	AND tf.Table_Field_Desc = 'Origin Group'

IF @PUIDConsumer IS NULL OR @OG IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0400 - ' +
				' Cannot identify the raw material inputs'
				,
				@puid
			)
	SELECT	@OutputValue =  'Cannot identify RMI'
	RETURN
END


--1) Active order
SELECT	@ppid = pps.pp_id,
		@processorder = pp.process_order
FROM dbo.production_plan_starts pps	WITH(NOLOCK)
JOIN dbo.production_plan pp		WITH(NOLOCK)	ON pp.pp_id = pps.pp_id
WHERE	pps.pu_id = @PUIDConsumer
	AND pps.start_time<@ThisTime
	AND (pps.end_time>@ThisTime OR pps.end_time IS NULL)

IF @ppid IS NULL  -- The look for initate or ready order on the path
BEGIN
	SELECT	@ppid = pp.pp_id,
			@processorder = pp.process_order
	FROM dbo.production_plan pp				WITH(NOLOCK) 
	JOIN dbo.production_plan_statuses pps	WITH(NOLOCK)	ON pp.pp_status_id = pps.pp_status_id
	JOIN dbo.prdExec_Path_units pepu		WITH(NOLOCK)	ON pp.path_id = pepu.path_id
	WHERE	pepu.pu_id = @PUIDConsumer
		AND	pps.pp_status_desc IN ('Initiate', 'Ready')

END


IF @ppid IS NULL 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0500 - ' +
				' No Active, Ready or initiate order found'
				,
				@puid
			)
	SELECT	@OutputValue =  'No Active,ready or Init PO'
	RETURN
END



--Get the product from the BOM
SELECT @prodcode = p.prod_code
FROM dbo.production_plan pp							WITH(NOLOCK) 
JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.[BOM_Formulation_Id] = bomfi.[BOM_Formulation_Id]
JOIN dbo.products_base p							WITH(NOLOCK)	ON Bomfi.prod_id = p.prod_id
JOIN dbo.Table_Fields_Values tfv					WITH(NOLOCK)	ON tfv.KeyId= bomfi.BOM_Formulation_Item_Id
JOIN dbo.Table_Fields	tf							WITH(NOLOCK)	ON tfv.Table_Field_Id = tf.Table_Field_Id AND tf.tableId = 28
WHERE bomfi.pu_id = @puid	
	AND tf.Table_Field_Desc = 'MaterialOriginGroup'
	AND tfv.value = @OG
	AND pp.pp_id = @ppid




IF @prodcode IS NULL 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0600 - ' +
				' Prod_code not found'	,
				@puid			)

	SELECT	@OutputValue =  'Material not found'
	RETURN
END



--get the location from the SOA property

SET @cnSiWMS	=	'PE:SI_WMS'


SET @pnLineID	=	'Destination LineID'

SET	@LineID	=		(SELECT  convert(varchar(50), pee.Value)
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	a.pu_id = @puid
							AND pee.Class = @cnSiWMS
							AND pee.Name = @pnLineID )

SET @pnLocation	=	'Destination Location'

SET	@LOCATION	=		(SELECT  convert(varchar(50), pee.Value)
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	a.pu_id = @puid
							AND pee.Class = @cnSiWMS
							AND pee.Name = @pnLocation )


IF @LOCATION IS NULL 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0700 - ' +
				' Destination not found'	,
				@puid			)
	
	SELECT	@OutputValue =  'Destination not found'
	RETURN
END


SET @RequestID = coalesce(((SELECT max(OpenTableID) FROM dbo.Local_WAMAS_OpenRequests_History)+1),1)


--Deleted in V1.2
--INSERT dbo.Local_WMS_Transaction ([Location],[Material],[ProcessOrder],[UserName],[Owner],[ModifiedDate],[WMS_Status_ID])
--VALUES (@LOCATION, @prodcode, @processorder, @userName, 'Proficy', @now, 1)

--Added in V1.2
INSERT dbo.Local_WAMAS_OPENREQUESTS ([RequestID],[RequestTime],[LocationID],[LineID],[PrimaryGCAS],[Status],[LastUpdatedTime], processorder)
VALUES (@RequestID,@Now,'OG',@LineID,@prodcode,'RequestMaterial', @now,@processorder)


SELECT	@OutputValue =  'Open request Created'