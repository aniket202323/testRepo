-------------------------------------------------------------------------------
-- Enterprise connector version of the spLocal_BTScheduleProdCreate SP.
--
-- 	  	  	 01 01 	 Initial coding
-- 17-May-2005 	 AJ  	 01 02 	 Make it check for PU and Path assocs even
-- 	  	  	  	 for existing products
-- 30-Sep-2005  AJ 	 01 03 	 Return flag whether associations were created
-- 29-Nov-2005  AJ      01 04   New input parameter to flag to update description
-- 	  	  	  	 Add Update product description routine
-- 13-Dec-2005  AJ      01 05   Check if Product exist before trying to create it
-- 	  	  	  	 (to avoid error when there are 2 MCA elements for
-- 	  	  	  	  the same new Prod Id)
-------------------------------------------------------------------------------
CREATE 	 PROCEDURE dbo.spS95_ScheduleProdCreate
 	 @ProdId 	  	  	 INT 	 OUTPUT,
 	 @CreatePUAssoc 	  	 INT 	 OUTPUT, 
 	 @CreatePathAssoc  	 INT 	 OUTPUT,
 	 @ProdCode      	  	 VarChar(255),
 	 @ProdDesc       	  	 VarChar(255),
 	 @FamilyId       	  	 INT,
 	 @UserId         	  	 INT,
 	 @PUId           	  	 INT,
 	 @PathId 	         	  	 INT,
 	 @FlgUpdateDesc 	  	 INT = 0
AS
DECLARE  @PUProdTransId        Int,
         @TransactionDesc      VarChar(50),
         @CurrentDate          Datetime,
         @RC                   VarChar(255)
-------------------------------------------------------------------------------
-- If ProdId was not passed, then the Product Code and Product Description are 
-- mandatory because it will create the new product
-------------------------------------------------------------------------------
SELECT 	 @CreatePUAssoc 	  	 = 0,
 	 @CreatePathAssoc 	 = 0
IF 	 @ProdId 	 Is Null
BEGIN
 	 IF 	 Len(RTrim(LTrim(@ProdCode)))=0
 	  	 OR 	 Len(RTrim(LTrim(@ProdDesc)))=0
 	 RETURN
 	 -------------------------------------------------------------------------------
 	 -- If ProdId was not passed, it will check if description is unique
 	 -------------------------------------------------------------------------------
END
-------------------------------------------------------------------------------
-- Create Product, if ProdId was not passed
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- If there are 2 MCA XML elements for the same new Product, the Passed ProdId
 	 -- for the 2nd one will be null, despite the ProdId having being created when
 	 -- processing the first element. So, to avoid errors when trying to create
 	 -- again the same product, I have to re-test whether the product already exists
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @ProdId 	 = Prod_Id
 	  	 FROM 	 Products
 	  	 WHERE 	 Prod_Code 	 = @ProdCode
 	 IF 	 @ProdId 	 IS NULL
 	 BEGIN
 	  	 SELECT @RC = 0
 	  	 EXEC 	 @RC = spEM_CreateProd
 	  	  	 @ProdDesc,  	 -- @Prod_Desc  VarChar(50), 	    
 	  	     	 @ProdCode,   	 -- 
 	  	     	 @FamilyId,   	 -- @Prod_Family_Id Int,
 	  	     	 @UserId,   	 -- @User_Id  Int,
 	  	     	 @ProdId  OUTPUT -- @Prod_Id  Int Output
 	 END
END
ELSE
BEGIN
 	 IF 	 @FlgUpdateDesc 	 = 1
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- If product exists and new description is different than current one and flag
 	  	 -- is on, then update the product description
 	  	 -------------------------------------------------------------------------------
 	  	 IF 	 (SELECT 	 COUNT(Prod_Id)
 	  	  	  	 FROM 	 Products 
 	  	  	  	 WHERE 	 Prod_Id 	  	 = @ProdId
 	  	  	  	 AND 	 Prod_Desc 	 <> @ProdDesc)> 0
 	  	 BEGIN
 	  	  	 SELECT @RC = 0
 	  	  	 EXEC 	 @RC = spEM_RenameProdDesc
 	  	  	 @ProdId,  	 --   @Prod_Id   int,
 	  	  	 @ProdDesc, 	 --   @Prod_Desc nvarchar(50),
 	  	  	 @UserId 	  	 --   @User_Id int
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- If there is the need to update the desc local columns for multi-language sites
 	  	  	 -------------------------------------------------------------------------------
