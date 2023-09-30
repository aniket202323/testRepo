Create Procedure dbo.spAL_ListGradeGroups AS
  SELECT Product_Grp_Id, Product_Grp_Desc FROM Product_Groups
  ORDER By Product_Grp_Desc
