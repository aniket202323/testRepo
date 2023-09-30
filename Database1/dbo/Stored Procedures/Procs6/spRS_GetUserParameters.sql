-----------------------------------------------------------------
-- This stored procedure is used by the following applications:
-- ProficyRPTEngine
-- ProficyRPTScheduler
-- Edit the master document in VSS project: ProficyRPTEngine
-----------------------------------------------------------------
CREATE PROCEDURE dbo.spRS_GetUserParameters
@Engine_Id int = Null,
@User_Id int = Null
 AS
--parameters for a user
If @Engine_Id Is Null
  Begin
    Select * 
    From user_Parameters
    Where User_Id = @User_Id
    Order By HostName Asc
  End
Else
  Begin
    -- Parameters for an Engine
    Declare @Service_Name varchar(20)
    Declare @Engine_Name varchar(50)
    Select @Service_Name = Service_Name, @Engine_Name = Engine_Name
    From Report_Engines
    Where Engine_Id = @Engine_Id
    Select @User_Id = User_Id
    From Users
    Where Upper(UserName) = Upper(@Service_Name)
    Select * 
    From User_Parameters
    Where User_Id = @User_Id
    and (HostName = '' or HostName = @Engine_Name)
    ORDER BY Hostname asc
End
