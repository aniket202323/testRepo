Create Procedure dbo.spEMPE_GetSiteEvalue
@PID int,
@Host nvarchar(20),
@User_Id int
AS
select Value from site_Parameters
where Parm_Id = @PID and HostName = @Host
