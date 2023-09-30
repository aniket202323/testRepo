
---------------------------------------------------------------------------------------------------

------------------------------------------[Creation Of SP]-----------------------------------------

CREATE PROCEDURE [dbo].[spLocal_PCMT_VariableEditControl]
---------------------------------------------------------------------------------------------------
--											PCMT Version 5.1.1
---------------------------------------------------------------------------------------------------
--Created by	:	Alberto Ledesma, Arido Software
--On			:	15-Sep-10	
--Version		:	1.0.0
--Purpose		:	This SP control the variables to edit. If variable to edit are in different lines and those 
--				variables are not same the edition is not available

--DECLARE 
@intVarId			INT,
@Lines				VARCHAR(100),
@Band				INT

/*
SELECT	@intVarId = 23216, 
		@Lines = '5, 8, 9, 10, 12, 13, 14, 335, 8, 9, 10, 12, 13, 14, 33, 34, 23, 24, 25, 26, 32, 155, 34, 8, 23, 9, 24, 10, 25, 12, 26, 13, 14, 33, 32, 155, 34, 8, 23, 9, 24, 10, 25, 12, 26, 13, 14, 33, 32, 155, 34, 8, 23, 9, 24', 
		@band = 1
*/

AS
SET NOCOUNT ON

CREATE TABLE #Temp_LinesParam(
	RecId	INT,
	Pl_ID	INT
)


Insert INTO #Temp_LinesParam --(RecId,Pl_ID)
Exec SPCMN_ReportCollectionParsing @PRMCollectionString = @Lines, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',', @PRMDataType01 = 'NVARCHAR(200)'



-------------------------------------------------------------------------------------------------
DECLARE @RESULTS TABLE(
	STATE			VARCHAR(100),
	COLUMN_NAME		VARCHAR(100),
	PL_ID1			INT,
	PL_ID2			INT,
	Var_Id			INT
)

-------------------------------------------------------------------------------------------------
DECLARE @TABLA1 TABLE(
		var_id						INT,
		Calculation_Id				INT,
		DS_Id						INT,
		CPK_SubGroup_Size			INT,
		Data_Type_Id				INT,
		Event_Subtype_Id			INT,
		Event_Type					INT,
		Group_Id					INT,
		Input_Tag					VARCHAR(255),
		Input_Tag2					VARCHAR(255),
		LEL_Tag						VARCHAR(255),
		LRL_Tag						VARCHAR(255),
		LUL_Tag						VARCHAR(255),
		LWL_Tag						VARCHAR(255),
		Output_DS_Id				INT,
		--PU_Id						INT,
		--PUG_Id					INT,
		--PUG_Order					INT,
		PVar_Id						INT,
		Sampling_Interval			INT,
		Sampling_Offset				INT,
		Sampling_Reference_Var_Id	INT,
		Sampling_Type				INT,
		Sampling_Window				INT,
		SPC_Calculation_Type_Id		INT,
		SPC_Group_Variable_Type_Id	INT,
		Spec_Id						INT,
		Tag							INT,
		Target_Tag					INT,
		Test_Name					VARCHAR(255),
		User_Defined1				VARCHAR(255),
		User_Defined2				VARCHAR(255),
		User_Defined3				VARCHAR(255),
		Var_Desc					VARCHAR(255),
		pl_id						INT
		)

