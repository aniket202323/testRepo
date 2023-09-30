CREATE PROCEDURE dbo.spRS_AddReportEngine
@EngineName varchar(50),
@ServiceName varchar(20),
@EngineId int output
 AS
Select @EngineId = Engine_Id
From Report_Engines
Where Engine_Name = @EngineName
and Service_Name = @ServiceName
If @EngineId Is Null -- add new engine
  Begin
    Insert Into Report_Engines(Engine_Name, Service_Name) 
    Values(@EngineName, @ServiceName)
    Select @EngineId = Scope_Identity()
    Return (0)  -- Insert was ok
  End
Else
  Begin
    Return (1) -- Enging already exists
  End
