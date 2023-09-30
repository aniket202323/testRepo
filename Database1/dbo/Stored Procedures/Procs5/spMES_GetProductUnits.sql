
CREATE PROCEDURE dbo.spMES_GetProductUnits
		 @ProductIds		nvarchar(max) = null
		,@DepartmentIds		nvarchar(max) = Null
		,@LineIds			nvarchar(max) = Null
		,@UnitIds			nvarchar(max) = Null
		,@UserId			Int
		,@ProductId			Int = Null
		,@UnitId			Int = Null
AS


IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END


DECLARE @AllProducts Table (Product_Id Int)
DECLARE @AllDepartments Table (Dept_Id Int)
DECLARE @AllLines Table (PL_Id Int)
DECLARE @AllUnits Table (PU_Id Int)

Declare @ProductUnitData table (ProductId int, DeptId int, PLId int, PUId int)
IF @ProductId Is Not NULL and @UnitId Is Not NULL
BEGIN
	INSERT INTO @ProductUnitData(ProductId, DeptId, PLId, PUId)
		SELECT	p.Prod_Id, d.Dept_Id, l.PL_Id, u.PU_Id
		FROM	PU_Products p
		join	Prod_Units_Base u on u.PU_Id = p.PU_Id
		join	Prod_Lines_Base l on l.PL_Id = u.PL_Id
		Join	Departments_Base d on d.Dept_Id = l.Dept_Id
		WHERE	p.Prod_Id = @ProductId and p.PU_Id = @UnitId
END
ELSE
BEGIN

	if (@ProductIds is not null)
		INSERT INTO @AllProducts (Product_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Products', @ProductIds, ',')
	if (@DepartmentIds is not null)
		INSERT INTO @AllDepartments (Dept_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Departments', @DepartmentIds, ',')
	if (@LineIds is not null)
		INSERT INTO @AllLines (PL_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines', @LineIds, ',')
	if (@UnitIds is not null)
		INSERT INTO @AllUnits (PU_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units', @UnitIds, ',')

	INSERT INTO @ProductUnitData(ProductId, DeptId, PLId, PUId)
		SELECT	Distinct p.Prod_Id, d.Dept_Id, l.PL_Id, u.PU_Id
		FROM	PU_Products p
		join	Prod_Units_Base u on u.PU_Id = p.PU_Id
		join	Prod_Lines_Base l on l.PL_Id = u.PL_Id
		Join	Departments_Base d on d.Dept_Id = l.Dept_Id
		WHERE	((@ProductIds is null) or (p.Prod_Id in (select Product_Id from @AllProducts)))
			And	((@DepartmentIds is null) or (d.Dept_Id in (select Dept_Id from @AllDepartments)))
			And	((@LineIds is null) or (l.PL_Id in (select PL_Id from @AllLines)))
			And	((@UnitIds is null) or (u.PU_Id in (select PU_Id from @AllUnits)))
END

SELECT   ProductId = p.ProductId
		,DepartmentId = p.DeptId
		,LineId = p.PLId
		,UnitId = p.PUId
	FROM  @ProductUnitData p
	ORDER BY p.ProductId, p.PUId
