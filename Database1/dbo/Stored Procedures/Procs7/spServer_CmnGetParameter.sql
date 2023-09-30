CREATE PROCEDURE dbo.spServer_CmnGetParameter
@ParmId int,
@UserId int,
@HostName nvarchar (50), 
@Value varchar(5000) OUTPUT,
@DepartmentId int = NULL
 AS
select @Value=NULL
if (@DepartmentId is not null)
 	 Select @Value=Value  From Dept_Parameters where Parm_Id=@ParmId and Dept_Id=@DepartmentId
If (@Value Is Null)
Begin
 	 Select @Value=Value  From User_Parameters where Parm_Id=@ParmId and User_Id=@UserId and HostName=@HostName
 	 If (@Value Is Null)
 	 Begin
 	   Select @Value=Value  From User_Parameters where Parm_Id=@ParmId and User_Id=@UserId and (HostName is NULL or HostName = '')
 	   If (@Value Is Null)
 	   Begin
 	     Select @Value=Value  From Site_Parameters where Parm_Id=@ParmId and HostName=@HostName
 	     If (@Value Is Null)
 	     Begin
 	       Select @Value=Value  From Site_Parameters where Parm_Id=@ParmId and (HostName is NULL or HostName = '')
 	     End
 	   End
 	 End
End
