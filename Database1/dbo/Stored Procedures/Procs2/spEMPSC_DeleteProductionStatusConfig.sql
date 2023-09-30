Create Procedure dbo.spEMPSC_DeleteProductionStatusConfig 
@id1 int, @id2 int, @id3 int, @id4 int, @str1 nvarchar(50)
AS
  delete from production_status where prodstatus_id = @id1
