CREATE PROCEDURE dbo.spRS_GetLocalLogPath
@HostName varchar(20), 
@UID integer
AS
select Value from User_Parameters
Where Parm_Id = 101
and ((HostName = @HostName) or HostName = '') and User_ID = @UID
order by Hostname
