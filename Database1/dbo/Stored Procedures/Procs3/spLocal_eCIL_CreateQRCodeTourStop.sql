
--Step B Creation Of SP
CREATE PROCEDURE [dbo].[spLocal_eCIL_CreateQRCodeTourStop]
/*
Stored Procedure		:		spLocal_eCIL_CreateQRCodeTourStop
Author					:		Praveen Jain
Date Created			:		07-De-2022
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Save QR details and get the QR name and description details

CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			07-De-2022		Praveen Jain        	Creation of SP

																		
Test Code:
EXEC spLocal_eCIL_CreateQRCodeTourStop 51, '125, 159',125
*/
@RouteId		INT,
@TourStopIds	VARCHAR(8000),
@Entry_By		INT

AS
SET NOCOUNT ON


--DECLARE @TourStopList	TABLE
--(
--PKey					INT IDENTITY(1,1),
--TourStopId					INT
--)

-- Determine the list of lines to include in the Plant Model
--INSERT @TourStopList (TourStopId)
--	SELECT	String
--	FROM		dbo.fnLocal_STI_Cmn_SplitString(@TourStopIds, ',')

INSERT INTO Local_PG_eCIL_TourStop_QRInfo(QR_Name,QR_Description,QR_GeneratedOn,Route_Id,TourStop_Id,Entry_By) 
Select CONCAT(LEFT(Tour_Stop_Desc,40),'_',Tour_Stop_Id) as QR_Name,LEFT(CONCAT(Route_Desc,'_',Tour_Stop_Desc),255) as QR_Description,getdate() as QR_GeneratedOn,r.Route_Id,Tour_Stop_Id,@Entry_By
from  Local_PG_eCIL_Routes r  join Local_PG_eCIL_TourStops ts on r.Route_Id=ts.Route_Id where r.Route_Id=@RouteId and ts.Tour_Stop_Id in (SELECT	String
	FROM		dbo.fnLocal_STI_Cmn_SplitString (@TourStopIds, ','))


Select QR_Id,QR_Name,QR_Description from [dbo].[Local_PG_eCIL_TourStop_QRInfo] where Route_Id=@RouteId and TourStop_Id in (SELECT String	FROM dbo.fnLocal_STI_Cmn_SplitString (@TourStopIds, ','))

SET NOCOUNT OFF
