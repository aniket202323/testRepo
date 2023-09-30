CREATE PROCEDURE [dbo].[spRS_WWWHeartBeatProficy]
@ConnectionId int
 AS
---------------------------------
-- LOCAL VARIABLES
---------------------------------
Declare @App_Version varchar(50)
Declare @RC int --Return Code
---------------------------------
-- GET APP VERSION NUMBER
---------------------------------
select @App_Version = App_Version from appversions where app_id = 11
If Upper(Ltrim(RTrim(@App_Version))) = 'UNKNOWN'
  Select @App_Version = '1.0?'
--------------------------------------------
-- Update the Client_Connection Time Stamp
--------------------------------------------
exec @RC = spCSS_HeartbeatClientConnection @ConnectionId
