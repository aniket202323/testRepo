-------------------------------------------------------------------------------
-- This Stored Procedure will retrieve a Product Id for a passed Search String.
-- It may be called several times by event model SPs used in interfaces to foreign
-- systems.
--
-- Original 	 21-Feb-2002 	 AlexJ
-- Revision
-------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spCmn_ProductSearchByUnit
 	 @ProdId 	  	 Int 	  	 OUTPUT,
 	 @PUId 	  	 Int,
 	 @SearchString 	 nVarchar(255),
 	 @DefaultId 	 Int = NULL
AS
SELECT 	 @ProdId = NULL
-------------------------------------------------------------------------------
-- Check the inputs.  The PUId must be a legitimate Master Production Unit and
-- the SearchString can not be NULL.
-------------------------------------------------------------------------------
IF 	 (SELECT 	 Count(PU_Id)
 	  	 FROM 	 Prod_Units
 	  	 WHERE 	 PU_Id = @PUId
 	  	 AND 	 Master_Unit IS NULL) = 0
 	 GOTO 	 BadInput
IF 	 LTrim(@SearchString) = '' OR @SearchString IS NULL
 	 GOTO 	 BadInput
-------------------------------------------------------------------------------
-- Look for a record on the XRef table that matches the passed unit and where
-- the product is associated with the unit. 
-------------------------------------------------------------------------------
SELECT 	 @ProdId = pux.Prod_Id
 	 FROM 	 PU_Products pup
 	 JOIN 	 Prod_XRef pux ON pup.PU_Id = pux.PU_Id
 	 WHERE 	 pup.Prod_Id = pux.Prod_Id
 	 AND 	 pup.PU_Id = @PUId
 	 AND 	 pux.Prod_Code_XRef = @SearchString
-------------------------------------------------------------------------------
-- Look for a record on the XRef table that matches the passed unit and where
-- the product is associated with the unit. It handles the situation where you
-- have Prod_XRef1, Prod_Xref2, Prod_XRef3 pointing to the same Proficy ProdId
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
BEGIN
 	 CREATE 	 TABLE #ProdXRef1 (
 	  	 PUId 	  	 Int 	  	 NULL,
 	  	 ProdId 	  	 Int 	  	 NULL,
 	  	 ProdCodeXRef 	 nVarChar(257) 	 NULL)
 	 INSERT 	 #ProdXRef1
 	  	 SELECT 	 pux.PU_Id, pux.Prod_Id, ',' + RTrim(LTrim(pux.Prod_Code_XRef)) + ','
 	  	  	 FROM 	 Prod_XRef pux
 	  	  	 WHERE 	 pux.PU_Id = @PUId
 	 SELECT 	 @ProdId = pux.ProdId
 	  	 FROM 	 PU_Products pup
 	  	 JOIN 	 #ProdXRef1 pux ON pup.PU_Id = pux.PUId
 	  	 WHERE 	 pup.Prod_Id = pux.ProdId
 	  	 AND 	 pup.PU_Id = @PUId
 	  	 AND 	 pux.ProdCodeXRef Like '%,' + @SearchString + ',%'
 	 DROP TABLE 	 #ProdXRef1
END
-------------------------------------------------------------------------------
-- If not found for the passed unit, look for a default record on the XRef table
-- for the passed SearchString.
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
 	 SELECT 	 @ProdId = pux.Prod_Id
 	  	 FROM 	 PU_Products pup
 	  	 JOIN 	 Prod_XRef pux ON pup.Prod_Id = pux.Prod_Id
 	  	 WHERE 	 pup.PU_Id = @PUId
 	  	 AND 	 pux.PU_Id IS NULL
 	  	 AND 	 pux.Prod_Code_XRef = @SearchString
-------------------------------------------------------------------------------
-- If not found for the passed unit, look for a default record on the XRef table
-- for the passed SearchString.  It handles the situation where you
-- have Prod_XRef1, Prod_Xref2, Prod_XRef3 pointing to the same Proficy ProdId
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
BEGIN 	 
 	 CREATE 	 TABLE #ProdXRef2 (
 	  	 ProdId 	  	 Int 	  	 NULL,
 	  	 ProdCodeXRef 	 nVarChar(257) 	 NULL)
 	 INSERT 	 #ProdXRef2
 	  	 SELECT 	 pux.Prod_Id, ',' + RTrim(LTrim(pux.Prod_Code_XRef)) + ','
 	  	  	 FROM 	 Prod_XRef pux
 	  	  	 WHERE 	 pux.PU_Id IS NULL
 	 SELECT 	 @ProdId = pux.ProdId
 	  	 FROM 	 PU_Products pup
 	  	 JOIN 	 #ProdXRef2 pux ON pup.Prod_Id = pux.ProdId
 	  	 WHERE 	 pup.PU_Id = @PUId
 	  	 AND 	 pux.ProdCodeXRef Like '%,' + @SearchString + ',%'
 	 DROP TABLE 	 #ProdXRef2
END
-------------------------------------------------------------------------------
-- Look if the passed description matches the ProdCode for any product that can
-- be produced on the passed unit.
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
 	 SELECT 	 @ProdId = pup.Prod_Id
 	  	 FROM 	 PU_Products pup
 	  	 JOIN 	 Products p ON pup.Prod_Id = p.Prod_Id
 	  	 WHERE 	 pup.PU_Id = @PUId
 	  	 AND 	 p.Prod_Code = @SearchString
-------------------------------------------------------------------------------
-- Look if the passed description matches the ProdDesc for any product that can
-- be produced on the passed unit.
-------------------------------------------------------------------------------
IF 	 @ProdId IS NULL
 	 SELECT 	 @ProdId = pup.Prod_Id
 	  	 FROM 	 PU_Products pup
 	  	 JOIN 	 Products p ON pup.Prod_Id = p.Prod_Id
 	  	 WHERE 	 pup.PU_Id = @PUId
 	  	 AND 	 p.Prod_Desc = @SearchString
-------------------------------------------------------------------------------
-- Returns the default value if not found.
-------------------------------------------------------------------------------
IF 	 IsNumeric(@ProdId) <> 1
 	 SELECT 	 @ProdId = @DefaultId
GOTO 	 Finished
-------------------------------------------------------------------------------
-- End of main body of stored procedure.
-------------------------------------------------------------------------------
BadInput:
 	 RETURN -100
Finished:
 	 RETURN 1
