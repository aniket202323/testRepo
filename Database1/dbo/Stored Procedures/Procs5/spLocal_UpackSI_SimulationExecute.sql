CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationExecute]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@Puid						int,
		@TrigerVarid				int,
		@ActionType					varchar(25),
		@ValidAT					varchar(25),
		@NewStack					varchar(25),
		@TrayDump					varchar(25),
		@StackReturn				varchar(25),
		@Weighedreturn				varchar(25)




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationExecute
	@OutputValue				OUTPUT,
	'27-Nov-2017 15:47:21',				
	4822,
	31020,
	'4 - Weighed return',
	'0 - Clear All',
	'1 - New Stack on Pos 3',
	'2 - Tray Dump',
	'3 - Stack return',
	'4 - Weighed return'

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE 
		@varidQty					int,
		@varidULID					int,
		@varidReturnType			int,
		@varidTrayDump				int,
		@VarIdExecute				int,
		@varIdTagQty				int,
		@varIdTagStatus				int,
		@varIdTagULID				int,
		@varIdTagRunOut				int,
		@varIdWeighedReturn			int,
		@Count						int,
		@UserId						int,
		@ExecuteValue				bit,
		@ULID						varchar(50),
		@Qty						float,
		@ReturnType					varchar(25),
		@Status						int,
		@Location					varchar(30),
		@cnSiWMS					varchar(30),
		@pnLocation					varchar(30),
		@UserName					varchar(50),
		@Message					nvarchar(4000),
		@RequestId					varchar(50),
		@GCAS						varchar(30),
		@VendorLot					varchar(50),
		@returnedTime				datetime,
		@UOM						varchar(30),
		@OP_ReturnCode				int,
		@OP_XML						xml,

		@WAMASFlag					bit,
		@RTCISSubscriptionID		int,
		@pnLineID					varchar(50),
		@LineID						varchar(25),
		@LOCATIONID					varchar(50),
		@MSTimestamp				bigint,
		@UTCDIff					int,
		@TableId					int,
		@TableFieldId				int


DECLARE @RSVar TABLE (
varid			int,
puid			int,
userId			int,
Canceled		int,
Result			varchar(25),
ResultOn		datetime,
transType		int,
PrePost			int,
SecondUserId	int,
TransNum		int,
EventId			int,
ArrayId			int,
CommentId		int,
ESigId			int,
EntryOn			int,
TestId			int,
ShouldArchive	int,
HasHistory		int,
IsLocked		int)



-------------------------------------------------------------------------------------------
--EXIT if the execute is not checked
-------------------------------------------------------------------------------------------
SET @ExecuteValue = (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @TrigerVarid AND result_on = @thistime)
IF @ExecuteValue !=1
BEGIN
	SELECT	@OutputValue = 'Execute not checked'
	RETURN
END







-------------------------------------------------------------------------------------------
--Get User
-------------------------------------------------------------------------------------------
SET @userId = (SELECT entry_by FROM dbo.tests WITH(NOLOCK) WHERE var_id = @TrigerVarid AND result_on = @thistime)
SET @UserName = (SELECT username FROM users where user_id = @userId) 

SET @LOCATIONID = 'OG'

