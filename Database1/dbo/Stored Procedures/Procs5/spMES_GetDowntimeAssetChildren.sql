

CREATE PROCEDURE dbo.spMES_GetDowntimeAssetChildren
	@ParentId			INT		-- Get all asset of type parented by this ID. Requires AssetId is NULL
	,@AssetType			INT		-- Asset type to return.
	,@UserId			INT
	,@PageNumber		INT = 1
	,@PageSize			INT = 20

AS

DECLARE @Assets Table (RowNumber Int IDENTITY(1,1),
						 AssetName nvarchar(100), AssetId Int,
						 Department nvarchar(100), DepartmentId Int,
						 Line nvarchar(100), LineId Int,
						 Unit nvarchar(100), UnitId Int
						 ,PU_Order Int
						 )
DECLARE @AvailableUnits TABLE  (PU_Id Int)
DECLARE @MasterUnit Int

INSERT INTO @AvailableUnits SELECT Distinct PU_Id FROM dbo.fnMES_GetDowntimeAvailableUnits(@UserId)


IF @AssetType = 1 -- Department
BEGIN
	INSERT INTO @Assets(AssetName,AssetId)
		SELECT 	DISTINCT AssetName = Dept_Desc,
				AssetId = d.Dept_Id
		FROM Departments_Base d 
		JOIN Prod_lines_Base pl on pl.Dept_Id = d.Dept_Id 
		JOIN Prod_Units_Base pu ON pu.Pl_Id = pl.Pl_Id
		JOIN @AvailableUnits au on au.PU_Id = pu.PU_Id
		ORDER BY Dept_Desc
END

IF @AssetType = 2 -- Line
BEGIN
	INSERT INTO @Assets(AssetName,AssetId)
		SELECT 	DISTINCT AssetName = PL_Desc,
				AssetId = pl.PL_Id
		FROM Prod_Lines_Base pl 
		JOIN  Departments_Base d  ON pl.Dept_Id = d.Dept_Id
		JOIN Prod_Units_Base pu ON pu.Pl_Id = pl.Pl_Id
		JOIN @AvailableUnits au on au.PU_Id = pu.PU_Id
		WHERE d.Dept_Id = @ParentId
		ORDER BY PL_Desc
END

IF @AssetType = 3 -- Unit
BEGIN
	INSERT INTO @Assets(AssetName,AssetId,PU_Order)
		SELECT DISTINCT
			AssetName = PU_Desc,
			AssetId = pu.PU_Id,
			pu.PU_Order
		FROM Prod_Units_Base pu
		JOIN Prod_Lines_Base pl ON pu.PL_Id = pl.PL_Id
		JOIN @AvailableUnits au ON au.PU_Id = pu.PU_Id or au.PU_Id = pu.Master_Unit
		WHERE  pl.PL_Id = @ParentId and pu.Timed_Event_Association > 0
		ORDER BY pu.PU_Order,PU_Desc,pu.PU_Id
END


IF @AssetType = 4 -- ALL for a user
BEGIN
	INSERT INTO  @Assets(Department,DepartmentId,Line, LineId,Unit, UnitId,PU_Order)
		SELECT 	DISTINCT Dept_Desc,d.Dept_Id
				,Pl_Desc,pl.PL_Id
				,Pu_desc,pu.pu_Id
				,pu.PU_Order
		FROM Departments_Base d 
		JOIN Prod_Lines_Base pl ON pl.Dept_Id = d.Dept_Id 
		JOIN Prod_Units_Base pu ON pu.Pl_Id = pl.Pl_Id
		JOIN @AvailableUnits au ON au.PU_Id = pu.PU_Id or au.PU_Id = pu.Master_Unit
		ORDER BY Dept_Desc,Pl_Desc,pu.PU_Order,pu.PU_Desc
END
IF @AssetType = 5 -- Parent Child
BEGIN
	SELECT @MasterUnit = Coalesce(Master_Unit,PU_Id)
		FROM Prod_Units
		WHERE PU_ID = @ParentId
	INSERT INTO @Assets(Department,DepartmentId,Line, LineId,Unit, UnitId,PU_Order)
		SELECT 	DISTINCT Dept_Desc,d.Dept_Id
				,Pl_Desc,pl.PL_Id
				,Pu_desc,pu.pu_Id
				,pu.PU_Order
		FROM Departments_Base d 
		JOIN Prod_Lines_Base pl ON pl.Dept_Id = d.Dept_Id 
		JOIN Prod_Units_Base pu ON pu.Pl_Id = pl.Pl_Id
		WHERE pu.PU_Id = @MasterUnit or pu.Master_Unit = @MasterUnit
		ORDER BY Dept_Desc,Pl_Desc,pu.PU_Order,pu.PU_Desc
END
-- Asset set has been built. Provide requested page.
DECLARE @startRow Int
DECLARE @endRow Int

SET @PageNumber = coalesce(@PageNumber,1)
SET @PageSize = coalesce(@PageSize,20)
SET @PageNumber = @PageNumber -1

SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
SET @endRow = @startRow + @PageSize - 1

SELECT *
FROM @Assets
WHERE RowNumber BETWEEN @startRow AND @endRow

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
