/* TEST SP
select * from prdexec_inputs
EXEC spLocal_CmnMobileApp_GetPathInfo 79, 0
*/
CREATE PROCEDURE [dbo].[spLocal_CmnMobileApp_GetPathInfo]
    @PathId						int,
    @ReturnNull					bit
AS
SET NOCOUNT ON

DECLARE @PathCode varchar(50) = (SELECT path_code FROM dbo.prdExec_paths WITH(NOLOCK) WHERE path_id = @pathId)

IF @PathCode IS NOT NULL
BEGIN
    /*--First recordset - GET ALL PATH UDPs*/
    exec spLocal_CmnWFGetUDPValues @pathId,'PrdExec_Paths', '%',@ReturnNull

	/* Second recordset: WMSInformation */
	exec spLocal_CmnMobileAppGetWMSInformation @pathId

	/* Third recordset: Path process orders for given statuses */
	exec spLocal_CmnMobileAppGetOrdersWithComments @pathCode,'Pending,Active,Initiate,Ready,Closing,Error,Pause'

	/* Fourth recordset: Get latest counts on path */
	exec spLocal_CmnGetLatestMobileAppCounts @pathCode
END

SET NOCOUNT OFF
RETURN