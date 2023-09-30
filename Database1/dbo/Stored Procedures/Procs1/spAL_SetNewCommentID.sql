Create Procedure dbo.spAL_SetNewCommentID
  @Comment_ID int,
  @Object_ID BigInt,
  @Object_Type int,
  @Result_On datetime = null
 AS
  IF @Object_Type = 1 	 --Variables
    BEGIN
      UPDATE Variables_Base SET Comment_Id = @Comment_Id WHERE Var_Id = @Object_Id
    END
  ELSE IF @Object_Type = 2 	 --Events
    BEGIN
      UPDATE Events SET Comment_Id = @Comment_Id WHERE Event_Id = @Object_Id
    END
  ELSE IF @Object_Type = 3 	 --Sheet_Column
    BEGIN
      UPDATE Sheet_Columns SET Comment_Id = @Comment_Id WHERE Sheet_Id = @Object_Id 
 	 AND Result_On = @Result_On
    END
  ELSE IF @Object_Type = 4 	 --Test
    BEGIN
      UPDATE Tests SET Comment_Id = @Comment_Id WHERE Test_Id = @Object_Id
    END
  ELSE IF @Object_Type = 5 	 --Product
    BEGIN
      UPDATE Products SET Comment_Id = @Comment_Id WHERE Prod_Id = @Object_Id
    END
  ELSE IF @Object_Type = 6 	 --Prod_Line
    BEGIN
      UPDATE Prod_Lines SET Comment_Id = @Comment_Id WHERE PL_Id = @Object_Id
    END
  ELSE IF @Object_Type = 7 	 --Prod_Unit
    BEGIN
      UPDATE Prod_Units SET Comment_Id = @Comment_Id WHERE PU_Id = @Object_Id
    END
  ELSE IF @Object_Type = 8 	 --Characteristic
    BEGIN
      UPDATE Characteristics SET Comment_Id = @Comment_Id WHERE Char_Id = @Object_Id
    END
  ELSE IF @Object_Type = 9 	 --Specification
    BEGIN
      UPDATE Specifications SET Comment_Id = @Comment_Id WHERE Spec_Id = @Object_Id
    END
  ELSE IF @Object_Type = 10 	 --Sheet
    BEGIN
      UPDATE Sheets SET Comment_Id = @Comment_Id WHERE Sheet_Id = @Object_Id
    END
  ELSE IF @Object_Type = 11 	 --Property
    BEGIN
      UPDATE Product_Properties SET Comment_Id = @Comment_Id WHERE Prop_Id = @Object_Id
    END
  ELSE 	  	  	  	 -- Unknown object type.
    BEGIN
      return
    END
