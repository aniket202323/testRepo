
CREATE PROCEDURE [dbo].[spLocal_eCIL_CreateTourStop]
/*
Stored Procedure		:		spLocal_eCIL_CreateTourStop
Author					:		Payal Gadhvi
Date Created			:		16-Nov-2022
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Creates a new tourstop
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			16-Nov-2022		Payal Gadhvi			Creation of SP
1.0.1			2-Feb-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.2			03-Apr-2023		Aniket B				Code clean up per new coding standards.  
1.0.3			19-Apr-2023		Payal Gadhvi			added SET NOCOUNT inside the SP body
1.0.4			27-Apr-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert
1.0.5 			02-May-2023     Aniket B				Remove grant permissions statement from the SP as moving it to permissions grant script
Test Code:
Declare
@RouteId INT = 20 ,@TourStopDesc  VARCHAR(150) = 'MyNewTourStopDesc',@TourStopId INT
EXEC spLocal_eCIL_CreateTourStop  @TourStopDesc , @RouteId ,@TourStopId
SELECT @TourStopId
*/
@TourStopDesc		VARCHAR(150),
@RouteId		INT ,
@TourStopId		INT		OUTPUT

AS
SET NOCOUNT ON ;

SET @TourStopId = 0;
SET @TourStopDesc = LTRIM(RTRIM(@TourStopDesc));

DECLARE @TourOrder	INT;

	IF EXISTS (SELECT 1 FROM Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId)
			SET @TourOrder = (SELECT MAX(Tour_Stop_Order) FROM Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId) + 1;
	ELSE 
			SET @TourOrder = 1;
	
	IF EXISTS (SELECT 1 FROM dbo.Local_PG_eCIL_TourStops WHERE Tour_Stop_Desc = @TourStopDesc AND Route_Id = @RouteId)
		BEGIN ;
			THROW 50001, 'There is already a tour with this description', 1 ;	
			 RETURN ;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.Local_PG_eCIL_Tourstops (Route_Id,Tour_Stop_Desc,Tour_Stop_Order)
				 SELECT @RouteId, @TourStopDesc, @TourOrder;
			SET @TourStopId = @@IDENTITY;
		END
