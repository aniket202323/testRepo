
/*=====================================================================================================================
Stored Procedure: splocal_CST_Report_ApplianceOverrides
=======================================================================================================================
Author				:	U. Lapierre, AutomaTech
Date created		:	2023-02-16
Version 			:	Version <1.0>
SP Type				:	Web
Caller				:	Called by CTS mobile application - Report
Description			:	Wave 2 - Get appliance overrides for the report
Editor tab spacing	:	4


EDIT HISTORY:
=============
1.0		2023-02-16		U. Lapierre			Initial Release 
1.1		2023-04-03		U. Lapierre			add appliance type
1.2		2023-06-27		U. Lapierre			Adapt for Code review
1.3		2023-08-08		U.Lapierre			Limit to 2000 rows
1.4		2023-09-06		U.Lapierre			Replace Input ApplianceId by Serial
================================================================================================*/

/*===========================================================================================
TEST CODE:

EXECUTE splocal_CST_Report_ApplianceOverrides '1-Feb-2023','1-Mar-2023', 'adsadasdsadas'

================================================================================================*/


/* ========================================================= */
CREATE   PROCEDURE [dbo].[splocal_CST_Report_ApplianceOverrides]
	@StartTime				DATETIME,
	@EndTime				DATETIME,
	@Serial					VARCHAR(50) = NULL,
	@UserId					INT = NULL

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@TABLEID				INT,
			@TFIDType				INT,
			@TFType					VARCHAR(50) = 'CTS appliance type',
			@ApplianceId			INT;

	DECLARE @Output TABLE (
	ApplianceId			INT,
	Appliance			VARCHAR(50)	,
	Appliance_Type		VARCHAR(50)	,
	Origin_Location		VARCHAR(50)	,
	Origin_Status		VARCHAR(50)	,
	Origin_CleanType	VARCHAR(50)	,
	Origin_ProcessOrder	VARCHAR(50)	,
	Origin_ProdCode		VARCHAR(50)	,
	Origin_ProdDesc		VARCHAR(100),
	New_Location		VARCHAR(50)	,
	New_Status			VARCHAR(50)	,
	New_CleanType		VARCHAR(50)	,
	New_ProcessOrder	VARCHAR(50)	,
	New_ProdCode		VARCHAR(50)	,
	New_ProdDesc		VARCHAR(100),
	UserId				INT,
	UserName			VARCHAR(50)	,
	Timestamp			DATETIME	,
	CommentId			INT
	);





/* Get user defoned properties for appliance type  */
SET @TABLEID	= (SELECT tableid FROM dbo.tables WITH(NOLOCK) WHERE tablename = 'Prod_units');
SET @TFIDType	= (SELECT table_field_id FROM dbo.table_fields WHERE tableid = @TABLEID AND table_field_desc = @TFtype	);


	INSERT @Output (
	ApplianceId			,
	Appliance			,
	Origin_Location		,
	Origin_Status		,
	Origin_CleanType	,
	Origin_ProcessOrder	,
	Origin_ProdCode		,
	Origin_ProdDesc		,
	New_Location		,
	New_Status			,
	New_CleanType		,
	New_ProcessOrder	,
	New_ProdCode		,
	New_ProdDesc		,
	UserId				,
	UserName			,
	Timestamp			,
	commentid
	)
	SELECT	TOP 2000 ApplianceId,
			ed.alternate_event_num,
			puo.pu_desc,
			pso.prodstatus_desc,
			o.Origin_CleanType,
			ppo.process_order,
			po.prod_code, 
			po.prod_desc,
			pun.pu_desc,
			psn.prodstatus_desc,
			o.New_CleanType,
			ppn.process_order,
			pn.prod_code, 
			pn.prod_desc,
			o.userId,
			u.username,
			o.timestamp,
			o.commentid
	FROM dbo.Local_CST_ApplianceOverrides	o	WITH(NOLOCK)
	JOIN dbo.event_details ed					WITH(NOLOCK)	ON o.applianceId = ed.event_id
	JOIN dbo.prod_units_Base puo				WITH(NOLOCK)	ON o.Origin_Location = puo.pu_id
	JOIN dbo.production_status	pso				WITH(NOLOCK)	ON o.Origin_Status = pso.prodStatus_id
	LEFT JOIN dbo.production_plan ppo			WITH(NOLOCK)	ON o.Origin_PPID = ppo.pp_id
	LEFT JOIN dbo.products_base po				WITH(NOLOCK)	ON o.Origin_Prod_Id = po.prod_id
	JOIN dbo.prod_units_Base pun				WITH(NOLOCK)	ON o.New_Location = pun.pu_id
	JOIN dbo.production_status	psn				WITH(NOLOCK)	ON o.New_Status = psn.prodStatus_id
	LEFT JOIN dbo.production_plan ppn			WITH(NOLOCK)	ON o.New_PPID = ppn.pp_id
	LEFT JOIN dbo.products_base pn				WITH(NOLOCK)	ON o.New_Prod_Id = pn.prod_id
	JOIN dbo.users_base u						WITH(NOLOCK)	ON o.userid = u.user_id
	WHERE o.timestamp > @starttime
		AND o.timestamp <=@endtime;

	/*Remove the appliance not desired*/
	IF @Serial IS NOT NULL
	BEGIN
		DELETE @Output WHERE Appliance !=@Serial;
	END

	/*Remove the @UserId not desired*/
	IF @UserId IS NOT NULL
	BEGIN
		DELETE @Output WHERE UserId !=@UserId;
	END

	/* Get the applaince type */
	UPDATE o
	SET Appliance_type = tfv.value
	FROM @Output o
	JOIN dbo.events e					WITH(NOLOCK)	ON e.event_id = o.ApplianceId
	JOIN dbo.table_fields_Values tfv	WITH(NOLOCK)	ON e.pu_id = tfv.KeyId	AND	tfv.table_field_id = @tfidType;


	/*return the list of overrides*/
	SELECT 	Appliance			,
			Appliance_Type		,
			Origin_Location		,
			Origin_Status		,
			Origin_CleanType	,
			Origin_ProcessOrder	,
			Origin_ProdCode		,
			Origin_ProdDesc		,
			New_Location		,
			New_Status			,
			New_CleanType		,
			New_ProcessOrder	,
			New_ProdCode		,
			New_ProdDesc		,
			UserName			,
			Timestamp			,
			CommentId		
	FROM @Output
	ORDER BY timestamp ;

END
RETURN
