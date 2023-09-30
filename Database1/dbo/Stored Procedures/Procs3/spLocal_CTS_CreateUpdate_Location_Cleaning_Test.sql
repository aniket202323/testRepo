--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_CreateUpdate_Location_Cleaning_Test
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-20
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application 
-- Description			: It creates or update the user_defined_events for a location cleaning
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-20		U.Lapierre				Initial Release 

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
DECLARE @OutPutStatus	int,
		@OutPutMessage	varchar(50)
EXEC [dbo].[spLocal_CTS_CreateUpdate_Location_Cleaning_Test] 
8464,
 2968191,  --UDEid
'Major',
'Approved',
'4556664556',
 4.4,
 '3775883776',
 3.3,
 '18-Nov-2021 14:01:00',
'18-Nov-2021 14:09',
 381,
 383,
 '18-Nov-2021 14:12',
NULL,
@OutPutStatus						 OUTPUT,
@OutPutMessage						 OUTPUT
SELECT @OutPutStatus , @OutPutMessage

*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CTS_CreateUpdate_Location_Cleaning_Test]
@PUId								int,
@UDEId								int = NULL,
@CleaningType						varchar(30),  --Minor, major
@CleaningStatus						varchar(30),
@SanitizerBatch						varchar(100),
@SanitizerConc						float,
@DetergentBatch						varchar(100),
@DetergentConc						float,
@StartTime							datetime,
@EndTime							datetime,
@UserId								int,
@ApprovalUserId						int = NULL,
@ApprovalTime						datetime,
@Comment							varchar(5000),
@OutPutStatus						int OUTPUT,
@OutPutMessage						varchar(255) OUTPUT
		

AS
SET NOCOUNT ON

DECLARE
	@SPName							varchar(100),
	@DebugFlag						int,
	@UserName						varchar(100),
	@ApprovalUserName				varchar(50),
--Production unit info
	@TableIdUnit					int,
	@TFIdLocationType				int,
	@PUDesc							varchar(50),

--UDE
	@UpdateType						int,
	@EST_Cleaning					int,
	@UDEStartTime					datetime,
	@UDEEndTime						datetime,
	@UDEUserId						int,
	@Type							varchar(25),
	@TestId							bigint,
	@UDEDESC						varchar(255),
	@CommentId						int,
	@UDEStatusId					int,
	@LastStatusId					int,
	@SignatureId					int,
	@Machine						varchar(3000),
	@now							datetime,
--Variables
	@LoopVarId						int,
	@LoopValue						varchar(30),
--Comments							
	@CommentUserId					int,
	@CommentId2						int

DECLARE @VarToUpdate	TABLE (
VarId						int,
Val							varchar(25),
UpdType						int
)
---------------------------------------------------------
--Initialization
---------------------------------------------------------
SET @OutPutStatus = 1
SET @OutPutMessage = ''

SET @SPName = 'spLocal_CTS_CreateUpdate_Location_Cleaning_Test'
SET @DebugFlag =		(SELECT CONVERT(INT,sp.value) 
						FROM	dbo.site_parameters sp		WITH(NOLOCK)
						JOIN	dbo.parameters p			WITH(NOLOCK)		ON sp.parm_Id = p.parm_id
						WHERE p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level')

IF @DebugFlag IS NULL
	SET @DebugFlag = 0

IF @DebugFlag >=2
BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			1,
			'SP Started:'  + 
			' Cleaning Type: ' +  COALESCE(@CleaningType, '') + 
			' Cleaning Status: ' + COALESCE(@CleaningStatus, ''),
			@PUId	)
END

SET @UserName = (SELECT COALESCE(username, 'John Doe') FROM dbo.users_base WHERE user_id = @UserId)

