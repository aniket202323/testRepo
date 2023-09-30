/* This sp is called by dbo.spBatch_ProcessProcedureReport parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_PutTransProduct
  @Trans_Id 	 int,
  @Prod_Id 	 int,
  @Unit_Id 	 int,
  @IsDelete       bit,
  @User_Id    	 int
  AS
  --
  -- Declare local variables.
  --
DECLARE @Insert_Id 	 Integer, 
  	 @Id 	  	 Integer,
 	 @CurrentId 	 Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutTransProduct',
                Convert(nVarChar(10),@Trans_Id) + ','  + 
                Convert(nVarChar(10),@Prod_Id) + ','  + 
                Convert(nVarChar(10),@Unit_Id) + ','  + 
                Convert(nVarChar(10),@IsDelete) + ','  + 
                Convert(nVarChar(10),@User_id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  Select @Insert_Id = Scope_Identity()
  Select @CurrentId = Null,@Id = Null
  Select @CurrentId = Prod_Id From PU_Products Where Prod_Id = @Prod_Id and PU_Id = @Unit_Id
  SELECT @Id = Trans_Id From Trans_Products
 	 WHERE Trans_Id = @Trans_Id and Prod_Id = @Prod_Id and  PU_Id = @Unit_Id
  If @IsDelete = 1
 	 Delete Trans_Characteristics Where Trans_Id = @Trans_Id and Prod_Id = @Prod_Id and  PU_Id = @Unit_Id
 Delete From  Trans_Products Where Trans_Id = @Trans_Id and Prod_Id = @Prod_Id and PU_Id = @Unit_Id
 IF @CurrentId IS NULL 
     BEGIN
 	 If  @IsDelete = 0
 	   Begin
 	     Insert Into Trans_Products(Trans_Id, Prod_Id,PU_Id,Is_Delete) Values(@Trans_Id,@Prod_Id,@Unit_Id,@IsDelete)
 	  	 Insert Into Trans_Characteristics (Prop_Id,Char_Id,Trans_Id,PU_Id,Prod_Id) 
 	  	    Select Prop_Id,Char_Id,@Trans_Id, @Unit_Id, Prod_Id
 	  	  	 From Product_Characteristic_Defaults c
 	  	  	 where c.Prod_Id = @Prod_Id
 	   End
     END
  ELSE
     BEGIN
 	 If  @IsDelete = 1
 	   Begin
 	     Insert Into Trans_Products(Trans_Id, Prod_Id,PU_Id,Is_Delete) Values(@Trans_Id,@Prod_Id,@Unit_Id,@IsDelete)
 	   End
     END
  --
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
