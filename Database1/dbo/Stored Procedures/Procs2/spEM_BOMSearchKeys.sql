--  spEM_BOMSearchKeys 'key1',null,null
CREATE PROCEDURE dbo.spEM_BOMSearchKeys
 	 @SearchString 	  	 nVarChar(100),
 	 @prodids 	  	 nvarchar(3000),
 	 @ordids 	  	  	 nvarchar(3000)
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
Declare @Orders table (ordkey int)
WHILE CHARINDEX(' ',@ordids)>0
BEGIN
 	 WHILE CHARINDEX(' ',@ordids)=1 SET @ordids=SUBSTRING(@ordids,2,3000)
 	 IF LEN(@ordids)>0 AND CHARINDEX(' ',@ordids)>0
 	 BEGIN
 	  	 INSERT INTO @Orders VALUES (CAST(LEFT(@ordids,CHARINDEX(' ',@ordids)-1) as int))
 	  	 SET @ordids=SUBSTRING(@ordids,CHARINDEX(' ',@ordids)+1,3000)
 	 END
END
IF LEN(@ordids)>0
 	 INSERT INTO @Orders VALUES (@ordids)
Declare @PONumber TinyInt,
 	 @LikeFlag 	 TinyInt,
 	 @SQLWhere 	 nvarchar(1000)
Declare @Keys Table (DS_XRef_Id int,Foreign_Key nvarchar(255),Parent_PP_Id int ,Prod_Id int)
set @PONumber=0
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
 	  	  	  	 Insert Into @Keys(DS_XRef_Id,Foreign_Key)
 	  	  	  	 Select 
 	  	  	  	  	 xr.DS_XRef_Id, xr.Foreign_Key+'<'+p.Prod_Desc+'>'
 	  	  	  	 From 
 	  	  	  	  	 Data_Source_XRef xr 
 	  	  	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	  	  	 inner join Products p ON xr.Actual_Id=p.Prod_Id
 	  	  	  	 Where 
 	  	  	  	  	 t.TableName='Products' 
 	  	  	  	  	 and xr.Foreign_Key like @SearchString
 	  	 else
 	  	  	  	 Insert Into @Keys(DS_XRef_Id,Foreign_Key)
 	  	  	  	 Select 
 	  	  	  	  	 xr.DS_XRef_Id, xr.Foreign_Key+'<'+pp.Process_Order+'>'
 	  	  	  	 From 
 	  	  	  	  	 Data_Source_XRef xr 
 	  	  	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	  	  	 inner join Production_Plan pp ON xr.Actual_Id=pp.PP_Id
 	  	  	  	 Where 
 	  	  	  	  	 t.TableName='Production_Plan' 
 	  	  	  	  	 and xr.Foreign_Key like @SearchString
 	 End
If @PONumber = 0
 	 If @prodids is not Null
 	  	 If @SearchString is Null 
 	  	  	 Insert Into @Keys(DS_XRef_Id,Foreign_Key)
 	  	  	 Select 
 	  	  	  	 xr.DS_XRef_Id, xr.Foreign_Key+'<'+p.Prod_Desc+'>'
 	  	  	 From 
 	  	  	  	 Data_Source_XRef xr 
 	  	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	  	 inner join Products p ON xr.Actual_Id=p.Prod_Id
 	  	  	  	 inner join @Products pi on p.Prod_Id=pi.prodkey
 	  	  	 Where 
 	  	  	  	 t.TableName='Products' 
 	  	 Else
 	  	  	 Delete From k
 	  	  	 From 
 	  	  	  	 @Keys k
 	  	  	  	 inner join Data_Source_XRef xr ON xr.DS_XRef_Id=k.DS_XRef_Id
 	  	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	  	 inner join Products p ON xr.Actual_Id=p.Prod_Id
 	  	  	  	 left join @Products pi on p.Prod_Id=pi.prodkey
 	  	  	 Where 
 	  	  	  	 t.TableName='Products' 
 	  	  	  	 and pi.prodkey is null
If @ordids is not Null
 	  	 If @SearchString is Null 
 	  	  	 Insert Into @Keys(DS_XRef_Id,Foreign_Key)
 	  	  	 Select 
 	  	  	  	 xr.DS_XRef_Id, xr.Foreign_Key+'<'+pp.Process_Order+'>'
 	  	  	 From 
 	  	  	  	 Data_Source_XRef xr 
 	  	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	  	 inner join Production_Plan pp ON xr.Actual_Id=pp.PP_Id
 	  	  	  	 inner join @Orders ord on pp.PP_Id=ord.ordkey
 	  	  	 Where 
 	  	  	  	 t.TableName='Production_Plan' 
 	  	 Else
 	  	  	 Delete From k
 	  	  	 From 
 	  	  	  	 @Keys k
 	  	  	  	 inner join Data_Source_XRef xr ON xr.DS_XRef_Id=k.DS_XRef_Id
 	  	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	  	 inner join Production_Plan pp ON xr.Actual_Id=pp.PP_Id
 	  	  	  	 left join @Orders ord on pp.PP_Id=ord.ordkey
 	  	  	 Where 
 	  	  	  	 t.TableName='Production_Plan' 
 	  	  	  	 and ord.ordkey is null
select distinct * from @Keys
