CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationStackReturn]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@Puid						int,
		@TrigerVarid				int,
		@ActionType					varchar(25),
		@ValidAT					varchar(25),
		@returnType					varchar(25)




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationStackReturn
	@OutputValue				OUTPUT,
	'22-aug-2017 14:03:27',				
	4822,
	31010,
	'3 - Stack return',
	'3 - Stack return',
	'Empty'

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE 
		@varidQty					int,
		@varidULID					int,
		@varidReturnType			int,
		@VarIdExecute				int,
		@varIdTagQty				int,
		@varIdTagStatus				int,
		@varIdTagULID				int,
		@varIdTagRunOut				int,
		@varidTrayDump				int,
		@Count						int,
		@UserId						int,
		@ULID						varchar(50),
		@EventId					int,
		@Qty						float,
		@QtyConsumed				float,
		@CountEC					int,
		@TrayDumped					varchar(50),
		@Status						int



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
--EXIT if the Action type is not Clear All
-------------------------------------------------------------------------------------------
IF @ActionType <> @ValidAT
BEGIN
	SELECT	@OutputValue = 'Invalid Action Type'
	RETURN
END




-------------------------------------------------------------------------------------------
--Get User
-------------------------------------------------------------------------------------------
SET @userId = (SELECT entry_by FROM dbo.tests WITH(NOLOCK) WHERE var_id = @TrigerVarid AND result_on = @thistime)




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





-------------------------------------------------------------------------------------------
--Try to get the oldest Stack on the production unit
-------------------------------------------------------------------------------------------
--V1.2
--SET @eventid = (SELECT TOP 1	event_id
--				FROM dbo.events e WITH(NOLOCK) 
--				JOIN dbo.production_status ps WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
--				WHERE pu_id = @puid 
--					AND prodStatus_desc IN ('Running', 'Consumed')	
--				ORDER BY timestamp DESC
--				)


SET @eventId = (SELECT TOP 1 source_event_id
				FROM dbo.event_components ec
				JOIN dbo.events e ON ec.source_event_id = e.event_id
				JOIN dbo.production_status ps WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
				WHERE e.pu_id = @puid
					AND prodStatus_desc IN ('Running')--, 'Consumed')	
				ORDER by ec.timestamp DESC)


IF @eventId IS NULL
	SET @eventId = (SELECT top 1 event_id
					FROM dbo.events e WITH(NOLOCK)  
					JOIN dbo.production_status ps WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
					WHERE e.pu_id = @puid
						AND prodStatus_desc IN ('Delivered','To Be returned')
					ORDER by e.timestamp ASC
					)

IF @eventid IS NULL
BEGIN
	SELECT	@OutputValue = 'No Stack in return Pos'
	RETURN
END


SET @ULID = (	SELECT	CASE CHARINDEX('_',e.Event_Num,0)
						WHEN 0 THEN e.Event_Num
						ELSE COALESCE(LEFT(e.Event_Num,CHARINDEX('_',e.Event_Num,0)-1),e.Event_Num)
						END	
				FROM dbo.events e WITH(NOLOCK) 
				WHERE event_id = @eventid
				)

				


--------------------------------------------------------------------
--Case return Type not set
-------------------------------------------------------------------- 
IF @returnType = '' OR @returnType IS NULL
BEGIN
	SELECT @Outputvalue = 'Missing return type'
	RETURN
END



--------------------------------------------------------------------
--Case Empty
-------------------------------------------------------------------- 
IF @returnType = 'Empty'
BEGIN

	SET @Qty = 0.00

	--4 is the status of Upack for empty
	SET @Status = 4
END




--------------------------------------------------------------------
--Case Unknown
-------------------------------------------------------------------- 
IF @returnType = 'Unknown Qty'
BEGIN

	--Calculate the actual quantity of the tray
	SET @Qty = (	SELECT	initial_dimension_x
					FROM dbo.event_details WITH(NOLOCK) 
					WHERE event_id = @eventid
					)

	IF @Qty IS NULL
		SET @Qty = 0.00

	--3 is the status of Upack for unknown Qty
	SET @Status = 3
END




--------------------------------------------------------------------
--Case Unknown
-------------------------------------------------------------------- 
IF @returnType = 'Known Qty'
BEGIN
	--Calculate the actual quantity of the tray
	SET @Qty = (	SELECT	initial_dimension_x
					FROM dbo.event_details WITH(NOLOCK) 
					WHERE event_id = @eventid
					)

	IF @Qty IS NULL
		SET @Qty = 0.00

	--2 is the status of Upack for known Qty
	SET @Status = 2
END







------------------------------------------------------------------------------------------
--Fill the temp var table
------------------------------------------------------------------------------------------

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidQty,@puid,@userId,0,@Qty,@ThisTime,1,0,0)

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidULID,@puid,@userId,0,@ULID,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidReturnType,@puid,@userId,1,NULL,@ThisTime,3,0,0)

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@VarIdExecute,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidTrayDump,@puid,@userId,0,@TrayDumped,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagULID,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagStatus,@puid,@userId,0,0,@ThisTime,1,0,0)







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

SELECT	@OutputValue = CONVERT(varchar(30),@Count) + ' Variable(s) updated'