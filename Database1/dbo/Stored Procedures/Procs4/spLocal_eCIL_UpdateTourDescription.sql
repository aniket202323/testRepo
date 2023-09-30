
CREATE PROCEDURE [dbo].[spLocal_eCIL_UpdateTourDescription]
/*
Stored Procedure		:		spLocal_eCIL_UpdateTourDescription
Author					:		Payal Gadhvi
Date Created			:		09-Dec-2022
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Update the description of an existing TourStop.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			09-Dec-2022		Payal Gadhvi			Creation of SP
1.0.1			02-Feb-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.2			03-Apr-2023    		Aniket B			Code clean up per new coding standards.  
1.0.3			19-Apr-2023		Payal Gadhvi			Added NOCOUNT ON inside SP body
1.0.4			27-Apr-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert
1.0.5 			04-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script

Test Code:
EXEC spLocal_eCIL_UpdateTourDescription 3, "New Description" , 26
*/
@RouteId				INT,
@NewTourDesc	VARCHAR(150),
@TourStopId				INT

AS
SET NOCOUNT ON ;

SET @NewTourDesc = LTRIM(RTRIM(@NewTourDesc));

/* Verifies if there is another TourStop in the table with the same description for RouteID*/
IF EXISTS	(
				SELECT		1
				FROM		dbo.Local_PG_eCIL_TourStops 
				WHERE		Tour_Stop_Desc = @NewTourDesc
				AND			Route_Id = @RouteId 
				AND			Tour_Stop_Id <> @TourStopId
				)
		BEGIN;
			THROW 50001, 'There is already a TourStop present with the same description within this Route.', 1 ;
			RETURN ;
		END
	ELSE
		/*Updates the Description of the Route */
		UPDATE	dbo.Local_PG_eCIL_TourStops
		SET		Tour_Stop_Desc = @NewTourDesc
		WHERE	Tour_Stop_Id = @TourStopId 
		AND		Route_Id = @RouteId;
