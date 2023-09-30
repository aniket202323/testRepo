Create Procedure dbo.spSS_WasteEventByDescription
 @Desc nVarChar(50) =Null,
 @StartDate DateTime = Null,
 @EndDate DateTime = Null
AS
 Declare @SQLCommand Varchar(2500),
 	  @SQLCond0 nVarChar(255),
 	  @FlgAnd int
------------------------------------------------------------------------
-- Initialize variables
------------------------------------------------------------------------
 Select @FlgAnd = 0 
 Select @SQLCond0 = Null
 Select @SQLCommand = 'Select E.Event_id, E.PU_Id, P.PU_Desc, E.Event_Id, E.Event_Num, E.TimeStamp ' +
                      'From Events E Inner Join Prod_Units P On E.PU_Id = P.PU_Id  '
-- Select E.Event_id, E.PU_Id, P.PU_Desc, E.Event_Id, E.Event_Num, E.TimeStamp
--  From Events E Inner Join Prod_Units P On E.PU_Id = P.PU_Id
--   Where Event_Num Like '%' + @Desc + '%'
--    Order by P.PU_Desc, E.Event_Num
----------------------------------------------------------------------
-- Append Description to the SQL command if this parameter was passed
-- flgAnd=1 means all other parameters should append 'And'
-- flgAnd=0 means the first parameter to be appended should also append the 'WHere' word
-----------------------------------------------------------------------
 If (@Desc Is Not Null And Len(@Desc)>0)
  Begin
   Select @SQLCond0 = " E.Event_Num Like '%" + @Desc + "%'"
   If @FlgAnd = 1  	 
    Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond0
   Else
    Begin
     Select @SQLCommand = @SQLCommand + ' Where ' + @SQLCond0 	 
     Select @FlgAnd = 1
    End 
  End
---------------------------------------------------------------------
-- Append Start/End Time to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@StartDate Is Not Null And @StartDate>'01-Jan-1970' 
 And @EndDate Is Not Null And @EndDate>'01-Jan-1970')
  Begin
   Select @SQLCond0 = "E.TimeStamp Between '" + Convert(nVarChar(30), @StartDate) + "' And '" +
                                                Convert(nVarChar(30), @EndDate) + "'"   
   If @FlgAnd = 1  	 
    Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond0
   Else
    Begin
     Select @SQLCommand = @SQLCommand + ' Where ' + @SQLCond0 	 
     Select @FlgAnd = 1
    End
  End
--------------------------------------------------------------------
-- Append Order By and run it
----------------------------------------------------------------------
 Select @SQLCommand = @SQLCommand + ' Order by P.PU_Desc, E.Event_Num'
 Exec (@SQLCommand)
--select @sqlcommand
--select right(@sqlcommand,20)
