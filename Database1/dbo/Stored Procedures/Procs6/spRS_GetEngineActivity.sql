CREATE PROCEDURE dbo.spRS_GetEngineActivity
@EngineName varchar(50) = Null,
@EngineId int = null
 AS
-- Only return the last 200 rows
If @EngineName Is Null
  Begin
    If @EngineId Is Null
      Begin
--        Select * From Report_Engine_Activity Where Time > DateAdd(d, -3, GetDate()) 
        Select top 200 * From Report_Engine_Activity order by time desc
 	  	 --Select top 5* from Report_Engine_Activity order by time desc
      End
    Else
      Begin
--        Select * From Report_Engine_Activity Where Time > DateAdd(d, -3, GetDate()) And Engine_Id = @EngineId
        Select top 200 * From Report_Engine_Activity Where Engine_Id = @EngineId order by time desc
      End
  End
Else
  Begin
--    Select * From Report_Engine_Activity Where Time > DateAdd(d, -3, GetDate()) and Engine_Name = @EngineName
    Select top 200 * From Report_Engine_Activity Where Engine_Name = @EngineName order by time desc
  End
