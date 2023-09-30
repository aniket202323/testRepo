-- DESCRIPTION: spXLASearchSpecification_Secure() retrieve "public" and security specs from database. 
-- Public specs are ones that have null Group_Id in Specifications Table: security, non-null Group_Id. Only users belonging 
-- to specified group, or admin group, may retrieve security specs. MT/5-30-2002  
CREATE PROCEDURE dbo.spXLASearchSpecification_Secure
 	   @Prop_Id 	  	 Integer
 	 , @SpecDescString 	 Varchar(50)
 	 , @User_Id 	  	 Integer
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Needed to define query types
DECLARE @QType 	  	  	 TinyInt
DECLARE @NoPropIdNoString 	 TinyInt
DECLARE @NoPropIdHasString 	 TinyInt
DECLARE @HasPropIdNoString 	 TinyInt
DECLARE @HasPropIdHasString 	 TinyInt
 	 --General need
DECLARE @Admin   	  	 TinyInt
 	 --Define query types
SELECT @NoPropIdNoString 	 = 1
SELECT @NoPropIdHasString 	 = 2
SELECT @HasPropIdNoString 	 = 3
SELECT @HasPropIdHasString 	 = 4
-- Define Query Types Based On Input Parameters
If @Prop_Id Is NULL
  BEGIN
    SELECT @QType = Case When @SpecDescString Is NULL Then @NoPropIdNoString  Else @NoPropIdHasString End
  END
Else --@Prop_Id NOT NULL
  BEGIN
    SELECT @QType = Case When @SpecDescString Is NULL Then @HasPropIdNoString  Else @HasPropIdHasString End
  END
--EndIf:@Prop_Id NULL
-- Get Security Memberships of this user; And Verify If User Is In Admin Group
--
CREATE TABLE #User_Security( Group_Id Int)
INSERT INTO #User_Security
  SELECT us.Group_Id FROM User_Security us WHERE us.User_Id = @User_Id
SELECT @Admin = 0
If EXISTS ( SELECT Group_Id FROM #User_Security WHERE Group_Id = 1 ) SELECT @Admin = 1
--EndIf
-- Retrieve Specifications Based On Query Types And User's Security
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @QType = @NoPropIdNoString
  BEGIN
    SELECT s.Spec_Id, s.Spec_Desc, s.Group_Id
      FROM Specifications s
      LEFT JOIN #User_Security us ON us.Group_Id = s.Group_Id
     WHERE ( s.Group_Id Is NULL OR s.Group_Id = us.Group_Id OR @Admin = 1 ) order by s.Spec_Desc
  END
Else If @QType = @NoPropIdHasString
  BEGIN
    SELECT s.Spec_Id, s.Spec_Desc, s.Group_Id
      FROM Specifications s
      LEFT JOIN #User_Security us ON us.Group_Id = s.Group_Id
     WHERE ( s.Group_Id Is NULL OR s.Group_Id = us.Group_Id OR @Admin = 1 )
       AND s.Spec_Desc LIKE '%' + LTRIM(RTRIM(@SpecDescString)) + '%' order by s.Spec_Desc
  END
Else If @QType = @HasPropIdNoString
  BEGIN
    SELECT s.Spec_Id, s.Spec_Desc, s.Group_Id
      FROM Specifications s
      LEFT JOIN #User_Security us ON us.Group_Id = s.Group_Id
     WHERE Prop_Id = @Prop_Id
       AND ( s.Group_Id Is NULL OR s.Group_Id = us.Group_Id OR @Admin = 1 ) order by s.Spec_Desc
  END
Else If @QType = @HasPropIdHasString
  BEGIN
    SELECT s.Spec_Id, s.Spec_Desc, s.Group_Id
      FROM Specifications s
      LEFT JOIN #User_Security us ON us.Group_Id = s.Group_Id
     WHERE Prop_Id = @Prop_Id
       AND ( s.Group_Id Is NULL OR s.Group_Id = us.Group_Id OR @Admin = 1 )
       AND s.Spec_Desc LIKE '%' + LTRIM(RTRIM(@SpecDescString)) + '%' order by s.Spec_Desc
  END
--EndIf:@QType....
DROP TABLE #User_Security
