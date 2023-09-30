--=====================================================================================================================
--	This stored procedure will return the Tree_NodeId that matches with the reason combination provided.  If it 
--	determines that the reason combination provided is invalid, it will return NULLs in the	Reasons it needs to 
--	(starting from 4 and moving to 1) until it finds a safe combination.
-----------------------------------------------------------------------------------------------------------------------
--	This is best viewed with a tab size of 4.
-----------------------------------------------------------------------------------------------------------------------
--	
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who				What
--	========	=====		===				====
--	1.0			2009-04-27	Andrew Waycott	Original Development.
--	1.1			2012-09-06	Renata Piedmont	LIBRARY-236: Added a comment to get the version script added to the sp
--	1.2			2019-02-20	Alex Klusmeyer	Converted to from "SSI" to "PG" for deployment on PG servers. Updated
--											header to comply w/ P&G standards.
-----------------------------------------------------------------------------------------------------------------------
--	How to execute it: Example
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE		@vchErrorMessage	VARCHAR(1000)	,
				@intTreeId			INT				, 
				@intReason1			INT				, 
				@intReason2			INT				, 
				@intReason3			INT				, 
				@intReason4			INT
	SELECT		@intTreeId		=	1				,
				@intReason1		=	1				, 
				@intReason2		=	5				, 
				@intReason3		=	6				, 
				@intReason4		=	7 
	SELECT	*
	FROM	dbo.fnLocal_PG_Cmn_ReasonTreeNodeId	(
								@intTreeId			,
								@intReason1			,
								@intReason2			,
								@intReason3			,
								@intReason4			)
*/
--=====================================================================================================================
--	NOTE:	SP will now receive a new output parameter to return back any error message instead of creating a new
--			result set with the error message
--=====================================================================================================================
CREATE	FUNCTION	[dbo].[fnLocal_PG_Cmn_ReasonTreeNodeId]	(
		@p_intTreeId		INT									,
		@p_intReason1		INT									,
		@p_intReason2		INT									,
		@p_intReason3		INT									,
		@p_intReason4		INT									)
RETURNS	@tblResult			TABLE	(
		Reason1				INT		,
		Reason2				INT		,
		Reason3				INT		,
		Reason4				INT		,
		NodeId				INT		,
		IsBottom			BIT		)
