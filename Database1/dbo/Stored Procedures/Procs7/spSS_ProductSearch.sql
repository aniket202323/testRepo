Create Procedure dbo.spSS_ProductSearch
 @ProductGroupOrFamilyId int = NULL,
 @ProductString nVarChar(100),
 @ProductGroupFlg int, --Determine whether to search by Product Family or Product Group
 @PUId int
AS
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @FlgAnd int,
         @MoreFlg int
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgAnd = 0
 Select @MoreFlg = 0
 Select @SQLCOnd0 = NULL
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select P.Prod_Id, P.Prod_Desc, P.Prod_Code, ' + 
                       'P.Event_ESignature_Level, P.Product_Change_ESignature_Level ' + 
                       'From Products P '
--------------------------------------------------------------------
-- Production Unit
--------------------------------------------------------------------
 If (@PUId Is Not Null and @PUId <> 0)
  Begin
   Select @SQLCond0 = 'Join PU_Products PP on PP.Prod_Id = P.Prod_Id '
   Select @SQLCommand = @SQLCommand + @SQLCond0
   Select @MoreFlg = 1
  End
--------------------------------------------------------------------
-- Product Group
--------------------------------------------------------------------
 If (@ProductGroupFlg = 0 and (@ProductGroupOrFamilyId Is Not NULL and @ProductGroupOrFamilyId <> 0))
  Begin
   Select @SQLCond0 = 'Join Product_Group_Data PG on PG.Prod_Id = P.Prod_Id ' +
                      'Where PG.Product_Grp_Id = ' + Convert(nVarChar(05), @ProductGroupOrFamilyId)
   Select @SQLCommand = @SQLCommand + @SQLCond0
   Select @FlgAnd = 1
  End
--------------------------------------------------------------------
-- Product Family
--------------------------------------------------------------------
 If (@ProductGroupFlg = -1 and (@ProductGroupOrFamilyId Is Not NULL and @ProductGroupOrFamilyId <> 0))
  Begin
   Select @SQLCond0 = 'Where P.Product_Family_Id = ' + Convert(nVarChar(05), @ProductGroupOrFamilyId)
   Select @SQLCommand = @SQLCommand + @SQLCond0
   Select @FlgAnd = 1
  End
-------------------------------------------------------------------
-- Product Description
-------------------------------------------------------------------
 If (@ProductString Is Not Null and Len(@ProductString)>0)
  Begin
   Select @SQLCond0 = "P.Prod_Desc Like '%" + @ProductString + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
-------------------------------------------------------------------
-- Production Unit - Add Where Clause
-------------------------------------------------------------------
 If @MoreFlg = 1
  Begin
   Select @SQLCond0 = "PP.PU_Id = " + Convert(nVarChar(05), @PUId)
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand = @SQLCommand + ' And (' + @SQLCond0 + ')'
    End
   else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
    End
  End
 Select @SQLCond0 = "P.Prod_Id > 1 "
 If (@FlgAnd=1)
  Begin
   Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')'
  End
 Else
  Begin
   Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')'
   Select @FlgAnd = 1  
  End 
----------------------------------------------------------------
--  Output partial result to a temp table
-----------------------------------------------------------------
 Create Table #Temp (
  Prod_Id Int NULL,
  Prod_Desc nVarChar(50) Null,
  Prod_Code nVarChar(50) Null,
  Event_Esignature_Level int Null,
  Product_Change_Esignature_Level int Null
 )
 Select @SQLCommand = 'Insert Into #Temp ' + @SQLCommand 
 Exec (@SQLCommand)
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
 Select Prod_Desc as 'Prod Desc', Prod_Code as 'Prod Code',
        Event_Esignature_Level as 'Event ESignature Level', 
        Product_Change_Esignature_Level as 'Product Change ESignature Level', Prod_Id as 'Prod Id' 
   From #Temp
    Order By Prod_Desc
 Drop Table #Temp
