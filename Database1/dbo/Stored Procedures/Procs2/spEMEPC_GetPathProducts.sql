CREATE Procedure dbo.spEMEPC_GetPathProducts
@Path_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetPathProducts',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select P.Prod_Desc as 'Prod Desc', P.Prod_Code as 'Prod Code', PPP.Prod_Id, PPP.PEPP_Id
From PrdExec_Path_Products PPP
Join Products P on P.Prod_Id = PPP.Prod_Id
Where Path_Id = @Path_Id
Order By P.Prod_Desc ASC, P.Prod_Code ASC
Select P.Prod_Desc as 'Prod Desc', P.Prod_Code as 'Prod Code', PUP.Prod_Id, PUP.PU_Id
From PU_Products PUP
Join Products P on P.Prod_Id = PUP.Prod_Id
Join PrdExec_Path_Units PEPU on PEPU.Path_Id = @Path_Id and PEPU.Is_Schedule_Point = 1
Where PEPU.Path_Id = @Path_Id
And PUP.PU_Id = PEPU.PU_Id
And PUP.Prod_Id NOT IN (Select Prod_Id From PrdExec_Path_Products Where Path_Id = @Path_Id)
Order By P.Prod_Desc ASC, P.Prod_Code ASC
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