---------------------------------------------------------
--Validation of the production unit
--Only unit with UDP CTS Location Type are allowed
---------------------------------------------------------
SET @TableIdUnit		=	(	SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
SET @TFIdLocationType	=	(	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdUnit AND Table_Field_Desc = 'CTS location Type')

IF (	SELECT tfv.value
		FROM dbo.Table_Fields_Values tfv	WITH(NOLOCK)	 
		WHERE tfv.Table_Field_Id = @TFIdLocationType
			AND keyid = @PUId
			) <> 'General'
BEGIN
	IF @DebugFlag >=1
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				11,
				' Invalid PuId'  + CONVERT(varchar(30),COALESCE(@PUID, 0))  ,
				@PUID	)
	END

	SET @OutPutStatus = 0
	SET @OutPutMessage = 'Invalid PuId'  + CONVERT(varchar(30),COALESCE(@PUID, 0))
	GOTO LaFin
END





/*-------------------------------------------------------
Get event_subtype
---------------------------------------------------------*/
SET @EST_Cleaning = (	SELECT event_subtype_id
							FROM dbo.event_subtypes WITH(NOLOCK) 
							WHERE event_subtype_desc = 'CTS location cleaning')



/*-------------------------------------------------------
Start cleaning : Cleaning Status = started
---------------------------------------------------------*/
IF @CleaningStatus = 'Started' OR @CleaningStatus= 'Cleaning Started'
BEGIN
	SET @CommentUserId = @UserId
	SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Cleaning Started')
	--A UDE Must be created
	IF @UDEId IS NULL
	BEGIN
		SET @UpdateType = 1
		SET @endTime = @StartTime

		--CHeck if the last cleaning event on this unit is completed
		SET @LastStatusId  = (SELECT TOP 1 event_status		
								FROM dbo.user_defined_events WITH(NOLOCK)
								WHERE pu_id = @puid	AND event_subtype_id = @EST_Cleaning
								ORDER BY Start_Time DESC)

		IF @LastStatusId = @UDEStatusId
		BEGIN
			IF @DebugFlag >=1
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						51,
						' Active cleaning in progress.  UDEID is required '  ,
						@PUId	)
			END

			SET @OutPutStatus = 0
			SET @OutPutMessage = 'Active cleaning in progress.  UDEID is required'
			GOTO LaFin
		END

	END
	ELSE
	BEGIN
		--Not the standard scenario.  When a cleaning starts, UDE shouldn't exist
		--Call the Get detail cleaning detail function
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					100,
					' Cleaning started while UDE exist.  UDEId: ' +  CONVERT(varchar(30),COALESCE(@UDEId, 0)) ,
					@PUId	)
		END

		SET @UpdateType = 2
		GOTO Lafin
	END

	-----------------------------------------------------------------------------------
	--Retrieve the variables that neeeds to be written during started phase
	-----------------------------------------------------------------------------------
	INSERT @VarToUpdate (varid, val, UpdType)
	SELECT var_id, @CleaningType, 1		FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Type'
	UNION
	SELECT var_id, @CleaningStatus, 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Status'
	UNION
	SELECT var_id, @DetergentBatch, 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Detergent batch:serial'
	UNION
	SELECT var_id, @SanitizerBatch, 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Sanitizer batch:serial'
	UNION
	SELECT var_id, CONVERT(varchar(30),@DetergentConc), 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Detergent batch:concentration'
	UNION
	SELECT var_id, CONVERT(varchar(30),@SanitizerConc), 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Sanitizer batch:concentration'
	UNION
	SELECT var_id, CONVERT(varchar(30),@StartTime,120), 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Cleaning:Start time'
	UNION
	SELECT var_id, @UserName, 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Cleaning:operator username'


	-----------------------------------------------------------------------------------
	--Define UDE spserver parameter
	-----------------------------------------------------------------------------------	
	SELECT	@UDEDesc = ude_desc, 
			@CommentId = comment_id	
	FROM dbo.user_defined_events WITH(NOLOCK)
	WHERE UDE_ID  = @UDEId

	IF @UDEDesc IS NULL
		SET @UDEDesc = 'LCL-' + CONVERT(varchar(30), @Starttime)

	GOTO Execution
