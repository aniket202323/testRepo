CREATE PROCEDURE dbo.spEM_QueryException
  @ExceptionType 	 nvarchar(1000),
  @Oper 	  	  	 nvarchar(1000),
  @Values 	  	 VarChar(7000),
  @Actions 	  	 nvarchar(1000)
 AS
/* 
****Operators ****
  0  =  "<"
  1 =   "<="
  2 =   "="
  3 =   ">="
  4 =   ">"
  5 =   "<>"
  6 =   "Like"
  7 =   "Not Like"
****Exception Types******
1 = "Ship To"
2 = "Bill To"
*****Actions******
0 = "Add"
1 = "Keep"
*/
Declare @iET 	 int,
 	 @ET 	 nvarchar(20),
 	 @iO 	 int,
 	 @O 	 nvarchar(20),
 	 @Val 	 nVarChar(27),
 	 @A 	 Int,
 	 @SQL   	 VarChar(7000)
Create Table #Customers (Customer_Id Int)
Create Table #Customer2 (Customer_Id Int)
Create Table #Output    (Exception_Desc nvarchar(50),Customer_name nVarChar(100),Value nVarChar(100))
While (len( LTRIM(RTRIM(@ExceptionType))) > 1) 
  Begin
       Select @iET = Convert(Int,SubString(@ExceptionType,1,CharIndex(Char(1),@ExceptionType)-1))
       Select @ExceptionType = SubString(@ExceptionType,CharIndex(Char(1),@ExceptionType),len(@ExceptionType))
       Select @ExceptionType = Right(@ExceptionType,len(@ExceptionType)-1)
       Select @iO = Convert(Int,SubString(@Oper,1,CharIndex(Char(1),@Oper)-1))
       Select @O = Case    When @iO =  0 Then ' < '
 	  	  	 When  @iO = 1 Then ' <= '
 	  	  	 When @iO =  2 Then ' = '
 	  	  	 When  @iO = 3 Then ' >= '
 	  	  	 When @iO =  4 Then ' > '
 	  	  	 When @iO =  5 Then ' <> '
 	  	  	 When @iO =  6 Then ' Like '
 	  	  	 When @iO =  7 Then ' Not Like '
 	  	 End
       Select @Oper = SubString(@Oper,CharIndex(Char(1),@Oper),len(@Oper))
       Select @Oper = Right(@Oper,len(@Oper)-1)
       Select @Val = SubString(@Values,1,CharIndex(Char(1),@Values)-1)
       Select @Values = SubString(@Values,CharIndex(Char(1),@Values),len(@Values))
       Select @Values = Right(@Values,len(@Values)-1)
       Select @Val = Case When @iO =  6 Then  REPLACE(@Val,'*','%')
 	  	  	 When @iO =  7 Then  REPLACE(@Val,'*','%')
 	  	  	 Else @Val
 	             End
       Select @Val = Case When @iO =  6 Then '''' + REPLACE(@Val,'?','_') + ''''
 	  	  	 When @iO =  7 Then  '''' + REPLACE(@Val,'?','_') + ''''
 	  	  	 Else @Val
 	             End
       Select @A = Convert(Int,SubString(@Actions,1,CharIndex(Char(1),@Actions)-1))
       Select @Actions = SubString(@Actions,CharIndex(Char(1),@Actions),len(@Actions))
       Select @Actions = Right(@Actions,len(@Actions)-1)
       Select @Sql = Case When @iET = 1 Then 'Select Customer_Id From Customer Where Customer_Name '
 	  	  	   When @iET = 2 Then 'Select Customer_Id From Customer Where Customer_Name '
                     End
    If @iO = 6 or @iO = 7
     Begin
      Select @Sql =  @Sql + @O  + '' + @Val + ''
     End
    Else 
     Begin
      Select @Sql =  @Sql +  @O  + ' ''' + @Val + ''''
     End
 	 
  Select @SQL = 'Insert into #Customer2 ' + @Sql
  Execute (@SQL)
  If @A = 0
     Begin
 	 Insert into #Customers Select * From #Customer2
     End
  Else
    Begin
 	 Delete From #Customers Where Customer_Id Not In (Select Customer_Id From #Customer2)
    End
  If  @iET = 1
    IF @A = 0 
      Insert into  #Output (Exception_Desc,Customer_name,Value) 
       Select 'Ship To',c.Customer_Name,co.Plant_Order_Number
       From Customer_Order_line_Items col
       Join Customer_orders co on col.order_id = co.Order_id
       Join Customer c ON co.customer_id = col.Consignee_Id
       Where col.Consignee_Id in (Select Customer_Id From #Customer2)
     Else
       Delete From #Output 
 	 Where Exception_Desc = 'Ship To' and Value in (Select co.Plant_Order_Number
       From Customer_Order_line_Items col
       Join Customer_orders co on col.order_id = co.Order_id
       Where col.Consignee_Id in (Select Customer_Id From #Customer2))
  Else If @iET = 2
    IF @A = 0 
      Insert into  #Output (Exception_Desc,Customer_name,Value) 
        Select 'Bill To',c.Customer_Name,co.Plant_Order_Number
        From customer_orders co
        Join Customer c ON co.customer_id = c.customer_Id
        Where co.Customer_Id in (Select Customer_Id From #Customer2)
    Else
      Delete From #Output 
       Where Exception_Desc = 'Bill To' and Value in ( 
        Select co.Plant_Order_Number From customer_orders co
        Where co.Customer_Id in (Select Customer_Id From #Customer2))
  Delete From #Customer2
 End
Select Distinct Exception_Desc,Customer_name,Value From #Output 
Drop Table #Customers
Drop Table #Customer2
Drop Table #Output
/*
select @Search1 = REPLACE(@Search1,'*','%')
select @Search1 = 'Select Customer_Id,Customer_Name,Customer_Code From customer where Customer_Name like ' +  '''' + REPLACE(@Search1,'?','_') + ''''
select @Search2 = REPLACE(@Search2,'*','%')
select @Search2 = 'Select Customer_Id,Customer_Name,Customer_Code From customer where Customer_Name like ' +  '''' + REPLACE(@Search2,'?','_') + ''''
Execute(@Search1)
Execute(@Search2)
*/
