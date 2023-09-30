CREATE PROCEDURE [dbo].[spRS_WWWConnectProficy] 
@HostName varchar(50), 
@PID int
AS
----------------------------------------------------------------------
-- @HostName will be the ip address of the connecting client computer
-- @PID will be the IIS Session Id
----------------------------------------------------------------------
Declare @RC int
Declare @ConnectionId int
Declare @Message varchar(100)
Declare @App_Version varchar(50)
select @App_Version = App_Version from appversions where app_id = 11
If Upper(Ltrim(RTrim(@App_Version))) = 'UNKNOWN'
  Select @App_Version = '1.0?'
---------------------------------------------------------------------
-- Get A Client Connection Id
---------------------------------------------------------------------
exec @RC = spcss_AddClientConnection @HostName, @PID, @ConnectionId output
----------------------------------------------------------------------
-- A Return Code of 0 = Connection OK
-- A Return Code  of -1 = Site is not licensed
-- A Return Code > 0 = You have reached the max number of connections
----------------------------------------------------------------------
exec @RC = spCSS_AddAppClientConnection @ConnectionId, 11, @App_Version
If @RC = 0
  Begin
    Select @Message = 'Connection OK'
  End
If @RC = -1
  Begin
    Select @ConnectionId = 0
    Select @Message = 'This site is not licensed to run Plant Applications Web Werver'
  End
If @RC > 0
  Begin
    Select @ConnectionId = 0
    Select @Message = 'No More User Connections Available'
  End
select @ConnectionId 'ConnectionId', @Message 'Message'
