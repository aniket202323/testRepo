
/*=====================================================================================================================
Stored Procedure: splocal_CST_Report_LocationOverrides
=======================================================================================================================
 Author					:	U. Lapierre, AutomaTech
 Date created			:	2023-02-16
 Version 				:	Version <1.0>
 SP Type				:	Web
 Caller					:	Called by CTS mobile application - Report
 Description			:	Wave 2 - Get appliance overrides for the report


 Editor tab spacing	: 4


 ===========================================================================================
 EDIT HISTORY:
  ===========================================================================================
 1.0		2023-02-16		U. Lapierre			Initial Release 
 1.1		2023-06-27		U. Lapierre			Adapt for Code review
 1.2		2023-08-08		U.Lapierre			Limit to 2000 rows
================================================================================================



 ===========================================================================================
 TEST CODE:
 EXECUTE splocal_CST_Report_LocationOverrides '1-Feb-2023','1-Mar-2023',10415



==================================================================================================*/
CREATE   PROCEDURE [dbo].[splocal_CST_Report_LocationOverrides]
	@StartTime				datetime,
	@EndTime				datetime,
	@LocationId				int = NULL,
	@UserId					int = NULL

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Output TABLE (
	LocationId			int,
	Location			Varchar(50)	,
	Origin_Status		Varchar(50)	,
	Origin_CleanType	Varchar(50)	,
	Origin_ProcessOrder	Varchar(50)	,
	Origin_ProdCode		Varchar(50)	,
	Origin_ProdDesc		Varchar(100),
	New_Status			Varchar(50)	,
	New_CleanType		Varchar(50)	,
	New_ProcessOrder	Varchar(50)	,
	New_ProdCode		Varchar(50)	,
	New_ProdDesc		Varchar(100),
	UserId				int,
	UserName			Varchar(50)	,
	Timestamp			datetime	,
	CommentId			int
	);

	INSERT @Output (
	LocationId			,
	Location			,
	Origin_Status		,
	Origin_CleanType	,
	Origin_ProcessOrder	,
	Origin_ProdCode		,
	Origin_ProdDesc		,
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
	SELECT	TOP 2000 o.LocationId,
			puo.pu_desc,
			pso.prodstatus_desc,
			o.Origin_CleanType,
			ppo.process_order,
			po.prod_code, 
			po.prod_desc,
			psn.prodstatus_desc,
			o.New_CleanType,
			ppn.process_order,
			pn.prod_code, 
			pn.prod_desc,
			o.userId,
			u.username,
			o.timestamp,
			o.commentid
	FROM dbo.Local_CST_LocationOverrides	o	WITH(NOLOCK)
	JOIN dbo.prod_units_Base puo				WITH(NOLOCK)	ON o.locationid = puo.pu_id
	JOIN dbo.production_status	pso				WITH(NOLOCK)	ON o.Origin_Status = pso.prodStatus_id
	LEFT JOIN dbo.production_plan ppo			WITH(NOLOCK)	ON o.Origin_PPID = ppo.pp_id
	LEFT JOIN dbo.products_base po				WITH(NOLOCK)	ON o.Origin_Prod_Id = po.prod_id
	JOIN dbo.production_status	psn				WITH(NOLOCK)	ON o.New_Status = psn.prodStatus_id
	LEFT JOIN dbo.production_plan ppn			WITH(NOLOCK)	ON o.New_PPID = ppn.pp_id
	LEFT JOIN dbo.products_base pn				WITH(NOLOCK)	ON o.New_Prod_Id = pn.prod_id
	JOIN dbo.users_base u						WITH(NOLOCK)	ON o.userid = u.user_id
	WHERE o.timestamp > @starttime
		AND o.timestamp <=@endtime;

	/*Remove the appliance not desired*/
	IF @LocationId IS NOT NULL
	BEGIN
		DELETE @Output WHERE LocationId != @LocationId;
	END

	/*Remove the @UserId not desired*/
	IF @UserId IS NOT NULL
	BEGIN
		DELETE @Output WHERE UserId !=@UserId;
	END




	/*return the list of overrides*/
	SELECT 	Location			,

			Origin_Status		,
			Origin_CleanType	,
			Origin_ProcessOrder	,
			Origin_ProdCode		,
			Origin_ProdDesc		,
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