-------------------------------------------------------------------------------------------------
DECLARE @TABLA2 TABLE(
		var_id						INT,
		Calculation_Id				INT,
		DS_Id						INT,
		CPK_SubGroup_Size			INT,
		Data_Type_Id				INT,
		event_Subtype_Id			INT,
		Event_Type					INT,
		Group_Id					INT,
		Input_Tag					VARCHAR(255),
		Input_Tag2					VARCHAR(255),
		LEL_Tag						VARCHAR(255),
		LRL_Tag						VARCHAR(255),
		LUL_Tag						VARCHAR(255),
		LWL_Tag						VARCHAR(255),
		Output_DS_Id				INT,
		--PU_Id						INT,
		--PUG_Id					INT,
		--PUG_Order					INT,
		PVar_Id						INT,
		Sampling_Interval			INT,
		Sampling_Offset				INT,
		Sampling_Reference_Var_Id	INT,
		Sampling_Type				INT,
		Sampling_Window				INT,
		SPC_Calculation_Type_Id		INT,
		SPC_Group_Variable_Type_Id	INT,
		Spec_Id						INT,
		Tag							INT,
		Target_Tag					INT,
		Test_Name					VARCHAR(255),
		User_Defined1				VARCHAR(255),
		User_Defined2				VARCHAR(255),
		User_Defined3				VARCHAR(255),
		Var_Desc					VARCHAR(255),
		pl_id						INT
)

-------------------------------------------------------------------------------------------------
INSERT INTO @tabla1 (
		var_id						,
		Calculation_Id				,
		DS_Id						,
		CPK_SubGroup_Size			,
		Data_Type_Id				,
		Event_Subtype_Id			,
		Event_Type					,
		Group_Id					,
		Input_Tag					,
		Input_Tag2					,
		LEL_Tag						,
		LRL_Tag						,
		LUL_Tag						,
		LWL_Tag						,
		Output_DS_Id				,
		--PU_Id						,
		--PUG_Id					,
		--PUG_Order					,
		PVar_Id						,
		Sampling_Interval			,
		Sampling_Offset				,
		Sampling_Reference_Var_Id	,
		Sampling_Type				,
		Sampling_Window				,
		SPC_Calculation_Type_Id		,
		SPC_Group_Variable_Type_Id	,
		Spec_Id						,
		Tag							,
		Target_Tag					,
		Test_Name					,
		User_Defined1				,
		User_Defined2				,
		User_Defined3				,
		Var_Desc					,
		PL_id						) 

SELECT 	--distinct	
		var_id						,
		Calculation_Id				,
		DS_Id						,
		CPK_SubGroup_Size			,
		Data_Type_Id				,
		Event_Subtype_Id			,
		Event_Type					,
		v.Group_Id					,
		Input_Tag					,
		Input_Tag2					,
		LEL_Tag						,
		LRL_Tag						,
		LUL_Tag						,
		LWL_Tag						,
		Output_DS_Id				,
		--v.PU_Id					,
		--v.PUG_Id					,
		--v.PUG_Order				,
		PVar_Id						,
		Sampling_Interval			,
		Sampling_Offset				,
		Sampling_Reference_Var_Id	,
		Sampling_Type				,
		Sampling_Window				,
		SPC_Calculation_Type_Id		,
		SPC_Group_Variable_Type_Id	,
		Spec_Id						,
		v.Tag							,
		Target_Tag					,
		Test_Name					,
		v.User_Defined1				,
		v.User_Defined2				,
		v.User_Defined3				,
		Var_Desc					,
		pl.pl_id		
FROM  dbo.Variables			v	WITH(NOLOCK)
	JOIN dbo.PU_Groups		pug	WITH(NOLOCK) ON pug.PUG_Id	=	v.PUG_Id
	JOIN dbo.Prod_Units		pu	WITH(NOLOCK) ON pu.PU_Id	=	pug.PU_Id
	JOIN dbo.Prod_Lines		pl	WITH(NOLOCK) ON pl.PL_Id	=	pu.PL_Id
WHERE var_id = @intVarId


-------------------------------------------------------------------------------------------------
INSERT INTO @tabla2 (	
		var_id						,	
		Calculation_Id				,
		DS_Id						,
		CPK_SubGroup_Size			,
		Data_Type_Id				,
		Event_Subtype_Id			,
		Event_Type					,
		Group_Id					,
		Input_Tag					,
		Input_Tag2					,
		LEL_Tag						,
		LRL_Tag						,
		LUL_Tag						,
		LWL_Tag						,
		Output_DS_Id				,
		--PU_Id						,
		--PUG_Id					,
		--PUG_Order					,
		PVar_Id						,
		Sampling_Interval			,
		Sampling_Offset				,
		Sampling_Reference_Var_Id	,
		Sampling_Type				,
		Sampling_Window				,
		SPC_Calculation_Type_Id		,
		SPC_Group_Variable_Type_Id	,
		Spec_Id						,
		Tag							,
		Target_Tag					,
		Test_Name					,
		User_Defined1				,
		User_Defined2				,
		User_Defined3				,
		Var_Desc					,
		pl_id) 
