
CREATE PROCEDURE [dbo].[spLocal_eCIL_DeleteRoute]
/*
Stored Procedure		:		spLocal_eCIL_DeleteRoute
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		21-Sep-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Delete a Route. Also delete the associated Units.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			11-Apr-2007		Normand Carbonneau		Creation of SP
1.1.0			02-Nov-2007		Normand Carbonneau		Modified code to delete associated Tasks instead of Units
																		Also included the deletion of associated users.
1.2.0			04-Jan-2008		Normand Carbonneau		There are no longer users associated to Routes.
1.2.1			13-Aug-2008		Normand Carbonneau		Fixed an issue causing a constraint error while deleting a route
																		that is referenced in Local_PG_eCIL_TeamRoutes table.
1.2.2			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.2.3			17-Feb-2022		Payal Gadhvi			Fixed an issue causing a constraint error while deleting a route
																		that is referenced in dbo.Local_PG_eCIL_RouteSheetInfo table.
1.2.4			17-Nov-2022		Payal Gadhvi			Delete TourStops associate with that Route, removed ANSI_NULL OFF as per code standard
1.2.5			04-Jan-2022		Payal Gadhvi			Delete QR Code associated with Route
1.2.6			24-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.2.7 			02-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.2.8			09-May-2023		Payal Gahdvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert, removed WITH encryption, updated to block comments
Test Code:
Declare @Msg varchar(100)
EXEC spLocal_eCIL_DeleteRoute 3
SELECT @Msg
*/
@RouteId		INT

AS
SET NOCOUNT ON;

/*-- Delete the Route-Tasks association */
DELETE FROM dbo.Local_PG_eCIL_RouteTasks WHERE Route_Id = @RouteId;

/*-- Delete the Team-Routes association*/
DELETE FROM dbo.Local_PG_eCIL_TeamRoutes WHERE Route_Id = @RouteId;

/*-- Delete the Route Activity Info association*/
DELETE FROM dbo.Local_PG_eCIL_RouteSheetInfo WHERE Route_Id = @RouteId;

/*--Delete Tour stop association */
DELETE FROM dbo.Local_PG_eCIL_TourStops WHERE Route_Id = @RouteId;

/*--Delete QR code associated with Route */
DELETE FROM Local_PG_eCIL_QRInfo WHERE Route_Ids = CAST( @RouteId as varchar(10));

/*-- Delete the Route itself */
DELETE FROM dbo.Local_PG_eCIL_Routes WHERE Route_Id = @RouteId;

/* -------------------------------------------------------------------------------------------------------------------
-- Version Management
---------------------------------------------------------------------------------------------------------------------- */
DECLARE @SP_Name	NVARCHAR(200) = 'spLocal_eCIL_DeleteRoute',	
		@Version	NVARCHAR(20) = '1.2.8' ,
		@AppId		INT = 0;

UPDATE dbo.AppVersions 
       SET App_Version = @Version,
              Modified_On = GETDATE() 
       WHERE App_Name = @SP_Name;
IF @@ROWCOUNT = 0
BEGIN
       SELECT @AppId = ISNULL(MAX(App_Id) + 1 ,1) FROM dbo.AppVersions WITH(NOLOCK);
       INSERT INTO dbo.AppVersions (App_Id, App_name, App_version)
              VALUES (@AppId, @SP_Name, @Version);
END