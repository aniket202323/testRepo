
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[splocal_RE_603_CreateWaste]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	TCS LEDS Product Team
Date			:	2013-11-18
Version		:	1.1.1
Purpose		: 	FO-01683 Removed ProficyPurge account as per compatiblity with Proficy Version 5. (This account is not needed for V5)
---------------------------------------------------------------------------------------------------------------------------------------
Modified By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-16
Version		:	1.1.0
Purpose		: 	Added Reason IDs to Resultset.
---------------------------------------------------------------------------------------------------------------------------------------
Created By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-09-09
Version		:	1.0.0
Purpose		: 	Create a waste from model 603
					Two tags are used :	- Amount Tag (Amount of wasted material)
												- Fault Tag (Fault Code, if any)
---------------------------------------------------------------------------------------------------------------------------------------
*/

@ReturnStatus 			int OUTPUT,
@ReturnMessage 		varchar(255) OUTPUT,
@JumptoTime 			varchar(30) OUTPUT,
@EC_Id 					int,
@Reserved1 				varchar(30),
@Reserved2 				varchar(30),
@Reserved3 				varchar(30),
---------------------------------------------------------------------------------------------------------------------------------------
-- Tag that triggered the Event
@TriggerTagNum 		varchar(10),
@TriggerPrevValue 	varchar(30),  
@TriggerNewValue 		varchar(30),
@TriggerPrevTime 		varchar(30),
@TriggerNewTime 		varchar(30),
---------------------------------------------------------------------------------------------------------------------------------------
-- 1st Tag in the list from the model configuration property
-- AmountTag (Tag used to hold the amount of wasted material)
@AmountPrevValue 		varchar(30),
@AmountNewValue 		varchar(30),
@AmountPrevTime 		varchar(30),
@AmountNewTime 		varchar(30),
---------------------------------------------------------------------------------------------------------------------------------------
-- 2nd Tag in the list from the model configuration property
-- FaultTag (Tag used to hold the Fault Code)
@FaultPrevValue 		varchar(30),
@FaultNewValue 		varchar(30),
@FaultPrevTime 		varchar(30),
@FaultNewTime 			varchar(30)
---------------------------------------------------------------------------------------------------------------------------------------

AS
SET NOCOUNT ON

Declare
@Float_Value		float,
@Pu_id				int,
@SourcePu_id		int,
@wed_id				int,
@User_id				int,
@TransType			int,
@UpdateType			int,
@TransNum			int,
@Exit					int,
@TrimFault			varchar(30),
@PosDot				int,
@Fault_Id			int,
@Reason1_Id			int,
@Reason2_Id			int,
@Reason3_Id			int,
@Reason4_Id			int,
@AppVersion			varchar(30)		-- Used to retrieve the Proficy database Version

SET @ReturnStatus = 0 	-- Indicate there is an error
SET @Exit = 0				-- Execute the SP

-- Execute the SP only if the model 603 was fired by the AmountTag
IF (@TriggerTagNum <> '1')
	BEGIN
		SET @Exit = 1
	END
	
-- Do not execute if the AmountTag is empty or 0 (No waste)
IF (@AmountNewValue IS NULL) OR (@AmountNewValue = '') OR (convert(int,convert(float,@AmountNewValue)) = 0)
	BEGIN
		SET @Exit = 1
	END

-- Execute the SP only if the value of the AmountTag is different from previous AmountTag
-- If it is the same, the time has to be different
IF @AmountNewValue = @AmountPrevValue
	IF @AmountNewTime = @AmountPrevTime
		BEGIN
			SET @Exit = 1
		END
		
-- Exit if one of the conditions is not met
IF @Exit = 1
	BEGIN
		SET @ReturnStatus = 1 -- OK
		SET NOCOUNT OFF
		RETURN
	END

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

-- Set Resultset Parameters
SELECT @User_id = user_id FROM dbo.Users WHERE Username like 'ReliabilitySystem'

-- Convert amount received as parameter to a float
SET @Float_Value = convert(FLOAT,@AmountNewValue)

-- Get the PU_Id of the waste event
SET @Pu_id = (SELECT PU_Id FROM dbo.Event_Configuration WHERE EC_Id = @EC_Id)

-- Remove dot and decimal 0s from the FaultCode if there is any
SET @PosDot = charindex('.',@FaultNewValue)
IF @PosDot > 0
	BEGIN
		SET @TrimFault = left(@FaultNewValue,@PosDot - 1)
	END
