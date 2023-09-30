--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_MakeReservation
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-05
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application or PPA model stored proc
-- Description			: Make a reservation for a serial in a specifies location
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-05		U.Lapierre				Initial Release 

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
DECLARE @OutPutStatus	int,
		@OutPutMessage	varchar(50)
EXEC [dbo].[spLocal_CTS_MakeReservation] 31,1060, 7, 'Soft', 'ulapierre', @OutPutStatus OUTPUT, @OutPutMessage OUTPUT
SELECT @OutPutStatus , @OutPutMessage

*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CTS_MakeReservation]
@ApplianceEventId					int,
@LocationPuId						int,
@ReservationPPId					int,
@ReservationType					varchar(25),
@C_User								varchar(100),
@OutPutStatus						int OUTPUT,
@OutPutMessage						varchar(255) OUTPUT
		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
	@SPName							varchar(100),
	@DebugFlag						int,

--User
	@UserId							int,
--Appliance
	@AppliancePUID					int,
	@ApplianceProdId				int,
	@ApplianceStatusId				int,
	@ApplianceStatus				varchar(50),

--Location
	@ExistVarIdStatus				int,
	@ExistVarIdType					int,
	@VarIdPPID						int,
	@VarIdEventId					int,
	@VarIdType						int,
	@VarIdStatus					int,
	@LoopVarId						int,
	@LoopValue						varchar(30),

--UDE
	@EST_Reservation				int,
	@ExistUDEId						int,
	@ExistUDEPUID					int,
	@ExistUDEStartTime				datetime,
	@ExistUDEEndTime				datetime,
	@ExistUserId					int,
	@ExistType						varchar(25),
	@UDEStartTime					datetime,
	@UDEEndTime						datetime,
	@TestId							bigint,
	@UDEDESC						varchar(255),
	@UDEId							int,
--ProcessOrder
	@BomfiId						int,

--Current Appliace Location
	@CurrentApplianceLocationId		INTEGER

DECLARE @VarToUpdate	TABLE (
VarId						int,
Val							varchar(25)
)
---------------------------------------------------------
--Initialization
---------------------------------------------------------
SET @OutPutStatus = 1
SET @OutPutMessage = ''

SET @SPName = 'spLocal_CTS_MakeReservation'
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
			' Appliance EventId: ' + CONVERT(varchar(30), COALESCE(@ApplianceEventId, 0)) + 
			' Location Puid: ' + CONVERT(varchar(30), COALESCE(@LocationPuId, 0)) + 
			' Reservation Type: ' + COALESCE(@ReservationType, 'Missing') + 
			' User name: ' + COALESCE(@C_User, 'Missing'),
			@ApplianceEventId	)
END


---------------------------------------------------------
--User validation
---------------------------------------------------------
SET @UserId  = ( SELECT user_id FROM dbo.users_base WITH(NOLOCK) WHERE WindowsUserInfo = @C_User)

IF @UserId IS NULL
	SET @UserId  = ( SELECT user_id FROM dbo.users_base WITH(NOLOCK) WHERE username LIKE '%' +  @C_User + '%')

IF @UserId IS NOT NULL
BEGIN
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				20,
				' User Id: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) ,
				@ApplianceEventId	)
	END
END
ELSE
BEGIN
	IF @DebugFlag >=1
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				21,
				' Error getting User ID.  Go to end'  ,
				@ApplianceEventId	)
	END

	SET @OutPutStatus = 0
	SET @OutPutMessage = 'Error getting User ID.'
	GOTO LaFin
END



/*-------------------------------------------------------
Appliance validation
-An appliance can have only one reservation at a time
-An existing soft reservation it can be replaced by anybody
-An existing hard reservation can only be replaced by who made the reservation or a super user
---------------------------------------------------------*/

-- GET @CurrentApplianceLocationId
SET @CurrentApplianceLocationId =	(
									SELECT	Location_id
									FROM		[dbo].[fnLocal_CTS_Appliance_Transitions](@ApplianceEventId, 0, NULL, NULL,'BACKWARD')
									)


SET @EST_Reservation = (	SELECT event_subtype_id
							FROM dbo.event_subtypes WITH(NOLOCK) 
							WHERE event_subtype_desc = 'CTS Reservation')

