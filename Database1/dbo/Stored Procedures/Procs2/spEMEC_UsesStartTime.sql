CREATE PROCEDURE dbo.spEMEC_UsesStartTime
@PU_Id int,
@User_Id int,
@Uses_Start_Time tinyint OUTPUT,
@Chain_Start_Time tinyint OUTPUT
AS
DECLARE @Insert_Id integer 
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
VALUES (1,@User_Id,'spEMEC_UsesStartTime',
              Convert(nVarChar(10),@PU_Id) + ','  + 
              Convert(nVarChar(10),@User_Id) + ','  + 
              Convert(nVarChar(10),@Uses_Start_Time) + ','  + 
              Convert(nVarChar(10),@Chain_Start_Time),dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @Uses_Start_Time is NULL
  Select @Uses_Start_Time = IsNull(Uses_Start_Time,0), @Chain_Start_Time = ISNULL(Chain_Start_Time,1) From Prod_Units Where PU_Id = @PU_Id
Else 
  Update Prod_Units Set Uses_Start_Time = @Uses_Start_Time, Chain_Start_Time = @Chain_Start_Time Where PU_Id = @PU_Id 
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
   WHERE Audit_Trail_Id = @Insert_Id
