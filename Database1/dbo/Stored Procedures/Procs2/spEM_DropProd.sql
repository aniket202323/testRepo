CREATE PROCEDURE dbo.spEM_DropProd
  @Prod_Id int,
  @User_Id int
AS 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Begin a transaction.
  --
   DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
   	   VALUES (1,@User_Id,'spEM_DropProd',
                 convert(nVarChar(10),@Prod_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Drop all variable specifications, transaction variables, production
  -- unit products, product group members, and product cross-references
  -- involving the product.
  --
  DELETE FROM Var_Specs WHERE Prod_Id = @Prod_Id
  DELETE FROM Trans_Variables WHERE Prod_Id = @Prod_Id
  DELETE FROM Trans_Characteristics WHERE Prod_Id = @Prod_Id
  Delete From Trans_Products Where  Prod_Id = @Prod_Id
  DELETE FROM PU_Characteristics WHERE Prod_Id = @Prod_Id
  DELETE FROM Product_Characteristic_Defaults WHERE Prod_Id = @Prod_Id
  DELETE FROM PU_Products WHERE Prod_Id = @Prod_Id
  DELETE FROM Product_Group_Data WHERE Prod_Id = @Prod_Id
  DELETE FROM Prod_XRef WHERE Prod_Id = @Prod_Id
  DELETE FROM Prdexec_Path_Products WHERE Prod_Id = @Prod_Id
  --
  -- Remove all GradeBook run summaries involving the product.
  --
  SELECT RSum_Id INTO #RS FROM GB_RSum WHERE Prod_Id = @Prod_Id
  DELETE FROM GB_RSum_Data WHERE RSum_Id IN (SELECT RSum_Id FROM #RS)
  DELETE FROM GB_RSum WHERE RSum_Id IN (SELECT RSum_Id FROM #RS)
  DROP TABLE #RS
  --
  -- Change all GradeBook captured data sets, events and production
  -- starts involving the product to the undefined product.
  --
  UPDATE GB_DSet SET Prod_Id = 1 WHERE Prod_Id = @Prod_Id
  UPDATE Production_Starts SET Prod_Id = 1 WHERE Prod_Id = @Prod_Id
  UPDATE Events SET Applied_Product = 1 WHERE Applied_Product = @Prod_Id
  UPDATE Bill_Of_Material_Formulation_Item SET Prod_Id = 1 WHERE Prod_Id = @Prod_Id
  UPDATE Bill_Of_Material_Product SET Prod_Id = 1 WHERE Prod_Id = @Prod_Id
  UPDATE Bill_Of_Material_Substitution SET Prod_Id = 1 WHERE Prod_Id = @Prod_Id
/*
Clean Production Plans
*/
 	 UPDATE Production_Plan SET Prod_Id = 1 WHERE Prod_Id = @Prod_Id
  Declare @CharId Int,@ProdCode nVarChar(25)
  Select @ProdCode = Prod_Code From Products where Prod_Id = @Prod_Id
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
  UPDate Characteristics set Prod_Id = Null where Prod_Id = @Prod_Id
  --
  -- Delete the product.
  --
  DELETE FROM Products_Aspect_MaterialDefinition WHERE Prod_Id = @Prod_Id
  DELETE FROM Products_Base WHERE Prod_Id = @Prod_Id
  --
  -- Commit our transaction and return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
