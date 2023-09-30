CREATE PROCEDURE dbo.spEM_GetIconData
   @AllIcons tinyInt
  AS
  IF @AllIcons = 1
      SELECT Icon_Id,Icon_Desc FROM Icons  ORDER BY Icon_Id
  ELSE
      SELECT Icon_Id,Icon_Desc FROM Icons Where Icon IS NOT NULL ORDER BY Icon_Id