SET @ExistUDEId = (	SELECT ude_id 
					FROM dbo.User_Defined_Events WITH(NOLOCK) 
					WHERE Event_Subtype_Id = @EST_Reservation
						AND UDE_DESC = 'Reserved'
						AND Event_Id = @ApplianceEventId)


--Reservation Exists
IF @ExistUDEId  IS NOT NULL
BEGIN
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				50,
				'There is already a reservtion for this appliance (UDE_ID) :' + CONVERT(varchar(30), COALESCE(@ExistUDEId, 0)) ,
				@ApplianceEventId	)
	END

	--Get existing reservation detail
	SELECT 	@ExistUDEStartTime	= start_time,
			@ExistUDEEndTime	= end_time,
			@ExistUserId		= user_id,
			@ExistUDEPUID		= pu_id
	FROM dbo.User_Defined_Events WITH(NOLOCK) 
	WHERE ude_id = @ExistUDEId

	--Get variable to ready type of reservation
	SET @ExistVarIdType = (	SELECT var_id 
							FROM dbo.variables_base WITH(NOLOCK) 
							WHERE pu_id = @ExistUDEPUID 
								AND event_subtype_id = @EST_Reservation
								AND Test_Name = 'Type')

	SET @ExistType =	(	SELECT result 
							FROM dbo.tests WITH(NOLOCK)
							WHERE var_id = @ExistVarIdType
								AND result_on = @ExistUDEEndTime	)
		

	IF @ExistType = 'Hard'
	BEGIN
	--for hard reservation, only some user can replace it
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					70,
					'The existing reservation is Hard' ,
					@ApplianceEventId	)
		END

		--Check if user is super user
		IF EXISTS (	SELECT urs.USER_Role_Security_ID	
					FROM dbo.User_Role_Security urs
					JOIN dbo.users_base u1				WITH(NOLOCK)	ON  urs.Role_User_Id = u1.User_Id AND u1.Username = 'Plant Apps Admin'
					JOIN dbo.Users_Base u2				WITH(NOLOCK)	ON  urs.User_Id = u2.User_Id	AND u2.User_Id = @UserId
			)
		BEGIN
			IF @DebugFlag >=2
			BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					80,
					'We have a Super user!' ,
					@ApplianceEventId	)
			END
		END
		ELSE
		BEGIN
			IF @Userid = @ExistUserId
			BEGIN
				IF @DebugFlag >=2
				BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						90,
						'This is the user that made the existing reservation' ,
						@ApplianceEventId	)
				END
			END
			ELSE
			BEGIN
				--We can't override the existing hard reservation
				IF @DebugFlag >=1
				BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						91,
						'User cannot override the existing hard reservation' ,
						@ApplianceEventId	)
				END

				SET @OutPutStatus = 0
				SET @OutPutMessage = 'User cannot override the existing hard reservation'
				GOTO LaFin
			END
		END
	END

END


/*-------------------------------------------------------
Location validation
-Appiance type must be in te RMI of the location
---------------------------------------------------------*/
--Get Appliance Info
SELECT	@AppliancePUID		=	e.pu_id
FROM dbo.events e				WITH(NOLOCK)
WHERE e.event_id = @ApplianceEventId

IF NOT EXISTS (	
					SELECT	1 
					FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
							JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
								ON pei.pei_id = peis.pei_id
					WHERE	pei.pu_id = @LocationPuId
								AND peis.PU_Id =  @AppliancePUID
								AND PEI.Input_Name = 'CTS Appliance'
					)
BEGIN
	--This is not a valid location for this appliance
	IF @DebugFlag >=1
	BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			111,
			'Location is not valid for the appliance type' ,
			@ApplianceEventId	)
	END

	SET @OutPutStatus = 0
	SET @OutPutMessage = 'Location is not valid for the appliance type'
	GOTO LaFin

END

IF NOT EXISTS	(SELECT 1 
				FROM	dbo.prdExec_inputs PEI	WITH(NOLOCK)
						JOIN dbo.PrdExec_Input_Sources peis	WITH(NOLOCK)
							ON pei.pei_id = peis.pei_id 
							AND peis.PU_Id = @CurrentApplianceLocationId
						JOIN dbo.PrdExec_Status PES WITH(NOLOCK) 
							ON PES.PU_Id = PEI.PU_Id
				WHERE	pei.pu_id = @LocationPuId
						AND PEI.Input_Name = 'CTS Location Transition'

				)

