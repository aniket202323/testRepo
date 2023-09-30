
-----------------------------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Calc_ActivityComplete_QIC
-----------------------------------------------------------------------------------------------------------------------
-- Author				: Steven Stier (Stier Automation)
-- Date created			: 02/14/2013
-- Version 				: 0.1
-- SP Type				: Calculation Stored Procedure
-- Caller				: Calculation
-- Description			: This stored procedure provides the validation for the completion of activity for QIC
--=====================================================================================================================
-- Edit History:
-------------------------------------------------------------------------------------------------
--Revision	Date			Who						What
--========	===========		=====================	==============================================
-- 0.1		02/14/2023		Steven Stier			Creation of the Stored Procedure 
-- 

--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_Calc_ActivityComplete_QIC]
-- --------------------------------------------------------------------------------------------------------------------
-- Input Parameters
--=====================================================================================================================
--DECLARE	
		@strOutput			NVARCHAR(25) OUTPUT		,
		@ActivityCompleteVarID          INT	,   -- Activity Complete Var Id
		@dtmResultOn		DATETIME		    -- Result On timestamp of Event
		
-----------------------------------------------------------------------------------------------------------------------
-- Test Statements
--SELECT
--	@ActivityCompleteVarID			= 9000
--	@dtmResultOn		= '2015-03-16 17:24:11.000'
-----------------------------------------------------------------------------------------------------------------------	
--WITH ENCRYPTION
AS

---------------------------------------------------------------------------------------------------
DECLARE
		
		@PUId 					int	,
		@RSUserId 				int	,
		@SheetId 				int	,
		@NumVariablesWithData int
--=================================================================================================

---------------------------------------------------------------------------------------------------
-- Initializes the variables
---------------------------------------------------------------------------------------------------
SET @NumVariablesWithData = 0


---------------------------------------------------------------------------------------------------
-- Set Resultset User 
---------------------------------------------------------------------------------------------------

SET @RSUserId = (SELECT [User_id] FROM dbo.Users_base WITH(NOLOCK) WHERE UserName = 'QualitySystem')

---------------------------------------------------------------------------------------------------
-- Get the sheet id 
---------------------------------------------------------------------------------------------------

SELECT @SheetId = sv.Sheet_Id FROM dbo.Sheet_Variables sv WITH(NOLOCK) JOIN dbo.sheets s WITH (NOLOCK) ON sv.sheet_id = s.sheet_id WHERE Var_Id = @ActivityCompleteVarID AND s.is_active = 1 AND sheet_type <> 11

---------------------------------------------------------------------------------------------------
--Get pu id
---------------------------------------------------------------------------------------------------

SELECT @PUId = PU_Id FROM dbo.Variables_base WITH(NOLOCK) WHERE Var_Id = @ActivityCompleteVarID

---------------------------------------------------------------------------------------------------
--Count the number of values entered for event
---------------------------------------------------------------------------------------------------

SELECT @NumVariablesWithData = count(*)
FROM dbo.Tests WITH(NOLOCK)
WHERE Result IS NOT NULL 
	AND Result_On = @dtmResultOn 
	AND Var_Id IN (	SELECT sv.Var_Id 
					FROM dbo.Sheet_Variables sv WITH(NOLOCK) 
					JOIN variables_base vb WITH (NOLOCK) ON sv.var_id = vb.var_id AND vb.data_type_id <> 4
					AND 	(vb.extended_info NOT LIKE '%/NOCHECK/%' OR vb.extended_info IS NULL)
					WHERE Sheet_Id = @SheetId 
						AND sv.Var_Id <> @ActivityCompleteVarID)


IF @NumVariablesWithData > 0
BEGIN
	SET @strOutput = 'Num Values Entered =' + CAST (@NumVariablesWithData as varchar(20))
	SELECT 
			2, -- Resultset Number 
			@ActivityCompleteVarID, -- Var_Id 
			@PUId, -- PU_Id 
			@RSUserId, -- User_Id 
			0, -- Canceled 
			1, -- Result 
			CONVERT(VARCHAR(30),@dtmResultOn,120), -- TimeStamp 
			2, -- TransactionType (1=Add 2=Update 3=Delete) 
			0, -- UpdateType (0=PreUpdate 1=PostUpdate)  
			NULL, -- SecondUserId 
			NULL, -- TransNum 
			NULL, -- EventId 
			NULL, -- ArrayId 
			NULL, -- CommentId
			-- Added P7 --
			NULL,													-- ESigId
			NULL,													-- EntryOn
			NULL,													-- TestId
			NULL,													-- ShouldArchive
			NULL,													-- HasHistory
			NULL												    -- IsLocked
	RETURN
END

SET @strOutput = 'No Values Entered'
RETURN 



SET NOCOUNT OFF
