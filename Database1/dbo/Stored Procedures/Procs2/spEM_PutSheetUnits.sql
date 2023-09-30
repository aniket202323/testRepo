CREATE PROCEDURE dbo.spEM_PutSheetUnits
 	 @Sheet_Id  	 Integer,
 	 @Order 	  	 Integer,
 	 @Id 	  	 Integer,
 	 @IsLast 	  	 Bit,
 	 @IsFirst 	 Bit,
 	 @User_Id 	 Integer
 AS
  DECLARE @Insert_Id integer,
 	   @St  	  	 Integer
       INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSheetUnits',
                Convert(nVarChar(10),@Sheet_Id) + ','  + 
                Convert(nVarChar(10),@Order) + ','  + 
                Convert(nVarChar(10),@Id) + ','  + 
                Convert(nVarChar(10),@IsLast) + ','  + 
                Convert(nVarChar(10),@IsFirst) + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
 SELECT @Insert_Id = Scope_Identity()
 Select @ST = Sheet_Type From Sheets where  Sheet_Id = @Sheet_Id
 IF @IsFirst = 1
 	   Delete Staged_Sheet_Variables where  Sheet_Id = @Sheet_Id
  Insert into Staged_Sheet_Variables (Sheet_Id,Var_Order,Var_Id,Title) Values (@Sheet_Id,@Order,@Id,Null)
  If @Islast = 1 
 	 BEGIN
 	   BEGIN TRANSACTION
 	   If @ST in (10,14,8,15,11,27,28,29,30)
 	     Begin
 	       Delete From Sheet_Unit Where Sheet_Id = @Sheet_Id
 	       Insert into  Sheet_Unit (Sheet_Id,PU_Id)
     	   Select  Sheet_Id,Var_Id
 	  	     From Staged_Sheet_Variables where  Sheet_Id = @Sheet_Id
 	     End
 	   Else If @ST  = 17
 	     Begin
 	       Delete From Sheet_Paths Where Sheet_Id = @Sheet_Id
 	       Insert into  Sheet_Paths (Sheet_Id,Path_Id)
     	   Select  Sheet_Id,Var_Id
 	  	     From Staged_Sheet_Variables where  Sheet_Id = @Sheet_Id
 	     End
 	   If @@Error = 0
 	        COMMIT TRANSACTION
 	   Else
 	     BEGIN
 	  	     ROLLBACK TRANSACTION
 	  	     UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 1
 	  	       WHERE Audit_Trail_Id = @Insert_Id
 	  	     Return(1)
 	      END
 	 END
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
