CREATE PROCEDURE dbo.spEM_PutTransCharacteristics2
  @Trans_Id int,
  @PU_Id     int,
  @Prod_Id   int,
  @Prop_Id   int,
  @Char_Id   int,
  @User_Id   int
  AS
  --
  -- Declare local variables.
  --
DECLARE @Insert_Id  	  	 Integer, 
 	 @Id            	  	 Integer,
 	 @CharExistsId 	  	 Integer,
 	 @ProductTrans 	  	 Int,
 	 @CurrentProdId 	  	 Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutTransCharacteristics2',
               Convert(nVarChar(10),@Trans_Id) + ','  + 
                Convert(nVarChar(10),@PU_Id) + ','  + 
                Convert(nVarChar(10),@Prop_Id) + ','  + 
                Convert(nVarChar(10),@Prod_Id) + ','  + 
                Convert(nVarChar(10),@Char_Id) + ','  + 
                Convert(nVarChar(10),@User_id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  -- Try to find a matching transaction.
  --
  Select @Id = Null,@ProductTrans = null,@CurrentProdId = Null,@CharExistsId = Null
  SELECT @Id = Trans_Id 
    FROM Trans_Characteristics
    WHERE (Trans_Id = @Trans_Id) AND (PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id) AND (Prop_Id = @Prop_Id)
  Select @CharExistsId = Char_Id
 	 From pu_Characteristics 
 	 Where(PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id) AND (Prop_Id = @Prop_Id)
  Select @ProductTrans = Is_Delete 
    FROM Trans_Products
    WHERE (Trans_Id = @Trans_Id) AND (PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id)
  Select @CurrentProdId = Prod_Id 
    From PU_Products 
    Where (PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id)
  If ((@ProductTrans is null) and (@CurrentProdId is Null)) or (@ProductTrans = 1)
   Begin
      Delete From  Trans_Characteristics
      WHERE Trans_Id = @Id AND (PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id) AND (Prop_Id = @Prop_Id)
      RETURN(0)
   End
  --
  -- If a matching transaction variable was found, update it. Otherwise,
  -- insert a new transaction variable. In the special case where all the
  -- limits are null, delete any transaction variable we find.
  --
  IF @Id IS NULL and @CharExistsId is Null
    INSERT INTO Trans_Characteristics(Trans_Id, PU_Id, Prop_Id,Prod_Id, Char_Id)
       VALUES(@Trans_Id, @PU_Id, @Prop_Id,@Prod_Id, @Char_Id)
  ELSE
    Begin
       If (@Char_Id is null And @CharExistsId Is Null) or (@CharExistsId = @Char_Id)
        Delete From  Trans_Characteristics
          WHERE Trans_Id = @Id AND (PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id) AND (Prop_Id = @Prop_Id)
      Else
 	  	  	 If @Id IS Not NULL
          	 Update  Trans_Characteristics set Char_Id = @Char_Id
           	 WHERE Trans_Id = @Id AND (PU_Id = @PU_Id) AND (Prod_Id = @Prod_Id) AND (Prop_Id = @Prop_Id)
 	  	  	 Else
     	  	  	 INSERT INTO Trans_Characteristics(Trans_Id, PU_Id, Prop_Id,Prod_Id, Char_Id) VALUES(@Trans_Id, @PU_Id, @Prop_Id,@Prod_Id, @Char_Id)
    End
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