END

/*-------------------------------------------------------
--Get existing UDE info
---------------------------------------------------------*/
SELECT	@UDEDesc = ude_desc, 
		@CommentId = comment_id	
FROM dbo.user_defined_events WITH(NOLOCK)
WHERE UDE_ID  = @UDEId



/*-------------------------------------------------------
Complete cleaning : Cleaning Status = Completed
---------------------------------------------------------*/
IF @CleaningStatus = 'Completed' OR @CleaningStatus= 'Cleaning Completed'
BEGIN
	SET @CommentUserId = @UserId
	IF @UDEId IS NULL
	BEGIN
		--UDE is NULL, Application must provide one
		IF @DebugFlag >=1
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					201,
					' Parameter UDE_ID is MISSING'   ,
					@PUID	)
		END

		SET @OutPutStatus = 0
		SET @OutPutMessage = 'Parameter UDE_ID is MISSING'
		GOTO LaFin
	END


	IF @Endtime IS NULL
	BEGIN
		SET @endTime = GETDATE()
		SET @endTime = DATEADD(ms,-1*DATEPART(ms,@endTime),@endTime)		--Remove ms
	END

	--This is update
	SET @UpdateType = 2

	SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Cleaning Completed')

	-----------------------------------------------------------------------------------
	--Retrieve the variables that neeeds to be written during Complete phase
	-----------------------------------------------------------------------------------
	INSERT @VarToUpdate (varid, val, UpdType)
	SELECT var_id, CONVERT(varchar(30),@EndTime,120), 1		FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Cleaning:End time'
		UNION
	SELECT var_id, @CleaningStatus, 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Status'

	GOTO Execution
END



/*-------------------------------------------------------
Approved cleaning : Cleaning Status = Approved
---------------------------------------------------------*/
IF @CleaningStatus = 'Approved' OR @CleaningStatus= 'Cleaning Approved'
BEGIN
	SET @CommentUserId = @ApprovalUserId
	IF @UDEId IS NULL
	BEGIN
		--UDE is NULL, Application must provide one
		IF @DebugFlag >=1
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					301,
					' Parameter UDE_ID is MISSING'   ,
					@PUID	)
		END

		SET @OutPutStatus = 0
		SET @OutPutMessage = 'Parameter UDE_ID is MISSING'
		GOTO LaFin
	END


	SET @Machine = (SELECT sp.value
					FROM dbo.site_parameters sp		WITH(NOLOCK)
					JOIN dbo.parameters p			WITH(NOLOCK)	ON sp.parm_id = p.parm_id
					WHERE p.Parm_Name  ='SiteName')

	SET @Now = GETDATE()
	--Create signature Id
	EXEC  [dbo].[spSDK_AU_ESignature]
			null, 
			@SignatureId OUTPUT, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			@ApprovalUserId, 
			@Machine, 
			null, 
			null, 
			@Now



	SET @ApprovalUserName = (SELECT COALESCE(username, 'John Doe') FROM dbo.users_base WHERE user_id = @ApprovalUserId)
	IF @ApprovalUserName IS NULL
	BEGIN
		IF @DebugFlag >=1
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					305,
					' Invalid Approval user'   ,
					@PUID	)
		END

		SET @OutPutStatus = 0
		SET @OutPutMessage = 'Invalid Approval user'
		GOTO LaFin
	END


	IF @ApprovalTime IS NULL
	BEGIN
		IF @DebugFlag >=1
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					311,
					' ApprovalTime required'   ,
					@PUID	)
		END

		SET @OutPutStatus = 0
		SET @OutPutMessage = ' ApprovalTime required'
		GOTO LaFin
	END

	IF @ApprovalTime IS NULL
	BEGIN
		SET @ApprovalTime = GETDATE()
		SET @ApprovalTime = DATEADD(ms,-1*DATEPART(ms,@ApprovalTime),@ApprovalTime)		--Remove ms
	END

	SET @endTime = @ApprovalTime

	--This is update
	SET @UpdateType = 2

	SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Cleaning Approved')

	-----------------------------------------------------------------------------------
	--Retrieve the variables that neeeds to be written during Complete phase
	-----------------------------------------------------------------------------------
	INSERT @VarToUpdate (varid, val, UpdType)
	SELECT var_id, @ApprovalUserName, 1		FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Cleaning:approver username'
	UNION
	SELECT var_id, CONVERT(varchar(30),@ApprovalTime,120), 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Approved:Timestamp'
	UNION
	SELECT var_id, @CleaningStatus, 1	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @puid AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Status'

	GOTO Execution
