CREATE PROCEDURE dbo.spCSS_PutUserParm
@UserId int, 
@ParmName nvarchar(50), 
@HostName nvarchar(50),
@Value nvarchar(50)
AS
Declare @ParmId int
Select @ParmId = Parm_Id
  From Parameters 
  Where Parm_Name = @ParmName
If @ParmId IS NULL 
  Return(-100)
Update User_Parameters 
  Set Value = @Value
  Where User_Id = @UserId and Parm_Id = @ParmId and HostName = @HostName
If @@ROWCOUNT = 0 
  Insert Into User_Parameters (User_Id, Parm_Id, HostName, Value) 
    Select @UserId, @ParmId, @HostName, @Value
Return(0)
