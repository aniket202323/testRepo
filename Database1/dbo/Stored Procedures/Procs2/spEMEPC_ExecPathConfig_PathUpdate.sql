CREATE PROCEDURE dbo.spEMEPC_ExecPathConfig_PathUpdate
@ListType int,
@id1 int,
@id2 int, 
@id3 int,
@id4 int,
@name1 nvarchar(50),
@id5 int = NULL,
@User_Id int,
@id6 int = NULL
AS
Declare @etid int, @etdesc nvarchar(50), @puid int
---UPDATE2---
if @ListType = 21
  begin
    delete from prdexec_status
      where pu_id = @id1 and valid_status = @id2
    delete prdexec_input_source_data
      from prdexec_input_source_data pr
        join prdexec_input_sources ps on ps.peis_id = pr.peis_id
          join prdexec_inputs pd on pd.pei_id = ps.pei_id
            where pd.pu_id = @id1 and pr.valid_status = @id2
    delete from prdexec_trans
      where pu_id = @id1 and (from_prodstatus_id = @id2 or to_prodstatus_id = @id2)
  end
---UPDATE1---
else if @ListType = 40
  begin
    if (Select Count(*) From PrdExec_Inputs Where Input_Name = @name1 and PU_Id = @id2) > 0
      Begin
        Select -100 as 'ReturnCode'
        Return
      End
    else
      Select 100 as 'ReturnCode'
    if @id4 = 0
      select @id4 = NULL
    if @id5 = 0
      select @id5 = NULL
    insert into prdexec_inputs
      (input_name, input_order, pu_id, event_subtype_id, primary_spec_id, alternate_spec_id, lock_inprogress_input)
      values(@name1, @id1, @id2, @id3, @id4, @id5, @id6)
    select pr.input_order,pr.input_name,es.Event_Subtype_Desc,pr.pei_id,
    pr.Event_SubType_Id,pr.Primary_Spec_Id,pr.Alternate_Spec_Id,pr.Lock_Inprogress_Input
      from prdexec_inputs pr
      join event_subtypes es on es.event_subtype_id = pr.event_subtype_id
      where pei_id = Scope_Identity()
  end 
---UPDATE2---
else if @ListType = 41
  begin
    declare @dead_position int, @pu_id int,@Rows int,@EcId Int
    delete prdexec_input_source_data
      from prdexec_input_source_data pr
        join prdexec_input_sources ps on ps.peis_id = pr.peis_id
          where ps.pei_id = @id1
    delete from prdexec_input_sources
        where pei_id = @id1
    select @pu_id = pu_id, @dead_position = input_order from prdexec_inputs where pei_id = @id1
    update prdexec_inputs set input_order = input_order - 1 where pu_id = @pu_id and input_order > @dead_position
-- Clean up event Configuration
    Declare ec cursor for 
 	 select Ec_Id from event_Configuration where  PEI_Id = @id1
    Open ec
    EcLoop:
    Fetch Next From Ec into @EcID
    If @@Fetch_Status = 0
      Begin
 	 Execute spEMEC_DeleteEC @EcID,2,1,@Rows  OUTPUT
 	 GoTo EcLoop
      End
    Close ec
    Deallocate ec
    Delete From prdexec_input_event Where PEI_Id = @id1
    Delete From prdexec_input_event_History Where PEI_Id = @id1
    Update Sheets Set pei_id = null ,Is_Active = 0 where pei_id = @id1
    Update Variables_Base Set pei_id = null where pei_id = @id1
    DELETE FROM PrdExec_Path_Inputs where pei_id = @id1
    Delete from prdexec_inputs where pei_id = @id1
  end
else
  return(100)
--------------------------------------------------------------------------------------------------------------------------------------------
--  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
--     WHERE Audit_Trail_Id = @Insert_Id
--------------------------------------------------------------------------------------------------------------------------------------------
