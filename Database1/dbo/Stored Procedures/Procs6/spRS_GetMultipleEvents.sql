--exec [spRS_GetMultipleEvents] 1,''
CREATE PROCEDURE [dbo].[spRS_GetMultipleEvents]
@Event_Ids varchar(7000),
@InTimeZone varchar(200) = NULL
 AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderID Int,Var_Id Int)
Select @I = 1
Select @INstr = @Event_Ids + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId,Var_Id) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
Select #t.Var_Id 
  	 ,convert(varchar(20), e.Event_Num) + ' - ' + Convert(varchar(20), p.Prod_Code) + ' - ' + Convert(varchar(25),  [dbo].[fnServer_CmnConvertFromDbTime] (e.timeStamp,@InTimeZone)  ) 
 	 ,EventNumber = e.Event_Num 
 	 ,'TimeStamp' =   [dbo].[fnServer_CmnConvertFromDbTime] (e.timeStamp,@InTimeZone), ProductCode = p.Prod_Code 
 	 from #t
 	 Join Events e on #t.Var_Id = e.Event_Id
 	 Join Production_Starts ps on ps.PU_Id = e.PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null)) 
 	 Join Products p on p.Prod_Id = ps.Prod_Id 
Drop Table #t
