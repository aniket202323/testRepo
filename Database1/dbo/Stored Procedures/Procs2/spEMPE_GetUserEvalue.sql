Create Procedure dbo.spEMPE_GetUserEvalue
@PID int,
@Host nvarchar(20),
@UID int,
@User_Id int
AS
select Value from User_Parameters
where Parm_Id = @PID and HostName = @Host and User_Id = @UID
