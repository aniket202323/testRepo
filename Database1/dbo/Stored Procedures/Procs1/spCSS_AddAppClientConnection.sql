CREATE PROCEDURE dbo.spCSS_AddAppClientConnection
@ConnectionID int,
@AppId int, 
@AppVersion nvarchar(50)
AS
set nocount on 
Declare 
  @OutputString nVarChar(255), 
  @ConcurrentUsers nVarChar(255), 
  @MaxUsers int, 
  @CurrentUsers int, 
  @ModuleId tinyint, 
  @HeartbeatLength int, 
  @AlreadyConnected int, 
  @HostName nvarchar(50),
  @Count int,
  @Now datetime, 
  @HeartbeatMinAgo datetime
--Exit sp if any triggers exist on the Client_Connection_Module_Data
Select @Count = Count(s.Name)
 	 From sysobjects s
 	 Left Join sysobjects s1 on s.parent_obj = s1.id
 Where s1.Name = 'Client_Connection_Module_Data' and s.xtype = 'TR'
If @Count > 0
  Begin
    Return (-99)
  End
--Exit sp if any triggers exist on the Client_Connection_App_Data
Select @Count = Count(s.Name)
 	 From sysobjects s
 	 Left Join sysobjects s1 on s.parent_obj = s1.id
 Where s1.Name = 'Client_Connection_App_Data' and s.xtype = 'TR'
If @Count > 0
  Begin
    Return (-99)
  End
Select @HostName = HostName 
  From Client_Connections 
  Where Client_Connection_Id = @ConnectionId 
SELECT @ModuleId = a.Module_Id, @ConcurrentUsers = m.Concurrent_Users
 FROM Modules m 
 JOIN AppVersions a on a.Module_id = m.Module_Id and a.App_Id = @AppId
IF @ModuleId = 0
  BEGIN
     RETURN(0)
  END
AttemptOtherModule:
--Get the HeartBeat rate for this workstation
Select @HeartbeatLength = COALESCE(CONVERT(int, COALESCE(value, '0') ), 0) 
  From Site_Parameters 
  Where Parm_Id = 21 and HostName = @HostName
--If missing get it for the site. 
If @HeartbeatLength = 0 
  Select @HeartbeatLength = CONVERT(int, COALESCE(value, '10') ) 
    From Site_Parameters p
    Where Parm_Id = 21 and Hostname = ''
-- If still missing, default to 10 minutes
If @HeartbeatLength is NULL or @HeartbeatLength = 0 
  Select @HeartbeatLength = 10
Select @Now = dbo.fnServer_CmnGetDate(getutcdate()), @HeartbeatMinAgo = DATEADD(minute,@HeartbeatLength * -1,@now)
-- If they are all ready connected and using this module, then they can have more
/*Select @AlreadyConnected = COALESCE(COUNT(*),0)
  From Client_Connection_Module_Data d
  Join Client_Connections c on c.Client_Connection_Id = d.Client_Connection_Id 
         and (c.End_Time is null and DATEDIFF(minute, c.Last_Heartbeat, dbo.fnServer_CmnGetDate(getutcdate())) < @HeartbeatLength) and HostName = @HostName
  Where Module_Id = @ModuleId
*/
Select TOP 1 @AlreadyConnected = d.Client_Connection_Id
  From Client_Connection_Module_Data d
  Join Client_Connections c on c.Client_Connection_Id = d.Client_Connection_Id 
         and (c.End_Time is null and c.Last_Heartbeat between @HeartbeatMinAgo and @Now) and HostName = @HostName
  Where Module_Id = @ModuleId
Select @AlreadyConnected = @@ROWCOUNT
If @AlreadyConnected > 0 
  BEGIN
    GOTO UpdateConnections
  END
--Otherwise do a compariason between licenses and users
EXEC spCmn_Encryption @ConcurrentUsers,'EncrYptoR',@ModuleId,0,@OutputString output 
SELECT @MaxUsers = CONVERT(Int, COALESCE(@OutputString, 0))
If @MaxUsers > 0 
  BEGIN 
    -- How many users are currently logged on
    SELECT @CurrentUsers = COALESCE(COUNT(DISTINCT HOSTNAME), 0) 
      From Client_Connection_Module_Data m
      Join Client_Connections c on c.Client_Connection_Id = m.Client_Connection_Id 
             and (c.End_Time is null and c.Last_Heartbeat between @HeartbeatMinAgo and @Now) 
      Where Module_Id = @ModuleId
    IF @MaxUsers > @CurrentUsers 
      BEGIN
 	 GOTO UpdateConnections
      END
    ELSE
      RETURN(@MaxUsers)  -- There are no available licenses for this app, return the maximum
      --print ' failed 1'
  END
Else
  --Time/Product_Time Autolog may be licensed under the Efficiency module if no Quality licenses
  If @AppId = 30 and @ModuleId <> 2
    Begin
      SELECT @ModuleId = Module_Id, @ConcurrentUsers = Concurrent_Users
       FROM Modules
         Where Module_Id = 2
      GOTO AttemptOtherModule
    End
--Return 0 for these 4 apps so that the applications can be registered and the Language cache loaded
--8 - Proficy Client
--22 - Common Dialogs
--23 - Server Object (ProfSVR)
--24 - Query Wizard
--200-299 - Standard Reports
-->50000 - Local Reports
IF @AppId = 8 or @AppId = 22 or @AppId = 23 or @AppId = 24 or (@AppId >= 200 and @AppId <= 299) or @AppId > 49999
  BEGIN
     RETURN(0)
  END
IF @AppId = 5 RETURN(0)
RETURN(-1)  -- There are no licenses for this app. 
--print ' failed 2'
UpdateConnections:
-- Each host can have multiple connections so this connection my or may not be there
    UPDATE Client_Connection_Module_Data Set Counter = Counter + 1 Where Client_Connection_Id = @ConnectionID and Module_Id = @ModuleId
    If @@ROWCOUNT = 0 
      INSERT INTO Client_Connection_Module_Data (Client_Connection_Id, Module_Id, Counter)
         Values (@ConnectionID, @ModuleId, 1) 
    UPDATE Client_Connection_App_Data Set Counter = Counter + 1 Where Client_Connection_Id = @ConnectionID and App_Id = @AppId
    If @@ROWCOUNT = 0 
      INSERT INTO Client_Connection_App_Data (Client_Connection_Id, App_Id, Counter, Version)
        Values (@ConnectionID, @AppId, 1, @AppVersion) 
    RETURN(0)
        --print 'success'
