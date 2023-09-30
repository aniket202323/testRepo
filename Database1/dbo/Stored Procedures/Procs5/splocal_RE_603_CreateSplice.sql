
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[splocal_RE_603_CreateSplice]
/*
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Created By	:	Mike Thomas (P&G)
Date			:	2009-06-04
Version		:	1.0.0
Purpose		: 	Create a waste from model 603
					Two tags are used :	- Splice Status (one (success) or zero (failed) splice)
										- Fault Tag (used for splice location): Trigger
---------------------------------------------------------------------------------------------------------------------------------------
*/

@ReturnStatus 			int OUTPUT,
@ReturnMessage 			varchar(255) OUTPUT,
@JumptoTime 			varchar(30) OUTPUT,
@EC_Id 					int,
@Reserved1 				varchar(30),
@Reserved2 				varchar(30),
@Reserved3 				varchar(30),
---------------------------------------------------------------------------------------------------------------------------------------
-- Tag that triggered the Event
@TriggerTagNum 			varchar(10),
@TriggerPrevValue 		varchar(30),  
@TriggerNewValue 		varchar(30),
@TriggerPrevTime 		varchar(30),
@TriggerNewTime 		varchar(30),
---------------------------------------------------------------------------------------------------------------------------------------
-- 1st Tag in the list from the model configuration property
-- Splice Status Tag (one (success) or zero (failed) splice)
@AmountPrevValue 		varchar(30),
@AmountNewValue 		varchar(30),
@AmountPrevTime 		varchar(30),
@AmountNewTime 			varchar(30),
---------------------------------------------------------------------------------------------------------------------------------------
-- 2nd Tag in the list from the model configuration property
-- FaultTag (Used for splice location)
@FaultPrevValue 		varchar(30),
@FaultNewValue 			varchar(30),
@FaultPrevTime 			varchar(30),
@FaultNewTime 			varchar(30)
---------------------------------------------------------------------------------------------------------------------------------------

AS
SET NOCOUNT ON

Declare
@Pu_id				int,
@SourcePu_id		int,
@wed_id				int,
@User_id			int,
@TransType			int,
@UpdateType			int,
@TransNum			int,
@Exit				int,
@TrimFault			varchar(30),
@PosDot				int,
@Fault_Id			int,
@Reason1_Id			int,
@Reason2_Id			int,
@Reason3_Id			int,
@Reason4_Id			int

SET @ReturnStatus = 0 	-- Indicate there is an error
SET @Exit = 0				-- Execute the SP

-- Execute the SP only if the model 603 was fired by the FaultTag
IF (@TriggerTagNum <> '2')
	BEGIN
		SET @Exit = 1
	END
	
-- Do not execute if the FaultTag is empty or 0 (No waste)
IF (@FaultNewValue IS NULL) OR (@FaultNewValue = '') OR (convert(int,convert(float,@FaultNewValue)) = 0)
	BEGIN
		SET @Exit = 1
	END

-- Execute the SP only if the value of the FaultTag is different from previous FaultTag
-- If it is the same, the time has to be different
IF @FaultNewValue = @FaultPrevValue
	IF @FaultNewTime = @FaultPrevTime
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

-- Set Resultset Parameters
SELECT @User_id = user_id FROM dbo.Users WHERE Username like 'ReliabilitySystem'

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

SELECT 9,											-- Result Set Type (9)
@UpdateType,										-- Update Type (0=Pre 1=Post)
@TransNum,											-- TransNum (0=New 2=All)
@user_id,											-- UserId
@TransType,											-- TransType (1=Add 2=Update)
@wed_id,											-- WasteEventId
@pu_id,												-- PUId
@SourcePu_id,										-- SourcePUId
NULL,												-- TypeId
NULL,												-- MeasureId
@Reason1_Id,										-- Reason1
@Reason2_Id,										-- Reason2
@Reason3_Id,										-- Reason3
@Reason4_Id,										-- Reason4
NULL,												-- EventId
@AmountNewValue,									-- Amount
NULL,												-- Marker1
NULL,												-- Marker2
convert(Varchar(30),@FaultNewTime,120),			-- TimeStamp
NULL,												-- Action1
NULL,												-- Action2
NULL,												-- Action3
NULL,												-- Action4
NULL,												-- ActionCommentId
NULL,												-- ResearchCommentId
NULL,												-- ResearchStatusId
NULL,												-- ResearchOpenDate
NULL,												-- ResearchCloseDate
NULL,												-- CommentId
NULL,												-- TargetProdRate
NULL,												-- ResearchUserId
@Fault_Id,											-- FaultId
NULL												-- RsnTreeDataId

SET @ReturnStatus = 1	-- Success

SET NOCOUNT OFF


