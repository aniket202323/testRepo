
CREATE PROCEDURE [dbo].[spLocal_eCIL_UpdateTourStopTasks]
/*
Stored Procedure		:		spLocal_eCIL_UpdateTourStopTasks
Author					:		Payal Gadhvi
Date Created			:		18-Nov-2022
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Save all the associations of Tasks to a TourStop and update TourStopOrder
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			18-Nov-2022		Payal Gadhvi			Creation of SP
1.0.1			26-Jan-2023		Payal Gadhvi			Added logic to update tour_stop_task_order
1.0.2			02-Feb-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.3			03-Apr-2023		Aniket B				Code clean up as per new coding standards.
1.0.4			19-Apr-2023		Payal Gadhvi			Added NOCOUNT ON inside SP body
1.0.5			27-Apr-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert
1.0.6 			04-May-2023     Aniket B				Remove grant permissions statement from the SP as moving it to permissions grant script
Test Code :
EXEC spLocal_eCIL_UpdateTourStopTasks 3 , '12,15,16,18' , 122 ,'122,123,124'
*/
@RouteId			INT,
@TaskIdsList		VARCHAR(8000) ,
@TourStopId		    INT,
@TourIdsOrder		VARCHAR(2000)

AS
SET NOCOUNT ON ;

DECLARE @OrderTable Table( TourId INT , TourOrder INT IDENTITY (1,1));

DECLARE @TaskOrder Table( TaskId INT , TaskOrder INT IDENTITY (1,1));

INSERT @OrderTable (TourId) SELECT	String FROM	dbo.fnLocal_STI_Cmn_SplitString (@TourIdsOrder, ',');

INSERT @TaskOrder (TaskId) SELECT	String FROM	dbo.fnLocal_STI_Cmn_SplitString (@TaskIdsList, ',');


/*set Tour_stop_id to NULL if we are deleting existing tasks*/ 
UPDATE dbo.Local_PG_eCIL_RouteTasks set Tour_Stop_Id = NULL , Tour_Stop_Task_Order = NULL
WHERE Route_Id = @RouteId and Tour_Stop_Id = @TourStopId AND Var_Id NOT IN (SELECT	String
	FROM		dbo.fnLocal_STI_Cmn_SplitString (@TaskIdsList, ','));

/*Update for the first time adding task to tour stops*/
UPDATE dbo.Local_PG_eCIL_RouteTasks SET Tour_Stop_Id = @TourStopId
WHERE Route_Id = @RouteId AND Var_Id IN (SELECT	String
	FROM		dbo.fnLocal_STI_Cmn_SplitString (@TaskIdsList, ',')); 

/*Update Tourstop task order*/
UPDATE	rt
SET		rt.Tour_Stop_Task_Order	= tso.TaskOrder
FROM		dbo.Local_PG_eCIL_RouteTasks rt
JOIN		@TaskOrder tso	ON		rt.Var_Id = tso.TaskId
WHERE		rt.Route_Id = @RouteId 	AND rt.Tour_Stop_Id IS NOT NULL 
			AND rt.Tour_Stop_Id = @TourStopId
			AND		(rt.Tour_Stop_Task_Order <> tso.TaskOrder
			OR  rt.Tour_Stop_Task_Order IS NULL);

/*Reorder Tour_Order for the all the Tour_Id whereever required*/
UPDATE	ts
SET		Tour_Stop_Order	=	ot.TourOrder
FROM		dbo.Local_PG_eCIL_TourStops ts
JOIN		@OrderTable ot	ON		ts.Tour_Stop_Id = ot.TourId
WHERE		ts.Route_Id = @RouteId AND ts.Tour_Stop_Order <> ot.TourOrder;
								

/* ----------------------------------------------------------------------------------------------------------------------
-- Version Management
---------------------------------------------------------------------------------------------------------------------- */
DECLARE @SP_Name	NVARCHAR(200) = 'spLocal_eCIL_UpdateTourStopTasks',	
		@Version	NVARCHAR(20) = '1.0.6' ,
		@AppId		INT = 0;

UPDATE dbo.AppVersions 
       SET App_Version = @Version,
              Modified_On = GETDATE() 
       WHERE App_Name = @SP_Name;
IF @@ROWCOUNT = 0
BEGIN
       SELECT @AppId = ISNULL(MAX(App_Id) + 1 ,1) FROM dbo.AppVersions WITH(NOLOCK);
       INSERT INTO dbo.AppVersions (App_Id, App_name, App_version )
              VALUES (@AppId, @SP_Name, @Version);
END