SELECT 	--distinct	
		var_id						,
		Calculation_Id				,
		DS_Id						,
		CPK_SubGroup_Size			,
		Data_Type_Id				,
		Event_Subtype_Id			,
		Event_Type					,
		v.Group_Id					,
		Input_Tag					,
		Input_Tag2					,
		LEL_Tag						,
		LRL_Tag						,
		LUL_Tag						,
		LWL_Tag						,
		Output_DS_Id				,
		--v.PU_Id					,
		--v.PUG_Id					,
		--v.PUG_Order				,
		PVar_Id						,
		Sampling_Interval			,
		Sampling_Offset				,
		Sampling_Reference_Var_Id	,
		Sampling_Type				,
		Sampling_Window				,
		SPC_Calculation_Type_Id		,
		SPC_Group_Variable_Type_Id	,
		Spec_Id						,
		v.Tag						,
		Target_Tag					,
		Test_Name					,
		v.User_Defined1				,
		v.User_Defined2				,
		v.User_Defined3				,
		Var_Desc					,
		pl.pl_id		
FROM  dbo.Variables			v	WITH(NOLOCK)
	JOIN dbo.PU_Groups		pug	WITH(NOLOCK) ON pug.PUG_Id	=	v.PUG_Id
	JOIN dbo.Prod_Units		pu	WITH(NOLOCK) ON pu.PU_Id	=	pug.PU_Id
	JOIN dbo.Prod_Lines		pl	WITH(NOLOCK) ON pl.PL_Id	=	pu.PL_Id
WHERE var_desc in (select var_desc from variables where var_id= @intVarId)
	AND pl.pl_id IN ( SELECT Pl_ID FROM #Temp_LinesParam)
	AND var_id <> @intVarId


--SELECT * FROM @TABLA1
--SELECT * FROM @TABLA2


-------------------------------------------------------------------------------------------------
INSERT INTO @RESULTS (STATE, COLUMN_NAME, PL_ID1, PL_ID2, var_id)
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Calculation_id IS NULL
					THEN '-1' 
					ELSE T1.Calculation_id
					END ) 
				= 
				(CASE 
					WHEN T2.Calculation_Id IS NULL
					THEN '-1' 
					ELSE T2.Calculation_id
					END) 
			THEN								'TRUE'			
		END																		AS	STATE,
		'Calculation_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID			
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0

UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.DS_Id IS NULL
					THEN '-1' 
					ELSE T1.DS_Id
					END ) 
				= 
				(CASE 
					WHEN T2.DS_Id IS NULL
					THEN '-1' 
					ELSE T2.DS_Id
					END) 
			THEN								'TRUE'	
		END																		AS	STATE,
		'DS_Id',
		T1.pl_id,
		T2.pl_id	, 
		T2.VAR_ID																
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.CPK_SubGroup_Size IS NULL
					THEN '-1' 
					ELSE T1.CPK_SubGroup_Size
					END ) 
				= 
				(CASE 
					WHEN T2.CPK_SubGroup_Size IS NULL
					THEN '-1' 
					ELSE T2.CPK_SubGroup_Size
					END) 
			THEN								'TRUE'	
		END																		AS	STATE,
		'CPK_SubGroup_Size',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID														
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Data_Type_Id IS NULL
					THEN '-1' 
					ELSE T1.Data_Type_Id
					END ) 
				= 
				(CASE 
					WHEN T2.Data_Type_Id IS NULL
					THEN '-1' 
					ELSE T2.Data_Type_Id
					END) 
			THEN								'TRUE'				
		END																		AS	STATE,	
		'Data_Type_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID															
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Event_Subtype_Id IS NULL
					THEN '-1' 
					ELSE T1.Event_Subtype_Id
					END)
				= 
				(CASE 
					WHEN T2.Event_Subtype_Id IS NULL
					THEN '-1' 
					ELSE T2.Event_Subtype_Id
					END)
			THEN								'TRUE'					
		END																		AS	STATE,
		'Event_Subtype_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID														
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Event_Type IS NULL
					THEN '-1' 
					ELSE T1.Event_Type
					END)
				= 
				(CASE 
					WHEN T2.Event_Type IS NULL
					THEN '-1'
					ELSE T2.Event_Type
					END)
			THEN								'TRUE'			
		END																		AS	STATE,
		'Event_Type',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID															
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Group_Id IS NULL
					THEN '-1'
					ELSE T1.Group_Id
					END)
				= 
				(CASE 
					WHEN T2.Group_Id IS NULL
					THEN '-1'
					ELSE T2.Group_Id 
					END)
			THEN								'TRUE'			
		END																		AS	STATE,
		'Group_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID																
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Input_Tag IS NULL
					THEN '-1'
					ELSE T1.Input_Tag
					END)
				= 
				(CASE 
					WHEN T2.Input_Tag IS NULL
					THEN '-1'
					ELSE T2.Input_Tag
					END)
			THEN								'TRUE'				
		END																		AS STATE,	
		'Input_Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION		
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Input_Tag2 IS NULL
					THEN '-1'
					ELSE T1.Input_Tag2
					END)
				= 
				(CASE 
					WHEN T2.Input_Tag2 IS NULL
					THEN '-1'
					ELSE T2.Input_Tag2
					END)
			THEN								'TRUE'				
		END																		AS STATE,
		'Input_Tag2',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION		
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.LEL_Tag IS NULL
					THEN '-1'
					ELSE T1.LEL_Tag
					END)
				= 
				(CASE 
					WHEN T2.LEL_Tag IS NULL
					THEN '-1'
					ELSE T2.LEL_Tag
					END)
			THEN								'TRUE'
		END																		AS STATE,
		'LEL_Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.LRL_Tag IS NULL
					THEN '-1'
					ELSE T1.LRL_Tag
					END)
				= 
				(CASE 
					WHEN T2.LRL_Tag IS NULL
					THEN '-1'
					ELSE T2.LRL_Tag
					END)
			THEN								'TRUE'		
		END																		AS STATE,
		'LRL_Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.LUL_Tag IS NULL
					THEN '-1'
					ELSE T1.LUL_Tag
					END)
				= 
				(CASE 
					WHEN T2.LUL_Tag IS NULL
					THEN '-1'
					ELSE T2.LUL_Tag
					END)
			THEN								'TRUE'					
		END																		AS STATE,
		'LUL_Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.LWL_Tag IS NULL
					THEN '-1'
					ELSE T1.LWL_Tag
					END)
				= 
				(CASE 
					WHEN T2.LWL_Tag IS NULL
					THEN '-1'
					ELSE T2.LWL_Tag
					END)
			THEN								'TRUE'				
		END																		AS STATE,
		'LWL_Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Output_DS_Id IS NULL
					THEN '-1'
					ELSE T1.Output_DS_Id
					END)
				= 
				(CASE 
					WHEN T2.Output_DS_Id IS NULL
					THEN '-1'
					ELSE T2.Output_DS_Id
					END)
			THEN								'TRUE'		
		END																		AS STATE,
		'Output_DS_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Sampling_Interval IS NULL
					THEN '-1'
					ELSE T1.Sampling_Interval
					END)
				= 
				(CASE 
					WHEN T2.Sampling_Interval IS NULL
					THEN '-1'
					ELSE T2.Sampling_Interval
					END)
			THEN								'TRUE'			
		END																		AS STATE,
		'Sampling_Interval',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Sampling_Offset IS NULL
					THEN '-1'
					ELSE T1.Sampling_Offset
					END)
				=
				(CASE 
					WHEN T2.Sampling_Offset IS NULL
					THEN '-1'
					ELSE T2.Sampling_Offset
					END)
			THEN								'TRUE'				
		END																		AS STATE,
		'Sampling_Offset',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Sampling_Reference_Var_Id IS NULL
					THEN '-1'
					ELSE T1.Sampling_Reference_Var_Id
					END)
				= 
				(CASE 
					WHEN T2.Sampling_Reference_Var_Id IS NULL
					THEN '-1'
					ELSE T2.Sampling_Reference_Var_Id
					END)
			THEN								'TRUE'				
		END																		AS STATE,
		'Sampling_Reference_Var_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Sampling_Type IS NULL
					THEN '-1'
					ELSE T1.Sampling_Type
					END)
				= 
				(CASE 
					WHEN T2.Sampling_Type IS NULL
					THEN '-1'
					ELSE T2.Sampling_Type
					END)
			THEN								'TRUE'			
		END																		AS STATE,
		'Sampling_Type',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Sampling_Window IS NULL
					THEN '-1'
					ELSE T1.Sampling_Window
					END)
				= 
				(CASE 
					WHEN T2.Sampling_Window IS NULL
					THEN '-1'
					ELSE T2.Sampling_Window
					END)
			THEN								'TRUE'			
		END																		AS STATE,
		'Sampling_Window',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.SPC_Calculation_Type_Id IS NULL
					THEN '-1'
					ELSE T1.SPC_Calculation_Type_Id
					END)
				= 
				(CASE 
					WHEN T2.SPC_Calculation_Type_Id IS NULL
					THEN '-1'
					ELSE T2.SPC_Calculation_Type_Id
					END)
			THEN								'TRUE'			
		END																		AS STATE,
		'SPC_Calculation_Type_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.SPC_Group_Variable_Type_Id IS NULL
					THEN '-1'
					ELSE T1.SPC_Group_Variable_Type_Id
					END)
				= 
				(CASE 
					WHEN T2.SPC_Group_Variable_Type_Id IS NULL
					THEN '-1'
					ELSE T2.SPC_Group_Variable_Type_Id
					END)
			THEN								'TRUE'				
		END																		AS STATE,
		'SPC_Group_Variable_Type_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Spec_Id IS NULL
					THEN '-1'
					ELSE T1.Spec_Id
					END)
				= 
				(CASE 
					WHEN T2.Spec_Id IS NULL
					THEN '-1'
					ELSE T2.Spec_Id 
					END)
			THEN								'TRUE'		
		END																		AS STATE,
		'Spec_Id',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Tag IS NULL
					THEN '-1'
					ELSE T1.Tag
					END)
				= 
				(CASE 
					WHEN T2.Tag IS NULL
					THEN '-1'
					ELSE T2.Tag
					END)
			THEN								'TRUE'		
		END																		AS STATE,
		'Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Target_Tag IS NULL
					THEN '-1'
					ELSE T1.Target_Tag
					END)
				= 
				(CASE 
					WHEN T2.Target_Tag IS NULL
					THEN '-1'
					ELSE T2.Target_Tag 
					END)
			THEN								'TRUE'		
		END																		AS STATE,
		'Target_Tag',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
