Create PROCEDURE [dbo].[spDAML_FetchPlantModelTree] 
AS
/*  -- set up the UDP 
insert into table_fields (ed_field_type_id, Table_field_desc)  values(2,'NOSOAVAR')
-- set var_id 1 to be NOSOA 
insert into table_fields_values (keyid, table_field_id, tableid, value) 
  select 1, -- the var_id
    table_field_id, 20, 1 
    from table_fields where table_field_desc = 'NOSOAVAR'
*/
 	 DECLARE @TableFieldId int
 	 DECLARE @Vars TABLE (Var_Id int, Var_Desc varchar(50), PUG_Id int, PVar_Id int)
 	 DECLARE @VarsToSkip TABLE (Var_Id int)
 	 DECLARE @Groups TABLE (Pug_Id int,PU_Id Int,PUG_Desc VarChar(50))
   -- Fliter Out Department   (17)
 	 SELECT @TableFieldId = NULL
 	 SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 17
 	 INSERT INTO @VarsToSkip(Var_Id)
 	 SELECT v.Var_Id
 	   From Variables v
 	   JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
 	   JOIN Prod_Lines pl On pl.Pl_Id = pu.Pl_Id
 	   JOIN Table_fields_values tfv on tfv.Table_Field_Id = @TableFieldId AND tfv.tableid = 17 and tfv.Keyid = pl.Dept_Id 
 	  Where v.PU_Id > 0
-- Fliter Out Line (18)
 	 SELECT @TableFieldId = NULL
 	 SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 18
 	 INSERT INTO @VarsToSkip(Var_Id)
 	 SELECT v.Var_Id
 	  	 From Variables v
 	  	 JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
 	  	 JOIN Prod_Lines pl On pl.Pl_Id = pu.Pl_Id
 	  	 JOIN Table_fields_values tfv on tfv.Table_Field_Id = @TableFieldId AND tfv.tableid = 18 and tfv.Keyid = pl.PL_Id 
 	  	 Where v.PU_Id > 0
-- Fliter Out Unit (43)
 	 SELECT @TableFieldId = NULL
 	 SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 43
 	 INSERT INTO @VarsToSkip(Var_Id)
 	  	 SELECT v.Var_Id
 	  	   From Variables v
 	  	   JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
 	  	   JOIN Table_fields_values tfv on tfv.Table_Field_Id = @TableFieldId AND tfv.tableid = 43 and tfv.Keyid = pu.PU_Id 
 	  	  Where v.PU_Id > 0
-- Fliter Out Group (19)
 	 SELECT @TableFieldId = NULL
 	 SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 19
 	 INSERT INTO @VarsToSkip(Var_Id)
 	  	 SELECT v.Var_Id
 	  	 From Variables v
 	  	 JOIN Table_fields_values tfv3 on tfv3.Table_Field_Id = @TableFieldId AND tfv3.tableid = 19 and tfv3.Keyid = v.PUG_Id
 	  	 Where v.PU_Id > 0
-- Fliter Out Variable  (20)
 	 SELECT @TableFieldId = NULL
 	 SELECT @TableFieldId = Table_Field_Id  FROM table_fields where table_field_desc = 'NOSOAVAR' AND tableid = 20
 	 INSERT INTO @VarsToSkip(Var_Id)
 	  	 SELECT v.Var_Id
 	  	 From Variables v
 	  	 JOIN Table_fields_values tfv3 on tfv3.Table_Field_Id = @TableFieldId AND tfv3.tableid = 20 and tfv3.Keyid = v.Var_Id
 	  	 Where v.PU_Id > 0
--Get All Vars
 INSERT INTO @Vars (Var_Id , Var_Desc , PUG_Id , PVar_Id) 
      SELECT v.Var_Id , v.Var_Desc , v.PUG_Id , v.PVar_Id
      From Variables v
      JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
      JOIN Prod_Lines pl On pl.Pl_Id = pu.Pl_Id
      Where v.PU_Id > 0
--Remove Not needed
DELETE  @Vars
 	 FROM @Vars v
 	 JOIN @VarsToSkip vs on vs.Var_Id = v.Var_Id
INSERT INTO @Groups(Pug_Id,PU_Id,PUG_Desc )
 	 SELECT DISTINCT a.PUG_Id,b.PU_Id,b.PUG_Desc
 	  	  FROM @Vars a
 	  	  Join PU_Groups b on b.PUG_Id = a.PUG_Id 
BEGIN
    -- The first part of the dataset loads production departments, line, units, variable groups, and variables
    --  Note: the outer joins are needed to pick up empty items.
    --        system calculation variables created by the EventMgr for a Waste model are
    --        exluded from the PA Administrator, so they are also excluded here.  They
    --        are identified PUG_Desc='Model 5014 Calculation'
    SELECT 	 TreeLevel = '1',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0),
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0),
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = IsNull(pug.PUG_Id,0),
 	  	         Param1Name = pug.PUG_Desc, 
 	  	         Param2Id = IsNull(v.Var_Id,0),
 	  	         Param2Name = v.Var_Desc,
 	  	  	  	 Param3Id = IsNull(v.PVar_Id,0) 
 	  	     FROM Departments d
 	  	  	 LEFT OUTER JOIN Prod_Lines pl ON pl.Dept_Id = d.Dept_Id and pl.PL_Id > 0
 	  	  	 LEFT OUTER JOIN Prod_Units pu ON pu.PL_Id = pl.PL_Id and pu.Pu_Id > 0
 	  	  	 LEFT OUTER JOIN @Groups pug on pug.PU_Id = pu.PU_Id and pug.PUG_Desc<>'Model 5014 Calculation' and pug.Pug_Id > 0
 	  	  	 LEFT OUTER JOIN @vars v on v.PUG_Id = pug.PUG_Id 
