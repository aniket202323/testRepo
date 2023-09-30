-- DESCRIPTION: spXLASearchProperty_Secure is modified from spXLAGetProperties.
--              Changes: Allow public properties (whose family's Group_Id is Null) and selected security properties. 
--              Security properties, those whose Group_Id not Null, are retrievable if the user belongs to 
--              the specified group or if user belong to the admin group. MT/5-30-2002
CREATE PROCEDURE dbo.spXLASearchProperty_Secure
 	 @User_Id  Int
AS
DECLARE @Admin 	  	  	 TinyInt
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
-- CREATE TEMP TABLES....
-- Get Security Memberships of this user; And Verify If User Is In Admin
CREATE TABLE #User_Security (Group_Id Int )
INSERT INTO #User_Security
  SELECT us.Group_Id FROM User_Security us WHERE us.User_Id = @User_Id
SELECT @Admin = 0
If EXISTS ( SELECT Group_Id FROM #User_Security WHERE Group_Id = 1 ) SELECT @Admin = 1
--EndIf
-- Retrieve Property Info Based On User's Security Privileges
--
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  SELECT pp.Prop_Id, pp.Prop_Desc, pp.Group_Id
    FROM Product_Properties pp
    LEFT JOIN #User_Security us ON us.Group_Id = pp.Group_Id
   WHERE ( pp.Group_Id Is NULL OR pp.Group_Id = us.Group_Id OR @Admin = 1 )
ORDER BY pp.Prop_Desc
DROP TABLE #User_Security
