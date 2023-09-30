--  spEM_BOMSearchFormulations Null,null,null,'11',1
CREATE PROCEDURE dbo.spEM_BOMSearchFormulations
 	 @ProductIds  	  	 nvarchar(3000),
 	 @POs 	  	  	 nvarchar(3000),
 	 @Fks 	  	  	 nvarchar(3000),
 	 @SearchString  	  	 nVarChar(100),
 	 @SearchType 	  	 Int,
 	 @FamilyId 	  	 Int,
 	 @BOMId 	  	  	 Int,
 	 @FromDate 	  	 datetime,
 	 @ToDate 	  	  	 datetime
AS
declare @sql varchar(8000)
set @sql='
CREATE PROCEDURE #spEM_BOMSearchFormulations
 	 @ProductIds  	  	 nvarchar(3000),
 	 @POs 	  	  	 nvarchar(3000),
 	 @Fks 	  	  	 nvarchar(3000),
 	 @SearchString  	  	 nVarChar(100),
 	 @SearchType 	  	 Int,
 	 @FamilyId 	  	 Int,
 	 @BOMId 	  	  	 Int,
 	 @FromDate 	  	 datetime,
 	 @ToDate 	  	  	 datetime
as
Declare @UseCode TinyInt,
 	  	  	  	 @LikeFlag 	 TinyInt,
 	  	  	  	 @SQLWhere 	 nvarchar(1000)
Declare @Products table (prodkey int)
WHILE CHARINDEX('' '',@productids)>0
BEGIN
 	 WHILE CHARINDEX('' '',@productids)=1 SET @productids=SUBSTRING(@productids,2,3000)
 	 IF LEN(@productids)>0 AND CHARINDEX('' '',@productids)>0
 	 BEGIN
 	  	 INSERT INTO @Products VALUES (CAST(LEFT(@productids,CHARINDEX('' '',@productids)-1) as int))
 	  	 SET @productids=SUBSTRING(@productids,CHARINDEX('' '',@productids)+1,3000)
 	 END
END
IF LEN(@productids)>0
 	 INSERT INTO @Products VALUES (@productids)
Declare @Orders table (ordkey int)
WHILE CHARINDEX('' '',@POs)>0
BEGIN
 	 WHILE CHARINDEX('' '',@POs)=1 SET @POs=SUBSTRING(@POs,2,3000)
 	 IF LEN(@POs)>0 AND CHARINDEX('' '',@POs)>0
 	 BEGIN
 	  	 INSERT INTO @Orders VALUES (CAST(LEFT(@POs,CHARINDEX('' '',@POs)-1) as int))
 	  	 SET @POs=SUBSTRING(@POs,CHARINDEX('' '',@POs)+1,3000)
 	 END
END
IF LEN(@POs)>0
 	 INSERT INTO @Orders VALUES (@POs)
Declare @fk table (fkey int)
WHILE CHARINDEX('' '',@Fks)>0
BEGIN
 	 WHILE CHARINDEX('' '',@Fks)=1 SET @Fks=SUBSTRING(@Fks,2,3000)
 	 IF LEN(@Fks)>0 AND CHARINDEX('' '',@Fks)>0
 	 BEGIN
 	  	 INSERT INTO @fk VALUES (CAST(LEFT(@Fks,CHARINDEX('' '',@Fks)-1) as int))
 	  	 SET @Fks=SUBSTRING(@Fks,CHARINDEX('' '',@Fks)+1,3000)
 	 END
END
IF LEN(@Fks)>0
 	 INSERT INTO @fk VALUES (@Fks)
If @SearchString Is Not Null
 	 Begin
 	  	 Select @LikeFlag = Left(@SearchString,1)
 	  	 Select @SearchString = substring(@SearchString,2,len(@SearchString)-1)
 	  	 If @LikeFlag = 0
 	  	  	 Select @SearchString =  @SearchString + ''%''
 	  	 Else If @LikeFlag = 1
 	  	  	 Select @SearchString = ''%'' + @SearchString + ''%''
 	  	 Else
 	  	  	 Select @SearchString =  ''%''  + @SearchString
 	 End
