CREATE PROCEDURE dbo.spRS_SearchCOAVariables
@ProdLine int = null,
@ProdUnit int = null,
@Mask varchar(50) = null,
@MaskFlag int = null,
@SearchBy int = null,
@Include int = null,
@IncludeStr varchar(1000) = null
 AS
-- ProdLine --Production Line Id
-- @ProdUnit --Production Unit Id
-- @Mask     --String to search for
-- @MaskFlag --Begins, Ends or Contains
-- @SearchBy --determines what field to apply search mask to
-- @Exclude  --comma separated list of var_id's to exclude
-- Local Stuff
Declare @SQLString varchar(255)
Declare @OrderBy varchar(25)
-- What is the order
If @SearchBy = 1 --Var Id
  Begin
    Select @SQLString = 'Select Var_Id, Var_Desc From Variables where Var_Desc Like ' --+ '''' + '%' + @Mask + '%' + ''''
    Select @OrderBy = ' order by Var_Desc'
  End 
Else
  Begin --Description
    --Select @SQLString = 'Select distinct ' + '''' + '0' + '''' + ', Test_Name From Variables where Test_Name Like ' --+ '''' + '%' + @Mask + '%' + ''''
    Select @SQLString = 'Select distinct Test_Name, Test_Name From Variables where Test_Name Like ' --+ '''' + '%' + @Mask + '%' + ''''
    Select @OrderBy = ' order by Test_Name'
  End
If @Mask is not null
  Begin
    If @MaskFlag = 0
      Begin
--        print 'Begins with ' + @Mask
        Select @SQLString = @SQLString + '''' + @Mask + '%' + ''''
      End
    Else
      If @MaskFlag = 1
        Begin
--          print 'Ends with ' + @Mask
          Select @SQLString = @SQLString + '''' + '%' + @Mask + ''''
        End
      Else
        Begin
--          print 'Contains ' + @Mask
          Select @SQLString = @SQLString + '''' + '%' + @Mask + '%' + ''''
        End
  End 
Else
  Select @SQLString = @SQLString + '''' + '%' + ''''
  Select @SQLString = @SQLString + ' and Var_id <> 0 '
-- is prodline null?
If @ProdLine Is not Null
  Begin
    -- Is produnit null?
    If @ProdUnit Is not null
      Begin
 	 Select @SQLString = @SQLString + ' and pu_id = ' + Convert(Varchar(5), @ProdUnit)
      End
    else
      Begin
 	 Select @SQLString = @SQLString + ' and pu_id in (Select PU_Id From Prod_Units Where PL_Id = ' + Convert(Varchar(5), @ProdLine) + ') '
      end
  End
-- Should I include or exclude a list of var_id's
If @IncludeStr is not null
  If @Include = 1
    Select @SQLString = @SQLString + ' and var_id in (' + @IncludeStr + ')'
  else
    Select @SQLString = @SQLString + ' and var_id not in (' + @IncludeStr + ')'
Select @SQLString = @SQLString + @OrderBy
--Select @SQLString
Exec (@SQLString)
