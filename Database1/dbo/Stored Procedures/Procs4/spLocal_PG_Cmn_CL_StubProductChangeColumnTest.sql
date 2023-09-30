

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CL_StubProductChangeColumnTest]
/*
--------------------------------------------------------------------------------------------------------
Stored procedure	 :	spLocal_PG_Cmn_CL_StubProductChangeColumnTest
Author				 :	Alexandre Turgeon, STI
Date created		 :	04-May-2006
Version				 : 1.2	
SP Type				 :	Calls a SP to create a user-defined event on a product change
Called by			 :	Product change calculation
Editor tab spacing :	3
Description			 :	If a shift change is detected, it calls a stored procedure that creates
							a user-defined event
Revision 		Date				Who						What
========			=====				====						=====
1.0.0				04-May-2006		Alexandre Turgeon		SP Creation
1.1.0				05-Jan-2009		Normand Carbonneau	Added WITH (NOLOCK) and reformatted
1.2.0				22-Jan-2009		Alexandre Turgeon		Added same functionalities than 
																	spLocal_PG_Cmn_CL_CreateCPEColumnFromProductChange
																	about product change history
1.2				26-Oct-09	Alexandre Turgeon		Adds 1 second to product change time so that new column 
																displays the new product code
																
1.3             22-Jul-2016  Megha Lohana(TCS)      Removed the register SP and update AppVersions section
1.4				17-Aug-2017	Laura Page (Factora)	Add filtering to get most recent product change
1.5				22-Sep-2017	Laura Page (Factora)	Fix table name for Production_Starts_History
--------------------------------------------------------------------------------------------------------
-- Changed for Version 3.0 and Version 3.1
1.6				2018-03-01		Fernando Rio			Changed how to get the Product History, when the server is too fast then Modified_On happens at the same time
1.7				2018-03-21		Fernando Rio			New change to deal with Product Changes
1.8				2019-05-03		Santiago Gimenez		Do not stub columns if the line is not scheduled.
3.1				2021-06-24		Cristian Jianu			Version Control for Centerline 3.1
3.1.1			2021-11-19		Camila Olguin			Changes to test PC in pilot sites
3.1.2			2021-11-26		Camila Olguin			Add TRY and CATCH logic
--------------------------------------------------------------------------------------------------------
*/

-- DECLARE
@OutputValue		varchar(200) OUTPUT,
@Timestamp			datetime,
@PUId					int

--WITH ENCRYPTION 
AS
SET NOCOUNT ON

BEGIN TRY 

DECLARE
@EventSubtypeId		int,
@Section VARCHAR(20)


-- For development servers that are very slow for Writing the History leave this delay
WAITFOR DELAY '00:00:02'

-- Get the type of operation and Start_Id in the Production_Starts_History table (2=Insert, 3=Update, 4=Delete) 

SET @Section = 'StubProductChangeColumn'
SET @EventSubtypeId =	(	SELECT	Event_Subtype_Id
									FROM		dbo.Event_Subtypes WITH (NOLOCK)
									WHERE		Event_Subtype_Desc = 'RTT Manual'
								)

-- add 1 second to timestamp
SET @Timestamp = dateadd(ss, 1, @Timestamp)


-- create a new event only if the product change was a new product change

-- verify if the event with the same event subtype is active
IF (	SELECT	Is_Active
		FROM		dbo.Event_Configuration WITH (NOLOCK)
		WHERE		Pu_Id = @Puid
		AND		Event_Subtype_Id = @EventSubtypeId
	) = 1
	BEGIN
		SET @Section = 'ExecManualColum'

		EXEC dbo.spLocal_PG_Cmn_CL_CreateManualColumnTest 'Product Change', @PUId, @EventSubtypeId, @Timestamp

		
		SET @OutputValue = 'DONOTHING'
	END
ELSE
	BEGIN
		SET @OutputValue ='UDE Not Active'
	END

END TRY
BEGIN CATCH

	 SET @OutputValue = @Section + ' ErrorMsg: '+ ERROR_MESSAGE () + ' LineError: '+Convert(varchar,ERROR_LINE())  

END CATCH
SET NOCOUNT OFF

