CREATE Procedure dbo.spEMEPC_GetInputStatuses
@PU_Id int,
@PEI_Id int,
@Path_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetInputStatuses',
             Convert(nVarChar(10),@PU_Id) + ','  +
             Convert(nVarChar(10),@PEI_Id) + ','  +
             Convert(nVarChar(10),@Path_Id) + ','  +  
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If (Select Count(*) From prdexec_path_input_sources where pu_id = @PU_Id and pei_id = @PEI_Id and path_id = @Path_Id) > 0
  Select Distinct
    cppisd.prodstatus_id, cppisd.prodstatus_desc
    From prdexec_path_input_sources ppis
    Left Outer Join prdexec_path_input_source_data ppisd on ppisd.pepis_id = ppis.pepis_id
    Left Outer Join production_status cppisd on cppisd.prodstatus_id = ppisd.valid_status
    Where ppis.pei_id = @PEI_Id
    And ppis.path_id = @Path_Id
    And ppis.pu_id = @PU_Id
Else
  Select Distinct
    cpisd.prodstatus_id, cpisd.prodstatus_desc
    From prdexec_input_sources pis
    Join prdexec_input_source_data pisd on pisd.peis_id = pis.peis_id 
    Join production_status cpisd on cpisd.prodstatus_id = pisd.valid_status
    Left Outer Join prdexec_path_input_sources ppis on ppis.pei_id = pis.pei_id And ppis.path_id = @Path_Id and ppis.pu_id = @PU_Id
    Left Outer Join prdexec_path_input_source_data ppisd on ppisd.pepis_id = ppis.pepis_id and ppisd.pepisd_id is NULL
    Where pis.pei_id = @PEI_Id and ppisd.pepisd_id is NULL
    Order By prodstatus_desc ASC
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
