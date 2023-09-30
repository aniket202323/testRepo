CREATE PROCEDURE dbo.spEM_ChangeProductFamily
  @Prod_Id int,
  @Prod_Family_Id int,
  @User_Id int
  AS
DECLARE @Insert_Id integer 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ChangeProductFamily',  convert(nVarChar(10),@Prod_Id) + ','  +  convert(nVarChar(10),@Prod_Family_Id) + ','  +  convert(nVarChar(10),@User_Id) ,dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  Declare @OldFamilyId Int
  Declare @CharId Int,@ProdCode nVarChar(25)
  Select  @OldFamilyId  = Product_Family_Id,@ProdCode = Prod_Code From Products WHERE Prod_Id = @Prod_Id 
  UPDATE Products SET Product_Family_Id = @Prod_Family_Id  WHERE Prod_Id = @Prod_Id
-- Remove Old Characteristics
  Declare ProductCursor Cursor
   	 for Select c.Char_Id 
 	  	 From Product_Properties pp 
 	  	 Join Characteristics c on pp.Prop_Id = c.Prop_Id and c.Char_Desc = @ProdCode
 	  	 where  pp.Auto_Sync_Chars = 1
  Open ProductCursor
ProductCursorLoop:
  Fetch next from ProductCursor Into @CharId
  If @@Fetch_Status = 0
 	 Begin
 	   Execute spEM_DropChar  @CharId, @User_Id
 	   GoTo ProductCursorLoop
 	 End
  Close ProductCursor
  Deallocate ProductCursor
-- Add New Characteristics
  Declare @PropId Int
  Declare ProductCursor Cursor
   	 for Select Prop_Id From Product_Properties where Product_Family_Id = @Prod_Family_Id and Auto_Sync_Chars = 1
  Open ProductCursor
ProductCursorLoop2:
  Fetch next from ProductCursor Into @PropId
  If @@Fetch_Status = 0
 	 Begin
 	   Select @CharId = Null
 	   Select @CharId = Char_Id from Characteristics where Char_Desc = @ProdCode and Prop_Id = @PropId
 	   If @CharId is null
 	  	 Begin
 	  	   execute spEM_CreateChar  @ProdCode,@PropId, @User_Id,@CharId  OUTPUT
 	  	 End
 	   GoTo ProductCursorLoop2
 	 End
  Close ProductCursor
  Deallocate ProductCursor
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