UNION
    -- The second part of the dataset loads production line paths
    SELECT 	 TreeLevel = '1',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = 0, 
 	  	         ProductionUnitName = '', 
 	  	         Param1Id = -1, 
 	  	         Param1Name = '', 
 	  	         Param2Id = IsNull(pep.Path_Id,0), 
 	  	         Param2Name = pep.Path_Desc,
                Param3Id = 0
 	         FROM Prdexec_Paths pep 
 	  	     INNER JOIN Prod_Lines pl ON pep.PL_Id = pl.PL_Id and pl.PL_Id > 0 	   	  	  	  	  	  	  	  	  	 
 	  	     INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
Union
    -- The third part of the dataset loads production unit inputs
    SELECT 	 TreeLevel = '1',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0), 
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = -2, 
 	  	         Param1Name = '', 
 	  	         Param2Id = IsNull(pei.PEI_Id,0), 
 	  	         Param2Name = pei.Input_Name,
                Param3Id = 0
 	         FROM Prdexec_Inputs pei 
 	  	  	 INNER JOIN Prod_Units pu ON pei.PU_Id = pu.PU_Id and pu.Pu_Id > 0 	 
 	  	     INNER JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id 	 and pl.PL_Id > 0 	  	  	  	  	  	  	  	  	 
 	  	     INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
Union
  -- The fourth part of the dataset loads production unit event types
  SELECT 	 Distinct TreeLevel = '2',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0), 
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = IsNull(ec.ET_Id,0),
 	  	         Param1Name = et.ET_Desc,
 	  	         Param2Id 	 = 0, 
 	  	         Param2Name = '',
 	  	  	  	 Param3Id = 0
 	         FROM Event_Types et 
 	  	  	 INNER JOIN Event_Configuration ec ON ec.ET_Id = et.ET_Id
 	  	  	 INNER JOIN Prod_Units pu ON ec.PU_Id = pu.PU_Id 	 and pu.Pu_Id > 0
 	  	  	 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id and pl.PL_Id > 0
 	  	  	 INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	 
Union
  -- The fifth part of the dataset loads production unit production plan starts
  SELECT 	 Distinct TreeLevel = '2',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0), 
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = 1111,
 	  	         Param1Name = 'Production Plan Start',
 	  	         Param2Id 	 = 0, 
 	  	         Param2Name = '',
 	  	  	  	 Param3Id = 0
 	         FROM prdexec_path_units ppu 
 	  	  	 INNER JOIN Prod_Units pu ON ppu.PU_Id = pu.PU_Id AND ppu.is_schedule_point = 1 and pu.Pu_Id > 0
 	  	  	 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id and pl.PL_Id > 0
 	  	  	 INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	  	  	  	  	  	  	  	  	  	 
Union
 	 -- Sheets associated with Lines
    SELECT 	 TreeLevel = '1',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = 0, 
 	  	         ProductionUnitName = '', 
 	  	         Param1Id = IsNull(sg.Sheet_Group_Id,0), 
 	  	         Param1Name = sg.Sheet_Group_Desc,
 	  	         Param2Id = IsNull(s.Sheet_Id,0), 
 	  	         Param2Name = s.Sheet_Desc,
                Param3Id = -3
 	         FROM Sheets s 
 	  	  	 INNER JOIN Sheet_Groups sg ON sg.Sheet_Group_Id = s.Sheet_Group_Id
 	  	     INNER JOIN Prod_Lines pl ON s.PL_Id = pl.PL_Id 	 and pl.PL_Id > 0 	  	  	  	  	  	  	  	  	 
 	  	     INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
Union
 	 -- Sheets associated with Units
    SELECT 	 TreeLevel = '1',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0),
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = IsNull(sg.Sheet_Group_Id,0), 
 	  	         Param1Name = sg.Sheet_Group_Desc,
 	  	         Param2Id = IsNull(s.Sheet_Id,0), 
 	  	         Param2Name = s.Sheet_Desc,
                Param3Id = -3
 	         FROM Sheets s 
 	  	  	 INNER JOIN Sheet_Groups sg ON sg.Sheet_Group_Id = s.Sheet_Group_Id
 	  	     INNER JOIN Prod_Units pu ON s.Master_Unit = pu.PU_Id and pu.Pu_Id > 0 	  	  	  	  	  	  	  	  	  	 
 	  	     INNER JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id 	 and pl.PL_Id > 0 	  	  	  	  	  	  	  	  	 
 	  	     INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
-- order is critical for the loading process 	         
ORDER BY DepartmentId, ProductionLineId, ProductionUnitId, TreeLevel, Param1Id, Param2Id, Param3Id
END
