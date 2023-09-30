CREATE PROCEDURE dbo.spCSS_HeartbeatClientConnection
@ConnectionID int,
@HostName 	  	 nvarchar(100) = ''
AS
Select @HostName = coalesce(@HostName,'')
if @HostName = '' goto PROCEXIT
Declare @DisableClients nvarchar(100)
Select @DisableClients = s.Value
 	 From Site_Parameters s with (NOLOCK)
 	 Where parm_Id = 82
If @DisableClients is not null and @DisableClients <> ''
  Begin
  --If it's not the sent in host name (like the box running the adminstrator) then
  --  return a 3 to tell the client to diconnect. 
 	 If @HostName <> @DisableClients
 	  	 Return(3)
  End
PROCEXIT:
RETURN(0) 
