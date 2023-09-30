Create Procedure dbo.spEMPSC_ProductionStatusConfig 
@ListType int, @id1 int, @id2 int, @id3 int, @id4 int, @str1 nvarchar(50)
AS
if @ListType = 1
  begin
    select ProdStatus_Id,prodstatus_desc
     from production_status
  end
else if @ListType = 3
  begin
 	 DECLARE @NotLockable Table (ProdStatus_Id Int,BlockLock Int)
 	 INSERT INTO @NotLockable(ProdStatus_Id,BlockLock)
 	  	 SELECT DISTINCT Default_Event_Status,1 FROM Event_Subtypes where Default_Event_Status Is not null
 	  	 UNION 
 	  	 SELECT DISTINCT Valid_Status,1 FROM PrdExec_Status WHERE Is_Default_Status = 1
    select a.Status_Valid_For_Input,a.Count_For_Production,a.Count_For_Inventory,
 	  	 a.icon_id,a.color_id,a.NoHistory,LockData = isnull(a.LockData,0),BlockLock = coalesce(b.BlockLock,0)
    from production_status a
    Left Join @NotLockable b on b.ProdStatus_Id = a.ProdStatus_Id
      where a.prodstatus_id = @id1
  end
else if @ListType = 4
  begin
    DECLARE @junk2  table  (icon_id int , icon_desc nvarchar(50))
    insert into @junk2 (icon_id, icon_desc) values(0, '<none>')
    insert into @junk2 (icon_id, icon_desc) select icon_id, icon_desc from icons Where donotdelete = 1
    select icon_id,icon_desc from @junk2
  end
else if @ListType = 5
  begin
    DECLARE @junk1 table  (color_id int, color_desc nvarchar(50), color int)
    insert into @junk1 (color_id, color_desc) values(0, '<none>')
    insert into @junk1 (color_id, color_desc) select color_id, color_desc from colors
    select color_id,color_desc,color from @junk1
  end
else if @ListType = 6
  select Color from colors where color_id = @id1
else
  return(100)
