/* Must Keep in sync with dbo.spBatch_ProcessProcedureReport */
CREATE PROCEDURE dbo.spEMEPC_ExecPathConfig_TableMod
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
DECLARE @LockedFrom Int
DECLARE @LockedTo Int
---UPDATE1---
if @ListType = 10
  insert into prdexec_status
    (pu_id, step, valid_status)
    values(@id1, @id2, null)
---UPDATE1---
else if @ListType = 11
  begin
    delete from prdexec_status
      where pu_id = @id1
    delete from prdexec_trans
      where pu_id = @id1
  end
---UPDATE1---
else if @ListType = 12
  update prdexec_status
    set step = @id2
      where pu_id = @id1
---UPDATE1---
else if @ListType = 20
  insert into prdexec_status
    (pu_id, step, valid_status)
    values(@id1, @id2, @id3)
else if @ListType = 23
  Begin
 	 Declare @CurentStatus TinyInt
 	 Select @CurentStatus = Is_Default_Status From prdexec_status Where  PU_Id = @id1 and valid_status = @id2
 	 Update prdexec_status set Is_Default_Status = null where PU_Id = @id1
 	 If @CurentStatus = 0  or @CurentStatus is null
 	  	 Update prdexec_status set Is_Default_Status = 1 where  PU_Id = @id1 and valid_status = @id2
  End
---UPDATE1---
else if @ListType = 25
BEGIN
  -- if there is no row in prdexec_trans where pu_id = @id1 and from_prodstatus_id = @id2 and to_prodstatus_id = @id3
  IF @id2 <> @id3
 	   insert into prdexec_trans
 	  	 (pu_id, from_prodstatus_id, to_prodstatus_id)
 	  	 values(@id1, @id2, @id3)
END
---UPDATE1---
else if @ListType = 26
  delete from prdexec_trans
    where pu_id = @id1 and  from_prodstatus_id = @id2 and to_prodstatus_id = @id3
---UPDATE1---
else if @ListType = 42
  begin
    if (Select Count(*) From PrdExec_Inputs Where Input_Name = @name1 and PU_Id = @id3 and PEI_Id <> @id1) > 0
      Begin
        Select -100 as 'ReturnCode'
        update prdexec_inputs
          set input_order = @id2, event_subtype_id = @id4
          where pei_id = @id1
        Return
      End
    else
      Select 100 as 'ReturnCode'
  update prdexec_inputs
    set input_order = @id2, event_subtype_id = @id4, input_name = @name1
    where pei_id = @id1
  end
---UPDATE1---
else if @ListType = 45
  begin
    insert into prdexec_input_sources
      (pei_id, pu_id)
      values(@id2, @id1)
    select peis_id = Scope_Identity()
  end
---UPDATE2---
else if @ListType = 46
  begin
    delete prdexec_input_source_data
      from prdexec_input_source_data pr
        join prdexec_input_sources ps on ps.peis_id = pr.peis_id
          where ps.pei_id = @id2 and ps.pu_id = @id1
    delete from prdexec_input_sources
      where pu_id = @id1 and pei_id = @id2
  end
---UPDATE1---
else if @ListType = 47
  insert into prdexec_input_source_data
    (peis_id, valid_status)
    values(@id1, @id2)
---UPDATE1---
else if @ListType = 48
  delete from prdexec_input_source_data
    where peis_id = @id1 and valid_status = @id2
---UPDATE1---
else if @ListType = 49
    if @id3 = 0
      insert into prdexec_input_source_data (peis_id, valid_status)
        select @id2, pp.valid_status 
        from prdexec_status pp
        join production_status ps on ps.ProdStatus_Id = pp.valid_status
        where pp.pu_id = @id1
        and ps.status_valid_for_input = 1
    else
      insert into prdexec_input_source_data (peis_id, valid_status)
        select @id2, pisd.valid_status 
        from prdexec_input_source_data pisd
        join prdexec_status pp on pp.valid_status = pisd.valid_status
        where peis_id = @id3
        and pp.pu_id = @id1
