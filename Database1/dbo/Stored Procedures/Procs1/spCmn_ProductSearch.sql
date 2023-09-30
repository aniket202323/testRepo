-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spCmn_ProductSearch
-----------------------------------------------------------
-------------------------------------------------------------------------------
-- This Stored Procedure will retrieve a Product Id for a passed Search String.
-- It may be called several times by event model SPs used in interfaces to foreign
-- systems.
--
-- Original  	  27-Feb-2002  	  AlexJ
-- Revision 	  12-Apr-2007 	  AlexJ 	 Fix truncation if ProdXref.Prod_Code_Xref
-- Revision  10-Mar-2008     DanS Restored @DSId for Data_Source_Xref
--  	  	  	  	  	 has 255 characters
-------------------------------------------------------------------------------
CREATE   	  PROCEDURE dbo.spCmn_ProductSearch
  	  @ProdId  	    	 INT  	    	  OUTPUT,
  	  @SearchString 	  	 nVARCHAR(255),
  	  @DefaultId  	   	 INT  	  	 = NULL,
 	  @DSId 	  	  	 INT = NULL
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
SELECT  	  @ProdId = NULL
-------------------------------------------------------------------------------
-- Check the inputs.  The PUId must be a legitimate Master Production Unit and
-- the SearchString can not be NULL.
-------------------------------------------------------------------------------
IF 	 LTRIM(@SearchString) = '' 
 	 OR @SearchString IS NULL
  	  	 GOTO  	  BadInput
-------------------------------------------------------------------------------
-- Look for a record on the Data_Source_XRef table that matches the DSId = @DSId
-- passed description. 
-------------------------------------------------------------------------------
If @DSId Is Not Null
 	 Select @ProdId = Actual_Id from Data_Source_Xref Where Table_Id = 23 and DS_Id = @DSId and Foreign_Key = @SearchString
-------------------------------------------------------------------------------
-- Look for a record on the XRef table that matches the unit = Null and the
-- passed description. 
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
SELECT  	  @ProdId = pux.Prod_Id
  	  FROM  	  dbo.Prod_XRef pux   	 WITH 	 (NOLOCK)
  	  WHERE  	  pux.PU_Id IS NULL
  	  AND  	  pux.Prod_Code_XRef = @SearchString
-------------------------------------------------------------------------------
-- Look for a record on the XRef table that matches the unit = Null and the
-- passed description.  It handles the situation where you have Prod_XRef1, 
-- Prod_Xref2, Prod_XRef3 pointing to the same Proficy ProdId
--------------------------------------------------------------------------------
IF  	  @ProdId IS NULL
BEGIN  	 
 	 DECLARE 	 @tProdXRef2 	 TABLE
(
 	  ProdId  	  INT 	  	 NULL,
  	  ProdCodeXRef  	  nVARCHAR(1000) 	 NULL
)
  	  INSERT 	 @tProdXRef2
  	    	  SELECT pux.Prod_Id, ',' 
 	  	  	 + RTRIM(LTRIM(pux.Prod_Code_XRef)) 
 	  	  	 + ','
  	    	    	 FROM  	 dbo.Prod_XRef pux 	 WITH 	 (NOLOCK)
  	    	    	 WHERE  	  pux.PU_Id IS NULL
  	  SELECT  @ProdId = pux.ProdId
  	    	  FROM  	  @tProdXRef2 pux  
  	    	  WHERE  	  pux.ProdCodeXRef LIKE '%,' + @SearchString + ',%'
END
-------------------------------------------------------------------------------
-- Look if the passed description matches the ProdCode for any product that can
-- be produced on the passed unit.
-------------------------------------------------------------------------------
IF  	  @ProdId IS NULL
  	  SELECT  @ProdId = p.Prod_Id
  	    	  FROM  	  dbo.Products p  	 WITH 	 (NOLOCK)
  	    	  WHERE  	  p.Prod_Code = @SearchString
-------------------------------------------------------------------------------
-- Look if the passed description matches the ProdDesc for any product that can
-- be produced on the passed unit.
-------------------------------------------------------------------------------
IF  	  @ProdId IS NULL
  	  SELECT  @ProdId = p.Prod_Id
  	    	  FROM  	  dbo.Products p  	 WITH 	 (NOLOCK)
  	    	  WHERE  	  p.Prod_Desc = @SearchString
-------------------------------------------------------------------------------
-- Returns the default value if not found.
-------------------------------------------------------------------------------
IF  	  ISNUMERIC(@ProdId) <> 1
  	  SELECT 	  @ProdId = @DefaultId
GOTO  	  Finished
-------------------------------------------------------------------------------
-- End of main body of stored procedure.
-------------------------------------------------------------------------------
BadInput:
  	  RETURN -100
Finished:
  	  RETURN 1
