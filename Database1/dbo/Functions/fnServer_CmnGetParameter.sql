/*
select CONVERT(INT,dbo.fnServer_CmnGetParameter(104, 26, HOST_NAME(), '20'))
select CONVERT(INT,dbo.fnServer_CmnGetParameter(104, 26, HOST_NAME(), default))
*/
CREATE FUNCTION dbo.fnServer_CmnGetParameter(
@ParmId int,
@UserId int,
@HostName varchar, 
@DefaultValue varchar(5000) = NULL, --Note per SQL BOL the keyword 'Default' is required to get the default value unlike sps)
@DepartmentId int = NULL
) 
     RETURNS Varchar(5000)
AS 
BEGIN -- Function
Declare @Value varchar(5000)
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
 	       If (@Value Is Null)
 	       Begin
 	         Select @Value=@DefaultValue 
 	       End
 	     End
 	   End
 	 End
End
RETURN @Value
END -- Function
