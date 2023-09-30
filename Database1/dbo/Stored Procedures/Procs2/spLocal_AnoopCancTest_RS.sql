

CREATE PROCEDURE [dbo].[spLocal_AnoopCancTest_RS]
-- --------------------------------------------------------------------------------------------------------------------
-- Input Parameters
--=====================================================================================================================
--DECLARE	
		@strOutput			NVARCHAR(20) OUTPUT		,
		@intVarId           INT						,		-- Test Complete Id
		@dtmResultOn		DATETIME						-- Test date
		
-----------------------------------------------------------------------------------------------------------------------
-- Test Statements
--SELECT
--	@intVarId			= 8291
--	@dtmResultOn		= '2015-03-16 17:24:11.000'
-----------------------------------------------------------------------------------------------------------------------	
--WITH ENCRYPTION
AS

---------------------------------------------------------------------------------------------------
DECLARE
		@SheetId 				INT				,
		@ResultOut 				INT	,
		@ResultOutL				INT		,
		@PUId 					INT				,
		@RSUserId 				INT			
		
Declare  @ResultSetVariables TABLE(
			VarId INT, 
			PUId INT, 
			DataType INT,
		Canceled	INT,
		Result		NVARCHAR(25),
		ResultOn	DATETIME,
		EntryOn		DATETIME,
		TransType 	INT DEFAULT 1,
		Post		INT DEFAULT 0)
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

SELECT @SheetId = sv.Sheet_Id FROM dbo.Sheet_Variables sv WITH(NOLOCK) JOIN dbo.sheets s WITH (NOLOCK) ON sv.sheet_id = s.sheet_id WHERE Var_Id = @intVarId AND s.is_active = 1 AND sheet_type <> 11

---------------------------------------------------------------------------------------------------
--Get pu id
---------------------------------------------------------------------------------------------------

SELECT @PUId = PU_Id FROM dbo.Variables_base WITH(NOLOCK) WHERE Var_Id = @intVarId

---------------------------------------------------------------------------------------------------
--Get all the null fields with the ids in the sheet and the Result_On & elminates variables which don't have to be considered for 
---------------------------------------------------------------------------------------------------
INSERT INTO @ResultSetVariables (
			VarId, 
			PUId, 
			DataType
					)
	SELECT	v.Var_Id, 
			v.PU_Id, 
			v.Data_Type_Id

	FROM dbo.Variables_Base v		WITH(NOLOCK)
	JOIN dbo.Sheet_Variables sv	WITH(NOLOCK)
								ON sv.Var_Id = v.Var_Id
	JOIN dbo.Sheets s			WITH(NOLOCK)
								ON s.sheet_id = sv.sheet_id
	WHERE	s.Sheet_id = @sheetId
	and v.data_type_id <> 4
	ORDER BY sv.Var_Order

---------------------------------------------------------------------------------------------------
--  Output
---------------------------------------------------------------------------------------------------

UPDATE @ResultSetVariables
	SET	Result	 = null, 
		ResultOn = @dtmResultOn, 
		EntryOn	 = getdate(),
		canceled = 1
	FROM @ResultSetVariables r
	LEFT JOIN dbo.Tests t	WITH(NOLOCK)
							ON t.Var_Id = r.VarId 
	WHERE t.Result_On = @dtmResultOn
	and t.result is not null


	SELECT
		2,							-- Resultset Number
		VarId,						-- Var_Id
		PUId,						-- PU_Id
		@RSUserId,				-- User_Id
		Canceled,					-- Canceled
		Result,						-- Result
		ResultOn,					-- TimeStamp
		TransType,					-- TransactionType (1=Add 2=Update 3=Delete)
		Post,						-- UpdateType (0=PreUpdate 1=PostUpdate)
		-- Added P4 --
		NULL,						-- SecondUserId
		NULL,						-- TransNum
		NULL,						-- EventId
		NULL,						-- ArrayId
		NULL						-- CommentId
	FROM @ResultSetVariables
	
SET @strOutput = 'Done'
RETURN 

SET NOCOUNT OFF
