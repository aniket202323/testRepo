CREATE PROCEDURE dbo.spCSS_GetCommentIds 
@TopOfChain_Id int
AS
--Get all comments for this chain
Select c.Comment_Id, c.Entry_On, c.Modified_On, u.User_Id, u.Username, trimcomment = convert(nVarChar(255), c.comment)
  From Comments C, Users U
    Where Coalesce(c.TopOfChain_Id, c.Comment_Id) = @TopOfChain_Id and u.User_Id = c.User_Id
    Order By c.Entry_On
