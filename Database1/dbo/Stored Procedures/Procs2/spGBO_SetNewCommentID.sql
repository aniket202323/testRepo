Create Procedure dbo.spGBO_SetNewCommentID 
  @Object_ID int,
  @Object_Type nvarchar(50),   
  @Comment_ID int OUTPUT
 AS
Insert Comments (Comment, User_Id, Modified_On, CS_ID) Values (' ', 1, dbo.fnServer_CmnGetDate(getutcdate()), 1)
Select @Comment_ID = Scope_Identity()
  IF @Object_Type = 'D'  	 -- Production Line
    UPDATE Prod_Lines SET Comment_Id = @Comment_Id WHERE PL_Id = @Object_Id
  ELSE IF @Object_Type = 'E' 	 -- Production Unit
    UPDATE Prod_Units SET Comment_Id = @Comment_Id WHERE PU_Id = @Object_Id
  ELSE IF @Object_Type = 'F' 	 -- Production Group
    UPDATE PU_Groups SET Comment_Id = @Comment_Id WHERE PUG_Id = @Object_Id
  ELSE IF @Object_Type = 'Variable' 	 -- Variable
    UPDATE Variables_Base SET Comment_Id = @Comment_Id WHERE Var_Id = @Object_Id
  ELSE IF @Object_Type = 'Product' 	 -- Product
    UPDATE Products SET Comment_Id = @Comment_Id WHERE Prod_Id = @Object_Id
  ELSE IF @Object_Type = 'Run Summary' 	 -- RSum
    UPDATE GB_RSum SET Comment_Id = @Comment_Id WHERE RSum_Id = @Object_Id
  ELSE IF @Object_Type = 'Captured Data' 	 -- DSet
    UPDATE GB_Dset SET Comment_Id = @Comment_Id WHERE DSet_Id = @Object_Id
  ELSE 	 
    RETURN 	  	  	 -- Unknown object type.
