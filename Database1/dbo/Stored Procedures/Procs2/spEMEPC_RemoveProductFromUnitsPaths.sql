Create  Procedure dbo.spEMEPC_RemoveProductFromUnitsPaths
@ProductId int,
@UnitId int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_RemoveProductFromUnits',
             Convert(nVarChar(10),@ProductId) + ','  + 
             Convert(nVarChar(10),@UnitId) + ','  +
 	      Convert(nVarChar(10),@User_Id) , dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
/*
Delete From PrdExec_Path_Inputs 
  Where PEPI_Id in (
    Select PEPI_Id 
    From PrdExec_Path_Products P
      Join PrdExec_Path_Units U ON P.Path_Id = U.Path_Id 
    Where Prod_Id = @ProductId and PU_Id = @UnitId)
*/
Delete From PrdExec_Path_Products 
  Where PEPP_Id in (Select PEPP_Id From PrdExec_Path_Products P
      Join PrdExec_Path_Units U ON P.Path_Id = U.Path_Id 
    Where Prod_Id = @ProductId and PU_Id = @UnitId)
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
