CREATE Procedure dbo.spDAML_TreeChanges
@Threshold DateTime OUTPUT
AS
DECLARE @NextThreshold DATETIME
SET @NextThreshold = GetDate()
Execute spDAML_PlantModelTreeChanges @Threshold
Execute spDAML_ProductTreeChanges @Threshold
--Select sys.object_id as Stored_Procedure_Id, sys.name, sys.modify_date 
--  from sys.procedures sys 
--  where sys.name like 'spLocal_%' and sys.type = 'P'
--union
Select sp.Stored_Procedure_Id as Stored_Procedure_Id, sys.name, sys.modify_date
  from sys.procedures sys 
  join ServiceProvider_Stored_Procedure sp on sp.Stored_Procedure_Name = sys.name
--  where sys.name not like 'spLocal_%' and sys.type = 'P'
  where sys.type = 'P'
order by sys.name
SET @Threshold = @NextThreshold