END



Execution:
-----------------------------------------------------------------------------------
--Manage comment
-----------------------------------------------------------------------------------
IF @Comment IS NOt NULL
BEGIN
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				800,
				' Create comments'   ,
				@PUID	)
	END
	EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
END






/***********************************************************************
EXECUTE THE ACTIONS
************************************************************************/
--Create/Update the UDE
IF @DebugFlag >=2
BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			900,
			' Start Execution Section'   ,
			@PUID	)
END
EXEC [dbo].[spServer_DBMgrUpdUserEvent]
	0, 
	'CTS location cleaning', 
	NULL,					--Action comment Id
	NULL,					--Action 4
	NULL, 					--Action 3
	NULL,					--Action 2
	NULL, 					--Action 1
	NULL,					--Cause comment Id
	NULL,					--Cause 4
	NULL, 					--Cause 3
	NULL,					--Cause 2
	NULL, 					--Cause 1
	NULL,					--Ack by
	0,						--Acked
	0,						--Duration
	@EST_Cleaning,			--event_subTypeId
	@PUID,					--pu_id
	@UDEDESC,				--UDE desc
	@UDEId OUTPUT,			--UDE_ID
	@UserId,				--User_Id
	NULL,					--Acked On
	@StartTime,				--@UDE Starttime, 
	@EndTime,				--@UDE endtime, 
	NULL,					--Research CommentId
	NULL,					--Research Status id
	NULL,					--Research User id
	NULL,					--Research Open Date
	NULL,					--Research Close date
	@UpdateType,			--Transaction type
	@CommentId2,			--Comment Id
	NULL,					--reason tree
	@SignatureId,			--signature Id
	NULL,					--eventId
	NULL,					--parent ude id
	@UDEStatusId,			--event status
	1,						--Testing status
	NULL,					--conformance
	NULL,					--test percent complete
	0	

SET @outputStatus = @udeid

IF @UDEId IS NOT NULL		
BEGIN
	IF @DebugFlag >=2
	BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			200,
			'Created or Updated UDEId: ' + CONVERT(varchar(30), @UDEId),
			@puid	)
	END


	--Update the variables
	SET @LoopVarId = (SELECT MIN(varid) FROM @VarToUpdate)
	WHILE @LoopVarId IS NOT NULL
	BEGIN
		SET @LoopValue = (SELECT val FROM @VarToUpdate WHERE varid = @LoopVarId )

		EXEC dbo.spServer_DBMgrUpdTest2 
			@LoopVarId,					--Var_id
			@UserId	,					--User_id
			0,							--Cancelled
			@LoopValue,					--New_result
			@EndTime,					--result_on
			NULL,						--Transnum
			NULL,						--Comment_id
			NULL,						--ArrayId
			@UDEId,						--event_id
			@PuId	,					--Pu_id
			@TestId	OUTPUT,				--testId
			NULL,						--Entry_On
			NULL,
			NULL,
			NULL,
			NULL

		SET @LoopVarId = (SELECT MIN(varid) FROM @VarToUpdate WHERE varid > @LoopVarId)
	END

	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				300,
				'All done writing into variables.',
				@puid	)
	END

END

LaFin:


IF @DebugFlag >=2
BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			999,
			'SP Ended:'  ,
			@puid	)
END


SET NOCOUNT OFF

RETURN
