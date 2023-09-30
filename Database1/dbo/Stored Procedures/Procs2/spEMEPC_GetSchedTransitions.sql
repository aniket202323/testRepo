CREATE Procedure dbo.spEMEPC_GetSchedTransitions
@Path_Id int,
@User_Id int,
@From_PPStatus_Id int = NULL,
@To_PPStatus_Id int = NULL,
@DeleteTrans bit = NULL
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetSchedTransitions',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@From_PPStatus_Id) + ','  + 
             Convert(nVarChar(10),@To_PPStatus_Id) + ','  + 
             Convert(nVarChar(10),@DeleteTrans), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @From_PPStatus_Id is NULL
  Select PP_Status_Id, PP_Status_Desc 
  From Production_Plan_Statuses 
  Order By PP_Status_Desc
Else If @From_PPStatus_Id is NOT NULL and @To_PPStatus_Id is NULL
  Select ppss.PP_Status_Id, ppss.PP_Status_Desc
  From Production_Plan_Status pps
  Join Production_Plan_Statuses ppss on ppss.PP_Status_Id = pps.To_PPStatus_Id
  Where pps.Path_Id = @Path_Id and pps.From_PPStatus_Id = @From_PPStatus_Id
  Order By ppss.PP_Status_Desc
Else If @DeleteTrans = 0
  Insert Into Production_Plan_Status
    (Path_Id, From_PPStatus_Id, To_PPStatus_Id)
    values(@Path_Id, @From_PPStatus_Id, @To_PPStatus_Id)
Else If @DeleteTrans = 1
  Delete From Production_Plan_Status
    Where Path_Id = @Path_Id and From_PPStatus_Id = @From_PPStatus_Id and To_PPStatus_Id = @To_PPStatus_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
