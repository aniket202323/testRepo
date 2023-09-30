
CREATE PROCEDURE [dbo].[spLocal_eCIL_DeleteTourStop]
/*
Stored Procedure		:		spLocal_eCIL_DeleteTourStop
Author					:		Payal Gadhvi
Date Created			:		11-Nov-2022
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Delete a Tourstop. Also Update RouteTask table if there are any task associated with TourStop.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			11-Nov-2022		Payal Gadhvi			Creation of SP
1.0.1			02-Feb-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.2			23-Feb-2023		Payal Gadhvi			Added TourMap as out parameter
1.0.3			09-Mar-2023		Payal Gadhvi			Added condition to check if image is associated with any other TourStop
1.0.4			03-Apr-2023		Aniket B			Code clean up as per new coding standards.
1.0.5			19-Apr-2023		Payal Gadhvi			Code cleanup as per feedback.
1.0.6			27-Apr-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert
1.0.7 			02-May-2023          Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script

Test Code :
Declare
@RouteId INT = 252 ,@TourStopId  INT = 382 ,@TourMap VARCHAR(100)
EXEC spLocal_eCIL_DeleteTourStop @RouteId,@TourStopId,@TourMap
*/

@RouteId		INT,
@TourStopId		INT,
@TourMap		VARCHAR(100) OUTPUT

AS
SET NOCOUNT ON;

DECLARE 
@TourOrder	INT,
@TourMapImageCheck	VARCHAR(100);

DECLARE @OrderTable TABLE( TourId INT , TourOrder INT IDENTITY (1,1));

SET @TourOrder = (SELECT Tour_Stop_Order FROM dbo.Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId AND Tour_Stop_Id = @TourStopId);

/*In this section we will verify that does tour_map_link is associated with any other TourStop then retun NULL else return tour_map_link */
SET  @TourMapImageCheck = (SELECT Tour_Map_link FROM dbo.Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId AND Tour_Stop_Id = @TourStopId);

IF ((SELECT COUNT(*) FROM dbo.Local_PG_eCIL_TourStops WHERE Tour_Map_link = @TourMapImageCheck) = 1)
		SET @TourMap = (SELECT Tour_Map_link FROM dbo.Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId AND Tour_Stop_Id = @TourStopId);
ELSE
		SET @TourMap = NULL;

UPDATE dbo.Local_PG_eCIL_RouteTasks SET Tour_Stop_Id = NULL WHERE Tour_Stop_Id = @TourStopId;

DELETE FROM dbo.Local_PG_eCIL_QRInfo WHERE Tour_Stop_Id = @TourStopId; 

DELETE FROM dbo.Local_PG_eCIL_TourStops WHERE Tour_Stop_Id = @TourStopId AND Route_Id = @RouteId ;

/* transfer remaining tourstops to @OrderTable */
INSERT @OrderTable(TourId) SELECT Tour_Stop_Id FROM dbo.Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId;

/*Reorder Tour_Order for the all the Tour_Id whereever required */
UPDATE	ts
SET		Tour_Stop_Order	= ot.TourOrder
FROM		dbo.Local_PG_eCIL_TourStops ts
JOIN		@OrderTable ot	ON		ts.Tour_Stop_Id = ot.TourId
WHERE		ts.Route_Id = @RouteId AND ts.Tour_Stop_Order <> ot.TourOrder ;

