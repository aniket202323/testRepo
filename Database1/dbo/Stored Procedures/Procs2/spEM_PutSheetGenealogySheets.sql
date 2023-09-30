CREATE PROCEDURE dbo.spEM_PutSheetGenealogySheets
 	 @Sheet_Id  	   Integer,
 	 @PU_Id 	  	   Integer,
 	 @Display_Sheet_Id Integer,
 	 @User_Id 	   Integer
 AS
  DECLARE @Insert_Id integer
       INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSheetGenealogySheets',
                Convert(nVarChar(10),@Sheet_Id) + ','  + 
                Convert(nVarChar(10),@PU_Id) + ','  + 
                Coalesce(Convert(nVarChar(10),@Display_Sheet_Id),'null') + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Delete From Sheet_Genealogy_Data where  Sheet_Id = @Sheet_Id and PU_Id = @PU_Id
  IF @Display_Sheet_Id Is Not Null
     Insert into Sheet_Genealogy_Data (Sheet_Id,PU_Id,Display_Sheet_Id)
 	 Values (@Sheet_Id,@Pu_Id,@Display_Sheet_Id)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