/*
 	  	  	 IF EXISTS (select * from dbo.syscolumns where name = 'Prod_Desc_Local' and id =  object_id(N'[Products]'))
 	  	  	 BEGIN
 	  	  	  	 UPDATE 	 Products
 	  	  	  	  	 SET 	 Prod_Desc_Local 	 = @ProdDesc
 	  	  	  	  	 WHERE 	 Prod_Id 	  	 = @ProdId
 	  	  	 END
*/
 	  	 END
 	 END
END
 -------------------------------------------------------------------------------
 -- If PU was passed, then checks if PU is associated with Product. It associates
 -- if not. The routine is for both: new and existing products
 -------------------------------------------------------------------------------
IF 	 @PUId Is Not Null
 	 AND 	 @ProdID 	 Is Not Null
BEGIN
 	 IF (SELECT Count(PU_Id)
 	     FROM PU_Products
 	     WHERE PU_Id = @PUId
 	     AND Prod_Id = @ProdId) = 0
 	 BEGIN
 	  	 ------------------------------------------------------------------------------
 	  	 -- Create new PU_product transaction
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @RC   = 0,
 	  	  	 @PUProdTransId  = Null,
 	  	  	 @TransactionDesc = 'AutoProductCreate: ' + Convert(VarChar(25), GetDate(), 121) 
 	  	 EXEC 	 @RC = spEM_CreateTransaction 
 	  	  	 @TransactionDesc,   	  	 -- @Trans_Desc   VarChar(50),
 	  	  	 Null,               	  	 -- @Corp_Trans_Id  Int,
 	  	  	 1,    	   	  	  	 -- @Trans_Type  Int,
 	  	       	 Null,    	  	  	 -- @Corp_Trans_Desc VarChar(25),
 	  	  	 @UserId,   	  	  	 -- @User_Id  Int,
 	  	       	 @PUProdTransId  	  	 OUTPUT  -- @Trans_Id  Int Output
 	 
 	  	 IF 	 @PUProdTransId Is Not Null
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Create PU/Product detail record on Trans_Products table
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 SELECT  @RC   = 0
 	  	  	 EXEC 	 @RC  = spEM_PutTransProduct
 	  	  	  	 @PUProdTransId, -- @Trans_Id Int,
 	  	  	       	 @ProdId,  	 -- @Prod_Id  Int,
 	  	  	       	 @PUId,   	 -- @Unit_Id Int,
 	  	  	       	 0,   	  	 -- @IsDelete VarChar(25),
 	  	  	       	 @UserId   	 -- @User_Id Int
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Approve PU/Product transaction
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 SELECT  @RC   = 0,
 	  	  	  	 @CurrentDate  = GetDate()
 	  	  	  	 EXEC  	 @RC  = spEM_ApproveTrans
 	  	  	  	  	 @PUProdTransId,   -- @Trans_Id  Int,
 	  	  	  	  	 @UserId,          -- @User_Id  Int
 	  	  	  	  	 1,                -- @Group_Id   Int,
 	  	  	  	  	 Null,             -- @Deviation_Date DateTime,
 	  	  	  	  	 @CurrentDate,     -- @Approved_Date DateTime,
 	  	  	  	  	 @CurrentDate      -- @Effective_Date DateTime 
 	  	  	 SELECT 	 @CreatePUAssoc = 1
 	  	 END
 	 END
END
-------------------------------------------------------------------------------
-- If Path was passed, then checks if Path is associated with Product. 
-- It associates if not. The routine is for both: new and existing products
-------------------------------------------------------------------------------
IF 	 @PathId 	 IS NOT NULL
 	 AND 	 @ProdId Is NOT NULL
BEGIN
 	 IF 	 (SELECT 	 Count(*)
 	  	  	 FROM 	 PrdExec_Path_Products
 	  	  	 WHERE 	 Path_Id 	 = @PathId
 	  	  	 AND 	 Prod_Id 	 = @ProdId) = 0
 	 BEGIN
 	  	 INSERT 	 Prdexec_Path_Products (Path_Id, Prod_Id)
 	  	  	 VALUES (@PathId, @ProdId)
 	  	 SELECT 	 @CreatePathAssoc = 1
 	 END
END
