-- DESCRIPTION: spXLASearchProduct_Secure is modified from spXLASearchProduct.
--              Changes: Allow public products (whose family's Group_Id is Null) and selected security products. 
--              Security products, those whose family's Group_Id not Null, are retrievable if the user belongs to 
--              the specified group or if user belong to the admin group. MT/5-29-2002
CREATE PROCEDURE dbo.spXLASearchProduct_Secure
 	   @Product_Grp_Id  	 Int
 	 , @SearchString  	 Varchar(50) 	 --Product Code filter string
 	 , @User_Id 	  	 Int
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Needed for Query Type
DECLARE @QType 	  	  	 TinyInt
DECLARE @NoGroupNoString 	 TinyInt
DECLARE @NoGroupHasString 	 TinyInt
DECLARE @HasGroupNoString 	 TinyInt
DECLARE @HasGroupHasString 	 TinyInt
 	 --General need
DECLARE @Admin 	  	  	 TinyInt
-- Define query type
--
SELECT @NoGroupNoString 	  	 = 1
SELECT @NoGroupHasString 	 = 2
SELECT @HasGroupNoString 	 = 3
SELECT @HasGroupHasString 	 = 4
-- CREATE TEMP TABLES....
CREATE TABLE #User_Security (Group_Id Int )
CREATE TABLE #Products (Prod_Id Int, Group_Id Int NULL)
-- Get Security Memberships of this user; And Verify If User Is In Admin
--
INSERT INTO #User_Security
  SELECT us.Group_Id FROM User_Security us WHERE us.User_Id = @User_Id
SELECT @Admin = 0
If EXISTS ( SELECT Group_Id FROM #User_Security WHERE Group_Id = 1 ) SELECT @Admin = 1
--EndIf
-- Get All Need Product Information Including Security Group Info
--
INSERT INTO #Products
  SELECT p.Prod_Id, pf.Group_Id
    FROM Products p
    LEFT JOIN Product_Family pf ON pf.Product_Family_Id = p.Product_Family_Id
   WHERE p.Prod_Id <> 1
-- Define Qtype based on inputs....
--
If @Product_Grp_Id Is NULL
  BEGIN
    SELECT @QType = Case When @SearchString Is NULL Then @NoGroupNoString Else @NoGroupHasString End
  END
Else
  BEGIN
    SELECT @QType = Case When @SearchString Is NULL Then @HasGroupNoString Else @HasGroupHasString End
  END
--EndIf
-- Retrieve Product Information: Filter Out Based On QType And User's Security
--
If @QType = @NoGroupNoString
  BEGIN
      SELECT p.Prod_Id, p.Prod_Code, p.Prod_Desc, t.Group_Id
        FROM Products p
        JOIN #Products t ON t.Prod_Id = p.Prod_Id
        LEFT JOIN #User_Security us ON us.Group_Id = t.Group_Id
       WHERE t.Group_Id Is NULL OR t.Group_Id = us.Group_Id OR @Admin = 1
    ORDER BY p.Prod_Code
  END
Else If @QType = @NoGroupHasString
  BEGIN
      SELECT p.Prod_Id, p.Prod_Code, p.Prod_Desc, t.Group_Id
        FROM Products p
        JOIN #Products t ON t.Prod_Id = p.Prod_Id
        LEFT JOIN #User_Security us ON us.Group_Id = t.Group_Id
       WHERE (t.Group_Id Is NULL OR t.Group_Id = us.Group_Id OR @Admin = 1)
         AND p.Prod_Code LIKE '%' + RTRIM(LTRIM(@SearchString)) + '%'
    ORDER BY p.Prod_Code
  END
Else If @QType = @HasGroupNoString
  BEGIN
      SELECT p.Prod_Id, p.Prod_Code, p.Prod_Desc, t.Group_Id
        FROM Products p
        JOIN #Products t ON t.Prod_Id = p.Prod_Id
        LEFT JOIN #User_Security us ON us.Group_Id = t.Group_Id
        JOIN Product_Group_Data pg ON pg.Prod_Id = p.Prod_Id AND pg.Product_Grp_Id = @Product_Grp_Id
       WHERE t.Group_Id Is NULL OR t.Group_Id = us.Group_Id OR @Admin = 1
    ORDER BY p.Prod_Code
  END
Else If @QType = @HasGroupHasString
  BEGIN
      SELECT p.Prod_Id, p.Prod_Code, p.Prod_Desc, t.Group_Id
        FROM Products p
        JOIN #Products t ON t.Prod_Id = p.Prod_Id
        LEFT JOIN #User_Security us ON us.Group_Id = t.Group_Id
        JOIN Product_Group_Data pg ON pg.Prod_Id = p.Prod_Id AND pg.Product_Grp_Id = @Product_Grp_Id
       WHERE (t.Group_Id Is NULL OR t.Group_Id = us.Group_Id OR @Admin = 1)
         AND p.Prod_Code LIKE '%' + RTRIM(LTRIM(@SearchString)) + '%'
    ORDER BY p.Prod_Code 
  END
--EndIf:QType
DROP TABLE #User_Security
DROP TABLE #Products
