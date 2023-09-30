Create Procedure dbo.spSS_AlarmProductByDescription
 @ProductDesc nVarChar(50),
 @Flag int,
 @ProductGroupId int = Null
AS
---------------------------------------------------------
--
---------------------------------------------------------
 If (@ProductGroupId=0) Or  (@ProductGroupId Is Null) 
  Begin
   If (@Flag=0)
    Begin
     Select P.Prod_Id, P.Prod_Code, P.Prod_Desc
      From Products P 
       Where Prod_Code Like '%' + @ProductDesc + '%'
        Order By P.Prod_Code
    End
   Else
    Begin
     Select P.Prod_Id, P.Prod_Code, P.Prod_Desc
      From Products P 
       Where Prod_Desc Like '%' + @ProductDesc + '%'
       Order By P.Prod_Desc
    End
  End
 Else
  Begin
   If (@Flag=0)
    Begin
     Select P.Prod_Id, P.Prod_Code, P.Prod_Desc
      From Products P 
       Inner Join Product_Group_Data G
        On G.Prod_Id = P.Prod_Id
         Where Prod_Code Like '%' + @ProductDesc + '%'
          And G.Product_Grp_Id = @ProductGroupId
           Order By P.Prod_Code
    End
   Else
    Begin
     Select P.Prod_Id, P.Prod_Code, P.Prod_Desc
      From Products P 
       Inner Join Product_Group_Data G
        On G.Prod_Id = P.Prod_Id
         Where Prod_Desc Like '%' + @ProductDesc + '%'
          And G.Product_Grp_Id = @ProductGroupId
           Order By P.Prod_Desc
    End
  End
