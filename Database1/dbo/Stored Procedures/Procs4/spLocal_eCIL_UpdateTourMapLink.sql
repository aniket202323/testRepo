
CREATE PROCEDURE [dbo].[spLocal_eCIL_UpdateTourMapLink]
/*
Stored Procedure		:		spLocal_eCIL_UpdateTourMapLink
Author					:		Payal Gadhvi
Date Created			:		10-Mar-2023
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Update the Tour_Stop_Map_Link based on the flag value for unlink/copy the image name. This SP will return count of image name used by other tourstop.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			10-Mar-2023		Payal Gadhvi			Creation of SP

*/
@TourStopId				INT,
@FileName		VARCHAR(150),
@UpdateOrCopyFlag		INT, 
@CheckIfFileExist		INT	OUTPUT
AS
SET NOCOUNT ON

/* Check if user want to unlink the image or want to copy the image where @UpdateOrCopyFlag value
 0 = user wants to copy image from other TourStop , 1= user wants to unlink the image  */
	IF (@UpdateOrCopyFlag = 1)
		BEGIN
		UPDATE	dbo.Local_PG_eCIL_TourStops
		SET		Tour_Map_link = NULL
		WHERE	Tour_Stop_Id = @TourStopId 
		END

	ELSE IF (@UpdateOrCopyFlag = 0)
		BEGIN
		UPDATE	dbo.Local_PG_eCIL_TourStops
		SET		Tour_Map_link = @FileName
		WHERE	Tour_Stop_Id = @TourStopId 
		END

/* Verify if the file name is used for any other TourStop */

SET @CheckIfFileExist = (SELECT COUNT(*) FROM dbo.Local_PG_eCIL_TourStops WHERE Tour_Map_link = @FileName)


SET NOCOUNT ,QUOTED_IDENTIFIER OFF
