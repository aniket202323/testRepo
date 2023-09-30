CREATE PROCEDURE [dbo].[spBF_APIMyMachines_APIGetMyMachines_Populate] 
 	 @UserId Int
AS 
DECLARE @AvailableUnitslist Table (Id int Identity(1,1),PU_Id Int , PU_Desc nVarChar(max), PL_Id Int, PL_Desc nVarChar(max), Dept_Id Int, Dept_Desc nVarChar(max),  ET_Id Int , ET_Desc nvarchar(1000),Access_level int)
 DECLARE @ouputTable Table (PU_Id Int , PU_Desc nVarChar(max), PL_Id Int, PL_Desc nVarChar(max),
  Dept_Id Int, Dept_Desc nVarChar(max),  ET_Id Int , ET_Desc nvarchar(1000),Is_Slave int)
DECLARE @PreferenceUnitslist Table (PU_Id Int , ET_Id Int,unit_prefId int)
DECLARE @ExistingPreferences Table (PU_Id Int , ET_Id Int,unit_prefId int)
DECLARE @currentrow int,@maxrow int,@pu_id int
--Get all the units user has acess to 
INSERT INTO @AvailableUnitslist ( Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc,Access_level)
SELECT Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc,Access_level FROM dbo.fnBF_ApiFindAvailableUnitsAndEventTypes(@UserId)
IF (SELECT COUNT(*) FROM @AvailableUnitslist) = 0
 	 BEGIN
 	  	 SELECT Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc FROM @AvailableUnitslist
 	  	 RETURN
 	 END
--Retreive the preferences 
INSERT INTO @PreferenceUnitslist (PU_Id,ET_Id,unit_prefId)
SELECT PU_Id,ET_Id,Unit_PrefId FROM dbo.User_UnitPreferences WITH(NOLOCK) WHERE User_Id = @UserId AND Profile_Id = 0
IF NOT EXISTS (SELECT 1 FROM @PreferenceUnitslist)
 	 BEGIN
 	  	 IF EXISTS (SELECT 1 FROM User_Security WHERE User_Id = @UserId  and Group_Id = 1 and Access_Level = 4)--admin to admin
 	  	  	 BEGIN
 	  	  	  	 Insert into @ouputTable (Dept_Id,Dept_Desc,PL_Id,PL_Desc,PU_Id,PU_Desc ,ET_Id,ET_Desc,Is_Slave)
 	  	  	  	 SELECT Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc,0 FROM @AvailableUnitslist
 	  	  	  	 GOTO CHECKFORSLAVES
 	  	  	  	 --RETURN
 	  	  	 END
 	  	  	 --return the available units to which user has write or above access 
 	  	  	 Insert into @ouputTable (Dept_Id,Dept_Desc,PL_Id,PL_Desc,PU_Id,PU_Desc ,ET_Id,ET_Desc,Is_Slave)
 	  	  	 SELECT Dept_Id, Dept_Desc, PL_Id, PL_Desc, PU_Id, PU_Desc, ET_Id,ET_Desc,0 FROM @AvailableUnitslist
 	  	  	  	 WHERE access_level >= 2
 	  	  	  	 GOTO CHECKFORSLAVES
 	  	 --RETURN
 	 END
--compare whether all the preference units are in available unit list w.r.t event types
INSERT INTO @ExistingPreferences (PU_Id,ET_Id,unit_prefId)
SELECT pul.pu_id,pul.ET_Id,unit_prefId FROM @PreferenceUnitslist pul  
JOIN @AvailableUnitslist aul ON 
(pul.PU_Id = aul.PU_Id) 
--remove the preferences not in @ExistingPreferences FROM preferences table 
Delete from dbo.User_UnitPreferences where Unit_PrefId in (
Select Unit_PrefId from @PreferenceUnitslist where unit_prefId not in 
(Select Unit_PrefId from @ExistingPreferences)
) 
--Query new preferences and return them 
Insert into @ouputTable (Dept_Id,Dept_Desc,PL_Id,PL_Desc,PU_Id,PU_Desc ,ET_Id,ET_Desc,Is_Slave)
SELECT 
de.Dept_Id,
de.Dept_Desc,
pl.PL_Id,
pl.PL_Desc,
ec.PU_Id, 
pu.PU_Desc,
ec.ET_Id, 
et.ET_Desc,
0
FROM dbo.Prod_Units_base pu  
inner join User_UnitPreferences ec on ec.Pu_Id=pu.PU_Id
inner join Event_Types et on et.ET_Id=ec.ET_Id
JOIN Prod_Lines_base pl on pl.PL_Id = pu.PL_Id
JOIN Departments_base de on de.Dept_Id = pl.Dept_Id
 WHERE User_Id = @UserId AND Profile_Id = 0 
CHECKFORSLAVES: 
 --check for slaves and add them
IF  EXISTS (Select 1 from dbo.Prod_Units_Base where Master_Unit in (Select pu_id from @ouputTable))
 	 BEGIN
 	  	  INSERT INTO @ouputTable (PU_Id,PU_Desc,Dept_Id,Dept_Desc,PL_Desc,PL_Id ,ET_Desc,ET_Id,Is_Slave)
 	  	  SELECT pu.PU_Id,pu.PU_Desc,au.dept_id,au.Dept_Desc,au.PL_Desc,au.PL_Id,au.ET_Desc,au.ET_Id ,1
 	  	  FROM @ouputTable au join dbo.Prod_Units_Base pu on pu.Master_Unit = au.pu_id
 	  	  WHERE au.ET_Id = 2
 	 END
SELECT Dept_Id,
Dept_Desc,
PL_Id,
PL_Desc,
PU_Id, 
PU_Desc,
ET_Id, 
ET_Desc,Is_Slave FROM @ouputTable
