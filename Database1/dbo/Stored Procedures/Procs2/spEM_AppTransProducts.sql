Create Procedure dbo.spEM_AppTransProducts
  @Trans_Id 	 Int,
  @User_Id 	 Int
  AS
  --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  DECLARE @Insert_Id 	 Int ,
 	       @RetCode 	 Int,
 	       @PU_Id 	 Int,
 	       @Prod_Id 	 Int,
 	       @Is_Delete tinyInt,
 	  	   @CharId 	 Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_AppTransProducts',
 	  Convert(nVarChar(10),@Trans_Id) + ','  + 
 	  Convert(nVarChar(10), @User_Id),
              dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Declare Trans_Cursor Cursor
    For Select PU_Id, Prod_Id,Is_Delete  From Trans_Products Where  Trans_Id  = @Trans_Id
    For Read Only
    Open Trans_Cursor
Next_Trans:
    Fetch Next From Trans_Cursor InTo @PU_Id, @Prod_Id,@Is_Delete
    If @@Fetch_Status = 0 
        Begin
 	 If @Is_Delete = 0 
 	    Begin
 	  	   Create Table #NewPropChars(Prop_Id Int,Char_Id Int,Trans_Id Int,PU_Id Int,Prod_Id Int)
 	  	   Insert into #NewPropChars(Prop_Id,Char_Id,Trans_Id,PU_Id,Prod_Id)
 	  	  	 Select Prop_Id,Char_Id,@Trans_Id, @PU_Id, @Prod_Id
 	  	  	 From Characteristics where Prod_Id = @Prod_Id
 	  	   Insert into #NewPropChars(Prop_Id,Char_Id,Trans_Id,PU_Id,Prod_Id)
 	  	  	 Select Prop_Id,Char_Id,@Trans_Id, @PU_Id, @Prod_Id
 	  	  	 From Product_Characteristic_Defaults c
 	  	  	 where c.Prod_Id = @Prod_Id
 	  	   Delete From #NewPropChars
 	  	  	 From #NewPropChars npc
 	  	  	 Join Trans_Characteristics tc on tc.Prop_Id = npc.Prop_Id and tc.Char_Id = npc.Char_Id and tc.Trans_Id= npc.Trans_Id and tc.PU_Id = npc.PU_Id and tc.Prod_Id = npc.Prod_Id
 	  	   Insert into Trans_Characteristics (Prop_Id,Char_Id,Trans_Id,PU_Id,Prod_Id) 
 	  	  	 Select Distinct Prop_Id,Char_Id,Trans_Id,PU_Id,Prod_Id
 	  	  	 From #NewPropChars
 	  	   Drop Table #NewPropChars
 	       Execute @RetCode = spEM_CreateUnitProd   @PU_Id, @Prod_Id, @User_Id
 	       If @RetCode <> 0 
 	  	   Begin
 	  	     Update  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 1  Where Audit_Trail_Id = @Insert_Id
 	  	     Return(1)
 	  	   End
 	    End
 	 Else
 	    Begin
 	       Execute @RetCode = spEM_DropUnitProd   @PU_Id, @Prod_Id, @User_Id
 	       If @RetCode <> 0 
 	  	 Begin
 	  	    Update  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 1
 	  	       Where Audit_Trail_Id = @Insert_Id
 	  	    Return(1)
 	  	 End
 	    End
 	 GoTo Next_Trans
        End
  Close Trans_Cursor
  Deallocate Trans_Cursor
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
Return (0)
