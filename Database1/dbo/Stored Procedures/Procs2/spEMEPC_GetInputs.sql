CREATE Procedure dbo.spEMEPC_GetInputs
@PU_Id int,
@Path_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetInputs',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select pr.pei_id, pr.input_name, pr.pu_id, pr.input_order, 
  Case When ppi.pepi_id is NOT NULL Then esppi.event_subtype_desc Else espr.event_subtype_desc End as event_subtype_desc, 
  Case When ppi.pepi_id is NOT NULL Then ppi.event_subtype_id Else pr.event_subtype_id End as event_subtype_id, 
  Case When ppi.pepi_id is NOT NULL Then ppi.primary_spec_id Else pr.primary_spec_id End as primary_spec_id, 
  Case When ppi.pepi_id is NOT NULL Then ppi.alternate_spec_id Else pr.alternate_spec_id End as alternate_spec_id, 
  Case When ppi.pepi_id is NOT NULL Then ppi.lock_inprogress_input Else pr.lock_inprogress_input End as lock_inprogress_input, 
  ppi.hide_input, ppi.allow_manual_movement, ppi.pepi_id
From prdexec_inputs pr
Join prod_units pu on pu.pu_id = pr.pu_id
Left Outer Join prdexec_paths pp on pp.pl_id = pu.pl_id and pp.path_id = @Path_Id
Left Outer Join prdexec_path_inputs ppi on ppi.pei_id = pr.pei_id and ppi.path_id = pp.path_Id
Left Outer Join event_subtypes esppi on esppi.event_subtype_id = ppi.event_subtype_id
Left Outer Join event_subtypes espr on espr.event_subtype_id = pr.event_subtype_id
Where pr.pu_id = @PU_Id
Order By pr.input_order
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
