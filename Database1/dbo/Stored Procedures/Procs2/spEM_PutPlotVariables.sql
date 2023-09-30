CREATE PROCEDURE dbo.spEM_PutPlotVariables
 	 @Sheet_Id  	 Integer,
 	 @PlotType 	 Integer,
 	 @VarId1 	  	 Integer,
 	 @VarId2 	  	 Integer,
 	 @VarId3 	  	 Integer,
 	 @VarId4 	  	 Integer,
 	 @VarId5 	  	 Integer,
 	 @PlotOrder 	 Integer,
 	 @IsLast 	  	 Bit,
 	 @IsFirst 	 Bit,
 	 @User_Id 	 Integer
 AS
  DECLARE @Insert_Id integer
       INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutPlotVariables',
                Convert(nVarChar(10),@Sheet_Id) + ','  + 
                Convert(nVarChar(10),@PlotType) + ','  + 
                Coalesce(Convert(nVarChar(10),@VarId1),'null') + ','  + 
                Coalesce(Convert(nVarChar(10),@VarId2),'null') + ','  + 
                Coalesce(Convert(nVarChar(10),@VarId3),'null') + ','  + 
                Coalesce(Convert(nVarChar(10),@VarId4),'null') + ','  + 
                Coalesce(Convert(nVarChar(10),@VarId5),'null') + ','  + 
 	  	 Convert(nVarChar(10),@PlotOrder) + ','  + 
                Convert(nVarChar(10),@IsLast) + ','  + 
                Convert(nVarChar(10),@IsFirst) + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  IF @IsFirst = 1
 	   Delete Staged_Plot_Variables where  Sheet_Id = @Sheet_Id
  Insert into Staged_Plot_Variables (Sheet_Id,SPC_Trend_Type_Id,Var_Id1,Var_Id2,Var_Id3,Var_Id4,Var_Id5,Plot_Order)
 	 Values (@Sheet_Id,@PlotType,@VarId1,@VarId2,@VarId3,@VarId4,@VarId5,@PlotOrder)
  If @Islast = 1 
 	 BEGIN
 	   BEGIN TRANSACTION
 	    Begin
      	      Delete From Sheet_Plots Where Sheet_Id = @Sheet_Id
 	      Insert into  Sheet_Plots (Sheet_Id,Var_Id1,Var_Id2,Var_Id3,Var_Id4,Var_Id5,SPC_Trend_Type_Id,Plot_Order)
 	  	 Select  Sheet_Id,Var_Id1,Var_Id2,Var_Id3,Var_Id4,Var_Id5,SPC_Trend_Type_Id,Plot_Order
 	  	  From Staged_Plot_Variables where  Sheet_Id = @Sheet_Id
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
