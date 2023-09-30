CREATE PROCEDURE dbo.spEMEPC_ExecPathConfig_List
@ListType int,
@id1 int,
@id2 int, 
@id3 int,
@id4 int,
@name1 nvarchar(50)
--------------------------------------------------------------------------------------------------------------------------------------------
  ,@User_Id int
  AS
--  DECLARE @Insert_Id integer 
--  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
-- 	 VALUES (1,@User_Id,'spEMPSC_ProductionStatusConfig',
--                Convert(nvarchar(15),@ListType) + ','  + 
--                Convert(nvarchar(15),@id1) + ','  + 
--                Convert(nvarchar(15),@id2) + ','  + 
--                Convert(nvarchar(15),@id3) + ','  + 
--                Convert(nvarchar(15),@id4) + ','  + 
--               @name1 + ',' +
-- 	    Convert(nVarChar(10),@User_Id),
--                dbo.fnServer_CmnGetDate(getUTCdate()))
--  SELECT @Insert_Id = Scope_Identity()
--------------------------------------------------------------------------------------------------------------------------------------------
---LIST1---
if @ListType = 1
  select pl_desc from prod_lines
    where pl_id = @id1
---LIST1---
else if @ListType = 23
    select pu.pu_id, pu.pl_id, pu.pu_desc, pl.pl_desc
    from prod_units pu
      join prod_lines pl  on pl.pl_id = pu.pl_id
      Join Event_Configuration ec On Ec.PU_Id = pu.PU_Id
      Join event_subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
      where (pu.pu_id > 0) and (pu.master_unit is null) and (ec.Event_Subtype_Id = @Id2)
      order by pu.pu_desc
---LIST1---
else if @ListType = 24 	 -- grab all trans of a specific pu and status
  select distinct prodstatus_id, prodstatus_desc from prdexec_trans tr
    join production_status ps on tr.to_prodstatus_id = ps.prodstatus_id
    where tr.pu_id = @id1 and tr.from_prodstatus_id = @id2
    order by prodstatus_desc
---LIST1---
else if @ListType = 30
  select pr.pei_id, pr.input_name, pr.pu_id, pr.input_order, es.event_subtype_desc, pr.event_subtype_id, pr.primary_spec_id, pr.alternate_spec_id, pr.lock_inprogress_input from prdexec_inputs pr
    left outer join event_subtypes es on es.event_subtype_id = pr.event_subtype_id
    where pr.pu_id = @id1
    order by pr.input_order
---LIST1---
else if @ListType = 43 	  	 -- get valid input sources
  select pr.PU_Id,pr.peis_id, pu.pu_desc, pl.pl_desc, pl.pl_id 
    from prdexec_input_sources pr
    join prod_units pu on pu.pu_id = pr.pu_id
    join prod_lines pl on pl.pl_id = pu.pl_id
    where pr.pei_id = @id1
    order by pu.pu_desc
---LIST1---
/*
else if @ListType = 44
  select * from prod_units
    where pl_id <> @id1
    order by pu_desc
*/
---LIST2---
else if @ListType = 49
  select c.prodstatus_id, c.prodstatus_desc from prdexec_input_sources a
    join prdexec_input_source_data b on b.peis_id = a.peis_id 
    join production_status c on c.prodstatus_id = b.valid_status
    where a.pu_id = @id1 and a.pei_id = @id2
---LIST2---
else if @ListType = 50
  select Event_Subtype_Id,Event_Subtype_Desc from event_subtypes where et_id = 1 order by event_subtype_desc
/*
---LIST2---
else if @ListType = 52
  select * from production_status
*/
--ALL---
else
  return(100)
--------------------------------------------------------------------------------------------------------------------------------------------
--  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
--     WHERE Audit_Trail_Id = @Insert_Id
--------------------------------------------------------------------------------------------------------------------------------------------
