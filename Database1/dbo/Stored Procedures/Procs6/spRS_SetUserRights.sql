CREATE PROCEDURE dbo.spRS_SetUserRights
@User_Id int,
@User_Right int,
@View_Setting int,
@NTUserID varchar(100) = Null
 AS
Update Report_Tree_Users
  Set User_Rights = @User_Right,
    View_Setting = @View_Setting,
    NTUserId = @NTUserId
  Where User_Id = @User_Id
If @@Error <> 0
  Return (1)
Else
  Return (0)
