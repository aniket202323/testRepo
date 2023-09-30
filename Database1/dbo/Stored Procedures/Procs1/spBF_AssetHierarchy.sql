/*
1 - List of all Areas(Departments)                                           EXECUTE spBF_AssetHierarchy 1,Null,5,1 	  	  -- EXECUTE spBF_AssetHierarchy 1,'1,2,3,4',99,1
2 - List of all lines of the plant ?> Children of Site                       EXECUTE spBF_AssetHierarchy 2,null,5,1      -- EXECUTE spBF_AssetHierarchy 2,'9,10,11,19',99,1
3 - List of all lines of the Area ?> Children of Department 	                  EXECUTE spBF_AssetHierarchy 3,1,9,1 	  	  -- EXECUTE spBF_AssetHierarchy 3,'1,2,20',15,1
4 - List of all the machines in a line --> Children of Segment               EXECUTE spBF_AssetHierarchy 4,5,3,2
5 - List of all the machines in a plant --> Leaf nodes of Site               EXECUTE spBF_AssetHierarchy 5,Null,5,2
*/
CREATE PROCEDURE [dbo].[spBF_AssetHierarchy] 
@ResultType 	  	  	  	  	 int = 1,
@InputId 	  	  	  	  	 nvarchar(max) = NULL,
@pageSize 	  	  	  	  	 Int = 20,
@pageNum 	  	  	  	  	 Int = 1
AS 
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @Ids Table (Id Int)
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,20)
SET @pageNum = @pageNum -1
SET @startRow = coalesce(@pageNum * @pageSize,0) + 1
SET @endRow = @startRow + @pageSize - 1
IF LTRIM(RTRIM(@InputId)) = ''
 	 SET @InputId = Null
IF @ResultType 	 = 1 -- all Area(s)(Departments)
BEGIN
 	 IF @InputId Is Not Null
 	  	 INSERT INTO @Ids(id) SELECT Id FROM dbo.fnCMN_IdListToTable('Departments',@InputId,',')
 	 ELSE
 	  	 INSERT INTO @Ids(id) SELECT Dept_Id FROM Departments 
 	 SELECT AreaId, AreaName 
 	 FROM (
 	  	 SELECT AreaId = a.Dept_Id, AreaName = a.Dept_Desc, ROW_NUMBER() OVER (ORDER BY a.Dept_Id) AS RowNum
 	  	 FROM  Departments_Base a
 	  	 WHERE a.Dept_Id > 0 and Dept_Id In (Select Id From @Ids)
 	 ) AS MyDepartmentsTable
 	 WHERE MyDepartmentsTable.RowNum BETWEEN @startRow AND @endRow
END
IF @ResultType 	 = 2 -- List of all lines of the plant ?> Children of Site(s) 
BEGIN
 	 IF @InputId Is Not Null
 	  	 INSERT INTO @Ids(id) SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines',@InputId,',')
 	 ELSE
 	  	 INSERT INTO @Ids(id) SELECT PL_Id FROM Prod_Lines 
 	 SELECT AreaId, AreaName,LineId, LineName
 	 FROM(
 	 SELECT   AreaId = b.Dept_Id,
 	  	  	  AreaName = b.Dept_Desc,
 	  	  	  LineId = a.PL_Id,
 	  	  	  LineName = a.PL_Desc,
 	  	  	  ROW_NUMBER() OVER (ORDER BY b.Dept_Desc,a.PL_Desc) AS RowNum
 	  	 FROM  Prod_Lines_Base a
 	  	 Join Departments_Base b on b.Dept_Id = a.Dept_Id
 	  	 WHERE b.Dept_Id > 0 and pl_Id in (SELECT Id FROM @Ids)) AS MyLineTable
 	 WHERE MyLineTable.RowNum BETWEEN @startRow AND @endRow
END
IF @ResultType 	 = 3 -- List of all lines of the Area ?> Children of Department(s)
BEGIN
 	 INSERT INTO @Ids(id) SELECT Id FROM dbo.fnCMN_IdListToTable('Departments',@InputId,',')
 	 SELECT @InputId = Min(id) FROM @Ids
 	 SELECT AreaId, AreaName,LineId, LineName
 	 FROM(
 	 SELECT  AreaId = b.Dept_Id,
 	  	  	 AreaName = b.Dept_Desc,
 	  	  	 LineId = a.PL_Id,
 	  	  	 LineName = a.PL_Desc,
 	  	  	 ROW_NUMBER() OVER (ORDER BY b.Dept_Desc,a.PL_Desc) AS RowNum
 	  	 FROM  Prod_Lines_Base a
 	  	 Join Departments_Base b on b.Dept_Id = a.Dept_Id
 	  	 WHERE a.Dept_Id in (select id From @Ids) )AS MyLineTable
 	 WHERE MyLineTable.RowNum BETWEEN @startRow AND @endRow
END
IF @ResultType 	 = 4 -- List of all the machines in a line(s) --> Children of Segment 
BEGIN
 	 IF @InputId Is Not Null
 	  	 INSERT INTO @Ids(id) SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines',@InputId,',')
 	 SELECT AreaId, AreaName,LineId, LineName,UnitId,UnitName
 	 FROM( 	 
 	 SELECT  AreaId = c.Dept_Id,
 	  	  	 AreaName = c.Dept_Desc,
 	  	     LineId = b.PL_Id,
 	  	  	 LineName = b.PL_Desc,
 	  	  	 UnitId = a.PU_Id,
 	  	  	 UnitName = a.PU_Desc,
 	  	  	 ROW_NUMBER() OVER (ORDER BY b.PL_Desc,a.PU_Order,a.PU_Desc) AS RowNum
 	  	 FROM  Prod_Units_Base a
 	  	 Join Prod_Lines_Base b on b.PL_Id = a.PL_Id
 	  	 join Departments_Base c on c.Dept_Id = b.Dept_Id
 	  	 WHERE a.PL_Id in (Select id FROM @Ids)) AS MyUnitTable
 	 WHERE MyUnitTable.RowNum BETWEEN @startRow AND @endRow 	  	 
END
IF @ResultType 	 = 5 -- List of all the machines in a plant --> Leaf nodes of Site
BEGIN
 	 IF @InputId Is Not Null
 	  	 INSERT INTO @Ids(id) SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@InputId,',')
 	 ELSE
 	  	 INSERT INTO @Ids(id) SELECT PU_Id FROM Prod_Units
 	 SELECT AreaId, AreaName,LineId, LineName,UnitId,UnitName
 	 FROM( 	 
 	 SELECT  AreaId = c.Dept_Id,
 	  	  	 AreaName = c.Dept_Desc,
 	  	     LineId = b.PL_Id,
 	  	  	 LineName = b.PL_Desc,
 	  	  	 UnitId = a.PU_Id,
 	  	  	 UnitName = a.PU_Desc,
 	  	  	 ROW_NUMBER() OVER (ORDER BY b.PL_Desc,a.PU_Order,a.PU_Desc) AS RowNum
 	  	 FROM  Prod_Units_Base a
 	  	 Join Prod_Lines_Base b on b.PL_Id = a.PL_Id
 	  	 join Departments_Base c on c.Dept_Id = b.Dept_Id
 	  	 WHERE a.PL_Id > 0 and PU_Id in (Select id From @Ids)) AS MyUnitTable
 	 WHERE MyUnitTable.RowNum BETWEEN @startRow AND @endRow
END