BEGIN
	--This is not a valid location for this appliance
	IF @DebugFlag >=1
	BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			111,
			'Location is not valid for this movement' ,
			@ApplianceEventId	)
	END

	SET @OutPutStatus = 0
	SET @OutPutMessage = 'Location is not valid for this movement'
	GOTO LaFin

END

/*-------------------------------------------------------
Process Order validation
-Process order must exist on the location
-An appliance containing material must match the BOM of the process order
---------------------------------------------------------*/
SELECT	@ApplianceProdId = last_product_id,
		@ApplianceStatus = Clean_Status
FROM [dbo].[fnLocal_CTS_Appliance_Status](@ApplianceEventId,NULL)

IF @ApplianceProdId IS NULL
	SET @ApplianceProdId = 0

IF @ApplianceStatus = 'In Use' AND @ApplianceProdId > 0
BEGIN
	--There is material in the Appliance.  Let verify the BOM.
	SET @BomfiId = (	SELECT bomfi.BOM_Formulation_Item_Id 
						FROM dbo.production_plan pp							WITH(NOLOCK)
						JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
						WHERE pp.pp_id = @ReservationPPId
					)
	IF @BomfiId IS NULL
			SET @BomfiId = (	SELECT bomfi.BOM_Formulation_Item_Id 
								FROM dbo.production_plan pp							WITH(NOLOCK)
								JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
								JOIN dbo.Bill_Of_Material_Substitution boms			WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
								WHERE pp.pp_id = @ReservationPPId
									AND boms.Prod_Id = @ApplianceProdId	)

	IF @BomfiId IS NULL
	BEGIN
		--This is not a valid PrO for the material in the appliance
		IF @DebugFlag >=1
		BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				151,
				'This is not a valid PrO for the material in the appliance' ,
				@ApplianceEventId	)
		END

		SET @OutPutStatus = 0
		SET @OutPutMessage = 'This is not a valid PrO for the material in the appliance'
		GOTO LaFin
	END


END



/***********************************************************************
EXECUTE THE ACTIONS
************************************************************************/

--=================Update the existing reservation============================
IF @ExistUDEId IS NOT NULL		
BEGIN
	IF @DebugFlag >=2
	BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			200,
			'There is an existing UDE to Cancel: ' + CONVERT(varchar(30), @ExistUDEId),
			@ApplianceEventId	)
	END
	--Get variable to ready type of reservation
	SET @ExistVarIdType = (	SELECT var_id 
							FROM dbo.variables_base WITH(NOLOCK) 
							WHERE pu_id = @ExistUDEPUID 
								AND event_subtype_id = @EST_Reservation
								AND Test_Name = 'Status')

	SET @TestId = (SELECT test_id FROM dbo.tests WITH(NOLOCK) WHERE var_id = @ExistVarIdType AND result_on = @ExistUDEStartTime )

	--Update status variable
	EXEC dbo.spServer_DBMgrUpdTest2 
		@ExistVarIdType,			--Var_id
		@UserId	,					--User_id
		0,							--Cancelled
		'InActive',					--New_result
		@ExistUDEStartTime,			--result_on
		NULL,						--Transnum
		NULL,						--Comment_id
		NULL,						--ArrayId
		@ExistUDEId,				--event_id
		@ExistUDEPUID	,			--Pu_id
		@TestId	OUTPUT,				--testId
		NULL,						--Entry_On
		NULL,
		NULL,
		NULL,
		NULL

	--Ude desc must be a date
	SET @UDEDESC = CONVERT(varchar(50),GETDATE(),120)

	--Update UDE desc 
	EXEC [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS Reservation', 
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
		@EST_Reservation,		--event_subTypeId
		@ExistUDEPUID,			--pu_id
		@UDEDESC,				--UDE desc
		@ExistUDEId OUTPUT,		--UDE_ID
		@UserId,				--User_Id
		NULL,					--Acked On
		@ExistUDEStartTime,		--@UDE Starttime, 
		@ExistUDEEndTime,		--@UDE endtime, 
		NULL,					--Research CommentId
		NULL,					--Research Status id
		NULL,					--Research User id
		NULL,					--Research Open Date
		NULL,					--Research Close date
		2,						--Transaction type
		NULL,					--Comment Id
		NULL,					--reason tree
		NULL,					--signature Id
		NULL,					--eventId
		NULL,					--parent ude id
		NULL,					--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0						--return result set

	IF @DebugFlag >=2
	BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			220,
			'UDE cancelled: ' + CONVERT(varchar(30), @ExistUDEId),
			@ApplianceEventId	)
	END