select distinct '+case @SearchType
 	 when 1 then '[Id] = bomfam.BOM_Family_Id, [Desc] = bomfam.BOM_Family_Desc
 	 '
 	 when 2 then '[Id] = bom.BOM_Id, [Desc] = bom.BOM_Desc
 	 '
 	 when 3 then '[Id] = bomf.BOM_Formulation_Id, [Desc] = bomf.BOM_Formulation_Desc
 	 '
 	 when 4 then '[Id] = bomf.BOM_Formulation_Id, [Desc] = bomf.BOM_Formulation_Desc
 	 '
end+'from
'+case @SearchType
 	 when 1 then ' 	 Bill_Of_Material_Family bomfam
 	 left join Bill_Of_Material bom on bomfam.BOM_Family_Id=bom.BOM_Family_Id
'
else ' 	 Bill_Of_Material bom
'
end+' 	 left join Bill_Of_Material_Formulation bomf on bom.BOM_Id=bomf.BOM_Id
 	 left join Bill_Of_Material_Formulation_Item bomfi on bomf.BOM_Formulation_Id=bomfi.BOM_Formulation_Id
 	 left join Production_Plan pp on bomf.BOM_Formulation_Id=pp.BOM_Formulation_Id
'+case 
 	 when not @fKs is null then ' 	 left join (
 	  	 select xr.Actual_Id
 	  	 from 
 	  	  	 Data_Source_XRef xr 
 	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	 inner join @fk fk on xr.DS_XRef_Id=fk.fkey
 	  	 Where 
 	  	  	 t.TableName=''Products''
 	 ) fkp on bomfi.Prod_Id=fkp.Actual_Id
 	 left join (
 	  	 select xr.Actual_Id
 	  	 from 
 	  	  	 Data_Source_XRef xr 
 	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	 inner join @fk fk on xr.DS_XRef_Id=fk.fkey
 	  	 Where 
 	  	  	 t.TableName=''Production_Plan''
 	 ) fko on pp.PP_Id=fko.Actual_Id'
 	 when not @POs is null then ' 	 left join @Orders pos on pp.PP_Id=pos.ordkey'
 	 when not @productids is null then ' 	 left join Bill_Of_Material_Product bomp on bomf.BOM_Formulation_Id=bomp.BOM_Formulation_Id
 	 left join @Products prd on bomp.Prod_Id=prd.prodkey'
 	 else ''
end+'
where'+case @SearchType
 	 when 1 then ' 	 (bomfam.BOM_Family_Desc like @SearchString OR @SearchString is null)'
 	 when 2 then ' 	 (bom.BOM_Desc like @SearchString OR @SearchString is null)
 	 and (@FamilyId is null or @FamilyId=-1 or bom.BOM_Family_Id=@FamilyId)'
 	 when 3 then ' 	 (@BomId=-1 or bomf.BOM_Id=@BomId)
 	 and bomf.Master_BOM_Formulation_Id is null
 	 and (bomf.BOM_Formulation_Desc like @SearchString OR @SearchString is null)
 	 and (@FamilyId is null or @FamilyId=-1 or bom.BOM_Family_Id=@FamilyId)
 	 and (
 	  	 (bomf.Effective_Date<=@ToDate and bomf.Expiration_Date is null)
 	  	 or (bomf.Effective_Date<=@FromDate and bomf.Expiration_Date>=@FromDate)
 	  	 or (bomf.Effective_Date<=@ToDate and bomf.Expiration_Date>=@ToDate)
 	  	 or (bomf.Effective_Date>@FromDate and bomf.Expiration_Date<@ToDate)
 	 )'
 	 when 4 then ' 	 (@BomId=-1 or bomf.BOM_Id=@BomId)
 	 and (bomf.BOM_Formulation_Desc like @SearchString OR @SearchString is null)
 	 and (@FamilyId is null or @FamilyId=-1 or bom.BOM_Family_Id=@FamilyId)
 	 and (
 	  	 (bomf.Effective_Date<=@ToDate and bomf.Expiration_Date is null)
 	  	 or (bomf.Effective_Date<=@FromDate and bomf.Expiration_Date>=@FromDate)
 	  	 or (bomf.Effective_Date<=@ToDate and bomf.Expiration_Date>=@ToDate)
 	  	 or (bomf.Effective_Date>@FromDate and bomf.Expiration_Date<@ToDate)
 	 )'
