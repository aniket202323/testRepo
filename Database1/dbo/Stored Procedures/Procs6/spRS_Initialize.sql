CREATE PROCEDURE dbo.spRS_Initialize
@hostname varchar(100)
AS
Declare @heartbeat varchar(10) 
set @heartbeat = null 
-- use heart beat if it's there for the profsched user
select @heartbeat=value from user_parameters where parm_id = 154 and user_id = 36
-- if not there is not one for that user, check for the current host in the users table
if @heartbeat is null
  begin
    select @heartbeat = value from user_parameters where parm_id = 154 and hostname = @hostname 
  end
-- if not there is not one for that user or host, check for the host in the site parameters table
if @heartbeat is null
  begin
    select @heartbeat=value from site_parameters where parm_id = 154 and hostname = @hostname 
  end
-- finally, if it's still not there, see there is a default for the site
if @heartbeat is null
  begin
    select @heartbeat=value from site_parameters where parm_id = 154 
  end
-- and at last, if it's not even there just default it to 30
if @heartbeat is null
  begin
    select @heartbeat=30
  end
SELECT  'HeartBeatRate' = @heartbeat
