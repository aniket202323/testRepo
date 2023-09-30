CREATE Procedure dbo.spEMEPC_GetSchedStatusDetail
@Path_Id int,
@User_Id int,
@PP_Status_Id int = NULL,
@How_Many int = NULL,--tinyint to int
@AutoPromoteFrom_PPStatusId int = NULL,
@AutoPromoteTo_PPStatusId int = NULL,
@Sort_Order tinyint = NULL,
@SortWith_PPStatusId int = NULL,
@DeleteTrans bit = NULL
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetSchedStatusDetail',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PP_Status_Id) + ','  + 
             Convert(nVarChar(10),@How_Many) + ','  + 
             Convert(nVarChar(10),@AutoPromoteFrom_PPStatusId) + ','  + 
             Convert(nVarChar(10),@AutoPromoteTo_PPStatusId) + ','  + 
             Convert(nVarChar(10),@Sort_Order) + ','  + 
             Convert(nVarChar(10),@SortWith_PPStatusId) + ','  + 
             Convert(nVarChar(10),@DeleteTrans), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @PP_Status_Id is NULL
  Begin    
    Select PPS.PP_Status_Desc as 'Status', PPSD.Sort_Order, PPSD.How_Many, PPSD.AutoPromoteFrom_PPStatusId, PPSD.AutoPromoteTo_PPStatusId, PPS.PP_Status_Id, PPSD.SortWith_PPStatusId
    From Production_Plan_Statuses PPS
    Left Outer Join PrdExec_Path_Status_Detail PPSD on PPSD.PP_Status_Id = PPS.PP_Status_Id and PPSD.Path_Id = @Path_Id
    Order By Coalesce(PPSD.Sort_Order, PPS.PP_Status_Id) ASC
  End
Else If @PP_Status_Id is NOT NULL and @Sort_Order is NULL
  Begin
    Select PP_Status_Id, PP_Status_Desc 
    From Production_Plan_Statuses PPS
    Where PP_Status_Id <> @PP_Status_Id
  End
Else If @DeleteTrans is NOT NULL
  Begin
    Delete From PrdExec_Path_Status_Detail
      Where Path_Id = @Path_Id and PP_Status_Id = @PP_Status_Id
    If @DeleteTrans = 0
      Insert Into PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, How_Many, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, Sort_Order, SortWith_PPStatusId) 
        Values (@Path_Id, @PP_Status_Id, @How_Many, @AutoPromoteFrom_PPStatusId, @AutoPromoteTo_PPStatusId, @Sort_Order, @SortWith_PPStatusId)
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
