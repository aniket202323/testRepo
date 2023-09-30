CREATE PROCEDURE dbo.spEM_XrefDeleteDataEmail
 	 @DeletedId Int,
 	 @UserId 	  	  Int
  AS
 	 DECLARE @Insert_Id Int 
 	 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	  	 VALUES (1,1,'spEM_XrefDeleteDataEmail',  IsNull(convert(nVarChar(10),@DeletedId),'Null') + ','  + 
 	  	  	  	  	  	  Isnull(Convert(nVarChar(10), @UserId),'Null'),dbo.fnServer_CmnGetDate(getUTCdate()))
 	 select @Insert_Id = scope_identity()
 	 Delete From Email_Group_Xref Where EG_XRef_Id = @DeletedId
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
