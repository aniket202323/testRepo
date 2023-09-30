-- DESCRIPTION: Want Data_Type_Desc (From Data_Type_Id)
--
CREATE PROCEDURE dbo.spXLA_SpecificationInfo
 	   @Spec_Id 	 Integer
 	 , @Spec_Desc  	 varchar(50) 
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003) 
DECLARE @Row_Count Int
SELECT @Row_Count = 0
-- First Verify Input parameter
If @Spec_Desc Is NOT NULL -- Use it
  BEGIN
    SELECT @Spec_Id = Spec_Id FROM Specifications WHERE Spec_Desc = @Spec_Desc
    SELECT @Row_Count  = @@ROWCOUNT
  END
Else  -- Verify the pass-in Spec_Id is valid
  BEGIN
    SELECT @Spec_Desc = Spec_Desc FROM Specifications WHERE Spec_Id = @Spec_Id
    SELECT @Row_Count  = @@ROWCOUNT
  END
--EndIf
If @Row_Count = 0
  BEGIN
    SELECT ReturnStatus = -10 	 -- Tells AddIn "Specification specified not found"
    RETURN
  END
--EndIf
-- RETRIEVE "Specification Attributes"
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003) 
SELECT s.Spec_Id
     , s.Spec_Desc
     , t.Data_Type_Desc
     , s.Spec_Precision
     , pp.Prop_Desc
     , s.Comment_Id
     --, s.External_Link
     --, s.Spec_Order
     --, s.Extended_Info
  FROM Specifications s
  JOIN Data_Type t ON t.Data_Type_Id = s.Data_Type_Id
  JOIN Product_Properties pp ON pp.Prop_Id = s.Prop_Id
 WHERE s.Spec_Id = @Spec_Id
