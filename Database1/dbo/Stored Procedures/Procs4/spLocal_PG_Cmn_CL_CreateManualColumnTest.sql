
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CL_CreateManualColumnTest]
/*
--------------------------------------------------------------------------------------------------------
Stored procedure	 :	spLocal_PG_Cmn_CL_CreateManualColumnTest
Author				 :	Alexandre Turgeon, STI
Date created		 :	18-Apr-2006
SP Type				 :	Creates user-defined events
Called by			 :	Called by other SPs by model 602, product change or manual event
Editor tab spacing :	3
Description			 :	
--------------------------------------------------------------------------------------------------------
Revision 		Date				Who							What
========		===========		==================		=================================================================================
1.0				18-Apr-2006		Alexandre Turgeon			Creation of SP
1.1				05-Jan-2009		Normand Carbonneau		Added WITH (NOLOCK) and reformatted
1.3				04-May-2015		Nilesh Panpaliya		Updated condition to get STLS Unit ID to check for IS NULL instead of= 0.
1.4				07-May-2015		Nilesh Panpaliya		Correct SQL Syntax for @STLSID
1.5             22-Jul-2016     Megha Lohana(TCS)       Remove the register SP and update AppVersions section
1.6             3-Oct-2016      Megha Lohana            FO-02657 Update Centerline SPs to look for correct Eventfield Property Desc Column Offset
1.7				18-Mar-2021		Cristian Jianu			Fix Product Change
---------------------------------------------------------------------------------------------------------------------------------------------
2.0				28-Mar-2018		Fernando Rio			Do not check for Active PO on RTT Manuals.
2.1				29-Mar-2021		Santiago Gimenez		Send UDEEndTime instead of Timestamp.
---------------------------------------------------------------------------------------------------------------------------------------------
3.1				24-Jun-2021		Cristian Jianu			Version Control for Centerline 3.1
3.1.1			2021-11-19		Camila Olguin			Changes to test PC in pilot sites
3.1.2			2021-11-26		Camila Olguin			Add TRY and CATCH logic
3.1.3			2022-04-21		Steven Stier			sent 1 in Result set for Hot insert for dbo.spServer_DBMgrUpdUserEvent 
---------------------------------------------------------------------------------------------------------------------------------------------
*/

@CallerId				varchar(30),
@PUId						int,
@EventSubType			int,
@Timestamp				datetime

--WITH ENCRYPTION 
AS
SET NOCOUNT ON

BEGIN TRY 



DECLARE
@RSUserId					int,
@CurrentTime				datetime,
@LastUDETime				datetime,
@CSId							int,
@CsStartTime				datetime,
@CsEndTime					datetime,
@UDENum						varchar(1000),
@UDEStartTime				datetime,
@UDEEndTime					datetime,
@UDEStartTimeString		varchar(25),
@EventSubtypeDesc			varchar(50),
@UDEId						int,
@Section					VARCHAR(20),
@ErrorMessage				nvarchar(4000)


SET @CurrentTime = getdate()

SET @Section = 'CreateManualColumn'


--Get last event time
SET @LastUDETime =
	(
	SELECT	max(End_Time)
	FROM		dbo.User_Defined_Events WITH (NOLOCK)
	WHERE		(Event_Subtype_Id = @EventSubType)
	AND		(PU_Id = @PUId)
	AND		(End_Time < @Timestamp)
	AND		(End_Time IS NOT NULL)
	)

IF @LastUDETime IS NULL
	BEGIN
		SET @LastUDETime  = '2000-01-01 00:00:00.000'
	END

IF @CallerId != 'Manual'
	BEGIN
		--Verify if there is a new shift since last column
		SELECT TOP 1	@CSId = CS_Id,
							@CsStartTime = Start_Time,
							@CsEndTime = End_Time
		FROM				dbo.Crew_Schedule cs		WITH (NOLOCK)
		JOIN			dbo.Prod_Units_Base converter	WITH (NOLOCK)	ON converter.PU_Id = cs.PU_Id
		JOIN			dbo.Prod_Units_Base RTT			WITH (NOLOCK)	ON RTT.Pl_Id = converter.Pl_Id 
		WHERE			(RTT.PU_Id = @PUId)
		AND			(cs.Start_Time <= @Timestamp)
		AND         ( @Timestamp <= @CurrentTime) --FO-02657 Condition included to stub column when the shift change plus offset is less than or equal to current time
		ORDER BY		cs.Start_Time DESC

		IF @CSId IS NULL
			BEGIN
				SET NOCOUNT OFF
				RETURN
			END

		SET @UDENum = convert(varchar(30), @Timestamp, 20) + '-Shift'
END

	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------

