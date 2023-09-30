CREATE PROCEDURE dbo.spEMEPC_ExecPathConfig_Path
@ListType int,
@id1 int,
@id2 int, 
@id3 int,
@id4 int,
@name1 nvarchar(50),
@id5 int = NULL,
--------------------------------------------------------------------------------------------------------------------------------------------
@User_Id int,
@id6 int = NULL
  AS
declare @etid int, @etdesc nvarchar(50), @puid int
--Get #1
if @ListType = 2
begin
/* Step is used to determine if unit is asscoiated */
  DECLARE  @Units TABLE(pu_id int, pu_desc nvarchar(50), et_id int Null, et_desc nvarchar(20) Null, step int Null,PU_Order int Null)
  insert into @Units (pu_id, pu_desc, step,PU_Order) 
    select distinct a.pu_id, a.pu_desc,[Step] = case When b.pu_id is null then Null
 	  	  	  	  	  	 Else 1
 	  	  	  	  	  	 End ,coalesce(a.PU_Order,-1)
     from prod_units a 
     left  join prdexec_status b on a.pu_id = b.pu_id
      where (a.master_unit is null) and (a.pu_id > 0) and (a.pl_id = @id1)
  declare tmp_cur insensitive cursor 
    for (select a.et_id, b.et_desc, a.pu_id from event_configuration a
           join event_types b on a.et_id = b.et_id) 
    for read only
  open tmp_cur
  fetch next from tmp_cur into @etid, @etdesc, @puid
  loop:
    if(@@fetch_status = 0)
    begin
      update @Units set et_id = 0 where (pu_id = @puid) and (et_id <> 1) and (@etid <> 1)
      update @Units set et_id = 1 where (pu_id = @puid) and (@etid = 1)
      update @Units set et_desc = @etdesc where (et_id = @etid)
      fetch next from tmp_cur into @etid, @etdesc, @puid
      goto loop
    end
  close tmp_cur
  deallocate tmp_cur
  update @Units set et_id = 0, et_desc = '<none>' 
 	 where et_id is null
  select pu_id, pu_desc, et_id, et_desc, step,PU_Order 
 	 from @Units 
 	 order by PU_Order,pu_desc
end
--- Get #2
else if @ListType = 22  	 -- get valid statuses for a prod unit
  begin
 	 DECLARE @Statuses Table(prodstatus_id int, valid_status int, prodstatus_desc nvarchar(50), icon_id int NULL, color_desc nvarchar(50),
 	  	  	  	  	  	  	  color_id int, goodbad tinyint,Is_Default_Status TinyInt, Count_For_Inventory tinyint, Count_For_Production tinyint,
 	  	  	  	  	  	  	  LockData Int)
    INSERT INTO @Statuses(prodstatus_id,valid_status,prodstatus_desc,icon_id,color_desc,color_id,goodbad,Is_Default_Status,Count_For_Inventory,Count_For_Production,LockData)
 	  	 SELECT prodstatus_id, valid_status, prodstatus_desc, ps.icon_id, color_desc, co.color_id, ps.status_valid_for_input, Coalesce(pes.Is_Default_Status,0), Count_For_Inventory, Count_For_Production,Coalesce(LockData,0) 
 	  	  from production_status ps
 	  	    left outer join prdexec_status pes on ps.prodstatus_id = pes.valid_status and pes.pu_id = @Id1
 	  	    left outer join colors co        on co.color_id = ps.color_id
    update @Statuses
       set icon_id = null 
       where  icon_id iN (select icon_iD from icons i where iCON is null)
    SELECT prodstatus_id,valid_status,prodstatus_desc,icon_id,color_desc,color_id,goodbad,Is_Default_Status,Count_For_Inventory,Count_For_Production,LockData
 	  	  FROM @Statuses order by prodstatus_desc
  end
--ALL---
else
  return(100)
--------------------------------------------------------------------------------------------------------------------------------------------
--  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
--     WHERE Audit_Trail_Id = @Insert_Id
--------------------------------------------------------------------------------------------------------------------------------------------
