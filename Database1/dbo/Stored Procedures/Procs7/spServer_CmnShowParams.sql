Create Procedure dbo.spServer_CmnShowParams
@ShowAll int = 0
AS
Set Nocount On
If (@ShowAll = 1)
  Begin
    Select a.Parm_Id,Parm_Name = Substring(a.Parm_Name,1,45),b.Value,b.Hostname
    From Parameters a
    Left Outer Join Site_Parameters b on (b.Parm_Id = a.Parm_Id)
    Order by a.Parm_Id
  End
Else
  Begin
    Select a.Parm_Id,Parm_Name = Substring(a.Parm_Name,1,45),b.Value,b.Hostname
    From Parameters a
    Left Outer Join Site_Parameters b on (b.Parm_Id = a.Parm_Id)
    Where (a.Parm_Id >= 100) And (a.Parm_Id <= 200)
    Order by a.Parm_Id
  End
Select Username = Substring(b.Username,1,20),a.Parm_Id,Parm_Name = Substring(c.Parm_Name,1,45),a.Value
  From User_Parameters a
  Join Users b on (b.User_Id = a.User_Id)
  Join Parameters c on (c.Parm_Id = a.Parm_Id)
  Order By a.User_Id,a.Parm_Id
