--==============================================================================================================================================
--  Name:       spLocal_TamuChecks
--  Type:       Stored Procedure
--  Editor Tab Spacing: 4 
--==============================================================================================================================================
--  DESCRIPTION: 
--  Stored Procedure will return details of any TAMU QA Tests on the line input between the date range input
--
--==============================================================================================================================================
--  EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--  Revision    Date    Who         What
--  ========    ====    ===         ====
--  1.0  		6/5/17 Marascalchi	Initial Development
--==============================================================================================================================================
--  CALLING EXAMPLE Statement:
------------------------------------------------------------------------------------------------------------------------------------------------
/*
EXEC  dbo.spLocal_TamuChecks
	@p_prodline				= 274				,
	@p_StartTime			= '2017-06-04'	,
	@p_EndTime				= '2017-06-06'
 
*/
--==============================================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_TamuChecks]
  @op_ErrorGUID			UNIQUEIDENTIFIER	= NULL  OUTPUT, 
  @op_ValidationCode    INT					= NULL  OUTPUT, --  <-1 : Expected Critical Errors
															--  -1  : Unexpected Critical Errors
															--  0 : Success
															--  >0  : Warning
  @op_ValidationMessage VARCHAR(MAX)		= NULL  OUTPUT, --  Validation Message
  @p_prodline			INT,
  @p_StartTime			DATETIME,
  @p_EndTime			DATETIME
AS
SET NOCOUNT ON
--==============================================================================================================================================
--  DECLARE VARIABLES
--  The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@TAMUDatatypeId	INT,
@LineDesc		VARCHAR(50)
--==============================================================================================================================================
--  DECLARE TABLE VARIABLES
--  The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@TAMUOutput	TABLE	
(
	ID				INT IDENTITY(1,1),
	Line			VARCHAR(100),
	EntryOn			DATETIME,
	Value			VARCHAR(50),
	VarId			INT,
	ParameterName	VARCHAR(200),
	CommentId		INT,
	Comment			VARCHAR(1000),
	ProdId			INT,
	BrandCode		VARCHAR(50),
	PO				VARCHAR(50),
	BrandSize		VARCHAR(200),
	UserId			INT,
	Operator		VARCHAR(50)
)

DECLARE
@ProcessUnits	TABLE
(
	ID		INT	IDENTITY(1,1),
	PUId	INT
)
--==============================================================================================================================================
--  DECLARE VARIABLE CONSTANTS
--  The following variables will be used as internal constants to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@TAMU_DATA_TYPE		VARCHAR(100)
--==============================================================================================================================================
--  INITIALIZE VARIABLES and VARIABLE CONSTANTS
--  Use this section to initialize variables and set valuse for any variable constants.
--==============================================================================================================================================
------------------------------------------------------------------------------------------------------------------------------------------------
--  Set constants used for business logic
------------------------------------------------------------------------------------------------------------------------------------------------
SET	@TAMU_DATA_TYPE	=	'TAMU-Attribute'
--==========================================================================================================================================
--  MAIN STORED PROCEDURE LOGIC
--==========================================================================================================================================
----------------------------------------------------------------------------------------------------------------------------------------
--  First obtain a line description to output
----------------------------------------------------------------------------------------------------------------------------------------
SET	@LineDesc	=	(
						SELECT	PL_Desc_Local
						FROM	Prod_Lines
						WHERE	PL_Id	=	@p_prodline
					)
					
----------------------------------------------------------------------------------------------------------------------------------------
--  Obtain the correct datatype ID in order to find TAMU-Attribute test results
----------------------------------------------------------------------------------------------------------------------------------------
SET	@TAMUDatatypeId	=	(
							SELECT	Data_Type_Id
							FROM	Data_Type
							WHERE	Data_Type_Desc = @TAMU_DATA_TYPE
						)

----------------------------------------------------------------------------------------------------------------------------------------
--  Obtain a list of process units on the inputted line so that the variables table can be filtered
----------------------------------------------------------------------------------------------------------------------------------------
INSERT	INTO	@ProcessUnits	(
									PUId
								)

SELECT	PU_Id
FROM	Prod_Units_Base
WHERE	PL_Id = @p_Prodline

----------------------------------------------------------------------------------------------------------------------------------------
--  Add the test type, value, and line to the output table
----------------------------------------------------------------------------------------------------------------------------------------
INSERT	INTO	@TAMUOutput	(	
								VarId,
								Line,
								EntryOn,
								Value,
								ParameterName,
								CommentId,
								UserId
							)

SELECT	t.Var_Id,
		@LineDesc,
		t.Entry_On,
		t.Result,
		v.Var_desc,
		t.Comment_Id,
		t.Entry_By
		
FROM	Tests t
JOIN	Variables v	
		ON	t.Var_Id = v.Var_Id
		AND	v.Data_Type_Id = @TAMUDatatypeId
WHERE	v.PU_Id IN	(	
						SELECT	PUId
						FROM	@ProcessUnits
					)
AND		t.Result_On	>= @p_StartTime
AND		t.Result_On <= @p_EndTime
AND		t.Result IS NOT NULL

----------------------------------------------------------------------------------------------------------------------------------------
--  Add the Test comment to the output table
----------------------------------------------------------------------------------------------------------------------------------------	
UPDATE	@TAMUOutput

SET	Comment =	c.Comment
FROM	Comments c
JOIN	@TAMUOutput tm
	ON	tm.CommentId = c.Comment_Id

----------------------------------------------------------------------------------------------------------------------------------------
--  Add the User (Operator) to the output table
----------------------------------------------------------------------------------------------------------------------------------------						
UPDATE	@TAMUOutput

SET	Operator = u.Username
FROM	Users u 
JOIN	@TAMUOutput tm
	ON	tm.UserId = u.[User_Id]				
			
----------------------------------------------------------------------------------------------------------------------------------------
--  Add the Process Order and Product Id to the output table
----------------------------------------------------------------------------------------------------------------------------------------	
UPDATE	@TAMUOutput
SET	PO		=	pp.Process_Order,
	ProdId	=	pp.Prod_Id
FROM	Production_Plan pp
JOIN	Production_Plan_Starts pps
	ON	pps.PP_Id = pp.PP_Id
WHERE	pps.Start_Time	<=	EntryOn
AND	pps.End_Time	>=	EntryOn 
----------------------------------------------------------------------------------------------------------------------------------------
--  Add the Product Code/Desc to the output table
----------------------------------------------------------------------------------------------------------------------------------------
UPDATE	@TAMUOutput
SET	BrandCode	=	pb.Prod_Code,
	BrandSize	=	pb.Prod_Desc
FROM	@TAMUOutput		tm
JOIN	Products_Base	pb
	ON	tm.ProdId = pb.Prod_Id

----------------------------------------------------------------------------------------------------------------------------------------
--  Return Output Table
----------------------------------------------------------------------------------------------------------------------------------------
SELECT		ID				,
			Line			,
			EntryOn			,
			Value			,
			VarId			,
			ParameterName	,
			Comment			,
			ProdId			,
			BrandCode		,
			PO				,
			BrandSize		,
			UserId			,
			Operator		
FROM	@TAMUOutput
--==============================================================================================================================================
--  Finish
--==============================================================================================================================================
SET NOCOUNT OFF
