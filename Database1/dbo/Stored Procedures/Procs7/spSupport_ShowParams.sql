Create Procedure dbo.spSupport_ShowParams
AS
Select ParmId = a.Parm_Id,
       ParamName = Substring(a.Parm_Name,1,25),
       Value = Substring(b.Value,1,35),
       HostName = Substring(b.HostName,1,20)
  From Parameters a
  Join Site_Parameters b on (b.Parm_Id = a.Parm_Id) And (Value Is Not NULL) And (Value <> '')
  Order By a.Parm_Id
Select ParmId = a.Parm_Id,
       Username = Substring(c.Username,1,20),
       ParamName = Substring(a.Parm_Name,1,25),
       Value = Substring(b.Value,1,35)
  From Parameters a
  Join User_Parameters b on b.Parm_Id = a.Parm_Id
  Join Users c on c.User_Id = b.User_Id
  Order By c.User_Id
