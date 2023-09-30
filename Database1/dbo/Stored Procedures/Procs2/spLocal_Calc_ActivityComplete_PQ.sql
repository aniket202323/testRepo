


-----------------------------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Calc_ActivityComplete_PQ
-----------------------------------------------------------------------------------------------------------------------
-- Author				: Steven Stier - Stier Automation
-- Date created			: 2021-08-17
-- Version 				: 1.0
-- SP Type				: Calculation Stored Procedure
-- Caller				: Calculation
-- Description			: This stored procedure provides the validation for the Activity Complete Variable
--                          using similar logic to  spLocal_CalcTestComplete_PQ
--	
-- Editor tab spacing	: 4 
-- --------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- --------------------------------------------------------------------------------------------------------------------
-- ========	====	  		====					=====
-- 1.0		2021-08-17		Steven Stier     		Initial Release - Proficy Mobility Rollout DEP-14919 CONF-23501
--=====================================================================================================================

CREATE PROCEDURE [dbo].[spLocal_Calc_ActivityComplete_PQ]
-- --------------------------------------------------------------------------------------------------------------------
-- Input Parameters
--=====================================================================================================================
--DECLARE	
		@strOutput			NVARCHAR(20) OUTPUT		,
		@intTestCompleteVarId           INT						,		-- Test Complete Var Id
		@intActivityCompleteVarId           INT						,		-- Activity Complete Var Id
		@dtmResultOn		DATETIME						-- Test date
		
-----------------------------------------------------------------------------------------------------------------------
-- Test Statements
--SELECT
--	@intTestCompleteVarId			= 19417,
--  @intActivityCompleteVarId = 244778,
--	@dtmResultOn		= '2021-08-19 10:08:13.000'
-----------------------------------------------------------------------------------------------------------------------	
--WITH ENCRYPTION
AS

---------------------------------------------------------------------------------------------------
DECLARE
		@SheetId 				INT ,
		@ResultOut 				INT	,
		@ResultOutL				INT	,
		@PUId 					INT	,
		@RSUserId 				INT,	
		@TestCompeteResult	    INT
--=================================================================================================
---------------------------------------------------------------------------------------------------
-- Initializes the variable
---------------------------------------------------------------------------------------------------
SET @ResultOut = 0
SET @ResultOutL = 0

---------------------------------------------------------------------------------------------------
-- Set Resultset User 
---------------------------------------------------------------------------------------------------

SET @RSUserId = (SELECT [User_id] FROM dbo.Users_base WITH(NOLOCK) WHERE UserName = 'QualitySystem')

---------------------------------------------------------------------------------------------------
-- Get the sheet id 
---------------------------------------------------------------------------------------------------

SELECT @SheetId = sv.Sheet_Id FROM dbo.Sheet_Variables sv WITH(NOLOCK) JOIN dbo.sheets s WITH (NOLOCK) ON sv.sheet_id = s.sheet_id WHERE Var_Id = @intTestCompleteVarId AND s.is_active = 1 AND sheet_type <> 11

---------------------------------------------------------------------------------------------------
--Get pu id
---------------------------------------------------------------------------------------------------

SELECT @PUId = PU_Id FROM dbo.Variables_base WITH(NOLOCK) WHERE Var_Id = @intTestCompleteVarId

---------------------------------------------------------------------------------------------------
--Get the value of the test complete variable
---------------------------------------------------------------------------------------------------

SELECT @TestCompeteResult = Result
FROM dbo.Tests WITH(NOLOCK)
WHERE  Result_On = @dtmResultOn 
	  AND Var_Id  =  @intTestCompleteVarId

---------------------------------------------------------------------------------------------------
--Get all the null fields with the ids in the sheet and the Result_On & elminates variables which don't have to be considered for 
---------------------------------------------------------------------------------------------------
SELECT @ResultOut = count(*)
FROM dbo.Tests WITH(NOLOCK)
WHERE Result IS NULL 
	AND Result_On = @dtmResultOn 
	AND Var_Id IN (	SELECT sv.Var_Id 
					FROM dbo.Sheet_Variables sv WITH(NOLOCK) 
					JOIN variables_base vb WITH (NOLOCK) ON sv.var_id = vb.var_id AND vb.data_type_id <> 4
					AND 	(vb.extended_info NOT LIKE '%/NOCHECK/%' OR vb.extended_info IS NULL)
					WHERE Sheet_Id = @SheetId 
						AND sv.Var_Id <> @intTestCompleteVarId)
					


-- Get all 0 fields & elminates variables which don't have to be considered for 						
SELECT @ResultOutL = count(*)
FROM dbo.Tests WITH(NOLOCK)
WHERE (Result = '0' OR RESULT IS NULL)
	AND Result_On = @dtmResultOn 
	AND Var_Id IN (	SELECT sv.Var_Id 
					FROM dbo.Sheet_Variables sv WITH(NOLOCK) 
					JOIN variables_base vb WITH (NOLOCK) ON sv.var_id = vb.var_id AND vb.data_type_id = 4
						AND 	(vb.extended_info NOT LIKE '%/NOCHECK/%' OR vb.extended_info IS NULL)
					WHERE Sheet_Id = @SheetId 
						AND sv.Var_Id <> @intTestCompleteVarId)


---------------------------------------------------------------------------------------------------
--  Output
---------------------------------------------------------------------------------------------------

IF( @TestCompeteResult IS NULL) OR  (@TestCompeteResult <> 1 )
BEGIN
SET @strOutput = 'Test Not Complete' 
SELECT 
			2, -- Resultset Number 
			@intActivityCompleteVarId, -- Var_Id 
			@puId, -- PU_Id 
			@RSUserId, -- User_Id 
			0, -- Canceled 
			NULL, -- Result 
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
			NULL
	RETURN
END


IF @ResultOut = 0 and @ResultOutL = 0
BEGIN
	SET @strOutput = 'Activity Complete' 
	SELECT 
			2, -- Resultset Number 
			@intActivityCompleteVarId, -- Var_Id 
			@puId, -- PU_Id 
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
			NULL
	RETURN
END

SET @strOutput = 'Missing Tests'
RETURN 

SET NOCOUNT OFF
