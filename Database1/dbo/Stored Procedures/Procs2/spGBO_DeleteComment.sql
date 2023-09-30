Create Procedure dbo.spGBO_DeleteComment 
  @Comment_Id int,
  @Object_Id int,
  @Object_Type nvarchar(50)    AS
  BEGIN TRANSACTION
  --
  -- Remove the reference to the comment from the object.
  --
  IF @Object_Type = 'D'  	 -- Production Line
    BEGIN
      UPDATE Prod_Lines SET Comment_Id = NULL WHERE PL_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'E' 	 -- Production Unit
    BEGIN
      UPDATE Prod_Units SET Comment_Id = NULL WHERE PU_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'F' 	 -- Production Group
    BEGIN
      UPDATE PU_Groups SET Comment_Id = NULL WHERE PUG_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'Variable'
    BEGIN
      UPDATE Variables_Base SET Comment_Id = NULL WHERE Var_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'Product'
    BEGIN
      UPDATE Products SET Comment_Id = NULL WHERE Prod_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'Run Summary' 	 -- RSum
    BEGIN
      UPDATE GB_Rsum SET Comment_Id = NULL WHERE RSum_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'Captured Data' 	 -- DSet
    BEGIN
      UPDATE GB_Dset SET Comment_Id = NULL WHERE DSet_Id = @Object_Id
    END
  ELSE 	  	  	  	 -- Unknown object type.
    BEGIN
      ROLLBACK TRANSACTION
    END
  --
  -- Delete the comment.
  --
--  DELETE FROM Comments WHERE Comment_Id = @Comment_Id
Update Comments Set Comment = '',ShouldDelete = 1 Where Comment_Id = @Comment_ID
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