ELSE
	BEGIN
		SET @TrimFault = @FaultNewValue
	END

-- Get the Source_PU_Id (Location), Fault_Id and Reason IDs
SELECT	@SourcePu_Id = Source_PU_Id,
			@Fault_Id = WEFault_Id,
			@Reason1_Id = Reason_Level1,
			@Reason2_Id = Reason_Level2,
			@Reason3_Id = Reason_Level3,
			@Reason4_Id = Reason_Level4
FROM		dbo.Waste_Event_Fault
WHERE		(PU_Id = @Pu_id) AND (WEFault_Value = @TrimFault)

IF @SourcePu_id IS NULL
	BEGIN
		SET @SourcePu_id = @Pu_id
	END

-- Check if a waste already exists on this unit at the same time
SELECT @wed_id = NULL
SET @wed_id = (SELECT wed_id FROM dbo.waste_event_details WHERE PU_Id = @pu_id and TimeStamp = @TriggerNewTime)

IF @wed_id IS NULL	-- New waste
	BEGIN
		SET @TransType = 1	-- Add
	END
ELSE						-- Modify an existing waste
	BEGIN
		SET @TransType = 2	-- Update
	END

SET @UpdateType = 1 	-- PostUpdate
SET @TransNum = 0 	-- Update all values

------------------------------------ Waste Resultset ------------------------------------------
IF  @AppVersion LIKE '4%'
	BEGIN
		---------------------------------------[ P4 Code ]---------------------------------------
		SELECT 9,											-- Result Set Type (9)
		@UpdateType,										-- Update Type (0=Pre 1=Post)
		@TransNum,											-- TransNum (0=New 2=All)
		@user_id,											-- UserId
		@TransType,											-- TransType (1=Add 2=Update)
		@wed_id,												-- WasteEventId
		@pu_id,												-- PUId
		@SourcePu_id,										-- SourcePUId
		NULL,													-- TypeId
		NULL,													-- MeasureId
		@Reason1_Id,										-- Reason1
		@Reason2_Id,										-- Reason2
		@Reason3_Id,										-- Reason3
		@Reason4_Id,										-- Reason4
		NULL,													-- EventId
		@Float_Value,										-- Amount
		NULL,													-- Marker1
		NULL,													-- Marker2
		convert(Varchar(30),@AmountNewTime,120),	-- TimeStamp
		NULL,													-- Action1
		NULL,													-- Action2
		NULL,													-- Action3
		NULL,													-- Action4
		NULL,													-- ActionCommentId
		NULL,													-- ResearchCommentId
		NULL,													-- ResearchStatusId
		NULL,													-- ResearchOpenDate
		NULL,													-- ResearchCloseDate
		NULL,													-- CommentId
		NULL,													-- TargetProdRate
		NULL,													-- ResearchUserId
		-- P4 Only --
		@Fault_Id,											-- FaultId
		NULL													-- RsnTreeDataId
	END
ELSE
	BEGIN
		---------------------------------------[ P3 Code ]---------------------------------------
		SELECT 9,											-- Result Set Type (9)
		@UpdateType,										-- Update Type (0=Pre 1=Post)
		@TransNum,											-- TransNum (0=New 2=All)
		@user_id,											-- UserId
		@TransType,											-- TransType (1=Add 2=Update)
		@wed_id,												-- WasteEventId
		@pu_id,												-- PUId
		@SourcePu_id,										-- SourcePUId
		NULL,													-- TypeId
		NULL,													-- MeasureId
		@Reason1_Id,										-- Reason1
		@Reason2_Id,										-- Reason2
		@Reason3_Id,										-- Reason3
		@Reason4_Id,										-- Reason4
		NULL,													-- EventId
		@Float_Value,										-- Amount
		NULL,													-- Marker1
		NULL,													-- Marker2
		convert(Varchar(30),@AmountNewTime,120),	-- TimeStamp
		NULL,													-- Action1
		NULL,													-- Action2
		NULL,													-- Action3
		NULL,													-- Action4
		NULL,													-- ActionCommentId
		NULL,													-- ResearchCommentId
		NULL,													-- ResearchStatusId
		NULL,													-- ResearchOpenDate
		NULL,													-- ResearchCloseDate
		NULL,													-- CommentId
		NULL,													-- TargetProdRate
		NULL													-- ResearchUserId
	END

SET @ReturnStatus = 1	-- Success

SET NOCOUNT OFF