-------------------------------------------------------------------------------------------
--retrieve the variables var_id
-------------------------------------------------------------------------------------------
SET @varidQty =			(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_Qty')
SET @varidULID =		(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_ULID')
SET @varidReturnType =	(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_ReturnType')
SET @varidTrayDump =	(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_TrayDumped')
SET @VarIdExecute =		(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_Execute')
SET @varIdTagQty =		(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_TagQty')
SET @varIdTagStatus =	(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_TagStatus')
SET @varIdTagULID =		(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_TagULID')
SET @varIdTagRunOut =	(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_TagRunOut')
SET @varIdWeighedReturn =	(	SELECT var_id	FROM dbo.variables	WITH(NOLOCK)	WHERE pu_id = @Puid	AND extended_info = 'SI_WeighedReturn')



------------------------------------------------------------------------------------------
--Fill the temp var table
------------------------------------------------------------------------------------------

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidQty,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidULID,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidReturnType,@puid,@userId,0,NULL,@ThisTime,3,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@VarIdExecute,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,0,@ThisTime,1,0,0)




---------------------------------------------------------------------------------
--Manage the New tray action
---------------------------------------------------------------------------------
IF @ActionType = @ValidAT
BEGIN
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,0,@ThisTime,1,0,0)

	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,0,@ThisTime,1,0,0)

	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,0,@ThisTime,1,0,0)
END





---------------------------------------------------------------------------------
--Manage the New stack action
---------------------------------------------------------------------------------
IF @ActionType = @newStack
BEGIN
	--Read ULID from ULID variable
	SET @ULID = (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidULID AND Result_on = @ThisTime )
	SET @Qty =  (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidQty AND Result_on = @ThisTime )

	--Quantity is ULID quantity
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,@Qty,@ThisTime,1,0,0)

	--Send ULID
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,@ULID,@ThisTime,1,0,0)

	--Send value 1 for status "In progress"
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,1,@ThisTime,1,0,0)
END



---------------------------------------------------------------------------------
--Manage the tray dump action
---------------------------------------------------------------------------------
IF @ActionType = @TrayDump
BEGIN
	--Read ULID from ULID variable
	SET @ULID = (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidULID AND Result_on = @ThisTime )
	SET @Qty =  (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidQty AND Result_on = @ThisTime )

	--Quantity is ULID quantity
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,@Qty,@ThisTime,1,0,0)

	--Send ULID
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,@ULID,@ThisTime,1,0,0)

	--Send value 1 for status "In progress"
	INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,1,@ThisTime,1,0,0)
END




---------------------------------------------------------------------------------
--Manage the stack return action
---------------------------------------------------------------------------------
IF @ActionType = @StackReturn
BEGIN
	--Get the return Type
	SET @ReturnType = (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidReturnType AND result_on = @ThisTime)

	IF @ReturnType IS NULL
	BEGIN
		--We do not send data to tag.  Only Uncheck the execute
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@VarIdExecute,@puid,@userId,0,0,@ThisTime,2,0,0)
	END
	ELSE
	BEGIN
			--Read ULID from ULID variable and qunatity from qty variable
		SET @ULID = (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidULID AND Result_on = @ThisTime )
		SET @Qty =  (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidQty AND Result_on = @ThisTime )
	END




	--------------------------------------------------------------------
	--Case Empty
	-------------------------------------------------------------------- 
	IF @returnType = 'Empty'
	BEGIN
		--Quantity is ULID quantity
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,@Qty,@ThisTime,1,0,0)

		--Send ULID
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,@ULID,@ThisTime,1,0,0)

		--4 is the status of Upack for empty
		SET @Status = 4
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,@Status,@ThisTime,1,0,0)
	END




	--------------------------------------------------------------------
	--Case 'Unknown Qty'
	-------------------------------------------------------------------- 
	IF @returnType = 'Unknown Qty'
	BEGIN
		--Quantity is ULID quantity
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,@Qty,@ThisTime,1,0,0)

		--Send ULID
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,@ULID,@ThisTime,1,0,0)

		--4 is the status of Upack for empty
		SET @Status = 3
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,@Status,@ThisTime,1,0,0)
	END


	--------------------------------------------------------------------
	--Case 'Known Qty'
	-------------------------------------------------------------------- 
	IF @returnType = 'Known Qty'
	BEGIN
		--Quantity is ULID quantity
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,@Qty,@ThisTime,1,0,0)

		--Send ULID
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,@ULID,@ThisTime,1,0,0)

		--4 is the status of Upack for empty
		SET @Status = 2
		INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,@Status,@ThisTime,1,0,0)
	END


END


