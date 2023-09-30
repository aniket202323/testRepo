CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationClearAll]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@Puid						int,
		@TrigerVarid				int,
		@ActionType					varchar(25),
		@ValidAT					varchar(25)




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationClearAll
	@OutputValue				OUTPUT,
	'27-Jun-2017 10:28',				
	4822,
	31010,
	'0 - Clear All',
	'0 - Clear All'

	
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
		@Count						int,
		@UserId						int

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




------------------------------------------------------------------------------------------
--Fill the temp var table
------------------------------------------------------------------------------------------

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidQty,@puid,@userId,0,0,@ThisTime,1,0,0)

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidULID,@puid,@userId,0,0,@ThisTime,1,0,0)

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidReturnType,@puid,@userId,1,NULL,@ThisTime,3,0,0)

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varidTrayDump,@puid,@userId,1,NULL,@ThisTime,3,0,0)

INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@VarIdExecute,@puid,@userId,0,0,@ThisTime,1,0,0)

--INSERT @RSVar (varid,puid,userId,Canceled,Result,ResultOn,transType,	PrePost	,TransNum)  VALUES (@varIdTagQty,@puid,@userId,0,0,@ThisTime,1,0,0)

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