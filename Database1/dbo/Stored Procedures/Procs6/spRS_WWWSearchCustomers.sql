CREATE PROCEDURE [dbo].[spRS_WWWSearchCustomers]
@SearchMask VarChar(50) = '',
@SearchFlag int = Null,
@IncludeList varchar(7000) = Null,
@ExcludeList varchar(7000) = Null,
@ViewBy int = Null
AS
-- Search Flag Constants
-- 1 = Starts With
-- 2 = Containser
-- 3 = Ends With
Declare @Mask varchar(52)
If @ViewBy Is Null
  Select @ViewBy = 1 --Description
If @SearchMask Is Null Select @SearchMask = ''
If @SearchFlag Is Null Select @SearchFlag = 2
If @SearchFlag = 1  	 Select @Mask = @SearchMask + '%'
If @SearchFlag = 2  	 Select @Mask = '%' + @SearchMask + '%'
If @SearchFlag = 3  	 Select @Mask = '%' + @SearchMask
Create Table #I(Id_Order int, Id_Value int) 	 --Table of customers to Include
Create Table #E(Id_Order int, Id_Value int) --Table of customers to Exclude
If @IncludeList = '' Select @IncludeList = Null
If @IncludeList Is Not Null 
  Begin
 	 Insert Into #I exec spRS_MakeOrderedResultSet @IncludeList
 	 If @ViewBy = 1
 	  	 Begin
 	  	  	 select customer_id, Customer_Name 'Customer_Name' from customer c
 	  	     Join #I on #I.ID_Value = c.Customer_Id
 	  	  	 Order By #I.Id_Order 
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 select customer_id, Customer_Code 'Customer_Code' from customer c
 	  	     Join #I on #I.ID_Value = c.Customer_Id
 	  	  	 Order By #I.Id_Order 
 	  	 End
 	 Drop Table #I
 	 return (0)
  End
If @ExcludeList = '' Select @ExcludeList = Null
If @ExcludeList Is Not Null 
  Begin
 	 Insert Into #E exec spRS_MakeOrderedResultSet @ExcludeList
 	 If @ViewBy = 1
 	  	 Begin
 	  	  	 select customer_id, Customer_Name 'Customer_Name' from customer c 
 	  	     Where c.Customer_Id Not In (Select ID_Value From #E) and
 	  	  	       (c.Customer_Name like @Mask or
 	  	  	  	   c.Customer_Code like @Mask)
 	  	  	 Order By Customer_Name
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 select customer_id, Customer_Code 'Customer_Code' from customer c 
 	  	     Where c.Customer_Id Not In (Select ID_Value From #E) and
 	  	  	       (c.Customer_Name like @Mask or
 	  	  	  	   c.Customer_Code like @Mask)
 	  	  	 Order By Customer_Name
 	  	 End
 	 Drop Table #E
 	 return (0)
  End
 	 If @ViewBy = 1
 	  	 Begin
 	  	  	 select customer_id, Customer_Name 'Customer_Name' from customer c 
 	  	  	 Where Customer_Name like @Mask or
 	  	  	  	   Customer_Code like @Mask
 	  	  	 Order By Customer_Name
 	  	  	 return (0)
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 select customer_id, Customer_Code 'Customer_Code' from customer c 
 	  	  	 Where Customer_Name like @Mask or
 	  	  	  	   Customer_Code like @Mask
 	  	  	 Order By Customer_Name
 	  	  	 return (0)
 	  	 End
