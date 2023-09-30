Create Procedure dbo.spCC_DeleteView
  @View_Id int 
 AS 
DELETE Views Where View_Id = @View_Id
IF @@ERROR > 0 RETURN (0)
RETURN(1)
