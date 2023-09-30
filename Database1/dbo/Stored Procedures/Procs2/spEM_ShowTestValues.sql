CREATE PROCEDURE dbo.spEM_ShowTestValues
 	 @Var_Id 	  	 Int,
 	 @StartTime  DateTime,
 	 @EndTime 	 DateTime,
 	 @Count     	 Int
  AS
Declare @SqlOutput varchar(7000)
Declare @Default_Value nVarChar(25)
Declare @ET Int,@PUID Int,@Calc_Id Int,@CalcName nvarchar(50),@CalcVarID as int
Select @ET = Event_Type,@PUID = PU_Id,@Calc_Id = Calculation_Id From Variables Where Var_Id = @Var_Id
Select @PUID = coalesce(Master_Unit,@PUID) From prod_Units where PU_Id = @PUID
DECLARE @T Table  (TimeColumns nVarChar(100))
Create Table #Output (Event nvarchar(50),
 	  	  	  	  	  	 Value nvarchar(25),
 	  	  	  	  	  	 [Result On] DateTime,
 	  	  	  	  	  	 [User] nVarChar(100),
 	  	  	  	  	  	 Canceled Int,
 	  	  	  	  	  	 [Array Data] nVarChar(3),
 	  	  	  	  	  	 [Entry On] DateTime)
Insert into @T(TimeColumns) Values ('Result On')
Insert into @T(TimeColumns) Values ('Entry On')
Select * From @T
Select @SqlOutput = 'Select Value,[Result On],[User],Canceled,[Array Data],[Entry On]'
If @Count = 0
  Begin
   Set Rowcount  500
 	 If @ET = 1
 	  Begin
       Insert Into #Output(Event,Value,[Result On],[User],Canceled,[Array Data],[Entry On])
 	    SELECT [Event] = Coalesce(e.Event_Num,''),[Value] = Coalesce(t.Result,'Null'),[Result On] = t.Result_On,[User] = u.Username,t.Canceled,[Array Data] = case When t.Array_Id Is NUll Then 'No' Else 'Yes' End,[Entry On] = t.Entry_On
 	  	 From tests t
 	  	 Left Join Users u on u.user_Id = t.Entry_By
 	  	 Left Join Events e On e.Timestamp = t.Result_On and e.PU_Id = @PUID
 	  	 where t.Var_Id = @Var_Id and t.Result_On Between  @StartTime and @EndTime
 	  	 Order by t.Result_On asc
     End
 	 Else
 	   Begin
 	  	 Insert Into #Output(Event,Value,[Result On],[User],Canceled,[Array Data],[Entry On])
 	  	 SELECT '',[Value] = Coalesce(t.Result,'Null'),[Result On] = Result_On,[User] = u.Username,Canceled,[Array Data] = case When Array_Id Is NUll Then 'No' Else 'Yes' End,[Entry On] = Entry_On
 	  	   From tests t
 	  	   Left Join Users u on u.user_Id = t.Entry_By
 	  	   where Var_Id = @Var_Id and Result_On Between  @StartTime and @EndTime
 	  	   Order by Result_On asc
 	   End
  End
Else
  Begin
   Set Rowcount  @Count
 	 If @ET = 1
 	   Begin
       Insert Into #Output(Event,Value,[Result On],[User],Canceled,[Array Data],[Entry On])
 	    SELECT [Event] = Coalesce(e.Event_Num,''),[Value] = Coalesce(t.Result,'Null'),[Result On] = t.Result_On,[User] = u.Username,t.Canceled,[Array Data] = case When t.Array_Id Is NUll Then 'No' Else 'Yes' End,[Entry On] = t.Entry_On
 	  	 From tests t
 	  	 Left Join Users u on u.user_Id = t.Entry_By
 	  	 Left Join Events e On e.Timestamp = t.Result_On and e.PU_Id = @PUID
 	  	 where t.Var_Id = @Var_Id and t.Result_On Between '01/01/1970' and @StartTime
 	  	 Order by t.Result_On desc
 	   End
 	 Else
 	   Begin
 	  	 Insert Into #Output(Event,Value,[Result On],[User],Canceled,[Array Data],[Entry On])
 	  	 SELECT '',[Value] = Coalesce(t.Result,'Null'),[Result On] = Result_On,[User] = u.Username,Canceled,[Array Data] = case When Array_Id Is NUll Then 'No' Else 'Yes' End,[Entry On] = Entry_On
 	  	 From tests t
 	  	 Left Join Users u on u.user_Id = t.Entry_By
 	  	 where Var_Id = @Var_Id and Result_On Between '01/01/1970' and @StartTime
 	  	 Order by Result_On desc
 	   End
  End
Declare @Sql nvarchar(1000)
If @Calc_Id is Not Null
  Begin
 	 Alter Table #Output add [Calculation] nvarchar(50)
 	 Select @SqlOutput = @SqlOutput + ',Calculation'
 	 Select @Sql = 'Update #Output set Calculation = substring(Coalesce(Equation,''''),1,50) From Calculations where Calculation_Id = ' + Convert(nVarChar(10),@Calc_Id)
 	 Execute (@Sql)
 	 Declare C Cursor For Select c.Input_Name,Member_Var_Id,cd.Default_Value
 	  	  	  From Calculation_Inputs c
 	  	  	  Left Join Calculation_Input_Data cd on cd.Calc_Input_Id = c.Calc_Input_Id
 	  	  	  Where Calculation_Id = @Calc_Id and Result_Var_Id = @Var_Id
 	  	  	  Order by Calc_Input_Order
    Open C
FetchLoop:
    Fetch Next From C Into @CalcName,@CalcVarID,@Default_Value
 	   If @@Fetch_Status = 0
 	     Begin 	 
 	  	   Select @Sql = 'Alter Table #Output add [' + @CalcName + '] nvarchar(50)'
 	  	   Select @SqlOutput = @SqlOutput + ',[' + @CalcName + ']'
 	  	   Execute (@Sql)
   	  	   If @CalcVarID is null 
 	  	    	 Select @Sql = 'Update #Output Set [' + @CalcName + '] = ''' + @Default_Value + ''''
 	  	   Else
 	  	    	 Select @Sql = 'Update #Output Set [' + @CalcName + '] = Tests.Result From Tests Where Tests.Var_Id = ' + Convert(nVarChar(10),@CalcVarID) + ' and Tests.Result_On = #Output.[result On]'
 	  	   Execute (@Sql)
 	  	   Select @Sql = 'Update #Output Set [' + @CalcName + '] = ''' + @Default_Value + ''''  + ' Where ['  + @CalcName + '] Is Null'
 	  	   Execute (@Sql)
 	  	   Goto FetchLoop
 	     End
    Close c
    Deallocate c
  End
Select @SqlOutput = @SqlOutput + ' From #Output'
If @ET = 1
  Select * From #Output
Else
  Execute (@SqlOutput)
Set Rowcount  0
