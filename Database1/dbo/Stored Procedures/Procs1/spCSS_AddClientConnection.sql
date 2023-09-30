CREATE PROCEDURE dbo.spCSS_AddClientConnection
@HostName nvarchar(50),
@PID int,
@ConnectionID int = NULL OUTPUT, 
@OS nvarchar(100) = NULL OUTPUT
AS
SET NOCOUNT ON
Declare @DisableClients nvarchar(100)
Declare @MyHost nvarchar(100)
--Had to add this parm as INPUT/OUTPUT because there was an OUTPUT at the end. Default if NULL 
Select @OS = Coalesce(@OS, 'Not Available') 
If charindex('/',@HostName) > 0
 	 Select @MyHost = left(@HostName,charindex('/',@HostName)-1)
Select @DisableClients = s.Value
 	 From Site_Parameters s
 	 Where parm_Id = 82
If @DisableClients is not null and @DisableClients <> '' and @MyHost <> '' and @MyHost is not null
  Begin
 	 If @MyHost <> @DisableClients --force timeouts in maintenance mode
 	  	 WAITFOR DELAY '00:00:40' 
  End
--Eliminates a problem with secondary DB connections. 
--  Just return the last connection ID for this hostname. 
--  FIX IN PROFSVR soon & remove this temporary fix.
-- 
Declare @HeartbeatMinAgo datetime, @Now datetime
Select @Now = dbo.fnServer_CmnGetDate(getutcdate()), @HeartbeatMinAgo = DATEADD(minute,-10,@now)
Select TOP 1 @ConnectionID = Client_Connection_Id
  From Client_Connections 
  Where (End_Time is null and Last_Heartbeat between @HeartbeatMinAgo and @Now) and HostName = @HostName
If @ConnectionID IS NOT NULL 
  Begin
    Return(0)
  end
INSERT INTO Client_Connections (HostName, Process_Id, Start_Time,Last_Heartbeat, Client_OS)
  Values(@HostName, @PID, dbo.fnServer_CmnGetDate(getutcdate()), dbo.fnServer_CmnGetDate(getutcdate()), @OS)
SELECT @ConnectionID = Scope_Identity()
SET NOCOUNT OFF