---UPDATE1---
else if @ListType = 51
  begin
    update prdexec_inputs
      set input_order = @id2
      where pei_id = @id1
    update prdexec_inputs
      set input_order = @id4
      where pei_id = @id3
  end
---UPDATE1---
else if @ListType = 53
  begin
    if @id2 = 0
      select @id2 = NULL
    if @id3 = 0
      select @id3 = NULL
    update prdexec_inputs
      set primary_spec_id = @id2, alternate_spec_id = @id3, lock_inprogress_input = @id4
      where pei_id = @id1
  end
---UPDATE2---
else if @ListType = 96
BEGIN
   declare @dead_position int
    select  @dead_position = step from prdexec_status where pu_id = @id1
    update prdexec_status set step = step - 1 where step > @dead_position
 	 DELETE FROM PrdExec_Path_Inputs WHERE PEI_Id IN (select Pei_Id from prdexec_inputs where pu_id = @id1)
    DELETE from PrdExec_Path_Input_Source_Data where PEPIS_Id in (select PEPIS_Id from PrdExec_Path_Input_Sources where pei_id in (select pei_id from prdexec_inputs where pu_id = @id1))
    DELETE from PrdExec_Path_Input_Source_Data where PEPIS_Id in (select PEPIS_Id from PrdExec_Path_Input_Sources where PU_Id =@id1)
    DELETE from PrdExec_Path_Input_Sources where pei_id in (select Pei_Id from prdexec_inputs where pu_id = @id1)
    DELETE from PrdExec_Path_Input_Sources where PU_Id =@id1
    DELETE from prdexec_input_source_data where peis_id in (select peis_id from prdexec_input_sources where pei_id in (select pei_id from prdexec_inputs where pu_id = @id1))
    DELETE from prdexec_input_sources where pei_id in (select pei_id from prdexec_inputs where pu_id = @id1)
 	 DELETE FROM PrdExec_Input_Event WHERE PEI_Id in (select pei_id from prdexec_inputs where pu_id = @id1)
    Update Sheets  Set  pei_id = Null where pei_id in (select pei_id from prdexec_inputs where pu_id = @id1)
    Update Variables_Base Set  pei_id = Null where pei_id in (select pei_id from prdexec_inputs where pu_id = @id1)
    DELETE from prdexec_inputs where pu_id = @id1
    DELETE from prdexec_trans where pu_id = @id1
    DELETE from prdexec_status where pu_id = @id1
END
---UPDATE1---
else if @ListType = 97
  begin
 	 SELECT  @LockedFrom = COALESCE(LockData,0) from Production_Status WHERE ProdStatus_Id = @id2
 	 SELECT  @LockedTo = COALESCE(LockData,0) from Production_Status WHERE ProdStatus_Id = @id3
 	 IF NOT (@LockedFrom = 1 and  @LockedTo = 0)
 	  	 insert into prdexec_trans (pu_id, from_prodstatus_id, to_prodstatus_id) values (@id1, @id2, @id3)
 	 IF NOT (@LockedTo = 1 and  @LockedFrom = 0)
 	  	 insert into prdexec_trans(pu_id,  from_prodstatus_id, to_prodstatus_id) values (@id1, @id3, @id2)
  end
---UPDATE1---
else if @ListType = 98
  begin
    if (select count(*) from prdexec_status where pu_id = @id1) > 0 
      update prdexec_status set step = @id2, valid_status = null where pu_id = @id1
    else
      insert into prdexec_status (pu_id, step, valid_status) values(@id1, @id2, null)
  end
--ALL---
else
  return(100)
--------------------------------------------------------------------------------------------------------------------------------------------
--  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
--     WHERE Audit_Trail_Id = @Insert_Id
--------------------------------------------------------------------------------------------------------------------------------------------