-- create user-defined event number
IF @CallerId = 'Manual'
	BEGIN
		SET @UDENum = convert(varchar(30), @Timestamp, 20) + '-manual'
	END
ELSE IF @CallerId = 'Product Change'
	BEGIN
		SET @UDENum = convert(varchar(30), @Timestamp, 20) + '-product'
	END

--insert into sti_test (sp, param, value) values ('CreateManualColumn', '@UDENum', @UDENum)
-- Set Resultset User
SET @RSUserId = (SELECT [User_Id] FROM dbo.Users WITH (NOLOCK) WHERE UserName = 'RTTSystem')
SET @RSUserId = ISNULL(@RSUserId, 6)

SET @UdeStartTime = @Timestamp
SET @UDEEndTime = dateadd(ss, 1, @UDEStartTime)
SET @UDEStartTimeString = convert(varchar(25), @UDEStartTime, 120)

SET @EventSubtypeDesc = (SELECT Event_Subtype_Desc FROM dbo.Event_Subtypes (NOLOCK) WHERE Event_Subtype_Id = @EventSubType)
set @Section = 'spServer_DBMgrUpdUserEvent'
EXEC dbo.spServer_DBMgrUpdUserEvent 
				0,										-- *Transaction Number  0=Update fields that are not null 2=Update all fields
				@EventSubtypeDesc,				-- *Event Subtype Desc
				NULL,									-- Action Comment Id
				NULL,									-- Action 4
				NULL,									-- Action 3
				NULL,									-- Action 2
				NULL,									-- Action 1
				NULL,									-- Cause Comment Id
				NULL,									-- Cause 4
				NULL,									-- Cause 3
				NULL,									-- Cause 2
				NULL,									-- Cause 1
				@RSUserId,							-- Ack By
				1,										-- *Ack
				NULL,									-- Duration
				@EventSubType,						-- *Event Subtype Id
				@PUId,								-- *Pu Id
				@UDENum,								-- *Ude Desc
				@UDEId OUTPUT,						-- *Ude Id
				@RSUserId,							-- *User Id
				@CurrentTime,						-- Ack On
				@UDEStartTimeString,				-- *Start Time
				@UDEEndTime,							-- *End Time
				NULL,									-- Research Comment Id
				NULL,									-- Research Status Id
				NULL,									-- Research User Id
				NULL,									-- Research Open Date
				NULL,									-- Research Close Date
				1,										-- *Transtype
				NULL,									-- UDE Comment Id
				NULL,									-- Event Reason Tree Data Id
				NULL,								--SignatureId
				NULL,								--EventId
				NULL,								--ParentUDEId
				NULL,								--Event_Status
				NULL,								--TestingStatus
				NULL,								--Conformance
				NULL,								--TestPctComplete
				1								--ReturnResultSet
-- Create the event on the unit for the path
SELECT	8,							-- UDE Resultset
			0,							-- Pre=1 Post=0
			@UDEId,					-- User Defined Event Id
			@UDENum,					-- User_Defined_Events Desc
			@PUId,					-- Unit Id
			@EventSubType,			-- Event Subtype Id
			@UDEStartTimeString,	-- Start Time
			@UDEEndTime,				-- End Time
			NULL,						-- Duration
			1,							-- Acknowledged
			@CurrentTime,			-- Ack Timestamp
			@RSUserId,				-- Acknowledged By
			NULL,						-- Cause 1
			NULL,						-- Cause 2
			NULL,						-- Cause 3
			NULL,						-- Cause 4
			NULL,						-- Cause Comment Id
			NULL,						-- Action 1
			NULL,						-- Action 2
			NULL,						-- Action 3
			NULL,						-- Action 4
			NULL,						-- Action Comment Id
			NULL,						-- Research User Id
			NULL,						-- Research Status Id
			NULL,						-- Research Open Date
			NULL,						-- Research Close Date
			NULL,						-- Research Comment Id
			NULL,						-- Comments (Comment_Id)
			1,							-- Transaction Type  1=Add 2=Update 3=Delete
			@EventSubtypeDesc,	-- Event Sub Type Desc
			2,							-- Transaction Number  0=Update fields that are not null 2=Update all fields
			@RSUserId,				-- User Id
			NULL,					-- ESigId
			NULL,						-- ProductionEventId
			NULL,						-- ParentUDEId
			NULL,						-- EventStatus
			NULL,						-- TestingStatus
			NULL						-- TestPctComplete


-- initialize variables
EXEC spLocal_PG_Cmn_CL_SetVariableReadyTest @CallerId, @PUId, @EventSubType, @UDEEndTime

END TRY
BEGIN CATCH
	SELECT @ErrorMessage = ERROR_MESSAGE()
	RAISERROR (@ErrorMessage,16,1)
END CATCH

SET NOCOUNT OFF

