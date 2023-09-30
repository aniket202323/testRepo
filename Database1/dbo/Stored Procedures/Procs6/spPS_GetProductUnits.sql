CREATE PROCEDURE [dbo].[spPS_GetProductUnits]
		 @ProductIds		nvarchar(max) = null
		,@DepartmentIds		nvarchar(max) = Null
		,@LineIds			nvarchar(max) = Null
		,@UnitIds			nvarchar(max) = Null
		,@UserId			Int
		,@ProductId			Int = Null
		,@UnitId			Int = Null
		,@PageNumber        INT = NULL -- Current page number
        ,@PageSize          INT = NULL -- Total records per page to display

  AS


IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END
DECLARE @SQL varchar(max)

DECLARE @AllProducts Table (Product_Id Int)
DECLARE @AllDepartments Table (Dept_Id Int)
DECLARE @AllLines Table (PL_Id Int)
DECLARE @AllUnits Table (PU_Id Int)
DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);

Declare @ProductUnitData table (ProductId int, DeptId int, PLId int, PUId int,engUnitId int,totalRecords int)
IF @ProductId Is Not NULL and @UnitId Is Not NULL
BEGIN
	INSERT INTO @ProductUnitData(ProductId, DeptId, PLId, PUId,engUnitId)
		SELECT	p.Prod_Id, d.Dept_Id, l.PL_Id, u.PU_Id,es.Dimension_X_Eng_Unit_Id
		FROM	PU_Products p
		join	Prod_Units_Base u on u.PU_Id = p.PU_Id
		join	Prod_Lines_Base l on l.PL_Id = u.PL_Id
		Join	Departments_Base d on d.Dept_Id = l.Dept_Id
		left join Event_Configuration ec on ec.PU_Id = p.PU_Id and ec.ET_Id = 1
		left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
		WHERE	p.Prod_Id = @ProductId and p.PU_Id = @UnitId
	   UPDATE @ProductUnitData set totalRecords = (select count(*) FROM @ProductUnitData)

	   
SELECT   ProductId = p.ProductId
		,DepartmentId = p.DeptId
		,LineId = p.PLId
		,UnitId = p.PUId
		,EngUnitId = p.engUnitId
		,totalRecords = p.totalRecords
	FROM  @ProductUnitData p
	ORDER BY p.ProductId, p.PUId
	OFFSET @StartPosition ROWS
	FETCH NEXT @PageSize ROWS ONLY;

END
ELSE
BEGIN
	--UPDATE @ProductUnitData set totalRecords = (select count(*) FROM @ProductUnitData)
	SELECT @SQL  =''
	SELECT @SQL =
'
;WITH GetProds as (
SELECT	Distinct p.Prod_Id, l.Dept_Id, l.PL_Id, u.PU_Id,es.Dimension_X_Eng_Unit_Id
	FROM	PU_Products p
	join	Prod_Units_Base u on u.PU_Id = p.PU_Id '+Case when @UnitIds is not null Then ' AND u.pu_id in (' +@UnitIds+')' else '' end +'
	join	Prod_Lines_Base l on l.PL_Id = u.PL_Id '+Case when @LineIds is not null Then ' AND l.PL_Id in (' +@LineIds+')' else '' end +'
	'+Case when @DepartmentIds is not null Then ' AND l.Dept_Id in (' +@DepartmentIds+')' else '' end +'
	left join Event_Configuration ec on ec.PU_Id = p.PU_Id and ec.ET_Id = 1
	left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
Where 1=1
'
+CAse when @ProductIds is not null then ' AND p.Prod_Id in ('+@ProductIds+')' else '' END +')
,getCount as (Select count(0) cnt from GetProds)
Select Prod_Id ProductId
,Dept_Id DepartmentId
,PL_Id LineId
,PU_Id UnitId
,Dimension_X_Eng_Unit_Id EngUnitId,(select cnt from getCount) totalRecords from GetProds
ORDER BY Prod_Id ,PU_Id
OFFSET '+CAST(@PageSize as nvarchar)+' * ('+CAST(@PageNumber as nvarchar)+' - 1) ROWS
							FETCH NEXT '+CAST(@PageSize as nvarchar)+' ROWS ONLY OPTION (RECOMPILE);
'

--Insert into @ProductUnitData(ProductId , DeptId , PLId , PUId ,engUnitId ,totalRecords )
EXEC (@SQL)

END


