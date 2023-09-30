--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnMobileAppGetPrIMELocation
--------------------------------------------------------------------------------------------------
-- Author				: Linda Hudon, Symasol
-- Date created			: 2019-01-09
-- Version 				: Version <1.0>
-- SP Type				: Mobile App, 
-- Caller				: FROm PrimeDataView
-- Description			: get Prime Proficy location wherept
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------



--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2019-01-09	linda Hudon		Initial Release -

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXEC [dbo].[spLocal_CmnMobileAppGetPrIMELocation] 	
--*/

----------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppDebug1] 	
@VartoSP	varchar(50) output

--WITH ENCRYPTION	
AS
SET NOCOUNT ON


DECLARE
		--For debug 
		@CurrentTime					datetime,
		@ErrMsg							varchar(1000),	
		@TimeStamp						datetime,
		@CallingSP						varchar(50),
		@DebugOnline					int




DECLARE @Path TABLE(
pathId			int)


DECLARE @ProdUnits  TABLE(
PUId			int,
PUDesc			varchar(50))

			
SET @CallingSP = 'spLocal_CmnMobileAppDebug1'
SET @DebugOnline = 1
SET @CurrentTime = GETDATE()

INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
VALUES(	getdate(), 
		@CallingSP,
		'0001 SP started' 
			)


SET @VartoSP  = 'Second'


SET NOCOUNT OFF