end+'
'+case 
 	 when not @fKs is null then 'and (@Fks is null or not fkp.Actual_Id is null or not fko.Actual_Id is null )'
 	 when not @POs is null then 'and (@POs is null or not pos.ordkey is null)'
 	 when not @productids is null then 'and (@productids is null or not prd.prodkey is null)'
 	 else ''
end+
case  
 	 when @SearchType in (3,4) then 'union select [Id] = bomfp.BOM_Formulation_Id, [Desc] = bomfp.BOM_Formulation_Desc
 	  	 from
 	  	 Bill_Of_Material bom
 	  	 left join Bill_Of_Material_Formulation bomf on bom.BOM_Id=bomf.BOM_Id
 	  	 left join Bill_Of_Material_Formulation bomfp on bomf.Master_BOM_Formulation_Id=bomfp.BOM_Formulation_Id
 	  	 left join Bill_Of_Material_Formulation_Item bomfi on bomf.BOM_Formulation_Id=bomfi.BOM_Formulation_Id
 	  	 left join Production_Plan pp on bomf.BOM_Formulation_Id=pp.BOM_Formulation_Id
'+case 
 	  	 when not @fKs is null then ' 	 left join (
 	  	 select xr.Actual_Id
 	  	 from 
 	  	  	 Data_Source_XRef xr 
 	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	 inner join @fk fk on xr.DS_XRef_Id=fk.fkey
 	  	 Where 
 	  	  	 t.TableName=''Products''
 	 ) fkp on bomfi.Prod_Id=fkp.Actual_Id
 	 left join (
 	  	 select xr.Actual_Id
 	  	 from 
 	  	  	 Data_Source_XRef xr 
 	  	  	 inner join Tables t ON xr.Table_Id=t.TableId
 	  	  	 inner join @fk fk on xr.DS_XRef_Id=fk.fkey
 	  	 Where 
 	  	  	 t.TableName=''Production_Plan''
 	 ) fko on pp.PP_Id=fko.Actual_Id'
 	  	 when not @POs is null then ' 	 left join @Orders pos on pp.PP_Id=pos.ordkey'
 	  	 when not @productids is null then ' 	 left join Bill_Of_Material_Product bomp on bomf.BOM_Formulation_Id=bomp.BOM_Formulation_Id
 	 left join @Products prd on bomp.Prod_Id=prd.prodkey'
 	  	 else ''
 	 end+'
where (@BomId=-1 or bomf.BOM_Id=@BomId)
 	 and bomf.Master_BOM_Formulation_Id is not null
 	 and (bomf.BOM_Formulation_Desc like @SearchString OR @SearchString is null)
 	 and (@FamilyId is null or @FamilyId=-1 or bom.BOM_Family_Id=@FamilyId)
 	 and (
 	  	 (bomf.Effective_Date<=@ToDate and bomf.Expiration_Date is null)
 	  	 or (bomf.Effective_Date<=@FromDate and bomf.Expiration_Date>=@FromDate)
 	  	 or (bomf.Effective_Date<=@ToDate and bomf.Expiration_Date>=@ToDate)
 	  	 or (bomf.Effective_Date>@FromDate and bomf.Expiration_Date<@ToDate)
 	 )
'+case 
 	  	 when not @fKs is null then 'and (@Fks is null or not fkp.Actual_Id is null or not fko.Actual_Id is null )'
 	  	 when not @POs is null then 'and (@POs is null or not pos.ordkey is null)'
 	  	 when not @productids is null then 'and (@productids is null or not prd.prodkey is null)'
 	  	 else ''
 	 end
 	 else ''
end
exec (@sql)
exec #spEM_BOMSearchFormulations @ProductIds,@POs,@Fks,@SearchString,@SearchType,@FamilyId,@BOMId,@FromDate,@ToDate
exec ('drop proc #spEM_BOMSearchFormulations')
