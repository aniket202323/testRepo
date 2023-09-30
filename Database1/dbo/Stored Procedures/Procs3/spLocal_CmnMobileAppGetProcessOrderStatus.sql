CREATE  PROCEDURE [dbo].spLocal_CmnMobileAppGetProcessOrderStatus
 
@PPId int=NULL,
@PathId int=NULL,
@ProcessOrder varchar(50)=NULL


AS
SET NOCOUNT ON
IF @PPId IS NULL
BEGIN
	SELECT pps.PP_Status_Id AS 'StatusId',pps.PP_Status_Desc AS 'StatusCode'
	FROM	dbo.Production_Plan pp WITH(NOLOCK)
	JOIN	dbo.Production_Plan_Statuses pps WITH(NOLOCK) ON pps.PP_Status_Id = pp.PP_Status_Id
	JOIN	dbo.PrdExec_Paths pep  WITH(NOLOCK) ON pep.Path_Id = pp.Path_Id
	WHERE	pep.Path_Id = @PathId 
	AND		pp.Process_Order = @ProcessOrder
END
ELSE
BEGIN
	SELECT	pps.PP_Status_Id AS 'StatusId',pps.PP_Status_Desc AS 'StatusCode'
	FROM	dbo.Production_Plan pp WITH(NOLOCK)
	JOIN	dbo.Production_Plan_Statuses pps WITH(NOLOCK)	ON pps.PP_Status_Id = pp.PP_Status_Id
	WHERE	pp.PP_Id = @PPId
END


SET NOCOUNT OFF
RETURN