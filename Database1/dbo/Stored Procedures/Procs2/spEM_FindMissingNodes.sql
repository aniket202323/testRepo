CREATE PROCEDURE dbo.spEM_FindMissingNodes
  @NodeType  nVarChar(2),
  @InNodeId  int,
  @OutNodeId    int OUTPUT
  AS
  --
  -- Fetch the correct id.
  IF @NodeType = 'ag'              -- Variable
    SELECT @OutNodeId = PU_Id FROM Variables WHERE Var_Id = @InNodeId
  ELSE IF @NodeType = 'aq'              -- Characteristic
         SELECT @OutNodeId = Prop_Id FROM Characteristics WHERE Char_Id = @InNodeId
  ELSE IF @NodeType = 'as'              -- Specification variable
         SELECT @OutNodeId = Prop_Id FROM Specifications WHERE Spec_Id = @InNodeId
  ELSE IF @NodeType = 'aj'              -- Product
         SELECT @OutNodeId = Product_Family_Id FROM Products WHERE Prod_Id = @InNodeId
  ELSE IF @NodeType = 'br'
         SELECT @OutNodeId = Sheet_Group_Id FROM Sheets WHERE Sheet_Id = @InNodeId
  ELSE IF @NodeType = 'ey'              -- Child Variable
        Begin
         SELECT @OutNodeId = v2.PU_Id FROM Variables v 
           Join Variables v2 on v2.Var_Id = v.PVar_Id
 	  	  	  	  	  	 WHERE v.Var_Id = @InNodeId
        End
   RETURN(0)