--UNION	
--	SELECT 
--		CASE 
--			WHEN 
--				(CASE 
--					WHEN T1.Test_Name IS NULL
--					THEN ''
--					ELSE T1.Test_Name
--					END)
--				<> 
--				(CASE 
--					WHEN T2.Test_Name IS NULL
--					THEN ''
--					ELSE T2.Test_Name
--					END)
--			THEN								'TRUE'					
--		END																		AS STATE,
--		'Test_Name'
--	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID <> T2.DS_ID
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.User_Defined1 IS NULL
					THEN '-1'
					ELSE T1.User_Defined1
					END)
				= 
				(CASE 
					WHEN T2.User_Defined1 IS NULL
					THEN '-1' 
					ELSE T2.User_Defined1
					END)
				--T1.User_Defined1 = T2.User_Defined1
			THEN								'TRUE'		
		END																		AS STATE,
		'User_Defined1',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.User_Defined2 IS NULL
					THEN '-1'
					ELSE T1.User_Defined2
					END)
				= 
				(CASE 
					WHEN T2.User_Defined2 IS NULL
					THEN '-1'
					ELSE T2.User_Defined2
					END)
			THEN								'TRUE'		
		END																		AS STATE,
		'User_Defined2',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.User_Defined3 IS NULL
					THEN '-1'
					ELSE T1.User_Defined3
					END)
				= 
				(CASE 
					WHEN T2.User_Defined3 IS NULL
					THEN '-1'
					ELSE T2.User_Defined3
					END)
			THEN								'TRUE'				
		END																		AS STATE,
		'User_Defined3',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0
