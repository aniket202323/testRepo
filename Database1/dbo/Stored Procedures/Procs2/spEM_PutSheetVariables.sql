CREATE PROCEDURE dbo.spEM_PutSheetVariables
 	 @Sheet_Id  	 Integer,
 	 @Order 	  	 Integer,
 	 @Id 	  	 Integer,
 	 @Title 	  	 nvarchar(50),
 	 @IsLast 	  	 Bit,
 	 @IsFirst 	 Bit,
 	 @User_Id 	 Integer
 AS
  DECLARE @Insert_Id integer
  DECLARE @Title_Var_Order_Id int
       INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSheetVariables',
                Convert(nVarChar(10),@Sheet_Id) + ','  + 
                Convert(nVarChar(10),@Order) + ','  + 
                Convert(nVarChar(10),@Id) + ','  + 
                	 @Title + ','  + 
                Convert(nVarChar(10),@IsLast) + ','  + 
                Convert(nVarChar(10),@IsFirst) + ','  + 
                 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 IF @IsFirst = 1
 	   Delete Staged_Sheet_Variables where  Sheet_Id = @Sheet_Id
IF @Title Is Null
BEGIN
 	 SELECT @Title_Var_Order_Id = MAX(Var_Order) 
 	  	 FROM Staged_Sheet_Variables 
 	  	 WHERE Title Is Not Null and Sheet_Id = @Sheet_Id
 	 SET @Title_Var_Order_Id = Coalesce(@Title_Var_Order_Id,0)
END
Insert into Staged_Sheet_Variables (Sheet_Id,Var_Order,Var_Id,Title,Title_Var_Order_Id) 
 	 Values (@Sheet_Id,@Order,@Id,@Title,@Title_Var_Order_Id)
If @Islast = 1 
BEGIN
 	   BEGIN TRANSACTION
 	    Begin
      	  Delete From Sheet_Variables Where Sheet_Id = @Sheet_Id
 	      Insert into  Sheet_Variables (Sheet_Id,Var_Order,Var_Id,Title,Title_Var_Order_Id)
    	    Select  Sheet_Id,Var_Order,Var_Id,Title,Title_Var_Order_Id
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