END

--=================Create the new reservation============================


--Set the right UDE time
SET @UDEStartTime = GETDATE()
SET @UDEStartTime = DATEADD(ms,-1*DATEPART(ms,@UDEStartTime),@UDEStartTime)
SET @UDEId = (	SELECT ude_id 
				FROM dbo.User_Defined_Events WITH(NOLOCK)
				WHERE pu_id = @LocationPuId
					AND event_subtype_id = @EST_Reservation
					AND start_time = @UDEStartTime)
--Loop til free timedtamp
WHILE @UDEId IS NOT NULL
BEGIN
	SET @UDEStartTime = DATEADD(ss,1,@UDEStartTime)

	SET @UDEId = (	SELECT ude_id 
				FROM dbo.User_Defined_Events WITH(NOLOCK)
				WHERE pu_id = @LocationPuId
					AND event_subtype_id = @EST_Reservation
					AND start_time = @UDEStartTime)
END

IF @DebugFlag >=2
BEGIN
INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
VALUES(	GETDATE(),
		@SPName,
		300,
		'Timestamp of the new Reservation: ' + CONVERT(varchar(30), @UDEStartTime, 120),
		@ApplianceEventId	)
END

--Create the UDE
EXEC [dbo].[spServer_DBMgrUpdUserEvent]
	0, 
	'CTS Reservation', 
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
	@EST_Reservation,		--event_subTypeId
	@LocationPuId,			--pu_id
	'Reserved',				--UDE desc
	@UDEId OUTPUT,			--UDE_ID
	@UserId,				--User_Id
	NULL,					--Acked On
	@UDEStartTime,			--@UDE Starttime, 
	@UDEStartTime,			--@UDE endtime, 
	NULL,					--Research CommentId
	NULL,					--Research Status id
	NULL,					--Research User id
	NULL,					--Research Open Date
	NULL,					--Research Close date
	1,						--Transaction type
	NULL,					--Comment Id
	NULL,					--reason tree
	NULL,					--signature Id
	@ApplianceEventId,		--eventId
	NULL,					--parent ude id
	NULL,					--event status
	1,						--Testing status
	NULL,					--conformance
	NULL,					--test percent complete
	0		

IF @DebugFlag >=2
BEGIN
INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
VALUES(	GETDATE(),
		@SPName,
		310,
		'New reservation id (UDE id): ' + CONVERT(varchar(30), @UDEId),
		@ApplianceEventId	)
END

--Get the target vaids
INSERT @VarToUpdate (varid, Val)
SELECT var_id, @ReservationType  FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @LocationPuId 	AND event_subtype_id = @EST_Reservation	AND Test_Name = 'Type'

INSERT @VarToUpdate (varid, Val)
SELECT var_id, 'Active' FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @LocationPuId 	AND event_subtype_id = @EST_Reservation	AND Test_Name = 'Status'

INSERT @VarToUpdate (varid, Val)
SELECT var_id, CONVERT(varchar(25),@ApplianceEventId) 
FROM dbo.variables_base WITH(NOLOCK) 
WHERE pu_id = @LocationPuId 	AND event_subtype_id = @EST_Reservation	AND Test_Name = 'Event Id'

INSERT @VarToUpdate (varid, Val)	
SELECT var_id, CONVERT(varchar(25),@ReservationPPId)
FROM dbo.variables_base WITH(NOLOCK) 
WHERE pu_id = @LocationPuId 	AND event_subtype_id = @EST_Reservation	AND Test_Name = 'Process order Id'

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
		@UDEStartTime,				--result_on
		NULL,						--Transnum
		NULL,						--Comment_id
		NULL,						--ArrayId
		@UDEId,						--event_id
		@LocationPuId	,			--Pu_id
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
		330,
		'All done creating the new reservation: ' + CONVERT(varchar(30), @UDEId),
		@ApplianceEventId	)
END



LaFin:


IF @DebugFlag >=2
BEGIN
	INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
	VALUES(	GETDATE(),
			@SPName,
			999,
			'SP Ended:'  ,
			@ApplianceEventId	)
END


SET NOCOUNT OFF

RETURN
