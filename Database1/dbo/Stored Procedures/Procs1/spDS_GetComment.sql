Create Procedure dbo.spDS_GetComment
@TopOfChain_Id int
AS
Select c.Comment_Id, c.Entry_On, c.Modified_On, u.User_Id, u.Username, trimcomment = convert(nVarChar(255), c.comment)
  From Comments C
 	 Join  Users U on  u.User_Id = c.User_Id
    Where (c.Comment_Id = @TopOfChain_Id  and c.TopOfChain_Id is null) or c.TopOfChain_Id = @TopOfChain_Id
    Order By c.Entry_On
RETURN(100)