AS
BEGIN
	--=================================================================================================================
	--	Initialize variables
	--=================================================================================================================
	DECLARE	@intNodeId			INT				,
			@vchErrorMessage	VARCHAR(255)	,
			@bitIsComplete		BIT

	SELECT	@intNodeId	=	NULL
	--=================================================================================================================
	--	Validate Input
	--=================================================================================================================
	IF	@p_intTreeId	IS	NULL
		OR	NOT	EXISTS	(
							SELECT	*	
							FROM	dbo.Event_Reason_Tree	WITH	(NOLOCK)
							WHERE	@p_intTreeId	=	Tree_Name_Id
						)
	BEGIN
		SELECT	@vchErrorMessage	=	'Supplied Tree Id is invalid.  Tree Id = '
										+	COALESCE(CONVERT(VARCHAR(25), @p_intTreeId), '')
	END
	--=================================================================================================================
	--	Find the Tree_NodeId that matches with the reason combination provided
	--=================================================================================================================
	IF	@p_intReason4 IS NOT NULL
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	If the four reasons are provided
		---------------------------------------------------------------------------------------------------------------
		SELECT		@intNodeId				=	r4.Event_Reason_Tree_Data_Id 
		FROM		dbo.Event_Reason_Tree_Data	r4	WITH	(NOLOCK)
			JOIN	dbo.Event_Reason_Tree_Data	r3	WITH	(NOLOCK)
													ON	r4.Parent_Event_R_Tree_Data_Id	=	r3.Event_Reason_Tree_Data_Id
			JOIN	dbo.Event_Reason_Tree_Data	r2	WITH	(NOLOCK)
													ON	r3.Parent_Event_R_Tree_Data_Id	=	r2.Event_Reason_Tree_Data_Id
			JOIN	dbo.Event_Reason_Tree_Data	r1	WITH	(NOLOCK)
													ON	r2.Parent_Event_R_Tree_Data_Id	=	r1.Event_Reason_Tree_Data_Id
		WHERE	r1.Event_Reason_Id		=	@p_intReason1
			AND r2.Event_Reason_Id		=	@p_intReason2 
			AND r3.Event_Reason_Id		=	@p_intReason3 
			AND r4.Event_Reason_Id		=	@p_intReason4 
			AND r4.Event_Reason_Level	=	4
			AND r4.Tree_Name_Id			=	@p_intTreeId
		---------------------------------------------------------------------------------------------------------------
		--	If the reason combination provided is invalid
		---------------------------------------------------------------------------------------------------------------
		IF	@intNodeId IS NULL
		BEGIN
			SELECT	@p_intReason4	=	NULL
		END
	END	
	-------------------------------------------------------------------------------------------------------------------
	--	If three reasons are provided or the forth reason is wrong
	-------------------------------------------------------------------------------------------------------------------
	IF	@p_intReason3 IS NOT NULL AND @intNodeId IS NULL
	BEGIN
		SELECT		@intNodeId		=	r3.Event_Reason_Tree_Data_Id 
		FROM		dbo.Event_Reason_Tree_Data	r3	WITH	(NOLOCK)
			JOIN	dbo.Event_Reason_Tree_Data	r2	WITH	(NOLOCK)
													ON	r3.Parent_Event_R_Tree_Data_Id	=	r2.Event_Reason_Tree_Data_Id
			JOIN	dbo.Event_Reason_Tree_Data	r1	WITH	(NOLOCK)
													ON	r2.Parent_Event_R_Tree_Data_Id	=	r1.Event_Reason_Tree_Data_Id
		WHERE	r1.Event_Reason_Id		=	@p_intReason1
			AND r2.Event_Reason_Id		=	@p_intReason2 
			AND r3.Event_Reason_Id		=	@p_intReason3 
			AND r3.Event_Reason_Level	=	3
			AND r3.Tree_Name_Id			=	@p_intTreeId
		---------------------------------------------------------------------------------------------------------------
		--	If the reason combination provided is invalid
		---------------------------------------------------------------------------------------------------------------
		IF	@intNodeId IS NULL
		BEGIN
			SELECT	@p_intReason3	=	NULL
		END
	END	
	-------------------------------------------------------------------------------------------------------------------
	--	If two reasons are provided or the third reason is wrong
	-------------------------------------------------------------------------------------------------------------------
	IF		@p_intReason2	IS NOT NULL
		AND @intNodeId	IS NULL
	BEGIN
		SELECT		@intNodeId		=	r2.Event_Reason_Tree_Data_Id 
		FROM		dbo.Event_Reason_Tree_Data	r2	WITH	(NOLOCK)
			JOIN	dbo.Event_Reason_Tree_Data	r1	WITH	(NOLOCK)
													ON	r2.Parent_Event_R_Tree_Data_Id	=	r1.Event_Reason_Tree_Data_Id
		WHERE	r1.Event_Reason_Id		=	@p_intReason1
			AND r2.Event_Reason_Id		=	@p_intReason2 
			AND r2.Event_Reason_Level	=	2
			AND r2.Tree_Name_Id			=	@p_intTreeId
		---------------------------------------------------------------------------------------------------------------
		--	If the reason combination provided is invalid
		---------------------------------------------------------------------------------------------------------------
		IF	@intNodeId IS NULL
		BEGIN
			SELECT	@p_intReason2	=	NULL
		END
	END
	-------------------------------------------------------------------------------------------------------------------
	--	If one reason is provided or the second reason is wrong
	-------------------------------------------------------------------------------------------------------------------
	IF	@p_intReason1 IS NOT NULL AND @intNodeId IS NULL
	BEGIN
		SELECT	@intNodeId		=	Event_Reason_Tree_Data_Id
		FROM	dbo.Event_Reason_Tree_Data	WITH	(NOLOCK)
		WHERE	Event_Reason_Id		=	@p_intReason1
			AND Event_Reason_Level	=	1
			AND Tree_Name_Id		=	@p_intTreeId
		---------------------------------------------------------------------------------------------------------------
		--	If the reason combination provided is invalid
		---------------------------------------------------------------------------------------------------------------
		IF	@intNodeId IS NULL
		BEGIN
			SELECT	@p_intReason1 = NULL	
		END
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Check if there are more records
	-------------------------------------------------------------------------------------------------------------------
	IF	(
			SELECT	COUNT(*)
			FROM	dbo.Event_Reason_Tree_Data	WITH	(NOLOCK)
			WHERE	Tree_Name_Id				=	@p_intTreeId
				AND	Parent_Event_R_Tree_Data_Id	=	@intNodeId
		)	=	0
		AND	@intNodeId	IS	NOT	NULL
	BEGIN
		SELECT	@bitIsComplete	=	1
	END
	ELSE
	BEGIN
		SELECT	@bitIsComplete	=	0
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Populate the output Table
	-------------------------------------------------------------------------------------------------------------------
	INSERT	@tblResult		(
			Reason1			,
			Reason2			,
			Reason3			,
			Reason4			,
			NodeId			,
			IsBottom		)
	VALUES					(
			@p_intReason1	,
			@p_intReason2	,
			@p_intReason3	,
			@p_intReason4	,
			@intNodeId		,
			@bitIsComplete	)
	--=================================================================================================================
	--	Finish.
	--=================================================================================================================
	RETURN
END
