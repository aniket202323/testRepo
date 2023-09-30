CREATE Procedure dbo.spEMEPC_GetInputSources
@Path_Id int,
@PEI_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetInputSources',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@PEI_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select 
  ppis.pu_id, pr.peis_id, puppis.pu_desc, plppis.pl_desc, plppis.pl_id, ppis.pepis_id
  From prdexec_path_input_sources ppis
  Left Outer Join prdexec_input_sources pr on pr.pei_id = ppis.pei_id and pr.pu_id = ppis.pu_id
  Join prod_units puppis on puppis.pu_id = ppis.pu_id
  Join prod_lines plppis on plppis.pl_id = puppis.pl_id
  Where ppis.path_id = @Path_Id and ppis.pei_id = @PEI_Id
Union
Select 
  pr.pu_id, pr.peis_id, pupr.pu_desc, plpr.pl_desc, plpr.pl_id, ppis.pepis_id
  From prdexec_input_sources pr
  Left Outer Join prdexec_path_input_sources ppis on ppis.pei_id = pr.pei_id and ppis.path_id = @Path_Id and ppis.pu_id = pr.pu_id
  Join prod_units pupr on pupr.pu_id = pr.pu_id
  Join prod_lines plpr on plpr.pl_id = pupr.pl_id
  Where pr.pei_id = @PEI_Id and ppis.pepis_id is NULL
  Order By pu_desc
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