UNION	
	SELECT 
		CASE 
			WHEN 
				(CASE 
					WHEN T1.Var_Desc IS NULL
					THEN ''
					ELSE T1.Var_Desc
					END)
				= 
				(CASE 
					WHEN T2.Var_Desc IS NULL
					THEN ''
					ELSE T2.Var_Desc
					END)
			THEN								'TRUE'			
		END																		AS STATE,
		'Var_Desc',
		T1.pl_id,
		T2.pl_id, 
		T2.VAR_ID
	FROM @TABLA1 T1 JOIN @TABLA2 T2 ON T1.DS_ID >=0

/*
IF @Band=0
	BEGIN
		SELECT 
			r.*, 
			pl1.pl_desc		AS Line_Desc_Selected,
			pl2.pl_desc		AS Lines_Differents
		FROM @RESULTS r
			JOIN dbo.Prod_Lines	pl1	WITH(NOLOCK) ON pl1.PL_Id	=	r.PL_Id1
			JOIN dbo.Prod_Lines	pl2	WITH(NOLOCK) ON pl2.PL_Id	=	r.PL_Id2
		WHERE STATE IS not NULL
	END
ELSE
	BEGIN
		SELECT DISTINCT 
			pl_id2,
			var_id,
			count(var_id)			
		FROM @RESULTS r
			JOIN dbo.Prod_Lines	pl	WITH(NOLOCK) ON pl.PL_Id	=	r.PL_Id2
		WHERE STATE IS not NULL
		GROUP BY VAR_ID, pl_id2 Having count(var_id)>27
	END*/

IF @Band=0
	BEGIN
		SELECT Top 1
			r.*, 
			pl1.pl_desc		AS Line_Desc_Selected,
			pl2.pl_desc		AS Lines_Differents
		FROM @RESULTS r
			JOIN dbo.Prod_Lines	pl1	WITH(NOLOCK) ON pl1.PL_Id	=	r.PL_Id1
			JOIN dbo.Prod_Lines	pl2	WITH(NOLOCK) ON pl2.PL_Id	=	r.PL_Id2
		WHERE STATE IS NOT NULL
	END
ELSE
	IF @band=1
		BEGIN
			SELECT DISTINCT 
					pl_desc		AS Line_Desc,
					var_id				
			FROM @RESULTS r
				JOIN dbo.Prod_Lines	pl	WITH(NOLOCK) ON pl.PL_Id	=	r.PL_Id2
			WHERE STATE IS NOT NULL
			GROUP BY VAR_ID, pl_desc 
			HAVING COUNT(DISTINCT var_id) < 28
		END
	ELSE
		BEGIN
			SELECT DISTINCT 
				pl_id2,
				var_id,
				count(DISTINCT var_id)
			FROM @RESULTS r
					JOIN dbo.Prod_Lines	pl	WITH(NOLOCK) ON pl.PL_Id	=	r.PL_Id2
			WHERE STATE IS not NULL
			GROUP BY VAR_ID, pl_id2 
			HAVING COUNT(DISTINCT var_id)>27
		END

DROP TABLE #Temp_LinesParam

