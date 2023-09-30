Create Procedure dbo.spEM_AppTransInValidation
 	 @Trans_Id int,
 	 @User_Id  int
 AS
  Declare @Char_Id 	 int,
 	   @TransId 	 int,
 	   @PU_Id 	 int,
               @Is_Delete 	 TinyInt,
 	   @Prod_Id 	 int,
 	   @Insert_Id 	 int,
 	   @SkipPUProd  Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_AppTransInValidation',
 	  Convert(nVarChar(10),@Trans_Id) + ','  + 
 	  Convert(nVarChar(10), @User_Id),
              dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Create Table #CharIds(Char_Id int)
  Create Table #CharId1(Char_Id int)
  Create Table #CharId2(Char_Id int)
  Create Table #Prods(PU_Id Int,Prod_Id int,Char_Id Int)
  Create Table #PUProds(PU_Id Int,Prod_Id int,Is_Delete tinyInt)
 -- Products
  Insert Into #Prods Select Pu_Id,Prod_Id,Char_Id From Trans_Characteristics Where Trans_Id = @Trans_Id
  Insert Into #PUProds Select Pu_Id,Prod_Id,Is_Delete From Trans_Products Where Trans_Id = @Trans_Id
  Insert into #CharIds Select From_Char_Id From Trans_Char_Links Where Trans_Id = @Trans_Id
  Insert into #CharId1 Select From_Char_Id From Trans_Char_Links Where Trans_Id = @Trans_Id
-- Collect branches below this point
Loop:
Insert Into #CharId2  Select Char_Id from Characteristics Where Derived_From_Parent in(Select Char_Id from #CharId1)
If @@Rowcount <> 0 
   BEGIN
 	 Insert Into #CharIds Select * From #CharId2
 	 Delete From #CharId1
 	 Insert Into #CharId1 Select * From #CharId2
 	 Delete From #CharId2
 	 GOTO Loop
   END
Drop Table #CharId1
Drop Table #CharId2
  Declare T_Cursor  Cursor
   For Select Trans_Id  From Transactions Where  Approved_by is Null and Trans_Type_Id <> 4 And Trans_Id <> @Trans_Id
   For Update
   Open T_Cursor
NextTran1:
   Select @SkipPUProd = Null
   Fetch Next From T_Cursor InTo @TransId
   If @@Fetch_Status = 0 
        Begin
 	 Update Trans_Char_Links set Validation_Trans_Id =  @Trans_Id Where (From_Char_Id in(Select Char_Id from #CharIds)  or To_Char_Id in(Select Char_Id from #CharIds) )and Trans_Id =  @TransId
 	   If @@Rowcount > 0 
 	    Begin
 	  	 Update Transactions set Trans_Type_Id = 4 Where current of T_Cursor
 	  	 GoTo NextTran1
 	    End
 	    Execute( 'Declare Prod_Cursor  Cursor Global ' +
 	  	 'For Select PU_Id,Prod_Id,Char_Id From #Prods ' +
 	  	 'For Read Only')
 	    Open  Prod_Cursor
FetchNextProd:
 	    Fetch Next From Prod_Cursor into @PU_Id,@Prod_Id,@Char_Id
 	    IF @@Fetch_Status = 0
 	       Begin
 	  	 Delete From Trans_Characteristics Where  Prod_Id = @Prod_Id and PU_Id =@PU_Id  and Trans_Id =  @TransId and @Char_Id =  Char_Id
 	  	 Update Trans_Characteristics  set Validation_Trans_Id =  @Trans_Id Where Prod_Id = @Prod_Id and PU_Id =@PU_Id  and Trans_Id =  @TransId and @Char_Id <> Char_Id
 	  	 If @@Rowcount > 0 
 	  	 Begin
 	  	    Update Transactions set Trans_Type_Id = 4 Where current of T_Cursor
 	  	    Select @SkipPUProd = 1
 	  	    Goto CloseProd
 	  	 End
 	  	 GoTo FetchNextProd
 	       End
CloseProd:
 	    Close Prod_Cursor
 	    Deallocate Prod_Cursor
 	    If @SkipPUProd = 1 GoTo NextTran1
 	    Execute( 'Declare PUProd_Cursor  Cursor Global ' +
 	  	 'For Select PU_Id,Prod_Id,Is_Delete From #PUProds ' +
 	  	 'For Read Only')
 	    Open  PUProd_Cursor
FetchNextPUProd:
 	    Fetch Next From PUProd_Cursor into @PU_Id,@Prod_Id,@Is_Delete
 	    IF @@Fetch_Status = 0
 	       Begin
 	  	 Delete From Trans_Products Where  Prod_Id = @Prod_Id and PU_Id =@PU_Id  and Trans_Id =  @TransId and @Is_Delete = Is_Delete
 	  	 Update Trans_Products  set Validation_Trans_Id =  @Trans_Id Where Prod_Id = @Prod_Id and PU_Id =@PU_Id  and Trans_Id =  @TransId and @Is_Delete <> Is_Delete
 	  	 If @@Rowcount > 0 
 	  	 Begin
 	  	    Update Transactions set Trans_Type_Id = 4 Where current of T_Cursor
 	  	    Goto ClosePUProd
 	  	 End
 	  	 GoTo FetchNextPUProd
 	       End
ClosePUProd:
 	    Close PUProd_Cursor
 	    Deallocate PUProd_Cursor
 	    GoTo NextTran1
         End
     Close T_Cursor
     Deallocate T_Cursor
Drop Table #CharIds
Drop Table #Prods
Drop Table #PUProds
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
