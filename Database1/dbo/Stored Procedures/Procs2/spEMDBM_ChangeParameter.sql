CREATE PROCEDURE dbo.spEMDBM_ChangeParameter
 	 @hostname nVarChar(100)
  AS
If @hostname <> ''
 	 Insert into site_Parameters(Parm_Id,Hostname,value) Values (82,'',@hostname)
Else
 	 Delete From site_Parameters where Parm_Id = 82