---------------------------------------------------------------------------------
--Manage weighed return
---------------------------------------------------------------------------------
IF @ActionType = @weighedReturn
BEGIN
	SET @RTCISSubscriptionID = (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS')	


	SET @TableId		= (	SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'SUBSCRIPTION')
	SET @TableFieldId	= (	SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'USE_WAMAS' and tf.TableId = @TableId)
	
	SET @WAMASFlag		= (	SELECT	CONVERT(bit, tfv.Value)
							FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
							WHERE	tfv.KeyId			=	@RTCISSubscriptionID
							and		tfv.Table_Field_Id	=	@TableFieldId
							and		tfv.TableId			=	@TableId);

	IF @WAMASFlag = 1
	RETURN

	--Read ULID from ULID variable
	SET @ULID = (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidULID AND Result_on = @ThisTime )
	SET @Qty =  (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @varidweighedReturn AND Result_on = @ThisTime )


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


	SELECT	@requestId	= RequestId,
			@vendorLot	= VendorLotId,
			@Gcas		= GCAS,
			@UOM		= [QuantityUOM]
	FROM [dbo].[Local_WAMAS_OPENREQUESTS] WITH(NOLOCK)
	WHERE ULID = @ULID
		AND LineID = @LineID
		AND [Status] = 'ToBeReturned'



/*
<?xml version="1.0" encoding="UTF-8" ?>
<root>
  <requestId>1234567890</requestId>
  <ULID>12312312312312312312</ULID>
  <Location>ULIN04</Location>
  <materialGcas>85472541</materialGcas>
  <vendorLot>4512784514</vendorLot>
  <returnedTime>2017-03-22T14:25:30+01:00</returnedTime>
  <returnedQuantity>
    <value>800</value>
    <UOM>EA</UOM>
  </returnedQuantity>
</root>
*/

----------------------- 1.7
SET @UTCDiff = datediff(minute,GETDATE(),GETUTCDATE())

SET @ThisTime = DATEADD(minute,@UTCDiff,@ThisTime)

SET @MSTimestamp =  convert(varchar(25),(cast(datediff(minute,'1970-01-01',@ThisTime) AS bigint)*60*1000)) 
----------------------- 1.7


	SET @Message =  '<RESTApiCall>'
	SET @Message = @Message + '<requestId>'+ CONVERT(varchar(50),@requestId)+'</requestId>'
	SET @Message = @Message + '<ULID>'+@ULID+'</ULID>'
	SET @Message = @Message + '<Location><locationId>'+@LOCATIONID+'</locationId>'
	SET @Message = @Message + '<lineId>'+@LineID+'</lineId></Location>'
	SET @Message = @Message + '<materialGcas>'
	SET @Message = @Message + '<primaryGcas>'	+@Gcas+'</primaryGcas>'
	SET @Message = @Message + '<alternateGcas>'	+@Gcas+'</alternateGcas></materialGcas>'
	SET @Message = @Message + '<vendorLot>'+@vendorLot+'</vendorLot>'
	SET @Message = @Message + '<returnedTime>'+convert(varchar(25),@MSTimestamp) +'</returnedTime>'
	SET @Message = @Message + '<returnedQuantity>'
	SET @Message = @Message + '<value>'+CONVERT(varchar(50),@Qty)+'</value>'
	SET @Message = @Message + '<UOM>'+@UOM+'</UOM>'
	SET @Message = @Message + '</returnedQuantity>'
	SET @Message = @Message + '</RESTApiCall>'

	EXEC	[dbo].[spLocal_WAMAS_WeighedReturn]	@Message, @OP_ReturnCode OUTPUT, @OP_XML OUTPUT  --V1.2
	--SELECT @Message
	

END

--Push result sets
SET @count = (SELECT count (1) FROM @RSVar)

IF @count > 0
BEGIN
	SELECT 	2,
			varid			,
			puid			,
			userId			,
			Canceled		,
			Result			,
			ResultOn		,
			transType		,
			PrePost			,
			SecondUserId	,
			TransNum		,
			EventId			,
			ArrayId			,
			CommentId		,
			ESigId			,
			EntryOn			,
			TestId			,
			ShouldArchive	,
			HasHistory		,
			IsLocked		
	FROM @RSVar
END

SELECT	@OutputValue = CONVERT(varchar(30),@Count) + ' Tags updated'