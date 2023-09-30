--  spEM_BOMSearchOrders 'ord1',null,null,null,null,null
CREATE PROCEDURE dbo.spEM_BOMSearchOrders
 	 @SearchString 	  	 nVarChar(100),
 	 @PathId 	  	  	 Int,
 	 @Status 	  	  	 Int,
 	 @from 	  	  	 datetime,
 	 @to 	  	  	 datetime,
 	 @prodids 	  	 nvarchar(3000)
AS
Declare @Products table (prodkey int)
WHILE CHARINDEX(' ',@prodids)>0
BEGIN
 	 WHILE CHARINDEX(' ',@prodids)=1 SET @prodids=SUBSTRING(@prodids,2,3000)
 	 IF LEN(@prodids)>0 AND CHARINDEX(' ',@prodids)>0
 	 BEGIN
 	  	 INSERT INTO @Products VALUES (CAST(LEFT(@prodids,CHARINDEX(' ',@prodids)-1) as int))
 	  	 SET @prodids=SUBSTRING(@prodids,CHARINDEX(' ',@prodids)+1,3000)
 	 END
END
IF LEN(@prodids)>0
 	 INSERT INTO @Products VALUES (@prodids)
Declare @PONumber TinyInt,
 	 @LikeFlag 	 TinyInt,
 	 @SQLWhere 	 nvarchar(1000)
Declare @Orders Table (PP_Id Int,Process_Order nvarchar(50),Path_Id int,PP_Status_Id int,Forecast_Start_Date datetime, Forecast_End_Date datetime,Prod_Id int)
If @SearchString Is Not Null
 	 Begin
 	  	 Select @PONumber = Left(@SearchString,1)
 	  	 Select @LikeFlag = substring(@SearchString,2,1)
 	  	 Select @SearchString = substring(@SearchString,3,len(@SearchString)-2)
 	  	 If @LikeFlag = 0
 	  	  	 Select @SearchString =  @SearchString + '%'
 	  	 Else If @LikeFlag = 1
 	  	  	 Select @SearchString = '%' + @SearchString + '%'
 	  	 Else
 	  	  	 Select @SearchString =  '%'  + @SearchString 
 	  	 If @PONumber = 0
 	  	  	  	 Insert Into @Orders(PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id)
 	  	  	  	  	 Select PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id From Production_Plan Where Process_Order like @SearchString
 	 End
If @Status is Not null
 	 If @SearchString is Null
 	  	 Insert Into @Orders(PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id)
 	  	  	 Select PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id 
 	  	  	 From Production_Plan Where PP_Status_Id=@Status
 	 Else
 	  	 Delete From @Orders where PP_Status_Id<>@Status
If @from is Not null
 	 If @SearchString is Null and @status is Null
 	  	 Insert Into @Orders(PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id)
 	  	  	 Select PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id 
 	  	  	 From Production_Plan Where @from<=Forecast_Start_Date OR @from<=Forecast_End_Date
 	 Else
 	  	 Delete From @Orders where @from>Forecast_End_Date 
If @to is Not null
 	 If @SearchString is Null and @status is Null and @from is null
 	  	 Insert Into @Orders(PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id)
 	  	  	 Select PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id 
 	  	  	 From Production_Plan Where @to>=Forecast_Start_Date OR @to>=Forecast_End_Date
 	 Else
 	  	 Delete From @Orders where @to<Forecast_Start_Date 
If @PathId is not Null
 	 If @SearchString is Null and @status is Null and @from is null and @to is null
 	  	 Insert Into @Orders(PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id)
 	  	  	 Select PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id 
 	  	  	 From Production_Plan Where Path_Id=@PathId
 	 Else
 	  	 Delete From @Orders where @PathId<>Path_Id or Path_Id is null
If @prodids is not Null
 	 If @SearchString is Null and @status is Null and @from is null and @to is null and @PathId is null
 	  	 Insert Into @Orders(PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id)
 	  	  	 Select PP_Id,Process_Order,Path_Id,PP_Status_Id,Forecast_Start_Date,Forecast_End_Date,Prod_Id 
 	  	  	 From Production_Plan Where Prod_Id IN (SELECT prodkey FROM @Products)
 	 Else
 	  	 Delete From @Orders where Prod_Id NOT IN (SELECT prodkey FROM @Products)
select distinct * from @Orders
